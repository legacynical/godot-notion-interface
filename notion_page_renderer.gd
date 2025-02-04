extends Control
class_name NotionPageRenderer

@export var api_manager: Node




func _ready() -> void:
	print(api_manager.notion_ids["EXPLORATION_LOG_PAGE_ID"])
	print(api_manager.notion_ids["EXPLORATION_PATHS_DATABASE_ID"])
	
