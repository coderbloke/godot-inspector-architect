@tool
extends EditorInspectorPlugin

var main_plugin: EditorPlugin

var debug_info_enabled := false

func _get_debug_log() -> DebugInfoLog:
	return DebugInfo.get_log("inspector_architect", "Inspector Architect")

func _debug_info(text: String):
	var debug_label := RichTextLabel.new()
	debug_label.add_theme_color_override("default_color", Color.LIGHT_BLUE)
	debug_label.add_theme_font_size_override("normal_font_size", 10)
	debug_label.add_theme_color_override("table_border", Color(Color.LIGHT_BLUE, 0.1))
	debug_label.bbcode_enabled = true
	debug_label.text= text
	debug_label.fit_content = true
	add_custom_control(debug_label)

func _can_handle(object: Object) -> bool:
	debug_info_enabled = true
	if true and debug_info_enabled:
		var log := _get_debug_log()
		log.print_rich("[color=LightBlue][_can_handle] object = %s, self = %s[/color]" % [object, self.get_instance_id()])
		var property_list = object.get_property_list()
		property_list = _get_inspector_property_list(object)
	return true

func _property_description_to_string(p: Dictionary):
	return "name = \"%s\", class_name = \"%s\", type = %s" % [p.name, p["class_name"], InspectorArchitect.enum_to_string(InspectorArchitect.VariantType, p.type)] \
			+ ", hint = %s, hint_string = \"%s\"" % [InspectorArchitect.enum_to_string(InspectorArchitect.PropertyHint, p.get("hint", 0)), p.get("hint_string", "")] \
			+ ", usage = %s" % [InspectorArchitect.flags_to_string(InspectorArchitect.PropertyUsageFlags, p.get("usage", 0))]
 
func _property_list_to_table(property_list: Array[Dictionary]):
	var s = "[table=6][cell]name[/cell][cell]class_name[/cell][cell]type[/cell][cell]hint[/cell][cell]hint_string[/cell][cell]usage[/cell]"
	var indent := ""
	for p in property_list:
		if p.usage == PROPERTY_USAGE_SUBGROUP:
			indent = "  - "
		elif p.usage == PROPERTY_USAGE_GROUP:
			indent = "- "
		elif p.usage == PROPERTY_USAGE_CATEGORY:
			indent = ""
		s += "[cell]%s%s[/cell][cell]%s[/cell][cell]%s[/cell]" % [indent, p.name, p["class_name"], InspectorArchitect.enum_to_string(InspectorArchitect.VariantType, p.type)] \
				+ "[cell]%s[/cell][cell]%s[/cell]" % [InspectorArchitect.enum_to_string(InspectorArchitect.PropertyHint, p.get("hint", 0)), p.get("hint_string", "")] \
				+ "[cell]%s[/cell]" % [InspectorArchitect.flags_to_string(InspectorArchitect.PropertyUsageFlags, p.get("usage", 0))]
		if p.usage == PROPERTY_USAGE_SUBGROUP:
			indent = "    - "
		elif p.usage == PROPERTY_USAGE_GROUP:
			indent = "  - "
		elif p.usage == PROPERTY_USAGE_CATEGORY:
			indent = "- "
	s += "[/table]"
	return s
 
func _get_reversed_property_list(object: Object, add_additional_info: bool = true) -> Array[Dictionary]:
	var original_list := object.get_property_list()
	# get_property_list exposed to GDScript list propertyies like this:
	# - Properties of the built-in class from base class to subclass 
	# - Then properties of script classes from subclass to base class
	# In inspector the order is
	# - Properties of script classes from subclass to base class
	# - Then the properties of built-in classes from subclass to base class
	# get_property_list automatically add a category for each class (category name is the class name)
	# To reverse order, we rely on that no built-in class put any category in their property list,
	# so in the beginning of the list the categories will mean the start of a built-in class property list
	# + That the category which is a start of a script class, has the name of the script file (+ the resource path as hint string)
	# (No clue what happens, if a script is created dynamically. But such may not appear in inspector in any way.)
	# But for sure we also start reversing, if we reach a category with name of base built-on class of bject
#	var log := _get_debug_log()
	var reversed_list: Array[Dictionary] = []
	var class_property_list: Array[Dictionary] = []
	var built_in_class := object.get_class()
	var last_category := ""
	var script_class_start_hit := false
	var log := _get_debug_log()
	for i in original_list.size():
		var property := original_list[i]
