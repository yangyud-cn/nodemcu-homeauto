led = require("led")
lan = require("network")
D = require("fakedisplay")
pm25led=require("pm25led")
ffuctrl=require("ffuctrl")

PMS =
{
    PM2_5 = 20,
    PM1_0 = 30,
    PM10  = 50,
    T = 15,
    H = 25,
    TM = 1509537739,
    active = function() end,
    suspend = function() end
}

Dcl = 1000
FFUcl=10

--  environment sensor parms
DARK_TH = 900  -- mV for ADC reading, higher than this is considered dark

-- Human sensor pin
PD_PIN = 0  -- D0
PDcl = 10 -- num D cycles until D out
PMS_Scl = 600 -- num D cycles until refresh PMS reading
PMS_Wcl = 60 -- stable reading time

-- display location parms
AQx=1
AQy=18

XAQx=80
XAQy=18
XAQTx=80
XAQTy=28

P25x=16
P25y=17

P1x=2
P1y=43

P10x=2
P10y=53

TPx=90
TPy=41

HMx=108
HMy=52


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
    -- check if we need to enable env detect mode by checking if rtc has been init correcly
    local tick=rtctime.get()
    print("T "..D.TM .. " H " .. node.heap())

    if tick > 1483228800 then
        local pd = bit.band(tick, 1)
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
        local bri = bit.band(tick, 1023)
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
--[[	D.set6x13()
	D.g:drawStr(AQx, AQy, "AQ")
	D.g:drawStr(TPx, TPy, Dtp)
	D.g:drawStr(HMx, HMy, Dhm)

	D.setLargeDigit()
	D.g:drawStr(P25x, P25y, D25)

	D.set6x10()
	D.g:drawStr(XAQx, XAQy, XAQD)
	D.g:drawStr(XAQTx, XAQTy, XAQT)
	D.g:drawStr(P1x, P1y, D1)
	D.g:drawStr(P10x, P10y, D10)
	]]
end

function getXAQ()
	node.task.post(node.task.LOW_PRIORITY, function()
		if node.heap() > 7000 and (not XAQI or (D.TM:sub(1,2) + 24 - XAQT:sub(1,2))%24 > 0) then
			require("waqi").get("@450", function(a,t) XAQI=tonumber(a); XAQT=t:sub(12,19) end)
		end
	end)
end

--led.init(7,6,5)
--D.init(1, 2, Dcl)
D.init(Dcl)

D.setCallback(Read, Draw)
lan.init()

_reentry = false
lan.startService(function()
    local srv = net.createServer(net.TCP, 5)
    srv:listen(80, function(c)
		if _reentry then print("-- BAD --") c:close() return end
		_reentry = true
		require("netserver").server(c, function() _reentry = false end) 
	end)
    getXAQ()
    tmr.create():alarm(5000, tmr.ALARM_AUTO, getXAQ)
end)

FFUcl=10

tmr.create():alarm(1567, tmr.ALARM_AUTO, function() 
	local t = rtctime.get()
	PMS.PM2_5 = bit.band(t, 7)
	PMS.TM = t
	ffuctrl.run(PMS.PM2_5, FFUcl, 7)
end)

