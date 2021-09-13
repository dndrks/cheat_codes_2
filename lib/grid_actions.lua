grid_actions = {}

held_query = {}
for i = 1,3 do
  held_query[i] = 0
end

speed_dial_active = false
was_transport_toggled = false

local last_grid_page = 0

local grid_level_clocks = {}
local mute_clock = {}

local _c = speed_dial.coordinate

zilches = 
{ 
    [2] = {{},{},{}} 
  , [3] = {{},{},{}} 
  , [4] = {{},{},{}}
}
for i = 1,3 do
  zilches[4][i].held = 0
  for j = 1,4 do
    zilches[4][i][j] = false
  end
end
for i = 1,3 do
  zilches[3][i].held = 0
  for j = 1,3 do
    zilches[3][i][j] = false
  end
end
for i = 1,3 do
  zilches[2][i].held = 0
  for j = 1,3 do
    zilches[2][i][j] = false
  end
end

function reset_step_seq(i)
  step_seq[i].active = (step_seq[i].active + 1)%2
  step_seq[i].meta_meta_step = 1
  step_seq[i].meta_step = 1
  step_seq[i].current_step = step_seq[i].start_point
  clock.sync(1)
  step_seq[i].active = (step_seq[i].active + 1)%2
  if step_seq[i].active == 1 and step_seq[i][step_seq[i].current_step].assigned_to ~= 0 then
    test_load(step_seq[i][step_seq[i].current_step].assigned_to+(((i)-1)*8),i)
  end
end

