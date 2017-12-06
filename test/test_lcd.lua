spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 10)
gpio.mode(6, gpio.INPUT, gpio.PULLUP)
cs  = 8 -- GPIO15, pull-down 10k to GND
dc  = 6 -- GPIO2
-- res = 0 -- GPIO16, RES is optional YMMV
-- disp=u8g.pcd8544_84x48_hw_spi(cs, dc, res)
disp=u8g.pcd8544_84x48_hw_spi(cs, dc)

disp:firstPage()
repeat
	disp:setFont(u8g.font_6x10r)
	disp:setFontRefHeightExtendedText()
	disp:setDefaultForegroundColor()
	disp:setFontPosTop()
	disp:drawStr(10, 3, "Hello")
	disp:setFont(u8g.font_6x10r)
	disp:setFontRefHeightExtendedText()
	disp:setDefaultForegroundColor()
	disp:setFontPosTop()
	disp:drawStr(3, 25, "World")
until disp:nextPage() == false
