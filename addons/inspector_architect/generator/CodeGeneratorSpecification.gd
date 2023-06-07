@tool
class_name CodeGeneratorSpecification extends Resource

const Action = preload("CodeGeneratorTemplateAction.gd")

@export_file var template: String
@export var comment_start: String
@export var comment_error_messages: bool = true

@export var template_actions: Array[Action]