function grid_actions.init(x,y,z)
  
  if osc_communication == true then osc_communication = false end
  
  if params:string("grid_size") == "128" then

    if not speed_dial_active then
      if grid_page == 0 then
        local vert_128_bank;

        local nx = _c(x,y)[1]
        local ny = _c(x,y)[2]

        if ny <= 5 then
          vert_128_bank = 1
        elseif ny <= 10 then
          vert_128_bank = 2
        elseif ny <= 15 then
          vert_128_bank = 3
        end

        local four_sub = {}

        -- for i = 1,3 do
        --   if rytm.grid.ui[i] and z == 1 then
        --     grid_actions.parse_euclid(i,9-y,x-(5*(i-1)),z)
        --   end
        -- end
        
        if vert_128_bank ~= nil and (grid_alt or bank[vert_128_bank].alt_lock) and ny == (1)+(5*(vert_128_bank-1)) and nx == 8 and z == 1 then
          bank[vert_128_bank].focus_hold = not bank[vert_128_bank].focus_hold
          mc.mft_redraw(bank[vert_128_bank][bank[vert_128_bank].focus_hold and bank[vert_128_bank].focus_pad or bank[vert_128_bank].id],"all")
        end
        
        -- 4x4
        if vert_128_bank ~= nil and ny < (5 * vert_128_bank) and nx <= 4 then
          if z == 1 then
            grid_actions.bank_pad_down(vert_128_bank,nx+(4* ((ny-(5*(vert_128_bank-1)))-1) ))
          elseif z == 0 then
            grid_actions.bank_pad_up(vert_128_bank,nx+(4* ((ny-(5*(vert_128_bank-1)))-1) ))
          end
        end
        
        -- zilchmo 3+4 handling
        if x == 4 or x == 5 or x == 9 or x == 10 or x == 14 or x == 15 then
          if ((x == 4 or x == 9 or x == 14) and y <= 3) or ((x == 5 or x == 10 or x == 15) and y <= 4) then
            if not rytm.grid.ui[util.round(x/5)] then
              local zilch_id = x%5 == 0 and 4 or 3
              local zmap = zilches[zilch_id]
              local k1 = util.round(x/5)
              local k2 = zilch_id == 3 and 4-y or 5-y
              if z == 1 then
                zmap[k1][k2] = true
                zmap[k1].held = zmap[k1].held + 1
                zilch_leds[zilch_id][k1][y] = 1
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
                zilch_leds[zilch_id][k1][y] = 0
                grid_dirty = true
                if menu ~= 1 then screen_dirty = true end
              end
            end
          end
        end
        --/ zilchmo 3+4 handling

        if x == 3 or x == 8 or x == 13 then
          if y <= 2 then
            -- need to delay the collation...
            if not rytm.grid.ui[util.round(x/5)] then
              local zilch_id = 2
              local zmap = zilches[zilch_id]
              local k1 = util.round(x/5)
              local k2 = 3-y
              if z == 1 then
                zmap[k1][k2] = true
                zmap[k1].held = zmap[k1].held + 1
                zilch_leds[zilch_id][k1][y] = 1
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
                    zmap[k1][j] = false
                  end
                end
                zmap[k1].held = 0
                zilch_leds[zilch_id][k1][y] = 0
                grid_dirty = true
                if menu ~= 1 then screen_dirty = true end
              end
            end
          end
        end

        
        if vert_128_bank ~= nil and z == 0 and ny == 2+(5*(vert_128_bank-1)) and nx == 8 then
          grid_actions.grid_pat_handler(vert_128_bank)
        end

        
        -- for i = 4,2,-1 do
        --   if x == 16 and y == i and z == 0 then
        --     local current = math.abs(y-5)
        --     local a_p; -- this will index the arc encoder recorders
        --     if arc_param[current] == 1 or arc_param[current] == 2 or arc_param[current] == 3 then
        --       a_p = 1
        --     else
        --       a_p = arc_param[current] - 2
        --     end
        --     if grid_alt then
        --       arc_pat[current][a_p]:rec_stop()
        --       arc_pat[current][a_p]:stop()
        --       arc_pat[current][a_p]:clear()
        --     elseif arc_pat[current][a_p].rec == 1 then
        --       arc_pat[current][a_p]:rec_stop()
        --       arc_pat[current][a_p]:start()
        --     elseif arc_pat[current][a_p].count == 0 then
        --       arc_pat[current][a_p]:rec_start()
        --     elseif arc_pat[current][a_p].play == 1 then
        --       arc_pat[current][a_p]:stop()
        --     else
        --       arc_pat[current][a_p]:start()
        --     end
        --   end
        -- end
        
        if vert_128_bank ~= nil and ny == (3)+(5*(vert_128_bank-1)) and nx == 5 and z == 1 then
          grid_actions.toggle_pad_loop(vert_128_bank)
        end
        
        if x == 16 and y == 8 then
          grid_alt = z == 1 and true or false
          arc_alt = z
          if menu ~= 1 then screen_dirty = true end
        end
        
        if y == 4 or y == 3 or y == 2 then
          if x == 1 or x == 6 or x == 11 then
            local which_pad = nil
            local current = util.round(math.sqrt(math.abs(x-2)))
            if not rytm.grid.ui[current] then
              if z == 1 then
                if not bank[current].alt_lock and not grid_alt then
                  if bank[current].focus_hold == false then
                    _ca.jump_clip(current, bank[current].id, math.abs(y-5))
                  else
                    _ca.jump_clip(current, bank[current].focus_pad, math.abs(y-5))
                  end
                elseif bank[current].alt_lock or grid_alt then
                  for j = 1,16 do
                    _ca.jump_clip(current, j, math.abs(y-5))
                  end
                end
              end
              if z == 0 then
                if menu ~= 1 then screen_dirty = true end
                if bank[current].focus_hold == false then
                  if params:string("preview_clip_change") == "yes" or bank[current][bank[current].id].loop then
                    cheat(current,bank[current].id)
                  end
                end
              end
            end
          end
        end

        if vert_128_bank ~= nil and (nx == 5 or nx == 6) and ny == (2)+(5*(vert_128_bank-1)) then
          if not bank[vert_128_bank].alt_lock and not grid_alt then
            local current = vert_128_bank
            local target = bank[current].focus_hold == false and bank[current][bank[current].id] or bank[current][bank[current].focus_pad]
            local old_mode = target.mode
            target.mode = math.abs(nx-4)
            if old_mode ~= target.mode then
              _ca.change_mode(target, old_mode)
            end

          elseif bank[vert_128_bank].alt_lock or grid_alt then
            for k = 1,16 do
              local current = vert_128_bank
              local old_mode = bank[current][k].mode
              bank[current][k].mode = math.abs(nx-4)
              if old_mode ~= bank[current][k].mode then
                _ca.change_mode(bank[current][k], old_mode)
              end
            end
          end


          if bank[vert_128_bank].focus_hold == false then
            if params:string("preview_clip_change") == "yes" then
              local current = vert_128_bank
              cheat(current,bank[current].id)
            end
          end
        end
        
        
        if x == 16 and z == 1 and (y == 7 or y == 6 or y == 5) then
          if rec.focus ~= 8-y then
            rec.focus = 8-y
          else
            if rec[rec.focus].loop == 0 and params:string("one_shot_clock_div") == "threshold" and not grid_alt then
              _ca.threshold_rec_handler()
            elseif not grid_alt then
              _ca.toggle_buffer(8-y)
            end
            if grid_alt then
              _ca.buff_flush()
            end
          end
        end

        -- sub-4x4 modifiers
        if (x == 5 or x == 10 or x == 15) then
          local b = util.round(x/5)
          if y == 5 then
            if not grid_alt then
              bank[b].alt_lock = z == 1 and true or false
            else
              if z == 1 then
                bank[b].alt_lock = not bank[b].alt_lock
              end
            end
          elseif y == 6 or y == 7 or y == 8 then
            if (bank[b].alt_lock and z == 1) or not bank[b].alt_lock then
              p_gate.flip(b,9-y)
            end
          end
        end
        
        if vert_128_bank ~= nil and z == 1 and nx == 6 and ny == (3)+(5*(vert_128_bank-1)) then
          if not bank[vert_128_bank].focus_hold then
            if not bank[vert_128_bank].alt_lock and not grid_alt then
              grid_actions.arp_handler(vert_128_bank)
            else
              grid_actions.kill_arp(vert_128_bank)
            end
          end
        end

        if vert_128_bank ~= nil and z == 1 and nx == 5 and ny == (4)+(5*(vert_128_bank-1)) then
          if not bank[vert_128_bank].focus_hold then
            if key1_hold == true then key1_hold = false end
            if not bank[vert_128_bank].alt_lock and not grid_alt then -- TODO verify if it shouldn't just be grid_alt
              grid_actions.arp_toggle_write(vert_128_bank)
            else
              grid_actions.clear_arp_sequencer(vert_128_bank)
            end
          else
            bank[vert_128_bank][bank[vert_128_bank].focus_pad].send_pad_note = not bank[vert_128_bank][bank[vert_128_bank].focus_pad].send_pad_note
            if bank[vert_128_bank].alt_lock or grid_alt then
              for j = 1,16 do
                if j ~= bank[vert_128_bank].focus_pad then
                  bank[vert_128_bank][j].send_pad_note = bank[vert_128_bank][bank[vert_128_bank].focus_pad].send_pad_note
                end
              end
            end
          end
        end

        if vert_128_bank ~= nil and z == 1 and nx == 7 and ny == (2)+(5*(vert_128_bank-1)) then
          random_grid_pat(vert_128_bank,3)
        end
        
      elseif grid_page == 1 then

        _ps.parse_press(x,y,z)
      
      elseif grid_page == 2 then
        if y == 3 or y == 6 then
          if x <= 2 and z == 1 then
            local changes = {"double", "halve", "sync"}
            del.change_duration(y == 6 and 1 or 2, y == 6 and 2 or 1, changes[x])
          elseif x == 3 and z == 1 then
            del.quick_action(y == 6 and 1 or 2, "reverse")
          elseif x >= 4 and x <= 8 then
            if z == 1 then
              del.set_value(math.abs(5-y), x-3, "level")
            end
          elseif x == 9 then
            del.quick_action(math.abs(y-5),"level_mute",z)
          end
        elseif y == 4 or y == 5 then
          if x >= 4 and x <= 8 then
            if z == 1 then
              del.set_value(6-y, x-3, "feedback")
            end
          elseif x == 9 then
            -- if grid.alt_delay then
            if grid_alt then
              del.quick_action(6-y, "clear")
            end
            del.quick_action(6-y,"feedback_mute",z)
          end
        elseif y == 1 or y == 8 then
          if x >= 10 and x <=14 then
            if z == 1 then
              -- del.set_value(y == 8 and 1 or 2,x-9,grid.alt_delay == true and "send all" or "send")
              del.set_value(y == 8 and 1 or 2,x-9,grid_alt == true and "send all" or "send")
            end
          elseif x == 15 then
            del.quick_action(y == 8 and 1 or 2,"send_mute",z)
          end
        end

        if y == 1 or y == 2 or y == 7 or y == 8 then
          if x <= 8 then
            if z == 1 then
              local y_vals = {[8] = 0, [7] = 1, [2] = 0, [1] = 1}
              local bundle = x+(8*y_vals[y])
              local target = y<=2 and 2 or 1
              local saved_already = delay_bundle[target][bundle].saved
              if not saved_already then
                delay[target].saver_active = true
                clock.run(del.build_bundle,target,bundle)
              elseif saved_already then
                -- if grid.alt_delay then
                if grid_alt then
                  del.clear_bundle(target,bundle)
                else
                  del.restore_bundle(target,bundle)
                  delay[target].selected_bundle = bundle
                end
              end
            elseif z == 0 then
              delay[y<=2 and 2 or 1].saver_active = false
            end
          end
        end

        if y == 6 or y == 5 or y == 4 then
          if x == 14 and z == 1 then
            delay_grid.bank = 7-y
          end
        end

        if y == 4 or y == 5 then
          if x == 1 and z == 1 then
            del.change_rate(6-y, "double")
          elseif x == 2 and z == 1 then
            del.change_rate(6-y, "halve")
          elseif x == 3 then
            del.change_rate(6-y,z == 1 and "wobble" or "restore")
          end
        end

        if x == 12 and y == 2 then
          if z == 1 then
            if grid_alt or bank[delay_grid.bank].alt_lock then
              grid_actions.kill_arp(delay_grid.bank)
            elseif not grid_alt and not bank[delay_grid.bank].alt_lock then
              grid_actions.arp_handler(delay_grid.bank)
            end
          end
        end

        if x == 13 and y == 2 and z == 1 then
          grid_actions.toggle_pad_loop(delay_grid.bank)
        end

        if x >= 10 and x <= 13 and y >=3 and y <=6 then
          local id = delay_grid.bank
          local xval = {9,4,-1}
          if z == 1 then
            grid_actions.bank_pad_down(delay_grid.bank,(math.abs((y + 2)-9)+(((x - xval[id])-1)*4))-(20*(id-1)))
          elseif z == 0 then
            grid_actions.bank_pad_up(delay_grid.bank,(math.abs((y + 2)-9)+(((x - xval[id])-1)*4))-(20*(id-1)))
          end
        end

        -- zilchmo 4!!
        if x == 15 then
          if y >= 3 and y <= 6 then
            local zilch_id = 4
            local zmap = zilches[zilch_id]
            local k1 = delay_grid.bank
            local k2 = 7-y
            if z == 1 then
              zmap[k1][k2] = true
              zmap[k1].held = zmap[k1].held + 1
              zilch_leds[zilch_id][k1][7-y] = 1
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
        end

        if x == 16 and y == 8 then
          grid_alt = z == 1 and true or false
          if menu ~= 1 then screen_dirty = true end
        end

      end
    else
      speed_dial.parse_press(x,y,z)
    end

    if x == 16 and y == 1 and z == 1 then
      if not grid_alt then
        page_switcher_clock = clock.run(function()
          clock.sleep(0.25)
          speed_dial_active = true
          page_switcher_clock = nil
          grid_dirty = true
        end)
      elseif grid_alt then
        speed_dial_active = not speed_dial_active
        -- if speed_dial_active == false then
        --   if grid_alt then grid_alt = false end
        -- end
      end
    elseif x == 16 and y == 1 and z == 0 then
      if not grid_alt then
        speed_dial_active = false
        if page_switcher_clock ~= nil then
          clock.cancel(page_switcher_clock)
          page_switcher_clock = nil
          speed_dial_active = false
          if grid_page == 0 then
            grid_page = 1
          elseif grid_page == 1 then
            grid_page = 0
          elseif grid_page == 2 then
            grid_page = 1
          end
        end
      end
    end

    if x == 16 and y == 2 and z == 1 then
      if grid_page == 0 then
        grid_page = 2
      elseif grid_page == 2 then
        grid_page = 0
      elseif grid_page == 1 then
        grid_page = 2
      end
    end

    grid_dirty = true
    
  -- 64 grid / grid 64
  elseif params:string("grid_size") == "64" then
    if grid_page_64 == 0 then
      
      local b = bank[bank_64]

      if rytm.grid.ui[bank_64] and z == 1 then
        if y>=4 then
          grid_actions.parse_euclid(bank_64,x,y-3,z)
        end
      end

      if x <=3 and y == 1 and z ==1  then
        bank_64 = x
        b = bank[x]
        if menu == 2 then
          page.loops.sel = x
        elseif menu == 3 then
          page.levels.bank = x
        elseif menu == 4 then
          page.pans.bank = x
        elseif menu == 5 then
          page.filters.bank = x
        elseif menu == 7 then
          page.time_sel = x
        elseif menu == 8 then
          rytm.track_edit = x
        elseif menu == 9 then
          page.arps.sel = x
        elseif menu == 10 then
        elseif menu == "MIDI_config" then
          page.midi_bank = x
        end
        screen_dirty = true
      end
      
      if grid_alt or b.alt_lock then
        if not rytm.grid.ui[bank_64] then
          if x == 8 and y == 4 and z == 1 then
            b.focus_hold = not b.focus_hold
            mc.mft_redraw(b[b.focus_hold and b.focus_pad or b.id],"all")
          end
        end
      end

      --arc parameters
      if y == 2 then
        if x == 8 and z == 1 then
          rytm.grid.ui[bank_64] = not rytm.grid.ui[bank_64]
        end
        if x == 6 or x ==7 or x == 8 then
          if not grid_alt then
            if z == 1 then
              table.insert(arc_switcher[bank_64],x)
              held_query[bank_64] = #arc_switcher[bank_64]
            elseif z == 0 then
              held_query[bank_64] = held_query[bank_64] - 1
              if held_query[bank_64] == 0 then
                if #arc_switcher[bank_64] == 1 then
                  arc_param[bank_64] = arc_switcher[bank_64][1] == 6 and 1 or (arc_switcher[bank_64][1] == 7 and 2 or 3)
                elseif #arc_switcher[bank_64] == 2 then
                  total = arc_switcher[bank_64][1] + arc_switcher[bank_64][2]
                  if total == 13 then
                    arc_param[bank_64] = 5
                  elseif total == 15 then
                    arc_param[bank_64] = 6
                  end
                elseif #arc_switcher[bank_64] == 3 then
                  arc_param[bank_64] = 4
                elseif #arc_switcher[bank_64] > 3 then
                  arc_switcher[bank_64] = {}
                end
                arc_switcher[bank_64] = {}
              end
            end
          end
        end
      end
      
      --arc recorders
      if x == 8 and y == 3 and z == 0 then
        if not rytm.grid.ui[bank_64] then
          local current = bank_64
          local a_p; -- this will index the arc encoder recorders
          if arc_param[current] == 1 or arc_param[current] == 2 or arc_param[current] == 3 then
            a_p = 1
          else
            a_p = arc_param[current] - 2
          end
          if grid_alt then
            arc_pat[current][a_p]:rec_stop()
            arc_pat[current][a_p]:stop()
            arc_pat[current][a_p]:clear()
          elseif arc_pat[current][a_p].rec == 1 then
            arc_pat[current][a_p]:rec_stop()
            arc_pat[current][a_p]:start()
          elseif arc_pat[current][a_p].count == 0 then
            arc_pat[current][a_p]:rec_start()
          elseif arc_pat[current][a_p].play == 1 then
            arc_pat[current][a_p]:stop()
          else
            arc_pat[current][a_p]:start()
          end
        end
      end
      
      if z == 1 and x <= 4 and y >= 4 and y <= 7 then
        if not rytm.grid.ui[bank_64] then
          if b.focus_hold == false then
            if not grid_alt then
              selected[bank_64].x = (y-3)+(5*(bank_64-1))
              selected[bank_64].y = 9-x
              selected[bank_64].id = (4*(y-4))+x
              b.id = selected[bank_64].id
              page.loops.meta_pad[bank_64] = b.id
              which_bank = bank_64
              pad_clipboard = nil
              if b.quantized_press == 0 then
                if arp[bank_64].enabled and grid_pat[bank_64].rec == 0
                and not arp[bank_64].pause
                -- and not arp[bank_64].gate.active
                and not pattern_gate[bank_64][2].active
                then
                  if arp[bank_64].down == 0 and params:string("arp_"..bank_64.."_hold_style") == "last pressed" then
                    for j = #arp[bank_64].notes,1,-1 do
                      arps.remove_momentary(bank_64,j)
                    end
                  end
                  -- arp[bank_64].time = b[b.id].arp_time
                  arps.momentary(bank_64, b.id, "on")
                  arp[bank_64].down = arp[bank_64].down + 1
                else
                  -- if rytm.track[bank_64].k == 0 then
                    if not arp[bank_64].playing
                    -- or arp[bank_64].playing and arp[bank_64].gate.active then
                    or arp[bank_64].playing and pattern_gate[bank_64][2].active then
                      cheat(bank_64, b.id)
                    end
                  -- end
                  grid_pattern_watch(bank_64)
                end
              else
                table.insert(quantize_events[bank_64],selected[bank_64].id)
              end
            else
              local released_pad = (4*(y-4))+x
              arps.momentary(bank_64, released_pad, "off")
            end
          else
            if not grid_alt then
              b.focus_pad = (4*(y-4))+x
              mc.mft_redraw(b[b.focus_pad],"all")
              main_menu.change_pad_focus(bank_64,b.focus_pad)
            elseif grid_alt then
              if not pad_clipboard then
                pad_clipboard = {}
                b.focus_pad = (4*(y-4))+x
                -- pad_copy(pad_clipboard, b[b.focus_pad])
                pad_clipboard = deep_copy(b[b.focus_pad])
              else
                b.focus_pad = (4*(y-4))+x
                -- pad_copy(b[b.focus_pad], pad_clipboard)
                b[b.focus_pad] = deep_copy(pad_clipboard)
                b[b.focus_pad].bank_id = bank_64
                pad_clipboard = nil
              end
            end
          end
        end
        if menu ~= 1 then screen_dirty = true end
      elseif z == 0 and x <= 4 and y >= 4 and y <= 7 then
        if not rytm.grid.ui[bank_64] then
          if not b.focus_hold then
            local released_pad = (4*(y-4))+x
            if b[released_pad].play_mode == "momentary" then
              softcut.rate(bank_64+1,0)
            end
            if arp[bank_64].enabled and grid_pat[bank_64].rec == 0
            and not arp[bank_64].pause
            -- and not arp[bank_64].gate.active
            and not pattern_gate[bank_64][2].active
            then
              if (arp[bank_64].enabled and not arp[bank_64].hold) or (menu == 9 and not arp[bank_64].hold) then
                if params:string("arp_"..bank_64.."_hold_style") ~= "sequencer" then
                  arps.momentary(bank_64, released_pad, "off")
                end
                arp[bank_64].down = arp[bank_64].down - 1
              elseif (arp[bank_64].enabled and arp[bank_64].hold and not arp[bank_64].pause) or (menu == 9 and arp[bank_64].hold and not arp[bank_64].pause) then
                arp[bank_64].down = arp[bank_64].down - 1
              end
            end
          end
        end
      end
      
      -- zilchmo 3+4 handling
      -- if x == 4 or x == 5 or x == 9 or x == 10 or x == 14 or x == 15 then
      if y == 6 or y == 7 or y == 8 then
        if ((y == 6 and x >=7) or (y == 7 and x >= 6) or (y == 8 and x >= 5)) then
          if not rytm.grid.ui[bank_64] then
            local zilch_id = (y == 8 and 4 or (y == 7 and 3 or 2))
            local zmap = zilches[zilch_id]
            local k1 = bank_64
            local k2 = (zilch_id == 3 and x-5 or (zilch_id == 4 and x-4 or x-6))
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
        end
      end

      if z == 0 and x == 8 and y == 5 then
        local i = bank_64
        if not rytm.grid.ui[i] then
          grid_actions.grid_pat_handler(i)
        end
      end
      
      if x == 5 and y == 6 and z == 1 then
        if not rytm.grid.ui[bank_64] then
          grid_actions.toggle_pad_loop(bank_64)
        end
      end
      
      if x == 1 and y == 8 then
        grid_alt = z == 1 and true or false
        arc_alt = z
        if menu ~= 1 then screen_dirty = true end
      end
      
      if x == 5 or x == 6 or x == 7 then
        if not rytm.grid.ui[bank_64] then
          if y == 4 then
            local which_pad = nil
            local current = bank_64
            if z == 1 then
              if not bank[current].alt_lock and not grid_alt then
                if bank[current].focus_hold == false then
                  _ca.jump_clip(current, bank[current].id, x-4)
                else
                  _ca.jump_clip(current, bank[current].focus_pad, x-4)
                end
              elseif bank[current].alt_lock or grid_alt then
                for j = 1,16 do
                  _ca.jump_clip(current, j, x-4)
                end
              end
            end
            if z == 0 then
              if menu ~= 1 then screen_dirty = true end
              if bank[current].focus_hold == false then
                if params:string("preview_clip_change") == "yes" or bank[current][bank[current].id].loop then
                  cheat(current,bank[current].id)
                end
              end
            end
          end
        end
      end

      if (y == 5 and (x == 5 or x == 6)) and z == 1 then
        if not rytm.grid.ui[bank_64] then
          local which_pad = nil
          local current = bank_64
          
          if not bank[current].alt_lock and not grid_alt then
            local target = bank[current].focus_hold == false and bank[current][bank[current].id] or bank[current][bank[current].focus_pad]
            local old_mode = target.mode
            target.mode = x-4
            if old_mode ~= target.mode then
              _ca.change_mode(target, old_mode)
            end

          elseif bank[current].alt_lock or grid_alt then
            for k = 1,16 do
              local old_mode = bank[current][k].mode
              bank[current][k].mode = x-4
              if old_mode ~= bank[current][k].mode then
                _ca.change_mode(bank[current][k], old_mode)
              end
            end
          end

          if bank[current].focus_hold == false then
            which_pad = bank[current].id
          else
            which_pad = bank[current].focus_pad
          end


          if bank[current].focus_hold == false then
            if params:string("preview_clip_change") == "yes" then
              cheat(current,bank[current].id)
            end
          end
        end
      end
      
      if y == 2 and x <= 3 and z == 1 then
        if rec.focus ~= x then
          rec.focus = x
        elseif rec.focus == x then
          if rec[rec.focus].loop == 0 and params:string("one_shot_clock_div") == "threshold" and not grid_alt then
            _ca.threshold_rec_handler()
          elseif not grid_alt then
            _ca.toggle_buffer(x)
          end
          if grid_alt then
            _ca.buff_flush()
          end
        end
      end

      if y == 3 and x <= 3 and z == 1 then
        if not grid_alt then
          _ca.SOS_toggle(x)
        else
          _ca.SOS_erase(x)
        end
      end
      
      if y == 8 and x == 4 then
        if not rytm.grid.ui[bank_64] then
          if not grid_alt then
            bank[bank_64].alt_lock = z == 1 and true or false
          else
            if z == 1 then
              bank[bank_64].alt_lock = not bank[bank_64].alt_lock
            end
          end
        end
      end
      
      if y == 6 and x == 6 and z == 1 then
        if not rytm.grid.ui[bank_64] then
          if not bank[bank_64].alt_lock and not grid_alt then
            grid_actions.arp_handler(bank_64)
          else
            grid_actions.kill_arp(bank_64)
          end
        end
      end

      if x == 3 and y == 8 and z == 1 then
        if not rytm.grid.ui[bank_64] then
          if not bank[bank_64].alt_lock and not grid_alt then
            grid_actions.arp_toggle_write(bank_64)
          else
            grid_actions.clear_arp_sequencer(bank_64)
          end
        end
      end

      if x == 2 and y == 8 then
        pattern_gate[bank_64][2].active = z == 1 and true or false
      end

      if y == 7 and x == 5 and z == 1 then
        if not rytm.grid.ui[bank_64] then
          local i = bank_64
          if bank[i].alt_lock or grid_alt then
            if not bank[i].focus_hold then
              for j = 1,16 do
                bank[i][j].rate = 1
                if bank[i][j].fifth == true then
                  bank[i][j].fifth = false
                end
              end
              -- softcut.rate(i+1,1*bank[i][bank[i].id].offset)
              softcut.rate(i+1,_loops.get_total_pitch_offset(i,bank[i].id))
            else
              bank[i][bank[i].focus_pad].send_pad_note = not bank[i][bank[i].focus_pad].send_pad_note
              for j = 1,16 do
                bank[i][j].send_pad_note = bank[i][bank[i].focus_pad].send_pad_note
              end
            end
          else
            if bank[i].focus_hold then
              bank[i][bank[i].focus_pad].send_pad_note = not bank[i][bank[i].focus_pad].send_pad_note
            end
          end
          screen_dirty = true
        end
      end

      if y == 5 and x == 7 and z == 1 and (grid_alt or bank[bank_64].alt_lock) then
        if not rytm.grid.ui[bank_64] then
          random_grid_pat(bank_64,3)
        end
      end

    elseif grid_page_64 == 2 then

      if x == 3 or x == 6 then
        if y <= 2 and z == 1 then
          local changes = {"double", "halve", "sync"}
          del.change_duration(x == 3 and 1 or 2, x == 3 and 2 or 1, changes[y])
        elseif y == 3 and z == 1 then
          del.quick_action(x == 3 and 1 or 2, "reverse")
        elseif y >= 4 and y <= 8 then
          if z == 1 then
            del.set_value(x == 3 and 1 or 2, math.abs(3-y), "level")
          end
        -- elseif y == 9 then
        --   del.quick_action(x == 3 and 1 or 2,"level_mute",z)
        end
      elseif x == 4 or x == 5 then
        if y >= 4 and y <= 8 then
          if z == 1 then
            del.set_value(x == 4 and 1 or 2, math.abs(3-y), "feedback")
          end
        elseif y == 1 and z == 1 then
          del.change_rate(x == 4 and 1 or 2, "double")
        elseif y == 2 and z == 1 then
          del.change_rate(x == 4 and 1 or 2, "halve")
        elseif y == 3 then
          del.change_rate(x == 4 and 1 or 2,z == 1 and "wobble" or "restore")
        end
      elseif x == 1 or x == 8 then

      elseif x == 2 or x == 7 then
        if y == 8 then
          del.quick_action(x == 2 and 1 or 2,"feedback_mute",z)
        elseif y == 7 then
          del.quick_action(x == 2 and 1 or 2,"level_mute",z)
        elseif (y == 1 or y == 2 or y == 3) and z == 1 then
          delay_grid.bank = y
          local current_level = x == 2 and bank[delay_grid.bank][bank[delay_grid.bank].id].left_delay_level or bank[delay_grid.bank][bank[delay_grid.bank].id].right_delay_level
          del.set_value(x == 2 and 1 or 2, current_level > 0 and 5 or 1,"send all")
        elseif y == 4 and z == 1 then
          params:set("delay "..(x == 2 and "L:" or "R:").." external input", params:get("delay "..(x == 2 and "L:" or "R:").." external input") > 0 and 0 or 1)
        end
      end

      if x == 1 or x == 8 then
        if y >= 3 and y <= 7 then
          if z == 1 then
            local bundle = (y-2)
            local target = x == 1 and 1 or 2
            local saved_already = delay_bundle[target][bundle].saved
            if not saved_already then
              delay[target].saver_active = true
              clock.run(del.build_bundle,target,bundle)
            elseif saved_already then
              -- if grid.alt_delay then
              if grid_alt then
                del.clear_bundle(target,bundle)
              else
                del.restore_bundle(target,bundle)
                delay[target].selected_bundle = bundle
              end
            end
          elseif z == 0 then
            delay[x<=2 and 1 or 2].saver_active = false
          end
        end
      end

      if x == 1 and y == 8 then
        grid_alt = z == 1 and true or false
        if menu ~= 1 then screen_dirty = true end
      end

    elseif grid_page_64 == 1 then
      local save_pat;
      if x <=3 and y == 1 and z ==1  then
        bank_64 = x
        b = bank[x]
        if menu == 2 then
          page.loops.sel = x
        elseif menu == 7 then
          page.time_sel = x
        elseif menu == 8 then
          rytm.track_edit = x
        elseif menu == 9 then
          page.arps.sel = x
        elseif menu == 10 then
        elseif menu == "MIDI_config" then
          page.midi_bank = x
        end
        screen_dirty = true
      end
      local current = bank_64
      if grid_loop_mod == 0 then
      
        if y == 2 then
          if z == 1 then
            if pattern_saver[current].saved[x] == 0 then
              if step_seq[current].held == 0 then
                pattern_saver[current].source = current
                pattern_saver[current].save_slot = x
                pattern_saver[current].clock = clock.run(test_save,current)
                -- print("starting save "..pattern_saver[current].clock)
              else
                --if there's a pattern saved there...
              end
            elseif pattern_saver[current].saved[x] == 1 then
              if step_seq[current].held == 0 and not grid_alt then
                pattern_saver[current].load_slot = x
                test_load((x)+(8*(current-1)),current)
              elseif step_seq[current].held ~= 0 and not grid_alt then
                step_seq[current][step_seq[current].held].assigned_to = x
              elseif grid_alt then
                pattern_deleter[current].clock = clock.run(test_delete,current,x)
              end
            end
          elseif z == 0 then
            if step_seq[current].held == 0 then
              if pattern_saver[current].clock then
                clock.cancel(pattern_saver[current].clock)
              end
              pattern_saver[current].active = false
            end
            if pattern_deleter[current].clock then
              clock.cancel(pattern_deleter[current].clock)
              pattern_deleter[current].active = false
            end
          end
        elseif y == 3 then
          if z == 1 then
            step_seq[current].meta_duration = x
          end
        elseif y == 4 or y == 5 then
          if z == 1 then
            step_seq[current].held = x + (y == 4 and 0 or 8)
            if grid_alt then
              step_seq[current][step_seq[current].held].assigned_to = 0
            end
          elseif z == 0 then
            step_seq[current].held = 0
          end
        elseif y == 6 then
          if step_seq[current].held == 0 then
            step_seq[current][step_seq[current].current_step].meta_meta_duration = x
          else
            step_seq[current][step_seq[current].held].meta_meta_duration = x
          end
          if grid_alt then
            for k = 1,16 do
              step_seq[current][k].meta_meta_duration = x
            end
          end
        end

        if (x == 2 or x == 3 or x == 4) and y == 8 and z == 1 then
          if step_seq[x-1].held == 0 then
            if grid_alt then
              clock.run(reset_step_seq,x-1)
            else
              step_seq[x-1].active = (step_seq[x-1].active + 1) % 2
            end
          else
            step_seq[x-1][step_seq[x-1].held].loop_pattern = (step_seq[x-1][step_seq[x-1].held].loop_pattern + 1) % 2
          end
        end
        
        if x == 1 and y == 8 then
          grid_alt = z == 1 and true or false
          if menu ~= 1 then screen_dirty = true end
        end
      
      elseif grid_loop_mod == 1 then

        if (y == 4 or y == 5) then
          if z == 1 then
            step_seq[current].loop_held = step_seq[current].loop_held + 1
            if step_seq[current].loop_held == 1 then
              step_seq[current].start_point = x + (y == 5 and 8 or 0)
              if step_seq[current].start_point > step_seq[current].current_step then
                step_seq[current].current_step = step_seq[current].start_point
              end
            elseif step_seq[current].loop_held == 2 then
              step_seq[current].end_point = x + (y == 5 and 8 or 0)
            end
          elseif z == 0 then
            step_seq[current].loop_held = step_seq[current].loop_held - 1
          end
        end
        
      end

      if x == 8 and y == 8 then
        grid_loop_mod = z
        if menu ~= 1 then screen_dirty = true end
        grid_dirty = true
      end

    end

    if x == 8 and y == 1 and z == 1 then
      speed_dial_active = true
    elseif x == 8 and y == 1 and z == 0 then
      speed_dial_active = false
      if not grid_alt and not was_transport_toggled then
        if grid_page_64 == 0 then
          grid_page_64 = 1
        elseif grid_page_64 == 1 then
          grid_page_64 = 2
        elseif grid_page_64 == 2 then  
          grid_page_64 = 0
        end
      elseif grid_alt then
        if grid_page_64 == 0 then
          grid_page_64 = 2
        elseif grid_page_64 == 1 then
          grid_page_64 = 0
        elseif grid_page_64 == 2 then  
          grid_page_64 = 1
        end
      end
      was_transport_toggled = false
    end

    grid_dirty = true
  end
