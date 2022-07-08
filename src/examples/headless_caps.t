local gfx = require("gfx")

function init()
  gfx.init_gfx{
    headless = true,
    backend = truss.args[3],
    lowlatency = true,
    width = 256, height = 256,
    --cb_ptr = require("addon/sdl.t").get_bgfx_callback() -- for callback traces?
  }
  for capname, supported in pairs(gfx.get_caps().features) do
    log.info(capname, supported)
  end

  local texcaps = {}
  for fname, fcaps in pairs(gfx.get_caps().texture_formats) do
    local scaps = fname .. ": "
    for capname, present in pairs(fcaps) do
      if capname:sub(1,1) ~= "_" and present then 
        scaps = scaps .. capname .. " " 
      end
    end
    table.insert(texcaps, {fname, scaps})
  end
  table.sort(texcaps, function(a, b) return a[1] < b[1] end)
  for _, v in ipairs(texcaps) do
    log.info(v[2])
  end
  print("We seem to have done something.")
end

function update()
  truss.quit()
end