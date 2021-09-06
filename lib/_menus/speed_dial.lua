local sd = {}

local sd_arp = include 'lib/speed_dial_pages/arps'
local sd_loop = include 'lib/speed_dial_pages/loops'
local sd_level = include 'lib/speed_dial_pages/levels'
local sd_filter = include 'lib/speed_dial_pages/filters'

local size;
sd.menu = 1
-- local positions;

function sd.init()
  if tonumber(params:string("grid_size")) == 128 then
    positions = 
    {
      [2] = {14,4},
      [3] = {15,4},
      [4] = {16,4},
      [5] = {14,3},
      [6] = {15,3},
      [7] = {16,3},
      [8] = {14,2},
      [9] = {15,2},
      [10] = {16,2},
      ["macro_config"] = {14,1},
      ["MIDI_config"] = {15,1}
    }
  end
end

-- 14,4 = 5,14
-- 8,7 = 2,8
-- x = 9-y, y = x

function sd.draw_grid()
  for k,v in pairs(positions) do
    g:led(positions[k][1],positions[k][2],4)
    if k == sd.menu then
      g:led(positions[k][1],positions[k][2],12)
    end
  end
  g:led(16,5,sd.menu == 1 and 12 or 4)
  if sd.menu == 2 then  
    sd_loop.draw_grid()
  elseif sd.menu == 3 then  
    sd_level.draw_grid()
  elseif sd.menu == 5 then
    sd_filter.draw_grid()
  elseif sd.menu == 9 then
    sd_arp.draw_grid()
  end
  g:led(sd.translate(1,16)[1],sd.translate(1,16)[2],grid_alt == true and 15 or 4)
end

function sd.parse_press(x,y,z)
  local nx = sd.coordinate(x,y)[1]
  local ny = sd.coordinate(x,y)[2]
  if nx >=5 and nx<=7 and (ny>=14 and ny<=16) and z == 1 then
    local nx_to_menu = {[5] = nx-5, [6] = nx-3, [7] = nx-1}
    if sd.menu ~= (ny-12)+(nx_to_menu[nx]) then
      sd.menu = (ny-12)+(nx_to_menu[nx])
    else
      menu = (ny-12)+(nx_to_menu[nx])
    end
  elseif nx == 4 and ny == 16 and z == 1 then
    if sd.menu ~= 1 then
      sd.menu = 1
    else
      menu = 1
    end
  end
  if sd.menu == 2 then
    sd_loop.parse_press(x,y,z)
  elseif sd.menu == 5 then
    sd_filter.parse_press(x,y,z)
  elseif sd.menu == 9 then
    sd_arp.parse_press(x,y,z)
  end
  if nx == 1 and ny == 16 then
    grid_alt = z == 1 and true or false
  end
  screen_dirty = true
end

function sd.coordinate(x,y)
  if tonumber(params:string("grid_size")) == 128 then
    return {9-y,x}
  else
    return {x,y}
  end
end

function sd.translate(x,y)
  if tonumber(params:string("grid_size")) == 128 then
    --3,1 = 1,6
    -- 4,5 = 5,5
    return {y,9-x}
  else
    return {x,y}
  end
end

_t = sd.translate
_c = sd.coordinate

