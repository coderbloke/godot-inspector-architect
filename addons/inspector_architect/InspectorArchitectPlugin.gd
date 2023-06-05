@tool
extends EditorPlugin

var inspector_plugin = InspectorArchitect.Types.InpectorPlugin.new()

func _enter_tree():
	inspector_plugin.main_plugin = self
	add_inspector_plugin(inspector_plugin)

func _exit_tree():
	inspector_plugin.main_plugin = null
	remove_inspector_plugin(inspector_plugin)
