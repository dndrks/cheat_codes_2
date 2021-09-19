local levels = {}

function levels.init()
  params:add_group("levels",12)
  params:add_separator("funnel shape")
  for i = 1,3 do
    params:add_option("bank "..i.." fnl shape", "bank "..i.." shape",easingFunctions.easingNames,1)
  end
  params:add_separator("funnel rise time")
  for i = 1,3 do
    params:add_number("bank "..i.." fnl rise", "bank "..i.." rise time (sec)",0,120,1)
  end
  params:add_separator("funnel fall time")
  for i = 1,3 do
    params:add_number("bank "..i.." fnl fall", "bank "..i.." fall time (sec)",0,120,1)
  end
end

function levels.volume_ramp(i)
  local b = bank[i].global_level_fnl
  local shape = params:string("bank "..i.." fnl shape")
  if b.fnl ~= nil then
    clock.cancel(b.fnl)
  end
  if b.active then -- if the funnel is interrupted...
    b.start_val = b.current_value
    b.direction = b.direction == "falling" and "rising" or "falling"
    b.end_val = b.direction == "falling" and 0 or bank[i].global_level
  else
    if b.current_value > 0 then
      b.start_val = bank[i].global_level
      b.end_val = 0
      b.direction = "falling"
    else
      b.start_val = 0
      b.end_val = bank[i].global_level
      b.direction = "rising"
    end
  end
  b.active = true
  b.fnl = _live.fnl(
    function(g_lvl)
      softcut.level(i+1,easingFunctions[shape](g_lvl,0,bank[i].global_level,1))
      print(easingFunctions[shape](g_lvl,0,bank[i].global_level,1))
      b.current_value = util.round(g_lvl,0.01)
      if (b.direction == "falling" and util.round(g_lvl,0.01) == 0)
      or (b.direction == "rising" and util.round(g_lvl,0.01) == util.round(bank[i].global_level,0.01))
      then
        print("LEVEL FUNNEL DONE")
        b.active = false
      end
    end,
    b.start_val,
    {{b.end_val,b.direction == "falling" and util.clamp(params:get("bank "..i.." fnl fall"),0.1,120) or util.clamp(params:get("bank "..i.." fnl rise"),0.1,120)}}
  )
end

function levels.return_current_funnel_value(i)
  local b = bank[i].global_level_fnl
  local shape = params:string("bank "..i.." fnl shape")
  return(easingFunctions[shape](b.current_value,0,bank[i].global_level,1))
end

return levels