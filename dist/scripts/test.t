-- A tiny test

function init()
	libs.trss.trss_log(libs.TRUSS_ID, "init called.")
end

function update()
	libs.trss.trss_log(libs.TRUSS_ID, "updated called; now shutting down.")
	libs.trss.trss_stop_interpreter(libs.TRUSS_ID)
end