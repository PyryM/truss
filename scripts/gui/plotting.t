-- plotting.t
--
-- functions for plotting graphs

local nanovg = core.nanovg
local class = require("class")
local m = {}

-- some default colors
m.defaultStrokeColor = nanovg.nvgRGBA(235,235,255,255) -- cyan-ish
m.defaultFillColor   = nanovg.nvgRGBA(235,235,255,60) -- cyan-ish
m.defaultLineWidth   = 1
m.fontsize           = 12

-- creates the path of a line graph from normalized (0-1) values
-- evenly spaced from x0 to x0+width
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

-- creates paths for a candlestick-ish chart
-- input is a 2n list of low, high normalized (0-1) pairs
-- e.g. {low_0, high_0, low_1, high_1, ...}
function m.createCandlestickPath(nvg, x0, y0, width, height, vals)
	local nvals = #vals / 2
	local dx = width / (nvals - 1)
	local y1 = y0 + height
	local x1 = x0 + width
	local idx = 1
	for i = 1,nvals do
		local low = vals[idx]
		local high = vals[idx+1]
		idx = idx + 2
		local x = (i-1)*dx + x0
		local ylow = y1 - (low*height)
		local yhigh = y1 - (high*height)
		nanovg.nvgMoveTo(nvg, x, ylow)
		nanovg.nvgLineTo(nvg, x, yhigh)
	end
end

-- creates paths for a xy chart
-- input is a 2n list of low, high normalized (0-1) pairs
-- e.g. {x0, y0, x1, y1, ...}
function m.createXYPath(nvg, x0, y0, width, height, vals)
	local nvals = #vals / 2
	local dx = width / (nvals - 1)
	local y1 = y0 + height
	local x1 = x0 + width
	local curx = x0 + vals[1]*width
	local cury = y1 - vals[2]*height
	--nanovg.nvgMoveTo(nvg, curx, cury)

	--nanovg.nvgFillColor(nvg, m.defaultFillColor)

	local idx = 1
	for i = 1,nvals do
		curx = x0 + vals[idx]*width
		cury = y1 - vals[idx+1]*height
		idx = idx + 2
		nanovg.nvgBeginPath(nvg)
		nanovg.nvgCircle(nvg, curx, cury, 12)
		nanovg.nvgFill(nvg)
	end
end

function m.drawCandleCore(nvg, bounds, style, vals)
	nanovg.nvgSave(nvg)

	nanovg.nvgStrokeWidth(nvg, (style.linewidth or m.defaultLineWidth)*3)
	nanovg.nvgStrokeColor(nvg, style.strokeColor or m.defaultStrokeColor)
	nanovg.nvgFillColor(nvg, style.fillColor or m.defaultFillColor)

	local x0 = bounds.x + bounds.ticlength
	local y0 = bounds.y
	local width = bounds.width - bounds.ticlength
	local height = bounds.height - bounds.ticlength

	nanovg.nvgScissor(nvg, x0, y0, width, height)
	nanovg.nvgBeginPath(nvg)
	m.createCandlestickPath(nvg, x0, y0, 
						   width, height, 
						   vals)
	nanovg.nvgStroke(nvg)

	nanovg.nvgRestore(nvg)
end

function m.drawXYCore(nvg, bounds, style, vals)
	nanovg.nvgSave(nvg)

	nanovg.nvgStrokeWidth(nvg, (style.linewidth or m.defaultLineWidth)*2)
	nanovg.nvgStrokeColor(nvg, style.strokeColor or m.defaultStrokeColor)
	nanovg.nvgFillColor(nvg, style.fillColor or m.defaultFillColor)
	nanovg.nvgMiterLimit(nvg, 0.5)

	local x0 = bounds.x + bounds.ticlength
	local y0 = bounds.y
	local width = bounds.width - bounds.ticlength
	local height = bounds.height - bounds.ticlength

	nanovg.nvgScissor(nvg, x0, y0, width, height)
	--nanovg.nvgBeginPath(nvg)
	m.createXYPath(nvg, x0, y0, 
						   width, height, 
						   vals)
	--nanovg.nvgStroke(nvg)

	nanovg.nvgRestore(nvg)
end


function m.drawGraphCore(nvg, bounds, style, vals, zeropoint)
	nanovg.nvgSave(nvg)

	nanovg.nvgStrokeWidth(nvg, (style.linewidth or m.defaultLineWidth)*2)
	nanovg.nvgStrokeColor(nvg, style.strokeColor or m.defaultStrokeColor)
	nanovg.nvgFillColor(nvg, style.fillColor or m.defaultFillColor)

	local x0 = bounds.x + bounds.ticlength
	local y0 = bounds.y
	local width = bounds.width - bounds.ticlength
	local height = bounds.height - bounds.ticlength

	nanovg.nvgScissor(nvg, x0, y0, width, height)

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

function m.drawGeneric(nvg, bounds, style, vals, funcs)
	nanovg.nvgSave(nvg)

	nanovg.nvgStrokeWidth(nvg, (style.linewidth or m.defaultLineWidth)*2)
	nanovg.nvgStrokeColor(nvg, style.strokeColor or m.defaultStrokeColor)
	nanovg.nvgFillColor(nvg, style.fillColor or m.defaultFillColor)

	local x0 = bounds.x + bounds.ticlength
	local y0 = bounds.y
	local width = bounds.width - bounds.ticlength
	local height = bounds.height - bounds.ticlength
	local h0 = bounds.h0
	local h1 = bounds.h1
	local v0 = bounds.v0
	local v1 = bounds.v1

	nanovg.nvgScissor(nvg, x0, y0, width, height)

	local nvals = #vals
	local stride = funcs.stride

	if funcs.pre then
		funcs.pre(vals, 1, x0, y0, width, height, h0, h1, v0, v1)
	end

	local idx = 1

	for i = 2,nvals do
		local x = (i-1)*dx + x0
		local y = y1 - (vals[i]*height)
		nanovg.nvgLineTo(nvg, x, y)

		idx = idx + stride
	end

	if funcs.post then
		funcs.post(vals, idx, x0, y0, width, height, h0, h1, v0, v1)
	end

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

