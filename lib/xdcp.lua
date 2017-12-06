-- module for Intersil XDCP digitally controlled potentiometer, eg X9Cxxx
local modname = ...
local M =
{
	UP = 1,		-- M.shift dir, move up wiper
	DOWN = 0	-- M.shift dir, move down wiper
}
_G[modname] = M

local CSp
local UDp
local INCp
local IOmd
local IOpu

local _BUSY = false
local _WRTM = nil

-- move the wiper bu cnt, dirrection is dir, optional persist if save == true
-- none save mode complete: /CS low, /INC low
function M.move(cnt, dir, save)
	if _BUSY then
		return false
	elseif _WRTM then  -- Tcph = 20 ms, delay before persist saves
		local curr = tmr.now()
		if _WRTM + 20000 > 4294967295 then  -- wrap around
			if curr < _WRTM + 20000 - 4294967295 then
				return false
			end
		elseif curr < _WRTM + 20000 then
			return false
		end
	end
	_BUSY = TRUE
	_WRTM = nil -- save will update it
	
	gpio.write(UDp, dir) 
	tmr.delay(3) -- Tdi = 2.9us
	gpio.write(CSp, 0)  -- make CS low to start, cs is high if init or previously persisted value 
	for i=1,cnt do
		gpio.write(INCp, 1)	
		tmr.delay(1)
		gpio.write(INCp, 0)	
		tmr.delay(1)
	end
	if save  and save then
		gpio.write(INCp, 1)  -- _/- move high for write
		tmr.delay(1) -- Tic = 1 us
		gpio.write(CSp, 1) --  CS up with INC high will trigger persist write
		tmr.delay(1) -- make sure the timing is correct for CS to start write
		_WRTM = tmr.now()
	else
		gpio.write(CSp, 1)  -- CS up with INC low will not write
		tmr.delay(1) -- Tic = 1 us
		gpio.write(INCp, 1)  -- _/- move high for standby
	end
	_BUSY = false
	return true
end

function M.reconfig()
	gpio.mode(CSp, IOmd, IOpu) gpio.write(CSp, 1)
	gpio.mode(UDp, IOmd, IOpu) gpio.write(UDp, 1)
	gpio.mode(INCp, IOmd, IOpu) gpio.write(INCp, 1)
end


-- initialize, cs is the pin for /CS, ud: U_/D, inc: /INC
-- output pin reuse is possible with CS and UD pin only
-- in these cases, INC pin will need to be kept low
-- call M.init to reconfigure the pins for XDCP
function M.init(cs, ud, inc, odmode)
	IOmd = odmode  and gpio.OPENDRAIN or gpio.OUTPUT
	IOpu = odmode  and gpio.PULLUP or gpio.FLOAT
	CSp = cs
	UDp = ud
	INCp = inc
	M.reconfig()
end

return M
