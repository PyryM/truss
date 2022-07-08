if _MAIN_MODULE then
  truss.main = require(_MAIN_MODULE)
end

function _core_init()
  truss.main.init()
end

function _core_update()
  truss.main.update()
end
