local levels = {}

function levels.rise(b,p)
  softcut.level_slew_time(b+1,0.01)
  local e = bank[b][p].level_envelope
  local shape = "inSine"
  if e.fnl ~= nil then
    clock.cancel(e.fnl)
  end
  if e.active then -- if the funnel is interrupted...
    e.start_val = e.current_value
    e.direction = e.direction == "falling" and "rising" or "falling"
    e.end_val = e.direction == "falling" and 0 or bank[b][p].level
  else
    e.start_val = 0
    e.end_val = bank[b][p].level
    e.direction = "rising"
  end
  if e.rise_stage_time == 0 then
    softcut.level(b+1,bank[b][p].level*bank[b].global_level)
    softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*bank[b][bank[b].id].level)*bank[b].global_level)
    softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*bank[b][bank[b].id].level)*bank[b].global_level)
    levels.fall(b,p)
    e.active = false
  else
    e.active = true
    e.fnl = _live.fnl(
      function(g_lvl)
        if bank[b].level_lfo ~= nil and bank[b].level_lfo.active ~= nil and bank[b].level_lfo.active then
          -- softcut.level(i+1,easingFunctions[shape](g_lvl*bank[b].level_lfo.slope,0,bank[b][p].level,1))
        else
          softcut.level(b+1,easingFunctions[shape](g_lvl,0,bank[b][p].level*bank[b].global_level,1))
          softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*bank[b][bank[b].id].level)*easingFunctions[shape](g_lvl,0,bank[b][p].level,1)*bank[b].global_level)
          softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*bank[b][bank[b].id].level)*easingFunctions[shape](g_lvl,0,bank[b][p].level,1)*bank[b].global_level)
        end
        -- print(easingFunctions[shape](g_lvl,0,bank[b][p].level,1))
        e.current_value = util.round(g_lvl,0.0001)
        if (e.direction == "falling" and util.round(g_lvl,0.01) == 0)
        or (e.direction == "rising" and util.round(g_lvl,0.01) == util.round(bank[b][p].level,0.01))
        then
          print("RISE LEVEL FUNNEL DONE",e.current_value,e.direction)
          e.active = false
          if e.direction == "falling" then
            e.mute_active = true
          else
            e.mute_active = false
            if e.fall_stage_active then
              levels.fall(b,p)
              print("should be falling...")
            end
          end
        end
      end,
      e.start_val,
      -- {{e.end_val,e.direction == "falling" and util.clamp(params:get("bank "..i.." fnl fall"),0.1,120) or util.clamp(params:get("bank "..i.." fnl rise"),0.1,120)}}
      {{e.end_val,e.rise_stage_time}},
      30
    )
  end
end

function levels.fall(b,p)
  softcut.level_slew_time(b+1,0.01)
  local e = bank[b][p].level_envelope
  local shape = "inExpo"
  if e.fnl ~= nil then
    clock.cancel(e.fnl)
  end
  if e.active then -- if the funnel is interrupted...
    e.start_val = e.current_value
    e.direction = e.direction == "falling" and "rising" or "falling"
    e.end_val = e.direction == "falling" and 0 or bank[b][p].level
  else
    print("no prev active")
    e.start_val = bank[b][p].level
    e.end_val = 0
    e.direction = "falling"
  end
  if e.fall_stage_time == 0 then
    softcut.level(b+1,bank[b][p].level*bank[b].global_level)
    softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*bank[b][bank[b].id].level)*bank[b].global_level)
    softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*bank[b][bank[b].id].level)*bank[b].global_level)
    e.active = false
  else
    e.active = true
    e.fnl = _live.fnl(
      function(g_lvl)
        if bank[b].level_lfo ~= nil and bank[b].level_lfo.active ~= nil and bank[b].level_lfo.active then
          -- softcut.level(i+1,easingFunctions[shape](g_lvl*bank[b].level_lfo.slope,0,bank[b][p].level,1))
        else
          softcut.level(b+1,easingFunctions[shape](g_lvl,0,bank[b][p].level,1)*bank[b].global_level)
          softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*bank[b][bank[b].id].level)*easingFunctions[shape](g_lvl,0,bank[b][p].level,1)*bank[b].global_level)
          softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*bank[b][bank[b].id].level)*easingFunctions[shape](g_lvl,0,bank[b][p].level,1)*bank[b].global_level)
        end
        -- print(easingFunctions[shape](g_lvl,0,bank[b][p].level,1))
        e.current_value = util.round(g_lvl,0.0001)
        if (e.direction == "falling" and util.round(g_lvl,0.01) == 0)
        or (e.direction == "rising" and util.round(g_lvl,0.01) == util.round(bank[b][p].level,0.01))
        then
          print("FALL LEVEL FUNNEL DONE",e.current_value)
          e.active = false
          if e.direction == "falling" then
            e.mute_active = true
          else
            e.mute_active = false
          end
        end
      end,
      e.start_val,
      {{e.end_val,e.fall_stage_time}},
      30
    )
  end
end

function levels.pad_envelope(b,p)
  
end

return levels