extends Node

@export var openai_http: HTTPRequest
@export var notion_http: HTTPRequest

var notion_api_key: String = OS.get_environment("NOTION_API_KEY")
var notion_api_url: String = "https://api.notion.com/v1/" # varies based on request type
var notion_ids: Dictionary
var notion_headers: PackedStringArray = [
	"Content-Type: application/json", 
	"Notion-Version: 2022-06-28", 
	"Authorization: Bearer " + notion_api_key
]

# https://developers.notion.com/reference/block
var block_type: Dictionary = { # omit 4, 5, 8, 17, 18, 21, 24, 26, 28, check notes
	1: {
		"type": "bookmark",
		"bookmark": {
			"caption": [],
			"url": "https://legacynical.com/hello"
		}
	},
	2: {
		"type": "bulleted_list_item",
		"bulleted_list_item": {
			"rich_text": [{
				"type": "text",
				"text": {
					"content": "Legacynical",
					"link": null
				}
			}],
			"color": "default"
		}
	},
	3: {
		"type": "callout",
		"callout": {
			"rich_text": [{
				"type": "text",
				"text": {
					"content": "Legacynical",
					"link": null
				}
			}],
			"icon": {
				"emoji": "⭐"
			},
			"color": "default"
		}
	},
	# NOTE: for 'child_database' blocks, use create database & update database endpoints with specified parent page ID
	#4: {
		#"type": "child_database",
		#"child_database": {
			#"title": "My database"
		#}
	#},
	# NOTE: for 'child_page' blocks, use create page and update page endpoints with specified parent page ID
	#5: {
		#"type": "child_page",
		#"child_page": {
			#"title": "Legacynical"
		#}
	#},
	6: {
		"type": "code",
		"code": {
			"caption": [],
			"rich_text": [{
				"type": "text",
				"text": {
					"content": "const answer = 42"
				}
			}],
			"language": "python"
		}
	},
# NOTE: for appending 'column_list' blocks, 'column_list' must have as least 2 'column's each w/ at
# least 1 child
	7: {
		"type": "column_list",
		"column_list": {
			"children": [
				{
					"type": "column",
					"column": {
						"children": [
							{
								"type": "paragraph",
								"paragraph": {
									"rich_text": [{
										"type": "text",
										"text": {
											"content": "Column 1",
											"link": null
										}
									}],
									"color": "default"
								}
							}
						]
					}
				},
				{
					"type": "column",
					"column": {
						"children": [
							{
								"type": "paragraph",
								"paragraph": {
									"rich_text": [{
										"type": "text",
										"text": {
											"content": "Column 2",
											"link": null
										}
									}],
									"color": "default"
								}
							}
						]
					}
				}
			]
		}
	},
	# NOTE: column block should be a child of column_list (7)
	#8: {
		#"type": "column",
		#"column": {
			#"children": []
		#}
	#},
	9: {
		"type": "divider",
		"divider": {}
	},
	10: {
		"type": "embed",
		"embed": {
			"url": "https://legacynical.com/hello"
		}
	},
	11: {
		"type": "equation",
		"equation": {
			"expression": "e=mc^2"
		}
	},
	12: {
		"type": "file",
		"file": {
			"caption": [],
			"type": "external",
			 "external": {
				"url": "https://pbs.twimg.com/profile_images/1322602546733568000/tz4SytsV_400x400.jpg"
			},
			"name": "doc.txt"
		}
	},
	13: {
		"type": "heading_1",
		"heading_1": {
			"rich_text": [{
				"type": "text",
				"text": {
					"content": "Legacynical",
					"link": null
				}
			}],
			"color": "default",
			"is_toggleable": false
		}
	},
	14: {
		"type": "heading_2",
		"heading_2": {
			"rich_text": [{
				"type": "text",
				"text": {
					"content": "Legacynical",
					"link": null
				}
			}],
			"color": "default",
			"is_toggleable": false
		}
	},
	15: {
		"type": "heading_3",
		"heading_3": {
			"rich_text": [{
				"type": "text",
				"text": {
					"content": "Legacynical",
					"link": null
				}
			}],
			"color": "default",
			"is_toggleable": false
		}
	},
	16: {
		"type": "image",
		"image": {
			"type": "external",
			"external": {
				"url": "https://pbs.twimg.com/profile_images/1322602546733568000/tz4SytsV_400x400.jpg"
			}
		}
	},
	# NOTE: No API support for creating/appending link_preview blocks, can only be retrieved
	#17: {
		#"type": "link_preview",
		#"link_preview": {
			#"url": ""
		#}
	#},
	# NOTE: mentions require initialization of ids or parsing from a search response
	# Mention block, represents any @ tag in the Notion UI- user, date, page, database, mini link preview
	#18: {
		#"type": "database", # refer to docs for all types
		#"database": { # subject to change based on mention type
			#"id": ""
		#}
	#},
	19: {
		"type": "numbered_list_item",
		"numbered_list_item": {
			"rich_text": [{
				"type": "text",
				"text": {
					"content": "Finish reading the docs",
					"link": null
				}
			}],
			"color": "default"
		}
	},
	20: {
		"type": "paragraph",
		"paragraph": {
			"rich_text": [{
				"type": "text",
				"text": {
					"content": "Legacynical",
					"link": null
				}
			}],
			"color": "default"
		}
	},
# NOTE: To test this I need a valid external pdf link, which I don't need for now.
	#21: {
		#"type": "pdf",
		#"pdf": {
			#"type": "external",
			#"external": {
				#"url": ""
			#}
		#}
	#},
	22: {
		"type": "quote",
		"quote": {
			"rich_text": [{
				"type": "text",
				"text": {
					"content": "I took the one less traveled by,\nAnd that has made all the difference.",
					"link": null
				},
			}],
			"color": "default"
		}
	},
	# NOTE: No API support for updating synced block content.
	23: { # original synced block
		"type": "synced_block",
		"synced_block": {
			"synced_from": null,
			"children": [{
				"callout": {
					"rich_text": [{
						"type": "text",
						"text": {
							"content": "Callout in synced block"
						}
					}]
				}
			}]
		}
	},
# NOTE: No API support for updating synced block content.
# Also requires valid 'block_id' to test
	#24: { # duplicate synced block
		#"type": "synced_block",
		#"synced_block": {
			#"synced_from": {
				#"block_id": "original_synced_block_id"
			#}
		#}
	#},
	# NOTE: table_width can only be set when the table is first created
	25: {
		"type": "table",
		"table": {
			"table_width": 3, # updates to change this will fail, create new instead
			"has_column_header": false,
			"has_row_header": false,
			"children": [{
				"type": "table_row",
				"table_row": {
					"cells": [
						[{
							"type": "text",
							"text": {
							"content": "column 1 content",
							"link": null
							},
							"annotations": {
								"bold": false,
								"italic": false,
								"strikethrough": false,
								"underline": false,
								"code": false,
								"color": "default"
							},
							"plain_text": "column 1 content",
							"href": null
						}],
						[{
							"type": "text",
							"text": {
							"content": "column 2 content",
							"link": null
							},
							"annotations": {
								"bold": false,
								"italic": false,
								"strikethrough": false,
								"underline": false,
								"code": false,
								"color": "default"
							},
							"plain_text": "column 2 content",
							"href": null
						}],
						[{
							"type": "text",
							"text": {
							"content": "column 3 content",
							"link": null
							},
							"annotations": {
								"bold": false,
								"italic": false,
								"strikethrough": false,
								"underline": false,
								"code": false,
								"color": "default"
							},
							"plain_text": "column 3 content",
							"href": null
						}]
					]
				}
			}]
		}
	},
	# NOTE: when creating a table block via append block children endpoint, 'table' must have 
	# at least one 'table_row' whose 'cells' array has the same length as 'table_width'
	# append as children under table block
	#26: {
		#"type": "table_row",
		#"table_row": {
			#"cells": [
				#[{
					#"type": "text",
					#"text": {
						#"content": "column 1 content",
						#"link": null
					#},
					#"annotations": {
						#"bold": false,
						#"italic": false,
						#"strikethrough": false,
						#"underline": false,
						#"code": false,
						#"color": "default"
					#},
					#"plain_text": "column 1 content",
					#"href": null
				#}],
				#[{
					#"type": "text",
					#"text": {
						#"content": "column 2 content",
						#"link": null
					#},
					#"annotations": {
						#"bold": false,
						#"italic": false,
						#"strikethrough": false,
						#"underline": false,
						#"code": false,
						#"color": "default"
					#},
					#"plain_text": "column 2 content",
					#"href": null
				#}],
				#[{
					#"type": "text",
					#"text": {
						#"content": "column 3 content",
						#"link": null
					#},
					#"annotations": {
						#"bold": false,
						#"italic": false,
						#"strikethrough": false,
						#"underline": false,
						#"code": false,
						#"color": "default"
					#},
					#"plain_text": "column 3 content",
					#"href": null
				#}]
			#]
		#}
	#},
	27: {
		"type": "table_of_contents",
		"table_of_contents": {
			"color": "default"
		}
	},
	# NOTE: creation of template blocks is no longer be supported since March 27, 2023
	# I'm still adding a dictionary entry as a placeholder just in case
	#28: {
		#"template": {
			#"rich_text": [{
				#"type": "text",
				#"text": {
					#"content": "Add a new to-do",
					#"link": null
				#},
				#"annotations": {
					#
				#},
				#"plain_text": "Add a new to-do",
				#"href": null
			#}]
		#}
	#},
	29: {
		"type": "to_do",
		"to_do": {
			"rich_text": [{
				"type": "text",
				"text": {
					"content": "Publish Polyfocus",
					"link": null
				}
			}],
			"checked": false,
			"color": "default",
		}
	},
	30: {
		"type": "toggle",
		"toggle": {
			"rich_text": [{
				"type": "text",
				"text": {
					"content": "Additional project details",
					"link": null
				}
			}],
			"color": "default",
		}
	},
	31: {
		"type": "video",
		"video": {
			"type": "external",
			"external": {
				"url": "https://www.youtube.com/watch?v=VzS7LjdrOEQ"
			}
		}
	}
}

