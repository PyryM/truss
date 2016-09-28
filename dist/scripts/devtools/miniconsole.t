-- devtools/miniconsole.t
--
-- a console that displays using the bgfx debug text

local m = {}
local stringutils = require("utils/stringutils.t")

m.defaultColor = 0x8f
m.errorColor = 0x83
m.editColor = 0x70
m.inverseEditColor = 0x07
m.commandColor = 0x87
m.headerSize = 3
m.headerColor = 0x6f
m.scrollChar = string.char(254)

local function bg_print(x, y, color, string)
    bgfx.bgfx_dbg_text_printf(x, y, color, "%s", string)
end

-- take over view 0
function m.hijackBGFX(windowW, windowH)
    m.fbBackBuffer = terralib.new(bgfx.bgfx_frame_buffer_handle_t)
    m.fbBackBuffer.idx = bgfx.BGFX_INVALID_HANDLE
    bgfx.bgfx_set_view_rect(0, 0, 0, windowW or 640, windowH or 480)
    bgfx.bgfx_set_view_clear(0, -- viewid 0
            bgfx_const.BGFX_CLEAR_COLOR + bgfx_const.BGFX_CLEAR_DEPTH,
            0x000000ff, -- clearcolor (black)
            1.0, -- cleardepth (in normalized space: 1.0 = max depth)
            0)
    bgfx.bgfx_set_view_frame_buffer(0, m.fbBackBuffer)
    bgfx.bgfx_set_debug(bgfx_const.BGFX_DEBUG_TEXT)
end

function m.keyDown_(keyname, modifiers)
    local keybinds = {
        Backspace = m.backspace_,
        Return = m.execute_,
        Left = m.left_,
        Right = m.right_,
        Up = m.up_,
        Down = m.down_,
        PageUp = m.pageUp_,
        PageDown = m.pageDown_
    }
    if keybinds[keyname] then keybinds[keyname]() end
end

function m.up_()
    if m.historyPos <= 0 then
        m.historyPos = #(m.editHistory)
    else
        m.historyPos = math.max(1, m.historyPos - 1)
    end

    m.editLine = m.editHistory[m.historyPos] or ""
    m.cursorPos = #(m.editLine)
end

function m.down_()
    m.historyPos = m.historyPos + 1
    if m.historyPos <= 0 or m.historyPos > #(m.editHistory) then
        m.historyPos = -1
        m.editLine = ""
    else
        m.editLine = m.editHistory[m.historyPos] or ""
    end
    m.cursorPos = #(m.editLine)
end

function m.pageUp_()
    m.bufferPos = math.max(0, m.bufferPos - 10)
end

