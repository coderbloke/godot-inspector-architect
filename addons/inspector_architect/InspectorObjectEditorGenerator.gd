@tool
class_name InspectorObjectEditorGenerator extends Resource

@export var code_generator_specification: CodeGeneratorSpecification
@export var inspector_specification: InspectorSpecification

@export var trigger_update: bool = false:
	set(new_value):
		if new_value == true: 
			emit_changed()
		trigger_update = false

func get_object_editor_source_code() -> String:
	if inspector_specification != null and code_generator_specification != null:
		return CodeGenerator.generate_source_code(code_generator_specification, self)
	return ""
		
func get_object_editor_script() -> Script:
	var source_code = get_object_editor_source_code()
	if not source_code.is_empty():
		var script := GDScript.new()
		script.source_code = CodeGenerator.generate_source_code(code_generator_specification, self)
		script.reload()
		return script
	return null

func _get_first_object_editor_specification() -> InspectorObjectEditorSpecification:
	if inspector_specification == null:
		return null
	if inspector_specification.plugins == null:
		return null
	if inspector_specification.plugins.size() == 0:
		return null
	return inspector_specification.plugins[0]

func _get_declarations() -> String:
	var object_editor_specification := _get_first_object_editor_specification()
	if object_editor_specification == null:
		return ""
	
	var code_snippets: PackedStringArray = [ "var object: Object # Coming from caller plug-in" ]
	var s = object_editor_specification.declarations
	if not s.is_empty(): code_snippets.append(s.trim_suffix("\n"))
	for action in object_editor_specification.parse_actions:
		s = action.declarations
		if not s.is_empty(): code_snippets.append(s.trim_suffix("\n"))

	return "\n\n".join(code_snippets)

func _get_initialization() -> String:
	var object_editor_specification := _get_first_object_editor_specification()
	if object_editor_specification == null:
		return ""
	
	var code_snippets: PackedStringArray = [ ]
	var s = object_editor_specification.initialization
	if not s.is_empty(): code_snippets.append(s.trim_suffix("\n"))
	for action in object_editor_specification.parse_actions:
		s = action.initialization
		if not s.is_empty(): code_snippets.append(s.trim_suffix("\n"))

	return "\n\n".join(code_snippets)
	
func _get_can_handle() -> String:
	var object_editor_specification := _get_first_object_editor_specification()
	if object_editor_specification == null:
		return ""
	
	var code_snippets: PackedStringArray = [ ]
	var s = object_editor_specification.object_filter.acceptance_check
	if not s.is_empty(): code_snippets.append(s.trim_suffix("\n"))

	return "\n\n".join(code_snippets)

func _get_parse_property() -> String:
	var object_editor_specification := _get_first_object_editor_specification()
	if object_editor_specification == null:
		return ""
	
	var code_snippets: PackedStringArray = [ ]
	for action in object_editor_specification.parse_actions:
		var s = action.action
		if not s.is_empty(): code_snippets.append(s.trim_suffix("\n"))

	return "\n\n".join(code_snippets)

