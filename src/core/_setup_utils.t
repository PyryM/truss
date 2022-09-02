function truss.extend_table(dest, ...)
  for idx = 1, select("#", ...) do
    local addition = select(idx, ...)
    for k,v in pairs(addition) do dest[k] = v end
  end
  return dest
end
truss.copy_table = function(t) return truss.extend_table({}, t) end

function truss.extend_list(dest, addition)
  for _, v in ipairs(addition) do
    dest[#dest+1] = v
  end
end

function truss.slice_list(src, start_idx, stop_idx)
  local dest = {}
  if stop_idx < 0 then
    stop_idx = #src + 1 + stop_idx
  end
  for i = start_idx, stop_idx do
    dest[i - start_idx + 1] = src[i]
  end
  return dest
end
