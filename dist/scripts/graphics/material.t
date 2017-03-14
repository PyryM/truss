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
  self.state   = src.state
  for k,v in pairs(src.tags or {}) do
    self.tags[k] = src.tags[k]
  end
  if clone and src.uniforms then
    self.uniforms = src.uniforms:clone()
  else
    self.uniforms = src.uniforms
  end
end

function Material:clone()
  return self.class(self, true)
end

return m
