-- buildshaders.t
--
-- just runs shaders through shaderc
-- TODO: actually implement this

local function makeDX11BuildCommand(src, dest)
end

local function makeDX9BuildCommand(src, dest)
end

local function makeOpenGLBuildCommand(src, dest)
end

local commandBuilders = {makeDX9BuildCommand, 
						 makeDX11BuildCommand,
						 makeOpenGLBuildCommand}