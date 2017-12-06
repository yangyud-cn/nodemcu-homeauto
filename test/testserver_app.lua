lan = require("network")
lan.init()

function getXAQ()
    node.task.post(node.task.LOW_PRIORITY, function()
        if node.heap() > 7000 then
            require("waqi").get("@450", function(a,t) XAQI=tonumber(a); XAQT=t:sub(12,19) end)
        end
    end)
end

lan.startService(function()
    local srv = net.createServer(net.TCP, 5)
    srv:listen(80, function(c)
        require("testserver").server(c, function() print("CB") end) 
    end)
    getXAQ()
    tmr.create():alarm(5000, tmr.ALARM_AUTO, getXAQ)
end)

tmr.create():alarm(1000, tmr.ALARM_AUTO, function() 
    print("T " .. rtctime.get() .. "  H " .. node.heap())
end)