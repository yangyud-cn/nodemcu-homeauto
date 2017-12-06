local mod = ...
local M =
{
	Msg = nil,
	SC = nil,
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
end

-- print 6x13 font
function M.set6x13()
end

-- print 18x25 digit
function M.setLargeDigit()
end

-- print 9x15 symbol
function M.setSymbol()
end

function M.setSleepMode(sleepOn)
	SLEEP = sleepOn
end

function M.setBrightness(bright)
	if bright < 0 then bright = 0
	elseif bright > 255 then bright = 255
	end
end

function M.ToYMDHMS(tk)
	local t=rtctime.epoch2cal(tk + 28800) -- convert to GMT+8
	return string.format("%4d/%d/%d %02d:%02d:%02d", t["year"], t["mon"], t["day"], t["hour"], t["min"], t["sec"])
end

function M.ToHMS(tk)
	local t=rtctime.epoch2cal(tk + 28800) -- convert to GMT+8
	return string.format("%02d:%02d:%02d", t["hour"],t["min"],t["sec"])
end

function M.HMSToS(hms)
	if not hms or hms:len() ~= 8 then return -1 end
	local h = hms:sub(1,2)
	if not h:match("%d") then return -1 end
	return h*3600 + hms:sub(4,5)*60 + hms:sub(7,8)
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

	if DRAWCB then DRAWCB() end
end

function M.setCallback(prepCall, drawCall)
	PREPCB = prepCall
	DRAWCB = drawCall
end

function M.init(drawInterval)
	tmr.create():alarm(drawInterval, tmr.ALARM_AUTO, Display)
end

return M
