local html = require("./htmlgen.t")

local generators = {}
local function gen(items)
  if not items then return "" end
  local fragments = {}
  for _, item in ipairs(items) do
    local frag = (generators[item.kind] or generators.generic)(item)
    table.insert(fragments, frag)
  end
  return fragments
end

function generators.generic(item)
  return html.p{item.kind .. ": " .. tostring(item.info.name)}
end

function generators.module(item)
  local ret = html.section{html.h2{item.info.name}}
  ret:add(gen(item.items))
  return ret
end

-- <table>
--     <thead>
--         <tr>
--             <th colspan="2">The table header</th>
--         </tr>
--     </thead>
--     <tbody>
--         <tr>
--             <td>The table body</td>
--             <td>with two columns</td>
--         </tr>
--     </tbody>
--     <tfoot>
--         <tr>
--             <td colspan="2">The table footer</td>
--         </tr>
--     </tfoot>
-- </table>

-- This is a different unicode character, although it doesn't look it
local EM_SPACE = " "

local function format_table_args(argtable)
  local inner = html.tbody()
  inner:add(html.tr{
    html.td{"name"}, html.td{EM_SPACE .. "type"}, 
    html.td{EM_SPACE .. "desc"}, html.td{EM_SPACE .. "default"}
  })
  for argname, arg in pairs(argtable) do
    local row = html.tr{
      html.td{argname}, html.td{EM_SPACE .. arg.kind}, 
      html.td{EM_SPACE .. arg.name}, 
      html.td{EM_SPACE .. tostring(arg.default) or "nil"}
    }
    inner:add(row)
  end

  return "options", html.table{inner}
end

local function format_args(arglist)
  local frags = {}
  local descriptions = html.ul{}
  for _, arg in ipairs(arglist or {}) do
    local astr = string.format("%s: %s", arg.name, arg.kind)
    table.insert(frags, astr)
    if arg.description or arg.default or arg.optional then
      local desc = string.format("%s — %s", arg.name, arg.description or "")
      if arg.default then
        desc = desc .. string.format(" (default: %s)", tostring(arg.default))
      elseif arg.optional then
        desc = desc .. " (optional)"
      end
      descriptions:add(html.li{desc})
    end
  end
  if #(descriptions.children) == 0 then
    descriptions = nil
  end
  return table.concat(frags, ", "), descriptions
end

function generators.func(item)
  local arg_list, arg_descriptions
  if item.table_args then
    arg_list, arg_descriptions = format_table_args(item.table_args)
  else
    arg_list, arg_descriptions = format_args(item.args)
  end
  local ret_list, ret_descriptions = format_args(item.returns)
  local sig = string.format("%s ( %s )", item.info.name, arg_list)
  if item.returns then
    sig = sig .. " → " .. ret_list
  end
  local ret = {html.h4(sig), arg_descriptions}
  if item.description then
    table.insert(ret, html.p(item.description))
  end
  return ret
end

local function generate_html(modules)
  local body = html.body()
  for k, module in pairs(modules) do
    body:add(gen({module}))
  end
  return [[
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>Truss Documentation</title>
  </head>
  ]] .. tostring(body) .. "</html>"
end

return generate_html