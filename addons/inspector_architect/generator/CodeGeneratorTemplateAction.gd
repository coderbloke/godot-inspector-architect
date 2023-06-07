@tool
class_name CodeGeneratorTemplateAction extends Resource

@export var tag: String
@export var comment_handling: CodeGenerator.CommentHandling
@export var action_method: String

@export var prefix_handling: CodeGenerator.PrefixHandling
@export var additional_indent: int = 0
@export var suffix_handling: CodeGenerator.SuffixHandling

