@tool
class_name InspectorPluginSpecification extends Resource

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

@export var object_filter: InspectorObjectFilter = null:
	set(value):
		if object_filter != null:
			object_filter.changed.disconnect(emit_changed)
		object_filter = value
		if object_filter != null:
			object_filter.changed.connect(emit_changed)

var connected_actions: Array[InspectorParseAction] = []
@export var parse_actions: Array[InspectorParseAction] = []:
	set(value):
		if parse_actions != null:
			for connected_action in connected_actions:
				connected_action.changed.disconnect(emit_changed)
			connected_actions.clear()
		parse_actions = value
		if parse_actions != null:
			for child in parse_actions:
				if child == null:
					continue
				child.changed.connect(emit_changed)
				connected_actions.append(child)


