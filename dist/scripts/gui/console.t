-- console.t
--
-- in-engine lua console

local m = {}
local nanovg = core.nanovg

local function makeTestLines(n)
	local ret = {}
	local c0 = nanovg.nvgRGBA(100,100,100,255)
	local c1 = nanovg.nvgRGBA(70,70,70,255)
	local cols = {c0, c1}
	for i = 1,n do
		ret[i] = {str = "test line " .. n .. " some descenders: pqjg",
				  bgcolor = cols[(i % 2) + 1]}
	end
	return ret
end

m.leftmargin = 5.5
m.linetopmargin = -3.5
m.xpos = 100
m.ypos = 100
m.width = 600
m.linemargin = 2
m.fontsize = 14
m.numBuffersLines = 10
m.bgcolor = nanovg.nvgRGBA(40,40,40,200)
m.fgcolor = nanovg.nvgRGBA(200,255,255,255)
m.inputcolor = nanovg.nvgRGBA(100,100,150,255)
m.bordercolor = nanovg.nvgRGBA(200,255,255,128)
m.bufferpos = 0
m.editline = ""
m.editchunklist =  {}
m.bufferchunklists = {}
m.numBufferChunkLists = 20
m.open = true
m.execCallback = nil

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

local function randchoice(opts)
	local nopts = #opts
	local idx = math.floor(math.random() * nopts) + 1
	return opts[idx]
end

local function makeTestChunk(nbits)
	local words = {"a word", "something ", "blargh ", "foo ", "oh my ",
					" PUNCTIONATIon???? "}
	
	local colors = {rgba(255,128,128,255),
					rgba(128,255,128,255),
					rgba(128,128,255,255),
					rgba(255,255,128,255),
					rgba(255,128,255,255),
					rgba(128,255,255,255)}
	local styles = {m.style_colored, m.style_normal, m.style_background}
	local ret = {}
	for i = 1,nbits do
		local c = {style = randchoice(styles),
				   fgcolor = randchoice(colors),
				   bgcolor = randchoice(colors),
				   str = randchoice(words)}
		table.insert(ret, c)
	end
	return ret
end

local function makeTestChunks(n)
	local ret = {}
	local nmake = 10
	for i = 1,nmake do
		table.insert(ret, makeTestChunk(7))
	end

	m.bufferchunklists = ret
	m.numBufferChunkLists = #(m.bufferchunklists)
end

--makeTestChunks(10)

function m.printChunkList_(chunklist)
	table.insert(m.bufferchunklists, chunklist)
	if #m.bufferchunklists >= m.numBufferChunkLists then
		m.bufferpos = m.bufferpos + 1
	end
end

function m.printStraightText_(rawtext)
	local chunk = {str = rawtext, style = m.style_normal}
	m.printChunkList_({chunk})
end

function m.printDivider_()
	local d = ""
	for i = 1,80 do 
		d = d .. "="
	end
	m.printStraightText_(d)
end

function m.printColored(str, color)
	local nvgColor = nanovg.nvgRGBA(color[1], color[2], color[3], 255)
	local chunk = {str = str or "", style = m.style_colored,
					fgcolor = nvgColor}
	m.printChunkList_({chunk})
end

function m.printHighlighted(str, color)
	local nvgColor = nanovg.nvgRGBA(color[1], color[2], color[3], 255)
	local chunk = {str = str or "", style = m.style_colored,
					bgcolor = nvgColor}
	m.printChunkList_({chunk})
end