# NOTE: 17 & 28 disabled
var append_blocks_test: PackedInt32Array = [ # omit 4, 5, 8, 17, 18, 21, 24, 26, 28, check notes in dict
	1, 2, 3, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 19, 20, 22, 23, 25, 27, 29, 30, 31
]

var openai_api_key: String = OS.get_environment("OPENAI_API_KEY")
var openai_api_url: String = "https://api.openai.com/v1/chat/completions"
var openai_headers: PackedStringArray = [
	"Content-Type: application/json", 
	"Authorization: Bearer " + openai_api_key
]
var openai_model: PackedStringArray = [
	"gpt-4o",
	"chatgpt-4o-latest",
	"gpt-4o-mini",
	"o1",
	"o1-mini",
	"o3-mini",
	"o1-preview",
	"gpt-4o-realtime-preview",
	"gpt-4o-mini-realtime-preview",
	"gpt-4o-audio-preview"
]
var selected_model = "gpt-4o-mini" # default to cheapest option, make the most out of my $5
var max_completion_tokens: int = 1024
var temperature: float = 0.5 # value between 0 and 2
var store: bool = true # to store chat completions in dev dashboard
var metadata: Dictionary = {
	"application": "godot-notion-interface",
	"version": "0.1.0-alpha"
}
var system_prompt: String = ""
var messages: Array = [
	{ "role": "system", "content": system_prompt }
]

