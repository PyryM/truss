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

local function printLimitedString(s, maxlen)
    if s:len() < maxlen then
        return '"' .. s .. '"'
    else
        return '"' .. s:sub(1,maxlen) .. '"[+' .. (s:len() - maxlen) .. "]"
    end
end

function ConsoleTools:_updateBlacklist()
    -- builds a list of tables that shouldn't be recursed, but instead just
    -- printed as a name
    self.blacklist = {}
    for k,v in pairs(truss.loadedLibs) do
        self.blacklist[v] = "module [" .. k .. "]"
    end
    for k,v in pairs(truss.addons) do
        self.blacklist[v] = "addon [" .. k .. "]"
    end
    for k,v in pairs(truss.rawAddons) do
        self.blacklist[v] = "raw addon [" .. k .. "]"
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

function ConsoleTools:valToString(v, vtype, blacklistName)
    if blacklistName then return blacklistName end
    if vtype == "string" then
        return '[string] ' .. printLimitedString(v, 30)
    else
        return '[' .. vtype .. '] ' .. tostring(v)
    end
end


function ConsoleTools:_tableInfo(val, maxrecurse, indent, nprinted)
    indent = indent or 0
    maxrecurse = maxrecurse or 2
    nprinted = nprinted or 0
    local pad = self.paddings[indent*2]
    if not pad then
        return 1000
    end

    for k,v in pairs(val) do
        local vtypename, bname = self:vtype(v)
        self.print(pad .. tostring(k) .. ": " .. self:valToString(v, vtypename, bname))
        nprinted = nprinted + 1
        if k ~= "class" and vtypename == "table" and maxrecurse > 0 then
            nprinted = nprinted + self:_tableInfo(v, maxrecurse-1, indent+1, nprinted)
        end
        if nprinted > 60 then
            self.print("[too many printed]")
            return 1000
        end
    end
    return nprinted
end

function ConsoleTools:info(val, maxrecurse)
    maxrecurse = maxrecurse or 2
    local vtype = type(val)
    if vtype == "table" then
        self:_updateBlacklist()
        self:_tableInfo(val, maxrecurse, 0, 0)
    else
        self.print(self:valToString(val, vtype))
    end
end

function ConsoleTools:prepareEnvironment(env)
    -- todo
end

return m
