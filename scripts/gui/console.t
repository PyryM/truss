-- console.t
--
-- in-engine lua console

local m = {}

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

m.leftmargin = 5
m.linetopmargin = -4
m.xpos = 100
m.ypos = 100
m.width = 600
m.lineheight = 20
m.fontsize = 14
m.numBuffersLines = 10
m.numEditLines = 1
m.bgcolor = nanovg.nvgRGBA(100,100,100,255)
m.fgcolor = nanovg.nvgRGBA(200,255,255,255)
m.bufferlines = makeTestLines(m.numBuffersLines)
m.bufferpos = 0
m.editlines = {{str = ">"}}

m.bounds_struct = terralib.new(float[4])

function m.getStrXSize(nvg, xpos, ypos, str)
	local x1 = nanovg.nvgTextBounds(nvg, xpos, ypos, str, nil, nil)
	return x1
end

function m.getStrBounds(nvg, xpos, ypos, str)
	nanovg.nvgTextBounds(nvg, xpos, ypos, str, nil, m.bounds_struct)
	return m.bounds_struct[0], m.bounds_struct[1], m.bounds_struct[2], m.bounds_struct[3]
end

-- chunk style functions
function m.style_normal(chunk, nvg, xpos, ypos)
	nanovg.nvgFillColor(nvg, m.fgcolor)
	local newx = nanovg.nvgText(nvg, xpos, ypos, chunk.str, nil)
	return newx
end

function m.style_colored(chunk, nvg, xpos, ypos)
	nanovg.nvgFillColor(nvg, chunk.fgcolor or m.fgcolor)
	local newx = nanovg.nvgText(nvg, xpos, ypos, chunk.str, nil)
	return newx
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
	local words = {" a word", " something ", " blargh ", " foo ", " oh my ",
					" PUNCTIONATIon???? "}
	local rgba = nanovg.nvgRGBA
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

makeTestChunks(10)

function m.renderChunkList_(nvg, chunklist, ypos)
	local xpos = m.xpos + m.leftmargin
	for i,chunk in ipairs(chunklist) do
		xpos = chunk:style(nvg, xpos, ypos)
	end
end

function m.renderLine_(nvg, line, ypos)
	if not line then return end

	nanovg.nvgBeginPath(nvg)
	nanovg.nvgRect(nvg, m.xpos, ypos, m.width, m.lineheight)
	nanovg.nvgFillColor(nvg, line.bgcolor or m.bgcolor)
	nanovg.nvgFill(nvg)

	nanovg.nvgFillColor(nvg, line.fgcolor or m.fgcolor)
	nanovg.nvgText(nvg, m.xpos + m.leftmargin, ypos + m.linetopmargin + m.lineheight, line.str, nil)
end

function m.renderBorders_(nvg)
	local numBuffersLines = m.numBuffersLines
	local numEditLines = m.numEditLines
	local h0 = m.lineheight * numBuffersLines
	local h1 = m.lineheight * numEditLines
	local y0 = m.ypos
	local y1 = y0 + h0
	local y2 = y1 + h1

	nanovg.nvgStrokeWidth(nvg, 2.0)
	nanovg.nvgStrokeColor(nvg, m.fgcolor)
	nanovg.nvgFillColor(nvg, m.fgcolor)

	nanovg.nvgBeginPath(nvg)
	nanovg.nvgRect(nvg, m.xpos, y0, m.width, h0)
	nanovg.nvgStroke(nvg)

	nanovg.nvgBeginPath(nvg)
	nanovg.nvgRect(nvg, m.xpos, y1, m.width, h1)
	nanovg.nvgStroke(nvg)
end

function m.renderLines_(nvg)
	local numBuf, numEdit = m.numBuffersLines, m.numEditLines
	local bufbuf = m.bufferlines
	local editbuf = m.editlines
	local boffset = m.bufferpos

	local ypos = m.ypos
	for i = 1, numBuf do
		m.renderLine_(nvg, bufbuf[i + boffset], ypos)
		ypos = ypos + m.lineheight
	end

	for i = 1, numEdit do
		m.renderLine_(nvg, editbuf[i], ypos)
		ypos = ypos + m.lineheight
	end
end

function m.renderChunkLists_(nvg)
	local numBuf, numEdit = m.numBufferChunkLists, m.numEditLines
	local bufbuf = m.bufferchunklists
	local editbuf = m.editlines
	local boffset = m.bufferpos

	local ypos = m.ypos + m.linetopmargin + m.lineheight
	for i = 1, numBuf do
		m.renderChunkList_(nvg, bufbuf[i + boffset], ypos)
		ypos = ypos + m.lineheight
	end

	for i = 1, numEdit do
		m.renderLine_(nvg, editbuf[i], ypos)
		ypos = ypos + m.lineheight
	end
end

function m.render_(nvg)
	--m.renderLines_(nvg)
	m.renderChunkLists_(nvg)
	m.renderBorders_(nvg)
end

function m.textInput_(tstr)
	m.editlines[1].str = m.editlines[1].str .. tstr
end

function m.execute_()
	for i = 1,m.numEditLines do
		table.insert(m.bufferlines, {str = m.editlines[i].str})
		m.editlines[i].str = ""
		m.bufferpos = m.bufferpos + 1
	end
end

function m.draw(nvg, width, height)
	m.render_(nvg)
end

function m.init(width, height)
	-- TODO 
end

function m.onTextInput(textstr)
	m.textInput_(textstr)
end

function m.onKeyDown(keyname, modifiers)
	if keyname == "Backspace" then
		-- todo
	elseif keyname == "Return" then
		m.execute_()
	end
end

return m