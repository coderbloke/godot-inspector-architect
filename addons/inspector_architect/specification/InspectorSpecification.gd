@tool
class_name InspectorSpecification extends Resource

var connected_plugins: Array[InspectorObjectEditorSpecification] = []
@export var plugins: Array[InspectorObjectEditorSpecification] = []:
	set(value):
		if plugins != null:
			for connected_plugin in connected_plugins:
				connected_plugin.changed.disconnect(emit_changed)
			connected_plugins.clear()
		plugins = value
		if plugins != null:
			for child in plugins:
				if child == null:
					continue
				child.changed.connect(emit_changed)
				connected_plugins.append(child)

