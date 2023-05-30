@tool
class_name InspectorObjectFilter extends Resource

@export var accepted_classes: PackedStringArray = []:
	set(value):
		if value != accepted_classes:
			accepted_classes = value
			emit_changed()

@export_category("Script")
@export_multiline var acceptance_check: String = "":
	set(value):
		if value != acceptance_check:
			acceptance_check = value
			emit_changed()
