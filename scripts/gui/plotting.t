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

local function tableMap(src, map)
	local dest = {}
	for i,v in ipairs(src) do
		dest[i] = map[v]
	end
	return dest
end

-- converts coordinates from graph space into screen spce
function m.convertCoordinates(vals, bounds, format, dest)
	-- convert all conversions into Ax+b linear transforms
	local sx = bounds.width  / (bounds.h1 - bounds.h0)
	local cx = bounds.x - (bounds.h0 * sx)
	local sy = -bounds.height / (bounds.v1 - bounds.v0)
	local cy = bounds.y + bounds.height - (bounds.v0 * sy)
	local A_base = {1.0, sx, sy, sx, sy}
	local b_base = {0.0, cx, cy, 0.0, 0.0}
	local formats = {i = 1, x = 2, y = 3, dx = 4, dy = 5}
	local nformat = tableMap(format, formats)
	local A = tableMap(nformat, A_base)
	local b = tableMap(nformat, b_base)

	local stride = #format
	local ntuples = #vals / stride

	dest = dest or {}
	local idx = 0
	for j = 1, ntuples do
		for k = 1,stride do
			--log.info("src: " .. k .. " " .. idx+k .. " " .. vals[idx+k])
			dest[idx+k] = A[k]*vals[idx+k] + b[k]
			--log.info("dest: " .. dest[idx+k])
		end
		idx = idx + stride
	end

	return dest
end

-- creates the path of a line graph from preconverted coordinates
-- {x,y} tuples
function m.createGraphPath(nvg, bounds, vals, ntuples, extraopts)
	local fillY = 0
	if extraopts.fill then
		fillY = bounds.y + bounds.height
		nanovg.nvgMoveTo(nvg, vals[1], fillY)
		nanovg.nvgLineTo(nvg, vals[1], vals[2])
	else
		nanovg.nvgMoveTo(nvg, vals[1], vals[2])
	end
	local lastx = 0
	local idx = 3
	for i = 2,ntuples do
		lastx = vals[idx]
		nanovg.nvgLineTo(nvg, vals[idx], vals[idx+1])
		idx = idx + 2
	end
	if extraopts.fill then
		nanovg.nvgLineTo(nvg, lastx, fillY)
		nanovg.nvgLineTo(nvg, vals[1], fillY)
	end
end

-- creates paths for a candlestick-ish chart
-- vals are preconverted {x, y0, y1} tuples
function m.createCandlestickPath(nvg, bounds, vals, ntuples, extraopts)
	local idx = 1
	for i = 1,ntuples do
		local x = vals[idx]
		local low = vals[idx+1]
		local high = vals[idx+2]
		nanovg.nvgMoveTo(nvg, x, low)
		nanovg.nvgLineTo(nvg, x, high)
		--log.info("x: " .. x .. " " .. high .. " " .. low)
		idx = idx + 3
	end
end

-- creates paths for a scatterplot
-- vals is precomputed {x,y} tuples
function m.createXYPath(nvg, bounds, vals, ntuples, extraopts)
	local idx = 1
	local rad = extraopts.rad or 12
	for i = 1,ntuples do
		nanovg.nvgBeginPath(nvg)
		nanovg.nvgCircle(nvg, vals[idx], vals[idx+1], rad)
		nanovg.nvgFill(nvg)
		idx = idx + 2
	end
end

function m.drawTypicalGraph(nvg, bounds, style, vals, scratch, format, drawfunc)
	m.drawVTicMarks(nvg, bounds, style)
	m.drawHTicMarks(nvg, bounds, style)

	nanovg.nvgSave(nvg)

	local x0 = bounds.x + bounds.ticlength
	local y0 = bounds.y
	local width = bounds.width - bounds.ticlength
	local height = bounds.height - bounds.ticlength

	local innerbounds = {x = x0, y = y0, width = width, height = height,
						 h0 = bounds.h0, h1 = bounds.h1,
						 v0 = bounds.v0, v1 = bounds.v1}

	nanovg.nvgScissor(nvg, x0, y0, width, height)

	local stride = #format
	local ntuples = #vals / stride
	m.convertCoordinates(vals, innerbounds, format, scratch)
	drawfunc(nvg, innerbounds, style, scratch, ntuples)

	nanovg.nvgRestore(nvg)
end

