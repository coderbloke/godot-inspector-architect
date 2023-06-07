@tool
extends Object

# ---------------------------------------------
# -------- Debug info helper functions --------
# ---------------------------------------------

func _get_debug_log() -> DebugInfoLog:
	var log := DebugInfo.get_log("inspector_architect", "Inspector Architect")
#	log.redirect_to_main = true
	return log

func _property_description_to_string(p: Dictionary):
	return "name = \"%s\", class_name = \"%s\", type = %s" % [p.name, p["class_name"], InspectorArchitect.enum_to_string(InspectorArchitect.VariantType, p.type)] \
			+ ", hint = %s, hint_string = \"%s\"" % [InspectorArchitect.enum_to_string(InspectorArchitect.PropertyHint, p.get("hint", 0)), p.get("hint_string", "")] \
			+ ", usage = %s" % [InspectorArchitect.flags_to_string(InspectorArchitect.PropertyUsageFlags, p.get("usage", 0))]

func _get_bbcode_cells(cell_contents: PackedStringArray):
	var s = ""
	for cell_content in cell_contents:
		s += "[cell]%s[/cell]" % cell_content
	return s

func _property_list_to_table(property_list: Array[Dictionary]):
	var header: PackedStringArray = [
		"name",
		"class_name",
		"type",
		"hint",
		"hint_string",
		"usage",
		"class_start",
		"label",
		"path",
		"level",
	]
	var s = "[table=%d]%s" % [header.size(), _get_bbcode_cells(header)]
	for p in property_list:
		var indent := ""
		var level: int = p.get("level", 0)
		var row: PackedStringArray = [
			indent + p.name,
			p["class_name"],
			InspectorArchitect.enum_to_string(InspectorArchitect.VariantType, p.type),
			InspectorArchitect.enum_to_string(InspectorArchitect.PropertyHint, p.hint),
			p.hint_string,
			InspectorArchitect.flags_to_string(InspectorArchitect.PropertyUsageFlags, p.usage),
			str(p.class_start) if p.has("class_start") else "",
			p.get("label", ""),
			p.get("path", ""),
			str(p["level"]) if p.has("level") else ""
		]
		s += _get_bbcode_cells(row)
		if p.usage == PROPERTY_USAGE_SUBGROUP:
			indent = "    - "
		elif p.usage == PROPERTY_USAGE_GROUP:
			indent = "  - "
		elif p.usage == PROPERTY_USAGE_CATEGORY:
			indent = "- "
	s += "[/table]"
	return s

func _get_container_elements_debug_info(elements: Array):
	var s := ""
	for e in elements:
		if not s.is_empty():
			s += ", "
		s += e.name
		if e is _PropertyContainer:
			s += "[]"
	if s.is_empty():
		s += "-"
	return s

func _print_container_debug_info(log: DebugInfoLog, container: _PropertyContainer, container_label_prefix: String):
	var s = _get_container_elements_debug_info(container.elements)
	s = container_label_prefix + container.label + ": " + s
	var indent := ""
	for i in container.level: indent += "  "
	log.print_colored("Lightgreen", "\t" + indent + " - " + s)
	for e in container.elements:
		if e is _PropertyContainer:
			_print_container_debug_info(log, e, "")
	
func _print_containers_debug_info(log: DebugInfoLog, containers: Array[_PropertyContainer]):
	for container in containers:
		var container_label_prefix := "(" + str(containers.find(container)) + ") "
		_print_container_debug_info(log, container, container_label_prefix)

# -----------------------------------------------------
# -------- Structure building helper functions --------
# -----------------------------------------------------

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
	var reversed_list: Array[Dictionary] = []
	var class_property_list: Array[Dictionary] = []
	var built_in_class := object.get_class()
	var last_category := ""
	var script_class_start_hit := false
	var log := _get_debug_log()
	for i in original_list.size():
		var property := original_list[i]
#		log.print_verbose("[%d] %s" % [i, property]) DEBUG
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

func _is_type_recognized(type: String):
	# Function coming from EditroData.cpp. No cue set if the commented part of the condition can be done via exposed methods
	return ClassDB.class_exists(type) # or ScriptServer.is_global_class(type) or get_custom_type_by_name(type)

