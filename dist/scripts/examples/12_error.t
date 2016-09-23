-- examples/12_error.t
--
-- has errors to demonstrate the error console

local AppScaffold = require("utils/appscaffold.t").AppScaffold

function init()
    app = AppScaffold({title = "examples/12_error.t",
                       width = 660,
                       height = 600,
                       usenvg = false})
end

function update()
    -- have an error
    error("I am error")
    app:update()
end
