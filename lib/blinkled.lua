local modname = ...
local M =
{
}
_G[modname] = M

local LED = nil
local MaxBlinkFreq = 10

local Blink = false
local BlinkFreq = 0
local BlinkCycle = 1
local BlinkCycle2 = 2
local BlinkCount = 0

local PrevR = 0
local PrevG = 0
local PrevB = 0
local CurrR = 0
local CurrG = 0
local CurrB = 0

local function Update()
	if Blink then
		if BlinkCount == 0 then
			LED.color(CurrR, CurrG, CurrB)
			PrevR = CurrR
			PrevG = CurrG
			PrevB = CurrB
		elseif BlinkCount == BlinkCycle then
			LED.color(0, 0, 0)
			PrevR = 0
			PrevG = 0
			PrevB = 0
		end
		if BlinkCount < BlinkCycle2 then
			BlinkCount = BlinkCount + 1
		else
			BlinkCount = 0
		end
	else
		if PrevR ~= CurrR or PrevG ~= CurrG or PrevB ~= CurrB then
			PrevR = CurrR
			PrevG = CurrG
			PrevR = CurrB
			LED.color(CurrR, CurrG, CurrB)
		end
	end
end

function M.SetFreq(freq)
	if freq == BlinlFreq then return end
	BlinkFreq = freq
	if freq == 0 then
		Blink = false
		return
	end
	if freq > MaxBlinkFreq then freq = MaxBlinkFreq end

	BlinkCycle2 = math.ceil(MaxBlinkFreq * 2 / freq)
	BlinkCycle = math.ceil (BlinkCycle2 / 2)
	Blink = true
end

function M.SetColor(r, g, b)
	CurrR = r
	CurrG = g
	CurrB = b
	Update()
end

local _timer = nil
function M.init(led, maxFreq)
	LED = assert(led, "led can't be nil")

	if maxFreq then
		if maxFreq > 10 then
			assert(false, "maxFreq must be not more than 10")
		end
		MaxBlinkFreq = maxFreq
	end

	if not _timer then
		LED.color(0,0,0)
		PrevR = 0
		PrevG = 0
		PrevB = 0
		Blink = false
		_timer = tmr.create()
		_timer:alarm(math.ceil(1000/MaxBlinkFreq/2), tmr.ALARM_AUTO, Update)
	end
end

function M.close()
	if _timer then
		_timer:stop()
		_timer:unregister()
		_timer = nil
	end
end


return M
