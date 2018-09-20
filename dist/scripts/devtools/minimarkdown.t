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

  local function namer(tag)
    return function(s)
      return setmetatable({tag = tag, content = s}, tag_mt)
    end
  end

  local function make_special(tag, open_str, close_str)
    local open = lpeg.P(open_str)
    local close = lpeg.P(close_str)
    return (open * lpeg.C((lpeg.P(1) - close)^0) * close) / namer(tag)
  end

  local emph = make_special("emph", "*", "*")
  local code = make_special("code", "`", "`")
  local link = make_special("link", "{{", "}}")
  local newline = lpeg.S("\n")
  local header = (lpeg.S(' \t\n')^0 * lpeg.C(lpeg.S("#")^1) * lpeg.C(lpeg.P(1)^0)) 
                  / function(pounds, content)
    return {tag = 'header', level = #pounds, content = content or ""}
  end
  local directive = (lpeg.S(' \t\n')^0 * lpeg.P("!!") * lpeg.C(lpeg.P(1)^0)) 
                  / namer("directive")

  local specials = emph + code + link
  local normal_text = lpeg.C((lpeg.P(1) - specials)^1)
  local tagged = header + directive + lpeg.Ct((normal_text + specials)^0)

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

m.default_resolver = {
  link = function(_, content)
    return html.a{content, href = content}
  end,
  directive = function(_, content)
    return html.emph{content}
  end
}

function m.generate(s, resolver)
  resolver = resolver or m.default_resolver
  local html = require("./htmlgen.t")
  local ret = html.group()

  s = (s or ""):gsub("\r", "") -- our grammar only handles \n
  s = s:gsub("<", "&lt")       -- sanitize <> so they won't break html
  s = s:gsub(">", "&gt") 

  for _, text in ipairs(m.split_paragraphs(s)) do
    local tags = m.split_tags(text)
    if tags.tag == "header" then
      local hlevel = "h" .. tags.level
      ret:add(html[hlevel]{tags.content})
    elseif tags.tag == "directive" then
      ret:add(resolver:directive(tags.content))
    else
      local p = html.p()
      for _, chunk in ipairs(tags) do
        if type(chunk) == 'string' then
          p:add(chunk)
        elseif chunk.tag == 'code' then
          p:add(html.code{chunk.content}) --, class="language-lua"})
        elseif chunk.tag == 'emph' then
          p:add(html.emph{chunk.content})
        elseif chunk.tag == 'link' then
          p:add(resolver:link(chunk.content))
        else
          truss.error("Unknown tag " .. tostring(chunk.tag))
        end
      end
      ret:add(p)
    end
  end
  return ret
end

return m