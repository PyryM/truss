-- plotting.t
--
-- functions for plotting graphs

local nanovg = core.nanovg
local m = {}

-- some default colors
m.defaultStrokeColor = nanovg.nvgRGBA(255,10,10,255) -- cyan-ish
m.defaultFillColor   = nanovg.nvgRGBA(255,10,10,60) -- cyan-ish
m.defaultLineWidth   = 2
m.fontsize           = 12

-- creates the path of a graph from normalized (0-1) values
-- Note: doesn't begin a path or actually stroke/fill it, just
-- LineTo's the points along it
function m.createGraphPath(nvg, x0, y0, width, height, vals, fillZero)
	local nvals = #vals
	local dx = width / (nvals - 1)
	local y1 = y0 + height
	local x1 = x0 + width
	local p0 = y1 - (vals[1] * height)
	local fillY = nil
	if fillZero then
		fillY = y1 - (fillZero * height)
		nanovg.nvgMoveTo(nvg, x0, fillY)
		nanovg.nvgLineTo(nvg, x0, p0)
	else
		nanovg.nvgMoveTo(nvg, x0, p0)
	end
	for i = 2,nvals do
		local x = (i-1)*dx + x0
		local y = y1 - (vals[i]*height)
		nanovg.nvgLineTo(nvg, x, y)
	end
	if fillZero then
		nanovg.nvgLineTo(nvg, x1, fillY)
		nanovg.nvgLineTo(nvg, x0, fillY)
	end
end



function m.drawGraphCore(nvg, bounds, style, vals, zeropoint)
	nanovg.nvgSave(nvg)

	nanovg.nvgStrokeWidth(nvg, style.linewidth or m.defaultLineWidth)
	nanovg.nvgStrokeColor(nvg, style.strokeColor or m.defaultStrokeColor)
	nanovg.nvgFillColor(nvg, style.fillColor or m.defaultFillColor)

	local x0 = bounds.x + bounds.ticlength
	local y0 = bounds.y
	local width = bounds.width - bounds.ticlength
	local height = bounds.height - bounds.ticlength

	if style.filled and zeropoint then
		nanovg.nvgBeginPath(nvg)
		m.createGraphPath(nvg, x0, y0, 
							   width, height, 
							   vals, zeropoint)
		nanovg.nvgFill(nvg)
	end

	nanovg.nvgBeginPath(nvg)
	m.createGraphPath(nvg, x0, y0, 
						   width, height, 
						   vals, nil)
	nanovg.nvgStroke(nvg)

	nanovg.nvgRestore(nvg)
end

-- finds next multiple of base that is larger than start
-- e.g. v = c*base >= start 
local function nextMultiple(start, base)
	local i = math.ceil(start / base)
	return base * i, i
end

function m.drawHTicMarks(nvg, bounds, style)
	nanovg.nvgSave(nvg)

	nanovg.nvgStrokeWidth(nvg, style.linewidth or m.defaultLineWidth)
	nanovg.nvgStrokeColor(nvg, style.strokeColor or m.defaultStrokeColor)
	nanovg.nvgFillColor(nvg, style.strokeColor or m.defaultStrokeColor)

	local fontsize = style.fontsize or m.fontsize
	nanovg.nvgFontSize(nvg, fontsize)
	nanovg.nvgFontFace(nvg, "sans")
	nanovg.nvgTextAlign(nvg, nanovg.NVG_ALIGN_CENTER)

	local h0 = bounds.h0
	local h1 = bounds.h1
	local ticspacing = bounds.hticspacing
	local ticmultiple = bounds.ticmultiple
	local ticheight = bounds.ticlength
	local y1 = bounds.y + bounds.height
	local y0 = y1 - ticheight
	local yminor = y1 - (ticheight * 0.75)
	local x0 = bounds.x + ticheight
	local x1 = bounds.x + bounds.width

	nanovg.nvgBeginPath(nvg)
	-- draw start and end tics
	-- nanovg.nvgMoveTo(nvg, x0, y0)
	-- nanovg.nvgLineTo(nvg, x0, y1)
	-- nanovg.nvgMoveTo(nvg, x1, y0)
	-- nanovg.nvgLineTo(nvg, x1, y1)

	-- draw other tics
	local xmult = (bounds.width - ticheight) / (h1 - h0)
	local curh, ticidx = nextMultiple(h0, ticspacing)
	local curx = (curh - h0) * xmult + x0
	local dx = ticspacing * xmult

	while curx < x1 do
		if ticidx % ticmultiple == 0 then
			nanovg.nvgMoveTo(nvg, curx, y0-5)
			nanovg.nvgLineTo(nvg, curx, yminor)
			nanovg.nvgText(nvg, curx, y1, "" .. curh, nil)
		else
			nanovg.nvgMoveTo(nvg, curx, y0)
			nanovg.nvgLineTo(nvg, curx, yminor)
		end
		curx = curx + dx
		curh = curh + ticspacing
		ticidx = ticidx + 1
	end

	nanovg.nvgStroke(nvg)
	nanovg.nvgRestore(nvg)
end

