local filters_menu = {}

local _f = filters_menu
local focused_pad = {nil,nil,nil}
local _f_ = nil

local last_slew = {nil,nil,nil}

function _f.init()
  page.filters = {}
  page.filters.regions = {"cutoff","Q","slew","type"}
  page.filters.selected_region = "cutoff"
  page.filters.sel = 1
  page.filters.bank = 1
  page.filters.alt_view = false
  page.filters.alt_view_sel = 1
  page.filters.meta_pad = {1,1,1}
  _f_ = page.filters
  -- _f.lfo_init()
end

function _f.reset_view()
  page.filters.alt_view = false
  page.filters.alt_view_sel = 1
end

function _f.nav_banks(d)
  -- page.filters.bank = 
end

function _f.draw_menu()
  for i = 1,3 do
    if bank[i].focus_hold == true then
      focused_pad[i] = bank[i].focus_pad
    else
      focused_pad[i] = bank[i].id
    end
  end
  _f.draw_side()
  _f.draw_header()
  if not _f_.alt_view then
    _f.draw_filters()
    _f.draw_params()
  else
    _f.draw_alt_view()
  end
end

function _f.draw_header()
  screen.level(15)
  screen.move(0,10)
  screen.line(128,10)
  screen.stroke()
  -- screen.rect(0,0,129,8)
  -- screen.fill()
  screen.move(3,6)
  screen.level(15)
  screen.text("filters")
  if _f_.alt_view then
    screen.move(128,6)
    screen.text_right("LFO UTILITIES")
  end
end

function _f.draw_alt_view()
  local f = _f_.meta_pad[_f_.bank]
  screen.level(_f_.alt_view_sel == 1 and 15 or 3)
  screen.move(24,20)
  screen.text("PAD: "..f)


  screen.level(_f_.alt_view_sel == 2 and 15 or 3)
  screen.move(26,30)
  local tilt_options = {"LP", "-", "HP"}
  local x_positions = {28,74,120}
  for i = 1,3 do
    screen.move(x_positions[i],30)
    screen.text_center(tilt_options[i])
  end
  local cut_to_line = util.round(math.abs(bank[_f_.bank][f].tilt),0.01)*100
  if bank[_f_.bank][f].tilt < 0 then
    for i = 0,cut_to_line do
      screen.move(util.linlin(0,100,74,28,i),38)
      screen.text_center("|")
    end
  elseif bank[_f_.bank][f].tilt > 0 then
    for i = 3,cut_to_line do
      screen.move(util.linlin(30,100,74,120,i),38)
      screen.text_center("|")
    end
  else
    screen.move(74,38)
    screen.text_center("|")
  end


  local x_positions = {43,74,105}
  -- {38,74,110}
  local q_scaled = util.linlin(0.0005,4,100,0,bank[_f_.bank][f].q)
  local ease_time_to_screen = bank[_f_.bank][f].tilt_ease_time
  local ease_type_to_screen = bank[_f_.bank][f].tilt_ease_type
  local ease_types = {"cont","jumpy"}
  local text_to_display =
  {
    string.format("%.4g",q_scaled) .."%",
    string.format("%.2f",ease_time_to_screen/100) .."s",
    ease_types[ease_type_to_screen]
  }
  for i = 1,3 do
    screen.level(_f_.alt_view_sel == i+2 and 15 or 3)
    screen.move(x_positions[i],50)
    screen.text_center(_f_.regions[i+1])
    screen.move(x_positions[i],60)
    screen.text_center(text_to_display[i])
  end
  -- screen.level(_f_.alt_view_sel == 7 and 15 or (_f_.alt_view_sel == 8 and 15 or 3))
  -- screen.move(26,60)
  -- screen.text("RANDOMIZE: ")
  -- screen.level(_f_.alt_view_sel == 7 and 15 or 3)
  -- screen.move(80,60)
  -- screen.text("pad")
  -- screen.level(_f_.alt_view_sel == 8 and 15 or 3)
  -- screen.move(122,60)
  -- screen.text_right("bank")
end

