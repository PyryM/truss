-- gfx/CameraComponent.t
--
-- basic CameraComponent components/entities/etc.

local class = require("class")
local math = require("math")
local pipeline = require("graphics/pipeline.t")
local Entity3d = require("ecs/entity.t").Entity3d

local m = {}
local CameraComponent = pipeline.DrawableComponent:extend("CameraComponent")
m.CameraComponent = CameraComponent

function CameraComponent:init(tag)
  CameraComponent.super.init(self)
  self.mount_name = "camera"
  self.camera_tag = tag or "primary"
  self.view_mat = math.Matrix4():identity()
  self.proj_mat = math.Matrix4():identity()
  self.inv_proj_mat = math.Matrix4():identity()
  self.view_proj_mat = math.Matrix4():identity()
  self._render_ops = {}
end

function CameraComponent:make_projection(fov_degrees, aspect, near, far)
  self.proj_mat:perspective_projection(fov_degrees, aspect, near, far)
  self.inv_proj_mat:invert(self.proj_mat)
  return self
end

function CameraComponent:make_orthographic(left, right, bottom, top, near, far, isGL)
  self.proj_mat:orthographic_projection(left, right,
                                          bottom, top,
                                          near, far, isGL)
  self.inv_proj_mat:invert(self.proj_mat)
  return self
end

function CameraComponent:set_projection(proj_mat)
  self.proj_mat:copy(proj_mat)
  self.inv_proj_mat:invert(self.proj_mat)
end

function CameraComponent:update_matrices()
  self.view_mat:invert(self._entity.matrix_world)
  return self.view_mat, self.proj_mat
end

function CameraComponent:on_update()
  self:update_matrices()
  self:draw()
end

function CameraComponent:get_view_proj_mat(target)
    local view, proj = self:update_matrices()
    target = target or self.view_proj_mat
    return target:multiply(proj, view)
end

-- "unproject" an image coordinate (in NDC, so [-1,1] w/ (0,0) center) to a ray
-- returns origin, direction (as new Vectors if none are provided; otherwise,
-- modifies the provided vectors in-place)
local tempVec = math.Vector()
function CameraComponent:unproject(ndcX, ndcY, origin, direction)
  local p = origin or math.Vector()
  local d = direction or math.Vector()

  local worldPose = self._entity.matrixWorld or self._entity.matrix
  worldPose:get_column(4, p)
  d:set(ndcX, ndcY, 0.0, 1.0)
  self.inv_proj_mat:multiply(d)
  d:divide_perspective():normalize3d()
  d.elem.w = 0.0              -- only apply the rotation component of the
  worldPose:multiply(d) -- world pose

  return p, d
end

local CameraControlOp = pipeline.RenderOperation:extend("CameraControlOp")
m.CameraControlOp = CameraControlOp
function CameraControlOp:init(tag)
  self._tag = tag or "primary"
end

function CameraControlOp:matches(component)
  if self._tag ~= component.camera_tag then return false end
  return (component.view_mat ~= nil) and (component.proj_mat ~= nil)
end

function CameraControlOp:draw(component)
  self.stage.view:set_matrices(component.view_mat, component.proj_mat)
end

-- this is not actually a class, but just produces an Entity3d with a
-- CameraComponent
function m.Camera(options)
  local ret = Entity3d(options.name)
  local cam_component = ret:add_component(CameraComponent(options.tag))
  cam_component:make_projection(options.fov or 70,
                                options.aspect or 1.0,
                                options.near or 0.01,
                                options.far or 30.0)
  return ret
end

return m