#		log.print_verbose("[%d] %s" % [i, property])
		var class_start: bool = false
		if property.get("usage", 0) & PROPERTY_USAGE_CATEGORY != 0:
			if script_class_start_hit == false: # A category during built-in classes means the start of a new class (so we store the previous classes in reverse order)
				class_property_list.append_array(reversed_list)
				reversed_list = class_property_list
				class_property_list = []
				class_start = true
			if property.get("hint_string", "") != "" or last_category == built_in_class: # For script classes, the class name is in the hint (for built-in is empty), so we assume this is the beginning odf the script class
				script_class_start_hit = true
				class_start = true
			last_category = property.get("name", "")
		if add_additional_info:
			property["class_start"] = class_start
		class_property_list.append(property)
	class_property_list.append_array(reversed_list)
	return class_property_list

func _get_current_feature_profile() -> EditorFeatureProfile:
	if main_plugin == null:
		return null
		
	var editor_settings = main_plugin.get_editor_interface().get_editor_settings()
	var profile_name = editor_settings.get("_default_feature_profile")
	
	var editor_paths = EditorPaths.new()
	var config_dir = editor_paths.get_config_dir()
	var profile_path = config_dir.path_join("feature_profiles").path_join(profile_name + ".profile")
	
	var profile := EditorFeatureProfile.new()
	profile.load_from_file(profile_path)
	
	return profile

func _is_gfx_low_end() -> bool:
	# In Godot cpp code, inspector gets is_low_end from the RS singleton (i.e. RenderServer)
	# In Godot cpp code, only setting of any low_end variable to true was found in drivers/gles3/rasterizer_gles3.h
	# In Godot doc reference to limitation of GLE3 is mentioned, when render_method = gl_compatibility
	return ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility"

func _is_property_disabled_by_feature_profile(object: Object, property: StringName, profile: EditorFeatureProfile) -> bool:
	if profile == null:
		return false

	var object_class := object.get_class()

	while object_class != "":
		if profile.is_class_disabled(object_class):
			return true
		if profile.is_class_property_disabled(object_class, property):
			return true
		object_class = ClassDB.get_parent_class(object_class)

	return false
	
func _call_method_if_exists(object: Object, method_name: String, default_retval: Variant = null):
	if object.has_method(method_name):
		return object.call(method_name)
	else:
		return default_retval
	
func _get_inspector_property_list(object: Object, add_additional_info: bool = true):
	var log := DebugInfo.get_log("inspector_architect", "Inspector Architect")
	log.clear()
	
	var feature_profile := _get_current_feature_profile()
	var restrict_to_basic := false # Used in condition, but no clue where it comes from, in original code, it can be set by setter
	var filter := "" # Also no clue yet, if it is accesible from here 
	var gfx_is_low_end := _is_gfx_low_end()
	
	var hide_script = false # Simply a property of the inspector class in Godot engine code
	
	var property_list := _get_reversed_property_list(object)
	# Do what editor_inspect.cpp / EditorInspector::update_tree is doing
	# Not all the things, as not all of them are necessary, but structure kept for tracebility
	# Scope is only to filter and order the same way
	var inspector_property_list: Array[Dictionary] = []
	var end_of_list_exceptions: Array[Dictionary] = []
	var last_index_outside_group := -1
	var group: String = ""
	var group_base: String = ""
	var subgroup: String = ""
	var subgroup_base: String = ""
	var previous_property_list_size = 0 # DEBUG
	for p in property_list:
		if add_additional_info:
			p["display_name"] = ""
		if previous_property_list_size != inspector_property_list.size():
			for i in inspector_property_list.size():
				if i > 0: log.printraw(", ")
				else: log.printraw("----> ")
				log.printraw("[%d] = %s" % [i, inspector_property_list[i].name])
			log.print("")
		previous_property_list_size = inspector_property_list.size()
		log.print("last_index_outside_group = %d" % last_index_outside_group)
		log.print_verbose("%s" % [_property_description_to_string(p)])
		if p.usage & PROPERTY_USAGE_SUBGROUP != 0:
			subgroup = p.name
			var hint_parts = p.hint_string.split(",")
			subgroup_base = hint_parts[0] if hint_parts.size() >= 0 else "" 
			if subgroup != "":
				inspector_property_list.append(p)
			continue
		if p.usage & PROPERTY_USAGE_GROUP != 0:
			group = p.name
			var hint_parts = p.hint_string.split(",")
			group_base = hint_parts[0] if hint_parts.size() >= 0 else "" 
			subgroup = ""
			subgroup_base = ""
			if group != "":
				inspector_property_list.append(p)
			continue
		if p.usage & PROPERTY_USAGE_CATEGORY != 0:
			group = ""
			group_base = ""
			subgroup = ""
			subgroup_base = ""
			inspector_property_list.append(p)
			last_index_outside_group = inspector_property_list.size() - 1
			continue
		if p.name.begins_with("metadata/_"):
			continue;
		if p.usage & PROPERTY_USAGE_EDITOR == 0 \
				or p.usage & PROPERTY_USAGE_EDITOR == 0 \
				or _is_property_disabled_by_feature_profile(object, p.name, feature_profile) \
				or (filter == "" and restrict_to_basic and p.usage & PROPERTY_USAGE_EDITOR_BASIC_SETTING != 0):
			continue
		
		if p.usage & PROPERTY_USAGE_HIGH_END_GFX != 0 and gfx_is_low_end:
			continue;
			
		if p.name == "script" and (hide_script or _call_method_if_exists(object, "_hide_script_from_inspector", false) == true):
			continue
	
		if p.name.begins_with("metadata/") and _call_method_if_exists(object, "_hide_metadata_from_inspector", false) == true:
			continue
			
		if p.name == "script":
			end_of_list_exceptions.append(p)
			continue

		log.print("\tgroup = \"%s\"" % group)
		if group == "" or not p.name.begins_with(group_base):
			log.print_verbose("\tINSERT @ %d" % last_index_outside_group)
			inspector_property_list.insert(last_index_outside_group + 1, p)
		else:
			log.print_verbose("\tAPPEND")
			inspector_property_list.append(p)

		if group == "":
			last_index_outside_group = inspector_property_list.size() - 1

	inspector_property_list.append_array(end_of_list_exceptions)
	
	log.print_rich(_property_list_to_table(inspector_property_list))
	return property_list

