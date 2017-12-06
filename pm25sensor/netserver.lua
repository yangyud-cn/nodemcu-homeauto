local M, mod = {}, ...
_G[mod] = M

function M.server(c, cb)
	c:on("receive", function(ck, b)
		local rtn = ''
		local cc=200
		if PMS.TM == 0 then
			cc=503
		else
			if b:find("GET / HTTP", 1, true) == 1 then
				b=nil
				rtn = rtn..'{\n\t"PM2_5":'.. PMS.PM2_5..
					',\n\t"PM1":'..PMS.PM1_0..',\n\t"PM10":'..PMS.PM10..
					',\n\t"Temperature":'..PMS.T..',\n\t"Humidity":'..PMS.H..
					',\n\t"UpTime":"'..D.UpT..'"\n}'
			else
				cc=404
			end
		end
		ck:send(string.format("HTTP/1.1 %d OK\r\nConnection: close\r\nContent-Length: %d\r\n\r\n%s\r\n", 
			cc, rtn:len(), rtn), function(ckk) ckk:close() rtn=nil end)
		if cb then cb() end
	end)
end
return M
