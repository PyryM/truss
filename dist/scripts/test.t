-- A tiny test

function init()
	libs.truss.truss_log(libs.TRUSS_ID, "init called.")
end

function update()
	libs.truss.truss_log(libs.TRUSS_ID, "updated called; now shutting down.")
	libs.truss.truss_stop_interpreter(libs.TRUSS_ID)
end