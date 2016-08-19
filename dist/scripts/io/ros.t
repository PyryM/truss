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
    self.serviceReponseCallbacks = {}
    self.serviceHandlers = {}
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

function Ros:addHandler_(handler)
    if self.topicHandlers[handler.topicName] == nil then
        self.topicHandlers[handler.topicName] = {}
    end
    self.topicHandlers[handler.topicName][handler.subscribeId] = handler
end

function Ros:removeHandler_(handler)
    self.topicHandlers[handler.topicName][handler.subscribeId] = nil
end

function Ros:dispatchToTopic_(topicName, msg)
    local handlers = self.topicHandlers[topicName]
    if handlers then
        for _,handler in pairs(handlers) do handler:callback(msg) end
    end
end

function Ros:addServiceCallback_(id, cbfunc)
    self.serviceReponseCallbacks[id] = cbfunc
end

function Ros:dispatchServiceResponse_(id, msg)
    local callback = self.serviceReponseCallbacks[id]
    self.serviceReponseCallbacks[id] = nil
    if callback then
        callback(msg)
    end
end

function Ros:addServiceHandler_(servicename, service)
    self.serviceHandlers[servicename] = service
end

function Ros:dispatchServiceCall_(servicename, msg)
    local service = self.serviceHandlers[servicename]
    if service then service:serviceResponse_(msg) end
end

function Ros:onMessage(rawmsg)
    local message = json:decode(rawmsg)
    if message.op == "png" then
        if not self.pngwarning then
            log.warn("Warning: PNG ros messages not supported!")
            self.pngwarning = true
        end
    elseif message.op == "publish" then
        self:dispatchToTopic_(message.topic, message.msg)
    elseif message.op == "service_response" then
        self:dispatchServiceResponse_(message.id, message)
    elseif message.op == "call_service" then
        self:dispatchServiceCall_(message.service, message)
    else
        log.error("Unknown message op: " .. tostring(message.op))
    end
end

function Ros:topic(options)
    return Topic(self, options)
end

function Ros:sendRawJSON(msg)
    self.socket:sendJSON(msg)
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
    self.ros:addHandler_(self)
    self.ros:sendRawJSON(submsg)
end

function Topic:unsubscribe()
    local msg = {
        op = "unsubscribe",
        id = self.subscribeId,
        topic = self.topicName
    }
    self.ros:removeHandler_(self)
    self.ros:sendRawJSON(msg)
end

function Topic:advertise()
    if self.isAdvertised then return end
    local nextid = self.ros:nextId()
    self.advertiseId = 'advertise:' .. self.topicName .. ":" .. nextid
    local admsg = {
        op = "advertise",
        id = self.advertiseId,
        ["type"] = self.messageType,
        topic = self.topicName,
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

    self.serviceCallback_ = callback
    self.ros:addServiceHandler_(self.serviceName, self)
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

function Service:serviceResponse_(rosbridgeRequest)
    local response = {}
    local success = self.serviceCallback_(rosbridgeRequest.args, response)

    local call = {
        op = 'service_response',
        service = self.name,
        values = response,
        result = success
    }

    if rosbridgeRequest.id then
        call.id = rosbridgeRequest.id
    end

    self.ros:sendRawJSON(call)
end

local ret = {Ros = Ros, Topic = Topic, Service = Service}
return ret
