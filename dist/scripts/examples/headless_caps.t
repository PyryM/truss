local gfx = require("gfx")

function init()
  gfx.init_gfx{
    headless = true,
    backend = truss.args[3],
    lowlatency = true,
    width = 256, height = 256,
    cb_ptr = require("addon/sdl.t").get_bgfx_callback() -- for callback traces?
  }
  for capname, supported in pairs(gfx.get_caps().features) do
    log.info(capname, supported)
  end
  print("We seem to have done something.")
end

function update()
  truss.quit()
end