end

function grid_actions.arp_handler(i)
  if params:string("arp_"..i.."_hold_style") ~= "sequencer" then
    if not arp[i].enabled and tab.count(arp[i].notes) == 0 then
      arps.enable(i,true)
      if not transport.is_running then
        print("should start transport...")
        transport.toggle_transport()
      end
    elseif arp[i].enabled and tab.count(arp[i].notes) == 0 then
      arps.enable(i,false)
    elseif not arp[i].hold then
      -- if #arp[i].notes > 0 then
      if tab.count(arp[i].notes) > 0 then
        arp[i].hold = true
      else
      end
    else
      -- if #arp[i].notes > 0 then
      if tab.count(arp[i].notes) > 0 then
        if arp[i].playing == true then
          arps.toggle("stop",i)
        else
          arps.toggle("start",i)
        end
      end
    end
  else
    if arp[i].playing == true then
      arps.toggle("stop",i)
    else
      arps.toggle("start",i)
    end
  end
  screen_dirty = true
  p_gate.check_conflicts(i,"arp")
end

function grid_actions.arp_toggle_write(i)
  if arp[i].playing then
    arps.enable(i,not arp[i].enabled)
    if not arp[i].enabled then
      arp[i].down = 0
    end
  end
end

function grid_actions.clear_arp_sequencer(i)
  if params:string("arp_"..i.."_hold_style") == "sequencer" then
    arps.clear(i)
  end
