-- gfx/immediate.t
--
-- psuedo-immediate mode rendering

local class = require("class")
local math = require("math")
local Texture = require("./texture.t").Texture
local View = require("./view.t").View
local rendertarget = require("./rendertarget.t")
local load_program = require("./shaders.t").load_program

local Pool = class("Pool")
function Pool:init(allocator)
  self._allocator = allocator
  self._items = {}
  self._next_item = 1
end
function Pool:get()
  if not self._items[self._next_item] then
    self._items[self._next_item] = self._allocator()
  end
  local ret = self._items[self._next_item]
  self._next_item = self._next_item + 1
  return ret
end
function Pool:clear(destroy)
  self._next_item = 1
  if destroy then
    self._items = {}
  end
end

local ResourceCache = class("ResourceCache")
function ResourceCache:init()
  self._cache = {[false]=0}
end
function ResourceCache:_deallocate(v)
  if v.destroy then v:destroy() end
  if v.release then v:release() end
end
function ResourceCache:_allocate(thing)
  truss.error("This function must be implemented by subclass!")
end
function ResourceCache:clear()
  self._next_handle = self._start_handle
  for _, v in pairs(self._cache) do
    self:_deallocate(v)
  end
  self._cache = {}
end
function ResourceCache:insert(thing)
  local reskey = self:_canonize(thing)
  if self._cache[reskey] then error(reskey .. " already in cache!") end
  self._cache[reskey] = self:_allocate(thing)
  return self._cache[reskey]
end
function ResourceCache:_canonize(resname)
  return resname or false
end
function ResourceCache:get(thing, no_load)
  local reskey = self:_canonize(thing)
  if self._cache[reskey] then 
    return self._cache[reskey]
  else
    if no_load then return nil end
    return self:insert(thing)
  end
end

local UserCache = ResourceCache:extend("UserCache")
function UserCache:_allocate(info)
  return info.func()
end
function UserCache:_canonize(info)
  return info.name
end

local TextureCache = ResourceCache:extend("TextureCache")
function TextureCache:_allocate(filename)
  return Texture(filename)
end

local GeoCache = ResourceCache:extend("GeoCache")
function GeoCache:_load(info)
  if type(info) == "string" then -- filename?
    truss.error("NIY!")
    -- TODO: deal with loaders?
  else -- assume table
    truss.error("NIY!")
    -- TODO
  end
end
function GeoCache:_canonize(info)
  if type(info) == 'string' then return info end
  if not info.name then truss.error("Right now geometries must have names!") end
  return info.name
end

local ProgramCache = ResourceCache:extend("ProgramCache")
function ProgramCache:_canonize(program)
  local vshader, fshader = unpack(program)
  return vshader .. "|" .. fshader
end
function ProgramCache:_allocate(program)
  local vshader, fshader = unpack(program)
  if not (vshader and fshader) then
    truss.error("Must give vshader and fshader!")
  end
  return load_program(vshader, fshader)
end

local ImmediateContext = class("ImmediateContext")

function ImmediateContext:init(options)
  self._view_mat = math.Matrix4()
  self._materials = ResourceCache(game2:claim_materials(32, MODNAME), 32)
  self._drawcalls = ResourceCache(game2:claim_drawcalls(128, MODNAME), 128)

  self._instance_cache = ResourceCache(game2:claim_instance_buffers(32, MODNAME), 32)
  self._texture_cache = TextureCache(game2:claim_textures(32, MODNAME), 32)
  self._mesh_cache = MeshCache(game2:claim_meshes(32, MODNAME), 32)
  self._program_cache = ProgramCache(game2:claim_programs(16, MODNAME), 16)

  self._matrix_pool = Pool(vmath.Matrix)
  self._targets = options.targets or {}
  self._readbacks = {}

  self._used_viewcache = {}
  self._viewcache = {}
end

function ImmediateContext:_clear_temporaries()
  -- These are fairly lightweight, so we just clear them
  -- each frame
  self._nodes:clear()
  self._materials:clear()
  self._drawcalls:clear()

  -- Textures, programs, meshes are heavier-weight
  -- TODO: LRU style cache?
  --self._textures:clear() -- these are persistent-ish?
  --self._meshes:clear()   -- ^^
