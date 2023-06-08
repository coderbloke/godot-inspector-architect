@tool
extends EditorInspectorPlugin

var main_plugin: EditorPlugin

var debug_info_enabled := false

var inspector_object_editor_generator := preload("inspector_object_editor_generator.tres")
var inspector_object_editor_script: Script
var object_editors = { }

func _init():
	inspector_object_editor_generator.changed.connect(_update_object_editor_script)
	_update_object_editor_script()
	
func _update_object_editor_script():
	inspector_object_editor_script = inspector_object_editor_generator.get_object_editor_script()

func _get_debug_log() -> DebugInfoLog:
	var log := DebugInfo.get_log("inspector_architect", "Inspector Architect")
#	log.redirect_to_main = true
	return log

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
		var inspector_structure := InspectorArchitect.Types.InspectorStructure.new()
		inspector_structure.editor_interface = main_plugin.get_editor_interface()
		property_list = inspector_structure.get_inspector_property_list(object)
	debug_info_enabled = false
	
	var can_handle: bool = inspector_object_editor_script.call("_can_handle", object)
	return can_handle

func _parse_begin(object: Object) -> void:
	if true and debug_info_enabled:
		var debug_info := "[_parse_begin] object = %s" % [object]
		var property_list = object.get_property_list()
		var inspector_structure := InspectorArchitect.Types.InspectorStructure.new()
		inspector_structure.editor_interface = main_plugin.get_editor_interface()
		property_list = inspector_structure.get_inspector_property_list(object)
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
		
	var can_handle: bool = inspector_object_editor_script.call("_can_handle", object)
	if can_handle:
		var object_editor = inspector_object_editor_script.new()
		object_editor.object = object
		object_editor.inspector = self
		object_editors[object] = object_editor

func _parse_category(object: Object, category: String) -> void:
	if true and debug_info_enabled:
		_debug_info("[_parse_category] object = %s, category = \"%s\"" % [object, category])

	if object_editors.has(object):
		object_editors[object]._parse_category(object, category)

func _parse_end(object: Object) -> void:
	if true and debug_info_enabled:
		_debug_info("[_parse_end] object = %s" % [object])

	if object_editors.has(object):
		object_editors[object]._parse_end(object)
		object_editors.erase(object)
		

func _parse_group(object: Object, group: String) -> void:
	if true and debug_info_enabled:
		_debug_info("[_parse_group] object = %s, group = \"%s\"" % [object, group])

	if object_editors.has(object):
		object_editors[object]._parse_group(object, group)

func _parse_property(object: Object, type: Variant.Type, name: String,
		hint_type: PropertyHint, hint_string: String,
		usage_flags: PropertyUsageFlags, wide: bool) -> bool:
	if true and debug_info_enabled:
		_debug_info("[_parse_property] object = %s, type = %s, name = \"%s\"," % [object, InspectorArchitect.enum_to_string(InspectorArchitect.VariantType, type), name]
				+ "\nhint_type = %s, hint_string = \"%s\"," % [InspectorArchitect.enum_to_string(InspectorArchitect.PropertyHint, hint_type), hint_string]
				+ "\nusage_flags = %s, wide = %s" % [InspectorArchitect.flags_to_string(InspectorArchitect.PropertyUsageFlags, usage_flags), wide])

	if object_editors.has(object):
		var handled = object_editors[object]._parse_property(object, type, name,
			hint_type, hint_string,
			usage_flags, wide)
		if handled:
			return true
	return false
