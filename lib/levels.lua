local levels = {}

function levels.set_up_rise(b,p)
  level_envelope_metro[b]:stop()

  softcut.level_slew_time(b+1,0.01)
  local e = bank[b].level_envelope
  -- local shape = bank[b][p].level_envelope.rise_stage_shape
  local shape = easingFunctions.easingNames[bank[b][p].level_envelope.rise_stage_shape_index]
  e.start_val = 0
  e.end_val = bank[b][p].level
  e.direction = "rising"
  
  if bank[b][p].level_envelope.rise_stage_time == 0 then
    softcut.level(b+1,bank[b][p].level*bank[b].global_level)
    softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*bank[b][bank[b].id].level)*bank[b].global_level)
    softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*bank[b][bank[b].id].level)*bank[b].global_level)
    levels.set_up_fall(b,p)
    e.active = false
  else
    e.active = true
    local frozen_target = bank[b][p].level

    -- local count = math.floor(bank[b][p].level_envelope.rise_stage_time * 60)
    local count = math.floor(bank[b][p].level_envelope.rise_stage_time * 100)
    level_envelope_metro[b].count = count
    local g_lvl = e.start_val
    local step_size = (e.end_val - g_lvl) / count
    local passing_val = easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level
    if passing_val == passing_val and not bank[b][p].pause then -- avoids nan
      print(b+1,easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
      softcut.level(b+1,easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
      softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*frozen_target)*easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
      softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*frozen_target)*easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
    end
    level_envelope_metro[b].event = function()
      g_lvl = g_lvl + step_size
      if bank[b].level_lfo ~= nil and bank[b].level_lfo.active ~= nil and bank[b].level_lfo.active then
      else
        local passing_val = easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level
        if passing_val == passing_val and not bank[b][p].pause then -- avoids nan
          print(b+1,easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level) -- do the action
          softcut.level(b+1,easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
          softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*frozen_target)*easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
          softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*frozen_target)*easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
        end
      end
      -- print(easingFunctions[shape](g_lvl,0,bank[b][p].level,1))
      e.current_value = util.round(g_lvl,0.0001)
      if util.round(g_lvl,0.01) == util.round(frozen_target,0.01) then
        -- print("RISE LEVEL FUNNEL DONE",e.current_value,e.direction)
        e.mute_active = false
        if bank[b][p].level_envelope.fall_stage_active and e.active then
          levels.set_up_fall(b,p)
          -- print("should be falling...")
        else
          e.active = false
        end
      end
    end

    level_envelope_metro[b]:start()
  end
end

function levels.set_up_fall(b,p)
  level_envelope_metro[b]:stop()
  
  softcut.level_slew_time(b+1,0.01)
  local e = bank[b].level_envelope
  -- local shape = bank[b][p].level_envelope.fall_stage_shape
  local shape = easingFunctions.easingNames[bank[b][p].level_envelope.fall_stage_shape_index]
  e.start_val = bank[b][p].level
  e.end_val = 0
  e.direction = "falling"
  e.active = true
  local frozen_target = bank[b][p].level

  -- local count = math.floor(bank[b][p].level_envelope.fall_stage_time * 60)
  local count = math.floor(bank[b][p].level_envelope.fall_stage_time * 100)
  level_envelope_metro[b].count = count
  local g_lvl = e.start_val
  local step_size = (e.end_val - g_lvl) / count
  local passing_val = easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level
  if passing_val == passing_val and not bank[b][p].pause then -- avoids nan
    print("FALL",b+1,easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
    -- print(easingFunctions[shape](g_lvl,0,bank[b][p].level,1),util.time()) -- do the action
    softcut.level(b+1,easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
    softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*frozen_target)*easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
    softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*frozen_target)*easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
  end
  level_envelope_metro[b].event = function()
    g_lvl = g_lvl + step_size
    if bank[b].level_lfo ~= nil and bank[b].level_lfo.active ~= nil and bank[b].level_lfo.active then
    else
      local passing_val = easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level
      if passing_val == passing_val and not bank[b][p].pause then -- avoids nan
        print("FALL",b+1,easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
        softcut.level(b+1,easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
        softcut.level_cut_cut(b+1,5,(bank[b][bank[b].id].left_delay_level*frozen_target)*easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
        softcut.level_cut_cut(b+1,6,(bank[b][bank[b].id].right_delay_level*frozen_target)*easingFunctions[shape](g_lvl,0,frozen_target,frozen_target)*bank[b].global_level)
      end
    end
    e.current_value = util.round(g_lvl,0.0001)
    if util.round(g_lvl,0.01) == 0 then
      -- print("FALL LEVEL FUNNEL DONE",e.current_value)
      e.active = false
      e.mute_active = true
      if bank[b][p].level_envelope.loop then
        levels.set_up_rise(b,p)
      else
      end
    end
  end

  level_envelope_metro[b]:start()
end

function levels.pad_envelope(b,p)
  
end

function levels.return_current_funnel_value(i)
  local b = bank[i].level_envelope
  -- local shape = params:string("bank "..i.." fnl shape")
  return(b.current_value)
end

return levels