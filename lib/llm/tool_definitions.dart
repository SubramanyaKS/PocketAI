const List<Map<String, dynamic>> toolDefinitions = [
  {
    "name": "create_reminder",
    "description": "Create a reminder for the user with delay in minutes",
    "parameters": {
      "type": "object",
      "properties": {
        "title": {
          "type": "string",
          "description": "The title or action of the reminder"
        },
        "delay_minutes": {
          "type": "integer",
          "description": "Delay before firing the reminder in minutes"
        }
      },
      "required": ["title", "delay_minutes"]
    }
  },
  {
    "name": "torch_control",
    "description": "Controls the device flashlight / torch (turn on, turn off, or toggle)",
    "parameters": {
      "type": "object",
      "properties": {
        "action": {
          "type": "string",
          "enum": ["on", "off", "toggle"],
          "description": "Flashlight action to perform"
        }
      },
      "required": ["action"]
    }
  }
];
