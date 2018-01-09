-- examples/zeromq.t
--
-- zeromq example

local zmq = require("io/zmq.t")

local npongs = 0
local function ping(datasize, data)
  print("message: ")
  print(ffi.string(data, datasize))
  npongs = npongs + 1
  return "pong_" .. npongs
end

function init()
  print("We didn't crash?")
  zmq.init()
  socket = zmq.ReplySocket("tcp://*:5555", ping)
end

local f = 0
local n = 30
function update()
  if socket:update() then 
    truss.sleep(10)
  else
    truss.sleep(200)
  end
  f = f + 1
  if f % 5 == 0 then
    print("Still alive! " .. n)
    n = n - 1
    if n <= 0 then truss.quit() end
  end
end