function sd.perf_draw(b)

  local edition = params:get("LED_style")

  for i = 5,7 do
    for x = i,8 do
      g:led(
        _t(x,17-i)[1],
        _t(x,17-i)[2],
        zilch_leds[9-i][b][x-(i-1)] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition]
      )
    end
  end

  if grid_pat[b].rec == 1 then
    g:led(
      _t(8,9)[1],
      _t(8,9)[2],
      9*grid_pat[b].led
    )
  elseif (grid_pat[b].quantize == 0 and grid_pat[b].play == 1) or (grid_pat[b].quantize == 1 and grid_pat[b].tightened_start == 1) then
    if grid_pat[b].overdub == 0 then
      g:led(
        _t(8,9)[1],
        _t(8,9)[2],
        9
      )
    else
      g:led(
        _t(8,9)[1],
        _t(8,9)[2],
        15
      )
    end
  elseif grid_pat[b].count > 0 then
    g:led(
      _t(8,9)[1],
      _t(8,9)[2],
      5
    )
  else
    g:led(
      _t(8,9)[1],
      _t(8,9)[2],
      3
    )
  end

  for x = 1,4 do
    for y = 8,11 do
      g:led(_t(x,y)[1],_t(x,y)[2],led_maps["square_off"][edition])
    end
  end

  if bank[b].focus_hold == false then
    local pad = bank[b].id
    local pad_x = _arps.index_to_grid_pos(pad,4)[1]
    local pad_y = _arps.index_to_grid_pos(pad,4)[2]+7
    g:led(_t(pad_x,pad_y)[1], _t(pad_x,pad_y)[2], led_maps["square_selected"][edition])
    if tab.count(held_keys[b]) > 0 then
      for j = 1,#held_keys[b] do
        local ghost_x = _arps.index_to_grid_pos(held_keys[b][j],4)[1]
        local ghost_y = _arps.index_to_grid_pos(held_keys[b][j],4)[2]+7
        g:led(_t(ghost_x,ghost_y)[1],_t(ghost_x,ghost_y)[2],8)
      end
    else
    end
    for j = 1,16 do
      if bank[b][j].drone then
        local ghost_x = _arps.index_to_grid_pos(j,4)[1]
        local ghost_y = _arps.index_to_grid_pos(j,4)[2]+7
        g:led(_t(ghost_x,ghost_y)[1],_t(ghost_x,ghost_y)[2],8)
      end
    end
    if bank[b][bank[b].id].pause == true then
      g:led(_t(7,10)[1],_t(7,10)[2],led_maps["pad_pause"][edition])
      g:led(_t(8,10)[1],_t(8,10)[2],led_maps["pad_pause"][edition])
    end
  else
    local focus_pad = bank[b].focus_pad
    local focus_pad_x = _arps.index_to_grid_pos(focus_pad,4)[1]
    local focus_pad_y = _arps.index_to_grid_pos(focus_pad,4)[2]+7
    g:led(_t(focus_pad_x,focus_pad_y)[1], _t(focus_pad_x,focus_pad_y)[2], led_maps["square_selected"][edition])

    local selected_pad =  bank[b].id
    local selected_pad_x = _arps.index_to_grid_pos(selected_pad,4)[1]
    local selected_pad_y = _arps.index_to_grid_pos(selected_pad,4)[2]+7
    g:led(_t(selected_pad_x,selected_pad_y)[1], _t(selected_pad_x,selected_pad_y)[2], led_maps["square_dim"][edition])

    if bank[b][bank[b].focus_pad].pause == true then
      g:led(_t(7,10)[1],_t(7,10)[2],led_maps["square_selected"][edition])
      g:led(_t(8,10)[1],_t(8,10)[2],led_maps["square_selected"][edition])
    else
      g:led(_t(7,10)[1],_t(7,10)[2],led_maps["square_off"][edition])
      g:led(_t(8,10)[1],_t(8,10)[2],led_maps["square_off"][edition])
    end
  end
  
  if bank[b].focus_hold then
    g:led(_t(5,11)[1],_t(5,11)[2],(10*(bank[b][bank[b].focus_pad].send_pad_note and 1 or 0))+5)
  end

  local alt = bank[b].alt_lock and 1 or 0
  g:led(_t(4,12)[1],_t(4,12)[2],15*alt)
  
  for i,e in pairs(lit) do
    g:led(_t(_c(e.x),_c(e.y))[1],_t(_c(e.x),_c(e.y))[2],led_maps["zilchmo_on"][edition])
  end
  
  local focused = bank[b].focus_hold == false and bank[b][bank[b].id] or bank[b][bank[b].focus_pad]

  g:led(_t(4+focused.clip,8)[1],_t(4+focused.clip,8)[2],led_maps["clip"][edition])
  g:led(_t(4+focused.mode,9)[1],_t(4+focused.mode,9)[2],led_maps["mode"][edition])
  g:led(_t(8,8)[1],_t(8,8)[2],bank[b].focus_hold == false and led_maps["off"][edition] or led_maps["focus_on"][edition])
  g:led(_t(5,10)[1],_t(5,10)[2],led_maps[focused.loop and "loop_on" or "loop_off"][edition])

  if not bank[b].focus_hold then
    if params:string("arp_"..b.."_hold_style") ~= "sequencer" then
      local arp_button = _t(6,10)
      local arp_writer = _t(5,11)
      if arp[b].enabled and tab.count(arp[b].notes) == 0 then
        g:led(arp_button[1],arp_button[2],led_maps["arp_on"][edition])
      elseif arp[b].playing then
        if arp[b].hold then
          g:led(arp_button[1],arp_button[2],led_maps["arp_play"][edition])
        else
          if not arp[b].pause then
            g:led(arp_button[1],arp_button[2],led_maps["arp_pause"][edition]) -- i know, i know...
          end
        end
        if arp[b].enabled then
          g:led(arp_writer[1],arp_writer[2],led_maps["arp_play"][edition])
        else
          g:led(arp_writer[1],arp_writer[2],led_maps["arp_on"][edition])
        end
      else
        if arp[b].hold then
          -- g:led(arp_button,3,led_maps["arp_pause"][edition])
        end
        if tab.count(arp[b].notes) > 0 then
          g:led(arp_button[1],arp_button[2],led_maps["arp_pause"][edition])
        end
      end
    else
      local arp_button = _t(6,10)
      local arp_writer = _t(5,11)
      if arp[b].playing then
        g:led(arp_button[1],arp_button[2],led_maps["arp_play"][edition])
        if arp[b].enabled then
          g:led(arp_writer[1],arp_writer[2],led_maps["arp_play"][edition])
        else
          g:led(arp_writer[1],arp_writer[2],led_maps["arp_on"][edition])
        end
      else
        g:led(arp_button[1],arp_button[2],led_maps["off"][edition])
        if tab.count(arp[b].notes) > 0 then
          g:led(arp_button[1],arp_button[2],led_maps["arp_pause"][edition])
        end
      end
    end
  end

  for i = 1,3 do
    g:led(_t(i,12)[1],_t(i,12)[2],pattern_gate[b][i].active == true and 8 or 0)
  end

