-- Note: actions and action_sets should be sorted by .name
-- so that the tests will pass
return {
  default_bindings = {
    {
      controller_type = "vive_controller",
      binding_url = "vive_controller_bindings.json"
    }
  }, 
  actions = {
    {
      name = "/actions/driving/in/HonkHorn",
      requirement = "optional",
      type = "boolean"
    },
    {
      name = "/actions/driving/in/Throttle",
      requirement = "suggested",
      type = "vector1"
    },
    {
      name = "/actions/main/in/OpenInventory",
      requirement = "mandatory",
      type = "boolean"
    },
    {
      name = "/actions/main/in/RightHand",
      requirement = "suggested",
      type = "pose"
    }
  },
  action_sets = {
    {
      name = "/actions/driving",
      usage = "leftright"
    },
    {
      name = "/actions/main",
      usage = "leftright"
    }
  },
  localization = {
   {
      language_tag = "en",

      ["/actions/main"] = "My Game Actions",
      ["/actions/driving"] = "driving",

      ["/actions/main/in/OpenInventory"] = "Open Inventory",
      ["/actions/main/in/RightHand"] = "Right Hand",

      ["/actions/driving/in/HonkHorn"] = "Honk Horn",
      ["/actions/driving/in/Throttle"] = "Throttle"
    }
  }
}