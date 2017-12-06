local M, mod = {}, ...
_G[mod] = M

function M.server(c, cb)
	c:on("receive", function(ck, b)
		print(b)
		local rtn = ''
		local cc=200
		if b:find("GET / HTTP", 1, true) == 1 then
			b=nil
			rtn ='<html><title>PM2.5 Sensor</title></head><body>'
			rtn = rtn..'<h1>PM2.5 :' .. 20 ..'</h1>' ..
				'<h2>PM1.0 :' .. 30 .. '<br/>PM10 :' .. 40 .. '</h2>' ..
				'<h2>Temperature: ' .. "23.5C" .. '<br/>Humidity: ' .. "35%" .. '</h2>' ..
				'<h2>'.. rtctime.get() ..'</h2>'
			rtn=rtn..'Up Time: ' .. tmr.time() .. "<br/>Heap: " .. node.heap()..'</body></html>'
		else
			b=nil
			cc=404
		end
		print(cc)
		print(rtn)
		ck:send(string.format("HTTP/1.1 %d OK\r\nConnection: close\r\nContent-Length: %d\r\n\r\n", cc, rtn:len()))
		ck:send(rtn .. "\r\n", function(ckk) ckk:close() rtn=nil end)
		if cb then cb() end
	end)
end
return M
