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

local function format_args(arglist)
  local frags = {}
  local descriptions = html.ul{}
  for _, arg in ipairs(arglist or {}) do
    local astr = string.format("%s: %s", arg.name, arg.kind)
    table.insert(frags, astr)
    if arg.description then
      descriptions:add(html.li{string.format("%s -- %s", arg.name, arg.description)})
    end
  end
  if #(descriptions.children) == 0 then
    descriptions = nil
  end
  return table.concat(frags, ", "), descriptions
end

function generators.func(item)
  local arg_list, arg_descriptions = format_args(item.args)
  local ret_list, ret_descriptions = format_args(item.returns)
  local sig = string.format("%s ( %s )", item.info.name, arg_list)
  if item.returns then
    sig = sig .. " -> " .. ret_list
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