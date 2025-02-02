extends Node

@export var openai_http: HTTPRequest
@export var notion_http: HTTPRequest

var notion_api_key: String = OS.get_environment("NOTION_API_KEY")
var notion_api_url: String = "https://api.notion.com/v1/"

var notion_ids: Dictionary


var openai_api_key: String = OS.get_environment("OPENAI_API_KEY")
var openai_api_url: String = "https://api.openai.com/v1/chat/completions"
var openai_headers: PackedStringArray = ["Content-Type: application/json", "Authorization: Bearer " + openai_api_key]
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
var user_prompt: String = ""
var messages: Array = [
	{ "role": "system", "content": system_prompt }
]

func _ready() -> void:
	# callGPT("testing. respond with success.") -> Success.
	load_notion_ids()
	pass

func load_notion_ids() -> void:
	var file = FileAccess.open("res://.notion-ids", FileAccess.READ)
	if file:
		print(".notion-ids file found!")
		var json = JSON.new()
		var err = json.parse(file.get_as_text())
		if err != OK:
			print("[json parse error] check debugger for more info")
			push_error("JSON parse error: %s" % json.get_error_message())
			return		
		notion_ids = json.data
		print(notion_ids)
		print("keys: ", notion_ids.keys())
		print("values: ", notion_ids.values())
	else:
		push_error("couldn't find .notion-ids file in root folder!")
	

func callGPT(user_prompt) -> void:
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
	if send_request != OK:
		print("Send request failed! :( Error Code: " + str(send_request))

func _on_open_ai_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	if parse_error == OK:
		var response = json.get_data()
		print("Full response: \n", response)
		
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
