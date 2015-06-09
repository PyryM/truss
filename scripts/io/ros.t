-- ros.t
--
-- rosbridge communication

local class = truss_import("core/30log.lua")
local websocket = truss_import("io/websocket.t")
local json = truss_import("lib/json.lua")

local Ros = class("Ros")
local Topic = class("Topic")

function Ros:init()
    self.socket = websocket.WebSocketConnection()
    self.topicHandlers = {}
    self.idCounter = 0
    local this = self
    self.socket:onMessage(function(msg)
        this:onMessage(msg)
    end)
end

function Ros:connect(url)
    self.socket:connect(url)
end

function Ros:disconnect()
    self.socket:disconnect()
end

function Ros:update()
    self.socket:update()
end

function Ros:nextId()
    self.idCounter = self.idCounter + 1
    return self.idCounter
end

function Ros:dispatchToTopic_(topicname, msg)
    local handlers = self.topicHandlers[topicname]
    if handlers then
        for i,handlerfunc in handlers do handlerfunc(msg) end
    end
end

function Ros:dispatchServiceResponse_(id, msg)
    -- todo
end

function Ros:onMessage(msg)
    local truemessage = json:decode(msg)
    if truemessage.op == "png" then
        if not self.pngwarning then
            trss.trss_log(0, "Warning: PNG ros messages not supported!")
            self.pngwarning = true
        end
    elseif truemessage.op == "publish" then
        self:dispatchToTopic_(truemessage.topic, truemessage.msg)
    elseif truemessage.op == "service_response" then
        self:dispatchServiceResponse_(truemessage.id, truemessage)
    else
        trss.trss_log(0, "Unknown message op: " .. tostring(truemessage.op))
    end
end

function Ros:topic(options)
    return Topic(self, options)
end

function Topic:init(ros, options)
    self.ros = ros
    self.topicName = options.topicName
    self.messageType = options.messageType
    self.throttleRate = options.throttleRate or 0
    self.latch = options.latch or false
    self.queueSize = options.queueSize or 100
end

function Topic:subscribe()
    local nextid = self.ros:nextId()
    self.subscribeId = "subscribe:" .. self.topicName .. ":" .. nextid
    local submsg = {
        op = "subscribe",
        id = self.subscribeId,
        ["type"] = self.messageType,
        topic = self.topicName,
        compression = "none",
        throttle_rate = self.throttleRate or 0
    }
    self.ros:sendRawJSON(submsg)
end

function Topic:unsubscribe()
    local msg = {
        op = "unsubscribe",
        id = self.subscribeId,
        topic = self.topicName
    }
    self.ros:sendRawJSON(msg)
end

function Topic:advertise()
    if self.isAdvertised then return end
    local nextid = self.ros:nextId()
    self.advertiseId = 'advertise:' .. self.topicname .. ":" .. nextid
    local admsg = {
        op = "advertise",
        id = self.advertiseId,
        ["type"] = self.messageType,
        topic = self.topicname,
        latch = self.latch,
        queue_size = self.queueSize
    }
    self.isAdvertised = true
    self.ros:sendRawJSON(admsg)
end

function Topic:unadvertise()
    if not self.isAdvertised then return end
    local msg = {
        op = "unadvertise",
        id = self.advertiseId,
        topic = self.topicName
    }
    self.isAdvertised = false
    self.ros:sendRawJSON(msg)
end

function Topic:publish(msg)
    self:advertise()
    local nextid = self.ros:nextId()
    local callmsg = {
        op = "publish",
        id = "publish:" .. self.topicName .. ":" .. nextid,
        topic = self.topicName,
        msg = msg,
        latch = self.latch
    }
    self.ros:sendRawJSON(callmsg)
end

local ret = {Ros = Ros, Topic = Topic}
return ret