func _parse_begin(object: Object) -> void:
	if true and debug_info_enabled:
		var debug_info := "[_parse_begin] object = %s" % [object]
		var property_list = object.get_property_list()
		property_list = _get_inspector_property_list(object)
		debug_info += "\n[table=6][cell]name[/cell][cell]class_name[/cell][cell]type[/cell][cell]hint[/cell][cell]hint_string[/cell][cell]usage[/cell]"
		for p in property_list:
			if p["usage"] & PROPERTY_USAGE_CATEGORY == 0:
				pass #continue
			debug_info += "[cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]" % [p.name, p["class_name"], InspectorArchitect.enum_to_string(InspectorArchitect.VariantType, p.type)] \
					+ "[cell]%s[/cell][cell]%s[/cell]" % [InspectorArchitect.enum_to_string(InspectorArchitect.PropertyHint, p.get("hint", 0)), p.get("hint_string", "")] \
					+ "[cell]%s[/cell]" % [InspectorArchitect.flags_to_string(InspectorArchitect.PropertyUsageFlags, p.get("usage", 0))]
#			debug_info += "\n-\tname = \"%s\", class_name = \"%s\", type = %s," % [p.name, p["class_name"], InspectorArchitect.enum_to_string(InspectorArchitect.VariantType, p.type)] \
#					+ "\n\thint = %s, hint_string = \"%s\"," % [InspectorArchitect.enum_to_string(InspectorArchitect.PropertyHint, p.get("hint", 0)), p.get("hint_string", "")] \
#					+ " usage = %s" % [InspectorArchitect.flags_to_string(InspectorArchitect.PropertyUsageFlags, p.get("usage", 0))]
		debug_info += "[/table]"
		_debug_info(debug_info)
		var log := _get_debug_log()
		log.print_rich(debug_info)

func _parse_category(object: Object, category: String) -> void:
	if true and debug_info_enabled:
		_debug_info("[_parse_category] object = %s, category = \"%s\"" % [object, category])

func _parse_end(object: Object) -> void:
	if true and debug_info_enabled:
		_debug_info("[_parse_end] object = %s" % [object])

func _parse_group(object: Object, group: String) -> void:
	if true and debug_info_enabled:
		_debug_info("[_parse_group] object = %s, group = \"%s\"" % [object, group])

func _parse_property(object: Object, type: Variant.Type, name: String,
		hint_type: PropertyHint, hint_string: String,
		usage_flags: PropertyUsageFlags, wide: bool) -> bool:
	if true and debug_info_enabled:
		_debug_info("[_parse_property] object = %s, type = %s, name = \"%s\"," % [object, InspectorArchitect.enum_to_string(InspectorArchitect.VariantType, type), name]
				+ "\nhint_type = %s, hint_string = \"%s\"," % [InspectorArchitect.enum_to_string(InspectorArchitect.PropertyHint, hint_type), hint_string]
				+ "\nusage_flags = %s, wide = %s" % [InspectorArchitect.flags_to_string(InspectorArchitect.PropertyUsageFlags, usage_flags), wide])
	return false
