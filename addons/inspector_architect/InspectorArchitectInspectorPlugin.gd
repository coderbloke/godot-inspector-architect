@tool
extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
	print("[_can_handle] object = %s" % [object])
	return true

func _parse_begin(object: Object) -> void:
	print("[_parse_begin] object = %s" % [object])

func _parse_category(object: Object, category: String) -> void:
	print("[_parse_category] object = %s, category = \"%s\"" % [object, category])

func _parse_end(object: Object) -> void:
	print("[_parse_end] object = %s" % [object])

func _parse_group(object: Object, group: String) -> void:
	print("[_parse_group] object = %s, group = \"%s\"" % [object, group])

func _parse_property(object: Object, type: Variant.Type, name: String,
		hint_type: PropertyHint, hint_string: String,
		usage_flags: PropertyUsageFlags, wide: bool) -> bool:
	print("[_parse_property] object = %s, type = %s, name = \"%s\"," % [object, InspectorArchitect.enum_to_string(InspectorArchitect.VariantType, type), name])
	print("                  hint_type = %s, hint_string = \"%s\"," % [InspectorArchitect.enum_to_string(InspectorArchitect.PropertyHint, hint_type), hint_string])
	print("                  usage_flags = %s, wide = %s" % [InspectorArchitect.flags_to_string(InspectorArchitect.PropertyUsageFlags, usage_flags), wide])
	return false
