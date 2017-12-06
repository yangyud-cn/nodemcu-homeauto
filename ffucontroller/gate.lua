-- module for I/O pin gate control for pin sharing
local mod = ...
local M =
{
	UP = 1,		-- M.shift dir, move up wiper
	DOWN = 0	-- M.shift dir, move down wiper
}
_G[mod] = M

local Goff = 0
local Gon = 1
local Gp

function M.on()
	gpio.write(Gp, Gon)
end	

function M.off()
	gpio.write(Gp, Goff)
end	

-- initialize, gate is the pin for i/o pin reuse gate control
-- nandGate  for NAND gate, nil for OR gate
function M.init(gate, nandGate)
	Gp = gate
	
	if nandGate then -- NAND gate
		Goff = 0  -- AND 0 ==> all 1
	else -- OR gate
		Goff = 1  -- OR 1  ==> all 1
	end
	Gon = 1 - Goff
	
	gpio.mode(Gp, gpio.OUTPUT, gpio.FLOAT)
	gpio.write(Gp, Goff)
end

return M
