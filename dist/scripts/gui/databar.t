-- a sidebar for manipulating settings
-- heavily inspired by 'dat.gui'

local class = require("class")
local m = {}

local KINDS = {
  "int", "float", "bool", "choice",
  "color", "dynchoice"
}

local DatabarBuilder = class("DatabarBuilder")
function DatabarBuilder:init()
  self._ordered_fields = {}
  self._named_fields = {}
end

function DatabarBuilder:field(options)
  local name = options[1] or options.name
  local kind = options[2] or options.kind
  local kind_info = KINDS[kind]
  if not kind_info then
    truss.error("Unknown Databar field kind: " .. kind)
  end
  if self._named_fields[name] then
    truss.error("Field " .. name .. " added multiple times!")
  end
  local finfo = {
    name=name, kind=kind_info, 
    default=options.default or kind_info.default,
    options=options,
    gen_draw=kind_info.gen_draw,
    idx=#(self._ordered_fields)
  }
  self._named_fields[name] = finfo
  table.insert(self._ordered_fields, finfo)
  return self
end

function DatabarBuilder:divider()
  table.insert(self._ordered_fields, {gen_draw=gen_divider})
end

function DatabarBuilder:build_c()
  local DataState = terralib.types.newstruct()
  DataState.entries = {}
  for fname, finfo in pairs(self._named_fields) do
    table.insert(DataState.entries, {fname, finfo.ctype})
  end
  table.insert(DataState.entries, {"_section_open", bool[#self._sections]})

  local _self = self
  terra DataState:init()
    escape
      for fname, finfo in pairs(_self._named_fields) do
        if finfo.gen_init then
          emit finfo:gen_init(`self, `io)
        else
          emit quote self.[fname] = [finfo.default] end
        end
      end
    end
  end

  terra DataState:draw()
    var io = IG.GetIO()
    escape
      for idx, finfo in ipairs(_self._ordered_fields) do
        emit finfo:gen_draw(`self, `io)
      end
    end
  end

  return DataState
end

function DatabarBuilder:build()
  -- TODO
end

return m