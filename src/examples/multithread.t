function init()
  other = truss.C.spawn_interpreter(0, "scripts/examples/multithread.t")
  print("Other: " .. other)
end

function update()
  print("Other state: " .. truss.C.get_interpreter_state(other))
  truss.C.step_interpreter(other)
  print("Other state: " .. truss.C.get_interpreter_state(other))
  truss.sleep(1000)
  print("Other state: " .. truss.C.get_interpreter_state(other))
  truss.quit()
end

function worker_init()
  print("Worker init")
end

function worker_update()
  print("Worker update start")
  truss.sleep(100)
  print("Worker update end")
end

if truss.interpreter_id > 0 then
  init = worker_init
  update = worker_update
end