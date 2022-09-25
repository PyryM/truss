local m = {}

function m.set_template_name(T, template_name, ...)
  local inners = {}
  for idx, inner_T in ipairs({...}) do
    inners[idx] = tostring(inner_T)
  end
  T.name = template_name .. "<" .. table.concat(inners, ",") .. ">"
end

return m