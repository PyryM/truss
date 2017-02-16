-- gfx/view.t
--
-- view management functions

local m = {}
local class = require("class")
local math = require("math")

local View = class("View")
m.View = View

function View:init(viewid)
  if not viewid then truss.error("View must be provided with id!") end
  self._viewid = viewid
  self._viewport = nil
  self._clear = {color = 0x303030ff, depth = 1.0}
  self._projmat = math.Matrix4():identity()
  self._viewmat = math.Matrix4():identity()
end

function View:set(options)
  options = options or {}
  self:set_render_target(options.render_target)
  self:set_matrices(options.view_matrix, options.proj_matrix)
  self:set_viewport(options.viewport)
  self:set_clear(options.clear)
end

function View:set_matrices(view, proj)
  if view then self._viewmat:copy(view) end
  if proj then self._projmat:copy(proj) end
  bgfx.set_view_transform(self._viewid, self._viewmat.data, self._projmat.data)
end

function View:set_viewport(rect)
  if rect == false then
    self._viewport = nil
  else
    self._viewport = rect or self._viewport
  end
  if not self._viewport then
    if self._rendertarget and self._rendertarget.width then
      local w, h = self._rendertarget.width, self._rendertarget.height
      bgfx.set_view_rect(self._viewid, 0, 0, w, h)
    else
      bgfx.set_view_rect_auto(self._viewid, 0, 0, bgfx.BACKBUFFER_RATIO_EQUAL)
    end
  else
    bgfx.set_view_rect(self._viewid, unpack(self._viewport))
  end
end

function View:set_clear(clear)
  self._clear = clear or self._clear
  clear = self._clear
  local clear_rgb = clear.color or 0x000000ff
  local clear_depth = clear.depth or 1.0
  local clear_stencil = clear.stencil or 0
  local flags = bgfx.CLEAR_NONE

  local rt = self._rendertarget or {has_color = true, has_depth = true}

  if clear.color ~= false and rt.has_color then
    flags = math.ullor(flags, bgfx.CLEAR_COLOR)
  end
  if clear.depth ~= false and rt.has_depth then
    flags = math.ullor(flags, bgfx.CLEAR_DEPTH)
  end
  if clear.stencil then
    flags = math.ullor(flags, bgfx.CLEAR_STENCIL)
  end

  bgfx.set_view_clear(self._viewid, flags,
      clear_rgb, clear_depth, clear_stencil)
end

function View:set_render_target(tgt)
  self._rendertarget = tgt or self._rendertarget
  tgt = self._rendertarget

  if tgt and tgt.framebuffer then
    bgfx.set_view_frame_buffer(self._viewid, tgt.framebuffer)
  end
end

function View:get_dimensions()
  if self._rendertarget and self._rendertarget.width then
    return self._rendertarget.width, self._rendertarget.height
  else
    local gfx = require("gfx")
    return gfx.backbuffer_width, gfx.backbuffer_height
  end
end

return m
