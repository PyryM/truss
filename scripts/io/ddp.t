-- ddp.t
--
-- implements the meteor ddp protocol

websocket = truss_import("io/websocket.t")
class = truss_import("core/30log.lua")

DDP = class("DDP")
DDPReturn = class("DDPReturn")

function DDPReturn:init()
	self.complete = false
end

function DDPReturn:onError(f)
	self.onError = f
	return self
end

function DDPReturn:onResult(f)
	self.onResult = f
	return self
end

function DDPReturn:result_(resultval, errorval)
	self.complete = true
	self.errormsg = errorval
	self.value = resultval
	if self.onError and errorval then
		self.onError(errorval)
	end
	if self.onResult then
		self.onResult(resultval)
	end
end

function DDP:init()
	self.collections = {}

	self.readysubs = {}
	self.submap_ = {}
	self.returns_ = {}
	self.socket_ = websocket.WebSocketConnection()
	self.socket_.decodeJSON = true
	local closureSelf = self
	self.socket_:onMessage(function(msg)
		closureSelf:onMessage(msg)
	end)

	self.connected = false

	self.handlers_ = {
		connected = self.sConnected,
		failed = self.sFailed,
		ping = self.sPing,
		pong = self.sPong,
		nosub = self.sNosub,
		added = self.sChanged,  -- changed handler does double-duty
		changed = self.sChanged,
		removed = self.sRemoved,
		ready = self.sReady,
		addedBefore = self.sUnsupported,
		movedBefore = self.sUnsupported,
		result = self.sResult,
		updated = self.sUnsupported
	}
end

function DDP:sResult(msg)
	local retobj = self.returns_[msg.id]
	if retobj then
		retobj:result_(msg.result, msg.error)
	else
		trss.trss_log(0, "Got result id=[" .. tostring(msg.id) 
			.. "] with no corresponding method call!")
	end
end

function DDP:sUnsupported(msg)
	trss.trss_log(0, "DDP implementation does not support " .. msg.msg)
end

function DDP:sReady(msg)
	for i,sub in ipairs(msg.subs) do
		self.readysubs[sub] = true
	end
end

function DDP:getCollection(colname)
	if self.collections[colname] == nil then
		self.collections[colname] = {}
	end
	return self.collections[colname]
end

function DDP:getDocument(colname, id)
	if self.collections[colname] == nil then
		self.collections[colname] = {}
	end
	local col = self.collections[colname]
	if col[id] == nil then
		col[id] = {}
		if self.additionListener then
			self.additionListener(colname, id, col[id])
		end
	end
	return col[id]
end

function DDP:removeDocument(colname id)
	local col = self.collections[colname]
	if not col then return end
	if col[id] and col[id].removed__ then
		col[id]:removed__()
	end
	col[id] = nil
end

-- Note: NOT a recursive merge, so if a field
-- is itself a table, then that entire table
-- will get overwritten in the document
local function mergeIntoDocument(doc, fields)
	if not fields then return end
	for k,v in pairs(fields) do
		doc[k] = v
	end
end

local function clearFields(doc, fieldlist)
	if not fieldlist then return end
	for i,fname in ipairs(fieldlist) do
		doc[fname] = nil
	end
end

function DDP:sChanged(msg)
	local doc = self:getDocument(msg.collection, msg.id)
	mergeIntoDocument(doc, msg.fields)
	clearFields(doc, msg.cleared)
	if doc.changed__ then
		doc:changed__(msg)
	end
end

function DDP:sRemoved(msg)
	self:removeDocument(msg.collection, msg.id)
end

function DDP:sNosub(msg)
	local tname = self.submap_[msg.id]
	trss.trss_log(0, "Error subscribing to " .. tostring(tname) .. ":"
					.. tostring(msg.error))
end

function DDP:sPing(msg)
	local pongmsg = {
		msg = "pong",
		id = msg.id
	}
	self.socket_:sendJSON(pongmsg)
end

function DDP:sPong(msg)
	-- don't care!
end

function DDP:sConnected(msg)
	trss.trss_log(0, "DDP Connection Established.")
	self.connected = true
end

function DDP:sFailed(msg)
	trss.trss_log(0, "DDP Connection Rejected!")
	trss.trss_log(0, "Server wants protocol version: " .. tostring(msg.version))
end

function DDP:onMessage(msg)
	local handler = self.handlers_[msg.msg]
	if handler then
		handler(self, msg)
	else
		trss.trss_log(0, "Unknown DDP message: " .. tostring(msg.msg))
	end
end

function DDP:connect(url)
	self.socket_:connect(url)
	local connmsg = {
		msg = "connect",
		version = "1",
		support = {"1"}
	}
	self.socket_:sendJSON(connmsg)
end

function DDP:sub(topicName, params)
	local id = tostring(self:nextId())
	local submsg = {
		msg = "sub",
		id = id,
		name = topicName,
		params = params
	}
	self.submap_[id] = topicName
	self.socket_:sendJSON(submsg)
	return id
end

function DDP:unsub(id)
	local unsubmsg = {
		msg = "unsub",
		id = id
	}
	self.socket_:sendJSON(unsubmsg)
end

function DDP:nextId()
	self.nextid_ = (self.nextid_ or 0) + 1
	return "id_" .. self.nextid_
end

function DDP:method(methodname, params)
	local id = tostring(self:nextId())
	local ret = DDPReturn()
	self.returns_[id] = ret
	local callmsg = {
		msg = "method",
		method = methodname,
		id = id,
		params = params
	}
	self.socket_:sendJSON(callmsg)
	return ret
end

function DDP:update()
	self.socket_:update()
end

local ret = {}
ret.DDP = DDP
ret.DDPReturn = DDPReturn
return ret