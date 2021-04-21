local pans_menu = {}

local _p = pans_menu
local focused_pad = {nil,nil,nil}
local _p_ = nil

local last_slew = {nil,nil,nil}

function _p.init()
  page.pans = {}
  page.pans.regions = {"panning","LFO","SHP","DPTH","RATE"}
  page.pans.selected_region = "panning"
  page.pans.sel = 1
  page.pans.bank = 1
  page.pans.alt_view = false
  page.pans.alt_view_sel = 1
  page.pans.meta_pad = {1,1,1}
  _p_ = page.pans
  -- _p.lfo_init()
end

function _p.reset_view()
  page.pans.alt_view = false
  page.pans.alt_view_sel = 1
end

function _p.nav_banks(d)
  -- page.pans.bank = 
end

function _p.draw_menu()
  for i = 1,3 do
    if bank[i].focus_hold == true then
      focused_pad[i] = bank[i].focus_pad
    else
      focused_pad[i] = bank[i].id
    end
  end
  _p.draw_side()
  _p.draw_header()
  if not _p_.alt_view then
    _p.draw_panning()
    _p.draw_lfo()
  else
    _p.draw_alt_view()
  end
end

function _p.draw_header()
  screen.level(15)
  screen.move(0,10)
  screen.line(128,10)
  screen.stroke()
  -- screen.rect(0,0,129,8)
  -- screen.fill()
  screen.move(3,6)
  screen.level(15)
  screen.text("pans")
  if _p_.alt_view then
    screen.move(128,6)
    screen.text_right("LFO UTILITIES")
  end
end

function _p.draw_alt_view()
  local f = _p_.meta_pad[_p_.bank]
  screen.level(_p_.alt_view_sel == 1 and 15 or 3)
  screen.move(26,20)
  screen.text("PAD: "..f)
  screen.level(_p_.alt_view_sel == 2 and 15 or 3)
  screen.move(26,30)
  screen.text("PANNING: "..bank[_p_.bank][f].pan)
  local x_positions = {33,60,88,114}
  local text_to_display =
  {
    bank[_p_.bank][f].pan_lfo.active == true and "on" or "off",
    bank[_p_.bank][f].pan_lfo.waveform,
    bank[_p_.bank][f].pan_lfo.depth,
    lfo_rates.names[bank[_p_.bank][f].pan_lfo.rate_index]
  }
  for i = 1,4 do
    screen.level(_p_.alt_view_sel == i+2 and 15 or 3)
    screen.move(x_positions[i],40)
    screen.text_center(_p_.regions[i+1])
    screen.move(x_positions[i],50)
    screen.text_center(text_to_display[i])
  end
  screen.level(_p_.alt_view_sel == 7 and 15 or (_p_.alt_view_sel == 8 and 15 or 3))
  screen.move(26,60)
  screen.text("RANDOMIZE: ")
  screen.level(_p_.alt_view_sel == 7 and 15 or 3)
  screen.move(80,60)
  screen.text("pad")
  screen.level(_p_.alt_view_sel == 8 and 15 or 3)
  screen.move(122,60)
  screen.text_right("bank")
end

function _p.draw_side()
  local modifier;
  local pan_to_screen_options = {"a", "b", "c"}
  local y_pos = {21,38,55}
  for i = 1, #pan_to_screen_options do
    screen.level(i == _p_.bank and 15 or 3)
    screen.move(8,y_pos[i])
    screen.text(pan_to_screen_options[i])
  end
  _p.draw_boundaries()
end

function _p.draw_panning()
  screen.level(_p_.selected_region == "panning" and 15 or 3)
  local pan_options = {"L", "C", "R"}
  local x_positions = {26,74,122}
  for i = 1,3 do
    screen.move(x_positions[i],20)
    screen.text_center(pan_options[i])
  end
  local pan_to_screen = util.linlin(-1,1,26,122,bank[_p_.bank][focused_pad[_p_.bank]].pan)
  screen.move(pan_to_screen,32)
  screen.text_center("|")
  for i = 0,20 do
    screen.move(util.linlin(0,20,26,122,i),30)
    screen.text_center(".")
  end
  if focused_pad[_p_.bank] == bank[_p_.bank].id then
    local lfo_to_screen = util.linlin(-1,1,26,122,bank[_p_.bank].pan_lfo.slope)
    screen.move(lfo_to_screen,28)
    screen.text_center("*")
  end