function m.drawVTicMarks(nvg, bounds, style)
	nanovg.nvgSave(nvg)

	nanovg.nvgStrokeWidth(nvg, style.linewidth or m.defaultLineWidth)
	nanovg.nvgStrokeColor(nvg, style.strokeColor or m.defaultStrokeColor)
	nanovg.nvgFillColor(nvg, style.strokeColor or m.defaultStrokeColor)

	local fontsize = style.fontsize or m.fontsize
	nanovg.nvgFontSize(nvg, fontsize)
	nanovg.nvgFontFace(nvg, "sans")
	nanovg.nvgTextAlign(nvg, nanovg.NVG_ALIGN_MIDDLE)

	local v0 = bounds.v0
	local v1 = bounds.v1
	local ticspacing = bounds.vticspacing
	local ticmultiple = bounds.ticmultiple
	local ticheight = bounds.ticlength
	local x0 = bounds.x + ticheight
	local x1 = x0 + 5
	local xcenter = x0 - (ticheight * 0.25)
	local y1 = bounds.y + bounds.height - ticheight
	local y0 = bounds.y


	nanovg.nvgBeginPath(nvg)
	-- draw start and end tics
	-- nanovg.nvgMoveTo(nvg, x0, y0)
	-- nanovg.nvgLineTo(nvg, x1, y0)
	-- nanovg.nvgMoveTo(nvg, x0, y1)
	-- nanovg.nvgLineTo(nvg, x1, y1)

	-- draw other tics
	local ymult = (bounds.height - ticheight) / (v1 - v0)
	local curv, ticidx = nextMultiple(v0, ticspacing)
	local cury = y1 - (curv - v0) * ymult
	local dy = ticspacing * ymult

	while cury > y0 do
		nanovg.nvgMoveTo(nvg, xcenter, cury)
		if ticidx % ticmultiple == 0 then
			nanovg.nvgLineTo(nvg, x1, cury)
			nanovg.nvgText(nvg, bounds.x, cury, "" .. curv, nil)
		else
			nanovg.nvgLineTo(nvg, x0, cury)
		end
		cury = cury - dy
		curv = curv + ticspacing
		ticidx = ticidx + 1
	end

	nanovg.nvgStroke(nvg)
	nanovg.nvgRestore(nvg)
end

function m.drawGraphAxes(nvg, bounds, style)
	-- todo
end

function m.init(nvg, width, height)
	m.pts = {}
	for i = 1,16 do
		m.pts[i] = {0.5, 0.5}
	end
end

function m.drawGraph(nvg, bounds, style, pts, zeropoint)
	m.drawVTicMarks(nvg, bounds, style)
	m.drawHTicMarks(nvg, bounds, style)
	m.drawGraphCore(nvg, bounds, style, pts, zeropoint)
end

m.t = 0.0
m.dumped = false

function m.makeTestBounds(x, y, w, h)
	local bounds = {x = x, y = y, width = w, height = h,
					h0 = 0, h1 = 21.0, hticspacing = 1.0, ticmultiple = 5,
					v0 = 0, v1 = 21.0, vticspacing = 2.0,
					ticlength = 14}
	return bounds
end

function m.testUpdatePts(pts)
	local nval = pts[#pts] + (math.random()-0.5)*0.1
	nval = math.min(1.0, math.max(0.0, nval))
	table.insert(pts, nval)
	if #pts > 60 then
		table.remove(pts, 1)
	end
end

function m.drawCross(nvg, x, y)
	-- a major divider is two capped lines
	nanovg.nvgSave(nvg)

	nanovg.nvgStrokeWidth(nvg, m.defaultLineWidth)
	nanovg.nvgStrokeColor(nvg, nanovg.nvgRGBA(255,255,255,100))

	nanovg.nvgBeginPath(nvg)

	nanovg.nvgMoveTo(nvg, x-5, y)
	nanovg.nvgLineTo(nvg, x+5, y)
	nanovg.nvgMoveTo(nvg, x, y-5)
	nanovg.nvgLineTo(nvg, x, y+5)	

	nanovg.nvgStroke(nvg)

	nanovg.nvgRestore(nvg)
end

function m.draw(nvg, width, height)
	nanovg.nvgFillColor(nvg, m.defaultStrokeColor)
	nanovg.nvgFontSize(nvg, 18)
	nanovg.nvgFontFace(nvg, "sans")

	-- just test draw a graph
	m.t = m.t + 1.0/60.0
	local pts = m.pts
	local style = {filled = true}
	local idx = 1
	for i = 1,4 do
		for j = 1,4 do
			local x = (i-1)*300 + 35
			local y = (j-1)*150 + 45
			local bounds = m.makeTestBounds(x, y, 280, 130)
			m.testUpdatePts(pts[idx])
			m.drawGraph(nvg, bounds, style, pts[idx], 0.0)
			nanovg.nvgText(nvg, x+7, y-4, "Graph " .. idx, nil)
			
			idx = idx + 1
		end
	end

	for i = 1,5 do
		for j = 1,5 do
			local x = (i-1)*300 + 30
			local y = (j-1)*150 + 30
			m.drawCross(nvg, x, y)
		end
	end
end

return m
