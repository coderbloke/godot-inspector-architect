@tool
extends EditorPlugin

var inspector_plugin = InspectorArchitect.Types.InpectorPlugin.new()

func _enter_tree():
	add_inspector_plugin(inspector_plugin)

func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
