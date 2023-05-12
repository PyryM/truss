-- runs the user config file

local function install(truss)
  function truss.load_config(configfn)
    local log = truss.log
    local default_config = {
      cpu_triple = "native",
      cpu_features = "",
      cpu_opt_profile = {},
      package_dirs = {truss.fs.joinpath(truss.binary_dir, "src")},
      packages = {{"@cwd", truss.working_dir}},
      include_paths = {terralib.includepath, "include"},
      log_enabled = {"all"}, --"~path", "~debug", "~perf"},
      entrypoints = {},
      entry_runner = function(root, modname)
        if not modname then
          log.fatal("No module specified to run!")
          return false
        end
        local mod = root.try_require(modname)
        if not mod then
          log.fatal("Couldn't find [" .. modname .. "]")
          return false
        end
        if mod.main then
          return mod.main()
        elseif mod.init then
          log.warn(
            "Module [" .. modname .. "] is using deprecated 'init'.",
            "Consider renaming entrypoint to 'main'."
          )
          return mod.init()
        else
          log.fatal("Module [" .. modname .. "] has no 'main' to run.")
          return false
        end
      end
    }
    if truss.working_dir ~= truss.binary_dir then
      --table.insert(default_config.paths, {".", truss.binary_dir})
      table.insert(default_config.include_paths, truss.fs.joinpath(truss.binary_dir, "include"))
    end

    local function list_config_options()
      local config_options = {}
      for k, _ in pairs(default_config) do
        table.insert(config_options, k)
      end
      table.sort(config_options)
      log.continuing("Valid config options:")
      for _, v in ipairs(config_options) do 
        log.continuing("  ", v) 
      end
    end

    local config_env = {
      WORKDIR = truss.working_dir,
      BINDIR = truss.binary_dir,
      BINARY = truss.binary_name,
      require = truss.require,
      log = log,
      truss = truss,
    }
    local config = truss.extend_table({}, default_config)

    if not configfn then
      configfn = truss.fs.joinpath(truss.working_dir, "trussconfig.lua")
    end
    local configfile = io.open(configfn)

    if configfile then
      log.info("Using configfile [" .. configfn .. "]")
      setmetatable(config_env, {
        __index = function(t, k)
          local val = config[k] or _G[k]
          if val ~= nil then return val end
          error('Config file referenced "' .. k .. '" which does not exist.')
        end,
        __newindex = function(t, k, v)
          if config[k] ~= nil then
            config[k] = v
            return
          end
          log.fatal('Tried to set invalid config option "' .. k .. '"')
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
      setfenv(configfunc, config_env)
      local happy, err = pcall(configfunc)
      if not happy then
        error("Error running config file: " .. err)
      end
      setmetatable(config, nil)
    else
      log.info("No config file at [" .. configfn .. "]; using defaults.")
    end

    function config:apply_native_config(root)
      local log_enabled = self.log_enabled
      if type(log_enabled) == 'string' then 
        log_enabled = {log_enabled}
      elseif log_enabled == true then
        log_enabled = {"all"}
      elseif log_enabled == false then
        log_enabled = {"~all"}
      end
      log.clear_enabled()
      log.set_enabled(log_enabled)

      if self.cpu_triple ~= "native" or self.cpu_features ~= "" then
        local triple = self.cpu_triple
        local features = self.cpu_features
        log.info("Using CPU triple:", triple)
        log.info("Using CPU features:", features)
        if triple == "native" then triple = nil end
        local opt_profile = assert(
          self.cpu_opt_profile, "config.cpu_opt_profile is missing!")
        terralib.nativetarget = terralib.newtarget{
          Triple = triple, 
          Features = features
        }
        terralib.jitcompilationunit = terralib.newcompilationunit(
          terralib.nativetarget, true, opt_profile)
      end
  
      root.original_include_path = terralib.includepath
      terralib.includepath = table.concat(config.include_paths, ";")
      log.info("Include path:", terralib.includepath)
  
      root.using_system_headers = true -- assume this is true?
    end

    function config:apply_packages(root)
      for _, dir in ipairs(config.package_dirs) do
        root.add_packages_dir(dir)
      end
  
      for _, package_pair in ipairs(config.packages) do
        local name, path = unpack(package_pair)
        root.add_package{
          name = name, 
          source_path = path
        }
      end
    end

    return config
  end
end

return {install = install}
