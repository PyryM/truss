local class = require("class")
local zmq = require("io/zmq.t")
local msgpack = require("lib/messagepack.lua")
local m = {}

local Remote = class("Remote")
local Task = class("Task")

m.Remote = Remote
m.Task = Task

function Remote:init(options)
  self._sock = zmq.ReplySocket(options.url, 
                              function(...) 
                                return self:_handle_request(...) 
                              end)
  self._ops = {load = self._load, 
               call = self._call, 
               get = self._get, 
               stop = self._stop}

  self._tasks = {}
  self._next_id = 1
  self._env = options.env or truss.extend_table({}, truss.clean_subenv)
end

function Remote:update()
  for task_id, task in pairs(self._tasks) do
    task:update()
    if task.returned then self._tasks[task_id] = nil end
  end
  self._sock:update()
end

function Remote:_handle_request(datasize, data)
  local msg = msgpack.unpack(ffi.string(data, datasize))
  print("got message: " .. msg.op or "?")
  local reply = (self._ops[msg.op or ""] or self._error)(self, msg)
  if reply == nil then print("nil reply???") end
  local packed = msgpack.pack(reply)
  if packed == nil then print("nil packed???") end
  print(packed)
  return packed
end

function Remote:_error(msg)
  return {rep = "error"}
end

function Remote:_load(msg)
  local f, err = truss.load_named_string(msg.source, "Remote:_load")
  if not f then
    return {rep = "error", msg = err}
  end
  setfenv(f, self._env)
  local ok, err = pcall(f)
  if ok then 
    return {rep = "ok"}
  else
    return {rep = "error", msg = err}
  end
end

function Remote:_call(msg)
  local f = self._env[msg.funcname]
  local t = Task(f, msg.funcargs)
  local new_task_id = self._next_id
  self._next_id = self._next_id + 1
  self._tasks[new_task_id] = t
  t:update()
  return self:_get{task_id = new_task_id}
end

function Remote:_get(msg)
  local task = self._tasks[msg.task_id or -1]
  if not task then return {rep = "error", msg = "No such task."} end
  if task.complete then
    task.returned = true
    return {rep = "result", task_id = msg.task_id, value = task.value}
  elseif task.running then
    return {rep = "running", task_id = msg.task_id}
  else
    task.returned = true
    return {rep = "error", msg = task.error or "unknown error"}
  end
end

function Remote:_stop(msg)
  local task = self._tasks[msg.task_id or -1]
  if not task then return {rep = "error", msg = "No such task."} end
  self._tasks[msg.task_id] = nil
  return {rep = "stopped", task_id = msg.task_id}
end

function Task:init(func, args)
  self._co = coroutine.create(func)
  self.running = true
  self:_continue(args)
end

function Task:_continue(args)
  if not self._co then return end
  local happy, res = coroutine.resume(self._co, unpack(args or {}))
  self.running = coroutine.status(self._co) ~= "dead"
  if not happy then
    self._co = nil
    self.error = res
    log.error("zremote task error: " .. self.error)
  end
  if not self.running then
    self._co = nil
    self.complete = true
    self.value = res
  end
end

function Task:update()
  self:_continue()
end

-- init+update to allow this to be called as a main script
local remote = nil
local remote_env = nil

local function wait(n)
  for i = 1, (n or 1) do
    coroutine.yield()
  end
end

local function wait_condition(condition_func)
  while not condition_func() do
    coroutine.yield()
  end
end

function m.init()
  local url = truss.args[3]
  if not url then
    print("Remote: no host url specified")
    truss.quit()
    return
  end
  remote_env = {
    wait = wait,
    wait_condition = wait_condition 
  }
  zmq.init()
  remote = Remote{url = url, 
                  env = truss.extend_table(remote_env, truss.clean_subenv)}
end

function m.update()
  remote:update()
  if remote_env.update then
    -- assume the loaded update will do frame timing
    remote_env.update()
  else
    -- don't burn too much CPU
    truss.sleep(0.2)
  end
end

return m