function _f.draw_side()
  local modifier;
  local pan_to_screen_options = {"a", "b", "c"}
  local y_pos = {21,38,55}
  for i = 1, #pan_to_screen_options do
    screen.level(i == _f_.bank and 15 or 3)
    screen.move(8,y_pos[i])
    screen.text(pan_to_screen_options[i])
  end
  _f.draw_boundaries()
end

function _f.draw_filters()
  screen.level(_f_.selected_region == "cutoff" and 15 or 3)
  local tilt_options = {"LP", "-", "HP"}
  local x_positions = {28,74,120}
  for i = 1,3 do
    screen.move(x_positions[i],20)
    screen.text_center(tilt_options[i])
  end

  local cut_to_line = util.round(math.abs(slew_counter[_f_.bank].slewedVal),0.01)*100

  if slew_counter[_f_.bank].slewedVal < 0 then
    for i = 0,cut_to_line do
      screen.move(util.linlin(0,100,74,28,i),32)
      screen.text_center("|")
    end
  elseif slew_counter[_f_.bank].slewedVal > 0 then
    for i = 3,cut_to_line do
      screen.move(util.linlin(30,100,74,120,i),32)
      screen.text_center("|")
    end
  else
    screen.move(74,32)
    screen.text_center("|")
  end

end

function _f.draw_params()
  screen.level(15)
  --three sections, 20 to 128: 36 each
  -- local x_positions = {47,75,101}
  local x_positions = {56,92}
  for i = 1,2 do
    screen.move(x_positions[i],40)
    screen.line(x_positions[i],64)
    screen.stroke()
  end
  -- x_positions = {33,60,88,114}
  x_positions = {38,74,110}
  local q_scaled = util.linlin(0.0005,4,100,0,bank[_f_.bank][bank[_f_.bank].id].q)
  local ease_time_to_screen = bank[_f_.bank][bank[_f_.bank].id].tilt_ease_time
  local ease_type_to_screen = bank[_f_.bank][bank[_f_.bank].id].tilt_ease_type
  local ease_types = {"cont","jumpy"}
  local text_to_display =
  {
    string.format("%.4g",q_scaled) .."%",
    string.format("%.2f",ease_time_to_screen/100) .."s",
    ease_types[ease_type_to_screen]
  }
  for i = 1,3 do
    screen.level(_f_.selected_region == _f_.regions[i+1] and 15 or 3)
    screen.move(x_positions[i],48)
    screen.text_center(_f_.regions[i+1])
    screen.move(x_positions[i],58)
    screen.text_center(text_to_display[i])
  end
end

function _f.draw_boundaries()
  screen.level(15)
  screen.move(20,10)
  screen.line(20,64)
  screen.stroke()
  screen.move(1,10)
  screen.line(1,64)
  screen.stroke()
  if not page.filters.alt_view then
    screen.move(20,40)
    screen.line(128,40)
    screen.stroke()
  end
  screen.move(128,10)
  screen.line(128,64)
  screen.stroke()
  screen.move(0,64)
  screen.line(128,64)
  screen.stroke()
end

