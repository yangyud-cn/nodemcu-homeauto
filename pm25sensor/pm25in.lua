local M, mod = {}, ...
_G[mod] = M

function M.get(c, cb)
	http.get("http://www.pm25.in/api/querys/aqis_by_station.json?station_code="..c.."&token=ADD_YOUR_TOKEN_HERE", nil, function(code, rtn) 
		if code == 200 then
			local res = sjson.decode(rtn)[1]
			rtn=nil
			if cb then
				cb(res.aqi, res.time_point)
			else
				print(res.aqi, res.time_point)
			end
			res=nil
		end
	end)
	package.loaded[mod]=nil
	_G[mod]=nil
end
return M
