-- dev/htmlgen.t
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

local function format_attributes(attribs)
  local ret = {}
  for k, v in pairs(attribs) do
    table.insert(ret, string.format('%s="%s"', k, v))
  end
  return table.concat(ret, " ")
end

local default_format = function(tagname, attribs)
  local end_tag = string.format("</%s>", tagname)
  if #attribs > 0 then
    return string.format("<%s %s>", tagname, attribs), end_tag
  else
    return string.format("<%s>", tagname), end_tag
  end
end

local elements = {
  td = {nonbreaking = true, indent = " ", format = default_format}, 
  span = {nonbreaking = true, indent = " ", format = default_format},
  precode = {
    indent = "",
    nonbreaking = true,
    format = function(_, a)
      return string.format("<pre><code %s>", a), "</code></pre>"
    end
  },
  code = {nonbreaking = true, indent = " ", format = default_format},
  p = {nonbreaking = true, indent = " ", format = default_format},
  default = {indent = "  ", format = default_format},
  none = {nonbreaking = true, indent = "", format = function() 
    return "", "" 
  end}
}

function node_proto:chunkify(fragments, indent)
  fragments = fragments or {}
  indent = "" --indent or ""
  local einfo = elements[self.kind] or elements.default
  local attribs = format_attributes(self.attributes)
  local opening, closing = einfo.format(self.kind, attribs)
  --opening = indent .. opening
  if not einfo.nonbreaking then
    opening = opening .. "\n"
    closing = "\n" .. closing .. "\n"
  end
  table.insert(fragments, opening)
  local nextindent = indent .. einfo.indent
  local broke_line = false
  for _, child in ipairs(self.children or {}) do
    if type(child) == "string" then
      table.insert(fragments, child)
    else
      if einfo.nonbreaking then
        child:chunkify(fragments, "")
      else
        broke_line = true
        --table.insert(fragments, "\n")
        child:chunkify(fragments, nextindent)
      end
    end
  end
  if broke_line then 
    --table.insert(fragments, string.format("\n%s", indent)) 
  end
  table.insert(fragments, closing)
  return fragments
end

function node_proto:__tostring()
  -- local chunks = self:chunkify()
  -- local ret = ""
  -- for i, c in ipairs(chunks) do
  --   ret = ret .. i .. ": " .. c .. "\n"
  -- end
  -- return ret
  return table.concat(self:chunkify(), "")
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
  'body', 'div', 'span', 'p', 'ul', 'li', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'section', 'table', 'tr', 'td', 'thead', 'tbody', 'tfoot', 'th', 'caption',
  'code', 'pre', 'main', 'a', 'nav', 'script', 'em', 'precode', 'strong'
}
for _, tname in ipairs(tagnames) do html[tname] = make_tag(tname) end
html.group = make_tag("none")

return html