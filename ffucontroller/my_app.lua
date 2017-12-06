MUX = require("gate")
D = require("display8544spi")
MuxCtl=0
MUX.init(MuxCtl, 1)  -- nand MUX
MUX.off()
tmr.delay(100)
D.init() -- fixed 5,6,7,8 pin

if require("setup").Setup(D) then
	DCP=require("xdcp_gated")
	websvr = require("websvr")
	lan = require("network")

	DcpCS=7
	DcpUD=5
	DcpINC=6
	DcpCL=30
	ROT_SW=4
	ROT_A=2
	ROT_B=3
	OneW=1

	InDUpd=false
	InSpdD=0

	SPD=0
	DELTA=0
	VIBL=15 -- range with vibration 
	VIBH=18
	STOR=false
	MAN=false
	LASTT=0

	function SetSpd()
		local dlt = DELTA > 0 and math.floor(DELTA) or math.ceil(DELTA)
		if dlt ~= 0 then
			DELTA = 0
			MUX.on()
			tmr.delay(DcpCL)
			DCP.reconfig() -- change pin config
			if dlt > 0 then
				DCP.move(dlt, DCP.UP, STOR)
			else
				DCP.move(-dlt, DCP.DOWN, STOR)
			end
				STOR=false
			SPD = SPD + dlt
			if SPD > 100 then SPD = 100
			elseif SPD < 0 then SPD = 0 end
			print(string.format("SPD=%d", SPD))
		end
	end

	function TryUpdSPD()
		LASTT=tmr.time()
		if not InDUpd and DELTA ~= 0 then
			InDUpd = true
			SetSpd()
			local spdStr = string.format("%d%%", SPD)

			MUX.off()
			tmr.delay(DcpCL)
			D.reconfig()
			D.g:firstPage()
			repeat
				D.setLargeDigit()
				D.g:drawStr(10, 5, spdStr)
			until D.g:nextPage() == false
			InDUpd = false
			InSpdD=3
		end
	end

	-- temperature sensor
	DS18ADR="28:FF:69:83:01:17:05:ED"
	InT=0.0
	InTM=0

	function ds18call(idx, ROM, resol, temp, temp_dec, par)
		InT=temp
		InTM=rtctime.get()
		print(string.format("Inlet=%fC", InT))
	end
				
	function UpdTemp()
		ds18b20.read(ds18call, {DS18ADR})
	end

	spdD=""
	tmpD=""
	function DPrep()
		spdD =  string.format("Speed: %d%%", SPD)
		tmpD = string.format("Inlet: %4.1fC", InT)
		D.SC = MAN and '\81' or '\85'
		local lu = tmr.time()-LASTT
		if lu > 1800 then D.SC2='\204' elseif lu > 300 then D.SC2='\203' end
	end

	function DDraw()
		D.set6x13()
		D.g:drawStr(0, 12, spdD)
		D.g:drawStr(0, 24, tmpD)
	end

	function MiniWeb()
		local svr = net.createServer(net.TCP, 5)
		svr:listen(80,websvr.run)
	end

	-- init LCD display
	D.SC2='\230'
	D.Update()
	tmr.delay(DcpCL)

	-- init SPD control
	MUX.on() -- trigger reset
	tmr.delay(DcpCL)
	DCP.init(DcpCS, DcpUD, DcpINC, 1, DcpCL)  -- NAND MUX
	DCP.move(100, DCP.DOWN, false)

	if file.exists("fan_speed_save.val") then
		file.open("fan_speed_save.val", "r")
		DELTA = file.read(3)
		file.close()
		if not DELTA or not DELTA:match("%d") then
			DELTA = 0
		else
			DELTA = DELTA + 0
		end
		SPD = 0
		TryUpdSPD()
	end


	lan.init("ffu", D)
	lan.startService(MiniWeb)

	ds18b20.setup(OneW)
	ds18b20.setting({DS18ADR}, 10)
	UpdTemp()
	tmr.create():alarm(30000,tmr.ALARM_AUTO, UpdTemp)

	-- rotary
	LastRot = -12345678
	rotary.setup(0, ROT_A, ROT_B, ROT_SW, 2000, 500)
	rotary.on(0, rotary.ALL, function (etype, pos, etime)
		if etype == rotary.DBLCLICK then
			file.open("fan_speed_save.val", "w+")
			file.write(SPD)
			file.close()
			D.Msg = "SPD Saved"
		elseif etype == rotary.TURN then
			local dlt = LastRot ~= -12345678 and pos - LastRot or 0
			LastRot = pos
			DELTA = DELTA + dlt/4 -- the used rotary coder seems to bump 4 pulses per stop
			TryUpdSPD()
		elseif etype == rotary.CLICK then
			MAN = not MAN
			D.Msg = MAN and "Manual" or "Remote"
		elseif etype == rotary.LONGPRESS then
			MUX.off()
			tmr.delay(DcpCL)
			D.reconfig()
			require("setup").Reset(D)
		end
	end)

	D.setCallback(DPrep, DDraw)

	-- main display loop
	tmr.create():alarm(1000, tmr.ALARM_AUTO, function()
		if InSpdD > 0 then
			InSpdD = InSpdD - 1
			return
		end
		if not InDUpd then
			InDUpd = true
			if DELTA ~= 0 then
				SetSpd()
			end
			MUX.off()
			tmr.delay(DcpCL)
			D.reconfig()
			D.Update()
			InDUpd = false
		end
	end)
end
