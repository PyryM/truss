-- ros.t
--
-- rosbridge communication

local class = require("class")
local websocket = require("io/websocket.t")
local json = require("lib/json.lua")

local Ros = class("Ros")
local Topic = class("Topic")
local Service = class("Service")

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

function Ros:addHandler_(topicname, handler)
    if self.topicHandlers[topicname] == nil then
        self.topicHandlers[topicname] = {}
    end
    self.topicHandlers[topicname][handler.subscribeId] = handler
end

function Ros:dispatchToTopic_(topicname, msg)
    local handlers = self.topicHandlers[topicname]
    if handlers then
        for _,handler in pairs(handlers) do handler:callback(msg) end
    end
end

function Ros:dispatchServiceResponse_(id, msg)
    -- todo
end

function Ros:onMessage(msg)
    local truemessage = json:decode(msg)
    if truemessage.op == "png" then
        if not self.pngwarning then
            log.warn("Warning: PNG ros messages not supported!")
            self.pngwarning = true
        end
    elseif truemessage.op == "publish" then
        self:dispatchToTopic_(truemessage.topic, truemessage.msg)
    elseif truemessage.op == "service_response" then
        self:dispatchServiceResponse_(truemessage.id, truemessage)
    else
        log.error("Unknown message op: " .. tostring(truemessage.op))
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

function Topic:callback(msg)
    -- default callback does nothing
end

function Topic:subscribe(callback)
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
    self.callback = callback
    self.ros:addHandler_(self.topicName, self)
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

----
-- A ROS service client.
--
-- @constructor
-- @params options - possible keys include:
--   -- ros - the ROSLIB.Ros connection handle
--   -- name - the service name, like /add_two_ints
--   -- serviceType - the service type, like 'rospy_tutorials/AddTwoInts'
--
function Service:init(ros, options)
    local options = options or {}
    self.ros = ros
    self.serviceName = options.name
    self.serviceType = options.serviceType
    self.isAdvertised = false
    self.serviceCallback = nil
end

----
-- Calls the service. Returns the service response in the callback.
--
-- @param request - the ROSLIB.ServiceRequest to send
-- @param callback - function with params:
--   -- response - the response from the service request
-- @param failedCallback - the callback function when the service call failed (optional). Params:
--   -- error - the error message reported by ROS
--/
function Service:callService(request, callback, failedCallback)
    if self.isAdvertised then return end

    local nextId = self.ros:nextId()
    local serviceCallId = 'call_service:' .. self.serviceName .. ':' .. nextId

    local cb = callback
    local failedcb = failedCallback
    self.ros:addServiceCallback_(serviceCallId, function(msg)
        if msg.result == false then
            failedcb(msg.values)
        else
            cb(msg.values)
        end
    end)

    local callmsg = {
        op = 'call_service',
        id = serviceCallId,
        service = self.serviceName,
        args = request
    }
    self.ros:sendRawJSON(callmsg)
end

--
--  Every time a message is published for the given topic, the callback
--  will be called with the message object.
--
--  @param callback - function with the following params:
--     message - the published message
--
function Service:advertise(callback)
    if self.isAdvertised then return end

    self._serviceCallback = callback
    self.ros:addServiceServer(self.serviceName, self)
    self.ros:sendRawJSON({
        op = 'advertise_service',
        type = self.serviceType,
        service = self.serviceName
    })
    self.isAdvertised = true
end

function Service:unadvertise()
    if not self.isAdvertised then return end

    self.ros:sendRawJSON({
        op = 'unadvertise_service',
        service = self.serviceName
    })
    self.isAdvertised = false
end

function Service:_serviceResponse(rosbridgeRequest)
    local response = {}
    local success = self._serviceCallback(rosbridgeRequest.args, response)

    local call = {
        op = 'service_response',
        service = self.name,
        values = response,
        result = success
    };

    if rosbridgeRequest.id then
        call.id = rosbridgeRequest.id
    end

    self.ros:sendRawJSON(call)
end

local ret = {Ros = Ros, Topic = Topic, Service = Service}
return ret