func _ready() -> void:
	# callGPT("testing. respond with success.") -> Success.
	load_notion_ids()
	check_api_keys()
	#request_notion_retrieve_page(notion_ids["EXPLORATION_LOG_PAGE_ID"])
	#request_notion_retrieve_block_children(notion_ids["EXPLORATION_LOG_PAGE_ID"])
	request_notion_append_block_children(notion_ids["EXPLORATION_LOG_PAGE_ID"], append_blocks_test)

func load_notion_ids() -> void:
	var file = FileAccess.open("res://.notion-ids", FileAccess.READ)
	if file:
		print(".notion-ids file found!")
		var json = JSON.new()
		var err = json.parse(file.get_as_text())
		if err != OK:
			print("[json parse error] check debugger for more info")
			push_error("JSON parse error: %s" % json.get_error_message())
		notion_ids = json.data
		print(notion_ids)
		print("keys: ", notion_ids.keys())
		print("values: ", notion_ids.values())
	else:
		push_error("couldn't find .notion-ids file in root folder!")
	
# sends a text completions request to openai (prompt, optional param model) defaults to gpt-4o-mini
func request_open_ai_chat(user_prompt: String, selected_model: String = "gpt-4o-mini") -> void:
	messages.append(
		{ "role": "user", "content": user_prompt }
	)
	
	var body = JSON.stringify({
		"model": selected_model,
		"max_completion_tokens": max_completion_tokens,
		"temperature": temperature,
		"store": store,
		"metadata": metadata,
		"messages": messages
	})

	var send_request = openai_http.request(openai_api_url, openai_headers, HTTPClient.METHOD_POST, body)
	check_request_error(send_request)

