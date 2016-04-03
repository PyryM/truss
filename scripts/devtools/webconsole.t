local class = require("class")
local websocket = require("io/websocket.t")

local m = {}

function m.start(options)
    options = options or {}
    m.createEnvironment()

    if options.redirectLog ~= false then
        m.installLogRedirects()
    end

    local host = options.host or "ws://localhost:8087"
    if host ~= "" then
        m.connect(host)
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
    m.env.main = subenv
    m.env.modules = loadedLibs
    m.env.G = _G

    -- copy over the 'clean' subenvironment
    for k,v in pairs(clean_subenv) do
        m.env[k] = v
    end

    -- make print be our remote print
    m.env.raw_print = print
    m.env.print = m.print
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
        message = msg
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