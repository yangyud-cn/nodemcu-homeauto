local M, mod = {}, ...
_G[mod] = M
local lastC = 0
local fil={0,0,0,0,0}
local idx=1
local INLET
function M.run(c, interv, minspd)
	fil[idx] = c
	idx = idx < 5 and idx + 1 or 1
	local tm = rtctime.get()
	if not wifi.sta.getip() then
		D.SC2='\94'
		return
	elseif tm < lastC + interv then 
		return
	end
	lastC = tm
	D.SC2='\99'
	http.get("http://ffu/inlet", nil, function(code, inlet)
		if code == 200 then
			D.SC2='\83'
			INLET=tonumber(inlet)
			if INLET then
				node.task.post(function()
					local avg = 0
					for i = 1,5 do
						avg = avg + fil[i]
					end
					avg = math.ceil(avg/5)
					local uplimit= (INLET < 18 or INLET > 30) and 50 or 80
					local newspd= (avg > uplimit) and uplimit or (avg<minspd and minspd or avg)
					http.post("http://ffu/fan?SPD="..newspd, nil, function(code, rtn) end)
					D.SC2='\81'
				end)
			end
		end
	end)
end
return M
