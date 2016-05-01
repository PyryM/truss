-- textdrawing.t
--
-- useful functions for drawing stylized text

local nanovg = core.nanovg

local m = {}

m.linemargin = 2
m.fontsize = 14
m.bgcolor = nanovg.nvgRGBA(40,40,40,200)
m.fgcolor = nanovg.nvgRGBA(200,255,255,255)

m.bounds_struct = terralib.new(float[4])

function m.getStrXSize(nvg, xpos, ypos, str)
	local x1 = nanovg.nvgTextBounds(nvg, xpos, ypos, str, nil, nil)
	return x1
end

function m.getStrBounds(nvg, xpos, ypos, str)
	local w = #str * m.charWidth
	local y0 = ypos + m.charTopOffset
	local y1 = y0 + m.charHeight

	return xpos, y0, xpos+w, y1
	--nanovg.nvgTextBounds(nvg, xpos, ypos, str, nil, m.bounds_struct)
	--return m.bounds_struct[0], m.bounds_struct[1], m.bounds_struct[2], m.bounds_struct[3]
end

-- chunk style functions
function m.style_normal(chunk, nvg, xpos, ypos)
	nanovg.nvgFillColor(nvg, m.fgcolor)
	nanovg.nvgText(nvg, xpos, ypos, chunk.str, nil)
	return xpos + (#(chunk.str) * m.charWidth)
end

function m.style_colored(chunk, nvg, xpos, ypos)
	nanovg.nvgFillColor(nvg, chunk.fgcolor or m.fgcolor)
	nanovg.nvgText(nvg, xpos, ypos, chunk.str, nil)
	return xpos + (#(chunk.str) * m.charWidth)
end

function m.style_background(chunk, nvg, xpos, ypos)
	local x0, y0, x1, y1 = m.getStrBounds(nvg, xpos, ypos, chunk.str)
	nanovg.nvgBeginPath(nvg)
	nanovg.nvgRoundedRect(nvg, x0, y0, x1-x0, y1-y0, 3.0)
	nanovg.nvgFillColor(nvg, chunk.bgcolor or m.bgcolor)
	nanovg.nvgFill(nvg)

	return m.style_normal(chunk, nvg, xpos, ypos)
end

function m.printStraightText(rawtext, dest)
	dest = dest or {}
	local chunk = {str = rawtext, style = m.style_normal}
	table.insert(dest, chunk)
	return dest
end

function m.printColored(str, color, dest)
	dest = dest or {}
	local nvgColor = nanovg.nvgRGBA(color[1], color[2], color[3], color[4] or 255)
	local chunk = {str = str or "", style = m.style_colored,
					fgcolor = nvgColor}
	table.insert(dest, chunk)
	return dest
end

function m.printHighlighted(str, color, dest)
	dest = dest or {}
	local nvgColor = nanovg.nvgRGBA(color[1], color[2], color[3], 255)
	local chunk = {str = str or "", style = m.style_colored,
					bgcolor = nvgColor}
	table.insert(dest, chunk)
	return dest
end

function m.renderChunkList_(nvg, chunklist, xpos, ypos)
	if not chunklist then return end
	for i,chunk in ipairs(chunklist) do
		xpos = chunk:style(nvg, xpos, ypos)
	end
end

function m.drawFormattedText(nvg, chunklists, bounds, style)
	nanovg.nvgSave(nvg)
	nanovg.nvgFontSize(nvg, style.fontsize or m.fontsize)
	nanovg.nvgFontFace(nvg, style.fontface or "sans")
	nanovg.nvgScissor(nvg, bounds.x, bounds.y, bounds.width, bounds.height)

	m.getCharacterSize_(nvg)

	local numBuf = #chunklists
	local bufbuf = chunklists

	local ypos = bounds.y + style.lineheight
	local xpos = bounds.x
	local lineheight = style.lineheight or (style.fontsize + 2)

	for i = 1, numBuf do
		m.renderChunkList_(nvg, bufbuf[i], xpos, ypos)
		ypos = ypos + lineheight
	end

	nanovg.nvgRestore(nvg)
end

function m.getCharacterSize_(nvg)
	local xpos, ypos = 40, 40

	local teststring = ""
	for i = 1,80 do
		teststring = teststring .. "="
	end

	nanovg.nvgTextBounds(nvg, xpos, ypos, teststring, nil, m.bounds_struct)
	m.charWidth = (m.bounds_struct[2] - m.bounds_struct[0]) / 80
	m.charHeight = m.bounds_struct[3] - m.bounds_struct[1]
	m.charTopOffset = m.bounds_struct[1] - ypos
	--truss.truss_log(0, "Char height: " .. m.charHeight)
	--truss.truss_log(0, "charTopOffset: " .. m.charTopOffset)
end

return m