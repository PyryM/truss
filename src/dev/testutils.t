local m = {}

m.TEST_BIN_DIR = truss.fs.joinpath(truss.working_dir, "_test_binaries")

function m.build_and_run_test(testname, f)
  assert(f, "No terra function provided!")
  local binexport = require("build/binexport.t")
  truss.fs.recursive_makedir(m.TEST_BIN_DIR)
  local outpath = truss.fs.joinpath(m.TEST_BIN_DIR, testname)
  binexport.export_binary{
    name = outpath,
    symbols = {main = f}
  }
  if truss.os ~= "Windows" then
    outpath = "/" .. outpath
  end
  if outpath:find(" ") then
    outpath = '"' .. outpath .. '"'
  end
  -- TODO: recover output?
  return os.execute(outpath)
end

return m