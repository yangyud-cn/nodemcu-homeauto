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

-- Nokia 5110 HSPI connection
-- D5/GPIO14 -> Clk
-- D6/GPIO12 -> DC
-- D7/GPIO13 -> Din
-- D8/GPIO15 -> CE, pull-down 10k to GND
-- 84 x 48

local WC={ "\208", "\211", "\209", "\210" }
local WCNT=1
local NWT=0  -- how many waiters
local IC_X=75
local IC_Y=0
local IC2_X=66
local IC2_Y=0
local M_X = 0
local M_Y = 38
local T_X=0
local T_Y=0

local PREPCB=nil
local DRAWCB=nil

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

function M.ToYMDHMS(tk)
	local t=rtctime.epoch2cal(tk + 28800) -- convert to GMT+8
	return string.format("%4d/%d/%d %02d:%02d:%02d", t["year"], t["mon"], t["day"], t["hour"], t["min"], t["sec"])
end

function M.ToHMS(tk)
	local t=rtctime.epoch2cal(tk + 28800) -- convert to GMT+8
	return string.format("%02d:%02d:%02d", t["hour"],t["min"],t["sec"])
end

function M.Update()
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

function M.reconfig()
	spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 10)
	gpio.mode(6, gpio.INPUT, gpio.PULLUP) -- release HMISO to use as D/C
end

function M.init()
	M.reconfig()
	local cs  = 8 -- GPIO15, pull-down 10k to GND
	local dc  = 6 -- GPIO12
	M.g=u8g.pcd8544_84x48_hw_spi(cs, dc)
end

return M
