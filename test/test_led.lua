
led = require("led")
led.init(7,6,5, true)

function pm25led(cnt)
	local r,g,b = 0,0,0
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
	led.color(r,g,b)
end

cnt = 0
tmr.create():alarm(200, tmr.ALARM_AUTO, function()
	pm25led(cnt % 1000)
	cnt = cnt + 10
end)
