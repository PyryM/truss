local async = require("async")
local graphics = require("graphics")
local gfx = require("gfx")
local math = require("math")

local m = {}

local drawables = {}
local next_drawable = 1

function m.draw_2d_drawables(ctx)
  for idx, draw in pairs(drawables) do
    if draw.dead then
      drawables[idx] = nil
    else
      draw:draw(ctx)
    end
  end
end

function m.add_2d_drawable(f, state)
  local d = state or {}
  drawables[next_drawable] = d
  next_drawable = next_drawable + 1
  async.run(f, d):next(nil, print)
  return d
end

function m.add_textbox(options)
  return m.add_2d_drawable(m.textbox, options)
end

local NVGDrawer = graphics.NanoVGComponent:extend("NVGDrawer")
m.NVGDrawer = NVGDrawer

function NVGDrawer:nvg_draw(ctx)
  ctx:load_font("font/FiraSans-Regular.ttf", "sans")
  ctx:load_font("font/FiraMono-Regular.ttf", "mono")
  m.draw_2d_drawables(ctx)
end

local function _drawbox(state, ctx)
  ctx:BeginPath()
  ctx:Rect(state.x, state.y, state.w, state.h)
  ctx:FillColor(ctx:RGBA(unpack(state.color)))
  ctx:Fill()
end

local function _drawtext(state, ctx)
  ctx:FontFace(state.font or "sans")
  ctx:FontSize(state.font_size)
  ctx:FillColor(ctx:RGBA(unpack(state.color)))
  ctx:TextAlign(ctx.ALIGN_LEFT + ctx.ALIGN_TOP)
  if state.clip_w then
    ctx:Scissor(state.x, state.y, state.clip_w, state.h)
  end
  ctx:Text(state.x, state.y, state.text or "NULL TEXT POINTER", nil)
  if state.clip_w then
    ctx:ResetScissor()
    ctx:BeginPath()
    ctx:Rect(state.x + state.clip_w, state.y, state.w - state.clip_w, state.h)
    ctx:Fill()
  end
end

local function out_expo(t)
  if t == 1 then
    return 1
  else
    return 1.001 * (-(2^(-10 * t)) + 1)
  end
end

function m.textbox(state)
  state.color = state.color or {0xFF, 0x1D, 0x76, 200}
  state.draw = _drawbox
  local final_w = state.w
  for f = 1, 20 do
    state.w = final_w * out_expo(f/20)
    async.await_frames(1)
  end
  state.draw = _drawtext
  for f = 1, 30 do
    state.clip_w = final_w * out_expo(f/30)
    async.await_frames(1)
  end
  state.clip_w = nil
end

function m.make_logo_column_edges()
  local edges = {}
  local prev_tier = nil
  for tier = 1, 4 do
    local pts = {}
    for idx = 0, 2 do
      local theta = (idx + tier/2) * math.pi * 2 / 3
      pts[idx] = math.Vector(math.cos(theta)*0.15+0.5, tier/5, math.sin(theta)*0.15+0.5)
    end
    for idx = 0, 2 do
      table.insert(edges, {pts[idx], pts[(idx+1)%3]})
      if prev_tier then
        table.insert(edges, {pts[idx], prev_tier[idx]})
        table.insert(edges, {pts[idx], prev_tier[(idx+1)%3]})
      end
    end
    prev_tier = pts
  end
  return edges
end

function m.dump_text_caps(printfunc)
  local texcaps = {}
  printfunc = printfunc or print
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
    printfunc(v[2])
  end
end

return m