end

function ImmediateContext:begin_render(start_view_id)
  self:_clear_temporaries()
  self:_disable_views()
  self._view_id = start_view_id
end

function ImmediateContext:_get_view(id)
  if not self._viewcache[id] then
    self._viewcache[id] = View(id)
  end
  self._used_viewcache[id] = self._viewcache[id]
  return self._viewcache[id]
end

function ImmediateContext:find_target(target)
  if type(target) ~= "string" then return target end
  return assert(self._targets[target]) -- TODO: create targets?
end

function ImmediateContext:add_target(name, target)
  if not self._targets[name] then
    self._targets[name] = target
  end
  return self._targets[name]
end

local function optional(val, default)
  if val == nil then return default end
  if val == false then return false end
  return val
end

function ImmediateContext:begin_view(options)
  local prev_view = self:_get_view(self._view_id)
  self._view_id = self._view_id + 1
  self._active_view = self:_get_view(self._view_id)
  local settings = {
    clear = optional(options.clear, {
      color = optional(options.clear_color, 0x000000ff),
      depth = optional(options.clear_depth, 1.0),
      stencil = optional(options.clear_stencil, 0)
    }),
    render_target = options.target and self:find_target(options.target),
    viewport = options.viewport and to_viewport(options.viewport),
    sequential = options.sequential
  }
  self._view_crop = settings.viewport
  self._active_view:copy_settings(prev_view)
  self._active_view:set(settings)
  if options.touch ~= false then self._active_view:touch() end
end

function ImmediateContext:begin_screen_space(options)
  self:begin_view(options)
  if options.unit == "pixel" then
    self:set_proj_mat_pixel(options.origin_top)
  else
    self:set_proj_mat_screen()
  end
  self:set_view_mat("identity")
end

function ImmediateContext:set_proj_mat_screen()
  self._active_view:set_ortho_proj_screen()
end

function ImmediateContext:set_proj_mat_pixel(origin_top)
  self._origin_top = not not origin_top
  self._active_view:set_ortho_proj_pixel(self._origin_top)
end

function ImmediateContext:set_proj_mat(options)
  local fovy = options.fov or vmath.degrees(60.0)
  local near = options.near or 0.1
  local far = options.far or 30.0
  local aspect = options.aspect or (self._view_crop.w / self._view_crop.h)

  local vheight = 2.0 * near * math.tan(fovy*0.5)
  local vwidth = vheight * aspect
  self._active_view:set_proj_frustum( 
    -vwidth/2.0, vwidth/2.0, 
    -vheight/2.0, vheight/2.0, 
    near, far
  )
end

function ImmediateContext:set_view_mat(viewmat)
  if viewmat == "identity" then
    self._active_view:set_camera_identity()
  elseif viewmat then
    self._view_mat:copy(viewmat)
    self._active_view:set_fields{view_mat = self._view_mat}
  else
    error("Invalid view matrix: " .. tostring(viewmat))
  end
end

function ImmediateContext:set_camera_transform(options)
  vmath.to_matrix(options, self._view_mat)
  self._view_mat:invert()
  self._active_view:set_fields{view_mat = self._view_mat}
end

function ImmediateContext:get_dc()
  return self._drawcalls:next_id()
end

function ImmediateContext:get_geo(options)
  if not options then return 0 end -- zero is just fixed at identity?
  if type(options) == "number" then return options end
  return self._mesh_cache:get(options)
end

function ImmediateContext:create_geo(name, options)
  local function loader(geo_idx, _)
    local mesh = game2:get_mesh(geo_idx)
    if options.configure then options:configure() end
    mesh:create(assert(options.n_verts), assert(options.n_indices))
    --options.generator(ptr, options)
    options:generator(mesh)
    mesh:update()
  end
  return self._mesh_cache:get(name, loader)
end

