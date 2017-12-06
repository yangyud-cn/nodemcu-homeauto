local modname = ...
local M = {}
_G[modname] = M

local RPIN = 7
local GPIN = 6
local BPIN = 5
local REV = false

function M.init(r_pin, g_pin, b_pin, rev)
	if rev then
		REV = true
	else
		REV = false
	end
	RPIN = r_pin
	GPIN = g_pin
	BPIN = b_pin
	pwm.setup(RPIN, 1000, 1023)
	pwm.setup(GPIN, 1000, 1023)
	pwm.setup(BPIN, 1000, 1023)
	pwm.start(RPIN)
	pwm.start(GPIN)
	pwm.start(BPIN)
end

function M.r(r)
	if r > 1023 then r = 1023 end
	pwm.setduty(RPIN, REV and 1023-r or r)
end

function M.g(g)
	if g > 1023 then g = 1023 end
	pwm.setduty(GPIN, REV and 1023-g or g)
end

function M.b(b)
	if b > 1023 then b = 1023 end
	pwm.setduty(BPIN, REV and 1023-b or b)
end

function M.color(r, g, b)
	M.r(r)
	M.g(g)
	M.b(b)
end

function M.freq(freq)
	pwm.setclock(RPIN, freq)
end

return M