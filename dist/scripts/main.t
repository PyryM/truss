-- main.t
-- run by truss unless you've patched main.cpp to do something else
-- override this script with your own main.t

if #truss.args >= 2 then
  -- allow other scripts to be invoked like
  -- truss scripts/examples/some_other_script.t
  return truss._import_main(truss.args[2])
else
  -- otherwise, show the logo
  return truss._import_main("scripts/examples/logo.t")
end
