-- widgetdrawing.t
--
-- common widget styling drawing operations

local m = {}
m.unitsize = 1 					-- how big a 'unit' is (px)
m.linewidth = m.unitsize * 1.5  -- lines are 1.5 units thick
m.blocksize = m.unitsize * 16   -- how big a 'block' is (units)
m.defaultColor = nanovg.nvgRGBA(200,255,255,200) -- cyan-ish

-- drawMajorDivider(nvg, x0, y0, width, color) --> y1
--
-- draws a major divider (can be used as a header or footer)
-- a major divider is 1 block high
function m.drawMajorDivider(nvg, x0, y0, width, color)
	-- a major divider is two capped lines
	nanovg.nvgSave(nvg)

	nanovg.nvgStrokeWidth(nvg, m.linewidth)
	nanovg.nvgStrokeColor(nvg, color or m.defaultColor)
	nanovg.nvgFillColor(nvg, color or m.defaultColor)


	local x1 = x0 + width
	nanovg.nvgBeginPath(nvg)
	nanovg.nvgMoveTo(nvg, x0, y0)
	nanovg.nvgLineTo(nvg, x1, y0)
	nanovg.nvgStroke(nvg)

	local y1 = y0 + m.blocksize * 0.4
	nanovg.nvgBeginPath(nvg)
	nanovg.nvgMoveTo(nvg, x0, y1)
	nanovg.nvgLineTo(nvg, x1, y1)
	nanovg.nvgStroke(nvg)

	local us = m.unitsize * 1.5
	nanovg.nvgBeginPath(nvg)
	nanovg.nvgRect(nvg, x0 - us, y0 - us, us*2, us*2)
	nanovg.nvgFill(nvg)

	nanovg.nvgBeginPath(nvg)
	nanovg.nvgRect(nvg, x1 - us, y0 - us, us*2, us*2)
	nanovg.nvgFill(nvg)

	nanovg.nvgBeginPath(nvg)
	nanovg.nvgRect(nvg, x0 - us, y1 - us, us*2, us*2)
	nanovg.nvgFill(nvg)

	nanovg.nvgBeginPath(nvg)
	nanovg.nvgRect(nvg, x1 - us, y1 - us, us*2, us*2)
	nanovg.nvgFill(nvg)

	nanovg.nvgRestore(nvg)
	--trss.trss_log(0, "drew?")

	return y0 + m.blocksize
end

-- drawFrame
--
-- draws a frame
function m.drawFrame()
	-- todo
end

-- drawAltFrame
--
-- draws a frame (alternative styling)
function m.drawAltFrame()
	--todo
end



-- test drawing function for live coding
function m.draw(nvg, width, height)
	nanovg.nvgBeginPath(nvg)
	nanovg.nvgRect(nvg, 0, 0, width, height)
	nanovg.nvgFillColor(nvg, nanovg.nvgRGBA(0,0,0,255))
	nanovg.nvgFill(nvg)

	m.drawMajorDivider(nvg, 20, 100.5, 200)

	m.drawMajorDivider(nvg, 20, 200, 200)
	m.drawMajorDivider(nvg, 20, 250, 200)

	m.drawMajorDivider(nvg, 20, 450 - m.blocksize * 0.35, 200)

	m.drawMajorDivider(nvg, 250, 100.5, 500)
	m.drawMajorDivider(nvg, 250, 450 - m.blocksize * 0.35, 500)
end

return m