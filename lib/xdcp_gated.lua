-- module for Intersil XDCP digitally controlled potentiometer, eg X9Cxxx with I/O pin gate control for pin sharing
local mod = ...
local M =
{
	UP = 1,		-- M.shift dir, move up wiper
	DOWN = 0	-- M.shift dir, move down wiper
}
_G[mod] = M

-- allow bus signal negative
local CS0 = 0
local CS1 = 1
local UD0 = 0
local UD1 = 1
local INC0 = 0
local INC1 = 1

local CSp
local UDp
local INCp
local IOmd
local IOpu
local CYC = 1

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
	dir = dir == M.UP and UD1 or UD0
	gpio.write(UDp, dir) 
	tmr.delay(3*CYC) -- Tdi = 2.9us
	gpio.write(CSp, CS0)  -- make CS low to start, cs is high if init or previously persisted value 
	for i=1,cnt do
		gpio.write(INCp, INC1)	
		tmr.delay(CYC)
		gpio.write(INCp, INC0)	
		tmr.delay(CYC)
	end
	if save  and save then
		gpio.write(INCp, INC1)  -- _/- move high for write
		tmr.delay(CYC) -- Tic = 1 us
		gpio.write(CSp, CS1) -- CS up with INC high will trigger persist write
		tmr.delay(CYC) -- make sure the timing is correct for CS to start write
		_WRTM = tmr.now() -- need to wait for 20 ms for next change
	else
		gpio.write(CSp, CS1) -- CS up with INC low will not write
		tmr.delay(CYC) -- Tic = 1 us
		gpio.write(INCp, INC1)  -- _/- move high for standby
	end
	_BUSY = false
	return true
end

function M.reconfig()
	gpio.mode(UDp, IOmd, IOpu) gpio.write(UDp, UD1)
	gpio.mode(CSp, IOmd, IOpu) gpio.write(CSp, CS1)
	gpio.mode(INCp, IOmd, IOpu) gpio.write(INCp, INC1)
end

-- initialize, cs is the pin for /CS, ud: U_/D, inc: /INC
-- nandGate  for NAND gate, nil for OR gate
-- odmode  for OD output, nil for normal output
-- call M.init to reconfigure the pins for XDCP
function M.init(cs, ud, inc, nandGate, odmode, cycle)
	IOmd = odmode  and gpio.OPENDRAIN or gpio.OUTPUT
	IOpu = odmode  and gpio.PULLUP or gpio.FLOAT
	CYC = cycle  and cycle or 1
	CSp = cs
	UDp = ud
	INCp = inc
	
	if nandGate then -- NAND gate
		CS0 = 1
		UD0 = 1
		INC0 = 1
	else -- OR gate
		CS0 = 0
		UD0 = 0
		INC0 = 0
	end
	CS1 = 1 - CS0
	UD1 = 1 - UD0
	INC1 = 1 - INC0
	
	M.reconfig()
end

return M
