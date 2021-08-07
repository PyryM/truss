-- main.t
-- run by truss unless you've patched main.cpp to do something else
-- override this script with your own main.t

-- allow other scripts to be invoked like
-- truss examples/some_other_script.t
local scriptname = truss.args[2] or "examples/logos/bone.t"
if scriptname:sub(1, #"scripts/") == "scripts/" then
  print("You do not need to and shouldn't prefix with scripts/ anymore!")
  scriptname = scriptname:sub(1 + #"scripts/", -1)
end
if scriptname == "repl" then
  scriptname = "examples/repl.t" 
elseif scriptname == "buildshaders" then
  scriptname = "dev/buildshaders.moon"
end
return require(scriptname, {allow_globals = true, env = _env}) 
