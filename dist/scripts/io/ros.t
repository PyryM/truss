-- ros.t
--
-- rosbridge communication

local class = require("class")
local websocket = require("io/websocket.t")

local Ros = class("Ros")
local Topic = class("Topic")
local Service = class("Service")

function Ros:init()
  self.socket = websocket.WebSocketConnection()
  self.topic_handlers = {}
  self.service_response_callbacks = {}
  self.service_handlers = {}
  self.id_counter = 0
  local this = self
  self.socket:on_json(function(msg)
    this:on_message(msg)
  end)
end

function Ros:connect(url)
  return self.socket:connect(url)
end

function Ros:disconnect()
  self.socket:disconnect()
end

function Ros:update()
  self.socket:update()
end

function Ros:next_id()
  self.id_counter = self.id_counter + 1
  return self.id_counter
end

function Ros:_add_handler(handler)
  if self.topic_handlers[handler.topic_name] == nil then
    self.topic_handlers[handler.topic_name] = {}
  end
  self.topic_handlers[handler.topic_name][handler.subscribe_id] = handler
end

function Ros:_remove_handler(handler)
  self.topic_handlers[handler.topic_name][handler.subscribe_id] = nil
end

function Ros:_dispatch_to_topic(topic_name, msg)
  local handlers = self.topic_handlers[topic_name]
  if handlers then
    for _, handler in pairs(handlers) do handler:callback(msg) end
  end
end

function Ros:_add_service_callback(id, cbfunc)
    self.service_response_callbacks[id] = cbfunc
end

function Ros:_dispatch_service_response(id, msg)
  local callback = self.service_response_callbacks[id]
  self.service_response_callbacks[id] = nil
  if callback then
    callback(msg)
  end
end

function Ros:_add_service_handler(service_name, service)
  self.service_handlers[service_name] = service
end

function Ros:_dispatch_service_call(service_name, msg)
  local service = self.service_handlers[service_name]
  if service then service:_service_response(msg) end
end

function Ros:on_message(message)
  if message.op == "png" then
    if not self.pngwarning then
      log.warn("Warning: PNG ros messages not supported!")
      self.pngwarning = true
    end
  elseif message.op == "publish" then
    self:_dispatch_to_topic(message.topic, message.msg)
  elseif message.op == "service_response" then
    self:_dispatch_service_response(message.id, message)
  elseif message.op == "call_service" then
    self:_dispatch_service_call(message.service, message)
  else
    log.error("Unknown message op: " .. tostring(message.op))
  end
end

function Ros:topic(options)
  return Topic(self, options)
end

function Ros:send_raw_json(msg)
  self.socket:send_json(msg)
end

function Topic:init(ros, options)
  self.ros = ros
  self.topic_name = options.topic_name
  self.message_type = options.message_type
  self.throttle_rate = options.throttle_rate or 0
  self.latch = options.latch or false
  self.queue_size = options.queue_size or 100
end

function Topic:callback(msg)
  -- default callback does nothing
end

function Topic:subscribe(callback)
  local next_id = self.ros:next_id()
  self.subscribe_id = "subscribe:" .. self.topic_name .. ":" .. next_id
  local submsg = {
    op = "subscribe",
    id = self.subscribe_id,
    ["type"] = self.message_type,
    topic = self.topic_name,
    compression = "none",
    throttle_rate = self.throttle_rate or 0
  }
  self.callback = callback
  self.ros:_add_handler(self)
  self.ros:send_raw_json(submsg)
end

function Topic:unsubscribe()
  local msg = {
    op = "unsubscribe",
    id = self.subscribe_id,
    topic = self.topic_name
  }
  self.ros:_remove_handler(self)
  self.ros:send_raw_json(msg)
end

function Topic:advertise()
  if self.is_advertised then return end
  local next_id = self.ros:next_id()
  self.advertise_id = 'advertise:' .. self.topic_name .. ":" .. next_id
  local admsg = {
    op = "advertise",
    id = self.advertise_id,
    ["type"] = self.message_type,
    topic = self.topic_name,
    latch = self.latch,
    queue_size = self.queue_size
  }
  self.is_advertised = true
  self.ros:send_raw_json(admsg)
end

function Topic:unadvertise()
  if not self.is_advertised then return end
  local msg = {
    op = "unadvertise",
    id = self.advertise_id,
    topic = self.topic_name
  }
  self.is_advertised = false
  self.ros:send_raw_json(msg)
end

function Topic:publish(msg)
  self:advertise()
  local next_id = self.ros:next_id()
  local callmsg = {
    op = "publish",
    id = "publish:" .. self.topic_name .. ":" .. next_id,
    topic = self.topic_name,
    msg = msg,
    latch = self.latch
  }
  self.ros:send_raw_json(callmsg)
end

----
-- A ROS service client.
--
-- @constructor
-- @params options - possible keys include:
--   -- ros - the ROSLIB.Ros connection handle
--   -- name - the service name, like /add_two_ints
--   -- service_type - the service type, like 'rospy_tutorials/AddTwoInts'
--
function Service:init(ros, options)
  local options = options or {}
  self.ros = ros
  self.service_name = options.name
  self.service_type = options.service_type
  self.is_advertised = false
  self.service_callback = nil
end

----
-- Calls the service. Returns the service response in the callback.
--
-- @param request - the ROSLIB.ServiceRequest to send
-- @param callback - function with params:
--   -- response - the response from the service request
-- @param fail_callback - the callback function when the service call failed (optional). Params:
--   -- error - the error message reported by ROS
--/
function Service:call(request, callback, fail_callback)
  if self.is_advertised then return end

  local next_id = self.ros:next_id()
  local call_id = 'call_service:' .. self.service_name .. ':' .. next_id

  local cb = callback
  local failedcb = fail_callback
  self.ros:_add_service_callback(call_id, function(msg)
    if msg.result == false then
      failedcb(msg.values)
    else
      cb(msg.values)
    end
  end)

  local callmsg = {
    op = 'call_service',
    id = call_id,
    service = self.service_name,
    args = request
  }
  self.ros:send_raw_json(callmsg)
end

--
--  Every time a message is published for the given topic, the callback
--  will be called with the message object.
--
--  @param callback - function  callback(arg) -> success, result
--
function Service:advertise(callback)
  if self.is_advertised then return end

  self._service_callback = callback
  self.ros:_add_service_handler(self.service_name, self)
  self.ros:send_raw_json({
    op = 'advertise_service',
    type = self.service_type,
    service = self.service_name
  })
  self.is_advertised = true
end

function Service:unadvertise()
  if not self.is_advertised then return end

  self.ros:send_raw_json({
    op = 'unadvertise_service',
    service = self.service_name
  })
  self.is_advertised = false
end

function Service:_service_response(request)
  local success, response = self._service_callback(request.args)
  local msg = {
    op = 'service_response',
    service = self.name,
    values = response,
    result = success,
    id = request.id
  }
  self.ros:send_raw_json(msg)
end

local ret = {Ros = Ros, Topic = Topic, Service = Service}
return ret
