local class = require("class")
local bgfx = require("./bgfx.t")
local shaders = require("./shaders.t")

local m = {}

function m.set_compute_buffers_and_images(buffers)
  local prev_stage = -1
  for idx, item in ipairs(buffers) do
    local stage = item[1] or item.stage or (prev_stage + 1)
    if stage <= prev_stage then 
      truss.error("Compute stages must be specified in order;" 
                  .. " previous stage was " .. prev_stage 
                  .. " but got " .. tostring(stage))
    end
    prev_stage = stage
    if item.vertex_buffer then
      item.vertex_buffer:bind_vertex_compute(stage, item.access)
    elseif item.index_buffer then
      item.index_buffer:bind_index_compute(stage, item.access)
    elseif item.image then
      item.image:bind_compute(stage, item.access)
    elseif item.texture then -- ??
      truss.error("Not sure what to do about compute textures...")
    else
      truss.error("Unknown compute binding " .. idx .. " / " .. stage)
    end
  end
end

BGFX_C_API void bgfx_dispatch(bgfx_view_id_t _id, bgfx_program_handle_t _program, uint32_t _numX, uint32_t _numY, uint32_t _numZ);


function m.dispatch_compute(options)
  if not options then truss.error("No options provided") end
  if not options.view then truss.error("No view specified") end
  if not options.bindings then truss.error("No bindings specified") end
  if not options.shape then truss.error("No workgroup size/shape specified") end
  if not options.program then truss.error("No program specified") end

  local sX, sY, sZ = unpack(options.shape)
  local viewid = options.view
  if type(viewid) == 'table' then viewid = viewid._viewid end

  m.set_compute_buffers_and_images(options.buffers)
  bgfx.dispatch(viewid, shaders.load_compute_program(options.program), 
                sX, sY, sZ)
end

return m