local modname = ...
local M =
{
	PM2_5 = nil,
	PM1_0 = nil,
	PM10  = nil,
	Temporature = nil,
	Humidity = nil
}
_G[modname] = M

local PMS_EN_PIN = 0

local PMS_RXBUF = {}
local PMS_RXIDX = 1

local PMS_CALL=nil
local D=
{
	Msg = nil,
	SC = nil
}
local LED = nil

local function PMS5003T_rx(data)
	-- find sync header
	if PMS_RXIDX == 1 then
		if data:byte(1) == 0x42 then
			PMS_RXBUF[1]=0x42
			PMS_RXIDX=2
		else
			PMS_RXIDX=1
		end
	elseif PMS_RXIDX == 2 then
		if data:byte(1) == 0x4d then
			PMS_RXBUF[2]=0x4d
			PMS_RXIDX=3
		else
			PMS_RXIDX=1
		end
   elseif PMS_RXIDX == 3 then
		if data:byte(1) == 0 then
			PMS_RXBUF[3]=0
			PMS_RXIDX=4
		else
			PMS_RXIDX=1
		end
	elseif PMS_RXIDX == 4 then
		if data:byte(1) == 28 then
			PMS_RXBUF[4]=28
			PMS_RXIDX=5
		else
			PMS_RXIDX=1
		end
	else
		-- data
		PMS_RXBUF[PMS_RXIDX]=data:byte(1)
		PMS_RXIDX=PMS_RXIDX + 1
		if PMS_RXIDX == 33 then
			PMS_RXIDX=1  -- reset state
			local csum=0xab;  -- header sum
			for i=5, 30, 1 do
				csum=csum + PMS_RXBUF[i]
			end
			local expcsum=bit.bor(bit.lshift(PMS_RXBUF[31], 8), PMS_RXBUF[32])
			if(expcsum ~= csum) then
				D.Msg="PMS Csum Err"
				D.SC="\204"
				return
			end

			M.PM2_5 = bit.bor(bit.lshift(PMS_RXBUF[ 5], 8), PMS_RXBUF[ 6])
			M.PM1_0 = bit.bor(bit.lshift(PMS_RXBUF[ 7], 8), PMS_RXBUF[ 8])
			M.PM10  = bit.bor(bit.lshift(PMS_RXBUF[ 9], 8), PMS_RXBUF[10])
			M.Temporature = bit.bor(bit.lshift(PMS_RXBUF[25], 8), PMS_RXBUF[26]) / 10.0
			M.Humidity	= bit.bor(bit.lshift(PMS_RXBUF[27], 8), PMS_RXBUF[28]) / 10.0
			D.SC = "\207"
			if PMS_CALL then PMS_CALL(M.PM2_5) end
		end
	end
end

function M.active()
	gpio.write(PMS_EN_PIN, gpio.HIGH)
	D.SC="\206"
	if LED then
		LED.color(128, 128, 128)
	end
end

function M.suspend()
	gpio.write(PMS_EN_PIN, gpio.LOW)
	D.SC="\203"
	if LED then
		LED.color(0, 0, 32)
		LED.freq(1)
	end
end

function M.init(en_pin, display, callback, use_alt, ledStatus)
	PMS_CALL = callback
	LED = ledStatus
	-- if LED == nil then
		node.output(function(str) end, 0)
		uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
		if use_alt == 1 then 
			uart.alt(1)
		end
		uart.on("data", 1, PMS5003T_rx, 0)
	-- end
	if en_pin then PMS_EN_PIN = en_pin end
	if display then D = display end
	gpio.mode(PMS_EN_PIN, gpio.OUTPUT)
	M.active()
end

--[[ tmr.create():alarm(60000, tmr.ALARM_AUTO, function()
	enablePMS5003T()
	tmr.create():alarm(10000, tmr.ALARM_SINGLE, disablePMS5003T)
end) ]]

-- M.RX = PMS5003T_rx
return M
