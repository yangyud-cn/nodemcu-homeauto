-- start init section --
D = require("display1306i2c")
D.init(1, 2)

if require("setup").Setup(D) then
	led = require("led")
	PMS = require("pms5003t")
	lan = require("network")
	pm25led=require("pm25led")
	ffuctrl=require("ffuctrl")

	Dcl = 1000
	FFUcl=10

	--  environment sensor parms
	DARK_TH = 900  -- mV for ADC reading, higher than this is considered dark

	-- Human sensor pin
	PD_PIN = 0  -- D0
	PDcl = 10 -- num D cycles until D out
	PMS_Scl = 600 -- num D cycles until refresh PMS reading
	PMS_Wcl = 60 -- stable reading time

	-- reconfig
	CFG_PIN = 3
	CFG=0

	-- display location parms

	D25="---"
	D1="PM1  ---"
	D10="PM10 ---"
	Dtp=" --- C"
	Dhm="--%"

	XAQD = "Out: N/A"
	XAQI=nil
	XAQT="--:--:--"

	isDark = false
	ledY = 1
	PDMode = false
	DOFFCNT = PDcl
	lastPD = 0
	PMSSCNT = 0

	function Read()
		local c = gpio.read(CFG_PIN)
		if c == 0 then
			CFG = CFG + 1
			if CFG > 3 then
				require("setup").Reset(D)
			end
		else
			CFG = 0
		end
		-- check if we need to enable env detect mode by checking if rtc has been init correcly
		local tick=rtctime.get()
		if tick > 1483228800 then
			local pd = gpio.read(PD_PIN)
			if pd == 1 then
				if lastPD == 0 then
					D.setSleepMode(false)  -- leave sleep mode
					if PMSSCNT > PMS_Wcl then
						PMS.active()
					end
				end
				-- alwasy reset the counter with people active
				PMSSCNT = 0
				DOFFCNT = PDcl
			else
				-- check sleep mode
				if PMSSCNT == PMS_Wcl then
					PMS.suspend()
				elseif PMSSCNT == PMS_Scl then
					PMS.active()
					PMSSCNT = 0
				end

				if DOFFCNT == 0 then
					D.setSleepMode(true)  -- enter sleep mode
				end
			end
			lastPD = pd
			DOFFCNT = DOFFCNT - 1
			PMSSCNT =  PMSSCNT + 1

			-- adjust display brightness and led brightness
			local bri = adc.read(0)
			local dk =  bri > DARK_TH
			if dk then
				if not isDark then
					D.setBrightness(0)
					ledY = 0.3
				end
			else
				if isDark then
					D.setBrightness(255)
					ledY = 1
				end
			end
			isDark = dk
		end

		if PMS.TM > 0 then
			D25= string.format("%03d", PMS.PM2_5)
			D1= string.format("PM1  %3d", PMS.PM1_0)
			D10= string.format("PM10 %3d", PMS.PM10)
			Dtp= string.format("%5.1fC", PMS.T)
			Dhm= string.format("%2d%%", PMS.H)
			if bit.band(tick, 2) == 0 then
				pm25led.run(PMS.PM2_5,led,ledY)
			end
		end
		if XAQI then
			XAQD = "Out: "..XAQI
			if bit.band(tick, 2) ~= 0 then
				pm25led.run(XAQI,led,ledY)
			end
		end
	end

	function Draw()
		D.set6x13()
		D.g:drawStr(1, 18, "AQ")
		D.g:drawStr(90, 41, Dtp)
		D.g:drawStr(108, 52, Dhm)

		D.setLargeDigit()
		D.g:drawStr(16, 17, D25)

		D.set6x10()
		D.g:drawStr(80, 18, XAQD)
		D.g:drawStr(80, 28, XAQT)
		D.g:drawStr(2, 43, D1)
		D.g:drawStr(2, 53, D10)
	end

	GETAQC=0
	function getXAQ()
		if not XAQI or GETAQC >= 15 then
			node.task.post(node.task.LOW_PRIORITY, function()
				if node.heap() > 6000 and (not XAQI or (D.TM:sub(1,2) + 24 - XAQT:sub(1,2))%24 > 0) then
					GETAQC=0
					require("waqi").get("@450", function(a,t) XAQI=tonumber(a); XAQT=t:sub(12,19) end)
				end
			end)
		else
			GETAQC=GETAQC+1
		end
	end

	-- main app
	-- set up env detection sensors
	-- we use ADC + light sense resistor to check for env light
	if adc.force_init_mode(adc.INIT_ADC)
	then
	  node.restart()
	  return
	end

	gpio.mode(PD_PIN, gpio.INPUT) -- enable PD sensor reading
	gpio.mode(CFG_PIN, gpio.INPUT) -- enable config reading

	led.init(7,6,5)
	D.setCallback(Read, Draw)
	D.start(Dcl)
	lan.init("pm25", D)
	lan.startService(function()
		local srv = net.createServer(net.TCP, 5)
		srv:listen(80, function(c) require("netserver").server(c) end)
		tmr.create():alarm(20000, tmr.ALARM_AUTO, getXAQ)
	end)

	PMS.init(D, function(cnt) ffuctrl.run(cnt, FFUcl, 7) end, 0)
end


