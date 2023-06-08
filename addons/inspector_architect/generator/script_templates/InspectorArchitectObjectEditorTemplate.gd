@tool
extends RefCounted

var inspector: EditorInspectorPlugin

# _DECLARATIONS_

func _init():
	# _INITIALIZATION_ # generated code
	pass
	
static func _can_handle(object: Object) -> bool:
	# _CAN_HANDLE_
	return false

func _parse_begin(object: Object) -> void:
	# _PARSE_BEGIN_
	pass
	
func _parse_category(object: Object, category: String) -> void:
	# _PARSE_CATEGORY_
	pass
	
func _parse_end(object: Object) -> void:
	# _PARSE_END_
	pass
	
func _parse_group(object: Object, group: String) -> void:
	# _PARSE_GROUP_
	pass
	
func _parse_property(object: Object, type: Variant.Type, name: String,
		hint_type: PropertyHint, hint_string: String,
		usage_flags: PropertyUsageFlags, wide: bool) -> bool:
	# _PARSE_PROPERTY_
	return false
