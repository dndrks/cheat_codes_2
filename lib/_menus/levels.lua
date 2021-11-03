local levels_menu = {}

local _l = levels_menu
local focused_pad = {nil,nil,nil}
local _l_ = nil
local lfo_rates = {["names"] = {}, ["values"] = {}}
lfo_rates.names = {
  "1/32",
  "1/16",
  "1/12",
  "1/8",
  "1/6",
  "3/16",
  "1/4",
  "5/16",
  "1/3",
  "3/8",
  "1/2",
  "3/4",
  "1",
  "1.5",
  "2",
  "3",
  "4",
  "6",
  "8",
  "16",
  "32"
}
lfo_rates.values = {
  1/32,
  1/16,
  1/12,
  1/8,
  1/6,
  3/16,
  1/4,
  5/16,
  1/3,
  3/8,
  1/2,
  3/4,
  1,
  1.5,
  2,
  3,
  4,
  6,
  8,
  16,
  32
}

function _l.init()
  page.levels = {}
  page.levels.regions = {"pad_level","bank_level","pad_env","pad_repeat","rise_time","rise_shape","fall_time","fall_shape"}
  page.levels.selected_region = "pad_level"
  page.levels.sel = 1
  page.levels.bank = 1
  page.levels.alt_view = false
  page.levels.alt_view_sel = 1
  page.levels.meta_pad = {1,1,1}
  _l_ = page.levels
end

function _l.reset_view()
  page.levels.alt_view = false
  page.levels.alt_view_sel = 1
end

function _l.draw_menu()
  for i = 1,3 do
    if bank[i].focus_hold == true then
      focused_pad[i] = bank[i].focus_pad
    else
      focused_pad[i] = bank[i].id
    end
  end
  _l.draw_side()
  _l.draw_header()
  if not _l_.alt_view then
    _l.draw_levels()
    _l.draw_env()
    _l.draw_repeat()
    _l.draw_time()
    -- _l.draw_lfo_active()
    -- _l.draw_lfo_shape()
    -- _l.draw_lfo_freq()
  elseif _l_.alt_view then
    _l.draw_alt_view()
  end
end

function _l.draw_header()
  screen.level(15)
  screen.move(0,10)
  screen.line(128,10)
  screen.stroke()
  screen.move(3,6)
  screen.level(15)
  screen.text("levels")
  -- if _l_.alt_view then
  --   screen.move(128,6)
  --   screen.text_right("LFO UTILITIES")
  -- end
end

