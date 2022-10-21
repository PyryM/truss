local m = {}

m.TEST_BIN_DIR = truss.joinpath(truss.working_dir, "_test_binaries")

function m.build_and_run_test(testname, f)
  assert(f, "No terra function provided!")
  local binexport = require("build/binexport.t")
  truss.fs.recursive_makedir(m.TEST_BIN_DIR)
  local outpath = truss.joinpath(m.TEST_BIN_DIR, testname)
  binexport.export_binary{
    name = outpath,
    symbols = {main = f}
  }
  if truss.os ~= "Windows" then
    outpath = "/" .. outpath
  end
  if os.execute(outpath) ~= 0 then 
    error("Test binary did not execute successfully")
  end
end

return m