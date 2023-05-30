@tool
class_name InspectorParseAction extends Resource

@export_multiline var declarations: String = "":
	set(value):
		if value != declarations:
			declarations = value
			emit_changed()

@export_multiline var initialization: String = "":
	set(value):
		if value != initialization:
			initialization = value
			emit_changed()

@export var action_trigger: InspectorInsertPosition = null:
	set(value):
		if action_trigger != null:
			action_trigger.changed.disconnect(emit_changed)
		action_trigger = value
		if action_trigger != null:
			action_trigger.changed.connect(emit_changed)

@export_multiline var action: String = "":
	set(value):
		if value != action:
			action = value
			emit_changed()


