-- vertexdefs.t
--
-- bgfx vertex definitions

local m = {}

m.ATTRIBUTE_INFO = {
  position  = {sn = "p", ctype = float, count = 3},
  normal    = {sn = "n", ctype = float, count = 3},
  tangent   = {sn = "tn", ctype = float, count = 3},
  bitangent = {sn = "b", ctype = float, count = 3},
  color0    = {sn = "c0", ctype = uint8, count = 4, normalized = true},
  color1    = {sn = "c1", ctype = uint8, count = 4, normalized = true},
  indices   = {sn = "i", ctype = uint8, count = 4},
  weight    = {sn = "w", ctype = float, count = 4},
  texcoord0 = {sn = "t0", ctype = float, count = 2},
  texcoord1 = {sn = "t1", ctype = float, count = 2},
  texcoord2 = {sn = "t2", ctype = float, count = 2},
  texcoord3 = {sn = "t3", ctype = float, count = 2},
  texcoord4 = {sn = "t4", ctype = float, count = 2},
  texcoord5 = {sn = "t5", ctype = float, count = 2},
  texcoord6 = {sn = "t6", ctype = float, count = 2},
  texcoord7 = {sn = "t7", ctype = float, count = 2}
}

local ATTRIB_ORDER = {
  "position", "normal", "tangent", "bitangent", "color0", "color1",
  "indices", "weight", "texcoord0", "texcoord1", "texcoord2",
  "texcoord3", "texcoord4", "texcoord5", "texcoord6", "texcoord7"
}

local BGFX_ATTRIBUTE_TYPES = {
  [float] = bgfx.ATTRIB_TYPE_FLOAT,
  [uint8] = bgfx.ATTRIB_TYPE_UINT8,
  [int16] = bgfx.ATTRIB_TYPE_INT16
}

local TYPENAMES = {
  [float] = "f",
  [uint8] = "u8",
  [int16] = "i16"
}

for attrib_name, attrib_data in pairs(m.ATTRIBUTE_INFO) do
  local enum_val = bgfx["ATTRIB_" .. string.upper(attrib_name)]
  if not enum_val then
    truss.error("attribute has no bgfx enum: " .. attrib_name)
  end
  attrib_data.bgfx_enum = enum_val
end

-- to avoid creating a ton of redundant vertex definitions (which are
-- a limited bgfx resource), reorder the attributes into a 'canonical' order
local function order_attributes(attrib_table)
  local alist = {}
  local name_parts = {}
  for _, attrib_name in ipairs(ATTRIB_ORDER) do
    local info = attrib_table[attrib_name]
    if info then
      local def_info = m.ATTRIBUTE_INFO[attrib_name]
      local npart = def_info.sn .. ":" 
                 .. info.count
                 .. TYPENAMES[info.ctype]
      if info.normalized then npart = npart .. "n" end
      table.insert(alist, {attrib_name, info})
      table.insert(name_parts, npart)
    end
  end
  return table.concat(name_parts, "_"), alist
end

m._vertex_types = {}
function m.create_vertex_type(attrib_table)
  local canon_name, attrib_list = order_attributes(attrib_table)
  if m._vertex_types[canon_name] then 
    return m._vertex_types[canon_name]
  end
  log.info("Creating vertex type " .. canon_name)

  local entries = {}
  local ntype = terralib.types.newstruct(canon_name)
  local vdecl = terralib.new(bgfx.vertex_decl_t)
  local acounts = {}

  bgfx.vertex_decl_begin(vdecl, bgfx.get_renderer_type())
  for i, atuple in ipairs(attrib_list) do
    local aname, ainfo = atuple[1], atuple[2]
    local atype = ainfo.ctype
    local acount = ainfo.count
    local normalized = ainfo.normalized or false
    entries[i] = {aname, atype[acount]}
    acounts[aname] = acount
    local bgfx_enum = m.ATTRIBUTE_INFO[aname].bgfx_enum
    local bgfx_type = BGFX_ATTRIBUTE_TYPES[atype]
    bgfx.vertex_decl_add(vdecl, bgfx_enum, acount, bgfx_type, normalized, false)
  end
  bgfx.vertex_decl_end(vdecl)

  ntype.entries = entries
  ntype:complete() -- complete the terra type now to avoid cryptic bugs

  m._vertex_types[canon_name] = {ttype = ntype,
                                 vdecl = vdecl,
                                 type_id = canon_name,
                                 attributes = acounts}
  return m._vertex_types[canon_name]
end

function m.create_basic_vertex_type(attrib_list)
  -- create attribute table with default types+counts
  local attrib_table = {} 
  for _, attrib_name in ipairs(attrib_list) do
    attrib_table[attrib_name] = m.ATTRIBUTE_INFO[attrib_name]
  end
  return m.create_vertex_type(attrib_table)
end

function m.guess_vertex_type(data)
  local attributes = data.attributes or data
  local attrib_list = {}
  for attrib_name, _ in pairs(attributes) do
    table.insert(attrib_list, attrib_name)
  end
  local vtype = m.create_basic_vertex_type(attrib_list)
  log.info("guessed vertex type [" .. vtype.type_id .. "]")
  return vtype
end

return m
