local function open_tag(tag, classname)
  local opening = "<" .. tag
  if classname then 
    opening = opening .. ' class="' .. classname .. '"'
  end
  return opening .. ">"
end

local function close_tag(tag)
  return "</" .. tag .. ">"
end

local function wrap_tag(s, tag, classname)
  return open_tag(tag, classname) .. "\n" .. s  .. "\n" .. close_tag(tag) .. "\n"
end

local generators = {}
local function gen(items)
  if not items then return "" end
  local fragments = {}
  for _, item in ipairs(items) do
    local frag = (generators[item.kind] or generators.generic)(item)
    table.insert(fragments, frag)
  end
  return table.concat(fragments)
end

function generators.generic(item)
  return wrap_tag(item.kind .. ": " .. tostring(item.info.name), "p")
end

local function with_wrapper(tag, f)
  return function(item) 
    return wrap_tag(f(item), tag)
  end
end

local function with_heading(hlevel, f)
  return function(item)
    local header = wrap_tag(item.info.name or 'ITEM', hlevel)
    return header .. f(item)
  end
end

function generators.module(item)
  local heading = wrap_tag(item.info.name, 'h2')
  local children = gen(item.items)
  return wrap_tag(heading .. children, "section")
end

local function format_args(arglist)
  local frags = {}
  local descriptions = {}
  for _, arg in ipairs(arglist or {}) do
    local astr = string.format("%s: %s", arg.name, arg.kind)
    table.insert(frags, astr)
    if arg.description then
      table.insert(descriptions, string.format("<li>%s -- %s</li>", arg.name, arg.description))
    end
  end
  if #descriptions > 0 then
    descriptions = wrap_tag(table.concat(descriptions, "\n"), "ul")
  else
    descriptions = ""
  end
  return table.concat(frags, ", "), descriptions
end

function generators.func(item)
  local ret = item.info.name or "?"
  local arg_list, arg_descriptions = format_args(item.args)
  local ret_list, ret_descriptions = format_args(item.returns)
  local ret = string.format("%s ( %s )", item.info.name, arg_list)
  if item.returns then
    ret = ret .. " -> " .. ret_list
  end
  ret = wrap_tag(ret, 'h4')
  ret = ret .. arg_descriptions
  if item.description then
    ret = ret .. wrap_tag(item.description, 'p')
  end
  return ret
end

local function generate_html(modules)
  local frags = {}
  for k, module in pairs(modules) do
    table.insert(frags, gen({module}))
  end
  local body = wrap_tag(table.concat(frags), "body")
  return [[
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>Truss Documentation</title>
  </head>
  ]] .. body .. "</html>"
end

return generate_html