function _l.draw_alt_view()
  screen.level(15)
  screen.move(128,6)
  screen.text_right("PER-PAD VALUES")
  local f = _l_.meta_pad[_l_.bank]
  screen.level(_l_.alt_view_sel == 1 and 15 or 3)
  screen.move(26,20)
  screen.text("PAD: "..f)
  screen.level(_l_.alt_view_sel == 2 and 15 or 3)
  screen.move(26,30)
  screen.text("LEVEL: "..util.round(bank[_l_.bank][f].level,(#arc.devices > 0 and 0.001 or 0.01)))
  local x_positions = {33,60,88}

  local shapes = {"\\","/","/\\"}

  local text_to_display =
  {
    "ENV",
    "LOOP",
    "RISE",
    "shape",
    "FALL",
    "shape"
  }
  local data_to_display =
  {
    bank[_l_.bank][f].enveloped == true and (shapes[bank[_l_.bank][f].envelope_mode]) or "off",
    bank[_l_.bank][f].level_envelope.loop == true and "on" or "off",
    lfo_rates.names[bank[_l_.bank][f].level_envelope.fall_time_index]
  }
  for i = 1,3 do
    screen.level(_l_.alt_view_sel == i+2 and 15 or 3)
    screen.move(x_positions[i],40)
    screen.text_center(text_to_display[i])
    screen.move(x_positions[i],50)
    screen.text_center(data_to_display[i])
  end
  screen.level(_l_.alt_view_sel == 6 and 15 or (_l_.alt_view_sel == 7 and 15 or 3))
  screen.move(26,60)
  screen.text("RANDOMIZE: ")
  screen.level(_l_.alt_view_sel == 6 and 15 or 3)
  screen.move(80,60)
  screen.text("pad")
  screen.level(_l_.alt_view_sel == 7 and 15 or 3)
  screen.move(122,60)
  screen.text_right("bank")
end

function _l.draw_side()
  local modifier;
  local level_to_screen_options = {"a"..focused_pad[1], "b"..focused_pad[2], "c"..focused_pad[3]}
  local y_pos = {21,38,55}
  for i = 1, #level_to_screen_options do
    screen.level(i == _l_.bank and 15 or 3)
    screen.move(10,y_pos[i])
    screen.text_center(level_to_screen_options[i])
  end
  _l.draw_boundaries()
end

function _l.draw_levels()

  screen.level(_l_.selected_region == "pad_level" and 15 or 3)
  screen.move(35,18)
  if (_l_.selected_region == "pad_env" or 
  _l_.selected_region == "pad_repeat" or
  _l_.selected_region == "rise_time" or 
  _l_.selected_region == "rise_shape" or 
  _l_.selected_region == "fall_time" or 
  _l_.selected_region == "fall_shape") 
  and bank[_l_.bank].focus_hold then
    screen.text_center("[PAD]")
  else
    screen.text_center("PAD")
  end
  for i = 1,9 do
    screen.level(3)
    screen.move(25,22+(i*4))
    screen.text("_")
    screen.move(40,22+(i*4))
    screen.text("_")
  end
  local pad_level_to_screen;
  local pad_lfo_level_to_screen;
  if bank[_l_.bank][focused_pad[_l_.bank]].level < 1.1 then
    pad_level_to_screen = util.linlin(0,1,0,25,bank[_l_.bank][focused_pad[_l_.bank]].level)
    -- pad_lfo_level_to_screen = util.linlin(0,bank[_l_.bank][focused_pad[_l_.bank]].level,58,33,bank[_l_.bank].level_lfo.slope)
  else
    pad_level_to_screen = util.linlin(1,2,25,33,bank[_l_.bank][focused_pad[_l_.bank]].level)
    -- pad_lfo_level_to_screen = util.linlin(0,bank[_l_.bank][focused_pad[_l_.bank]].level,33,25,bank[_l_.bank].level_lfo.slope)
  end
  for i = 1,3 do
    screen.move(33+i,58)
    screen.line(33+i,58-pad_level_to_screen)
    screen.close()
    screen.stroke()
  end

  screen.level(_l_.selected_region == "bank_level" and 15 or 3)
  screen.move(65,18)
  if (_l_.selected_region ~= "pad_level" and  _l_.selected_region ~= "bank_level") and not bank[_l_.bank].focus_hold then
    screen.text_center("[BANK]")
  else
    if _l_.selected_region == "bank_lfo_active" or  _l_.selected_region == "bank_lfo_shape" or  _l_.selected_region == "bank_lfo_freq" and bank[_l_.bank].focus_hold then
      screen.text_center("[BANK]")
    else
      screen.text_center("BANK")
    end
  end
  for i = 1,9 do
    screen.level(3)
    screen.move(56,22+(i*4))
    screen.text("_")
    screen.move(71,22+(i*4))
    screen.text("_")
  end
  local bank_level_to_screen;
  if bank[_l_.bank].global_level < 1.1 then
    bank_level_to_screen = util.linlin(0,1,0,25,bank[_l_.bank].global_level)
  else
    bank_level_to_screen = util.linlin(1,2,25,33,bank[_l_.bank].global_level)
  end
  for i = 1,3 do
    screen.move(64+i,58)
    screen.line(64+i,58-bank_level_to_screen)
    screen.close()
    screen.stroke()
  end
end

function _l.draw_env()
  screen.level(_l_.selected_region == "pad_env" and 15 or 3)
  screen.move(84,18)
  local shapes = {"FALL","RISE","RISE/FALL"}
  if bank[_l_.bank][focused_pad[_l_.bank]].enveloped then
    screen.text(shapes[bank[_l_.bank][focused_pad[_l_.bank]].envelope_mode])
  else
    screen.text("ENV: NONE")
  end
end

function _l.draw_repeat()
  screen.level(_l_.selected_region == "pad_repeat" and 15 or 3)
  screen.move(84,26)
  if bank[_l_.bank][focused_pad[_l_.bank]].level_envelope.loop then
    screen.text("LOOP: on")
  else
    screen.text("LOOP: off")
  end
end

function _l.draw_time()
  screen.level(_l_.selected_region == "rise_time" and 15 or 3)
  screen.move(84,34)
  screen.text("RISE: "..lfo_rates.names[bank[_l_.bank][focused_pad[_l_.bank]].level_envelope.rise_time_index])
  screen.level(_l_.selected_region == "rise_shape" and 15 or 3)
  screen.move(84,42)
  screen.text("")
  screen.level(_l_.selected_region == "fall_time" and 15 or 3)
  screen.move(84,50)
  screen.text("FALL: "..lfo_rates.names[bank[_l_.bank][focused_pad[_l_.bank]].level_envelope.fall_time_index])
  screen.level(_l_.selected_region == "fall_shape" and 15 or 3)
  screen.move(84,58)
  screen.text("")
end


function _l.draw_lfo_active()
  screen.level(_l_.selected_region == "bank_lfo_active" and 15 or 3)
  screen.move(84,44)
  screen.text("LFO: "..(bank[_l_.bank].level_lfo.active == true and "on" or "off"))
end

function _l.draw_lfo_shape()
  screen.level(_l_.selected_region == "bank_lfo_shape" and 15 or 3)
  screen.move(84,52)
  screen.text("SHP: "..bank[_l_.bank].level_lfo.waveform)
end

function _l.draw_lfo_freq()
  screen.level(_l_.selected_region == "bank_lfo_freq" and 15 or 3)
  screen.move(84,60)
  screen.text("RATE: "..lfo_rates.names[bank[_l_.bank].level_lfo.rate_index])
end

function _l.draw_boundaries()
  screen.level(15)
  screen.move(1,10)
  screen.line(1,64)
  screen.stroke()
  screen.move(128,10)
  screen.line(128,64)
  screen.stroke()
  screen.move(0,64)
  screen.line(128,64)
  screen.stroke()
  screen.move(20,10)
  screen.line(20,64)
  screen.stroke()
  if not _l_.alt_view then
    screen.move(50,10)
    screen.line(50,64)
    screen.stroke()
    screen.move(81,10)
    screen.line(81,64)
    screen.stroke()
    -- screen.move(80,37)
    -- screen.line(128,37)
    -- screen.stroke()
  end
end

function _l.process_encoder(n,d)
  local b = bank[_l_.bank]
  local f = focused_pad[_l_.bank]
  if n == 1 then
    _l_.bank = util.clamp(_l_.bank + d,1,3)
  elseif n == 2 then
    if _l_.alt_view then
      _l_.alt_view_sel = util.clamp(_l_.alt_view_sel+d,1,7)
    else
      local current_area = tab.key(_l_.regions,_l_.selected_region)
      current_area = util.clamp(current_area+d,1,#_l_.regions)
      _l_.selected_region = _l_.regions[current_area]
    end
  elseif n == 3 then
    if _l_.alt_view then
      _l.process_meta_encoder(n,d)
    else
      if _l_.selected_region == "pad_level" or _l_.selected_region == "bank_level" then
        if _l_.selected_region == "bank_level" then
          if b.global_level < 0.4 then
            b.global_level = util.clamp(b.global_level+d/50,0,2)
          elseif b.global_level >= 1.3 then
            b.global_level = util.clamp(b.global_level+d/25,0,2)
          else
            b.global_level = util.clamp(b.global_level+d/20,0,2)
          end
        elseif _l_.selected_region == "pad_level" then
          if b[f].level < 0.4 then
            b[f].level = util.clamp(b[f].level+d/50,0,2)
          elseif b[f].level >= 1.3 then
            b[f].level = util.clamp(b[f].level+d/25,0,2)
          else
            b[f].level = util.clamp(b[f].level+d/20,0,2)
          end
          if _l_.selected_region == "pad_level" then
            if b[f].enveloped and not b[f].pause and b.focus_hold == false then
              -- if b.level_envelope.active then
              --   if b.level_envelope.direction == "rising" then
              --     b.level_envelope.end_val = b[f].level
              --     print("changing rise")
              --   elseif b.level_envelope.direction == "falling" then
              --     b.level_envelope.start_val = b[f].level
              --   end
              -- end
            end
          end
        end
        if b[b.id].envelope_mode == 2 or b[b.id].enveloped == false then
          if b.focus_hold == false then
            softcut.level_slew_time(_l_.bank+1,1.0)
            -- softcut.level(_l_.bank+1,b[b.id].level*b.global_level)
            softcut.level(_l_.bank+1,b[b.id].level*_l.get_global_level(_l_.bank))
            -- softcut.level_cut_cut(_l_.bank+1,5,(b[b.id].left_delay_level*b[b.id].level)*b.global_level)
            -- softcut.level_cut_cut(_l_.bank+1,6,(b[b.id].right_delay_level*b[b.id].level)*b.global_level)
            softcut.level_cut_cut(_l_.bank+1,5,(b[b.id].left_delay_level*b[b.id].level)*_l.get_global_level(_l_.bank))
            softcut.level_cut_cut(_l_.bank+1,6,(b[b.id].right_delay_level*b[b.id].level)*_l.get_global_level(_l_.bank))
          end
        end

      elseif _l_.selected_region == "pad_env" then

        local pre_enveloped = b[f].enveloped
        local pre_mode = b[f].envelope_mode
        b[f].envelope_mode = util.clamp(b[f].envelope_mode + d,0,3)
        
        if b[f].envelope_mode == 0 then
          b[f].enveloped = false
          b[f].level_envelope.rise_stage_active = false
          b[f].level_envelope.fall_stage_active = false
          if b.id == f then
            softcut.level_slew_time(_l_.bank+1,1.0)
            softcut.level(_l_.bank+1,b[b.id].level*_l.get_global_level(_l_.bank))
            softcut.level_cut_cut(_l_.bank+1,5,(b[b.id].left_delay_level*b[b.id].level)*_l.get_global_level(_l_.bank))
            softcut.level_cut_cut(_l_.bank+1,6,(b[b.id].right_delay_level*b[b.id].level)*_l.get_global_level(_l_.bank))
          end
        else
          if b[f].envelope_mode == 1 then
            print(f)
            b[f].level_envelope.fall_stage_active = true
            b[f].level_envelope.rise_stage_active = false
          elseif b[f].envelope_mode == 2 then
            b[f].level_envelope.rise_stage_active = true
            b[f].level_envelope.fall_stage_active = false
          elseif b[f].envelope_mode == 3 then
            b[f].level_envelope.rise_stage_active = true
            b[f].level_envelope.fall_stage_active = true
          end
          b[f].enveloped = true
          if pre_enveloped ~= b[f].enveloped then
            if bank[_l_.bank].focus_hold == false then
              -- cheat(_l_.bank, bank[_l_.bank].id)
            end
          elseif pre_mode ~= b[f].envelope_mode then
            if bank[_l_.bank].focus_hold == false then
              -- cheat(_l_.bank, bank[_l_.bank].id)
            end
          end
        end
        if bank[_l_.bank].focus_hold == false then
          _l.pass_to_all(_l_.bank,f,{"enveloped"})
          _l.pass_to_all(_l_.bank,f,{"envelope_mode"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","rise_stage_active"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","fall_stage_active"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","rise_stage_time"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","fall_stage_time"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","rise_time_index"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","fall_time_index"})
        end
      elseif _l_.selected_region == "pad_repeat" then
        local pre_loop = b[f].level_envelope.loop
        if d>0 then
          b[f].level_envelope.loop = true
          if pre_loop ~= b[f].level_envelope.loop then
            if bank[_l_.bank].focus_hold == false and b[f].enveloped then
              -- cheat(_l_.bank, bank[_l_.bank].id)
            end
          end
        else
          b[f].level_envelope.loop = false
        end
        if bank[_l_.bank].focus_hold == false then
          _l.pass_to_all(_l_.bank,f,{"level_envelope","loop"})
        end
      elseif _l_.selected_region == "rise_time" then
        b[f].level_envelope.rise_time_index = util.clamp(b[f].level_envelope.rise_time_index + d,1,#lfo_rates.values)
        b[f].level_envelope.rise_stage_time = (clock.get_beat_sec() * lfo_rates.values[b[f].level_envelope.rise_time_index]) * 4
        -- if b.id == f and b[f].level > 0.05 then
        --   env_counter[b[f].bank_id].time = (b[f].envelope_time/(b[f].level/0.05))
        -- end
        if bank[_l_.bank].focus_hold == false then
          _l.pass_to_all(_l_.bank,f,{"envelope_rate_index"})
          _l.pass_to_all(_l_.bank,f,{"envelope_time"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","rise_stage_active"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","fall_stage_active"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","rise_stage_time"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","fall_stage_time"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","rise_time_index"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","fall_time_index"})
        end
      elseif _l_.selected_region == "fall_time" then
        b[f].level_envelope.fall_time_index = util.clamp(b[f].level_envelope.fall_time_index + d,1,#lfo_rates.values)
        b[f].level_envelope.fall_stage_time = (clock.get_beat_sec() * lfo_rates.values[b[f].level_envelope.fall_time_index]) * 4
        -- if b.id == f and b[f].level > 0.05 then
        --   env_counter[b[f].bank_id].time = (b[f].envelope_time/(b[f].level/0.05))
        -- end
        if bank[_l_.bank].focus_hold == false then
          _l.pass_to_all(_l_.bank,f,{"envelope_rate_index"})
          _l.pass_to_all(_l_.bank,f,{"envelope_time"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","rise_stage_active"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","fall_stage_active"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","rise_stage_time"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","fall_stage_time"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","rise_time_index"})
          _l.pass_to_all(_l_.bank,f,{"level_envelope","fall_time_index"})
        end
      elseif _l_.selected_region == "bank_lfo_active" then
        -- b.level_lfo.active = d > 0 and true or false
        params:set("level_lfo_active_".._l_.bank,d > 0 and 2 or 1)
      elseif _l_.selected_region == "bank_lfo_shape" then
        local current_index = tab.key(lfo_types,b.level_lfo.waveform)
        current_index = util.clamp(current_index + d,1,#lfo_types)
        -- b.level_lfo.waveform = lfo_types[current_index]
        params:set("level_lfo_waveform_".._l_.bank,current_index)
      elseif _l_.selected_region == "bank_lfo_freq" then
        b.level_lfo.rate_index = util.clamp(b.level_lfo.rate_index + d,1,#lfo_rates.values)
        -- b.level_lfo.freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[b.level_lfo.rate_index])
        params:set("level_lfo_rate_".._l_.bank,b.level_lfo.rate_index)
      end
    end
  end
end

function _l.process_meta_encoder(n,d)
  local b = bank[_l_.bank]
  local _f = _l_.meta_pad[_l_.bank]
  local f = focused_pad[_l_.bank]
  if n == 3 then
    if _l_.alt_view_sel == 1 then
      _l_.meta_pad[_l_.bank] = util.clamp(_l_.meta_pad[_l_.bank]+d,1,16)
    elseif _l_.alt_view_sel == 2 then
      if b[_f].level < 0.4 then
        b[_f].level = util.clamp(b[_f].level+d/50,0,2)
      elseif b[_f].level >= 1.3 then
        b[_f].level = util.clamp(b[_f].level+d/25,0,2)
      else
        b[_f].level = util.clamp(b[_f].level+d/20,0,2)
      end
      if _f == f then
        if b[f].enveloped == false then
          softcut.level_slew_time(_l_.bank+1,1.0)
          softcut.level(_l_.bank+1,b[f].level*_l.get_global_level(_l_.bank))
          softcut.level_cut_cut(_l_.bank+1,5,(b[f].left_delay_level*b[f].level)*_l.get_global_level(_l_.bank))
          softcut.level_cut_cut(_l_.bank+1,6,(b[f].right_delay_level*b[f].level)*_l.get_global_level(_l_.bank))
        end
      end
    elseif _l_.alt_view_sel == 3 then
      local pre_enveloped = b[_f].enveloped
      local pre_mode = b[_f].envelope_mode
      b[_f].envelope_mode = util.clamp(b[_f].envelope_mode + d,0,3)
      
      if b[_f].envelope_mode == 0 then
        b[_f].enveloped = false
        b[_f].level_envelope.rise_stage_active = false
        b[_f].level_envelope.fall_stage_active = false
        if b.id == f then
          softcut.level_slew_time(_l_.bank+1,1.0)
          softcut.level(_l_.bank+1,b[b.id].level*_l.get_global_level(_l_.bank))
          softcut.level_cut_cut(_l_.bank+1,5,(b[b.id].left_delay_level*b[b.id].level)*_l.get_global_level(_l_.bank))
          softcut.level_cut_cut(_l_.bank+1,6,(b[b.id].right_delay_level*b[b.id].level)*_l.get_global_level(_l_.bank))
        end
      else
        if b[_f].envelope_mode == 1 then
          b[_f].level_envelope.fall_stage_active = true
          b[_f].level_envelope.rise_stage_active = false
        elseif b[_f].envelope_mode == 2 then
          b[_f].level_envelope.rise_stage_active = true
          b[_f].level_envelope.fall_stage_active = false
        elseif b[_f].envelope_mode == 3 then
          b[_f].level_envelope.rise_stage_active = true
          b[_f].level_envelope.fall_stage_active = true
        end
        b[_f].enveloped = true
      end
    elseif _l_.alt_view_sel == 4 then
      local pre_loop = b[_f].level_envelope.loop
      if d>0 then
        b[_f].level_envelope.loop = true
        if pre_loop ~= b[f].level_envelope.loop and f == _f then
          if bank[_l_.bank].focus_hold == false and b[f].enveloped then
            -- cheat(_l_.bank, f)
          end
        end
      else
        b[_f].level_envelope.loop = false
      end
    elseif _l_.alt_view_sel == 5 then
      b[_f].envelope_rate_index = util.clamp(b[_f].envelope_rate_index + d,1,#lfo_rates.values)
      b[_f].envelope_time = (clock.get_beat_sec() * lfo_rates.values[b[_f].envelope_rate_index]) * 4
      if b.id == f and b[f].level > 0.05 and f == _f then
        env_counter[b[f].bank_id].time = (b[f].envelope_time/(b[f].level/0.05))
      end
    end
  end
end

function _l.pass_to_all(bank_id,f,param)
  for i = 1,16 do
    if i ~= f then
      if #param == 1 then
        bank[bank_id][i][param[1]] = bank[bank_id][f][param[1]]
      else
        bank[bank_id][i][param[1]][param[2]] = bank[bank_id][f][param[1]][param[2]]
      end
    end
  end
end

function _l.send_to_softcut(b,i,param)

end

function _l.get_global_level(id)
  if bank[id].level_envelope.active then
    return _levels.return_current_funnel_value(id)
  else
    if not bank[id].level_envelope.mute_active then
      return bank[id].global_level
    else
      return 0
    end
  end
end

function _l.get_pad_level(b,p)
  if bank[b][p].level_envelope.active then
    if bank[b][p].level_lfo.active then
      return util.linlin(-1,1,0,_levels.return_current_funnel_value(id),bank[b][p].level_lfo.slope)
    else
      return _levels.return_current_funnel_value(id)
    end
  else
    if bank[b][p].level_lfo.active and not bank[b][p].level_envelope.mute_active then
      return util.linlin(-1,1,0,bank[b][p].global_level,bank[b][p].level_lfo.slope)
    elseif not bank[b][p].level_envelope.mute_active then
      return bank[b][p].global_level
    elseif bank[b][p].level_envelope.mute_active then
      return 0
    end
  end
end

function _l.calc_delay_sends(b,p,side_table)
  for i = 1,#side_table do
    if side_table[i] == "L" then
      softcut.level_cut_cut(b+1,5,(bank[b][p].left_delay_level*bank[b][p].level)*_l.get_global_level(b))
    else
      softcut.level_cut_cut(b+1,6,(bank[b][p].right_delay_level*bank[b][p].level)*_l.get_global_level(b))
    end
  end    
  -- softcut.level_cut_cut(b+1,5,(bank[b][p].left_delay_level*bank[b][p].level)*_l.get_global_level(b))
  -- softcut.level_cut_cut(b+1,6,(bank[b][p].right_delay_level*bank[b][p].level)*_l.get_global_level(b))
end

function _l.process_key(n,z)
  if n == 1 and z == 1 then
    _l_.alt_view = not _l_.alt_view
    if _l_.alt_view then
      -- _l_.meta_pad[_l_.bank] = focused_pad[_l_.bank]
    end
  elseif n == 3 and z == 1 and _l_.alt_view then
    if _l_.alt_view_sel == 6 then
      _l.meta_actions("randomize_this_pad")
    elseif _l_.alt_view_sel == 7 then
      _l.meta_actions("randomize_this_bank")
    end
  elseif n == 2 and z == 1 then
    menu = 1
  end
end

return levels_menu