-- examples/12_error.t
--
-- has errors to demonstrate the error console

local AppScaffold = require("utils/appscaffold.t").AppScaffold

function init()
    app = AppScaffold({title = "examples/12_error.t",
                       width = 660,
                       height = 600,
                       usenvg = false})
    woo()
end

function ohno()
    error("I am error")
end

function yay()
    ohno()
end

function woo()
    yay()
end

function update()
    -- have an error
    woo()
    app:update()
end
