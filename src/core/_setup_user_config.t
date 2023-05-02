-- runs the user config file

local function install(truss)
  local log = truss.log
  local default_config = {
    cpu_triple = "native",
    cpu_features = "",
    cpu_opt_profile = {},
    --paths = {{".", truss.working_dir}},
    package_dirs = {truss.fs.joinpath(truss.binary_dir, "src")},
    packages = {{"HERE", truss.working_dir}},
    log_enabled = {"all"}, --"~path", "~debug", "~perf"},
    entrypoints = {main="main.t"},
    include_paths = {terralib.includepath, "include"},
    WORKDIR = truss.working_dir,
    BINDIR = truss.binary_dir,
    BINARY = truss.binary_name,
    rootdir = truss.binary_dir,
  }
  if truss.working_dir ~= truss.binary_dir then
    --table.insert(default_config.paths, {".", truss.binary_dir})
    table.insert(default_config.include_paths, truss.fs.joinpath(truss.binary_dir, "include"))
  end

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

  local configfn = truss.fs.joinpath(truss.working_dir, "trussconfig.lua")
  local configfile = io.open(configfn)

  if configfile then
    log.info("Using configfile [" .. configfn .. "]")
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
    local configsrc = configfile:read("*a")
    configfile:close()
    local configfunc, configerr = loadstring(configsrc)
    if not configfunc then
      error("Error parsing config file:", configerr)
    end
    setfenv(configfunc, config)
    local happy, err = pcall(configfunc)
    if not happy then
      error("Error running config file: " .. err)
    end
    setmetatable(config, nil)
  else
    log.info("No config file at [" .. configfn .. "]; using defaults.")
  end

  truss.rootdir = config.rootdir
  truss.config = config

  local log_enabled = config.log_enabled
  if type(log_enabled) == 'string' then 
    log_enabled = {log_enabled}
  elseif log_enabled == true then
    log_enabled = {"all"}
  elseif log_enabled == false then
    log_enabled = {"~all"}
  end
  log.enabled = {}
  for _, level in ipairs(log_enabled) do
    if level:sub(1,1) == "~" then
      log.enabled[level:sub(2,-1)] = false
    else
      log.enabled[level] = true
    end
  end

  log.info("Rootdir:", truss.rootdir)

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

  truss.original_include_path = terralib.includepath
  terralib.includepath = table.concat(config.include_paths, ";")
  log.info("Include path:", terralib.includepath)

  truss.using_system_headers = true -- assume this is true?

  for _, dir in ipairs(config.package_dirs) do
    truss.root.add_packages_dir(dir)
  end

  for _, package_pair in ipairs(config.packages) do
    local name, path = unpack(package_pair)
    truss.root.add_package(name, path)
  end
end

return {install = install}
