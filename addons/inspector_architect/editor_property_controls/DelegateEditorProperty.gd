@tool
extends EditorProperty

var control: Control#:
#	set(value):
#		if control != null:
#			remove_child(control)
#		control = value
#		print("helló 4")
#		if control != null:
#			control.set("editor_property", self)
#			add_child(control)

func _init(control: Control, add_control: bool = true, add_to_bottom: bool = true):
	self.control = control
	control.set("editor_property", self)
	if add_control:
		add_child(control)
		if add_to_bottom:
			set_bottom_editor(control)

func _set_read_only(read_only):
	control.set("read_only", read_only)
	
func _update_property():
	if control.has_method("_update_property"):
		control.call("_update_property")
	pass
