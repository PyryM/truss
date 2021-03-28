-- consoletools.t
--
-- common console functionality (e.g., info())

local class = require("class")
local m = {}

local ConsoleTools = class("ConsoleTools")
m.ConsoleTools = ConsoleTools

function ConsoleTools:init(options)
  self.print = options.print
  self.width = options.width or 80
  self.paddings = {}
  for i = 0,self.width do
    self.paddings[i] = string.rep(" ", i)
  end
  self.blacklist = {}
end

function ConsoleTools:wrap(fname)
  local nself = self
  local nf = self[fname]
  return function(...)
    return nf(nself, ...)
  end
end

local function print_limited_string(s, maxlen)
  if s:len() < maxlen then
    return '"' .. s .. '"'
  else
    return '"' .. s:sub(1,maxlen) .. '"[+' .. (s:len() - maxlen) .. "]"
  end
end

function ConsoleTools:_update_blacklist()
  -- builds a list of tables that shouldn't be recursed, but instead just
  -- printed as a name
  self.blacklist = {}
  for k,v in pairs(truss._loaded_libs) do
    self.blacklist[v] = "module [" .. k .. "]"
  end
  for k,v in pairs(truss.addons) do
    self.blacklist[v] = "addon [" .. k .. "]"
  end
end

function ConsoleTools:vtype(val)
  if val == nil then return "nil" end
  if self.blacklist[val] then
    return "blacklist", self.blacklist[val]
  else
    return type(val)
  end
end

function ConsoleTools:val_to_string(v, vtype, blacklistName)
  if blacklistName then return blacklistName end
  if vtype == "string" then
    return '[string] ' .. print_limited_string(v, 30)
  else
    return '[' .. vtype .. '] ' .. tostring(v)
  end
end

function ConsoleTools:_table_info(val, maxrecurse, indent, nprinted)
  indent = indent or 0
  maxrecurse = maxrecurse or 2
  nprinted = nprinted or 0
  local pad = self.paddings[indent*2]
  if not pad then
    return 1000
  end

  for k,v in pairs(val) do
    if truss.clean_subenv[k] ~= v then
      local vtypename, bname = self:vtype(v)
      self.print(pad .. tostring(k) .. ": " .. self:val_to_string(v, vtypename, bname))
      nprinted = nprinted + 1
      if k ~= "class" and vtypename == "table" and maxrecurse > 0 then
        nprinted = nprinted + self:_table_info(v, maxrecurse-1, indent+1, nprinted)
      end
      if nprinted > 100 then
        self.print("[too many printed]")
        return 1000
      end
    end
  end
  return nprinted
end

function ConsoleTools:info(val, maxrecurse)
  maxrecurse = maxrecurse or 2
  local vtype = type(val)
  if vtype == "table" then
    self:_update_blacklist()
    self:_table_info(val, maxrecurse, 0, 0)
  else
    self.print(self:val_to_string(val, vtype))
  end
end

function ConsoleTools:gfx_features()
  local caps = require("gfx").get_caps()
  for capname, supported in pairs(caps.features) do
    local color = (supported and 10) or 3
    self.print(capname .. ": " .. tostring(supported), color, 8)
  end
end

function ConsoleTools:prepare_environment(env)
  -- todo
end

return m
