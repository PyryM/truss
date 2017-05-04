-- io/websocket.t
--
-- a websocket wrapper

local class = require("class")
local json = require("lib/json.lua")

local websocket = {}
local WebSocketConnection = class("WebSocketConnection")

local numsockets = 0

local ws_addon = truss.addons.wsclient.functions
local ws_addon_ptr = truss.addons.wsclient.pointer

function WebSocketConnection:init()
  self.open = false
  self.decode_json = false
  self.id = -1
end

function WebSocketConnection:is_open()
  return self.open
end

function WebSocketConnection:connect(url)
  if self.open then self:disconnect() end
  self.id = ws_addon.truss_wsclient_open(ws_addon_ptr, tostring(url))
  self.open = (self.id >= 0)
  log.debug("Websocket connection opened on id " .. self.id)
  return self.open
end

function WebSocketConnection:disconnect(url)
  ws_addon.truss_wsclient_close(ws_addon_ptr, self.id)
  self.open = false
end

function WebSocketConnection:update()
  if not self.open then return end

  local nmessages = ws_addon.truss_wsclient_receive(ws_addon_ptr, self.id)
  if nmessages < 0 then
    log.error("Websocket connection broken or closed remotely.")
    self.open = false
    return
  end

  if not self.callback then return end

  if self.decode_json then
    for i = 1,nmessages do
      local rawstr = ws_addon.truss_wsclient_getmessage(ws_addon_ptr, self.id, i - 1)
      local msgstr = ffi.string(rawstr)
      local obj = json:decode(msgstr)
      self.callback(obj)
    end
  else
    for i = 1,nmessages do
      local rawstr = ws_addon.truss_wsclient_getmessage(ws_addon_ptr, self.id, i - 1)
      local msgstr = ffi.string(rawstr)
      self.callback(msgstr)
    end
  end
end

function WebSocketConnection:on_json(cbfunc)
  self.decode_json = true
  self:on_message(cbfunc)
end

function WebSocketConnection:on_message(cbfunc)
  if self.callback then
    log.warn("Warning: WebSocketConnection already had callback,")
    log.warn("existing callback will be replaced.")
  end
  self.callback = cbfunc
end

function WebSocketConnection:send(msgstr)
  if not self.open then return end
  ws_addon.truss_wsclient_send(ws_addon_ptr, self.id, tostring(msgstr))
end

function WebSocketConnection:send_json(obj)
  if not self.open then return end
  local jdata = json:encode(obj)
  ws_addon.truss_wsclient_send(ws_addon_ptr, self.id, jdata)
end

websocket.WebSocketConnection = WebSocketConnection
return websocket