end

function grid_actions.kill_arp(i)
  if params:string("arp_"..i.."_hold_style") ~= "sequencer" then
    page.arps.sel = i
    arp[i].hold = false
    if not arp[i].hold then
      if arp_clears == nil then
        arp_clears = {nil,nil,nil}
      end
      arps.clear(i)
      if arp_clears[i] ~= nil then
        local which_to_clear = arp_clears[i]
        clock.cancel(which_to_clear)
        arp_clears[i] = nil
        for j = 1,128 do
          arp[i].prob[j] = 100
          arp[i].conditional.A[j] = 1
          arp[i].conditional.B[j] = 1
        end
      else
        arp_clears[i] = clock.run(function()
          clock.sleep(0.25)
          arp_clears[i] = nil
        end)
      end
    end
    arp[i].down = 0
    arps.enable(i,false)
    screen_dirty = true
  elseif params:string("arp_"..i.."_hold_style") == "sequencer" then
    page.arps.sel = i
    arps.clear(i)
    screen_dirty = true
  end
end

function grid_actions.toggle_pad_loop(i)
  -- which_bank = i
  local which_pad = bank[i].focus_hold == true and bank[i].focus_pad or bank[i].id
  bank[i][which_pad].loop = not bank[i][which_pad].loop
  if bank[i].alt_lock or grid_alt then
    for j = 1,16 do
      bank[i][j].loop = bank[i][which_pad].loop
    end
  end
  if bank[i].focus_hold == false then
    softcut.loop(i+1,bank[i][which_pad].loop == true and 1 or 0)
  end
  if menu ~= 1 then screen_dirty = true end