function m.drawCandleCore(nvg, bounds, style, vals, ntuples)
	nanovg.nvgStrokeWidth(nvg, (style.linewidth or m.defaultLineWidth)*3)
	nanovg.nvgStrokeColor(nvg, style.strokeColor or m.defaultStrokeColor)

	nanovg.nvgBeginPath(nvg)
	m.createCandlestickPath(nvg, bounds, vals, ntuples, style)
	nanovg.nvgStroke(nvg)
end

function m.drawXYCore(nvg, bounds, style, vals, ntuples)
	nanovg.nvgFillColor(nvg, style.fillColor or m.defaultFillColor)
	m.createXYPath(nvg, bounds, vals, ntuples, style)
end


function m.drawLineGraphCore(nvg, bounds, style, vals, ntuples)
	nanovg.nvgStrokeWidth(nvg, (style.linewidth or m.defaultLineWidth)*2)
	nanovg.nvgStrokeColor(nvg, style.strokeColor or m.defaultStrokeColor)
	nanovg.nvgFillColor(nvg, style.fillColor or m.defaultFillColor)

	if style.filled then
		nanovg.nvgBeginPath(nvg)
		m.createGraphPath(nvg, bounds, vals, ntuples, {fill = true})
		nanovg.nvgFill(nvg)
	end

	nanovg.nvgBeginPath(nvg)
	m.createGraphPath(nvg, bounds, vals, ntuples, {fill = false})
	nanovg.nvgStroke(nvg)
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

function m.init(nvg, width, height)
	m.pts = {}
	for i = 1,16 do
		m.pts[i] = {0.5, 0.5}
	end
end

function m.drawLineGraph(nvg, bounds, style, pts, scratch)
	m.drawTypicalGraph(nvg, bounds, style, pts, scratch, 
						{"x", "y"}, m.drawLineGraphCore)
end

function m.drawCandleGraph(nvg, bounds, style, pts, scratch)
	m.drawTypicalGraph(nvg, bounds, style, pts, scratch, 
						{"x", "y", "y"}, m.drawCandleCore)
end

function m.drawXYGraph(nvg, bounds, style, pts, scratch)
	m.drawTypicalGraph(nvg, bounds, style, pts, scratch, 
						{"x", "y"}, m.drawXYCore)
end

m.t = 0.0
m.dumped = false

function m.makeTestBounds(x, y, w, h)
	local bounds = {x = x, y = y, width = w, height = h,
					h0 = m.t + 0, h1 = m.t + 20.0, hticspacing = 1.0, ticmultiple = 5,
					v0 = -10, v1 = 10.0, vticspacing = 2.0,
					ticlength = 14}
	return bounds
end

function m.testUpdatePts(pts, doubleAdd)


	local nval = pts[#pts] + (math.random()-0.5)*0.1
	nval = math.min(1.0, math.max(0.0, nval))

	local xval = m.t + 20.0
	table.insert(pts, xval)

	if doubleAdd then
		local nval2 = pts[#pts-2] + (math.random()-0.5)*0.1
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
					v0 = 0, v1 = 21.0, vticspacing = 0.2,
					ticlength = 14}
	self.pts_ = {}
	self.maxPts_ = 300
	self.isLineGraph = true
	self.isXYGraph = false
	self.scratch_ = {}
	self.lastx_ = 0
	self.title_ = options.title_ or "Graph"
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

function Graph:pushValue(newvals)
	self.lastx_ = newvals[1]
	for i = 1,#newvals do
		table.insert(self.pts_, newvals[i])
	end
	while #(self.pts_) > self.maxPts_ do
		table.remove(self.pts_, 1)
	end
end

function Graph:draw(nvg)
	if #self.pts_ == 0 then return end
	if self.isLineGraph then
		m.drawLineGraph(nvg, self.bounds_, self.style_, self.pts_, self.scratch_)
	elseif self.isXYGraph then
		m.drawXYGraph(nvg, self.bounds_, self.style_, self.pts_, self.scratch_)
	else
		m.drawCandleGraph(nvg, self.bounds_, self.style_, self.pts_, self.scratch_)
	end

	nanovg.nvgSave(nvg)

	nanovg.nvgFillColor(nvg, m.defaultStrokeColor)
	nanovg.nvgFontFace(nvg, "sans")
	nanovg.nvgFontSize(nvg, 20)

	nanovg.nvgText(nvg, self.bounds_.x + self.bounds_.ticlength*2, 
					self.bounds_.y + 15, self.title_, nil)

	nanovg.nvgRestore(nvg)
end

m.Graph = Graph
return m
