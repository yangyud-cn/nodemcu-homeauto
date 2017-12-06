local modname = ...
local M = {}
_G[modname] = M

local D=
{
	Msg = nil,
	SC = nil,
	startWait = function() end,
	endWait = function() end
}

function M.init(name, disp)
	if disp then D = disp end
	wifi.setmode(wifi.STATION, false)
	local cfg = wifi.sta.getdefaultconfig(true)
	cfg.save = false
	cfg.auto = true
	wifi.sta.config(cfg)
	cfg=nil
	wifi.sta.sethostname(name);

	tmr.create():alarm(600000, tmr.ALARM_AUTO, function()
		if not wifi.sta.getip() then
			D.Msg="Reconn"
			wifi.sta.connect(function() D.Msg="Connected" end)
		end
	end)
end

function M.startService(netserver)
	D.startWait()
	tmr.create():alarm(1000, tmr.ALARM_SEMI, function(t)
		if not wifi.sta.getip() then
			t:start()  -- restart the timer to wait
			D.Msg="Wait IP"
		else
			D.Msg="Get NTP"
			sntp.sync({
				 "203.135.184.123",  -- 0.cn.pool.ntp.org
				 "173.255.246.13",   -- 1.cn.pool.ntp.org
				 "212.47.249.141",   -- 2.cn.pool.ntp.org
				 "193.228.143.23"	-- 3.cn.pool.ntp.org
				 },
				 function()  -- unregister the timer upon success
					D.endWait()
					t:unregister()
					D.Msg="NTP OK"
				 end,
				 function()
					t:start()  -- restart the timer to wait
					D.Msg="NTP Retry"
				 end,
				 1)  -- refresh ntp each 1000 seconds
			if netserver then pcall(netserver) end
	   end
   end)
end

return M
