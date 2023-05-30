@tool
extends EditorInspectorPlugin

var debug_info_enabled = false

func _debug_info(text: String):
	var debug_label := RichTextLabel.new()
	debug_label.add_theme_color_override("default_color", Color.LIGHT_BLUE)
	debug_label.add_theme_font_size_override("normal_font_size", 10)
	debug_label.text= text
	debug_label.fit_content = true
	add_custom_control(debug_label)

func _can_handle(object: Object) -> bool:
	if true and debug_info_enabled:
		print_rich("[color=LightBlue][_can_handle] object = %s, self = %s[/color]" % [object, self.get_instance_id()])
	return true

func _parse_begin(object: Object) -> void:
	if true and debug_info_enabled:
		var debug_info := "[_parse_begin] object = %s" % [object]
		var property_list = object.get_property_list()
		for p in property_list:
			#debug_info += "\n%s" % [p] 
			debug_info += "\n-\tname = \"%s\", class_name = \"%s\", type = %s," % [p.name, p["class_name"], InspectorArchitect.enum_to_string(InspectorArchitect.VariantType, p.type)] \
					+ "\n\thint = %s, hint_string = \"%s\"," % [InspectorArchitect.enum_to_string(InspectorArchitect.PropertyHint, p.get("hint", 0)), p.get("hint_string", "")] \
					+ " usage = %s" % [InspectorArchitect.flags_to_string(InspectorArchitect.PropertyUsageFlags, p.get("usage", 0))]
		_debug_info(debug_info)

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
