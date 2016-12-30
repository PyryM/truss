-- vertexdefs.t
--
-- bgfx vertex definitions

local m = {}

m.DefaultDefaultAttributeInfo = {
  {"position",  "p",  float, 3, false},
  {"normal",    "n",  float, 3, false},
  {"tangent",   "t",  float, 3, false},
  {"bitangent", "b",  float, 3, false},
  {"color0",    "c0", uint8, 4, true},
  {"color1",    "c1", uint8, 4, true},
  {"indices",   "i",  uint8, 4, false},
  {"weight",    "w",  float, 4, false},
  {"texcoord0", "t0", float, 2, false},
  {"texcoord1", "t1", float, 2, false},
  {"texcoord2", "t2", float, 2, false},
  {"texcoord3", "t3", float, 2, false},
  {"texcoord4", "t4", float, 2, false},
  {"texcoord5", "t5", float, 2, false},
  {"texcoord6", "t6", float, 2, false},
  {"texcoord7", "t7", float, 2, false}
}

m.AttributeBGFXTypes = {
  [float]  = bgfx.BGFX_ATTRIB_TYPE_FLOAT,
  [uint8]  = bgfx.BGFX_ATTRIB_TYPE_UINT8,
  [int16] = bgfx.BGFX_ATTRIB_TYPE_INT16
}

m.AttributeMap = {}
m.AttributeBGFXEnums = {}
for i,attribData in ipairs(m.DefaultAttributeInfo) do
  local attribName = attribData[1]
  local enumVal = bgfx["ATTRIB_" .. string.upper(attribName)]
  m.AttributeBGFXEnums[attribName] = enumVal
  m.AttributeMap[attribName] = attribData
end

function m.order_attributes(attrib_list)
  local t = {}
  for _,v in ipairs(attrib_list) do
    t[v] = true
  end
  local ordered = {}
  for _,v in ipairs(m.DefaultAttributeInfo) do
    if t[v[1]] then table.insert(ordered, v[1]) end
  end
  return ordered
end

m._basic_vertex_types = {}
function m.create_basic_vertex_type(attrib_list)
  attrib_list = m.order_attributes(attrib_list)
  local cname = table.concat(attrib_list, "_")
  if not m._basic_vertex_types[cname] then
    local entries = {}
    local ntype = terralib.types.newstruct(cname)
    local vdecl = terralib.new(bgfx.bgfx_vertex_decl_t)
    local acounts = {}

    bgfx.vertex_decl_begin(vdecl, bgfx.get_renderer_type())
    for i,a_name in ipairs(attrib_list) do
      local attrib = m.AttributeMap[a_name]
      local atype = attrib[3]
      local acount = attrib[4]
      local normalized = attrib[5]
      entries[i] = {a_name, atype[acount]}
      acounts[a_name] = acount
      local bgfx_enum = m.AttributeBGFXEnums[a_name]
      local bgfx_type = m.AttributeBGFXTypes[atype]
      bgfx.vertex_decl_add(vdecl, bgfx_enum, acount, bgfx_type, normalized, false)
    end
    bgfx.vertex_decl_end(vdecl)

    ntype.entries = entries
    -- terra will automatically complete types in some, but not all, cases
    -- so force the type to complete now to avoid cryptic bugs
    ntype:complete()

    m._basic_vertex_types[cname] = {ttype = ntype,
                    vdecl = vdecl,
                    attributes = acounts}
  end
  return m._basic_vertex_types[cname]
end

function m.create_pos_color_vertex_info()
  return m.create_basic_vertex_type({"position", "color0"})
end

function m.create_pos_normal_vertex_info()
  return m.create_basic_vertex_type({"position", "normal"})
end

function m.create_pos_normal_uv_vertex_info()
  return m.create_basic_vertex_type({"position", "normal", "texcoord0"})
end

return m
