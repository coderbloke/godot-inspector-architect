@tool
class_name InspectorInsertPosition extends Resource

enum Position {
	BEFORE, BEGINNING, END, AFTER
}
enum AnchorType {
	INSPECTOR, CATEGORY, GROUP, PROPERTY
}

@export var position: Position = Position.END
@export var anchor_type: AnchorType = AnchorType.INSPECTOR
@export var anchor: String

