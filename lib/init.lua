print "Delay 5 seconds to start, Enter to stop ..."

stop_received = false
uart.on("data", '\r', function(data)
  uart.on("data") -- unregister callback function
  stop_received = true
end, 0)

tmr.create():alarm(5000, tmr.ALARM_SINGLE,
	function()
		uart.on("data") -- unregister callback function
		if not stop_received then
			if file.exists("my_app.lc") then
				dofile("my_app.lc")
			elseif file.exists("my_app.lua") then
				dofile("my_app.lua")
			end
		else
			print "quit to console"
		end
	end)
