-- Documentation Scaffold
-- ======================

-- This defines an application that uses co-routines to run documentation
-- examples as if they were simple linear scripts

-- It inherits from the basic AppScaffold which takes care of most of the
-- low-level bookkeeping
local class = require("class")
local AppScaffold = require("utils/appscaffold.t").AppScaffold
local DocScaffold = AppScaffold:extend("DocScaffold")

-- Script Management
-- -----------------

-- A script is simply a function(app) that is written as a list of things to do.
function DocScaffold:startScript(scriptFunction)
    self.script_ = coroutine.create(scriptFunction)
end

-- The script can output images to file
function DocScaffold:present(imageFilename)
    self:takeScreenshot(imageFilename)
    coroutine.yield()
end

-- Internally DocScaffold runs a normal per-frame update and uses co-routines
-- to make the script look like it's running in one continuous block.
function DocScaffold:continueScript()
    if not self.script_ then return end

    -- When running in multithreaded mode bgfx has a three frame delay, so to
    -- be safe between script resumes the application delays three frames
    if self.delayFramesLeft_ > 0 then
        self.delayFramesLeft_ = self.delayFramesLeft_ - 1
        return
    end
    self.delayFramesLeft_ = 3

    -- Examples can add a pre-resume function if they need to do some work here
    -- (for example, clearing the previous scene)
    if self.preResume then self:preResume() end

    -- The script will be called with the DocScaffold instance as its argument
    local running = coroutine.resume(self.script_, self)

    -- When the coroutine has ended, terminate the application
    if not running then
        truss.truss_stop_interpreter(core.TRUSS_ID)
        self.script_ = nil
    end
end

-- We override the default lights that AppScaffold sets because they do not
-- work well for perfectly axis-aligned objects like the examples will want
-- to make.
function DocScaffold:setDefaultLights()
    local Vector = require("math").Vector
    local forwardpass = self.forwardpass
    forwardpass.globals.lightDirs:setMultiple({
            Vector( 1.0,  1.0,  0.7),
            Vector(-1.0,  1.0,  1.0),
            Vector( 1.2, -1.0,  1.0),
            Vector( 0.4, -1.0, -1.0)})

    forwardpass.globals.lightColors:setMultiple({
            Vector(0.8, 0.8, 0.8),
            Vector(0.5, 0.5, 0.5),
            Vector(0.05, 0.05, 0.1),
            Vector(0.05, 0.05, 0.1)})
end


function DocScaffold:update()
    self:continueScript()
    DocScaffold.super.update(self)
end

function DocScaffold:init(options)
    DocScaffold.super.init(self,
        {   title = "Documentation Scaffold",
            width = options.width or 320,
            height = options.height or 320,
            usenvg = false })
    self.docOptions_ = options
    self.delayFramesLeft_ = 0
end

-- Modules export their classes/functions as the table they return
return {DocScaffold = DocScaffold}
