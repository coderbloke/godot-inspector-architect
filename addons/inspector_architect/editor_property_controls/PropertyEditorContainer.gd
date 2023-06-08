@tool
extends VBoxContainer

var header := HBoxContainer.new()
var property_name := Label.new()

var editor_property: EditorProperty:
	set(value):
		editor_property = value
		_update_property_name()
		_sync_with_editor_property()

var read_only: bool:
	set(value):
		if value != null:
			read_only = value
			_read_only_changed()

func _init():
	property_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(property_name)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(header)

func _update_property_name():
	property_name.text = editor_property.get_edited_property() if editor_property != null else ""
	
func _sync_with_editor_property():
	pass
	
func _read_only_changed():
	#_update_property_name()
	pass
	
func _update_property():
	_update_property_name()
