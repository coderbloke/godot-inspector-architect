@tool
extends "PropertyEditorContainer.gd"

var detach_button := Button.new()
var code_edit := CodeEdit.new()

func _init():
	super._init()
	code_edit.text_changed.connect(_on_text_changed)
	code_edit.scroll_fit_content_height = true
	add_child(code_edit)
	header.add_child(detach_button)

func _sync_with_editor_property():
	super._sync_with_editor_property()
	if editor_property != null:
		editor_property.add_focusable(code_edit)
	
func _notification(what):
	match what:
		NOTIFICATION_THEME_CHANGED, NOTIFICATION_ENTER_TREE:
			detach_button.icon = get_theme_icon("DistractionFree", "EditorIcons")

func _on_text_changed():
	if editor_property != null:
		editor_property.emit_changed(editor_property.get_edited_property(), code_edit.text)

func _update_property():
	super._update_property()
	var text := editor_property.get_edited_object().get(editor_property.get_edited_property())
	if text != code_edit.text:
		var caret_line = code_edit.get_caret_line()
		var caret_column = code_edit.get_caret_column()
		code_edit.text = text
		code_edit.set_caret_line(caret_line)
		code_edit.set_caret_column(caret_column)
