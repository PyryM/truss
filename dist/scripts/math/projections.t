-- math/projections.t
--
-- functions for creating various types of projecion matrices

local m = {}
local cmath = require("math/cmath.t")

function m.deg_to_rad(deg)
    return deg * math.pi / 180.0
end

m.use_gl_depth_range = false

function m.set_default_gl_mode(is_gl)
  m.use_gl_depth_range = is_gl
end

function m.make_proj_mat(mat, fovy, aspect, near, far, is_gl)
  local vheight = 2.0 * near * math.tan(m.deg_to_rad(fovy)*0.5)
  local vwidth  = vheight * aspect

  m.proj_frustum(mat, -vwidth/2.0, vwidth/2.0, -vheight/2.0, vheight/2.0, 
                  near, far, is_gl)
end

function m.make_tiled_projection(mat, fovy, aspect, near, far, 
                                 gwidth, gheight, gxidx, gyidx)
  local vheight = 2.0 * near * math.tan(m.deg_to_rad(fovy)*0.5)
  local vwidth  = vheight * aspect

  local xdiv = vwidth / gwidth
  local ydiv = vheight / gheight
  local left = (-vwidth/2.0) + xdiv * gxidx
  local right = left + xdiv
  local bottom = (-vheight/2.0) + ydiv * gyidx
  local top = bottom + ydiv

  m.proj_frustum(mat, left, right, bottom, top, near, far)
end

function m.proj_frustum(mat, left, right, bottom, top, near, far, is_gl)
  if is_gl == nil then is_gl = m.use_gl_depth_range end
  if is_gl then
    m.proj_frustum_gl(mat, left, right, bottom, top, near, far)
  else
    m.proj_frustum_dx(mat, left, right, bottom, top, near, far)
  end
end

terra m.proj_frustum_gl(mat: &float,
                  left: float, right: float,
                  bottom: float, top: float,
                  near: float, far: float)
  mat[ 0] = 2.0*near / (right - left)
  mat[ 5] = 2.0*near / (top - bottom)
  mat[ 8] = (right + left) / (right - left)
  mat[ 9] = (top + bottom) / (top - bottom)
  mat[10] = -(far + near) / (far - near)
  mat[11] = -1.0
  mat[14] = -2 * far * near / (far - near)
end

terra m.proj_frustum_dx(mat: &float,
                  left: float, right: float,
                  bottom: float, top: float,
                  near: float, far: float)
  mat[ 0] = 2.0*near / (right - left)
  mat[ 5] = 2.0*near / (top - bottom)
  mat[ 8] = (right + left) / (right - left)
  mat[ 9] = (top + bottom) / (top - bottom)
  mat[10] = -far / (far - near)
  mat[11] = -1.0
  mat[14] = -far * near / (far - near)
end

function m.proj_ortho(mat, left, right, bottom, top, near, far, is_gl)
  if is_gl == nil then is_gl = m.use_gl_depth_range end
  if is_gl then
    m.proj_ortho_gl(mat, left, right, bottom, top, near, far)
  else
    m.proj_ortho_dx(mat, left, right, bottom, top, near, far)
  end
end

terra m.proj_ortho_gl(mat: &float,
                   left: float, right: float,
                   bottom: float, top: float,
                   near: float, far: float)
  mat[ 0] = 2.0 / (right - left)
  mat[ 5] = 2.0 / (top - bottom)
  mat[10] = -2.0 / (far - near)
  mat[12] = -(right + left) / (right - left)
  mat[13] = -(top + bottom) / (top - bottom)
  mat[14] = -(far + near) / (far - near)
  mat[15] = 1.0
end

terra m.proj_ortho_dx(mat: &float,
                   left: float, right: float,
                   bottom: float, top: float,
                   near: float, far: float)
  mat[ 0] = 2.0 / (right - left)
  mat[ 5] = 2.0 / (top - bottom)
  mat[10] = -1.0 / (far - near)
  mat[12] = -(right + left) / (right - left)
  mat[13] = -(top + bottom) / (top - bottom)
  mat[14] = -near / (far - near)
  mat[15] = 1.0
end

return m