-- gfx/blitstage.t
--
-- a stage to perform a blit operation

local class = require("class")
local Queue = require("utils/queue.t").Queue
local m = {}

local BlitStage = class("BlitStage")
function BlitStage:init(options)
    options = options or {}
    self.options_ = options
    self.queue_ = Queue()
    self.cbqueue_ = Queue()
end

function BlitStage:setupViews(startView)
    self.viewid_ = startView
    return startView + 1
end

function BlitStage:render(context)
    if self.cbqueue_:length() > 0 then
        local cb = self.cbqueue_:pop()
        cb()
    end

    if self.queue_:length() <= 0 then return end
    local blitop = self.queue_:pop()


    if blitop.callback then self.cbqueue_:push(blitop.callback) end
end

local BlitJob = class("BlitJob")
function BlitJob:init(options)
    self.blitop = options or {}
end

function BlitJob:readRenderTarget(rt, attachmentIdx)
    local rbb = rt:getReadBackBuffer(attachmentIdx or 1)
    self.blitop.blitSrc = rbb.src
    self.blitop.blitTarget = rbb.dest
    self.blitop.readTarget = rbb.buffer
    self.blitop.width = rt.width
    self.blitop.height = rt.height
    return self
end

function BlitJob:onFinish(cb)
    self.callback = cb
end

function BlitJob:execute(worker, context)
    local blitop = self.blitop
    local dMip = blitop.destMip or 0
    local dX = blitop.destX or 0
    local dY = blitop.destY or 0
    local dZ = blitop.destFace or 0
    local sMip = blitop.srcMip or 0
    local sX = blitop.srcX or 0
    local sY = blitop.srcY or 0
    local sZ = blitop.srcFace or 0
    local w = blitop.width
    local h = blitop.height
    local d = blitop.depth or 0

    log.info("blit viewid: " .. worker.viewid)
    log.info("w: " .. w .. ", h: " .. h .. ", d: " .. d)
    log.info("src: " .. tostring(blitop.blitSrc.idx))
    log.info("dest: " .. tostring(blitop.blitTarget.idx))
    bgfx.bgfx_blit(worker.viewid, blitop.blitTarget, dMip, dX, dY, dZ,
                                  blitop.blitSrc, sMip, sX, sY, sZ, w, h, d)

    if blitop.readTarget ~= nil then
        log.info("Reading back texture?")
        bgfx.bgfx_read_texture(blitop.blitTarget, blitop.readTarget.data)
    end
    log.info("Blitjob executed!")
end

function BlitJob:finish(worker)
    log.info("Blitjob finished!")
    if self.callback then self.callback(self, worker) end
end

m.BlitStage = BlitStage
m.BlitJob = BlitJob
return m
