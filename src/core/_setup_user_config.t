-- runs the user config file

local configfile = io.open("trussconfig.lua")

local default_config = {
  cpu_triple = "native",
  cpu_features = "",
  cpu_opt_profile = {},
  script_paths = {"src/"},
}

local config
if configfile then
  config = truss.extend_table({}, default_config)
  setmetatable(config, {__index = _G})
  configsrc = configfile:read("*a")
  configfile:close()
  local configfunc, configerr = loadstring(configsrc)
  if not configfunc then
    error("Error parsing config file:", configerr)
  end
  setfenv(configfunc, config)
  local happy, err = pcall(configfunc)
  if not happy then
    error("Error running config file:", err)
  end
  for k, v in pairs(config) do
    if not default_config[k] then
      error('Unexpected config key: "' .. k .. '"')
    end
  end
else
  config = default_config
end

if config.cpu_triple ~= "native" or config.cpu_features ~= "" then
  local triple = config.cpu_triple
  local features = config.cpu_features
  log.info("Using CPU triple:", triple)
  log.info("Using CPU features:", features)
  if triple == "native" then triple = nil end
  local opt_profile = assert(
    config.cpu_opt_profile, "config.cpu_opt_profile is missing!")
  terralib.nativetarget = terralib.newtarget{
    Triple = triple, 
    Features = features
  }
  terralib.jitcompilationunit = terralib.newcompilationunit(
    terralib.nativetarget, true, opt_profile)
end