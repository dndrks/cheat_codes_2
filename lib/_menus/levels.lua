local levels_menu = {}

local _l = levels_menu
local focused_pad = {nil,nil,nil}
local _l_ = nil

function _l.init()
  page.levels = {}
  page.levels.regions = {"pad_level","bank_level","pad_env","pad_repeat","pad_time","bank_env","bank_repeat","bank_time"}
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
  _l.draw_levels()
  _l.draw_env()
  _l.draw_repeat()
  _l.draw_time()
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

-- function _l.draw_alt_view()
--   screen.level(_l_.alt_view_sel == 1 and 15 or 3)
--   screen.move(26,20)
--   screen.text("SOURCE:")
--   screen.move(122,20)
--   screen.text_right("pad ".._l_.meta_pad[_l_.bank])
--   screen.level(_l_.alt_view_sel == 2 and 15 or (_l_.alt_view_sel == 3 and 15 or 3))
--   screen.move(26,30)
--   screen.text("COPY TO:")
--   screen.level(_l_.alt_view_sel == 2 and 15 or 3)
--   screen.move(122,30)
--   screen.text_right("unassigned")
--   screen.level(_l_.alt_view_sel == 3 and 15 or 3)
--   screen.move(122,40)
--   screen.text_right("entire bank")
--   screen.level(_l_.alt_view_sel == 4 and 15 or (_l_.alt_view_sel == 5 and 15 or 3))
--   screen.move(26,50)
--   screen.text("RANDOMIZE: ")
--   screen.level(_l_.alt_view_sel == 4 and 15 or 3)
--   screen.move(122,50)
--   screen.text_right("this pad")
--   screen.level(_l_.alt_view_sel == 5 and 15 or 3)
--   screen.move(122,60)
--   screen.text_right("entire bank")
-- end

function _l.draw_side()
  local modifier;
  local level_to_screen_options = {"a"..focused_pad[1], "b"..focused_pad[2], "c"..focused_pad[3],"#"}
  for i = 1, #level_to_screen_options do
    screen.level(i == _l_.bank and 15 or 3)
    screen.move(10,20+((i-1)*13))
    screen.text_center(level_to_screen_options[i])
  end
  _l.draw_boundaries()
end

function _l.draw_levels()

  screen.level(_l_.selected_region == "pad_level" and 15 or 3)
  screen.move(35,18)
  if _l_.selected_region == "pad_env" or  _l_.selected_region == "pad_repeat" or  _l_.selected_region == "pad_time" then
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
  -- if focused_pad[_l_.bank] == bank[_l_.bank].id then
  --   screen.move(40,pad_lfo_level_to_screen)
  --   screen.text_center("_")
  -- end

  screen.level(_l_.selected_region == "bank_level" and 15 or 3)
  screen.move(65,18)
  if _l_.selected_region == "bank_env" or  _l_.selected_region == "bank_repeat" or  _l_.selected_region == "bank_time" then
    screen.text_center("[BANK]")
  else
    screen.text_center("BANK")
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
  -- screen.rect(32,60,6,level_to_screen)
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
  local shapes = {"\\","/","/\\"}
  if bank[_l_.bank][focused_pad[_l_.bank]].enveloped then
    screen.text("ENV: "..shapes[bank[_l_.bank][focused_pad[_l_.bank]].envelope_mode])
  else
    screen.text("ENV: off")
  end
  screen.level(_l_.selected_region == "bank_env" and 15 or 3)
  screen.move(84,44)
  local shapes = {"\\","/","/\\"}
  if bank[_l_.bank][focused_pad[_l_.bank]].enveloped then
    screen.text("ENV: "..shapes[bank[_l_.bank][focused_pad[_l_.bank]].envelope_mode])
  else
    screen.text("ENV: off")
  end
end

function _l.draw_repeat()
  screen.level(_l_.selected_region == "pad_repeat" and 15 or 3)
  screen.move(84,26)
  if bank[_l_.bank][focused_pad[_l_.bank]].envelope_loop then
    screen.text("LOOP: on")
  else
    screen.text("LOOP: off")
  end
  screen.level(_l_.selected_region == "bank_repeat" and 15 or 3)
  screen.move(84,52)
  if bank[_l_.bank][focused_pad[_l_.bank]].envelope_loop then
    screen.text("LOOP: on")
  else
    screen.text("LOOP: off")
  end
