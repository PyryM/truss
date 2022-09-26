-- protobuf/schemaparser.t
--
-- parses ".proto" schemas

local m = {}

local function chunkify(src, pos)
  local chunks = {}
  while pos <= #src do
    local newpos = src:find("[;{}]", pos) or #src+1
    local delim = src:sub(newpos, newpos)
    if delim == "{" then
      local subchunks, subpos = chunkify(src, newpos+1)
      table.insert(chunks, {src:sub(pos, newpos-1), subchunks})
      pos = subpos
    elseif delim == "}" then
      return chunks, newpos+1
    else
      table.insert(chunks, src:sub(pos, newpos-1))
      pos = newpos+1
    end
  end
  return chunks, pos
end

local function strip(s)
  s = s:gsub("\n", ""):gsub("\r", "")
  return s:match('^()%s*$') and '' or s:match('^%s*(.*%S)')
end

local function strip_comments(s)
  s = s:gsub("//[^\n]*", "")
  local block_open = s:find("/%*")
  if not block_open then return s end
  local block_close = s:find("%*/", block_open+2)
  return s:sub(1, block_open-1) .. strip_comments(s:sub(block_close+2, #s))
end

local function split(text, delim)
  local pos, parts = 1, {}
  while true do
    local first, last = text:find(delim or "%s+", pos)
    if first then -- found?
      table.insert(parts, text:sub(pos, first-1))
      pos = last+1
    else
      table.insert(parts, text:sub(pos))
      break
    end
  end
  return parts
end

local function parse_field(ctx, fields, chunk)
  local identifier, index = chunk:match("^([^=]*)=([^=]*)$")
  if not identifier then return false end
  local opts = split(strip(identifier))
  local field = {}
  -- flags like "repeated"
  for idx = 1, #opts - 2 do
    field[opts[idx]] = true
  end
  field.name = opts[#opts]
  field.kind = opts[#opts - 1]
  field.idx = tonumber(index)
  if ctx.messages[field.kind] and ctx.messages[field.kind].is_enum then
    field.kind = "enum"
  end
  table.insert(fields, field)
  return field
end

local function parse_enum(ctx, chunk)
  local enum_name = strip(chunk[1]):match("^enum%s+(%w+)$")
  if not enum_name then return false end
  for _, subchunk in ipairs(chunk[2]) do
    if type(subchunk) == 'string' then
      local identifier, index = subchunk:match("^([^=]*)=([^=]*)$")
      identifier = strip(identifier)
      index = tonumber(index)
      ctx.enums[identifier] = index
    end
  end
  ctx.messages[enum_name] = {name=enum_name, is_enum=true}
  return true
end

local function parse_oneof(ctx, fields, chunk)
  local parts = split(strip(chunk[1]))
  if parts[1] ~= "oneof" then return false end
  -- we don't actually do anything w/ the name for now
  local identifier = parts[2]
  for _, subchunk in ipairs(chunk[2]) do
    local field = parse_field(ctx, fields, subchunk)
    assert(not field.repeated, "oneof fields cannot be repeated")
    field.boxed = true -- hmmm
  end
  return true
end

local function parse_message(ctx, chunk)
  local messages = ctx.messages
  local msg_name = strip(chunk[1]):match("^message%s+(%w+)$")
  if not msg_name then return false end
  local fields = {}
  for _, subchunk in ipairs(chunk[2]) do
    if type(subchunk) == 'table' then-- submessage
      parse_oneof(ctx, fields, subchunk)
      parse_message(ctx, subchunk)
    else -- assume string
      parse_field(ctx, fields, subchunk)
    end
  end
  messages[msg_name] = {name=msg_name, fields=fields}
  return true
end

local _parse

local function parse_import(ctx, chunk)
  local import_path = strip(chunk):match('^import%s+"([^"]*)"$')
  if not import_path then return false end
  assert(ctx.import_resolver, "No import resolver!")
  local src = assert(ctx.import_resolver(import_path), "Failed import!")
  _parse(ctx, src)
end

local TOP_LEVEL_STATEMENTS = {
  ["message"] = parse_message,
  ["enum"] = parse_enum,
  ["import"] = parse_import
}

_parse = function(ctx, src)
  src = strip_comments(src)
  local chunks = chunkify(src, 1)
  for _, chunk in ipairs(chunks) do
    local chunkstr = chunk
    if type(chunkstr) == 'table' then
      chunkstr = chunkstr[1]
    end
    local parts = split(strip(chunkstr))
    local parser = TOP_LEVEL_STATEMENTS[parts[1]]
    if parser then parser(ctx, chunk) end
  end
end

local function make_resolver(options)
  local root_path = options.import_path or ""
  return function(path)
    local parts = split(strip(path), "/")
    local fn = parts[#parts]
    local realpath = root_path .. fn
    local file = assert(io.open(realpath, "rt"),
      "Couldn't open proto file: " .. realpath)
    local src = file:read("*a")
    file:close()
    return src
  end
end

function m.parse(src, options)
  options = options or {}
  local ctx = {
    messages = {}, 
    enums = {}, 
    meta = {},
    import_resolver = options.import_resolver or make_resolver(options)
  }
  _parse(ctx, src)
  return ctx.messages, ctx.enums, ctx
end

return m