-- io/websocket.t
--
-- a websocket wrapper

local class = require("class")
local json = require("lib/json.lua")

local websocket = {}
local WebSocketConnection = class("WebSocketConnection")

local numsockets = 0

wsAddon = raw_addons.wsclient.functions
wsAddonPointer = raw_addons.wsclient.pointer

function WebSocketConnection:init()
	if numsockets > 0 then
		log.warn("Warning: only one WebSocketConnection at a time is currently supported,")
		log.warn("but multiple WebSocketConnections have been created. They will all fight")
		log.warn("over the one connection.")
	end
	numsockets = numsockets + 1
	self.open = false
	self.decodeJSON = false
end

function WebSocketConnection:isOpen()
	return self.open
end

function WebSocketConnection:connect(url)
	if self.open then self:disconnect() end

	local success = wsAddon.trss_wsclient_open(wsAddonPointer, tostring(url))
	self.open = success
	return success
end

function WebSocketConnection:disconnect(url)
	wsAddon.trss_wsclient_close(wsAddonPointer)
	self.open = false
end

function WebSocketConnection:update()
	if not self.open then return end
	
	local nmessages = wsAddon.trss_wsclient_receive(wsAddonPointer)
	if nmessages < 0 then
		log.error("Websocket connection broken or closed remotely.")
		self.open = false
		return
	end

	if not self.callback then return end
	
	if self.decodeJSON then
		for i = 1,nmessages do
			local rawstr = wsAddon.trss_wsclient_getmessage(wsAddonPointer, i - 1)
			local msgstr = ffi.string(rawstr)
			local obj = json:decode(msgstr)
			self.callback(obj)
		end
	else
		for i = 1,nmessages do
			local rawstr = wsAddon.trss_wsclient_getmessage(wsAddonPointer, i - 1)
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
	wsAddon.trss_wsclient_send(wsAddonPointer, tostring(msgstr))
end

function WebSocketConnection:sendJSON(obj)
	if not self.open then return end
	local jdata = json:encode(obj)
	wsAddon.trss_wsclient_send(wsAddonPointer, jdata)
end

websocket.WebSocketConnection = WebSocketConnection
return websocket