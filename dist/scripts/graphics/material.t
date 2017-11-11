-- graphics/material.t
--
-- some material-related utilities

local class = require("class")
local gfx = require("gfx")
local m = {}

local Material = class("Material")
m.Material = Material

function Material:init(src, clone)
  src = src or {}
  self.program = src.program
  if src.state ~= false then
    self.state = src.state or gfx.create_state()
  end
  if src.tags then
    self.tags = {}
    for k,v in pairs(src.tags) do self.tags[k] = src.tags[k] end
  end
  if clone and src.uniforms then
    self.uniforms = src.uniforms:clone()
  else
    self.uniforms = src.uniforms
  end
  self.global_uniforms = src.global_uniforms
end

function Material:bind(globals)
  if self.state then gfx.set_state(self.state) end
  if self.uniforms then self.uniforms:bind() end
  if self.global_uniforms then
    self.global_uniforms:bind_as_fallbacks(globals)
  end
end

function Material:bind_state()
  if self.state then gfx.set_state(self.state) end
end

function Material:bind_locals()
  if self.uniforms then self.uniforms:bind() end
end

function Material:bind_globals(globals)
  if self.global_uniforms then
    self.global_uniforms:bind_as_fallbacks(globals)
  end
end

function Material:clone()
  return self.class(self, true)
end

return m
