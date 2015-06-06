-- labels.t
--
-- implements on-screen labels

local class = truss_import("core/30log.t")
local Labels = class("Labels")

function Labels:init()
	self.labels = {}
	self.dirty = false
end

function Labels:addLabel(labelname, screenpos)
	self:updateLabel(labelname, screenpos)
end

function Labels:removeLabel(labelname)
	self.labels[labelname] = nil
end

function Labels:updateLabel(labelname, screenpos)
	self.labels[labelname] = {ax = screenpos.x or screenpos[1],
							  ay = screenpos.y or screenpos[2],
							  lx = 0,
							  ly = 0}
	self.dirty = true	
end

function Labels:update()
	if not self.dirty then return end
	self.dirty = false
end

function Labels:draw(nvg)
end