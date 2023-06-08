@tool
class_name InspectorInsertPosition extends Resource

enum Position {
	BEFORE, BEGINNING, END, AFTER
}
enum AnchorType {
	INSPECTOR, CATEGORY, GROUP, PROPERTY
}

@export var position: Position = Position.END:
	set(new_value):
		if new_value != position:
			position = new_value
			emit_changed()
			
@export var anchor_type: AnchorType = AnchorType.INSPECTOR:
	set(new_value):
		if new_value != anchor_type:
			anchor_type = new_value
			emit_changed()

@export var anchor: String:
	set(new_value):
		if new_value != anchor:
			anchor = new_value
			emit_changed()

