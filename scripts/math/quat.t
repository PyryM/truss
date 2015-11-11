-- quat.t
--
-- quaternion math
-- mostly copied from threejs 
--  (https://github.com/mrdoob/three.js/blob/master/src/math/Quaternion.js)

local m = {}

local class = require("class")

local Quaternion = class("Quaternion")

function Quaternion:init(x, y, z, w)
	self:set(x,y,z,w)
end

function Quaternion:set(x, y, z, w)
	self.x = x or 0.0
	self.y = y or 0.0
	self.z = z or 0.0
	self.w = w or 1.0
	return self
end

function Quaternion:copy(qright)
	self.x = qright.x
	self.y = qright.y
	self.z = qright.z
	self.w = qright.w
	return self
end

function Quaternion:fromArray(arr)
	self.x, self.y, self.z, self.w = unpack(arr)
	return self
end

function Quaternion:toArray()
	return {self.x, self.y, self.z, self.w}
end

-- basically unpack(q:toArray())
function Quaternion:components()
	return self.x, self.y, self.z, self.w
end

function Quaternion:fromEuler(euler, order)
	local c1 = math.cos( euler.x / 2 );
	local c2 = math.cos( euler.y / 2 );
	local c3 = math.cos( euler.z / 2 );
	local s1 = math.sin( euler.x / 2 );
	local s2 = math.sin( euler.y / 2 );
	local s3 = math.sin( euler.z / 2 );
	order = order or 'XYZ'

	if order == 'XYZ' then
		self.x = s1 * c2 * c3 + c1 * s2 * s3
		self.y = c1 * s2 * c3 - s1 * c2 * s3
		self.z = c1 * c2 * s3 + s1 * s2 * c3
		self.w = c1 * c2 * c3 - s1 * s2 * s3
	elseif order == 'YXZ' then
		self.x = s1 * c2 * c3 + c1 * s2 * s3
		self.y = c1 * s2 * c3 - s1 * c2 * s3
		self.z = c1 * c2 * s3 - s1 * s2 * c3
		self.w = c1 * c2 * c3 + s1 * s2 * s3
	elseif order == 'ZXY' then
		self.x = s1 * c2 * c3 - c1 * s2 * s3
		self.y = c1 * s2 * c3 + s1 * c2 * s3
		self.z = c1 * c2 * s3 + s1 * s2 * c3
		self.w = c1 * c2 * c3 - s1 * s2 * s3
	elseif order == 'ZYX' then
		self.x = s1 * c2 * c3 - c1 * s2 * s3
		self.y = c1 * s2 * c3 + s1 * c2 * s3
		self.z = c1 * c2 * s3 - s1 * s2 * c3
		self.w = c1 * c2 * c3 + s1 * s2 * s3
	elseif order == 'YZX' then
		self.x = s1 * c2 * c3 + c1 * s2 * s3
		self.y = c1 * s2 * c3 + s1 * c2 * s3
		self.z = c1 * c2 * s3 - s1 * s2 * c3
		self.w = c1 * c2 * c3 - s1 * s2 * s3
	elseif order == 'XZY' then
		self.x = s1 * c2 * c3 - c1 * s2 * s3
		self.y = c1 * s2 * c3 - s1 * c2 * s3
		self.z = c1 * c2 * s3 + s1 * s2 * c3
		self.w = c1 * c2 * c3 + s1 * s2 * s3
	end
	return self
end

function Quaternion:fromAxisAngle(axis, angle)
	local halfAngle = angle / 2
	local s = math.sin( halfAngle )

	self.x = axis.x * s
	self.y = axis.y * s
	self.z = axis.z * s
	self.w = math.cos( halfAngle )

	return self
end

-- makes the quaternion be the identity quaternion
function Quaternion:identity()
	self.x, self.y, self.z, self.w = 0.0, 0.0, 0.0, 1.0
	return self
end

function Quaternion:length()
	local x,y,z,w = self:components()
	return math.sqrt( x*x + y*y + z*z + w*w )
end

function Quaternion:normalize()
	local length = self:length()

	if length == 0 then
		self.x = 0
		self.y = 0
		self.z = 0
		self.w = 1
	else
		length = 1.0 / length

		self.x = self.x * length
		self.y = self.y * length
		self.z = self.z * length
		self.w = self.w * length
	end
	
	return self
end

function Quaternion:conjugate()
	self.x = self.x * -1
	self.y = self.y * -1
	self.z = self.z * -1

	return self
end

function Quaternion:invert()
	return self:conjugate():normalize()
end

-- Note: assumes m is a 4x4 matrix from matrix.4 (i.e., a terra float[16])
-- assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)
function Quaternion:fromRotationMatrix(m)
	-- Note: we import 'late' to avoid mutual import issues
	local matrix = require("math/matrix.t")

	return self:set(matrix.matrixToQuaternion(m.data))
end

function Quaternion:multiplyInto( a, b )
	--from http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/code/index.htm

	local qax, qay, qaz, qaw = a.x, a.y, a.z, a.w
	local qbx, qby, qbz, qbw = b.x, b.y, b.z, b.w

	self.x = qax * qbw + qaw * qbx + qay * qbz - qaz * qby
	self.y = qay * qbw + qaw * qby + qaz * qbx - qax * qbz
	self.z = qaz * qbw + qaw * qbz + qax * qby - qay * qbx
	self.w = qaw * qbw - qax * qbx - qay * qby - qaz * qbz

	return self
end

function Quaternion:prettystr()
	return "<" .. self.x .. ", " 
			   .. self.y .. ", " 
			   .. self.z .. ", " 
			   .. self.w .. ">"
end

-- 'export' classes
m.Quaternion = Quaternion
return m