end

function _l.draw_time()
  screen.level(_l_.selected_region == "pad_time" and 15 or 3)
  screen.move(84,34)
  screen.text("DUR: "..lfo_rates.names[bank[_l_.bank][focused_pad[_l_.bank]].envelope_rate_index])
  screen.level(_l_.selected_region == "bank_time" and 15 or 3)
  screen.move(84,60)
  screen.text("TIME: 1/8")
end

-- function _l.draw_lfo()
--   screen.level(15)
--   --four sections, 20 to 128: 21.6 each
--   local x_positions = {47,75,101}
--   for i = 1,3 do
--     screen.move(x_positions[i],40)
--     screen.line(x_positions[i],64)
--     screen.stroke()
--   end
--   x_positions = {33,60,88,114}
--   local text_to_display =
--   {
--     bank[_l_.bank][focused_pad[_l_.bank]].level_lfo.active == true and "on" or "off",
--     bank[_l_.bank][focused_pad[_l_.bank]].level_lfo.waveform,
--     bank[_l_.bank][focused_pad[_l_.bank]].level_lfo.depth,
--     -- _l.freq_to_string(_l_.bank),
--     _lfos.freq_to_string(_l_.bank,"level_lfo")
--   }
--   for i = 1,4 do
--     screen.level(_l_.selected_region == _l_.regions[i+1] and 15 or 3)
--     screen.move(x_positions[i],48)
--     screen.text_center(_l_.regions[i+1])
--     screen.move(x_positions[i],58)
--     screen.text_center(text_to_display[i])
--   end
-- end

function _l.draw_boundaries()
  screen.level(15)
  screen.move(20,10)
  screen.line(20,64)
  screen.stroke()
  screen.move(1,10)
  screen.line(1,64)
  screen.stroke()
  screen.move(50,10)
  screen.line(50,64)
  screen.stroke()
  screen.move(80,10)
  screen.line(80,64)
  screen.stroke()
  screen.move(128,10)
  screen.line(128,64)
  screen.stroke()
  screen.move(0,64)
  screen.line(128,64)
  screen.stroke()
  screen.move(80,37)
  screen.line(128,37)
  screen.stroke()
  -- screen.move(80,28)
  -- screen.line(128,28)
  -- screen.stroke()
  -- screen.move(80,46)
  -- screen.line(128,46)
  -- screen.stroke()
end