end

function grid_actions.parse_euclid(i,x,y,z)
  if y == 1 then
    rytm.track[i].s[x] = not rytm.track[i].s[x]
    -- rytm.reer(i)
  elseif y == 2 then
    rytm.track[i].s[x+8] = not rytm.track[i].s[x+8]
    rytm.reer(i)
  elseif y == 3 or y == 4 then
    local which_param = {"k","n","rotation"}
    local r_p = rytm.grid.page[i]
    if y == 3 then
      if rytm.track[i][which_param[r_p]] ~= x then
        if which_param[r_p] ~= "k" then
          rytm.track[i][which_param[r_p]] = x
        else
          rytm.track[i][which_param[r_p]] = util.clamp(x,0,rytm.track[i].n)
        end
      elseif which_param[r_p] ~= "n" then
        rytm.track[i][which_param[r_p]] = 0
      end
    elseif y == 4 then
      if rytm.track[i][which_param[r_p]] ~= x+8 then
        if which_param[r_p] ~= "k" then
          rytm.track[i][which_param[r_p]] = x+8
        else
          rytm.track[i][which_param[r_p]] = util.clamp(x+8,0,rytm.track[i].n)
        end
      elseif which_param[r_p] ~= "n" then
        rytm.track[i][which_param[r_p]] = 0
      end
    end
    rytm.reer(i)
  elseif y == 5 and x >= 6 then
    rytm.grid.page[i] = x-5
  end
