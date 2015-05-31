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

function m.render_(nvg)
	m.renderLines_(nvg)
	m.renderBorders_(nvg)
end

function m.getKeyString(keyname, modifiers)
	trss.trss_log(0, "Modifiers: " .. modifiers)

	local shiftdown = false
	if bit.band(modifiers, 1) > 0 or bit.band(modifiers, 2) > 0 then
		shiftdown = true
	end

	if #keyname == 1 then
		if shiftdown then 
			return keyname 
		else 
			return string.lower(keyname) 
		end
		--if modifiers
	else
		return keyname -- ??
	end
end

function m.typeLetter_(keyname, modifiers)
	m.editlines[1].str = m.editlines[1].str .. m.getKeyString(keyname, modifiers)
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
	-- todo
end

function m.onKeyDown(keyname, modifiers)
	if #keyname == 1 then
		m.typeLetter_(keyname, modifiers)
	elseif keyname == "Space" then
		m.typeLetter_(" ", 0)
	elseif keyname == "Backspace" then
		-- todo
	elseif keyname == "Return" then
		m.execute_()
	end
end

return m