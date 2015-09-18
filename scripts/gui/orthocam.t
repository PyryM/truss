-- orthocam.t
--
-- functions for creating an orthographic camera

local m = {}

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

return m