end

function _p.draw_lfo()
  screen.level(15)
  --four sections, 20 to 128: 21.6 each
  local x_positions = {47,75,101}
  for i = 1,3 do
    screen.move(x_positions[i],40)
    screen.line(x_positions[i],64)
    screen.stroke()
  end
  x_positions = {33,60,88,114}
  local text_to_display =
  {
    bank[_p_.bank][focused_pad[_p_.bank]].pan_lfo.active == true and "on" or "off",
    bank[_p_.bank][focused_pad[_p_.bank]].pan_lfo.waveform,
    bank[_p_.bank][focused_pad[_p_.bank]].pan_lfo.depth,
    -- _p.freq_to_string(_p_.bank),
    _lfos.freq_to_string(_p_.bank,"pan_lfo")
  }
  for i = 1,4 do
    screen.level(_p_.selected_region == _p_.regions[i+1] and 15 or 3)
    screen.move(x_positions[i],48)
    screen.text_center(_p_.regions[i+1])
    screen.move(x_positions[i],58)
    screen.text_center(text_to_display[i])
  end
end

function _p.draw_boundaries()
  screen.level(15)
  screen.move(20,10)
  screen.line(20,64)
  screen.stroke()
  screen.move(1,10)
  screen.line(1,64)
  screen.stroke()
  if not page.pans.alt_view then
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

