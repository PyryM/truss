-- devtools/htmlgen.t
--
-- tools for generating html

local html = {}

local node_proto = {}
node_proto.__index = node_proto

function node_proto:add(child)
  if not self.children then self.children = {} end
  if type(child) == 'string' or child.kind then
    table.insert(self.children, child)
  else -- assume 'child' is actually list-like
    for _, real_child in ipairs(child) do self:add(real_child) end
  end
  return self
end

function node_proto:chunkify(fragments, indent)
  fragments = fragments or {}
  indent = indent or ""
  local attribs = "" -- TODO: generate attributes
  local opening
  if #attribs > 0 then
    opening = string.format("%s<%s %s>", indent, self.kind, attribs)
  else
    opening = string.format("%s<%s>", indent, self.kind)
  end
  table.insert(fragments, opening)
  local nextindent = indent .. "  "
  for _, child in ipairs(self.children or {}) do
    if type(child) == "string" then
      table.insert(fragments, nextindent .. child)
    else
      child:chunkify(fragments, nextindent)
    end
  end
  table.insert(fragments, string.format("%s</%s>", indent, self.kind))
  return fragments
end

function node_proto:__tostring()
  return table.concat(self:chunkify(), "\n")
end

function html.tag(kind, options)
  options = options or {}
  local ret = {kind = kind, attributes = {}}
  setmetatable(ret, node_proto)
  if options.text then ret:add(options.text) end
  if options.children then ret:add(options.children) end
  for attr_name, attr_val in pairs(options) do
    if type(attr_name) == 'string' 
      and attr_name ~= 'text' and attr_name ~= 'children' then
      ret.attributes[attr_name] = attr_val
    end
  end
  return ret
end

local function make_tag(tagname)
  return function(contents)
    if contents == nil or type(contents) == 'string' then 
      contents = {contents} 
    end
    if not contents.children then contents.children = contents end
    return html.tag(tagname, contents)
  end
end

local tagnames = {
  'body', 'p', 'ul', 'li', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'section'
}
for _, tname in ipairs(tagnames) do html[tname] = make_tag(tname) end

return html