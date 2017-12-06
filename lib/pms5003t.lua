local mod = ...
local M =
{
	PM2_5 = nil,
	PM1_0 = nil,
	PM10  = nil,
	T = nil,
	H = nil,
	TM = 0
}
_G[mod] = M

local RXB = {}
local RXI = 1

local PMSCB=nil
local D=
{
	Msg = nil,
	SC = nil
}

local function PMSRX(data)
	-- find sync header
	if RXI == 1 then
		if data:byte(1) == 0x42 then
			RXB[1]=0x42
			RXI=2
		else
			RXI=1
		end
	elseif RXI == 2 then
		if data:byte(1) == 0x4d then
			RXB[2]=0x4d
			RXI=3
		else
			RXI=1
		end
   elseif RXI == 3 then
		if data:byte(1) == 0 then
			RXB[3]=0
			RXI=4
		else
			RXI=1
		end
	elseif RXI == 4 then
		if data:byte(1) == 28 then
			RXB[4]=28
			RXI=5
		else
			RXI=1
		end
	else
		-- data
		RXB[RXI]=data:byte(1)
		RXI=RXI + 1
		if RXI == 33 then
			RXI=1  -- reset state
			local csum=0xab;  -- header sum
			for i=5, 30, 1 do
				csum=csum + RXB[i]
			end
			local expcsum=bit.bor(bit.lshift(RXB[31], 8), RXB[32])
			if(expcsum ~= csum) then
				D.Msg="PMS Csum Err"
				D.SC="\204"
				RXB = {}
				return
			end

			M.PM2_5 = bit.bor(bit.lshift(RXB[ 5], 8), RXB[ 6])
			M.PM1_0 = bit.bor(bit.lshift(RXB[ 7], 8), RXB[ 8])
			M.PM10  = bit.bor(bit.lshift(RXB[ 9], 8), RXB[10])
			M.T = bit.bor(bit.lshift(RXB[25], 8), RXB[26]) / 10.0
			M.H = bit.bor(bit.lshift(RXB[27], 8), RXB[28]) / 10.0
			RXB = {}
			M.TM = rtctime.get()
			D.SC = "\207"
			if PMSCB then PMSCB(M.PM2_5) end
		end
	end
end

function M.active()
	uart.write(0, 0x42, 0x4d, 0xe4, 0, 1, 0x01, 0x74)
	D.SC="\206"
end

function M.suspend()
	uart.write(0, 0x42, 0x4d, 0xe4, 0, 0, 0x01, 0x73)
	D.SC="\203"
end

function M.init(display, callback, use_alt)
	PMSCB = callback
	node.output(function(str) end, 0)
	uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
	if use_alt == 1 then 
		uart.alt(1)
	end
	uart.on("data", 1, PMSRX, 0)
	
	if display then D = display end
	M.active()
end

return M