function m.printLogo_()
	local foo = [[asdf]]
	local logolines = {
		[[    _____________________ ____ ___  _________ _________]],
		[[    \__    ___/\______   \    |   \/   _____//   _____/]],
		[[      |    |    |       _/    |   /\_____  \ \_____  \ ]],
		[[      |    |    |    |   \    |  / /        \/        \]],
		[[      |____|    |____|_  /______/ /_______  /_______  /]],
		[[                       \/                 \/        \/ ]]
	}
	local padding = "          "
	local color0 = nanovg.nvgRGBA(128,128,255,255)
	local color1 = nanovg.nvgRGBA(255,255,255,255)
	
	m.printDivider_()
	m.printDivider_()
	for i = 1,#logolines do
		local alpha = (i - 1) / (#logolines - 1)
		local color = nanovg.nvgLerpRGBA(color0, color1, alpha)
		local chunk = {str = padding .. logolines[i],
					   style = m.style_colored,
					   fgcolor = color}
		m.printChunkList_({chunk})
	end
	m.printDivider_()
	m.printDivider_()
end

function m.renderChunkList_(nvg, chunklist, ypos)
	if not chunklist then return end
	local xpos = m.xpos + m.leftmargin
	for i,chunk in ipairs(chunklist) do
		xpos = chunk:style(nvg, xpos, ypos)
	end
end

function m.renderLine_(nvg, line, ypos)
	if not line then return end

	nanovg.nvgFillColor(nvg, m.fgcolor)
	nanovg.nvgText(nvg, m.xpos + m.leftmargin, ypos, line, nil)
end

function m.renderBackground_(nvg)
	nanovg.nvgBeginPath(nvg)
	nanovg.nvgRect(nvg, m.xpos, m.ypos, m.width, m.height)
	nanovg.nvgFillColor(nvg, m.bgcolor)
	nanovg.nvgFill(nvg)
end

function m.renderBorders_(nvg)
	local numBuffersLines = m.numBuffersLines
	local h0 = m.height - m.lineheight
	local h1 = m.lineheight
	local y0 = m.ypos
	local y1 = y0 + h0
	local y2 = y1 + h1

	nanovg.nvgBeginPath(nvg)
	nanovg.nvgStrokeColor(nvg, m.bordercolor)
	nanovg.nvgStrokeWidth(nvg, 1.0)

	nanovg.nvgMoveTo(nvg, m.xpos, y0)
	nanovg.nvgLineTo(nvg, m.xpos, y2)

	nanovg.nvgMoveTo(nvg, m.xpos, y1)
	nanovg.nvgLineTo(nvg, m.xpos + m.width, y1)

	nanovg.nvgMoveTo(nvg, m.xpos, y1 - 2)
	nanovg.nvgLineTo(nvg, m.xpos + m.width, y1 - 2)

	nanovg.nvgStroke(nvg)

	-- nanovg.nvgStrokeWidth(nvg, 2.0)
	-- nanovg.nvgStrokeColor(nvg, m.fgcolor)
	-- nanovg.nvgFillColor(nvg, m.fgcolor)

	-- nanovg.nvgBeginPath(nvg)
	-- nanovg.nvgRect(nvg, m.xpos, y0, m.width, h0)
	-- nanovg.nvgStroke(nvg)

	-- nanovg.nvgBeginPath(nvg)
	-- nanovg.nvgRect(nvg, m.xpos, y1, m.width, h1)
	-- nanovg.nvgStroke(nvg)
end

function m.renderChunkLists_(nvg)
	nanovg.nvgFontSize(nvg, m.fontsize)
	nanovg.nvgFontFace(nvg, "sans")

	local numBuf = m.numBufferChunkLists
	local bufbuf = m.bufferchunklists
	local boffset = m.bufferpos

	local ypos = m.ypos + m.linetopmargin + m.lineheight
	for i = 1, numBuf do
		m.renderChunkList_(nvg, bufbuf[i + boffset], ypos)
		ypos = ypos + m.lineheight
	end

	m.renderLine_(nvg, m.editline, m.height + m.linetopmargin)
	ypos = ypos + m.lineheight

end

function m.render_(nvg)
	--m.renderLines_(nvg)
	m.renderBackground_(nvg)
	m.getCharacterSize_(nvg)
	m.renderChunkLists_(nvg)
	m.renderBorders_(nvg)
end

function m.chunkify_(str)
	local ret = {}
	-- for now, just put the chunk into a single string
	ret[1] = {str = ">" .. str, style = m.style_background, bgcolor = m.inputcolor}
	return ret
end

function m.textInput_(tstr)
	m.editline = m.editline .. tstr
end

function m.execute_()
	if not m.open then return end

	table.insert(m.bufferchunklists, m.chunkify_(m.editline))
	if #m.bufferchunklists >= m.numBufferChunkLists then
		m.bufferpos = m.bufferpos + 1
	end
	if m.execCallback then
		m.execCallback(m.editline)
	end
	m.editline = ""
end

function m.draw(nvg, width, height)
	if m.open then
		m.render_(nvg)
	end
end

function m.getCharacterSize_(nvg)
	local xpos, ypos = 40, 40
	nanovg.nvgFontSize(nvg, m.fontsize)
	nanovg.nvgFontFace(nvg, "sans")
	local teststring = ""
	for i = 1,80 do
		teststring = teststring .. "="
	end

	nanovg.nvgTextBounds(nvg, xpos, ypos, teststring, nil, m.bounds_struct)
	m.charWidth = (m.bounds_struct[2] - m.bounds_struct[0]) / 80
	m.charHeight = m.bounds_struct[3] - m.bounds_struct[1]
	m.charTopOffset = m.bounds_struct[1] - ypos
	m.lineheight = m.charHeight + m.linemargin
	--truss.truss_log(0, "Char height: " .. m.charHeight)
	--truss.truss_log(0, "charTopOffset: " .. m.charTopOffset)
end

function m.init(width, height, nvg)
	m.getCharacterSize_(nvg)
	log.debug("Char size: " .. m.charWidth .. ", " .. m.charHeight)
	m.width = 81 * m.charWidth
	m.height = height - 2
	m.xpos = width - m.width - 0.5
	m.ypos = 0.5
	m.numBufferChunkLists = math.floor(m.height / m.lineheight)
	m.printLogo_()
	-- height??
end

function m.onTextInput(textstr)
	if m.open then
		m.textInput_(textstr)
	end
end

function m.backspace_()
	if #(m.editline) > 0 and m.open then
		m.editline = string.sub(m.editline, 1, -2)
	end
end

function m.onKeyDown(keyname, modifiers)
	if keyname == "Backspace" then
		m.backspace_()
	elseif keyname == "Escape" then
		m.open = not m.open
	elseif keyname == "Return" then
		m.execute_()
	end
end

return m