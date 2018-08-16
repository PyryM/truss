-- gfx/CameraComponent.t
--
-- basic CameraComponent components/entities/etc.

local class = require("class")
local math = require("math")
local gfx = require("gfx")
local renderer = require("./renderer.t")
local renderop = require("./renderop.t")
local ecs = require("ecs")

local m = {}
local CameraComponent = renderer.RenderComponent:extend("CameraComponent")
m.CameraComponent = CameraComponent

function CameraComponent:init(options)
  CameraComponent.super.init(self)
  options = options or {}
  self.mount_name = "camera"
  self.tags = gfx.tagset{is_camera = true, camera_tag = options.tag or "primary"}
  self.view_mat = math.Matrix4():identity()
  self.proj_mat = math.Matrix4():identity()
  self.inv_proj_mat = math.Matrix4():identity()
  self.view_proj_mat = math.Matrix4():identity()
  self._render_ops = {}
  if options.orthographic then
    self:make_orthographic(options.left or -1.0,
                           options.right or 1.0,
                           options.bottom or -1.0,
                           options.top or 1.0,
                           options.near or 0.01,
                           options.far or 30.0)
  else
    self:make_projection(options.fov or 70,
                         options.aspect or 1.0,
                         options.near or 0.01,
                         options.far or 30.0)
  end
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
  self.view_mat:invert(self.ent.matrix_world)
  return self.view_mat, self.proj_mat
end
CameraComponent.get_matrices = CameraComponent.update_matrices

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

  local worldPose = self.ent.matrix_world or self.ent.matrix
  worldPose:get_column(4, p)
  d:set(ndcX, ndcY, 0.0, 1.0)
  self.inv_proj_mat:multiply(d)
  d:divide_perspective():normalize3d()
  d.elem.w = 0.0        -- only apply the rotation component of the
  worldPose:multiply(d) -- world pose

  return p, d
end

local CameraControlOp = renderop.RenderOperation:extend("CameraControlOp")
m.CameraControlOp = CameraControlOp
function CameraControlOp:init(tag)
  self._tag = tag or "primary"
end

function CameraControlOp:matches(tags)
  if not tags.is_camera then return nil end
  if self._tag ~= tags.camera_tag then return nil end
  return self.opfunc
end

function CameraControlOp:apply(component, tf)
  -- TODO: not terribly efficient to reinvert the view matrix for every stage
  self.stage.view:set_matrices(component:get_matrices())
end

-- TODO: figure out multirendering in the new system
--[[
local MultiCameraControlOp = renderop.MultiRenderOperation:extend("MultiCameraControlOp")
m.MultiCameraControlOp = MultiCameraControlOp

function MultiCameraControlOp:init()
  -- hmmm, maybe need to think about this a bit
  -- right now this will match *every* camera, and only in the actual
  -- :multi_render() call does it apply the matrices to the correct view
  -- 
  -- Probably you'll never have enough cameras and multistages that this 
  -- is a performance problem, but nonetheless it's inelegant.
  -- Perhaps the right way to do it would be to change :matches() to also take
  -- the stage as an argument, so this could check stage._contexts...
end

function MultiCameraControlOp:matches(component)
  if not component.camera_tag then return false end
  return (component.view_mat ~= nil) and (component.proj_mat ~= nil)
end

function MultiCameraControlOp:multi_render(contexts, component)
  for _, ctx in ipairs(contexts) do
    if ctx.name == component.camera_tag then
      ctx.view:set_matrices(component.view_mat, component.proj_mat)
    end
  end
end
]]

-- convenience Camera entity
m.Camera = ecs.promote("Camera", CameraComponent)

-- convenience function to create six cameras under one parent to
-- render to cubemap faces
function m.CubeCamera(_ecs, name, options)
  options = options or {}
  local parent = ecs.Entity3d(_ecs, name)
  local vpx, vnx = math.Vector(1,0,0), math.Vector(-1, 0, 0)
  local vpy, vny = math.Vector(0,1,0), math.Vector( 0,-1, 0)
  local vpz, vnz = math.Vector(0,0,1), math.Vector( 0, 0,-1)
  -- see updateTextureCube in bgfx.h for face orientations
  local faces = { 
    nx = {up = vpy, right = vnz}, px = {up = vpy, right = vpz},
    ny = {up = vnz, right = vpx}, py = {up = vpz, right = vpx},
    pz = {up = vpy, right = vpx}, nz = {up = vpy, right = vnx}
  }
  local forward = math.Vector()
  for face_id, face in pairs(faces) do
    -- cube map faces have fixed fov and aspect
    local cam_options = {fov = 90, aspect = 1, 
                         near = options.near, far = options.far,
                         name = (options.name or "face") .. "_" .. face_id,
                         tag = (options.tag or "cube") .. "_" .. face_id}
    local face_cam = parent:create_child(m.Camera, "facecam", cam_options)
    forward:cross(face.right, face.up)
    face_cam.matrix:identity()
    face_cam.matrix:from_basis{face.right, face.up, forward}
  end
  return parent
end


return m