function ImmediateContext:create_instance_buffer(name, options)
  local function loader(inst_idx, _)
    local ibuff = game2:get_instance_buffer(inst_idx)
    ibuff:allocate(assert(options.count))
    if options.generator then 
      options.generator(ibuff, options.count) 
      ibuff:update()
    end
  end
  return self._instance_cache:get(name, loader)
end

function ImmediateContext:get_instance_buffer(options)
  if not options then return -1 end -- -1 indicates no instances
  if type(options) == "number" then return options end
  return self._instance_cache:get(options)
end

function ImmediateContext:get_node(options)
  if not options then return 0 end -- zero is just fixed at identity?
  local nodeid = self._nodes:next_id()
  game2:get_node(nodeid):set_fields{world_transform = self:Matrix(options)}
  return nodeid
end

function ImmediateContext:get_texture(texname)
  return self._texture_cache:get(texname)
end

function ImmediateContext:get_program(options)
  local program = {"vs_error", "fs_error"}
  if #options == 2 then
    program = options
  elseif options.program then
    return self:get_program(options.program)
  elseif options.vshader and options.fshader then
    program = {options.vshader, options.fshader}
  else
    error("Didn't know how to turn this into a program")
  end
  return self._program_cache:get(program)
end

local function to_vector(v)
  return {x=v.x or v[1], y=v.y or v[2], z=v.z or v[3], w=v.w or v[4]}
end

function ImmediateContext:get_material(options)
  if not options then return 0 end
  if type(options) == "number" then return options end
  local kind = options.kind
  if (not kind) or (not _MATERIALS[kind]) then
    error("Unknown material kind: " .. options.kind)
  end
  local matid = self._materials:next_id()
  local mat = game2:get_material(matid)
  mat:create_kind(_MATERIALS[kind]) -- make def?
  mat:zero() -- zero out material to avoid stale stuff
  local mat_info = {
    program = self:get_program(options)
  }
  for k, v in pairs(options) do
    if k:sub(1,2) == "u_" then -- uniform
      if (#v == 16) or (#v == 9) then -- matrix
        mat_info[k] = v
      else -- assume vector
        mat_info[k] = to_vector(v)
      end
    elseif k:sub(1,2) == "s_" then -- texture
      mat_info[k] = self:get_texture(v)
    end
  end
  mat_info.state = options.state
  mat:set_fields(mat_info)
  return matid
end

function ImmediateContext:draw_mesh(options)
  local dcid = self:get_dc()
  game2:get_drawcall(dcid):set_fields{
    mesh_index = self:get_geo(options.geometry),
    node_index = self:get_node(options.transform),
    material_index = self:get_material(options.material),
    instance_buffer_index = self:get_instance_buffer(options.instances),
    target_view = self._view_id,
    enabled = true
  }
  game2:submit_drawcall(dcid)
end

function ImmediateContext:draw_screen_quad(options)
  local dcid = self:get_dc()
  local material = options.material and self:get_material(options.material)
  if not material then
    material = self:get_material{
      kind="model",
      u_params1 = options.u_params1 or options.params1,
      u_params2 = options.u_params2 or options.params2,
      u_baseColor = options.u_baseColor or options.baseColor,
      s_tex1 = options.s_tex1 or options.texture,
      state = options.state,
      vshader = options.vshader or "vs_model_decal",
      fshader = options.fshader or "fs_model_decal"
    }
  end
  local tf = options.transform
  if not tf then
    local x, y = options.x or options.pos.x, options.y or options.pos.y
    local w, h = options.w or options.pos.w, options.h or options.pos.h
    if self._origin_top then
      y = y + h
      h = -h
    end
    tf = {position={x, y, 0}, scale={w, h, 1}}
  end
  game2:get_drawcall(dcid):set_fields{
    mesh_index = 1, -- hardcoded quad?
    node_index = self:get_node(tf),
    material_index = material,
    instance_buffer_index = self:get_instance_buffer(options.instances),
    target_view = self._view_id,
    enabled = true
  }
  game2:submit_drawcall(dcid)
end

-- TODO: refactor these back into vmath?
function ImmediateContext:Matrix(options)
  return vmath.to_matrix(options, self._matrix_pool:get())
end

return {ImmediateContext = ImmediateContext}