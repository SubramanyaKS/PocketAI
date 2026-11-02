const List<Map<String, dynamic>> toolDefinitions = [
  {
    "name": "create_reminder",
    "description": "Create a reminder for the user",
    "parameters": {
      "type": "object",
      "properties": {
        "title": {
          "type": "string"
        },
        "delay_minutes": {
          "type": "integer"
        }
      },
      "required": ["title", "delay_minutes"]
    }
  }
];