function _p.process_encoder(n,d)
  local b = bank[_p_.bank]
  local f = focused_pad[_p_.bank]
  if _p_.alt_view then
    _p.process_meta_encoder(n,d)
  else
    if n == 1 then
      _p_.bank = util.clamp(_p_.bank + d,1,3)
    elseif n == 2 then
      local current_area = tab.key(_p_.regions,_p_.selected_region)
      current_area = util.clamp(current_area+d,1,#_p_.regions)
      _p_.selected_region = _p_.regions[current_area]
    elseif n == 3 then
      if _p_.selected_region == "panning" then
        if not b.focus_hold then
          b[f].pan = util.round(util.clamp(b[f].pan+d/10,-1,1),0.01)
          for i = 1,16 do
            if i ~= f then
              b[i].pan = b[f].pan
            end
          end
        else
          b[f].pan = util.round(util.clamp(b[f].pan+d/10,-1,1),0.01)
          if b.id == f then
            if not bank[_p_.bank].pan_lfo.active then
              bank[_p_.bank].pan_lfo.slope = b[b.id].pan
            end
          end
        end
        bank[_p_.bank].pan_lfo.offset = b[b.id].pan
        softcut.pan(_p_.bank+1, b[b.id].pan)
      else
        _lfos.process_encoder(n,d,"pan_lfo",_p_.selected_region)
      end
    end
  end
end

function _p.process_meta_encoder(n,d)
  local b = bank[_p_.bank]
  local _f = _p_.meta_pad[_p_.bank]
  local f = focused_pad[_p_.bank]
  if n == 1 then
    _p_.bank = util.clamp(_p_.bank + d,1,3)
  elseif n == 2 then
    _p_.alt_view_sel = util.clamp(_p_.alt_view_sel+d,1,8)
  elseif n == 3 then
    if _p_.alt_view_sel == 1 then
      _p_.meta_pad[_p_.bank] = util.clamp(_p_.meta_pad[_p_.bank]+d,1,16)
    elseif _p_.alt_view_sel == 2 then
      b[_f].pan = util.round(util.clamp(b[_f].pan+d/10,-1,1),0.01)
      if _f == f then
        bank[_p_.bank].pan_lfo.offset = b[_f].pan
        softcut.pan(_p_.bank+1, b[_f].pan)
      end
    elseif _p_.alt_view_sel == 3 then
      b[_f].pan_lfo.active = d > 0 and true or false
      if _f == f then
        bank[_p_.bank].pan_lfo.active = b[_f].pan_lfo.active
      end
    elseif _p_.alt_view_sel == 4 then
      local current_index = tab.key(lfo_types,b[_f].pan_lfo.waveform)
      current_index = util.clamp(current_index + d,1,#lfo_types)
      b[_f].pan_lfo.waveform = lfo_types[current_index]
      if _f == f then
        bank[_p_.bank].pan_lfo.waveform = b[_f].pan_lfo.waveform
      end
    elseif _p_.alt_view_sel == 5 then
      b[_f].pan_lfo.depth = util.clamp(b[_f].pan_lfo.depth + d,1,200)
      if _f == f then
        bank[_p_.bank].pan_lfo.depth = b[_f].pan_lfo.depth
      end
    elseif _p_.alt_view_sel == 6 then
      b[_f].pan_lfo.rate_index = util.clamp(b[_f].pan_lfo.rate_index + d,1,#lfo_rates.values)
      b[_f].pan_lfo.freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[b[_f].pan_lfo.rate_index])
      if _f == f then
        bank[_p_.bank].pan_lfo.rate_index = b[_f].pan_lfo.rate_index
        bank[_p_.bank].pan_lfo.freq = b[_f].pan_lfo.freq
      end
    end
  end
end

function _p.process_key(n,z)
  if n == 1 and z == 1 then
    _p_.alt_view = not _p_.alt_view
    if _p_.alt_view then
      -- _p_.meta_pad[_p_.bank] = focused_pad[_p_.bank]
    end
  elseif n == 3 and z == 1 and _p_.alt_view then
    if _p_.alt_view_sel == 7 then
      _p.meta_actions("randomize_this_pad")
    elseif _p_.alt_view_sel == 8 then
      _p.meta_actions("randomize_this_bank")
    end
  elseif n == 2 and z == 1 then
    menu = 1
  end
end

function _p.meta_actions(id)
  if id == "copy_to_unassigned" or id == "copy_to_entire_bank" then
    for i = 1,16 do
      if id == "copy_to_unassigned" and (i ~= _p_.meta_pad[_p_.bank] and bank[_p_.bank][i].pan_lfo.active == false) or (id == "copy_to_entire_bank" and i ~= _p_.meta_pad[_p_.bank]) then
        for k,v in pairs(bank[_p_.bank][_p_.meta_pad[_p_.bank]].pan_lfo) do
          bank[_p_.bank][i].pan_lfo[k] = v
        end
      end
    end
  elseif id == "randomize_this_pad" or id == "randomize_this_bank" then
    local reasonable_max = 16
    for i = 1,reasonable_max do
      if id == "randomize_this_pad" then
        reasonable_max = 1
        i = _p_.meta_pad[_p_.bank]
      end
      local random_on = math.random(0,1)
      bank[_p_.bank][i].pan_lfo.active = random_on == 0 and false or true
      bank[_p_.bank][i].pan_lfo.waveform = lfo_types[math.random(1,#lfo_types)]
      bank[_p_.bank][i].pan_lfo.depth = math.random(1,200)
      bank[_p_.bank][i].pan_lfo.rate_index = math.random(1,#lfo_rates.values)
      bank[_p_.bank][i].pan_lfo.freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[bank[_p_.bank][i].pan_lfo.rate_index])
    end
  end
  _p.seed_change("LFO")
  _p.seed_change("SHP")
  _p.seed_change("DPTH")
  _p.seed_change("RATE")
end

function _p.seed_change(parameter)
  local b = bank[_p_.bank]
  local f = focused_pad[_p_.bank]
  if parameter == "LFO" then
    if b.id == f then
      b.pan_lfo.active = b[f].pan_lfo.active
      if not b.pan_lfo.active then
        softcut.pan(_p_.bank+1,b[f].pan)
        b.pan_lfo.counter = 1 -- TODO ERROR WHEN PATTERN IS GOING??
        b.pan_lfo.slope = b[f].pan
      end
    end
  elseif parameter == "SHP" then
    if b.id == f then
      b.pan_lfo.waveform = b[f].pan_lfo.waveform
    end
  elseif parameter == "DPTH" then
    if b.id == f then
      b.pan_lfo.depth = b[f].pan_lfo.depth
    end
  elseif parameter == "RATE" then
    if b.id == f then
      b.pan_lfo.freq = b[f].pan_lfo.freq
    end
  end
end

return pans_menu