func _on_open_ai_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	if parse_error == OK:
		var response = json.get_data()
		print("Result: ", result, "\nResponse code: ", response_code, "\nHeaders: ", headers)
		print("\nFull response: \n", response)
		
		if response.has("choices") and response["choices"].size() > 0:
			var choice = response["choices"][0]
			if choice.has("message") and choice["message"].has("content"):
				var message = choice["message"]["content"]
				print("Model Output: \n", message)
				messages.append({
					"role": "assistant",
					"content": message
				})
			else:
				push_error('Unexpected reponse. Wrong structure.')
		else:
			push_error('Unexpected responce. No "choices" in response.')
	else:
		push_error('Parse JSON failed. Error code: ' + str(parse_error))

##typical error response
# { "error": 
#	{
#	"message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.", 
#	"type": "insufficient_quota", 
#	"param": <null>, 
#	"code": "insufficient_quota" 
#	} 
# }

# NOTE: make sure to restart godot engine after setting an environment variable!
# I also had to restart my PC for OS.get_environment() to properly read
func check_api_keys() -> void: # helps prevent spooky ghost errors
	if notion_api_key == "":
		push_error("Environment variable NOTION_API_KEY not set!")
	elif openai_api_key == "":
		push_error("Environment variable OPENAI_API_KEY not set!")
	else:
		print("Environment keys loaded!")
	
func request_notion_retrieve_page(page_id: String): # GET
	var endpoint_url: String = "https://api.notion.com/v1/pages/" + page_id
	var send_request = notion_http.request(endpoint_url, notion_headers, HTTPClient.METHOD_GET)
	check_request_error(send_request)

# NOTE: a notion page is considered a block that can have block children, so page_id can be called
func request_notion_retrieve_block_children(block_id: String): # GET
	var endpoint_url: String = "https://api.notion.com/v1/blocks/" + block_id + "/children"
	var send_request = notion_http.request(endpoint_url, notion_headers, HTTPClient.METHOD_GET)
	check_request_error(send_request)

func request_notion_append_block_children(block_id: String, blocks: PackedInt32Array = [], after: String = ""): # PATCH
	var endpoint_url: String = "https://api.notion.com/v1/blocks/" + block_id + "/children"
	var children: Array = []
	for block in blocks:
		children.append(block_type[block])
	
	var body = JSON.stringify({
		"children": children
	})
	
	var send_request = notion_http.request(endpoint_url, notion_headers, HTTPClient.METHOD_PATCH, body)
	check_request_error(send_request)
	

func check_request_error(send_request) -> void:
	if send_request != OK:
		print("Send request failed! :( Error Code: " + str(send_request))
	

func _on_notion_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	if parse_error == OK:
		var response = json.get_data()
		print("Result: ", result, "\nResponse code: ", response_code, "\nHeaders: ", headers)
		print("\nFull response: \n", response)
	else:
		push_error('Parse JSON failed. Error code: ' + str(parse_error))
