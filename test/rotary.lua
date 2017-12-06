rotary.setup(0, 2, 3, 4, 500, 500)

rotary.on(0, rotary.ALL, function (type, pos, evtime)

  print("Position=" .. pos .. " event type=" .. type .. " time=" .. evtime)

end)
