local filters_menu = {}

local _f = filters_menu
local focused_pad = {nil,nil,nil}
local _f_ = nil

local last_slew = {nil,nil,nil}

function _f.init()
  page.filters = {}
  page.filters.regions = {"FREQ","Q","DRY","LP","HP","BP"}
  page.filters.selected_region = "FREQ"
  page.filters.sel = 1
  page.filters.bank = 1
  page.filters.alt_view = false
  page.filters.alt_view_sel = 1
  page.filters.meta_pad = {1,1,1}
  page.filters.dj_dials = {}
  for i = 1,3 do
    page.filters.dj_dials[i] = UI.Dial.new(35, 17, 30, params:get("filter "..i.." dj tilt"), -1,1, 0.01, params:get("filter "..i.." dj tilt"), {},'','lp/hp')
  end
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
    screen.text_right("FILTER STYLE")
  end
end

function _f.draw_alt_view()
  local f = _f_.meta_pad[_f_.bank]
  screen.font_size(25)
  screen.level(params:string("filter ".._f_.bank.." style") == "dj" and 15 or 3)
  screen.move(30,32)
  screen.text("dj")
  screen.move(30,56)
  screen.level(params:string("filter ".._f_.bank.." style") == "dj" and 3 or 15)
  screen.text("mmf")
  screen.font_size(8)
  -- screen.level(_f_.alt_view_sel == 1 and 15 or 3)
  -- screen.move(24,20)
  -- screen.text("MIN: "..string.format("%.6g",params:get("filter dynamic freq min ".._f_.bank)).."hz")
  -- screen.level(_f_.alt_view_sel == 2 and 15 or 3)
  -- screen.move(24,32)
  -- screen.text("MAX: "..string.format("%.6g",params:get("filter dynamic freq max ".._f_.bank)).."hz")
  -- screen.level(_f_.alt_view_sel == 3 and 15 or 3)
  -- screen.move(24,44)
  -- screen.text("RISE: "..params:string("filter dynamic freq attack ".._f_.bank)..(params:get("filter dynamic freq attack ".._f_.bank) >= 13 and " bars" or " beats"))
  -- screen.level(_f_.alt_view_sel == 4 and 15 or 3)
  -- screen.move(24,56)
  -- screen.text("FALL: "..params:string("filter dynamic freq release ".._f_.bank)..(params:get("filter dynamic freq release ".._f_.bank) >= 13 and " bars" or " beats"))
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
  if params:string("filter ".._f_.bank.." style") == "dj" then
    screen.fill()
    page.filters.dj_dials[_f_.bank].active = _f_.selected_region == "FREQ"
    page.filters.dj_dials[_f_.bank]:redraw()
    screen.level(_f_.selected_region == "Q" and 15 or 3)
    screen.move(95,38)
    screen.font_size(20)
    local q_scaled = util.linlin(0.0005,2,100,0,params:get("filter ".._f_.bank.." q"))
    screen.text_center("RES")
    screen.font_size(8)
    screen.move(95,54)
    screen.text_center(string.format("%.4g",q_scaled).."%")
  else
    screen.level(_f_.selected_region == "FREQ" and 15 or 3)
    screen.move(25,21)
    screen.text("F: "..string.format("%.6g",params:get("filter ".._f_.bank.." cutoff")).."hz")
    -- screen.text("F: "..filter[_f_.bank].freq.display_value)
    screen.level(_f_.selected_region == "Q" and 15 or 3)
    local q_scaled = util.linlin(0.0005,2,100,0,params:get("filter ".._f_.bank.." q"))
    screen.move(120,21)
    screen.text_right("Q: "..string.format("%.4g",q_scaled).."%")
    screen.level(_f_.selected_region == "FADE" and 15 or 3)
    local tilt_options = {"DRY","LP","HP","BP"}
    local x_positions = {32,60,88,116}
    for i = 1,#tilt_options do
      screen.level(_f_.selected_region == tilt_options[i] and 15 or 3)
      screen.move(x_positions[i],44)
      screen.text_center(tilt_options[i])
      screen.move(x_positions[i],54)
      if params:string("filter ".._f_.bank.." "..string.lower(tilt_options[i]).." mute") == "true" then
        screen.text_center("OFF")
      else  
        screen.text_center( util.round(params:get("filter ".._f_.bank.." "..string.lower(tilt_options[i])) * 100) )
      end
      screen.move(x_positions[i],59)
      -- screen.text_center(filter[_f_.bank][string.lower(tilt_options[i])].active == true and "on" or "off")
    end
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
  if params:string("filter ".._f_.bank.." style") == "dj" then
  else
    if not page.filters.alt_view then
      screen.move(20,30)
      screen.line(128,30)
      screen.stroke()
    end
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
      if params:string("filter ".._f_.bank.." style") == "dj" then
        current_area = util.clamp(current_area+d,1,2)
      else
        current_area = util.clamp(current_area+d,1,#_f_.regions)
      end
      _f_.selected_region = _f_.regions[current_area]
    elseif n == 3 then
      if _f_.selected_region == "FREQ" then
        if params:string("filter ".._f_.bank.." style") == "dj" then
          params:delta("filter ".._f_.bank.." dj tilt",d)
        else
          params:delta("filter ".._f_.bank.." cutoff",d/10)
        end
      elseif _f_.selected_region == "Q" then
        params:delta("filter ".._f_.bank.." q",d*-1)
      else
        if params:string("filter ".._f_.bank.." "..string.lower(_f_.selected_region).." mute") == "false" then
          params:delta("filter ".._f_.bank.." "..string.lower(_f_.selected_region),d)
        end
      end
    end
  end
  if speed_dial.menu == 5 and speed_dial_active then
    grid_dirty = true
  end
end

function _f.process_meta_encoder(n,d)
  local b = bank[_f_.bank]
  local _f = _f_.meta_pad[_f_.bank]
  local f = focused_pad[_f_.bank]
  if n == 1 then
    _f_.bank = util.clamp(_f_.bank + d,1,3)
  elseif n == 2 then
    params:delta("filter ".._f_.bank.." style",d)
    -- _f_.alt_view_sel = util.clamp(_f_.alt_view_sel+d,1,4)
  elseif n == 3 then
    params:delta("filter ".._f_.bank.." style",d)
    -- if _f_.alt_view_sel == 1 then
    --   params:delta("filter dynamic freq min ".._f_.bank,d)
    --   -- _f_.meta_pad[_f_.bank] = util.clamp(_f_.meta_pad[_f_.bank]+d,1,16)
    -- elseif _f_.alt_view_sel == 2 then
    --   params:delta("filter dynamic freq max ".._f_.bank,d)
    -- elseif _f_.alt_view_sel == 3 then
    --   params:delta("filter dynamic freq attack ".._f_.bank,d)
    -- elseif _f_.alt_view_sel == 4 then
    --   params:delta("filter dynamic freq release ".._f_.bank,d)
    -- end
  end
end

function _f.process_key(n,z)
  if n == 1 then
    _f_.alt_view = z == 1 and true or false
    if _f_.alt_view then
      -- _f_.meta_pad[_f_.bank] = focused_pad[_f_.bank]
    end
  elseif n == 2 and z == 1 then
    menu = 1
  elseif n == 3 then
    -- if (_f_.selected_region == "FREQ" and not _f_.alt_view) or _f_.alt_view then
    --   params:set("filter dynamic freq ".._f_.bank,z)
    -- end
    if z == 1 then
      if (_f_.selected_region == "DRY" or _f_.selected_region == "LP" or _f_.selected_region == "HP" or _f_.selected_region == "BP")
      and not _f_.alt_view then
        -- filters.filt_flip(_f_.bank,string.lower(_f_.selected_region),"rapid",filter[_f_.bank][string.lower(_f_.selected_region)].active and 0 or 1)

        if params:string("filter ".._f_.bank.." "..string.lower(_f_.selected_region).." mute") == "true" then
          params:set("filter ".._f_.bank.." "..string.lower(_f_.selected_region).." mute",1)
          local concat_sc = "post_filter_"..string.lower(_f_.selected_region)
          softcut[concat_sc](_f_.bank+1,params:get("filter ".._f_.bank.." "..string.lower(_f_.selected_region)))
        else
          params:set("filter ".._f_.bank.." "..string.lower(_f_.selected_region).." mute",2)
          local concat_sc = "post_filter_"..string.lower(_f_.selected_region)
          softcut[concat_sc](_f_.bank+1,0)
        end
        --   page.filters.last_value[_f_.bank][string.lower(_f_.selected_region)] = params:get("filter ".._f_.bank.." "..string.lower(_f_.selected_region))
        --   params:set("filter ".._f_.bank.." "..string.lower(_f_.selected_region),0)
        -- else
        --   params:set("filter ".._f_.bank.." "..string.lower(_f_.selected_region),page.filters.last_value[_f_.bank][string.lower(_f_.selected_region)])
        -- end
      end
    end
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
        -- softcut.pan(_f_.bank+1,b[f].pan)
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