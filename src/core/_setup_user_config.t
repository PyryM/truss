-- runs the user config file

local configfile = io.open("trussconfig.lua")

local default_config = {
  cpu_triple = "native",
  cpu_features = "",
  cpu_opt_profile = {},
  script_paths = {"src/"},
  WORKDIR = truss.working_dir,
  BINDIR = truss.binary_dir,
  BINARY = truss.binary_name,
}

local function list_config_options()
  local config_options = {}
  for k, _ in pairs(default_config) do
    if k:upper() ~= k then table.insert(config_options, k) end
  end
  table.sort(config_options)
  log.error("Valid config options:")
  log.error(table.concat(config_options, "\n"))
end

local config = truss.extend_table({}, default_config)

if configfile then
  setmetatable(config, {
    __index = function(t, k)
      if _G[k] then return _G[k] end
      error('Config file referenced "' .. k .. '" which does not exist.')
    end,
    __newindex = function(t, k, v)
      log.error('Tried to set invalid config option "' .. k .. '"')
      list_config_options()
      error('Invalid config option "' .. k .. '"')
    end
  })
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
  setmetatable(config, nil)
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