function m.drawLineGraph(nvg, bounds, style, pts, zeropoint)
	m.drawVTicMarks(nvg, bounds, style)
	m.drawHTicMarks(nvg, bounds, style)
	m.drawGraphCore(nvg, bounds, style, pts, zeropoint)
end

function m.drawCandleGraph(nvg, bounds, style, pts)
	m.drawVTicMarks(nvg, bounds, style)
	m.drawHTicMarks(nvg, bounds, style)
	m.drawCandleCore(nvg, bounds, style, pts)
end

function m.drawXYGraph(nvg, bounds, style, pts)
	m.drawVTicMarks(nvg, bounds, style)
	m.drawHTicMarks(nvg, bounds, style)
	m.drawXYCore(nvg, bounds, style, pts)
end

m.t = 0.0
m.dumped = false

function m.makeTestBounds(x, y, w, h)
	local bounds = {x = x, y = y, width = w, height = h,
					h0 = m.t + 0, h1 = m.t + 21.0, hticspacing = 1.0, ticmultiple = 5,
					v0 = 0, v1 = 21.0, vticspacing = 2.0,
					ticlength = 14}
	return bounds
end

function m.testUpdatePts(pts, doubleAdd)
	local nval = pts[#pts] + (math.random()-0.5)*0.1
	nval = math.min(1.0, math.max(0.0, nval))

	if doubleAdd then
		local nval2 = pts[#pts-1] + (math.random()-0.5)*0.1
		nval2 = math.min(1.0, math.max(0.0, nval2))
		table.insert(pts, nval2)
	end
	
	table.insert(pts, nval)

	while #pts > 60 do
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
	nanovg.nvgFontFace(nvg, "sans")
	nanovg.nvgFontSize(nvg, 50)
	nanovg.nvgText(nvg, 770, 60, "truss/ futureplot", nil)


	nanovg.nvgFontSize(nvg, 18)

	-- just test draw a graph
	m.t = m.t + 21.0/120.0
	local pts = m.pts
	local style = {filled = true}
	local idx = 1
	for i = 1,4 do
		for j = 1,4 do
			local x = (i-1)*300 + 35
			local y = (j-1)*150 + 105
			local bounds = m.makeTestBounds(x, y, 280, 130)
			if (i+j) % 2 == 0 then
				m.testUpdatePts(pts[idx], false)
				m.drawLineGraph(nvg, bounds, style, pts[idx], 0.0)
			else
				m.testUpdatePts(pts[idx], true)
				m.drawXYGraph(nvg, bounds, style, pts[idx])
			end
			nanovg.nvgText(nvg, x+7, y-4, "Graph " .. idx, nil)
			
			idx = idx + 1
		end
	end

	for i = 1,5 do
		for j = 1,5 do
			local x = (i-1)*300 + 30
			local y = (j-1)*150 + 90
			m.drawCross(nvg, x, y)
		end
	end
end

local function mergeTableInto(target, src)
	for k,v in pairs(src) do
		target[k] = v
	end
end

local Graph = class("Graph")

function Graph:init(options)
	self.style_ = {filled = options.filled}
	self.bounds_ = {x = 0, y = 0, width = 100, height = 100,
					h0 = 0, h1 = 21.0, hticspacing = 1.0, ticmultiple = 5,
					v0 = 0, v1 = 21.0, vticspacing = 2.0,
					ticlength = 14}
	self.pts_ = {0,0}
	self.maxPts_ = 60
	self.isLineGraph = true
	self.isXYGraph = false
end

function Graph:setBounds(bounds)
	self.bounds_.x = bounds.x
	self.bounds_.y = bounds.y
	self.bounds_.width = bounds.width
	self.bounds_.height = bounds.height
	return self
end

function Graph:setLimits(x0, x1, y0, y1)
	self.bounds_.h0 = x0
	self.bounds_.h1 = x1
	self.bounds_.v0 = y0
	self.bounds_.v1 = y1
	return self
end

function Graph:setHistoryLength(npts)
	self.maxPts_ = npts
	return self
end

function Graph:setTics(hTicSpacing, vTicSpacing, majorMultiple)
	self.bounds_.hticspacing = hTicSpacing
	self.bounds_.vticspacing = vTicSpacing
	self.bounds_.ticmultiple = majorMultiple
	return self
end

function Graph:pushValue(newval)
	table.insert(self.pts_, newval)
	while #(self.pts_) > self.maxPts_ do
		table.remove(self.pts_, 1)
	end
end

function Graph:draw(nvg)
	if self.isLineGraph then
		m.drawLineGraph(nvg, self.bounds_, self.style_, self.pts_, 0.0)
	elseif self.isXYGraph then
		m.drawXYGraph(nvg, self.bounds_, self.style_, self.pts_)
	else
		m.drawCandleGraph(nvg, self.bounds_, self.style_, self.pts_)
	end
end

m.Graph = Graph
return m
