-- utils/config.t
--
-- save/load configuration files

local class = require("class")
local json = require("lib/json.lua")
local m = {}

local Config = class("Config")
m.Config = Config

function Config:init(opts)
  if not opts then truss.error("opts must be provided to config") end
  local orgname = opts.orgname
  local appname = opts.appname
  local default_settings = opts.defaults
  if not default_settings then 
    truss.error("Config must be provided defaults for all settings!")
  end
  self._settings = default_settings
  self._orgname = orgname
  self._appname = appname
  self._global_save = opts.use_global_save_dir
  if self._orgname and (not self._global_save) then
    log.warn("Config does not use orgname without use_global_save_dir")
  end
  if self._global_save and ((not self._orgname) or (not self._appname)) then
    truss.error("Both appname and orgname must be provided with use_global_save_dir")
  end
  self._forbidden = {}
  -- save all existing keys in self so they can't be overwritten
  for k, v in pairs(self) do
    self._forbidden[k] = true
  end
  for k,v in pairs(default_settings) do
    if self._forbidden[k] then 
      truss.error("Cannot use " .. k .. " as a configuration key.") 
    end
    self[k] = v
  end
end

function Config:_get_save_path(fn)
  local fullfn = fn or "cfg.json"
  if self._global_save then
    truss.set_app_directories(self._orgname, self._appname)
    return fullfn
  else
    return self._appname .. "_" .. fullfn
  end
end

function Config:_get_load_path(fn)
  local fullfn = fn or "cfg.json"
  if self._global_save then
    truss.set_app_directories(self._orgname, self._appname)
    return "writedir/" .. fullfn
  else
    return self._appname .. "_" .. fullfn
  end
end

function Config:load(configfile)
  local fullfn = self:_get_load_path(configfile)
  local data = truss.load_string(fullfn)
  if data then
    local new_settings = json:decode(data)
    log.info("Loaded config: " .. fullfn)
    for k, default_val in pairs(self._settings) do
      -- can't do "new_settings[k] or default_val" because false
      -- always gets clobbered by default value
      if new_settings[k] ~= nil then
        self[k] = new_settings[k]
      else 
        self[k] = default_val
      end
    end
  else
    log.info("Config file " .. fullfn .. " not found.")
  end
  return self
end

function Config:save(configfile)
  local fullfn = self:_get_save_path(configfile)
  local s = {}
  for k,v in pairs(self._settings) do
    s[k] = self[k]
  end
  truss.save_string(fullfn, json:encode_pretty(s))
  return self
end

return m