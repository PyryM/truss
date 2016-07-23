-- gfx/workerstage.t
--
-- a stage that will execute jobs (one per frame)

local class = require("class")
local Queue = require("utils/queue.t").Queue
local m = {}

local WorkerStage = class("WorkerStage")
function WorkerStage:init(options)
    options = options or {}
    self.options_ = options
    self.queue_ = Queue()
    self.cbqueue_ = Queue()
end

function WorkerStage:addJob(job)
    self.queue_:push(job)
end

function WorkerStage:setupViews(startView)
    self.viewid = startView
    return startView + 1
end

function WorkerStage:render(context)
    -- inidicate to job completed last frame that it has rendered
    if self.cbqueue_:length() > 0 then
        local cb = self.cbqueue_:pop()
        if cb.finish then cb:finish(self) end
    end

    if self.queue_:length() <= 0 then return end
    local job = self.queue_:pop()
    if job.execute then job:execute(self, context) end
    if job.repeating then self:addJob(job) else self.cbqueue_:push(job) end
end

m.WorkerStage = WorkerStage
return m
