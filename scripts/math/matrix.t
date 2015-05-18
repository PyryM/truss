-- matrix.t
--
-- 4x4 matrix math functions

local m = {}
local CMath = terralib.includec("math.h")

terra m.rotateXY(mat: &float, ax: float, ay: float)
	var sx = CMath.sinf(ax)
	var cx = CMath.cosf(ax)
	var sy = CMath.sinf(ay)
	var cy = CMath.cosf(ay)

	mat[ 0] = cy
	mat[ 1] = 0.0f 
	mat[ 2] = sy
	mat[ 3] = 0.0f
	mat[ 4] = sx*sy
	mat[ 5] = cx
	mat[ 6] = -sx*cy
	mat[ 7] = 0.0f
	mat[ 8] = -cx*sy
	mat[ 9] = sx
	mat[10] = cx*cy
	mat[11] = 0.0f
	mat[12] = 0.0f
	mat[13] = 0.0f
	mat[14] = 0.0f
	mat[15] = 1.0f
end

terra m.projXYWH(mat: &float, x: float, y: float, width: float, height: float, near: float, far: float)
	var diff = far - near
	var aa = far / diff
	var bb = -near*aa

	mat[ 0] = width;
	mat[ 5] = height;
	mat[ 8] =  x;
	mat[ 9] = -y;
	mat[10] = aa;
	mat[11] = 1.0f;
	mat[14] = bb;
end

terra m.setIdentity(mat: &float)
	mat[ 0], mat[ 1], mat[ 2], mat[ 3] = 1.0f, 0.0f, 0.0f, 0.0f 
	mat[ 4], mat[ 5], mat[ 6], mat[ 7] = 0.0f, 1.0f, 0.0f, 0.0f
	mat[ 8], mat[ 9], mat[10], mat[11] = 0.0f, 0.0f, 1.0f, 0.0f
	mat[12], mat[13], mat[14], mat[15] = 0.0f, 0.0f, 0.0f, 1.0f
end

function m.toRad(deg)
	return deg * math.pi / 180.0 
end

function m.makeProjMat(mat, fovy, aspect, near, far)
	local vheight = 1.0 / math.tan(m.toRad(fovy)*0.5)
	local vwidth  = vheight * 1.0/aspect;
	m.projXYWH(mat, 0.0, 0.0, vwidth, vheight, near, far)
end

return m