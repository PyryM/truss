-- utils/config.t
--
-- save/load configuration files

local class = require("class")
local json = require("json")
local m = {}

local Config = class("Config")
m.Config = Config

function Config:init(orgname, appname, default_settings)
  self._settings = default_settings
  self.settings = {}
  for k,v in pairs(default_settings) do
    self.settings[k] = v
  end
end

function Config:load(configfile)
  truss.set_app_directories(orgname, appname)
  local fullfn = "writedir/" .. (configfile or "cfg.json")
  local new_settings = json:decode(truss.load_string(fullfn))
  for k, default_val in pairs(self._settings) do
    self.settings[k] = new_settings[k] or default_val
  end
  return self
end

function Config:save(configfile)
  truss.set_app_directories(orgname, appname)
  truss.save_string(configfile or "cfg.json", json:encode_pretty(self.settings))
  return self
end

return m