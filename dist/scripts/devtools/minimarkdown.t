-- minimarkdown.t
--
-- a tiny, restricted set of markdown

-- parser.t
--
-- parses text adventure stuff

local class = require("class")
local lpeg = require("lib/lulpeg.lua")
local m = {}

local function gen_patterns()
  local quote_mark = lpeg.S('"')
  local whitespace = lpeg.S(' \t')
  local newline = lpeg.S('\n')
  local hardbreak = newline * (whitespace^0 * newline)^1

  local paragraph = lpeg.C((lpeg.P(1) - hardbreak)^1)
  local paragraphs = lpeg.Ct(paragraph^-1 * (hardbreak * paragraph)^0 * hardbreak^0)

  local tag_mt = {
    __tostring = function(t)
      return string.format("<%s>%s</%s>", t.tag or "?", t.content or "?", t.tag or "?")
    end
  }

  local function make_special(tag, open_str, close_str)
    local open = lpeg.P(open_str)
    local close = lpeg.P(close_str)
    local namer = function(s)
      return setmetatable({tag = tag, content = s}, tag_mt)
    end
    return (open * lpeg.C((lpeg.P(1) - close)^0) * close) / namer
  end

  local emph = make_special("emph", "*", "*")
  local code = make_special("code", "`", "`")
  local link = make_special("link", "{{", "}}")
  local specials = emph + code + link

  local normal_text = lpeg.C((lpeg.P(1) - specials)^1)
  local tagged = lpeg.Ct((normal_text + specials)^0)

  return {paragraphs = paragraphs, tagged = tagged}
end

local patterns = nil
function m.split_paragraphs(s)
  patterns = patterns or gen_patterns()
  return patterns.paragraphs:match(s)
end

function m.split_tags(s)
  patterns = patterns or gen_patterns()
  return patterns.tagged:match(s)
end

function m.default_resolver(link_content)
  return link_content, link_content
end

function m.generate(s, link_resolver)
  link_resolver = link_resolver or m.default_resolver
  local html = require("./htmlgen.t")
  local ret = html.group()

  s = (s or ""):gsub("\r", "") -- our grammar only handles \n
  s = s:gsub("<", "&lt")       -- sanitize <> so they won't break html
  s = s:gsub(">", "&gt") 

  for _, text in ipairs(m.split_paragraphs(s)) do
    local p = html.p()
    for _, chunk in ipairs(m.split_tags(text)) do
      if type(chunk) == 'string' then
        p:add(chunk)
      elseif chunk.tag == 'code' then
        p:add(html.code{chunk.content}) --, class="language-lua"})
      elseif chunk.tag == 'emph' then
        p:add(html.emph{chunk.content})
      elseif chunk.tag == 'link' then
        local label, href = link_resolver(chunk.content)
        p:add(html.a{label, href=href})
      end
    end
    ret:add(p)
  end
  return ret
end

return m