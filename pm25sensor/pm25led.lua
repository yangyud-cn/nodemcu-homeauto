local M, module = {}, ...
_G[module] = M

function M.run(cnt, led, y)
	-- package.loaded[module]=nil
	local r,g,b = 0,0,0,0
	if cnt <= 150 then
		r=math.floor(255 * cnt / 150)
		g=math.floor(255 * (150 - cnt) / 150)
	elseif cnt <= 300 then
		r=math.floor(255 * (300 - cnt) / 150)
		b=math.floor(255 * (cnt -150) / 150)
	else
		r=cnt - 300
		b=cnt - 300 + 255
	end
	led.color(r*y, g*y, b*y)
end
return M