end

local function dumb_shit(i,note_in_question)
  if arp[i].enabled then
    if arp[i].hold then
      return false
    else
      return true
    end
  else
    return true
  end
end

function grid_actions.rec_stop(i)
  if #grid_pat[i].event > 0 then
    print("1769")
    if #held_keys[i] > 0 then
      local original_max = #grid_pat[i].event
      for j = #held_keys[i],1,-1 do
        print("~~~~",#held_keys[i],j,held_keys[i][j])
        if held_keys[i][j] ~= nil then
          if not bank[i][held_keys[i][j]].drone then
            if dumb_shit(i,held_keys[i][j]) then
              local special_shit;
              for k = 1,original_max do
                if held_keys[i][j] == grid_pat[i].event[k].id then
              -- how do i find out whether this pad is paired with any actual note down in the pattern????
                  print(held_keys[i][j].." is still held",k,original_max)
                  special_shit = held_keys[i][j]
                  grid_p[i] = {}
                  grid_p[i].action = "pads-release"
                  grid_p[i].i = i
                  grid_p[i].id = held_keys[i][j]
                  grid_pat[i]:rec_event(grid_p[i])
                  if arp[i].enabled
                  and not arp[i].pause
                  -- and not arp[i].gate.active
                  and pattern_gate[i][1].active and pattern_gate[i][2].active
                  then
                    print("off...")
                    arps.momentary(i, held_keys[i][j], "off")
                  end
                else
                  if held_keys[i][j] == nil then
                    print("unique",j,original_max,k,#held_keys[i],special_shit)
                    for this = 1,#arp[i].notes do
                      if arp[i].notes[this] ~= special_shit then
                        grid_p[i] = {}
                        grid_p[i].action = "pads-release"
                        grid_p[i].i = i
                        grid_p[i].id = arp[i].notes[this]
                        grid_pat[i]:rec_event(grid_p[i])
                      end
                    end
                    -- tab.print(held_keys[i])
                    print("unique---") -- GUH, ok, 
                  end
                  -- print(held_keys[i][j].." is not part of the grid pattern")
                end
              end
            end
          end
        end
      end
    end
  end
  grid_pat[i]:rec_stop()
  print(#grid_pat[i].event)
end

function grid_actions.drone_pad(b,p)
  bank[b][p].drone = not bank[b][p].drone
  if not bank[b][p].drone then
    grid_actions.kill_note(b,p)
  else
    if not tab.contains(held_keys[b],p) then
      cheat(b,p)
    end
  end
end

function grid_actions.kill_note(b,p)
  mc.global_note_off(b,p)
  grid_actions.remove_held_key(b,p)
end

function grid_actions.remove_held_key(b,p)
  if tab.contains(held_keys[b],p) then
    table.remove(held_keys[b],tab.key(held_keys[b],p))
    bank[b][p].drone = false
  end
end

function grid_actions.add_held_key(b,p)
  table.insert(held_keys[b],p)
end

function grid_actions.bank_pad_down(i,p)
  if bank[i].focus_hold == false then
    if (not grid_alt and not _live.enabled) or _live.enabled then
      if params:string("grid_size") == "128" then
        if grid_page == 0 then
          selected[i].x = _arps.index_to_grid_pos(p,4)[2] + (5*(i-1))
          selected[i].y = 9-_arps.index_to_grid_pos(p,4)[1]
        elseif grid_page == 2 then
          selected[i].x = _arps.index_to_grid_pos(p,4)[2] + (5*(i-1))
          selected[i].y = 9-_arps.index_to_grid_pos(p,4)[1]
        end
      elseif params:string("grid_size") == "64" then
        selected[i].x = x
        selected[i].y = y
      end
      selected[i].id = p
      bank[i].id = selected[i].id
      page.loops.meta_pad[i] = bank[i].id
      which_bank = i
      if menu == 11 then
        help_menu = "banks"
      end
      pad_clipboard = nil
      if arp[i].enabled
      and not arp[i].pause
      and (not pattern_gate[i][2].active or (pattern_gate[i][2].active and pattern_gate[i][1].active))
      then
        if (rytm.track[i].k == 0 and not pattern_gate[i][3].active)
        or (rytm.track[i].k ~= 0 and not pattern_gate[i][3].active) then
          if arp[i].down == 0 and params:string("arp_"..i.."_hold_style") == "last pressed" then
            for j = #arp[i].notes,1,-1 do
              arps.remove_momentary(i,j)
            end
          end
          arps.momentary(i, bank[i].id, "on")
          arp[i].down = arp[i].down + 1
        end
      else
        -- if rytm.track[i].k == 0 then -- this needs touched up
          if (not arp[i].playing and not pattern_gate[i][1].active)
          -- or arp[i].playing and arp[i].gate.active then
          or (arp[i].playing and pattern_gate[i][2].active)
          or (arp[i].playing and not pattern_gate[i][2].active and not pattern_gate[i][1].active and not arp[i].enabled) then
            if rytm.track[i].k == 0
            or (rytm.track[i].k ~= 0 and not pattern_gate[i][3].active) then
              if not bank[i].quantized_press then
                cheat(i, bank[i].id)
                for k,v in pairs(held_keys[i]) do
                  if v == selected[i].id then
                    print("KILLING 2")
                    grid_actions.remove_held_key(i,selected[i].id)
                  end
                end
                grid_actions.add_held_key(i,selected[i].id)
              else
                quantize_events[i] = {["bank"] = i, ["pad"] = bank[i].id}
                for k,v in pairs(held_keys[i]) do
                  if v == selected[i].id then
                    print("KILLING 2")
                    grid_actions.remove_held_key(i,selected[i].id)
                  end
                end
                grid_actions.add_held_key(i,selected[i].id)
              end
            end
          end
        -- end
      end
      grid_pattern_watch(i)
      -- else
        -- table.insert(quantize_events[i],selected[i].id)
      -- end
    else
      local released_pad = p
      arps.momentary(i, released_pad, "off")
    end
  else
    if not grid_alt then
      bank[i].focus_pad = p
      mc.mft_redraw(bank[i][bank[i].focus_pad],"all")
      main_menu.change_pad_focus(i,bank[i].focus_pad)
    elseif grid_alt then
      if not pad_clipboard then
        pad_clipboard = {}
        bank[i].focus_pad = p
        -- pad_copy(pad_clipboard, bank[i][bank[i].focus_pad])
        pad_clipboard = deep_copy(bank[i][bank[i].focus_pad])
      else
        bank[i].focus_pad = p
        -- pad_copy(bank[i][bank[i].focus_pad], pad_clipboard)
        bank[i][bank[i].focus_pad] = deep_copy(pad_clipboard)
        bank[i][bank[i].focus_pad].bank_id = i
        pad_clipboard = nil
      end
    end
  end
  if menu ~= 1 then screen_dirty = true end
  grid_dirty = true
end

function grid_actions.bank_pad_up(i,p)
  if not bank[i].focus_hold then
    local released_pad = p
    -- if not grid_alt then
    if (not grid_alt and not _live.enabled) or _live.enabled then
      if not bank[i][released_pad].drone then
        grid_actions.remove_held_key(i,released_pad)
      end
    elseif grid_alt then
      if not _live.enabled then
        grid_actions.drone_pad(i,released_pad)
      end
    end
    if bank[i][released_pad].play_mode == "momentary" and released_pad == selected[i].id then
      softcut.rate(i+1,0)
      softcut.position(i+1,bank[i][released_pad].start_point)
      softcut.loop_start(i+1,bank[i][released_pad].start_point)
      softcut.loop_end(i+1,bank[i][released_pad].end_point)
    end
    if not arp[i].enabled or (arp[i].enabled and arp[i].pause) then
      if not grid_alt then
        grid_actions.kill_note(i,released_pad)
      elseif grid_alt then
      end
    end

    if arp[i].enabled
    and not pattern_gate[i][1].active
    and pattern_gate[i][2].active
    then
      if not grid_alt then
        grid_actions.kill_note(i,released_pad)
      end
    end


    if arp[i].enabled
    and not arp[i].pause
    -- and (not pattern_gate[i][2].active or (pattern_gate[i][2].active and grid_pat[i].rec == 1) and pattern_gate[i][1].active)
    and (not pattern_gate[i][2].active or (pattern_gate[i][2].active and pattern_gate[i][1].active))
    then
      if (arp[i].enabled and not arp[i].hold) or (menu == 9 and not arp[i].hold) then
        if params:string("arp_"..i.."_hold_style") ~= "sequencer" then
          arps.momentary(i, released_pad, "off")
        end
        arp[i].down = arp[i].down - 1
      elseif (arp[i].enabled and arp[i].hold and not arp[i].pause) or (menu == 9 and arp[i].hold and not arp[i].pause) then
        arp[i].down = arp[i].down - 1
      end
    end
    if grid_pat[i].rec ~= 0 then
      grid_pattern_watch(i,"release",released_pad)
    end
  end
  if menu ~= 1 then screen_dirty = true end
  grid_dirty = true
end

function grid_actions.grid_pat_handler(i)
  if grid_pat[i].quantize == 0 then -- still relevant
    if bank[i].alt_lock and not grid_alt then
      if grid_pat[i].play == 1 then
        grid_pat[i].overdub = grid_pat[i].overdub == 0 and 1 or 0
      end
    else
      if grid_alt then -- still relevant
        if grid_pat[i].rec == 1 then
          grid_actions.rec_stop(i)
        end
        -- grid_pat[i]:stop()
        stop_pattern(grid_pat[i])
        --grid_pat[i].external_start = 0
        grid_pat[i].tightened_start = 0
        grid_pat[i]:clear()
        pattern_saver[i].load_slot = 0
      elseif grid_pat[i].rec == 1 then -- still relevant
        grid_actions.rec_stop(i)
        midi_clock_linearize(i)
        if grid_pat[i].auto_snap == 1 then
          print("auto-snap")
          snap_to_bars(i,how_many_bars(i))
        end
        if grid_pat[i].mode ~= "quantized" then
          --grid_pat[i]:start()
          start_pattern(grid_pat[i])
        --TODO: CONFIRM THIS IS OK...
        elseif grid_pat[i].mode == "quantized" then
          start_pattern(grid_pat[i])
        end
        grid_pat[i].loop = 1
      elseif grid_pat[i].count == 0 then
        if grid_pat[i].playmode ~= 2 then
          if not transport.is_running then
            print("starting transport...")
            transport.toggle_transport()
          end
          grid_pat[i]:rec_start()
        --new!
        else
          grid_pat[i].rec_clock = clock.run(synced_record_start,grid_pat[i],i)
        end
        --/new!
      elseif grid_pat[i].play == 1 then
        --grid_pat[i]:stop()
        stop_pattern(grid_pat[i])
      else
        start_pattern(grid_pat[i])
      end
    end
  else
    if grid_alt then
      grid_actions.rec_stop(i)
      -- grid_pat[i]:stop()
      stop_pattern(grid_pat[i])
      grid_pat[i].tightened_start = 0
      grid_pat[i]:clear()
      pattern_saver[i].load_slot = 0
    else
      --table.insert(grid_pat_quantize_events[i],i)
      better_grid_pat_q_clock(i)
    end
  end
  if menu == 11 then
    help_menu = "grid patterns"
    which_bank = i
  end
end

return grid_actions