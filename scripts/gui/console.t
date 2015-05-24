-- console.t
--
-- in-engine lua console

local m = {}

function makeRandomLines(nlines)
	local lines = {}
	for i = 1,nlines do
		lines[i] = "[" .. math.random() .. "]"
	end
	return lines
end

local function testDraw(nvg, width, height)
	nanovg.nvgSave(nvg)
	nanovg.nvgBeginPath(nvg)
	--nanovg.nvgRect(nvg, 100, 100, width-200, height-200)
	nanovg.nvgCircle(nvg, width / 2, height / 2, height / 2)
	local color0 = nanovg.nvgRGBA(0,0,0,255)
	local color1 = nanovg.nvgRGBA(0,255,255,255)
	local bg = nanovg.nvgRadialGradient(nvg, width/2 - 100, height/2 - 100, 0, height / 2,
					   color0, color1)
	--nanovg.nvgFillColor(nvg, color)
	nanovg.nvgFillPaint(nvg, bg)
	nanovg.nvgFill(nvg)
	nanovg.nvgRestore(nvg)

	nanovg.nvgSave(nvg)
	nanovg.nvgFontSize(nvg, 14)
	nanovg.nvgFontFace(nvg, "sans")
	local lines = makeRandomLines(20)
	local lineheight = 14
	local x0 = 30
	local y0 = 100
	local nlines = #lines
	for i = 1,nlines do
		local y = y0 + lineheight * (i-1)
		nanovg.nvgText(nvg, x0, y, lines[i], nil)
	end
	nanovg.nvgRestore(nvg)
end

function m.draw(nvg, width, height)
	testDraw(nvg, width, height)
end

return m