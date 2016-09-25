-- futureplot.t
--
-- Futuristic plotting gui thing for truss

local class = require("class")
local m = {}

-- some default colors
m.defaultStrokeColor = nanovg.nvgRGBA(235,235,255,255) -- cyan-ish
m.defaultFillColor   = nanovg.nvgRGBA(235,235,255,60) -- cyan-ish
m.defaultLineWidth   = 1
m.fontsize           = 12

local FuturePlot = class("FuturePlot")

function FuturePlot:init(options, width, height)
    -- todo
    self.gridrows_ = options.gridrows or 20
    self.gridcols_ = options.gridcols or 20
    self.width_ = width
    self.height_ = height
    self.cellwidth_ = self.width_ / self.gridcols_
    self.cellheight_ = self.height_ / self.gridrows_
    self.cellmargin_ = options.cellmargin or 10
    self.grid_ = {}
    self.components_ = {}
end

function FuturePlot:getInnerBounds(row, col, rowheight, colwidth)
    local ret = {}
    ret.x = self.cellwidth_ * (col-1) + self.cellmargin_
    ret.y = self.cellheight_ * (row-1) + self.cellmargin_
    ret.width = (colwidth * self.cellwidth_) - (self.cellmargin_ * 2)
    ret.height = (rowheight * self.cellheight_) - (self.cellmargin_ * 2)
    return ret
end

function FuturePlot:add(component, name, row, col, rowheight, colwidth)
    self.components_[name] = {component = component,
                              row = row, col = col,
                              rowheight = rowheight,
                              colwidth = colwidth}
    if component.setBounds then
        component:setBounds(self:getInnerBounds(row, col, rowheight, colwidth))
    end
end

local function drawCross(nvg, x, y)
    nanovg.nvgBeginPath(nvg)

    nanovg.nvgMoveTo(nvg, x-5, y)
    nanovg.nvgLineTo(nvg, x+5, y)
    nanovg.nvgMoveTo(nvg, x, y-5)
    nanovg.nvgLineTo(nvg, x, y+5)

    nanovg.nvgStroke(nvg)
end

function FuturePlot:drawBorder(component, nvg)
    local x = (component.col - 1) * self.cellwidth_
    local y = (component.row - 1) * self.cellheight_
    local w = component.colwidth * self.cellwidth_
    local h = component.rowheight * self.cellheight_

    nanovg.nvgSave(nvg)

    nanovg.nvgStrokeWidth(nvg, 1)
    nanovg.nvgStrokeColor(nvg, nanovg.nvgRGBA(255,255,255,100))

    -- nanovg.nvgBeginPath(nvg)
    -- nanovg.nvgRect(nvg, x, y, w, h)
    -- nanovg.nvgStroke(nvg)

    nanovg.nvgStrokeWidth(nvg, 2)
    drawCross(nvg, x,   y)
    drawCross(nvg, x+w, y)
    drawCross(nvg, x, y+h)
    drawCross(nvg, x+w, y+h)

    nanovg.nvgRestore(nvg)
end

function FuturePlot:draw(altnvg)
    local nvg = altnvg or self.nvg_
    for compname, component in pairs(self.components_) do
        self:drawBorder(component, nvg)
        if component.component.draw then
            component.component:draw(nvg)
        end
    end
end

function m.init(nvg, w, h)
    local plots = require("gui/plotting.t")

    m.fp = FuturePlot({gridrows = 4,
                       gridcols = 6}, w, h)

    m.p1 = plots.CandleGraph({title = "Plot 1: Candle", filled = true})
    m.p2 = plots.CandleGraph({title = "Plot 2: Candle", filled = true})
    m.p3 = plots.LineGraph({title = "Plot 3: Line (filled)", filled = true})
    --m.p3.isLineGraph = false
    -- m.p4 = plots.Graph({})
    -- m.p4.isLineGraph = false
    -- m.p4.maxPts_ = 200
    -- m.p5 = plots.Graph({})
    -- m.p5.isLineGraph = false
    -- m.p5.isXYGraph = true
    -- m.p5.maxPts_ = 200
    m.texty = plots.TextBox({title = "truss/ FUTUREPLOT", fontsize = 80, align = "center"})
    m.fp:add(m.texty, "texty", 1, 1, 1, 4)

    m.loggy = m.TextLog({fontsize = 18})
    m.fp:add(m.loggy, "loggy", 1, 5, 4, 2)

    --m.fp:add(m.p4, "header",  1, 1, 1, 3)
    m.fp:add(m.p1, "p1",      2, 1, 1, 2)
    m.fp:add(m.p2, "p2",      3, 1, 1, 2)
    m.fp:add(m.p3, "p3",      4, 1, 1, 2)
    --m.fp:add(m.p5, "console", 2, 3, 3, 2)

    m.t = 0.0
    m.f = 0
    m.prevval = 0.0
