-- vec.t
--
-- vec4 math (incomplete)

local m = {}

local class = require("class")

local Vec4 = class("Vec4")
local matrix = require("math/matrix.t")

function Vec4:init()
	self.data_ = terralib.new(matrix.vec4_)
end

m.Vec4 = Vec4
return m