end

function sd.perf_press(b,x,y,z)
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]
  
  -- 4x4
  if (nx >= 1 and nx <= 4) and (ny >= 8 and ny <= 11) then
    if z == 1 then
      grid_actions.bank_pad_down(b,nx+((ny-8)*4))
    elseif z == 0 then
      grid_actions.bank_pad_up(b,nx+((ny-8)*4))
    end
  end
  
  -- focus pad
  if grid_alt or bank[b].alt_lock then
    if nx == 8 and ny == 8 and z == 1 then
      bank[b].focus_hold = not bank[b].focus_hold
      mc.mft_redraw(bank[b][bank[b].focus_hold and bank[b].focus_pad or bank[b].id],"all")
    end
  end

  -- zilchmo 4 + zilchmo 3
  if ((nx >= 5 and nx <= 8) and ny == 12) or ((nx >= 6 and nx <= 8) and ny == 11) then
    local zilch_id = ny == 12 and 4 or 3
    local zmap = zilches[zilch_id]
    local k1 = b
    local k2 = zilch_id == 3 and nx-5 or nx-4
    if z == 1 then
      zmap[k1][k2] = true
      zmap[k1].held = zmap[k1].held + 1
      zilch_leds[zilch_id][k1][k2] = 1
      grid_dirty = true
    elseif z == 0 then
      if zmap[k1].held > 0 then
        local coll = {}
        for j = 1,4 do
          if zmap[k1][j] == true then
            table.insert(coll,j)
          end
        end
        coll.con = table.concat(coll)
        local previous_rate = bank[k1][bank[k1].id].rate
        rightangleslice.init(zilch_id,k1,coll.con)
        if zilch_id == 4 then
          record_zilchmo_4(previous_rate,k1,4,coll.con)
        end
        for j = 1,4 do
          zmap[k1][j] = false
        end
      end
      zmap[k1].held = 0
      zilch_leds[zilch_id][k1][k2] = 0
      grid_dirty = true
      if menu ~= 1 then screen_dirty = true end
    end
  end

  -- zilchmo 2
  if (nx == 7 or nx == 8) and ny == 10 then
    local zilch_id = 2
    local zmap = zilches[zilch_id]
    local k1 = b
    local k2 = nx-6
    if z == 1 then
      zmap[k1][k2] = true
      zmap[k1].held = zmap[k1].held + 1
      zilch_leds[zilch_id][k1][k2] = 1
      grid_dirty = true
    elseif z == 0 then
      if zmap[k1].held > 0 then
        local coll = {}
        for j = 1,4 do
          if zmap[k1][j] == true then
            table.insert(coll,j)
          end
        end
        coll.con = table.concat(coll)
        local previous_rate = bank[k1][bank[k1].id].rate
        rightangleslice.init(2,k1,coll.con)
        for j = 1,4 do
          zmap[k1][k2] = false
        end
      end
      zmap[k1].held = 0
      zilch_leds[zilch_id][k1][k2] = 0
      grid_dirty = true
      if menu ~= 1 then screen_dirty = true end
    end
  end

  -- pattern recorder
  if (nx == 8 and ny == 9 and z == 1) then
    grid_actions.grid_pat_handler(b)
  end

  -- pad loop
  if (nx == 5 and ny == 10 and z == 1) then
    grid_actions.toggle_pad_loop(b)
  end

  -- clip changes
  if ((nx >= 5 and nx <= 7) and ny == 8) then
    if z == 1 then
      if not bank[b].alt_lock and not grid_alt then
        if bank[b].focus_hold == false then
          _ca.jump_clip(b, bank[b].id, nx-4)
        else
          _ca.jump_clip(b, bank[b].focus_pad, nx-4)
        end
      elseif bank[b].alt_lock or grid_alt then
        for j = 1,16 do
          _ca.jump_clip(b, j, nx-4)
        end
      end
    end
    if z == 0 then
      if menu ~= 1 then screen_dirty = true end
      if bank[b].focus_hold == false then
        if params:string("preview_clip_change") == "yes" or bank[b][bank[b].id].loop then
          cheat(b,bank[b].id)
        end
      end
    end
  end

  -- mode changes
  if ((nx == 5 or nx == 6) and ny == 9) then
    if not bank[b].alt_lock and not grid_alt then
      local target = bank[b].focus_hold == false and bank[b][bank[b].id] or bank[b][bank[b].focus_pad]
      local old_mode = target.mode
      target.mode = nx-4
      if old_mode ~= target.mode then
        _ca.change_mode(target, old_mode)
      end
    elseif bank[b].alt_lock or grid_alt then
      for k = 1,16 do
        local old_mode = bank[b][k].mode
        bank[b][k].mode = nx-4
        if old_mode ~= bank[b][k].mode then
          _ca.change_mode(bank[b][k], old_mode)
        end
      end
    end
    if bank[b].focus_hold == false then
      if params:string("preview_clip_change") == "yes" then
        cheat(b,bank[b].id)
      end
    end
  end

  -- sub 4x4
  if (nx >= 1 and nx <= 4) and (ny == 12) then
    if nx == 4 then
      if not grid_alt then
        bank[b].alt_lock = z == 1 and true or false
      else
        if z == 1 then
          bank[b].alt_lock = not bank[b].alt_lock
        end
      end
    else
      if (bank[b].alt_lock and z == 1) or not bank[b].alt_lock then
        p_gate.flip(b,nx)
      end
    end
  end

  -- arps + tangential external pad note send
  if ((nx == 6 and ny == 10) or (nx == 5 and ny == 11)) and z == 1 then
    if not bank[b].alt_lock and not grid_alt then
      if not bank[b].focus_hold then
        if nx == 6 then
          grid_actions.arp_handler(b)
        else
          if key1_hold == true then key1_hold = false end
          if nx == 5 then
            if not bank[b].alt_lock and not grid_alt then -- TODO verify if it shouldn't just be grid_alt
              grid_actions.arp_toggle_write(b)
            else
              grid_actions.clear_arp_sequencer(b)
            end
          end
          if menu ~= 1 then screen_dirty = true end
        end
      else
        if nx == 5 then
          bank[b][bank[b].focus_pad].send_pad_note = not bank[b][bank[b].focus_pad].send_pad_note
        end
      end
    elseif bank[b].alt_lock or grid_alt then
      if not bank[b].focus_hold then
        if nx == 6 then
          grid_actions.kill_arp(b)
        end
      else
        if nx == 5 then
          bank[b][bank[b].focus_pad].send_pad_note = not bank[b][bank[b].focus_pad].send_pad_note
          for j = 1,16 do
            bank[b][j].send_pad_note = bank[b][bank[b].focus_pad].send_pad_note
          end
        end
      end
    end
    ---
  end

  if nx == 7 and ny == 9 and z == 1 and grid_alt then
    random_grid_pat(b,3)
  end

end

return sd