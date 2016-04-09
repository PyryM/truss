-- A tiny test

function init()
	libs.trss.trss_log(libs.TRSS_ID, "init called.")
end

function update()
	libs.trss.trss_log(libs.TRSS_ID, "updated called; now shutting down.")
	libs.trss.trss_stop_interpreter(libs.TRSS_ID)
end