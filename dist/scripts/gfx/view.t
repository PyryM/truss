-- gfx/view.t
--
-- view management functions

local m = {}
local class = require("class")
local math = require("math")

local View = class("View")
m.View = View

function View:init(options)
  options = options or {}
  self._viewid = nil
  self._viewport = nil
  self._clear = {color = 0x303030ff, depth = 1.0}
  self._projmat = math.Matrix4():identity()
  self._viewmat = math.Matrix4():identity()
  self._sequential = false
  self.props = options.props or options
  self.name = options.name or "View"
  self:set(options)
end

function View:set(options)
  self:set_render_target(options.render_target)
  self:set_matrices(options.view_matrix, options.proj_matrix)
  self:set_viewport(options.viewport)
  self:set_clear(options.clear)
  self:set_sequential(options.sequential)
  return self
end

function View:set_matrices(view, proj)
  if view then self._viewmat:copy(view) end
  if proj then self._projmat:copy(proj) end
  self:apply_matrices()
end

function View:apply_matrices()
  if (not self._viewid) or (self._viewid < 0) then return end
  bgfx.set_view_transform(self._viewid, self._viewmat.data, self._projmat.data)
end

function View:set_viewport(rect)
  if rect == false then
    self._viewport = nil
  else
    self._viewport = rect or self._viewport
  end
end

function View:apply_viewport()
  if (not self._viewid) or (self._viewid < 0) then return end
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
  if clear == false then 
    clear = {color = false, depth = false, stencil = false}
  end
  self._clear = clear or self._clear
  self:apply_clear()
end

function View:apply_clear()
  if (not self._viewid) or (self._viewid < 0) then return end
  local clear = self._clear
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
  self:apply_render_target()
end

function View:apply_render_target()
  if (not self._viewid) or (self._viewid < 0) then return end
  local tgt = self._rendertarget
  if not (tgt and tgt.framebuffer) then return end
  bgfx.set_view_frame_buffer(self._viewid, tgt.framebuffer)
end

function View:set_sequential(s)
  if s ~= nil then self._sequential = s end
  self:apply_sequential()
end

function View:apply_sequential()
  if (not self._viewid) or (self._viewid < 0) then return end
  local mode = bgfx.VIEW_MODE_DEFAULT
  if self._sequential then mode = bgfx.VIEW_MODE_SEQUENTIAL end
  bgfx.set_view_mode(self._viewid, mode)
end

function View:apply_all()
  if (not self._viewid) or (self._viewid < 0) then return end
  self:apply_matrices()
  self:apply_clear()
  self:apply_render_target()
  self:apply_viewport()
  self:apply_sequential()
  return self
end

function View:get_dimensions()
  if self._rendertarget and self._rendertarget.width then
    return self._rendertarget.width, self._rendertarget.height
  else
    local gfx = require("gfx")
    return gfx.backbuffer_width, gfx.backbuffer_height
  end
end

function View:get_active_dimensions()
  if self._viewport then
    return self._viewport[3], self._viewport[4]
  else
    return self:get_dimensions()
  end
end

function View:bind(viewid)
  if viewid ~= nil then self._viewid = viewid end
  self:apply_all()
  return self
end

function View:touch()
  bgfx.touch(self._viewid)
  return self
end

return m
