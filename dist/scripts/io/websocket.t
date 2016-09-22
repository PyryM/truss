-- io/websocket.t
--
-- a websocket wrapper

local class = require("class")
local json = require("lib/json.lua")

local websocket = {}
local WebSocketConnection = class("WebSocketConnection")

local numsockets = 0

wsAddon = truss.rawAddons.wsclient.functions
wsAddonPointer = truss.rawAddons.wsclient.pointer

function WebSocketConnection:init()
    self.open = false
    self.decodeJSON = false
    self.id = -1
end

function WebSocketConnection:isOpen()
    return self.open
end

function WebSocketConnection:connect(url)
    if self.open then self:disconnect() end
    self.id = wsAddon.truss_wsclient_open(wsAddonPointer, tostring(url))
    self.open = (self.id >= 0)
    log.debug("Websocket connection opened on id " .. self.id)
    return self.open
end

function WebSocketConnection:disconnect(url)
    wsAddon.truss_wsclient_close(wsAddonPointer, self.id)
    self.open = false
end

function WebSocketConnection:update()
    if not self.open then return end

    local nmessages = wsAddon.truss_wsclient_receive(wsAddonPointer, self.id)
    if nmessages < 0 then
        log.error("Websocket connection broken or closed remotely.")
        self.open = false
        return
    end

    if not self.callback then return end

    if self.decodeJSON then
        for i = 1,nmessages do
            local rawstr = wsAddon.truss_wsclient_getmessage(wsAddonPointer, self.id, i - 1)
            local msgstr = ffi.string(rawstr)
            local obj = json:decode(msgstr)
            self.callback(obj)
        end
    else
        for i = 1,nmessages do
            local rawstr = wsAddon.truss_wsclient_getmessage(wsAddonPointer, self.id, i - 1)
            local msgstr = ffi.string(rawstr)
            self.callback(msgstr)
        end
    end
end

function WebSocketConnection:onJSON(cbfunc)
    self.decodeJSON = true
    self:onMessage(cbfunc)
end

function WebSocketConnection:onMessage(cbfunc)
    if self.callback then
        log.warn("Warning: WebSocketConnection already had callback,")
        log.warn("existing callback will be replaced.")
    end
    self.callback = cbfunc
end

function WebSocketConnection:send(msgstr)
    if not self.open then return end
    wsAddon.truss_wsclient_send(wsAddonPointer, self.id, tostring(msgstr))
end

function WebSocketConnection:sendJSON(obj)
    if not self.open then return end
    local jdata = json:encode(obj)
    wsAddon.truss_wsclient_send(wsAddonPointer, self.id, jdata)
end

websocket.WebSocketConnection = WebSocketConnection
return websocket
