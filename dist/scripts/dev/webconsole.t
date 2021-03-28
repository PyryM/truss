local class = require("class")
local websocket = require("io/websocket.t")

local m = {}

function m.start(options)
    if m.socket and m.socket.open then return true end

    options = options or {}
    m.createEnvironment()

    if options.redirectLog ~= false then
        m.installLogRedirects()
    end

    local host = options.host or "ws://localhost:8087"
    if host ~= "" then
        return m.connect(host)
    else
        return false
    end
end

function m.update()
    if m.socket then m.socket:update() end
end

function m.connect(host)
    m.socket = websocket.WebSocketConnection()
    -- ask socket to call our callback with decoded objects not strings
    m.socket:onJSON(m.onMessage)
    m.socket:connect(host)
    m.print("------ truss connected ------")
    return m.socket.open
end

function m.installLogRedirects()
    for logname, logfunc in pairs(log) do
        local topic = logname
        local nf = function(msg)
            m.log(msg, topic)
            logfunc(msg) -- call old log function
        end
        log[logname] = nf
    end
end

function m.createEnvironment()
    m.env = {}
    m.env.mainObj = truss.mainObj
    m.env.mainEnv = truss.mainEnv
    m.env.m = truss.mainEnv
    m.env.app = (truss.mainEnv or {}).app
    m.env.loadedLibs = truss.loadedLibs
    m.env.G = _G
    m.env.CG = m.env

    -- copy over the 'clean' subenvironment
    for k,v in pairs(truss.clean_subenv) do
        m.env[k] = v
    end

    -- make print be our remote print
    m.env.raw_print = print
    m.env.print = m.print

    m.ct = require("dev/consoletools.t").ConsoleTools{print = m.print,
                                                           width = m.width}

    m.env.info = m.ct:wrap("info")
end

function m.log(msg, topic)
    if not m.socket then return end
    local mdata = {
        source = "host",
        mtype = "log",
        topic = topic,
        message = msg
    }
    m.socket:sendJSON(mdata)
end

function m.print(msg)
    if not m.socket then return end
    local mdata = {
        source = "host",
        mtype = "print",
        message = tostring(msg)
    }
    m.socket:sendJSON(mdata)
end

function m.eval(code)
    local codefunc, loaderror = terralib.loadstring(code)
    if codefunc then
        setfenv(codefunc, m.env)
        local succeeded, ret = pcall(codefunc)
        if succeeded then
            if ret then m.print(tostring(ret)) end
        else
            m.print("Error: " .. tostring(ret))
        end
    else
        m.print("Parse error: " .. loaderror)
    end
end

function m.onMessage(msg)
    if msg.mtype == "eval" then
        m.eval(msg.code)
    end
end

return m
