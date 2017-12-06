local M, mod = {}, ...
_G[mod] = M

function M.get(c, cb)
	http.get("http://api.waqi.info/feed/"..c.."/?token=ADD_YOUR_TOKEN_HERE", nil, function(code, rtn) 
		if code == 200 then
			pcall(function()
					local res = sjson.decode(rtn)
					rtn=nil
					if res.status == "ok" then
						if cb then
							cb(res.data.aqi, res.data.time.s)
						else
							print(res.data.aqi)
							print(res.data.time.s)
						end
					end
					res=nil
			end)
		end
	end)
	package.loaded[mod]=nil
	_G[mod]=nil
end
return M
