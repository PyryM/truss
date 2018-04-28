-- examples/repl.t
--
-- just launches a basic text repl

local mc = require("devtools/miniconsole.t")

function init()
  app = mc.ConsoleApp{title = 'truss repl'}
end

function update()
  app:update()
end
