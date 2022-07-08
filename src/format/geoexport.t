-- format/geoexport.t
--
-- general geometry exporting thing

local m = {}

function m.dump_obj_geo(geo, dumper)
  if not geo.allocated then
    truss.error("Geometry has no allocated data!")
  end
  for vidx = 0, geo.n_verts-1 do
    dumper:push_vert(geo.verts[vidx])
  end
  local nfaces = geo.n_indices / 3
  local fidx = 0
  for _ = 1, nfaces do
    dumper:push_face(geo.indices[fidx+0], geo.indices[fidx+1], geo.indices[fidx+2])
    fidx = fidx + 3
  end
  return dumper:dump()
end

function m.dump_obj_data(data, dumper)
  local v = data.attributes.position
  local vn = data.attributes.normal or {}
  local vt = data.attributes.texcoord0 or {}
  for vidx = 1, #v do
    dumper:push_vert(v[vidx], vt[vidx], vn[vidx])
  end
  if type(data.indices[1]) == "number" then
    local nfaces = #data.indices / 3
    local fidx = 1
    for _ = 1, nfaces do
      dumper:push_face(data.indices[fidx+0], data.indices[fidx+1], data.indices[fidx+2])
      fidx = fidx + 3
    end
  else -- assume list-of-lists
    for _, ftuple in ipairs(data.indices) do
      dumper:push_face(unpack(ftuple))
    end
  end
  return dumper:dump()
end

function m.dump(geo_or_data, dumper)
  local s = ""
  if geo_or_data.attributes then
    s = m.dump_obj_data(geo_or_data, dumper)
  else
    s = m.dump_obj_geo(geo_or_data, dumper)
  end
  return s
end

function m.save(filename, geo_or_data, dumper)
  local s = m.dump(geo_or_data, dumper)
  truss.save_string(filename, s)
end

return m