end

function m.draw(nvg, w, h)
    m.t = m.t + 1.0 / 60.0

    m.p1:setLimits(m.t+3, m.t+10.0, -2.0, 2.0)
    m.p2:setLimits(m.t+2, m.t+10.0, -2.0, 2.0)
    m.p3:setLimits(m.t+1, m.t+10.0, -2.0, 2.0)

    m.f = m.f + 1
    if m.f % 5 == 0 then
        m.p1:pushValue({m.t + 10.0, 0.0, math.sin(m.t) + math.cos(m.t*5)})
        m.p2:pushValue({m.t + 10.0, math.sin(m.t*2), math.cos(m.t*3)})

        local newval = m.prevval + (math.random()-0.5) * 0.5
        newval = math.max(-2.0, math.min(2.0, newval))

        m.p3:pushValue({m.t + 10.0, newval})
        m.prevval = newval

        if m.f % 30 == 0 then
            local text = "Text line at frame #" .. m.f
            m.loggy:addText(text)
            if math.random() < 0.1 then
                m.loggy:addColoredText("Oh no! This is a fake error.",
                                       {255,0,0,255})
            end
        end

        -- local v = (math.sin(m.t) * math.cos(m.t*15))*0.5 + 0.5
        -- local v2 = (math.sin(m.t*3) + math.cos(m.t*7))*0.25 + 0.5

        -- m.p4:pushValue(v - math.random()*0.1)
        -- m.p4:pushValue(v + math.random()*0.1)

        -- m.p5:pushValue(v + (math.random() - 0.5)*0.1)
        -- m.p5:pushValue(v2 + (math.random() - 0.5)*0.1)
    end
    m.fp:draw(nvg)
end

-- text stuff
local textdrawing = require("gui/textdrawing.t")

local TextLog = class("TextLog")
function TextLog:init(options)
    self.text = {}
    self.bounds_ = {x = 0, y = 0, width = 100, height = 100}
    self.innerbounds_ = {x = 0, y = 0, width = 100, height = 100}
    self.margin = options.margin or 10
    self.style = {}
    self.style.fontsize = options.fontsize or 12
    self.style.fontface = options.fontface or "sans"
    self.style.lineheight = options.lineheight or (self.style.fontsize + 4)
    self.maxlines = 10
    self.textcolor = options.textcolor or {255,255,255,255}
end

function TextLog:addChunkedLine(linechunks)
    table.insert(self.text, linechunks)
    while #(self.text) > self.maxlines do
        table.remove(self.text, 1)
    end
end

function TextLog:addText(text)
    self:addChunkedLine(textdrawing.printColored(text, self.textcolor))
end

function TextLog:addColoredText(text, color)
    self:addChunkedLine(textdrawing.printColored(text, color))
end

function TextLog:setBounds(bounds)
    self.bounds_.x = bounds.x
    self.bounds_.y = bounds.y
    self.bounds_.width = bounds.width
    self.bounds_.height = bounds.height
    self.innerbounds_.x = bounds.x + self.margin
    self.innerbounds_.y = bounds.y + self.margin
    self.innerbounds_.width = bounds.width - (self.margin * 2)
    self.innerbounds_.height = bounds.height - (self.margin * 2)

    self.maxlines = math.floor(self.innerbounds_.height / self.style.lineheight)
    log.debug("TextLog max lines: " .. self.maxlines)
    return self
end

function TextLog:draw(nvg)
    textdrawing.drawFormattedText(nvg, self.text,
                                  self.innerbounds_, self.style)
end

m.FuturePlot = FuturePlot
m.TextLog = TextLog
return m
