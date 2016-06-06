-- matrix.t
--
-- 4x4 matrix math functions

local m = {}
local CMath = terralib.includec("math.h")

local class = require("class")

struct m.vec4_ {
    x: float;
    y: float;
    z: float;
    w: float;
}
local vec4_ = m.vec4_

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

    mat[ 0] = width
    mat[ 5] = height
    mat[ 8] =  x
    mat[ 9] = -y
    mat[10] = -aa
    mat[11] = -1.0f
    mat[14] = bb
end

terra m.projFrustum(mat: &float,
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

terra m.setIdentity(mat: &float)
    mat[ 0], mat[ 1], mat[ 2], mat[ 3] = 1.0f, 0.0f, 0.0f, 0.0f
    mat[ 4], mat[ 5], mat[ 6], mat[ 7] = 0.0f, 1.0f, 0.0f, 0.0f
    mat[ 8], mat[ 9], mat[10], mat[11] = 0.0f, 0.0f, 1.0f, 0.0f
    mat[12], mat[13], mat[14], mat[15] = 0.0f, 0.0f, 0.0f, 1.0f
end

-- assumes far = 1, near = -1
terra m.orthoProjMat(mat: &float,
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

-- Convert LH to RH projection matrix and vice versa.
terra m.flipProjMatrixHandedness(dest: &float, src: &float)
    dest[ 0] = -src[ 0]
    dest[ 1] = -src[ 1]
    dest[ 2] = -src[ 2]
    dest[ 3] = -src[ 3]
    dest[ 4] =  src[ 4]
    dest[ 5] =  src[ 5]
    dest[ 6] =  src[ 6]
    dest[ 7] =  src[ 7]
    dest[ 8] = -src[ 8]
    dest[ 9] = -src[ 9]
    dest[10] = -src[10]
    dest[11] = -src[11]
    dest[12] =  src[12]
    dest[13] =  src[13]
    dest[14] =  src[14]
    dest[15] =  src[15]
end

-- Convert LH to RH view matrix and vice versa.
terra m.flipViewMatrixHandedness(dest: &float, src: &float)
    dest[ 0] = -src[ 0]
    dest[ 1] =  src[ 1]
    dest[ 2] = -src[ 2]
    dest[ 3] =  src[ 3]
    dest[ 4] = -src[ 4]
    dest[ 5] =  src[ 5]
    dest[ 6] = -src[ 6]
    dest[ 7] =  src[ 7]
    dest[ 8] = -src[ 8]
    dest[ 9] =  src[ 9]
    dest[10] = -src[10]
    dest[11] =  src[11]
    dest[12] = -src[12]
    dest[13] =  src[13]
    dest[14] = -src[14]
    dest[15] =  src[15]
end

terra m.zeroMatrix(dest: &float)
    for i = 0,16 do
        dest[i] = 0.0f
    end
end

function m.toRad(deg)
    return deg * math.pi / 180.0
end

function m.makeProjMat(mat, fovy, aspect, near, far)
    local vheight = 2.0 * near * math.tan(m.toRad(fovy)*0.5)
    local vwidth  = vheight * aspect
    m.projFrustum(mat, -vwidth/2.0, vwidth/2.0,
                       -vheight/2.0, vheight/2.0,
                        near, far)
end

function m.makeTiledProjection(mat, fovy, aspect, near, far, gwidth, gheight, gxidx, gyidx)
    local vheight = 2.0 * near * math.tan(m.toRad(fovy)*0.5)
    local vwidth  = vheight * aspect

    local xdiv = vwidth / gwidth
    local ydiv = vheight / gheight
    local left = (-vwidth/2.0) + xdiv * gxidx
    local right = left + xdiv
    local bottom = (-vheight/2.0) + ydiv * gyidx
    local top = bottom + ydiv

    m.projFrustum(mat, left, right,
                       bottom, top,
                        near, far)
end

-- matrix functions ported from threejs
-- https://github.com/mrdoob/three.js/blob/master/src/math/Matrix4.js

-- makes the matrix be a pure rotation from a quaternion
terra m.setMatrixFromQuat(mat: &float, quat: &vec4_)
    var x = quat.x
    var y = quat.y
    var z = quat.z
    var w = quat.w

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
terra m.scaleMatrix(mat: &float, s: &vec4_)
    mat[ 0 ]  = mat[0] * s.x
    mat[ 4 ]  = mat[4] * s.y
    mat[ 8 ]  = mat[8] * s.z
    mat[ 1 ]  = mat[1] * s.x
    mat[ 5 ]  = mat[5] * s.y
    mat[ 9 ]  = mat[9] * s.z
    mat[ 2 ]  = mat[2] * s.x
    mat[ 6 ]  = mat[6] * s.y
    mat[ 10 ] = mat[10] * s.z
    mat[ 3 ]  = mat[3] * s.x
    mat[ 7 ]  = mat[7] * s.y
    mat[ 11 ] = mat[11] * s.z
end

terra m.setMatrixPosition(mat: &float, p: &vec4_)
    mat[ 12 ] = p.x
    mat[ 13 ] = p.y
    mat[ 14 ] = p.z
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

-- multiplies a vec4 vsrc by matrix a and puts the result into vdest
-- safe to use inplace (vsrc == vdest)
terra m.multiplyMatrixVector(a: &float, vsrc: &vec4_, vdest: &vec4_)
    var v0 = vsrc.x
    var v1 = vsrc.y
    var v2 = vsrc.z
    var v3 = vsrc.w

    vdest.x = a[0]*v0 + a[4]*v1 + a[ 8]*v2 + a[12]*v3
    vdest.y = a[1]*v0 + a[5]*v1 + a[ 9]*v2 + a[13]*v3
    vdest.z = a[2]*v0 + a[6]*v1 + a[10]*v2 + a[14]*v3
    vdest.w = a[3]*v0 + a[7]*v1 + a[11]*v2 + a[15]*v3
end

-- multiplies a 4x4 matrix by a scalar in place
terra m.multiplyMatrixScalar(mat: &float, scale: float)
    -- note terra is 0 indexed so this is like a c loop
    for i = 0,16 do
        mat[i] = mat[i] * scale
    end
end

-- transposes a matrix in place
terra m.transposeMatrix(a: &float)
    var      a12, a13, a14 =         a[ 4 ], a[ 8 ], a[ 12 ]
    var a21,      a23, a24 = a[ 1 ],         a[ 9 ], a[ 13 ]
    var a31, a32,      a34 = a[ 2 ], a[ 6 ],         a[ 14 ]
    var a41, a42, a43      = a[ 3 ], a[ 7 ], a[ 11 ]
            a[ 4 ], a[ 8 ], a[ 12 ] =      a21, a31, a41
    a[ 1 ],         a[ 9 ], a[ 13 ] = a12,      a32, a42
    a[ 2 ], a[ 6 ],         a[ 14 ] = a13, a23,      a43
    a[ 3 ], a[ 7 ], a[ 11 ]         = a14, a24, a34
end

-- gets the inverse of a 4x4 matrix
-- safe to use in place (src == dest)
terra m.getMatrixInverse(dest: &float, src: &float)
        -- based on http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm
        var n11, n12, n13, n14 = src[ 0 ], src[ 4 ], src[ 8 ],  src[ 12 ]
        var n21, n22, n23, n24 = src[ 1 ], src[ 5 ], src[ 9 ],  src[ 13 ]
        var n31, n32, n33, n34 = src[ 2 ], src[ 6 ], src[ 10 ], src[ 14 ]
        var n41, n42, n43, n44 = src[ 3 ], src[ 7 ], src[ 11 ], src[ 15 ]

        dest[ 0 ] = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44
        dest[ 4 ] = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44
        dest[ 8 ] = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44
        dest[ 12 ] = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34
        dest[ 1 ] = n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44
        dest[ 5 ] = n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 * n44
        dest[ 9 ] = n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 * n44
        dest[ 13 ] = n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 * n34
        dest[ 2 ] = n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 * n44
        dest[ 6 ] = n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 * n44
        dest[ 10 ] = n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 * n44
        dest[ 14 ] = n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 * n34
        dest[ 3 ] = n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 * n43
        dest[ 7 ] = n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 * n43
        dest[ 11 ] = n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 * n43
        dest[ 15 ] = n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 * n33

        var det = n11 * dest[ 0 ] + n21 * dest[ 4 ] + n31 * dest[ 8 ] + n41 * dest[ 12 ]

        if det == 0.0 then
            m.setIdentity(dest)
        else
            m.multiplyMatrixScalar(dest, 1.0 / det)
        end
end

-- assumes pure rotation upper 3x3 (unscaled)
terra m.matrixToQuaternion(src: &float, dest: &vec4_)
    var m11, m12, m13 = src[ 0 ], src[ 4 ], src[ 8 ]
    var m21, m22, m23 = src[ 1 ], src[ 5 ], src[ 9 ]
    var m31, m32, m33 = src[ 2 ], src[ 6 ], src[ 10 ]

    var trace = m11 + m22 + m33
    var s: float = 0.0

    if trace > 0.0 then
        s = 0.5 / CMath.sqrt( trace + 1.0 )
        dest.w = 0.25 / s
        dest.x = ( m32 - m23 ) * s
        dest.y = ( m13 - m31 ) * s
        dest.z = ( m21 - m12 ) * s
    elseif m11 > m22 and m11 > m33 then
        s = 2.0 * CMath.sqrt( 1.0 + m11 - m22 - m33 )
        dest.w = ( m32 - m23 ) / s
        dest.x = 0.25 * s
        dest.y = ( m12 + m21 ) / s
        dest.z = ( m13 + m31 ) / s
    elseif m22 > m33 then
        s = 2.0 * CMath.sqrt( 1.0 + m22 - m11 - m33 )
        dest.w = ( m13 - m31 ) / s
        dest.x = ( m12 + m21 ) / s
        dest.y = 0.25 * s
        dest.z = ( m23 + m32 ) / s
    else
        s = 2.0 * CMath.sqrt( 1.0 + m33 - m11 - m22 )
        dest.w = ( m21 - m12 ) / s
        dest.x = ( m13 + m31 ) / s
        dest.y = ( m23 + m32 ) / s
        dest.z = 0.25 * s
    end
end

terra m.matrixCopy(dest: &float, src: &float)
    for i = 0,16 do
        dest[i] = src[i]
    end
end

local Matrix4 = class("Matrix4")

function Matrix4:init()
    self.data = terralib.new(float[16])
    self.elem = self.data
end

function Matrix4:identity()
    m.setIdentity(self.data)
    return self
end

function Matrix4:zero()
    m.zeroMatrix(self.data)
    return self
end

function Matrix4:copy(src)
    m.matrixCopy(self.data, src.data)
    return self
end

function Matrix4:clone()
    local ret = Matrix4()
    ret:copy(self)
    return ret
end

function Matrix4:fromCArray(arr)
    -- both arrays are zero indexed
    for i = 0,15 do
        self.data[i] = arr[i]
    end
    return self
end

function Matrix4:fromArray(arr)
    for i = 1,16 do
        -- self.data is zero indexed
        self.data[i-1] = arr[i]
    end
    return self
end

function Matrix4:transpose()
    m.transposeMatrix(self.data)
    return self
end

function Matrix4:toArray()
    local ret = {}
    for i = 1,16 do
        -- self.data is zero indexed
        ret[i] = self.data[i-1]
    end
    return ret
end

function Matrix4:fromQuaternion(q)
    local e = q.elem
    m.setMatrixFromQuat(self.data, e.x, e.y, e.z, e.w)
    return self
end

function Matrix4:toQuaternion()
    -- import 'late' to avoid mutual recursion issues
    local quat = require("math/quat.t")
    local qret = quat.Quaternion()
    m.matrixToQuaternion(self.data, qret.elem)
    return qret
end

function Matrix4:scale(scaleVec)
    m.scaleMatrix(self.data, scaleVec.elem)
    return self
end

function Matrix4:setTranslation(posVec)
    m.setMatrixPosition(self.data, posVec.elem)
    return self
end

function Matrix4:makeTranslation(v)
    self:identity()
    return self:setTranslation(v)
end

-- takes a translation (vec3), rotation (quaternion), and scale (vec3) and
-- and composes them together into one 4x4 transformation
function Matrix4:compose(posVec, rotationQuat, scaleVec)
    local destmat = self.data
    m.setMatrixFromQuat(destmat, rotationQuat.elem)
    m.scaleMatrix(destmat, scaleVec.elem)
    m.setMatrixPosition(destmat, posVec.elem)
    return self
end

-- like compose, but without a scale component
function Matrix4:composeRigid(posVec, rotationQuat)
    local destmat = self.data
    m.setMatrixFromQuat(destmat, rotationQuat.elem)
    m.setMatrixPosition(destmat, posVec.elem)
    return self
end

-- if src==nil (or not provided), then inverts the matrix
-- itself in place, otherwise inverts src into this matrix
function Matrix4:invert(src)
    src = src or self
    m.getMatrixInverse(self.data, src.data)
    return self
end

-- matrix multiplication:
-- if one argument is provided,
-- self = self * a
-- if two arguments are provided,
-- self = a * b
function Matrix4:multiply(a, b)
    if b == nil then
        m.multiplyMatrices(self.data, self.data, a.data)
    else
        m.multiplyMatrices(self.data, a.data, b.data)
    end
    return self
end

-- matrix multiplication on left:
-- self = b * self
function Matrix4:leftMultiply(b)
    m.multiplyMatrices(self.data, b.data, self.data)
    return self
end

-- matrix multiplication:
-- self = a * b
function Matrix4:multiplyInto(a,b)
    m.multiplyMatrices(self.data, a.data, b.data)
    return self
end

-- matrix*vector multiplication, in place
-- i.e. v <- M * v
function Matrix4:multiplyVector(v)
    m.multiplyMatrixVector(self.data, v.elem, v.elem)
    return v
end

-- Note: this is 1-indexed, so the columns are 1,2,3,4
function Matrix4:getColumn(idx, dest)
    if idx <= 0 or idx > 4 then
        log.error("Error: Matrix4:getColumn expects index in range [1,4], got " .. idx)
        return nil
    end
    local s = (idx-1)*4
    local d = self.data
    if not dest then
        local Vector = require("math/vec.t").Vector
        dest = Vector()
    end
    dest:set(d[s], d[s+1], d[s+2], d[s+3])
    return dest
end

function Matrix4:setColumn(idx, src)
    if idx <= 0 or idx > 4 then
        log.error("Error: Matrix4:getColumn expects index in range [1,4], got " .. idx)
        return nil
    end
    local s = (idx-1)*4
    local d = self.data
    local e = src.elem
    d[s], d[s+1], d[s+2], d[s+3] = e.x, e.y, e.z, e.w
    return self
end

function Matrix4:fromBasis(basisVecList)
    for columnIdx, basisVec in ipairs(basisVecList) do
        self:setColumn(columnIdx, basisVec)
    end
    return self
end

function Matrix4:prettystr()
    local ret = "Matrix4 {"
    local data = self.data
    for row = 0,3 do
        if row > 0 then
            ret = ret .. "         "
        end
        local p = row
        -- column major
        local a,b,c,d = data[p], data[p+4], data[p+8], data[p+12]
        ret = ret .. ("{%.2f, %.2f, %.2f, %.2f}"):format(a,b,c,d)
        if row < 3 then ret = ret .. ",\n" end
    end
    ret = ret .. "}"
    return ret
end

function Matrix4:fromPrettyArray(parr)
    local data = self.data
    -- column major
    for row = 0,3 do
        local p = row
        local src = parr[p+1]
        data[p], data[p+4], data[p+8], data[p+12] = src[1],src[2],src[3],src[4]
    end
end

function Matrix4:__tostring()
    return self:prettystr()
end

-- fovy in degrees
function Matrix4:makeProjection(fovy, aspect, near, far)
    self:zero()
    m.makeProjMat(self.data, fovy, aspect, near, far)
    return self
end

function Matrix4:makeOrthographicProjection(left, right, bottom, top, near, far)
    m.orthoProjMat(self.data, left, right,
                              bottom, top,
                              near, far)
end

function Matrix4:flipViewHandedness()
    m.flipViewMatrixHandedness(self.data, self.data)
    return self
end

function Matrix4:flipProjHandedness()
    m.flipProjMatrixHandedness(self.data, self.data)
    return self
end

-- 'export' the class
m.Matrix4 = Matrix4
m.Mat4    = Matrix4 -- shorter alias

return m
