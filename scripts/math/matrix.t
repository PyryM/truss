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

-- matrix functions ported from threejs
-- https://github.com/mrdoob/three.js/blob/master/src/math/Matrix4.js

-- makes the matrix be a pure rotation from a quaternion
terra m.setMatrixFromQuat(mat: &float, x: float, y: float, z: float, w: float)
	var x2 = x + x 
	var y2 = y + y
	var z2 = z + z
	var xx = x * x2
	var xy = x * y2
	var xz = x * z2
	var yy = y * y2
	var yz = y * z2
	var zz = z * z2
	var wx = w * x2
	var wy = w * y2
	var wz = w * z2

	mat[ 0 ] = 1.0f - ( yy + zz )
	mat[ 4 ] = xy - wz
	mat[ 8 ] = xz + wy

	mat[ 1 ] = xy + wz
	mat[ 5 ] = 1.0f - ( xx + zz )
	mat[ 9 ] = yz - wx

	mat[ 2 ] = xz - wy
	mat[ 6 ] = yz + wx
	mat[ 10 ] = 1.0f - ( xx + yy )

	-- last column
	mat[ 3 ] = 0.0f
	mat[ 7 ] = 0.0f
	mat[ 11 ] = 0.0f

	-- bottom row
	mat[ 12 ] = 0.0f
	mat[ 13 ] = 0.0f
	mat[ 14 ] = 0.0f
	mat[ 15 ] = 1.0f
end

-- applies scaling to a transform (4x4 matrix) in place
terra m.scaleMatrix(mat: &float, sx: float, sy: float, sz: float)
	mat[ 0 ] *= sx
	mat[ 4 ] *= sy
	mat[ 8 ] *= sz
	mat[ 1 ] *= sx
	mat[ 5 ] *= sy
	mat[ 9 ] *= sz
	mat[ 2 ] *= sx
	mat[ 6 ] *= sy
	mat[ 10 ] *= sz
	mat[ 3 ] *= sx
	mat[ 7 ] *= sy
	mat[ 11 ] *= sz
end

terra m.setMatrixPosition(mat: &float, x: float, y: float, z: float)
	mat[ 12 ] = x
	mat[ 13 ] = y
	mat[ 14 ] = z
end

-- takes a rotation (quaternion), scaling (vec3), and translation (vec3)
-- and composes them together into one 4x4 transformation
function m.composeMatrix(destmat, rotationQuat, scaleVec, posVec)
	m.setMatrixFromQuat(destmat, rotationQuat.x, 
								 rotationQuat.y, 
								 rotationQuat.z, 
								 rotationQuat.w)
	m.scaleMatrix(destmat, scaleVec.x, scaleVec.y, scaleVec.z)
	m.setMatrixPosition(destmat, posVec.x, posVec.y, posVec.z)
end

-- multiplies 4x4 matrices so that dest = a * b
-- it is safe to have dest == a to do an in-place
-- multiply
terra m.multiplyMatrices(dest: &float, a: &float, b: &float)
	var a11, a12, a13, a14 = a[ 0 ], a[ 4 ], a[ 8 ], a[ 12 ]
	var a21, a22, a23, a24 = a[ 1 ], a[ 5 ], a[ 9 ], a[ 13 ]
	var a31, a32, a33, a34 = a[ 2 ], a[ 6 ], a[ 10 ], a[ 14 ]
	var a41, a42, a43, a44 = a[ 3 ], a[ 7 ], a[ 11 ], a[ 15 ]

	var b11, b12, b13, b14 = b[ 0 ], b[ 4 ], b[ 8 ], b[ 12 ]
	var b21, b22, b23, b24 = b[ 1 ], b[ 5 ], b[ 9 ], b[ 13 ]
	var b31, b32, b33, b34 = b[ 2 ], b[ 6 ], b[ 10 ], b[ 14 ]
	var b41, b42, b43, b44 = b[ 3 ], b[ 7 ], b[ 11 ], b[ 15 ]

	dest[ 0 ] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41
	dest[ 4 ] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42
	dest[ 8 ] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43
	dest[ 12 ] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44

	dest[ 1 ] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41
	dest[ 5 ] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42
	dest[ 9 ] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43
	dest[ 13 ] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44

	dest[ 2 ] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41
	dest[ 6 ] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42
	dest[ 10 ] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43
	dest[ 14 ] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44

	dest[ 3 ] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41
	dest[ 7 ] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42
	dest[ 11 ] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43
	dest[ 15 ] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44
end

return m