function _l.process_encoder(n,d)
  local b = bank[_l_.bank]
  local f = focused_pad[_l_.bank]
  if n == 1 then
    _l_.bank = util.clamp(_l_.bank + d,1,3)
  elseif n == 2 then
    if _l_.alt_view then
      _l_.alt_view_sel = util.clamp(_l_.alt_view_sel+d,1,5)
    else
      local current_area = tab.key(_l_.regions,_l_.selected_region)
      current_area = util.clamp(current_area+d,1,#_l_.regions)
      _l_.selected_region = _l_.regions[current_area]
    end
  elseif n == 3 then
    if _l_.alt_view then
      if _l_.alt_view_sel == 1 then
        _l_.meta_pad[_l_.bank] = util.clamp(_l_.meta_pad[_l_.bank]+d,1,16)
      end
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
            if b[f].enveloped and not b[f].pause then
              if b[f].level > 0.05 then
                env_counter[n].time = (b[f].envelope_time/(b[f].level/0.05))
              end
            end
          end
        end
        if b[b.id].envelope_mode == 2 or b[b.id].enveloped == false then
          if b.focus_hold == false then
            softcut.level_slew_time(_l_.bank+1,1.0)
            softcut.level(_l_.bank+1,b[b.id].level*b.global_level)
            softcut.level_cut_cut(_l_.bank+1,5,(b[b.id].left_delay_level*b[b.id].level)*b.global_level)
            softcut.level_cut_cut(_l_.bank+1,6,(b[b.id].right_delay_level*b[b.id].level)*b.global_level)
          end
        end
      elseif _l_.selected_region == "pad_env" then

        local pre_enveloped = b[f].enveloped
        local pre_mode = b[f].envelope_mode
        b[f].envelope_mode = util.clamp(b[f].envelope_mode + d,0,3)
        
        if b[f].envelope_mode == 0 then
          b[f].enveloped = false
        else
          b[f].enveloped = true
          if pre_enveloped ~= b[f].enveloped then
            if bank[_l_.bank].focus_hold == false then
              cheat(_l_.bank, bank[_l_.bank].id)
            end
          elseif pre_mode ~= b[f].envelope_mode then
            if bank[_l_.bank].focus_hold == false then
              cheat(_l_.bank, bank[_l_.bank].id)
            end
          end
        end
      elseif _l_.selected_region == "pad_repeat" then
        if b[f].enveloped then
          local pre_loop = b[f].envelope_loop
          if d>0 then
            b[f].envelope_loop = true
            if pre_loop ~= b[f].envelope_loop then
              if bank[n].focus_hold == false then
                cheat(n, bank[n].id)
              end
            end
          else
            b[f].envelope_loop = false
          end
        end
      elseif _l_.selected_region == "pad_time" then
        b[f].envelope_rate_index = util.clamp(b[f].envelope_rate_index + d,1,#lfo_rates.values)
        b[f].envelope_time = (clock.get_beat_sec() * lfo_rates.values[b[f].envelope_rate_index]) * 4
        if b.id == f and b[f].level > 0.05 then
          env_counter[b[f].bank_id].time = (b[f].envelope_time/(b[f].level/0.05))
        end
      end
    end
  end
end

-- function _l.process_key(n,z)
--   if n == 1 and z == 1 then
--     _l_.alt_view = not _l_.alt_view
--     if _l_.alt_view then
--       _l_.meta_pad[_l_.bank] = focused_pad[_l_.bank]
--     end
--   elseif n == 3 and z == 1 and _l_.alt_view then
--     if _l_.alt_view_sel == 2 then
--       _l.meta_actions("copy_to_unassigned")
--     elseif _l_.alt_view_sel == 3 then
--       _l.meta_actions("copy_to_entire_bank")
--     elseif _l_.alt_view_sel == 4 then
--       _l.meta_actions("randomize_this_pad")
--     elseif _l_.alt_view_sel == 5 then
--       _l.meta_actions("randomize_this_bank")
--     end
--   elseif n == 2 and z == 1 then
--     menu = 1
--   end
-- end

-- function _l.meta_actions(id)
--   if id == "copy_to_unassigned" or id == "copy_to_entire_bank" then
--     for i = 1,16 do
--       if id == "copy_to_unassigned" and (i ~= _l_.meta_pad[_l_.bank] and bank[_l_.bank][i].level_lfo.active == false) or (id == "copy_to_entire_bank" and i ~= _l_.meta_pad[_l_.bank]) then
--         for k,v in pairs(bank[_l_.bank][_l_.meta_pad[_l_.bank]].level_lfo) do
--           bank[_l_.bank][i].level_lfo[k] = v
--         end
--       end
--     end
--   elseif id == "randomize_this_pad" or id == "randomize_this_bank" then
--     local reasonable_max = 16
--     for i = 1,reasonable_max do
--       if id == "randomize_this_pad" then
--         reasonable_max = 1
--         i = _l_.meta_pad[_l_.bank]
--       end
--       local random_on = math.random(0,1)
--       bank[_l_.bank][i].level_lfo.active = random_on == 0 and false or true
--       bank[_l_.bank][i].level_lfo.waveform = lfo_types[math.random(1,#lfo_types)]
--       bank[_l_.bank][i].level_lfo.depth = math.random(1,200)
--       bank[_l_.bank][i].level_lfo.rate_index = math.random(1,#lfo_rates.values)
--       bank[_l_.bank][i].level_lfo.freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[bank[_l_.bank][i].level_lfo.rate_index])
--     end
--   end
--   _l.seed_change("LFO")
--   _l.seed_change("SHP")
--   _l.seed_change("DPTH")
--   _l.seed_change("RATE")
-- end

-- function _l.seed_change(parameter)
--   local b = bank[_l_.bank]
--   local f = focused_pad[_l_.bank]
--   if parameter == "LFO" then
--     if b.id == f then
--       b.level_lfo.active = b[f].level_lfo.active
--       if not b.level_lfo.active then
--         softcut.level(_l_.bank+1,b[f].level)
--         b.level_lfo.counter = 1 -- TODO ERROR WHEN PATTERN IS GOING??
--         b.level_lfo.slope = b[f].level
--       end
--     end
--   elseif parameter == "SHP" then
--     if b.id == f then
--       b.level_lfo.waveform = b[f].level_lfo.waveform
--     end
--   elseif parameter == "DPTH" then
--     if b.id == f then
--       b.level_lfo.depth = b[f].level_lfo.depth
--     end
--   elseif parameter == "RATE" then
--     if b.id == f then
--       b.level_lfo.freq = b[f].level_lfo.freq
--     end
--   end
-- end


-- OG
-- screen.move(0,10)
-- screen.level(3)
-- screen.text("levels")
-- screen.line_width(1)
-- local level_options = {"levels","envelope enable","loop","time"}
-- local focused_pad = nil
-- for i = 1,3 do
--   if bank[i].focus_hold == true then
--     focused_pad = bank[i].focus_pad
--   else
--     focused_pad = bank[i].id
--   end
--   screen.level(3)
--   screen.move(10,79-(i*20))
--   local level_markers = {"0 -", "1 -", "2 -"}
--   screen.text(level_markers[i])
--   screen.move(10+(i*20),64)
--   screen.level(level_options[page.levels.sel+1] == "levels" and 15 or 3)
--   local level_to_screen_options = {"a", "b", "c"}
--   if key1_hold or grid_alt or bank[i].alt_lock then
--     screen.text("("..level_to_screen_options[i]..")")
--   else
--     screen.text(level_to_screen_options[i]..""..focused_pad)
--   end
--   screen.move(35+(20*(i-1)),57)
--   local level_to_screen = ((key1_hold or grid_alt or bank[i].alt_lock) and util.linlin(0,2,0,40,bank[i].global_level) or util.linlin(0,2,0,40,bank[i][focused_pad].level))
--   screen.line(35+(20*(i-1)),57-level_to_screen)
--   screen.close()
--   screen.stroke()
--   screen.level(level_options[page.levels.sel+1] == "envelope enable" and 15 or 3)
--   screen.move(85,10)
--   screen.text("env?")
--   screen.move(90+((i-1)*15),20)
--   local shapes = {"\\","/","/\\"}
--   if bank[i][focused_pad].enveloped then
--     screen.text_center(shapes[bank[i][focused_pad].envelope_mode])
--   else
--     screen.text_center("-")
--   end
--   screen.level(level_options[page.levels.sel+1] == "loop" and 15 or 3)
--   screen.move(90+((i-1)*15),30)
--   if bank[i][focused_pad].envelope_loop then
--     screen.text_center("∞")
--   else
--     screen.text_center("-")
--   end
  
--   screen.level(level_options[page.levels.sel+1] == "time" and 15 or 3)
--   -- screen.move(85,30)
--   -- screen.text("time")
--   screen.move(85,34+((i)*10))
--   local envelope_to_screen_options = {"a", "b", "c"}
--   if key1_hold or grid_alt or bank[i].alt_lock then
--     screen.text("("..envelope_to_screen_options[i]..")")
--   else
--     screen.text(envelope_to_screen_options[i]..""..focused_pad)
--   end
--   screen.move(103,34+((i)*10))
--   if bank[i][focused_pad].enveloped then
--     screen.text(string.format("%.2g", bank[i][focused_pad].envelope_time).."s")
--   else
--     screen.text("---")
--   end
-- end
-- screen.level(3)
-- screen.move(0,64)

return levels_menu