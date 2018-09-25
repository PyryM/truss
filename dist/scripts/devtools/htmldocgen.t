local html = require("./htmlgen.t")
local md = require("./minimarkdown.t")

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

local function field_row_gen(argname, arg)
  return {argname, arg.kind, arg.name}
end

local function arg_row_gen(argname, arg)
  local desc = arg.name
  if arg.kind == "enum" and arg.options then
    desc = desc .. ": " .. format_enum_options(arg.options)
  end
  return {argname, arg.kind, desc, format_value(arg.default) or "nil"}
end

local function sorted_keys(t)
  local keys = {}
  for k, _ in pairs(t) do table.insert(keys, k) end
  table.sort(keys)
  return keys
end

local function format_type_table(argtable, caption, labels, rowgen)
  local caption = html.caption{caption}
  local header_row = html.tr{}
  for _, s in ipairs(labels) do
    header_row:add(html.th{s})
  end
  local head = html.thead{header_row}
  local body = html.tbody()
  --for argname, arg in pairs(argtable) do
  for _, argname in ipairs(sorted_keys(argtable)) do
    local arg = argtable[argname]
    local row = html.tr{}
    for _, part in ipairs(rowgen(argname, arg)) do
      row:add(html.td{part})
    end
    body:add(row)
  end
  return html.table{caption, head, body}
end

local function format_table_args(argtable)
  local htable = format_type_table(argtable, "Options", 
                                   {"name", "type", "desc", "default"},
                                   arg_row_gen)
  return "options", htable
end

local function format_fields(fieldtable, caption)
  local htable = format_type_table(fieldtable, caption or "Fields", 
                                   {"name", "type", "desc"},
                                   field_row_gen)
  return htable
end

local function list_zip(l, filler)
  local ret = {}
  for idx, item in ipairs(l) do
    table.insert(ret, item)
    if idx < #l then
      table.insert(ret, filler)
    end
  end
  return ret
end

local function format_args(arglist)
  local frags = {}
  local descriptions = html.ul{}
  for _, arg in ipairs(arglist or {}) do
    if type(arg) == 'function' then arg = arg("???") end
    local astr
    if arg.name then
      astr = {html.strong{arg.name}, ": ", arg.kind}
    else
      astr = arg.kind
    end
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
  return list_zip(frags, ", "), descriptions
  --table.concat(frags, ", "), descriptions
end

function generators.module(item, parent)
  local ret = html.section{html.h2{"◈ " .. item.info.name}}
  item.resolver = md.ModuleResolver(item.info.name)
  if item.description then
    ret:add(md.generate(item.description, item.resolver))
  end
  if item.fields then
    ret:add(format_fields(item.fields))
  end
  ret:add(gen(item.items, item))
  ret.attributes.id = module_id(item)
  return ret
end

function generators.sourcefile(item, parent)
  local ret = html.group{}
  --item.parent = parent
  if false and item.description then
    ret:add(html.h3{item.info.name})
    ret:add(md.generate(item.description, parent.resolver))
  end
  if item.fields then
    ret:add(format_fields(item.fields))
  end
  ret:add(gen(item.items, parent))
  return ret
end

function generators.func(item, parent)
  local arg_list, arg_descriptions
  local sig
  if item.table_args then
    arg_list, arg_descriptions = format_table_args(item.table_args)
    sig = html.strong{item.info.name, " { ",  arg_list, " } "}
  else
    arg_list, arg_descriptions = format_args(item.args)
    sig = {html.strong{item.info.name, " ( "},  arg_list, html.strong{" ) "}}
  end
  local ret_list, ret_descriptions = format_args(item.returns)
  if item.returns then
    sig = {sig, html.strong{" → "}, ret_list}
  end
  local refname = parent.info.name .. '-' .. (item.info.anchor_id or item.info.name)
  refname = refname:gsub("%.", "-")
  local ret = {
    html.h4{sig, class = 'function-signature', id = refname}, 
    arg_descriptions
  }
  if item.description then
    table.insert(ret, md.generate(item.description, parent.resolver))
  end
  if item.example then
    table.insert(ret, html.precode{item.example, class="language-lua"})
  end
  return ret
end
generators.classfunc = generators.func

function generators.classdef(item, parent)
  local ret = html.group()
  local refname = parent.info.name .. '-' .. item.info.name
  ret:add(html.h3{"class " .. item.info.name, class = 'class-signature', id = refname})
  if item.fields then
    ret:add(format_fields(item.fields))
  end
  if item.description then
    ret:add(md.generate(item.description, parent.resolver))
  end
  local classname = item.info.name
  for _, subitem in ipairs(item.items or {}) do
    if subitem.info.name == classname or subitem.info.name == "init" then
      subitem.info.anchor_id = classname .. '-init'
      subitem.info.name = classname
    else
      subitem.info.anchor_id = classname .. '-' .. subitem.info.name
      subitem.info.name = {classname, ":", subitem.info.name}
    end
  end
  ret:add(gen(item.items, parent))
  return ret
end

local function nav_link(module)
  return html.a{module.info.name, href="#" .. module_id(module)}
end

local function generate_html(modules, options)
  options = options or {}
  local nav_inner = html.group()
  local main = html.main()
  --k, module
  for _, modname in ipairs(sorted_keys(modules)) do
    local module = modules[modname]
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