function _f.process_encoder(n,d)
  local b = bank[_f_.bank]
  local f = focused_pad[_f_.bank]
  if _f_.alt_view then
    _f.process_meta_encoder(n,d)
  else
    if n == 1 then
      _f_.bank = util.clamp(_f_.bank + d,1,3)
    elseif n == 2 then
      local current_area = tab.key(_f_.regions,_f_.selected_region)
      current_area = util.clamp(current_area+d,1,#_f_.regions)
      _f_.selected_region = _f_.regions[current_area]
    elseif n == 3 then
      if _f_.selected_region == "cutoff" then
        encoder_actions.set_filter_cutoff(_f_.bank,d)
      elseif _f_.selected_region == "Q" then
        params:delta("filter ".._f_.bank.." q",d*-1)
      elseif _f_.selected_region == "slew" then
        for j = 1,16 do
          bank[_f_.bank][j].tilt_ease_time = util.clamp(bank[_f_.bank][j].tilt_ease_time+(d/1), 5, 15000)
        end
      elseif _f_.selected_region == "type" then
        for j = 1,16 do
          bank[_f_.bank][j].tilt_ease_type = util.clamp(bank[_f_.bank][j].tilt_ease_type+d, 1, 2)
        end
      end
    end
  end
end

function _f.process_meta_encoder(n,d)
  local b = bank[_f_.bank]
  local _f = _f_.meta_pad[_f_.bank]
  local f = focused_pad[_f_.bank]
  if n == 1 then
    _f_.bank = util.clamp(_f_.bank + d,1,3)
  elseif n == 2 then
    _f_.alt_view_sel = util.clamp(_f_.alt_view_sel+d,1,5)
  elseif n == 3 then
    if _f_.alt_view_sel == 1 then
      _f_.meta_pad[_f_.bank] = util.clamp(_f_.meta_pad[_f_.bank]+d,1,16)
    elseif _f_.alt_view_sel == 2 then
      slew_counter[_f_.bank].prev_tilt =  b[_f].tilt
      b[_f].tilt = util.clamp(b[_f].tilt+(d/100),-1,1)
      if d < 0 then
        if util.round(b[_f].tilt*100) < 0 and util.round(b[_f].tilt*100) > -9 then
          b[_f].tilt = -0.10
        elseif util.round(b[_f].tilt*100) > 0 and util.round(b[_f].tilt*100) < 32 then
          b[_f].tilt = 0.0
        end
      elseif d > 0 and util.round(b[_f].tilt*100) > 0 and util.round(b[_f].tilt*100) < 32 then
        b[_f].tilt = 0.32
      end
      if _f == f then
        slew_filter(_f_.bank,slew_counter[_f_.bank].prev_tilt,b[_f].tilt,b[_f].q,b[_f].q,15)
      end
    elseif _f_.alt_view_sel == 3 then
      local cs_q = controlspec.new(0.0005, 2.0, 'exp', 0, 0.32, "")
      local current_q = cs_q:unmap(b[_f].q)
      current_q = current_q - (d/100)
      b[_f].q = cs_q:map(current_q)
      if _f == f then
        softcut.post_filter_rq(_f_.bank+1,b[_f].q)
      end
    elseif _f_.alt_view_sel == 4 then
      b[_f].tilt_ease_time = util.clamp(b[_f].tilt_ease_time+(d/1), 5, 15000)
    elseif _f_.alt_view_sel == 5 then
      b[_f].tilt_ease_type = util.clamp(b[_f].tilt_ease_type+d, 1, 2)
    end
  end
end

function _f.process_key(n,z)
  if n == 1 and z == 1 then
    _f_.alt_view = not _f_.alt_view
    if _f_.alt_view then
      -- _f_.meta_pad[_f_.bank] = focused_pad[_f_.bank]
    end
  elseif n == 2 and z == 1 then
    menu = 1
  end
end

function _f.meta_actions(id)
  if id == "copy_to_unassigned" or id == "copy_to_entire_bank" then
    for i = 1,16 do
      if id == "copy_to_unassigned" and (i ~= _f_.meta_pad[_f_.bank] and bank[_f_.bank][i].filter_lfo.active == false) or (id == "copy_to_entire_bank" and i ~= _f_.meta_pad[_f_.bank]) then
        for k,v in pairs(bank[_f_.bank][_f_.meta_pad[_f_.bank]].filter_lfo) do
          bank[_f_.bank][i].filter_lfo[k] = v
        end
      end
    end
  elseif id == "randomize_this_pad" or id == "randomize_this_bank" then
    local reasonable_max = 16
    for i = 1,reasonable_max do
      if id == "randomize_this_pad" then
        reasonable_max = 1
        i = _f_.meta_pad[_f_.bank]
      end
      local random_on = math.random(0,1)
      bank[_f_.bank][i].filter_lfo.active = random_on == 0 and false or true
      bank[_f_.bank][i].filter_lfo.waveform = lfo_types[math.random(1,#lfo_types)]
      bank[_f_.bank][i].filter_lfo.depth = math.random(1,200)
      bank[_f_.bank][i].filter_lfo.rate_index = math.random(1,#lfo_rates.values)
      bank[_f_.bank][i].filter_lfo.freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[bank[_f_.bank][i].filter_lfo.rate_index])
    end
  end
  _f.seed_change("LFO")
  _f.seed_change("SHP")
  _f.seed_change("DPTH")
  _f.seed_change("RATE")
end

function _f.seed_change(parameter)
  local b = bank[_f_.bank]
  local f = focused_pad[_f_.bank]
  if parameter == "LFO" then
    if b.id == f then
      b.filter_lfo.active = b[f].filter_lfo.active
      if not b.filter_lfo.active then
        softcut.pan(_f_.bank+1,b[f].pan)
        b.filter_lfo.counter = 1 -- TODO ERROR WHEN PATTERN IS GOING??
        b.filter_lfo.slope = b[f].pan
      end
    end
  elseif parameter == "SHP" then
    if b.id == f then
      b.filter_lfo.waveform = b[f].filter_lfo.waveform
    end
  elseif parameter == "DPTH" then
    if b.id == f then
      b.filter_lfo.depth = b[f].filter_lfo.depth
    end
  elseif parameter == "RATE" then
    if b.id == f then
      b.filter_lfo.freq = b[f].filter_lfo.freq
    end
  end
end

return filters_menu



-- old filters:
-- screen.move(0,10)
-- screen.level(3)
-- screen.text("filters")

-- for i = 1,3 do
--   screen.move(17+((i-1)*45),20)
--   screen.level(15)
--   local filters_to_screen_options = {"a", "b", "c"}
--   if key1_hold or grid_alt then
--     screen.text_center(filters_to_screen_options[i]..""..bank[i].id)
--   else
--     screen.text_center("("..filters_to_screen_options[i]..")")
--   end
--   screen.move(17+((i-1)*45),30)
  
--   screen.level(page.filters.sel+1 == 1 and 15 or 3)
--   if slew_counter[i].slewedVal ~= nil then
--     if slew_counter[i].slewedVal >= -0.04 and slew_counter[i].slewedVal <=0.04 then
--     screen.text_center(".....|.....")
--     elseif slew_counter[i].slewedVal < -0.04 then
--       if slew_counter[i].slewedVal > -0.3 then
--         screen.text_center("....||.....")
--       elseif slew_counter[i].slewedVal > -0.45 then
--         screen.text_center("...|||.....")
--       elseif slew_counter[i].slewedVal > -0.65 then
--         screen.text_center("..||||.....")
--       elseif slew_counter[i].slewedVal > -0.8 then
--         screen.text_center(".|||||.....")
--       elseif slew_counter[i].slewedVal >= -1.01 then
--         screen.text_center("||||||.....")
--       end
--     elseif slew_counter[i].slewedVal > 0 then
--       if slew_counter[i].slewedVal < 0.5 then
--         screen.text_center(".....||....")
--       elseif slew_counter[i].slewedVal < 0.65 then
--         screen.text_center(".....|||...")
--       elseif slew_counter[i].slewedVal < 0.8 then
--         screen.text_center(".....||||..")
--       elseif slew_counter[i].slewedVal < 0.85 then
--         screen.text_center(".....|||||.")
--       elseif slew_counter[i].slewedVal <= 1.01 then
--         screen.text_center(".....||||||")
--       end
--     end
--   end
--   screen.move(17+((i-1)*45),40)
--   screen.level(page.filters.sel+1 == 2 and 15 or 3)
--   local ease_time_to_screen = bank[i][bank[i].id].tilt_ease_time
--   screen.text_center(string.format("%.2f",ease_time_to_screen/100).."s")
--   screen.move(17+((i-1)*45),50)
--   screen.level(page.filters.sel+1 == 3 and 15 or 3)
--   local q_scaled = util.linlin(0.0005,4,100,0,params:get("filter "..i.." q"))
--   screen.text_center(string.format("%.4g",q_scaled).."%")
--   screen.move(17+((i-1)*45),60)
--   screen.level(page.filters.sel+1 == 4 and 15 or 3)
--   local ease_type_to_screen = bank[i][bank[i].id].tilt_ease_type
--   local ease_types = {"cont","jumpy"}
--   screen.text_center(ease_types[ease_type_to_screen])
-- end