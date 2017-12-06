local mod = ...
local M =
{
	Msg = nil,
	SC = nil,
	SC2 = nil,
	u8g = nil,
	TM="--:--:--",
	UpT=''
}
_G[mod] = M

-- 128 x 64 with top 16 lines in different color

local WC={ "\208", "\211", "\209", "\210" }
local WCNT=1
local NWT=0  -- how many waiters
local IC_X=119
local IC_Y=0
local IC2_X=110
local IC2_Y=0
local M_X = 51
local M_Y = 5
local T_X=0
local T_Y=2

local PREPCB=nil
local DRAWCB=nil
local SLEEP =false


function M.startWait()
	NWT=NWT + 1
end

function M.endWait()
	if NWT > 0 then
		NWT=NWT-1
	end
end


-- print 6x10 font
function M.set6x10()
	M.g:setFont(u8g.font_6x10r)
	M.g:setFontRefHeightExtendedText()
	M.g:setDefaultForegroundColor()
	M.g:setFontPosTop()
end

-- print 6x13 font
function M.set6x13()
	M.g:setFont(u8g.font_6x13r)
	M.g:setFontRefHeightExtendedText()
	M.g:setDefaultForegroundColor()
	M.g:setFontPosTop()
end

-- print 18x25 digit
function M.setLargeDigit()
	M.g:setFont(u8g.font_fub25n)
	M.g:setFontRefHeightExtendedText()
	M.g:setDefaultForegroundColor()
	M.g:setFontPosTop()
end

-- print 9x15 symbol
function M.setSymbol()
	M.g:setFont(u8g.font_9x15_67_75)
	M.g:setFontRefHeightExtendedText()
	M.g:setDefaultForegroundColor()
	M.g:setFontPosTop()
end

function M.setSleepMode(sleepOn)
	if sleepOn then
		M.g:sleepOn()
	else
		M.g:sleepOff()
	end
	SLEEP = sleepOn
end

function M.setBrightness(bright)
	if bright < 0 then bright = 0
	elseif bright > 255 then bright = 255
	end
	M.g:setContrast(bright)
end

function M.ToYMDHMS(tk)
	local t=rtctime.epoch2cal(tk + 28800) -- convert to GMT+8
	return string.format("%4d/%d/%d %02d:%02d:%02d", t["year"], t["mon"], t["day"], t["hour"], t["min"], t["sec"])
end

function M.ToHMS(tk)
	local t=rtctime.epoch2cal(tk + 28800) -- convert to GMT+8
	return string.format("%02d:%02d:%02d", t["hour"],t["min"],t["sec"])
end

local function Display()
	local up = tmr.time()
	M.UpT=string.format("%d.%02d:%02d", up/86400, up%86400/3600, up%3600/60)
	local tick=rtctime.get()
	if tick > 1483228800 then -- 2017/1/1
		M.TM=M.ToHMS(tick)
	end
	local icon=M.SC
	if NWT > 0 then
	   icon=WC[(WCNT % 4) + 1]
	   WCNT=WCNT + 1
	end

	local msg=M.Msg
	M.Msg=nil

	if PREPCB then PREPCB() end

	if SLEEP then
		return
	end

	if bit.band(up, 2) == 0 and not msg then 
		msg = "H:"..node.heap()
	end

	M.g:firstPage()
	repeat
		M.set6x10()
		if msg then
			M.g:drawStr(M_X, M_Y, msg)
		else
			M.g:drawStr(M_X, M_Y, M.UpT)
		end
		if icon or M.SC2 then
			M.setSymbol()
			if icon then M.g:drawStr(IC_X, IC_Y, icon) end
			if M.SC2 then M.g:drawStr(IC2_X, IC2_Y, M.SC2) end
		end
		M.set6x13()
		M.g:drawStr(T_X, T_Y, M.TM)
		if DRAWCB then DRAWCB() end
	until M.g:nextPage() == false
end

function M.setCallback(prepCall, drawCall)
	PREPCB = prepCall
	DRAWCB = drawCall
end

function M.init(i2c_sda_pin, i2c_scl_pin)
	i2c.setup(0, i2c_sda_pin, i2c_scl_pin, i2c.SLOW)
	M.g=u8g.ssd1306_128x64_i2c(0x3C)
end

function M.start(drawInterval)
	tmr.create():alarm(drawInterval, tmr.ALARM_AUTO, Display)
end

return M
