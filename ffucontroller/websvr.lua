local M, mod = {}, ...
_G[mod] = M

function M.run(c)
	c:on("receive", function(ck, b)
		print(b)
		local rtn = ''
		local cc=200
		if b:find("GET / HTTP", 1, true) == 1 then
			rtn = '{\n\t"FanSpeed":'..SPD..',\n\t"Inlet":'..InT..
				',\n\t"UpTime":"'..D.UpT..'"\n}'
		elseif b:find("GET /fan HTTP", 1, true) == 1 then
			rtn = rtn..SPD
		elseif b:find("GET /inlet HTTP", 1, true) == 1 then
			rtn = rtn..InT
		elseif b:find("POST /fan?SPD=", 1, true) == 1 then
			D.SC2='\206'
			if not MAN then 
				local i = b:find('HTTP', 15, true)
				if i then
					local spd = b:sub(15, i-1)
					if spd:match("%d") then
						D.SC2='\207'
						spd = tonumber(spd)
						if spd >= VIBL and spd <= VIBH then spd=VIBH+1 end -- avoid vibration
						DELTA = spd - SPD 
						TryUpdSPD()
					end
				else
					cc=400
				end
			else
				cc=403
			end
		else
			cc=404
		end
		ck:send(string.format("HTTP/1.1 %d OK\r\nConnection: close\r\nContent-Length: %d\r\n\r\n%s\r\n",
			cc, rtn:len(), rtn), function(ckk) ckk:close() rtn=nil end)
	end)
end
return M