func _get_script_class_name(script: Script) -> String:
	# Also no clue yet, how to do it with exposed methods
	# In engine soruce it's done in editor_data.cpp / EditorData::script_class_get_name, but that's only using an already filled data
	# It is filled in editor_file_system.cpp / EditorFileSystem::_update_script_classes
	return ""

func _get_current_feature_profile() -> EditorFeatureProfile:
	var editor_settings = editor_interface.get_editor_settings()
	var profile_name = editor_settings.get("_default_feature_profile")

	var editor_paths = editor_interface.get_editor_paths()
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

# ------------------------------------
# -------- Structure building --------
# ------------------------------------

class _PropertyContainer: # Helper class to substitute VBoxContainer from inspector's code
	var level: int
	var name: String
	var label: String
	var owner: Dictionary
	var elements: Array # Dictionary for properties, _PropertyContainer for arrays
	func _init(owner, name: String, label: String, level: int):
		if owner != null:
			self.owner = owner
		self.name = name
		self.label = label
		self.level = level
		
var restrict_to_basic := false # Used in condition, but no clue where it comes from, in original code, it can be set by setter
var filter := "" # Also no clue yet, if it is accesible from here
var use_filter := false # Simply a private field of inspector, with this value given in editor_inspector.h
var use_folding := false # Simply a private field of inspector, with this value given in editor_inspector.h (don't know who sets it to true later)
var read_only := false # Simply a private field of inspector, with this value given in editor_inspector.h (don't know who sets it to true later)
var hide_script = false # Simply a property of the inspector class in Godot engine code

var editor_interface: EditorInterface
var print_debug_info := false

var property_prefix := "" # Used for sectioned inspector (@editor_inspector.h). So not in our case

