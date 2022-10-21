-- protobuf/gen.t
--
-- higher level generation

local m = {}

local ffi = require("ffi")

local class = require("class")
local eg = require("./encodergen.t")
local dg = require("./decodergen.t")
local wf = require("./wireformat.t")
local parser = require("./schemaparser.t")

local substrate = require("substrate")
local derive = substrate.derive

local ByteArray = substrate.ByteArray

local struct CombBuffer {
  data: ByteArray;
  scratch: ByteArray;
  buff: wf.buffer_t;
  enc: wf.encode_state_t;
}
m.CombBuffer = CombBuffer

terra CombBuffer:init()
  self.data:init()
  self.buff:init()
  self.scratch:init()
  self.enc:init()
end

terra CombBuffer:clear()
  self.data:clear()
  self.scratch:clear()
  self.buff:clear()
  self.enc:clear()
  self.buff:view(&self.data)
  self.enc.buff:view(&self.scratch)
end

terra CombBuffer:allocate(size: uint64, max_markers: uint32)
  self.data:allocate(size)
  self.buff:view(&self.data)
  self.scratch:allocate(size)
  self.enc:allocate_markers(max_markers)
  self.enc.buff:view(&self.scratch)
end

terra CombBuffer:release()
  self.data:release()
  self.scratch:release()
end

terra CombBuffer:view_raw(data: &uint8, datasize: uint32)
  self.buff:view_raw(data, datasize)
end

local ProtoGen = class("ProtoGen")
m.ProtoGen = ProtoGen

function ProtoGen:init(options)
  options = options or {}
  self.messages = {}
  self._encoder_ctx = {}
  self._decoder_ctx = {}
  eg.prep_ctx(self._encoder_ctx)
  dg.prep_ctx(self._decoder_ctx)
  self.vec_template = options.vec or assert(substrate.Vec)
  self.box_template = options.box or assert(substrate.Box)
  self.parser_options = options
end

function ProtoGen:_gen_struct(message)
  local schema = message.schema
  local Message = terralib.types.newstruct(schema.name or "Message")
  Message.entries = {}
  for _, finfo in ipairs(schema.fields) do
    assert(finfo.name)
    local ftype = assert(wf.C_TYPES[finfo.kind] or self.messages[finfo.kind].ctype)
    if finfo.repeated then
      ftype = self.vec_template(ftype)
    elseif finfo.boxed then 
      ftype = self.box_template(ftype) 
    end
    table.insert(Message.entries, {finfo.name, assert(ftype)})
  end
  Message:complete()
  derive.derive_init(Message)
  derive.derive_release(Message)
  derive.derive_clear(Message)
  derive.derive_move(Message)
  derive.derive_copy(Message)

  message.ctype = Message
  return Message
end

local function dump_string(field)
  if field == nil then return "" end
  return ffi.string(field.data, field.len)
end

local function identity(v)
  return v
end

function ProtoGen:_gen_dumper(message)
  local schema = message.schema
  message.dump = function(cmsg)
    local ret = {}
    for _, finfo in ipairs(schema.fields) do
      local name, kind, field = finfo.name, finfo.kind, cmsg[finfo.name]
      local dumper
      if kind == "string" or kind == "bytes" then
        dumper = dump_string
      elseif wf.C_TYPES[kind] then
        dumper = identity
      else
        dumper = self.messages[kind].dump
      end
      if finfo.repeated then
        ret[name] = {}
        if dumper == identity then
          for idx = 0, tonumber(field.size)-1 do
            table.insert(ret[name], dumper(field:get_val(idx)))
          end
        else
          for idx = 0, tonumber(field.size)-1 do
            table.insert(ret[name], dumper(field:get_ref(idx)))
          end
        end
      elseif finfo.boxed then
        if field:is_filled() then
          ret[name] = dumper(field:get())
        end
      else
        ret[name] = dumper(field)
      end
    end
    return ret
  end
end

function ProtoGen:add_schemas(schemas)
  local enums
  if type(schemas) == 'string' then
    schemas, enums = parser.parse(schemas, self.parser_options)
  else
    enums = schemas.enums
  end
  for k, schema in pairs(schemas) do
    assert(schema.name == k, 
          ("Schema name inconsistency: %s vs. %s"):format(k, schema.name))
    -- should be error?
    if self.messages[k] then print("Duplicate schema: " .. k) end
    self.messages[k] = {name = k, schema = schema}
  end
  self.enum = enums
end

function ProtoGen:add_schema_file(fn)
  local file = io.open(fn, "rt")
  if not file then error(("Couldn't open schema file [%s]"):format(fn)) end
  self:add_schemas(file:read("*a")) 
  file:close()
end

function ProtoGen:_map_messages(root, f, level)
  local message = self.messages[root]
  if not message then error("Unknown message type: " .. name) end
  if message.is_enum then return end
  for _, finfo in ipairs(message.schema.fields) do
    if not wf.WIRE_TYPES[finfo.kind] then -- assume submessage
      self:_map_messages(finfo.kind, f, level+1)
    end
  end
  f(message, level)
end

function ProtoGen:_create_codecs(name)
  local ectx = self._encoder_ctx
  local dctx = self._decoder_ctx
  self:_map_messages(name, function(message, level)
    if not message.ctype then
      --print("Generating ctype for", message.name)
      self:_gen_struct(message) 
      self:_gen_dumper(message)
    end
    if not message.encoder then
      --print("Generating encoder for", message.name)
      message.encoder = eg.generate_encoder(ectx, message.schema, message.ctype)
    end
    if not message.decoder then
      --print("Generating decoder for", message.name)
      message.decoder = dg.generate_decoder(dctx, message.schema, message.ctype)
    end
    if level > 0 then
      if not ectx.encoders[message.name] then
        --print("Generating field encoder for", message.name)
        ectx.encoders[message.name] = eg.wrap_message_encoder(
          ectx, message.schema, message.ctype, message.encoder
        )
      end
      if not dctx.decoders[message.name] then
        --print("Generating field decoder for", message.name)
        dctx.decoders[message.name] = dg.wrap_message_decoder(
          dctx, message.schema, message.ctype, message.decoder
        )
      end
    end
  end, 0)
end

function ProtoGen:get(name)
  self:_create_codecs(name)
  return self.messages[name] -- TODO: wrap in something nicer?
end

return m