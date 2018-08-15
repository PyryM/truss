local html = require("./htmlgen.t")

local generators = {}
local function gen(items, parent)
  if not items then return "" end
  local fragments = {}
  for _, item in ipairs(items) do
    local frag = (generators[item.kind] or generators.generic)(item, parent)
    table.insert(fragments, frag)
  end
  return fragments
end

function generators.generic(item, parent)
  return html.p{item.kind .. ": " .. tostring(item.info.name)}
end

local function module_id(item)
  return "module-" .. item.info.name
end

function generators.module(item, parent)
  local ret = html.section{html.h2{"◈ " .. item.info.name}}
  if item.description then
    ret:add(html.p{item.description})
  end
  ret:add(gen(item.items, item))
  ret.attributes.id = module_id(item)
  return ret
end

function generators.sourcefile(item, parent)
  local ret = html.group{
    html.h3{item.info.name}
  }
  item.parent = parent
  if item.description then ret:add(html.p{item.description}) end
  ret:add(gen(item.items, item))
  return ret
end

local function format_value(v)
  if type(v) == "string" then
    return "'" .. v .. "'"
  else
    return tostring(v)
  end
end

local function format_enum_options(options)
  local t = {}
  for _, k in ipairs(options) do
    table.insert(t, format_value(k))
  end
  return table.concat(t, ", ")
end

local function format_table_args(argtable)
  local caption = html.caption{"Options"}
  local head = html.thead{
    html.tr{
      html.th{"name"}, html.th{"type"}, 
      html.th{"desc"}, html.th{"default"}
    }
  }
  local body = html.tbody()
  for argname, arg in pairs(argtable) do
    local desc = arg.name
    if arg.kind == "enum" and arg.options then
      desc = desc .. ": " .. format_enum_options(arg.options)
    end
    local row = html.tr{
      html.td{argname}, html.td{arg.kind}, 
      html.td{desc}, 
      html.td{format_value(arg.default) or "nil"}
    }
    body:add(row)
  end

  return "options", html.table{caption, head, body}
end

local function format_args(arglist)
  local frags = {}
  local descriptions = html.ul{}
  for _, arg in ipairs(arglist or {}) do
    local astr = string.format("%s: %s", arg.name, arg.kind)
    table.insert(frags, astr)
    if arg.description or arg.default or arg.optional or arg.kind == 'enum' then
      local desc = string.format("%s — %s", arg.name, arg.description or "")
      if arg.default then
        desc = desc .. string.format(" (default: %s)", format_value(arg.default))
      elseif arg.optional then
        desc = desc .. " (optional)"
      end
      if arg.kind == 'enum' and arg.options then
        desc = desc .. ": " .. format_enum_options(arg.options)
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
  local sig
  if item.table_args then
    arg_list, arg_descriptions = format_table_args(item.table_args)
    sig = string.format("%s { %s }", item.info.name, arg_list)
  else
    arg_list, arg_descriptions = format_args(item.args)
    sig = string.format("%s ( %s )", item.info.name, arg_list)
  end
  local ret_list, ret_descriptions = format_args(item.returns)
  if item.returns then
    sig = sig .. " → " .. ret_list
  end
  local ret = {html.h4{sig, class = 'function-signature'}, arg_descriptions}
  if item.description then
    table.insert(ret, html.p(item.description))
  end
  if item.example then
    table.insert(ret, html.code{item.example, class="language-lua"})
  end
  return ret
end

-- <nav class="menu">
--   <ul>
--     <li><a href="#">Home</a></li>
--     <li><a href="#">About</a></li>
--     <li><a href="#">Contact</a></li>
--   </ul>
-- </nav>

local function nav_link(module)
  return html.a{module.info.name, href="#" .. module_id(module)}
end

local function generate_html(modules, options)
  options = options or {}
  local nav_inner = html.group()
  local main = html.main()
  for k, module in pairs(modules) do
    nav_inner:add(nav_link(module))
    main:add(gen({module}))
  end
  local body = html.body{html.nav{
    html.h3{"Modules"},
    nav_inner}, 
  main}
  for _, script in ipairs(options.scripts or {}) do
    body:add(html.script{"", src = script})
  end
  local css = {}
  for i, fn in ipairs(options.css or {}) do
    css[i] = string.format('<link rel="stylesheet" href="%s">', fn)
  end
  css = table.concat(css, '\n  ')
  return [[
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Truss Documentation</title>]]
  .. "\n  " .. css .. "\n</head>\n"
  .. tostring(body) .. "</html>"
end

return generate_html