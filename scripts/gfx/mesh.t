local Mesh = class("Mesh")
function Mesh:init(geo, mat)
	self.geo = geo
	self.mat = mat
	self.material = mat

	self.matrix = Matrix4():identity()
	self.quaternion = Quaternion():identity()
	self.position = Vector(0.0, 0.0, 0.0)
	self.scale = Vector(1.0, 1.0, 1.0)

	self.visible = true
end

function Mesh:updateMatrix()
	self.matrix:compose(self.quaternion, self.scale, self.position)
end