func get_inspector_property_list(object: Object, add_additional_info: bool = true):
	var log := _get_debug_log()
	log.clear()

	var feature_profile := _get_current_feature_profile()
	var gfx_is_low_end := _is_gfx_low_end()

	var property_list := _get_reversed_property_list(object)

	# Source: editor_inspector.cpp / EditorInspector::update_tree()
	# https://github.com/godotengine/godot/blob/543750a1b3f5696f9ba8e91cb49dc7db05d2ae62/editor/editor_inspector.cpp#L2675
	var group: String = ""
	var group_base: String = ""
	var subgroup: String = ""
	var subgroup_base: String = ""
	var section_depth := 0

	var category_container: _PropertyContainer = null # In inspector's code: VBoxContainer *category_vbox = nullptr;
	var containers: Array[_PropertyContainer] = [] # In inspector code: main_vbox
	var container_per_path := { } # In inspector's code: HashMap<VBoxContainer *, HashMap<String, VBoxContainer *>> vbox_per_path;
	var array_per_prefix := { } # In inspector's code: HashMap<String, EditorInspectorArray *>

	var script_category_container: _PropertyContainer = null
	var metadata_category_container: _PropertyContainer = null

	var category_property: Dictionary
	var group_property: Dictionary
	var subgroup_property: Dictionary

	var properties_to_end: Array[Dictionary] = []
	for p in property_list:
		if p.name == "script":
			properties_to_end.append(p)
	for p in properties_to_end:
		property_list.erase(p)
		property_list.append(p)
	properties_to_end = []
	for p in property_list:
		if p.name.begins_with("metadata/"):
			properties_to_end.append(p)
	for p in properties_to_end:
		property_list.erase(p)
		property_list.append(p)

	for p in property_list:
		if add_additional_info:
			p["label"] = p.name
			p["path"] = p.name
			p["level"] = 1

		if print_debug_info:
			log.print_colored("Lightgreen", "\tContainers:" + (" none" if containers.size() == 0 else ""))
			_print_containers_debug_info(log, containers)
			log.print_colored("Lightslategray" ,"(%d) %s" % [property_list.find(p), _property_description_to_string(p)])

		if p.usage & PROPERTY_USAGE_SUBGROUP != 0:
			subgroup = p.name
			var hint_parts = p.hint_string.split(",")
			subgroup_base = hint_parts[0] if hint_parts.size() >= 0 else ""
			# Inspector's source read section depth here from hint_part[1] (or 0 by default).
			# We don't do it (yet), as it seems its only used for GUI purposes
			subgroup_property = p
			continue
		if p.usage & PROPERTY_USAGE_GROUP != 0:
			group = p.name
			var hint_parts = p.hint_string.split(",")
			group_base = hint_parts[0] if hint_parts.size() >= 0 else ""
			subgroup = ""
			subgroup_base = ""
			# Inspector's source read section depth here from hint_part[1] (or 0 by default).
			# We don't do it (yet), as it seems its only used for GUI purposes
			group_property = p
			continue
		if p.usage & PROPERTY_USAGE_CATEGORY != 0:
			group = ""
			group_base = ""
			subgroup = ""
			subgroup_base = ""
			# In inspector's code: Continue, if show_cetagories is false.
			# In inspector's code: Continue, if it's the "MultiNodeEdit" category of MultiNodeEdit
			# In inspector's code: Check if category is empty, and continue (skip it). Let's check this in the end.

			# Below from condition we skip the original is_type_recognized part, as it is not implemented here correctly
			if p.hint_string.length() > 0 and ResourceLoader.exists(p.hint_string):
				var scr := ResourceLoader.load(p.hint_string) as Script
				if is_instance_valid(scr):
					var script_class_name := _get_script_class_name(scr)
					if script_class_name != "":
						if add_additional_info:
							p["label"] = script_class_name
			# As last steps inspector's course code deal with icons and documetation here.
			# We skip it, as we don't need those (yet)
			category_container = null
			category_property = p
			continue
		if p.name.begins_with("metadata/_"):
			continue;
		if p.usage & PROPERTY_USAGE_EDITOR == 0 \
				or p.usage & PROPERTY_USAGE_EDITOR == 0 \
				or _is_property_disabled_by_feature_profile(object, p.name, feature_profile) \
				or (filter == "" and restrict_to_basic and p.usage & PROPERTY_USAGE_EDITOR_BASIC_SETTING != 0):
			continue

		if p.usage & PROPERTY_USAGE_HIGH_END_GFX != 0 and gfx_is_low_end:
			# Do not show this property in low end gfx.
			continue;

		if p.name == "script" and (hide_script or _call_method_if_exists(object, "_hide_script_from_inspector", false) == true):
			# Hide script variables from inspector if required.
			continue

		if p.name.begins_with("metadata/") and _call_method_if_exists(object, "_hide_metadata_from_inspector", false) == true:
			# Hide metadata from inspector if required.
			continue

		if p.name == "script":
			# Script should go into its own category
			# In inspector's code, it is simly reset the category container, and let latr code to make it.
			# We make an explicit one, to keep the structure.
			# (Other wise script would go to the last category, which is usually Node or RefCount)
			if script_category_container == null:
				script_category_container = _PropertyContainer.new(null, "", "", 0)
				containers.append(script_category_container)
			category_container = script_category_container

		# Below code is not done by inspector's source, but didn't find where it solve to put metadata to the end
		if p.name.begins_with("metadata/"):
			if metadata_category_container == null:
				metadata_category_container = _PropertyContainer.new(null, "", "", 0)
				containers.append(metadata_category_container)
			category_container = metadata_category_container

		var path: String = p.name
		var path_owner: Array[Dictionary] = [p]

		var array_prefix := ""
		var array_index := -1
		if print_debug_info:
			log.print("\tarray_per_prefix.keys = " + str(array_per_prefix.keys()))
			for key in array_per_prefix:
				log.print("\t\t" + key + " -> " + str(array_per_prefix[key]))
		for key in array_per_prefix:
			if p.name.begins_with(key) and key.length() > array_prefix.length():
				array_prefix = key
				if print_debug_info:
					log.print("\tarray_prefix = %s" % array_prefix)

		if not array_prefix.is_empty():
			var str: String = p.name.trim_prefix(array_prefix)
			var to_char_index := 0
			while to_char_index < str.length():
				if not (str[to_char_index] >= "0" and str[to_char_index] <= "9"): # this is the "is_digit" function in char_utils.h
					break
				to_char_index += 1
			if to_char_index > 0:
				array_index = str.left(to_char_index).to_int();
				if print_debug_info:
					log.print("\tarray_index = %s" % array_index)
			else:
				array_prefix = "";
				if print_debug_info:
					log.print("\tarray_prefix = %s (as no index found)" % array_prefix)

		if not array_prefix.is_empty():
			path = path.trim_prefix(array_prefix)
			var char_index := path.find("/");
			if char_index >= 0:
				path = path.right(-char_index - 1)
			else:
				path = &"Element %s" % array_index
		else:
			# Check if we exit or not a subgroup. If there is a prefix, remove it from the property label string.
			if not subgroup.is_empty() and not subgroup_base.is_empty():
				if path.begins_with(subgroup_base):
					path = path.trim_prefix(subgroup_base)
				elif subgroup_base.begins_with(path):
					pass # Keep it, this is used pretty often.
				else:
					subgroup = "" # The prefix changed, we are no longer in the subgroup.

			# Check if we exit or not a group. If there is a prefix, remove it from the property label string.
			if not group.is_empty() and not group_base.is_empty() and subgroup.is_empty():
				if path.begins_with(group_base):
					path = path.trim_prefix(group_base);
				elif group_base.begins_with(path):
					pass # Keep it, this is used pretty often.
				else:
					group = "" # The prefix changed, we are no longer in the group.
					subgroup = ""

			# Add the group and subgroup to the path.
			if not subgroup.is_empty():
				path = subgroup + "/" + path
				path_owner.push_front(subgroup_property)
			if not group.is_empty():
				path = group + "/" + path
				path_owner.push_front(group_property)

		if print_debug_info:
			log.print("\tpath = %s" % path)
		if add_additional_info:
			p["path"] = path

		# Get the property label's string.
		var name_override := path.substr(path.rfind("/") + 1) if path.contains("/") else path;
		var feature_tag: String
		var dot := name_override.find(".");
		if dot >= 0:
			feature_tag = name_override.substr(dot);
			name_override = name_override.substr(0, dot);

		var property_label_string = InspectorArchitect.Utils.capitalize_property_name(name_override) + feature_tag;
		if print_debug_info:
			log.print_rich("\tproperty_label_string = [b]%s[/b]" % property_label_string)
		if add_additional_info:
			p["label"] = property_label_string

		# Remove the property from the path.
		var idx := path.rfind("/")
		if idx > -1:
			path = path.left(idx)
			path_owner.remove_at(path_owner.size() - 1)
		else:
			path = ""
			path_owner = []

		# Ignore properties that do not fit the filter.
		if use_filter && not filter.is_empty():
			var property_path := property_prefix + ("" if path.is_empty() else path + "/") + name_override;
			if not InspectorArchitect.Utils.property_path_matches(property_path, filter):
				continue

		# Recreate the category container if it was reset.
		if category_container == null:
			category_container = _PropertyContainer.new(category_property, category_property.name, category_property.label, 0)
			containers.append(category_container)

		# Find the correct section/vbox to add the property editor to.
		var root_container: _PropertyContainer
		if array_prefix.is_empty():
			root_container = category_container
			if print_debug_info:
				log.print_verbose("\troot_container = category_container = (%s) %s" % [containers.find(root_container), root_container])
		else:
			if array_per_prefix.has(array_prefix):
				root_container = array_per_prefix[array_prefix]
				if print_debug_info:
					log.print_verbose("\troot_container = array_per_prefix[array_prefix] = (%s) %s" % [containers.find(root_container), root_container])
			else:
				continue

		if not container_per_path.has(root_container):
			container_per_path[root_container] = { }
			container_per_path[root_container][""] = root_container
		
		if print_debug_info:
			for container_key in container_per_path:
				for path_key in container_per_path[container_key]:
					log.print_verbose("\tcontainer_key[%d][\"%s\"] = %s" % [container_key.get_instance_id(), path_key, container_per_path[container_key][path_key]])

		var current_container := root_container
		var acc_path := ""
		var level := 1

		var components := path.split("/")
		for i in components.size():
			var component := components[i]
			acc_path += "/" + component if i > 0 else component
			if not container_per_path[root_container].has(acc_path):
				# In inspector's code, here comes, the code which setup the label for the category/group
				# We just make a new container
				var label := InspectorArchitect.Utils.capitalize_property_name(component)
				container_per_path[root_container][acc_path] = _PropertyContainer.new(path_owner[i] if i < path_owner.size() else null, component, label, level)
				if print_debug_info:
					log.print_verbose("\t-> container_key[%d][\"%s\"] = %s" % [root_container.get_instance_id(), acc_path, "new"])
				containers.append(container_per_path[root_container][acc_path])

			if print_debug_info:
				log.print_verbose("\t<- root_container = %d, acc_path = \"%s\"" % [root_container.get_instance_id(), acc_path])
			current_container = container_per_path[root_container][acc_path]
			#level = min(level + 1, 4)
			level = level + 1 # We do not restrict as inspector's code, as we use it to recover full structure, and not for GUI formatting

		if add_additional_info:
			p["level"] = level

		if print_debug_info:
			log.print("\tcurrent_container = (%d) \"%s\" %s" % [containers.find(current_container), current_container.name, current_container])

		if p.usage & PROPERTY_USAGE_ARRAY != 0:
			# In inspector code here comes the setup for the editor of the array
			# GUI element creation is not brought here, but processing the property inof replicated,
			# even if it's not used, it can be usefull in future
			var array_element_prefix: String
			var class_name_components = p["class_name"].split(",")

			var page_size := 5;
			var movable := true;
			var numbered := false;
			var foldable := use_folding
			var add_button_text := &"Add Element"
			var swap_method: String
			for i in class_name_components.size():
				if p.type == TYPE_NIL:
					if i < 1: continue
				else:
					if i < 2: continue
				if class_name_components[i].begins_with("page_size") and class_name_components[i].get_slice_count("=") == 2:
					page_size = class_name_components[i].get_slice("=", 1).to_int();
				elif class_name_components[i].begins_with("add_button_text") and class_name_components[i].get_slice_count("=") == 2:
					add_button_text = class_name_components[i].get_slice("=", 1).strip_edges();
				elif class_name_components[i] == "static":
					movable = false;
				elif class_name_components[i] == "numbered":
					numbered = true;
				elif class_name_components[i] == "unfoldable":
					foldable = false;
				elif class_name_components[i].begins_with("swap_method") and class_name_components[i].get_slice_count("=") == 2:
					swap_method = class_name_components[i].get_slice("=", 1).strip_edges();

			var add_to_list := false
			if p.type == TYPE_NIL:
				array_element_prefix = class_name_components[0]
				var array_label = InspectorArchitect.Utils.capitalize_property_name(property_label_string)
				if print_debug_info:
					log.print("\tarray_element_prefix = %s" % array_element_prefix)
					log.print("\tarray_label = %s" % array_label)
				add_to_list = true
			elif p.type == TYPE_INT:
				if class_name_components.size() >= 2:
					array_element_prefix = class_name_components[1]
					if print_debug_info:
						log.print("\tarray_element_prefix = %s" % array_element_prefix)
					add_to_list = true

			if add_to_list:
				var array_container := _PropertyContainer.new(p, p.name, p.label, level)
				current_container.elements.append(array_container)
				array_per_prefix[array_element_prefix] = array_container

			continue

		# These one again not used, but put here, to remember and see what inspector code processes, once it's needed
		var checkable := false
		var checked := false
		if p.usage & PROPERTY_USAGE_CHECKABLE != 0:
			checkable = true
			checked = (p.usage & PROPERTY_USAGE_CHECKED != 0)

		var property_read_only = (p.usage & PROPERTY_USAGE_READ_ONLY) != 0 or read_only

		# Mark properties that would require an editor restart (mostly when editing editor settings).
		if p.usage & PROPERTY_USAGE_RESTART_IF_CHANGED != 0:
			#restart_request_props.insert(p.name)
			pass

		# Here comes a huge code part in inspector's source dealing with docs

		# And here comes the code in inspector'ss oruce, where it chooses a property aditor

		if print_debug_info:
			log.print_verbose("\t* current_container = (%d) %s" % [containers.find(current_container), current_container])
		current_container.elements.append(p)

	if true or print_debug_info:
		_print_containers_debug_info(log, containers)

	# TODO: put property list together from containers
#	inspector_property_list.append_array(end_of_list_exceptions)

	var inspector_property_list: Array[Dictionary] = []
	for container in containers:
		_extract_properties_from_container(container, inspector_property_list)

	if true or print_debug_info:
		log.print_rich(_property_list_to_table(inspector_property_list))
	return property_list

func _extract_properties_from_container(container: _PropertyContainer, property_list: Array[Dictionary]):
	if container.owner != null and not container.owner.is_empty():
		property_list.append(container.owner)
	_extract_properties_from_elements(container.elements, property_list)
	
func _extract_properties_from_elements(elements: Array, property_list: Array[Dictionary]):
	for e in elements:
		if e is Dictionary and not e.is_empty():
			property_list.append(e)
		if e is _PropertyContainer:
			_extract_properties_from_container(e, property_list)

