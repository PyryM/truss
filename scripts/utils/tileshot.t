-- tileshot.t
--
-- simplifies setting up tiled high-res screenshots

local class = truss_import("core/30log.lua")
local matrix = truss_import("math/matrix.t")
local Matrix4 = matrix.Matrix4

local TileShot = class("TileShot")


function TileShot:init(inoptions)
	local options = inoptions or {}
	self.fovy = options.fov or 60.0
	self.gridrows = options.gridrows or 3
	self.gridcols = options.gridcols or 3
	self.near = options.near or 0.05
	self.far = options.far or 100.0
	self.aspect = options.aspect or 1.0
	self.fn = options.fn or "_"
	self.mat = Matrix4()
	self.shots = {}
	self.curshot = 0
end

function TileShot:start()
	self.shots = {}
	for row = 0,self.gridrows-1 do
		for col = 0,self.gridcols-1 do
			table.insert(self.shots, {col, row})
		end
	end

	self.curshot = 0
end

function TileShot:shotsLeft()
	return #(self.shots) - self.curshot
end

function TileShot:nextShot()
	self.mat:zero()
	self.curshot = self.curshot + 1
	local curshot = self.shots[self.curshot]
	if not curshot then return nil end
	matrix.makeTiledProjection(self.mat.data, 
								self.fovy, self.aspect, 
								self.near, self.far, 
								self.gridcols, self.gridrows, 
								curshot[1], curshot[2])
	local fn = self.fn .. curshot[1] .. "x" .. curshot[2]
	return self.mat, fn
end

function TileShot:getMatrix()
	return self.mat
end

return TileShot