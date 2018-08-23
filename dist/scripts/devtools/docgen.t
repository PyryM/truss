-- devtools/docgen.t
--
-- generates documentation

local class = require("class")
local stringutils = require("utils/stringutils.t")
local m = {}

local DocParser = class("DocParser")
m.DocParser = DocParser

function DocParser:init()
  self.modules = {}
  self.modules["(unspecified)"] = {kind = "module", info = {name = "(unspecified)"}}
  self.structure = self.modules["(unspecified)"]
  self:start()
end

function DocParser:get_modules()
  if self.modules["(unspecified)"] and self.modules["(unspecified)"].items == nil then
    self.modules["(unspecified)"] = nil
  end
  return self.modules
end

function DocParser:start()
  self.open_stack = {}
end

function DocParser:_is_open(kind)
  for _, v in ipairs(self.open_stack) do
    if v == kind then return true end
  end
  return false
end

function DocParser:cursor()
  local cursor = self.structure
  for i = 1, #self.open_stack do
    cursor = cursor.items[#cursor.items]
  end
  return cursor
end

function DocParser:open(kind, parent)
  if parent and (not self:_is_open(parent)) then
    truss.error(kind .. " must be nested in " .. parent)
  end
  self:close(kind)
  local cursor = self:cursor()
  if not cursor.items then cursor.items = {} end
  table.insert(cursor.items, {kind = kind})
  table.insert(self.open_stack, kind)
end

function DocParser:close(kind)
  local found_kind = false
  local nlevels = #self.open_stack
  for i = 1, nlevels do
    found_kind = found_kind or (self.open_stack[i] == kind)
    if found_kind then
      self.open_stack[i] = nil
    end
  end
end

local function unwrap_name_table(s)
  if type(s) == "table" then 
    return truss.extend_table({name = s[1] or s.name}, s) 
  else 
    return {name = s} 
  end
end

local function unwrap_string(s)
  if type(s) == "string" then return s else return s[1] end
end

local function parse_type_arg(arg)
  if type(arg) == "string" then
    -- try to split "name: description"
    local parts = stringutils.split(":", arg)
    return parse_type_arg(parts)
  elseif type(arg) == "table" then
    local ret = truss.extend_table({}, arg)
    ret.name, ret.description = arg[1], arg[2]
    if not ret.description then
      ret.name, ret.description = unpack(stringutils.split(":", ret.name))
    end
    return ret
  else
    truss.error("Type argument makes no sense: " .. tostring(arg))
  end
end

local function make_type(tname)
  return function(arg)
    return truss.extend_table({kind = tname}, parse_type_arg(arg))
  end
end

local function def_qualifier(tname, k)
  return string.format("%s[%s]", tname, k)
end

local function make_metatype(tname, qualifier)
  local template_metatable = {
    __index = function(t, k)
      local qualified_name = (qualifier or def_qualifier)(tname, k)
      print("Qualified type to: " .. qualified_name)
      return make_type(qualified_name)
    end,
    __call = function(_, arg)
      return truss.extend_table({kind = tname}, parse_type_arg(arg))
    end
  }
  local m = {}
  setmetatable(m, template_metatable)
  return m
end

local type_functions = {}
local basic_types = {
  "bool", "number", "enum", "string", "callable", "list", "table", "dict",
  "int", "classproto"
}
for _, tname in ipairs(basic_types) do
  type_functions[tname] = make_type(tname)
end
type_functions.object = make_metatype("object", function(_, k) return k end)
type_functions.ctype = make_metatype("ctype")
type_functions.cdata = make_metatype("cdata")
type_functions.self = {kind = 'self'}
type_functions.clone = {kind = 'clone'}

local function section_like(name, parent)
  return function(parser, arg)
    parser:open(name, parent)
    parser:cursor().info = unwrap_name_table(arg)
  end
end

local function property_like(name, arg_handler)
  return function(parser, arg)
    if arg_handler then arg = arg_handler(arg) end
    parser:cursor()[name] = arg
  end
end

local keyword_functions = {}
function keyword_functions.module(parser, module_name)
  parser:_module(module_name, "module")
end
function keyword_functions.article(parser, article_name)
  parser:_module(article_name, "article")
end
keyword_functions.sourcefile = section_like("sourcefile")
keyword_functions.classdef = section_like("classdef")
keyword_functions.func = section_like("func")
keyword_functions.classfunc = section_like("classfunc", "classdef")
keyword_functions.funcdef = keyword_functions.func
keyword_functions.description = property_like("description", unwrap_string)
keyword_functions.extends = property_like("extends", unwrap_string)
keyword_functions.returns = property_like("returns")
keyword_functions.args = property_like("args")
keyword_functions.table_args = property_like("table_args")
keyword_functions.example = property_like("example", unwrap_string)

function DocParser:_module(module_name, module_kind)
  module_name = unwrap_string(module_name)
  if not self.modules[module_name] then
    self.modules[module_name] = {kind = module_kind, info = {name = module_name}}
  end
  self.structure = self.modules[module_name]
  self.open_stack = {}
end

function DocParser:bind_functions(env)
  local ret = env or {}
  for funcname, func in pairs(keyword_functions) do
    ret[funcname] = function(options)
      return func(self, options)
    end
  end
  truss.extend_table(ret, type_functions)
  ret.tostring = tostring
  ret.print = print
  return ret
end

function DocParser:parse_string(s)
  local f, had_err = loadstring(s)
  if had_err then truss.error(had_err) end
  setfenv(f, self:bind_functions())
  f()
  return self.structure
end

function DocParser:parse_file(fn)
  local s = truss.load_string_from_file(fn)
  return self:parse_string(s)
end

function m.init()
  -- Nothing special to do?
end

function m.update()
  print("Doc generation complete.")
  truss.quit()
end

return m