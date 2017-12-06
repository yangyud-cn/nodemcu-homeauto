local M, mod = {}, ...
_G[mod] = M
M.done = false

local function mprint(D, msg)
	if D then
		D.g:firstPage()
		repeat
			D.set6x13()
			for i=1, #msg do
				D.g:drawStr(0, 2 + 16*i, msg[i])
			end
		until D.g:nextPage() == false
	end
	for i=1, #msg do
		print(msg[i])
	end
end

function M.Setup(D)
	local cfg = wifi.sta.getconfig(true)
	if not cfg.ssid or #cfg.ssid == 0 then
		mprint(D, {"Setup AP ..."})
		local ap = {}
		ap.ssid = "MCU" .. node.chipid() 
		ap.pwd = "P$" .. (node.random(100000, 999999))
		ap.auth = wifi.WPA2_PSK
		ap.save = false
		wifi.setmode(wifi.STATIONAP, false)
		wifi.ap.config(ap)
		mprint(D, {"SSID: " .. ap.ssid, "PWD: " .. ap.pwd})
		
		enduser_setup.manual(true)
		enduser_setup.start(
		  function()
			mprint(D, {"Conn: " .. wifi.sta.getip()})
			enduser_setup.stop()
			wifi.setmode(wifi.STATION, true)
			node.restart()
		  end,
		  function(err, str)
			mprint(D, {"Err #" .. err .. ": " .. str})
			enduser_setup.stop()
		  end
		)
		return false
	else
		package.loaded[mod]=nil
		_G[mod]=nil
		return true
	end
end

function M.Reset(D)
	mprint(D, {"Reset configuration"})
	wifi.setmode(wifi.STATION, false)
	wifi.sta.clearconfig()
	tmr.create():alarm(2000, tmr.ALARM_SEMI, function() node.restart() end)
end
return M