function m.pageDown_()
    m.bufferPos = math.min(#(m.lineBuffer), m.bufferPos + 10)
end

function m.textInput_(tstr)
    if m.cursorPos >= #(m.editLine) then
        m.editLine = m.editLine .. tstr
        m.cursorPos = #m.editLine
    else
        local prev = m.editLine:sub(1,m.cursorPos)
        local rem = m.editLine:sub(m.cursorPos+1, -1)
        m.editLine = prev .. tstr .. rem
        m.cursorPos = m.cursorPos + 1
    end
end

function m.backspace_()
    if m.editLine:len() <= 0 or m.cursorPos <= 0 then return end

    if m.cursorPos >= #(m.editLine) then
        m.editLine = string.sub(m.editLine, 1, -2)
        m.cursorPos = #m.editLine
    else
        local prev = m.editLine:sub(1,m.cursorPos-1)
        local rem = m.editLine:sub(m.cursorPos+1, -1)
        m.editLine = prev .. rem
        m.cursorPos = m.cursorPos - 1
    end
end

function m.left_()
    m.cursorPos = math.max(0, m.cursorPos - 1)
end

function m.right_()
    m.cursorPos = math.min(m.cursorPos + 1, #m.editLine)
end

m.downkeys = {}

function m.handleInputs()
    local sdl = truss.addons.sdl
    for evt in sdl:events() do
        local etype = evt.event_type
        if etype == sdl.EVENT_WINDOW and evt.flags == 14 then
            truss.quit()
        elseif etype == sdl.EVENT_KEYDOWN or etype == sdl.EVENT_KEYUP then
            local keyname = ffi.string(evt.keycode)
            if etype == sdl.EVENT_KEYDOWN then
                if not m.downkeys[keyname] then
                    m.downkeys[keyname] = true
                    m.keyDown_(keyname, evt.flags)
                end
            else -- keyup
                m.downkeys[keyname] = false
            end
        elseif etype == sdl.EVENT_TEXTINPUT then
            local input = ffi.string(evt.keycode)
            m.textInput_(input)
        end
    end
end

function m.printColors()
    for i = 0,15 do
        m.print(tostring(i), i*16)
    end
end

function m.drawPositionBar_()
    local fp = m.bufferPos / (#(m.lineBuffer) - m.height)
    local p = math.min(m.height - 1, math.ceil(m.height * fp))
    local nheader = #(m.headerLines)
    local bar = string.char(179)
    for i = 0,(m.height-1) do
        local c = bar
        if i == p then c = m.scrollChar end
        bg_print(m.width-1, i + nheader + 1, m.inverseEditColor, c)
    end
end

function m.debugPrintLines()
    bgfx.bgfx_dbg_text_clear(0, false)
    local headersize = #(m.headerLines) + 1
    for idx, headerline in ipairs(m.headerLines) do
        bg_print(0, idx-1, m.headerColor, headerline or "?")
    end
    for i = 0,m.height-1 do
        local lineinfo = m.lineBuffer[m.bufferPos + i] or {}
        local text, color = lineinfo[1] or "", lineinfo[2] or m.defaultColor
        local ppos = text:len()
        local padding = m.paddings[m.width - ppos] or ""
        bg_print(0, i+headersize, color, text)
        bg_print(ppos, i+headersize, color, padding)
    end
    local fp = m.editLine:sub(1, m.cursorPos)
    local cp = m.editLine:sub(m.cursorPos+1, m.cursorPos+1)
    if not cp or cp == "" then cp = " " end
    local rp = m.editLine:sub(m.cursorPos+2,-1)
    local editpadding = m.paddings[m.width - (fp:len()+cp:len()+rp:len()+2)] or ""
    bg_print(0, m.height+headersize, m.editColor, ">" ..
        fp .. editpadding)
    bg_print(#(fp)+1, m.height+headersize, m.inverseEditColor, cp)
    bg_print(#(fp)+2, m.height+headersize, m.editColor, rp .. editpadding)
    m.drawPositionBar_()
end

function m.update()
    m.handleInputs()
    m.debugPrintLines()
    if m.webconsole then m.webconsole.update() end
    bgfx.bgfx_touch(0)
    bgfx.bgfx_frame(false)
end

function m.attachWebconsole()
    if m.webconsole then return true end
    local webconsole = require("devtools/webconsole.t")
    if webconsole then
        local connected = webconsole.start()
        if connected then
            m.webconsole = webconsole
            m.divider()
            m.print("Webconsole connected")
            m.divider()
        else
            m.print("Webconsole: connection error", m.errorColor)
        end
    else
        m.print("Webconsole: devtools/webconsole.t not present", m.errorColor)
    end
end

function m.wrapOverlong_(s, ret)
    local remainder = s
    local lw = m.width - 1
    while remainder:len() > lw do
        local front = remainder:sub(1,lw)
        remainder = remainder:sub(lw+1,-1)
        table.insert(ret, front)
    end
    table.insert(ret, remainder)
end

function m.wrapLines(s)
    local ret = {}
    local lines = stringutils.splitLines(s)
    for _, line in ipairs(lines) do
        m.wrapOverlong_(line, ret)
    end
    return ret
end

function m.setHeader(line)
    m.headerLines = m.wrapLines(line)
    m.height = m.totalHeight - 2 - #(m.headerLines)
end

function m.print(line, color)
    local splitlines = m.wrapLines(tostring(line))
    for _, line in ipairs(splitlines) do
        table.insert(m.lineBuffer, {line, color or m.defaultColor})
    end
    if #m.lineBuffer >= m.height-1 then
        m.bufferPos = m.bufferPos + #(splitlines)
    end
end

function m.eval(code)
    local codefunc, loaderror = terralib.loadstring(code)
    if codefunc then
        setfenv(codefunc, m.env)
        local succeeded, ret = pcall(codefunc)
        if succeeded then
            if ret then m.print(tostring(ret)) end
        else
            m.print("Error: " .. tostring(ret), m.errorColor)
        end
    else
        m.print("Parse error: " .. loaderror, m.errorColor)
    end
end

function m.divider()
    m.print(string.rep("-", m.width-1))
end

function m.printMiniHelp()
    m.print("Miniconsole")
    m.divider()
    m.print("help() for help [this message]")
    m.print("info(thing) to pretty-print info")
    m.print("print(str, color) to print to this console")
    m.print("colors() for pretty colors")
    m.print("truss.quit() or quit() to quit [or just close the window]")
    m.print("remote() or rc() to connect to remote console")
    m.print("resume() to resume [warning! very wonky!]")
    m.print("log() to show the log")
    m.print("pageup / pagedown to see history")
    m.print("clear() to clear")
    m.print("div() or divider() to create a divider")
    m.print("trace() to get traceback at error")
    m.print("save([filename]) to save this console buffer to a text file")
    m.divider()
end

function m.info(val, maxrecurse, indent, nprinted)
    indent = indent or 0
    maxrecurse = maxrecurse or 2
    nprinted = nprinted or 0
    local padding = m.paddings[indent*2]
    if not padding then
        return 1000
    end
    if type(val) == "table" then
        for k,v in pairs(val) do
            if type(v) == "table" then
                m.print(padding .. k .. ": [table]")
                if maxrecurse > 0 then
                    nprinted = nprinted + m.info(v, maxrecurse-1, indent+1, nprinted)
                end
            else
                nprinted = nprinted + 1
                m.print(padding .. k .. ": " .. tostring(v))
            end
            if nprinted > 60 then
                m.print("[too many printed]")
                return 1000
            end
        end
        return nprinted
    else
        m.print(padding .. tostring(val))
        return nprinted+1
    end
end

function m.printChars()
    for i = 0,255 do m.print(i .. " = " .. string.char(i)) end
end

function m.createEnvironment()
    m.env = {}
    m.env.mainObj = truss.mainObj
    m.env.mainEnv = truss.mainEnv
    m.env.loadedLibs = truss.loadedLibs
    m.env.G = _G

    -- copy over the 'clean' subenvironment
    for k,v in pairs(truss.clean_subenv) do
        m.env[k] = v
    end

    -- make print be our remote print
    m.env.raw_print = print
    m.env.print = m.print
    m.env.info = m.info
    m.env.colors = m.printColors
    m.env.chars = m.printChars
    m.env.help = m.printMiniHelp
    m.env.rc = m.attachWebconsole
    m.env.remote = m.attachWebconsole
    m.env.resume = truss.resumeFromError
    m.env.quit = truss.quit
    m.env.printlog = m.dumpLog
    m.env.log = m.dumpLog
    m.env.clear = m.clear
    m.env.div = m.divider
    m.env.divider = m.divider
    m.env.trace = m.trace
    m.env.save = m.saveConsoleLines
    m.env.m = truss.mainEnv
    m.env.app = (truss.mainEnv or {}).app
    m.env.minicon = m
end

function m.trace()
    m.print(truss.errorTrace)
end

function m.clear()
    m.bufferPos = 0
    m.lineBuffer = {}
end

m.logColors = {
    ["[0]"] = 0x90,
    ["[1]"] = 0x89,
    ["[2]"] = 0x83,
    ["[3]"] = 0x8c,
    ["[4]"] = 0x8a
}
function m.dumpLog()
    local loglines = truss.loadStringFromFile("trusslog.txt")
    if not loglines then
        m.print("Couldn't load trusslog.txt", m.errorColor)
        return
    end
    local lines = stringutils.splitLines(loglines)
    for _, line in ipairs(lines) do
        local prefix = line:sub(1,3)
        m.print(line, m.logColors[prefix])
    end
end

function m.saveConsoleLines(filename)
    filename = filename or "console_log.txt"
    truss.C.set_fs_savedir("/")
    local lines = {}
    for i,line in ipairs(m.lineBuffer) do
        lines[i] = line[1]
    end
    local str = table.concat(lines, "\n")
    truss.C.save_data(filename, str, str:len())
end

function m.execute_()
    m.print("=>" .. m.editLine, m.commandColor)
    m.bufferPos = math.max(0, #m.lineBuffer - m.height + 1)
    if m.execCallback then
        m.execCallback(m.editLine)
    else
        m.eval(m.editLine)
    end
    if m.editLine ~= m.editHistory[#(m.editHistory)] then
        table.insert(m.editHistory, m.editLine)
    end
    m.historyPos = -1
    m.editLine = ""
    m.cursorPos = 0
end

function m.init(width, height)
    m.headerLines = {}
    m.width = width or 80
    m.totalHeight = height or 30
    m.height = m.totalHeight - 2 - #(m.headerLines)
    m.bufferPos = 0
    m.lineBuffer = {}
    m.historyPos = -1
    m.editHistory = {}
    m.editLine = ""
    m.paddings = {}
    m.cursorPos = 0
    local padding = ""
    for i = 0,m.width do
        m.paddings[i] = padding
        padding = padding .. " "
    end
    m.createEnvironment()
    truss.addons.sdl:startTextinput()
end

return m
