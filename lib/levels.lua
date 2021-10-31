local levels = {}

function levels.rise(b,p)
  softcut.level_slew_time(b+1,0.01)
  -- local e = bank[b][p].level_envelope
  local e = bank[b].level_envelope
  local shape = "linear"
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
  -- if e.rise_stage_time == 0 then
  if bank[b][p].level_envelope.rise_stage_time == 0 then
    softcut.level(b+1,bank[b][p].level*bank[b].global_level)
    softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*bank[b][bank[b].id].level)*bank[b].global_level)
    softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*bank[b][bank[b].id].level)*bank[b].global_level)
    levels.fall(b,p)
    e.active = false
  else
    e.active = true
    local frozen_target = bank[b][p].level
    e.fnl = _live.fnl(
      function(g_lvl)
        if bank[b].level_lfo ~= nil and bank[b].level_lfo.active ~= nil and bank[b].level_lfo.active then
          -- softcut.level(i+1,easingFunctions[shape](g_lvl*bank[b].level_lfo.slope,0,bank[b][p].level,1))
        else
          -- softcut.level(b+1,easingFunctions[shape](g_lvl,0,bank[b][p].level*bank[b].global_level,bank[b][p].level*bank[b].global_level))
          softcut.level(b+1,easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
          softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*frozen_target)*easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
          softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*frozen_target)*easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
        end
        -- print(easingFunctions[shape](g_lvl,0,bank[b][p].level,1))
        e.current_value = util.round(g_lvl,0.0001)
        if util.round(g_lvl,0.01) == util.round(frozen_target,0.01) then
          -- print("RISE LEVEL FUNNEL DONE",e.current_value,e.direction)
          e.mute_active = false
          if bank[b][p].level_envelope.fall_stage_active and e.active then
            levels.fall(b,p)
            -- print("should be falling...")
          else
            e.active = false
          end
        end
      end,
      e.start_val,
      -- {{e.end_val,e.direction == "falling" and util.clamp(params:get("bank "..i.." fnl fall"),0.1,120) or util.clamp(params:get("bank "..i.." fnl rise"),0.1,120)}}
      -- {{e.end_val,e.rise_stage_time}},
      {{e.end_val,bank[b][p].level_envelope.rise_stage_time}},
      60
    )
  end
end

function levels.fall(b,p)
  softcut.level_slew_time(b+1,0.01)
  -- local e = bank[b][p].level_envelope
  local e = bank[b].level_envelope
  local shape = "inExpo"
  if e.fnl ~= nil then
    clock.cancel(e.fnl)
  end
  if e.active then -- if the funnel is interrupted...
    e.start_val = e.current_value
    e.direction = e.direction == "falling" and "rising" or "falling"
    e.end_val = e.direction == "falling" and 0 or bank[b][p].level
  else
    -- print("no prev active")
    e.start_val = bank[b][p].level
    e.end_val = 0
    e.direction = "falling"
  end
  if bank[b][p].level_envelope.fall_stage_time == 0 then
    softcut.level(b+1,bank[b][p].level*bank[b].global_level)
    softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*bank[b][bank[b].id].level)*bank[b].global_level)
    softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*bank[b][bank[b].id].level)*bank[b].global_level)
    e.active = false
  else
    e.active = true
    local frozen_target = bank[b][p].level
    e.fnl = _live.fnl(
      function(g_lvl)
        if bank[b].level_lfo ~= nil and bank[b].level_lfo.active ~= nil and bank[b].level_lfo.active then
          -- softcut.level(i+1,easingFunctions[shape](g_lvl*bank[b].level_lfo.slope,0,bank[b][p].level,1))
        else
          softcut.level(b+1,easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
          softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*frozen_target)*easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
          softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*frozen_target)*easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
        end
        -- print(easingFunctions[shape](g_lvl,0,bank[b][p].level,1))
        e.current_value = util.round(g_lvl,0.0001)
        if util.round(g_lvl,0.01) == 0 then
          -- print("FALL LEVEL FUNNEL DONE",e.current_value)
          e.active = false
          e.mute_active = true
          if bank[b][p].level_envelope.loop then
            levels.rise(b,p)
          else
            -- e.mute_active = true
          end
        end
      end,
      e.start_val,
      {{e.end_val, bank[b][p].level_envelope.fall_stage_time}},
      60
    )
  end
end

function levels.pad_envelope(b,p)
  
end

function levels.return_current_funnel_value(i)
  local b = bank[i].level_envelope
  -- local shape = params:string("bank "..i.." fnl shape")
  return(b.current_value)
end

return levels