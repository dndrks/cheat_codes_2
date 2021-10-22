grid_actions = {}

held_query = {}
for i = 1,3 do
  held_query[i] = 0
end

grid_clip_key_held = false
sample_selector_active = false
last_grid_page_128 = 0
last_grid_page_128_horizontal = 0

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

last_global_level = {1,1,1}
global_mute_modifier = {false,false,false}

function grid_actions.init(x,y,z)
  
  if osc_communication == true then osc_communication = false end
  
  if params:string("grid_size") == "128" and params:string("128_orientation") == "vertical" then

    if grid_page == 0 then
      
      for i = 1,3 do
        if grid_alt or bank[i].alt_lock then
          if x == 1+(5*(i-1)) and y == 1 and z == 1 then
            bank[i].focus_hold = not bank[i].focus_hold
            if menu == 2 then
              page.loops.meta_pad[i] = bank[i].focus_pad
            end
            mc.mft_redraw(bank[i][bank[i].focus_hold and bank[i].focus_pad or bank[i].id],"all")
          end
        end
      end
      
      for i = 1,3 do
        if z == 1 and x > 0 + (5*(i-1)) and x <= 4 + (5*(i-1)) and y >=5 then
          if bank[i].focus_hold == false then
            grid_actions.pad_down(i,(math.abs(y-9)+((x-1)*4))-(20*(i-1)))
          else
            if not grid_alt then
              bank[i].focus_pad = (math.abs(y-9)+((x-1)*4))-(20*(i-1))
              page.loops.meta_pad[i] = bank[i].focus_pad
              mc.mft_redraw(bank[i][bank[i].focus_pad],"all")
            elseif grid_alt then
              if not pad_clipboard then
                pad_clipboard = {}
                bank[i].focus_pad = (math.abs(y-9)+((x-1)*4))-(20*(i-1))
                pad_copy(pad_clipboard, bank[i][bank[i].focus_pad])
              else
                bank[i].focus_pad = (math.abs(y-9)+((x-1)*4))-(20*(i-1))
                pad_copy(bank[i][bank[i].focus_pad], pad_clipboard)
                pad_clipboard = nil
              end
            end
          end
          if menu ~= 1 then screen_dirty = true end
        elseif z == 0 and x > 0 + (5*(i-1)) and x <= 4 + (5*(i-1)) and y >=5 then
          if not bank[i].focus_hold then
            grid_actions.pad_up(i,(math.abs(y-9)+((x-1)*4))-(20*(i-1)))
          end
        end
      end
      
      -- zilchmo 3+4 handling
      if x == 4 or x == 5 or x == 9 or x == 10 or x == 14 or x == 15 then
        if ((x == 4 or x == 9 or x == 14) and y <= 3) or ((x == 5 or x == 10 or x == 15) and y <= 4) then
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
      --/ zilchmo 3+4 handling

      if x == 3 or x == 8 or x == 13 then
        if y <= 2 then
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

      
      for k = 1,1 do
        for i = 1,3 do
          if z == 0 and x == (k+1)+(5*(i-1)) and y<=k then
            grid_actions.grid_pat_handler(i)
          end
        end
      end
      
      for i = 4,2,-1 do
        if x == 16 and y == i and z == 0 then
          local current = math.abs(y-5)
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
      
      for i = 1,3 do
        if x == (3)+(5*(i-1)) and y == 4 and z == 1 then
          grid_actions.toggle_pad_loop(i)
        end
      end
      
      if x == 16 and y == 8 then
        grid_alt = z == 1 and true or false
        arc_alt = z
        if menu ~= 1 then screen_dirty = true end
      end
      
      if y == 4 or y == 3 or y == 2 then
        if x == 1 or x == 6 or x == 11 then
          if not sample_selector_active then
            local which_pad = nil
            local current = util.round(math.sqrt(math.abs(x-2)))
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
          end
          if grid_clip_key_held and z == 1 then
            if not sample_selector_active then
              -- local current = util.round(math.sqrt(math.abs(x-2)))
              -- _norns.key(1,1)
              -- _norns.key(1,0)
              -- fileselect.enter(_path.audio,function(n) _ca.sample_callback(n,bank[current][bank[current].id].clip) end)
              -- sample_selector_active = true
            end
          end
          if z == 0 and not sample_selector_active then
            local current = util.round(math.sqrt(math.abs(x-2)))
            if menu ~= 1 then screen_dirty = true end
            if bank[current].focus_hold == false then
              if params:string("preview_clip_change") == "yes" or bank[current][bank[current].id].loop then
                cheat(current,bank[current].id)
              end
            end
          end
        end
      end
      
      for i = 4,3,-1 do
        for j = 2,12,5 do
          if x == j and y == 3 then
            grid_clip_key_held = z == 1 and true or false
          end
          if x == j and y == i and z == 1 then
            local which_pad = nil
            
            if not bank[math.sqrt(math.abs(x-3))].alt_lock and not grid_alt then
              local current = math.sqrt(math.abs(x-3))
              local target = bank[current].focus_hold == false and bank[current][bank[current].id] or bank[current][bank[current].focus_pad]
              local old_mode = target.mode
              target.mode = math.abs(i-5)
              if old_mode ~= target.mode then
                _ca.change_mode(target, old_mode)
              end

            elseif bank[math.sqrt(math.abs(x-3))].alt_lock or grid_alt then
              for k = 1,16 do
                local current = math.sqrt(math.abs(x-3))
                local old_mode = bank[current][k].mode
                bank[current][k].mode = math.abs(i-5)
                if old_mode ~= bank[current][k].mode then
                  _ca.change_mode(bank[current][k], old_mode)
                end
              end
            end

            local current = math.sqrt(math.abs(x-3))
            if bank[current].focus_hold == false then
              which_pad = bank[current].id
            else
              which_pad = bank[current].focus_pad
            end


            if bank[current].focus_hold == false then
              if params:string("preview_clip_change") == "yes" then
                local current = math.sqrt(math.abs(x-3))
                cheat(current,bank[current].id)
              end
            end

            if menu == 11 then
              which_bank = current
              help_menu = "mode"
            end
          end
        end
      end
      
      for i = 7,5,-1 do
        if x == 16 and z == 1 and y == i then
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
      end
      

      for i = 8,6,-1 do
        if x == 5 or x == 10 or x == 15 then
          if y == i then
            if not grid_alt then
              if z == 1 then
                table.insert(arc_switcher[x/5],y)
                held_query[x/5] = #arc_switcher[x/5]
              elseif z == 0 then
                held_query[x/5] = held_query[x/5] - 1
                if held_query[x/5] == 0 then
                  if #arc_switcher[x/5] == 1 then
                    if arc_switcher[x/5][1] == 8 then
                      arc_param[x/5] = 1
                    elseif arc_switcher[x/5][1] == 7 then
                      arc_param[x/5] = 2
                    elseif arc_switcher[x/5][1] == 6 then
                      arc_param[x/5] = 3
                    end
                  elseif #arc_switcher[x/5] == 2 then
                    total = arc_switcher[x/5][1] + arc_switcher[x/5][2]
                    if total == 15 then
                      arc_param[x/5] = 5
                    elseif total == 13 then
                      arc_param[x/5] = 6
                    end
                  elseif #arc_switcher[x/5] == 3 then
                    arc_param[x/5] = 4
                  elseif #arc_switcher[x/5] > 3 then
                    arc_switcher[x/5] = {}
                  end
                  arc_switcher[x/5] = {}
                end
              end
            elseif grid_alt then
              if y == 8 then
                -- sixteen_slices(x/5)
              elseif y == 7 then
                -- rec_to_pad(x/5)
              elseif y == 6 then
                -- pad_to_rec(x/5)
              end
            end
          end
        end
      end
      
      if y == 5 then
        --CROW
        -- if z == 1 then
        --   for i = 1,3 do
        --     if bank[i].focus_hold == true then
        --       if x == i*5 then
        --         bank[i][bank[i].focus_pad].crow_pad_execute = (bank[i][bank[i].focus_pad].crow_pad_execute + 1)%2
        --         if grid_alt then
        --           for j = 1,16 do
        --             bank[i][j].crow_pad_execute = bank[i][bank[i].focus_pad].crow_pad_execute
        --           end
        --         end
        --       end
        --     end
        --   end
        -- end
        if x == 5 or x == 10 or x == 15 then
          if not grid_alt then
            bank[x/5].alt_lock = z == 1 and true or false
          else
            if z == 1 then
              bank[x/5].alt_lock = not bank[x/5].alt_lock
            end
          end
        end
      end
      
      --- new page focus
      for k = 4,1,-1 do
        for i = 1,3 do
          if z == 1 and x == k+(5*(i-1)) and y == k then
            
            ---
            --if not grid_alt then
            if not bank[i].alt_lock and not grid_alt then
              if y == 3 then
                grid_actions.arp_handler(i)
              else
                if key1_hold == true then key1_hold = false end
                if y == 4 then
                  --CROW
                  bank[i][bank[i].focus_pad].crow_pad_execute = (bank[i][bank[i].focus_pad].crow_pad_execute + 1)%2
                end
                if menu ~= 1 then screen_dirty = true end
              end
            elseif bank[i].alt_lock or grid_alt then
              if y == 2 then
                random_grid_pat(math.ceil(x/4),3)
              end
              if y == 3 then
                grid_actions.kill_arp(i)
              end
              if y == 4 and not bank[i].focus_hold then
                local current = math.floor(x/5)+1
                for j = 1,16 do
                  bank[current][j].rate = 1
                  if bank[current][j].fifth == true then
                    bank[current][j].fifth = false
                  end
                end
                -- softcut.rate(current+1,1*bank[current][bank[current].id].offset)
                softcut.rate(current+1,_loops.get_total_pitch_offset(current,bank[current].id))
              elseif y == 4 and bank[i].focus_hold then
                bank[i][bank[i].focus_pad].crow_pad_execute = (bank[i][bank[i].focus_pad].crow_pad_execute + 1)%2
                for j = 1,16 do
                  bank[i][j].crow_pad_execute = bank[i][bank[i].focus_pad].crow_pad_execute
                end
              end
            end
            ---
          end
        end
      end
      
    elseif grid_page == 1 then

      local nx = _t(x,y)[1]
      local ny = _t(x,y)[2]

      -- PATTERNS:
      if ny == 1 or ny == 6 or ny == 11 then
        local current = math.floor(ny/5)+1
        if z == 1 then
          saved_pat = pattern_saver[current].saved[nx] -- hate that this is global...
          pattern_saver[current].source = current
          pattern_saver[current].save_slot = nx
          pattern_saver[current].clock = clock.run(test_save,current)
        elseif z == 0 then
          if pattern_saver[current].clock then
            clock.cancel(pattern_saver[current].clock)
          end
          pattern_saver[current].active = false
          if not grid_alt and saved_pat == 1 then
            if pattern_saver[current].saved[nx] == 1 then
              pattern_saver[current].load_slot = nx
              test_load((nx)+(8*(current-1)),current,"from_grid")
            end
          end
        end
      end

    -- SNAPSHOTS:

      -- save:
      if ny == 2 or ny == 3 or ny == 7 or ny == 8 or ny == 12 or ny == 13 then
        local current = math.floor(ny/5)+1
        nx = (ny == 2 or ny == 7 or ny == 12) and nx or nx+8
        if z == 1 then
          if not grid_alt then
            if not bank[current].snapshot_mod then
              if not bank[current].snapshot[nx].saved then
                bank[current].snapshot_saver_clock = clock.run(_snap.save_to_slot,current,nx)
              else
                local modifier, style = 0,"beats"
                if bank[current].restore_mod then
                  modifier =  bank[current].snapshot[nx].restore_times[bank[current].snapshot[nx].restore_times.mode][bank[current].restore_mod_index]
                  style = bank[current].snapshot[nx].restore_times.mode
                end
                _snap.restore(current,nx,modifier,style)
              end
            else
              bank[current].snapshot_mod_index = nx
            end
          else
            _snap.clear(current,nx)
          end
        else
          if bank[current].snapshot_saver_clock ~= nil then
            clock.cancel(bank[current].snapshot_saver_clock)
          end
        end
      end

      -- mod_time:
      if ny == 4 or ny == 9 or ny == 14 then
        local current = math.floor(ny/5)+1
        if z == 1 then
          bank[current].restore_mod = true
          bank[current].restore_mod_index = nx
        elseif not grid_alt then -- don't need to filter out if z == 0 cuz it always is otherwise...
          bank[current].restore_mod = false
        end
      end
      
      if nx == 1 and ny == 16 then
        grid_alt = z == 1 and true or false
        if menu ~= 1 then screen_dirty = true end
      elseif nx == 2 and ny == 16 then
        pattern_saver_glue = z == 1 and true or false
      end

      if nx == 7 and ny == 16 and grid_alt and z == 1 then
        if transport.is_running then
          clock.transport.stop()
        else
          if params:string("clock_source") == "internal" then
            clock.internal.start(-0.1)
          else
            transport.cycle = 1
            clock.transport.start()
          end
          transport.pending = true
        end
        screen_dirty = true
      end

      if nx == 6 and ny == 16 and grid_alt and z == 1 then
        params:set("metronome_audio_state",params:get("metronome_audio_state") == 1 and 2 or 1)
      end

      -- mod modifier
      if nx == 1 and (ny == 5 or ny == 10 or ny == 15) then
        local current = math.floor(ny/5)
        bank[current].snapshot_mod = z == 1 and true or false
      end

      -- mods to modify
      if (nx == 4 or nx == 5 or nx == 6 or nx == 7 or nx == 8) and (ny == 5 or ny == 10 or ny == 15) and z == 1 then
        local current = math.floor(ny/5)
        local prms = {"rate","start_point","end_point","level","tilt"}
        if bank[current].snapshot_mod then
          bank[current].snapshot[bank[current].snapshot_mod_index].restore[prms[nx-3]] = not bank[current].snapshot[bank[current].snapshot_mod_index].restore[prms[nx-3]]
        end
      end

      -- toggle song mode on/off
      if nx == 8 and (ny == 5 or ny == 10 or ny == 15) and z == 1 then
        local current = math.floor(ny/5)
        if not bank[current].snapshot_mod and grid_alt then
          song_atoms.bank[current].active = not song_atoms.bank[current].active
        end
      end
    
    elseif grid_page == 2 then
      local nx = _t(x,y)[1]
      local ny = _t(x,y)[2]
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

      if x == 9 and (y == 2 or y == 7) and z == 1 then
        params:set("delay "..(y == 7 and "L:" or "R:").." external input", params:get("delay "..(y == 7 and "L:" or "R:").." external input") > 0 and 0 or 1)
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

      if (nx == 1 or nx == 8) and (ny == 9) and z == 1 then
        if not grid_alt then
          del.reset_to_start(nx == 1 and 1 or 2)
        else
          del.reset_to_start(1)
          del.reset_to_start(2)
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
        if not grid_alt then
          if z == 1 then
            local xval = {9,4,-1}
            selected[id].x = x - xval[id]
            selected[id].y = y + 2
            selected[id].id = (math.abs(selected[id].y-9)+((selected[id].x-1)*4))-(20*(id-1))
            bank[id].id = selected[id].id
            -- if (arp[id].hold or (menu == 9)) and grid_pat[id].rec == 0 and not arp[id].pause then
            if (arp[id].enabled or (menu == 9)) and grid_pat[id].rec == 0 and not arp[id].pause then
              if arp[id].down == 0 and params:string("arp_"..id.."_hold_style") == "last pressed" then
                for i = #arp[id].notes,1,-1 do
                  table.remove(arp[id].notes,i)
                end
              end
              arp[id].time = bank[id][bank[id].id].arp_time
              arps.momentary(id, bank[id].id, "on")
              arp[id].down = arp[id].down + 1
            else
              if (transport.is_running and rytm.track[id].k == 0) or (not transport.is_running) then
                if bank[id].quantize_press == 0 then
                  cheat(id, bank[id].id)
                else
                  quantize_events[id] = {["bank"] = id, ["pad"] = bank[id].id}
                end
              end
              grid_pattern_watch(id)
            end
          else
            -- if not arp[id].hold then
            if not bank[id].focus_hold then
              if arp[id].enabled and not arp[id].hold then
                local xval = {9,4,-1}
                local released_pad = (math.abs((y + 2)-9)+(((x - xval[id])-1)*4))-(20*(id-1))
                arps.momentary(id, released_pad, "off")
                arp[id].down = arp[id].down - 1
              elseif arp[id].enabled and arp[id].hold then
                arp[id].down = arp[id].down - 1
              end
            end
          end
        else
          if z == 1 then
            local xval = {9,4,-1}
            local released_pad = (math.abs((y + 2)-9)+(((x - xval[id])-1)*4))-(20*(id-1))
            arps.momentary(id, released_pad, "off")
          end
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
        -- grid.alt_delay = not grid.alt_delay
        -- grid_alt = not grid_alt
        grid_alt = z == 1 and true or false
      end

    end
    

    if x == 16 and y == 1 and z == 1 then
      if grid_page == 0 then
        if grid_alt then
          grid_page = 1
        else
          grid_page = 2
        end
        last_grid_page_128 = 0
      elseif grid_page == 1 then
        if not grid_alt then
          grid_page = 2
        else
          grid_page = last_grid_page_128
        end
      elseif grid_page == 2 then
        if not grid_alt then
          grid_page = 0
        else
          grid_page = 1
        end
        last_grid_page_128 = 2
      end
    end

    grid_dirty = true
    
  -- 64 grid / grid 64
  elseif params:string("grid_size") == "128" and params:string("128_orientation") == "horizontal" then
    local b = bank[bank_128]

    if x <=3 and y == 1 and z ==1  then
      bank_128 = x
      b = bank[x]
      if menu == 2 then
        page.loops.sel = x
      elseif menu == 7 then
        page.time_sel = x
      elseif menu == 8 then
        rytm.track_edit = x
      elseif menu == 9 then
        page.arp_page_sel = x
      elseif menu == 10 then
        page.rnd_page = x
      elseif menu == "MIDI_config" then
        page.midi_bank = x
      end
      screen_dirty = true
    end
    
    if grid_alt or b.alt_lock then
      if x == 8 and y == 4 and z == 1 then
        b.focus_hold = not b.focus_hold
        mc.mft_redraw(b[b.focus_hold and b.focus_pad or b.id],"all")
      end
    end

    --arc parameters
    if y == 2 then
      if x == 6 or x ==7 or x == 8 then
        if not grid_alt then
          if z == 1 then
            table.insert(arc_switcher[bank_128],x)
            held_query[bank_128] = #arc_switcher[bank_128]
          elseif z == 0 then
            held_query[bank_128] = held_query[bank_128] - 1
            if held_query[bank_128] == 0 then
              if #arc_switcher[bank_128] == 1 then
                arc_param[bank_128] = arc_switcher[bank_128][1] == 6 and 1 or (arc_switcher[bank_128][1] == 7 and 2 or 3)
              elseif #arc_switcher[bank_128] == 2 then
                total = arc_switcher[bank_128][1] + arc_switcher[bank_128][2]
                if total == 13 then
                  arc_param[bank_128] = 5
                elseif total == 15 then
                  arc_param[bank_128] = 6
                end
              elseif #arc_switcher[bank_128] == 3 then
                arc_param[bank_128] = 4
              elseif #arc_switcher[bank_128] > 3 then
                arc_switcher[bank_128] = {}
              end
              arc_switcher[bank_128] = {}
            end
          end
        end
      end
    end
    
    --arc recorders
    if x == 8 and y == 3 and z == 0 then
      local current = bank_128
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
    
    if z == 1 and x <= 4 and y >= 4 and y <= 7 then
      if b.focus_hold == false then
        if not grid_alt then
          selected[bank_128].x = (y-3)+(5*(bank_128-1))
          selected[bank_128].y = 9-x
          selected[bank_128].id = (4*(y-4))+x
          b.id = selected[bank_128].id
          which_bank = bank_128
          pad_clipboard = nil
          if b.quantize_press == 0 then
            if arp[bank_128].enabled and grid_pat[bank_128].rec == 0 and not arp[bank_128].pause then
              if arp[bank_128].down == 0 and params:string("arp_"..bank_128.."_hold_style") == "last pressed" then
                for j = #arp[bank_128].notes,1,-1 do
                  table.remove(arp[bank_128].notes,j)
                end
              end
              arp[bank_128].time = b[b.id].arp_time
              arps.momentary(bank_128, b.id, "on")
              arp[bank_128].down = arp[bank_128].down + 1
            else
              if (transport.is_running and rytm.track[bank_128].k == 0) or (not transport.is_running) then
                cheat(bank_128, b.id)
              end
            end
          else
            if arp[bank_128].enabled and grid_pat[bank_128].rec == 0 and not arp[bank_128].pause then
              if arp[bank_128].down == 0 and params:string("arp_"..bank_128.."_hold_style") == "last pressed" then
                for j = #arp[bank_128].notes,1,-1 do
                  table.remove(arp[bank_128].notes,j)
                end
              end
              arp[bank_128].time = b[b.id].arp_time
              arps.momentary(bank_128, b.id, "on")
              arp[bank_128].down = arp[bank_128].down + 1
            else
              if (transport.is_running and rytm.track[bank_128].k == 0) or (not transport.is_running) then
                quantize_events[bank_128] = {["bank"] = bank_128, ["pad"] = bank[bank_128].id}
              end
            end
          end
          grid_pattern_watch(bank_128)
        else
          local released_pad = (4*(y-4))+x
          arps.momentary(i, released_pad, "off")
        end
      else
        if not grid_alt then
          b.focus_pad = (4*(y-4))+x
          mc.mft_redraw(b[b.focus_pad],"all")
        elseif grid_alt then
          if not pad_clipboard then
            pad_clipboard = {}
            b.focus_pad = (4*(y-4))+x
            pad_copy(pad_clipboard, b[b.focus_pad])
          else
            b.focus_pad = (4*(y-4))+x
            pad_copy(b[b.focus_pad], pad_clipboard)
            pad_clipboard = nil
          end
        end
      end
      if menu ~= 1 then screen_dirty = true end
    elseif z == 0 and x <= 4 and y >= 4 and y <= 7 then
      if not b.focus_hold then
        local released_pad = (4*(y-4))+x
        if b[released_pad].play_mode == "momentary" then
          softcut.rate(bank_128+1,0)
        end
        if (arp[bank_128].enabled and not arp[bank_128].hold) or (menu == 9 and not arp[bank_128].hold) then
          arps.momentary(bank_128, released_pad, "off")
          arp[bank_128].down = arp[bank_128].down - 1
        elseif (arp[bank_128].enabled and arp[bank_128].hold and not arp[bank_128].pause) or (menu == 9 and arp[bank_128].hold and not arp[bank_128].pause) then
          arp[bank_128].down = arp[bank_128].down - 1
        end
      end
    end
    
    -- zilchmo 3+4 handling
    -- if x == 4 or x == 5 or x == 9 or x == 10 or x == 14 or x == 15 then
    if (y == 6 or y == 7 or y == 8) and (x == 5 or x == 6 or x == 7 or x == 8) then
      if ((y == 6 and x >=7) or (y == 7 and x >= 6) or (y == 8 and x >= 5)) then
        local zilch_id = (y == 8 and 4 or (y == 7 and 3 or 2))
        local zmap = zilches[zilch_id]
        local k1 = bank_128
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

    if z == 0 and x == 8 and y == 5 then
      local i = bank_128
      if grid_pat[i].quantize == 0 then -- still relevant
        if bank[i].alt_lock and not grid_alt then
          if grid_pat[i].play == 1 then
            grid_pat[i].overdub = grid_pat[i].overdub == 0 and 1 or 0
          end
        else
          if grid_alt then -- still relevant
            if grid_pat[i].rec == 1 then
              -- grid_actions.rec_stop(i)
              grid_pat[i]:rec_stop()
            end
            -- grid_pat[i]:stop()
            stop_pattern(grid_pat[i])
            --grid_pat[i].external_start = 0
            grid_pat[i].tightened_start = 0
            grid_pat[i]:clear()
            pattern_saver[i].load_slot = 0
          elseif grid_pat[i].rec == 1 then -- still relevant
            -- grid_actions.rec_stop(i)
            grid_pat[i]:rec_stop()
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
                if transport.is_running then
                  clock.transport.stop()
                else
                  if params:string("clock_source") == "internal" then
                    -- clock.internal.start(3.9)
                    clock.internal.start(-0.1)
                  -- elseif params:string("clock_source") == "link" then
                  else
                    transport.cycle = 1
                    clock.transport.start()
                  end
                  transport.pending = true
                  -- clock.transport.start()
                end
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
          -- grid_actions.rec_stop(i)
          grid_pat[i]:rec_stop()
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
    
    if x == 5 and y == 6 and z == 1 then
      grid_actions.toggle_pad_loop(bank_128)
    end
    
    if x == 1 and y == 8 then
      grid_alt = z == 1 and true or false
      arc_alt = z
      if menu ~= 1 then screen_dirty = true end
    end
    
    if x == 5 or x == 6 or x == 7 then
      if y == 4 then
        local which_pad = nil
        local current = bank_128
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

    if (y == 5 and (x == 5 or x == 6)) and z == 1 then
      local which_pad = nil
      local current = bank_128
      
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
    
    if y == 2 and x <= 3 and z == 1 then
      if rec.focus ~= x then
        rec.focus = x
      else
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
    
    if y == 8 and x == 4 then
      if not grid_alt then
        bank[bank_128].alt_lock = z == 1 and true or false
      else
        if z == 1 then
          bank[bank_128].alt_lock = not bank[bank_128].alt_lock
        end
      end
    end
    
    if y == 6 and x == 6 and z == 1 then
      if not bank[bank_128].alt_lock and not grid_alt then
        grid_actions.arp_handler(bank_128)
      else
        grid_actions.kill_arp(bank_128)
      end
    end

    if y == 7 and x == 5 and z == 1 then
      local i = bank_128
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
          bank[i][bank[i].focus_pad].crow_pad_execute = (bank[i][bank[i].focus_pad].crow_pad_execute + 1)%2
          for j = 1,16 do
            bank[i][j].crow_pad_execute = bank[i][bank[i].focus_pad].crow_pad_execute
          end
        end
      else
        if bank[i].focus_hold then
          bank[i][bank[i].focus_pad].crow_pad_execute = (bank[i][bank[i].focus_pad].crow_pad_execute + 1)%2
        end
      end
      screen_dirty = true
    end

    if y == 5 and x == 7 and z == 1 and (grid_alt or bank[bank_128].alt_lock) then
      random_grid_pat(bank_128,3)
    end

    if x == 8 and y == 1 and z == 1 then
      if grid_alt then
        last_grid_page_64 = grid_page_64
        grid_page_64 = 2
      else
        grid_page_64 = 1
      end
    end

    if grid_page_128_horizontal == 0 then
      if x == 11 or x == 14 then
        if y <= 2 and z == 1 then
          local changes = {"double", "halve", "sync"}
          del.change_duration(x == 11 and 1 or 2, x == 11 and 2 or 1, changes[y])
        elseif y == 3 and z == 1 then
          del.quick_action(x == 11 and 1 or 2, "reverse")
        elseif y >= 4 and y <= 8 then
          if z == 1 then
            del.set_value(x == 11 and 1 or 2, math.abs(3-y), "level")
          end
        -- elseif y == 9 then
        --   del.quick_action(x == 3 and 1 or 2,"level_mute",z)
        end
      elseif x == 12 or x == 13 then
        if y >= 4 and y <= 8 then
          if z == 1 then
            del.set_value(x == 12 and 1 or 2, math.abs(3-y), "feedback")
          end
        elseif y == 1 and z == 1 then
          del.change_rate(x == 12 and 1 or 2, "double")
        elseif y == 2 and z == 1 then
          del.change_rate(x == 12 and 1 or 2, "halve")
        elseif y == 3 then
          del.change_rate(x == 12 and 1 or 2,z == 1 and "wobble" or "restore")
        -- elseif y == 9 then
        --   if grid_alt then
        --     del.quick_action(6-y, "clear")
        --   end
        --   del.quick_action(6-y,"feedback_mute",z)
        end
      elseif x == 10 or x == 15 then
        if y == 8 then
          del.quick_action(x == 10 and 1 or 2,"feedback_mute",z)
        elseif y == 7 then
          del.quick_action(x == 10 and 1 or 2,"level_mute",z)
        elseif (y == 1 or y == 2 or y == 3) and z == 1 then
          delay_grid.bank = y
          local current_level = x == 10 and bank[delay_grid.bank][bank[delay_grid.bank].id].left_delay_level or bank[delay_grid.bank][bank[delay_grid.bank].id].right_delay_level
          del.set_value(x == 10 and 1 or 2, current_level > 0 and 5 or 1,"send all")
        elseif y == 4 and z == 1 then
          params:set("delay "..(x == 10 and "L:" or "R:").." external input", params:get("delay "..(x == 10 and "L:" or "R:").." external input") > 0 and 0 or 1)
        end
        -- if x >= 10 and x <=14 then
        --   if z == 1 then
        --     del.set_value(y == 8 and 1 or 2,x-9,grid_alt == true and "send all" or "send")
        --   end
        -- elseif x == 15 then
        --   del.quick_action(y == 8 and 1 or 2,"send_mute",z)
        -- end
      end

      if x == 9 or x == 16 then
        if y >= 3 and y <= 7 then
          if z == 1 then
            local bundle = (y-2)
            local target = x == 9 and 1 or 2
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
            delay[x<=10 and 1 or 2].saver_active = false
          end
        end
      end

      if x == 16 and y == 1 and z == 1 then
        if grid_alt then
          last_grid_page_128_horizontal = grid_page_128_horizontal
          grid_page_128_horizontal = 2
        else
          grid_page_128_horizontal = 0
        end
      end
    elseif grid_page_128_horizontal == 1 then
    end

    grid_dirty = true

  elseif params:string("grid_size") == "64" then
    if grid_page_64 == 0 then
      
      local b = bank[bank_64]

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
          page.arp_page_sel = x
        elseif menu == 10 then
          page.rnd_page = x
        elseif menu == "MIDI_config" then
          page.midi_bank = x
        end
        screen_dirty = true
      end
      
      if grid_alt or b.alt_lock then
        if x == 8 and y == 4 and z == 1 then
          b.focus_hold = not b.focus_hold
          mc.mft_redraw(b[b.focus_hold and b.focus_pad or b.id],"all")
        end
      end

      --arc parameters
      if y == 2 then
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
      
      if z == 1 and x <= 4 and y >= 4 and y <= 7 then
        if b.focus_hold == false then
          if not grid_alt then
            selected[bank_64].x = (y-3)+(5*(bank_64-1))
            selected[bank_64].y = 9-x
            selected[bank_64].id = (4*(y-4))+x
            b.id = selected[bank_64].id
            which_bank = bank_64
            pad_clipboard = nil
            if b.quantize_press == 0 then
              if arp[bank_64].enabled and grid_pat[bank_64].rec == 0 and not arp[bank_64].pause then
                if arp[bank_64].down == 0 and params:string("arp_"..bank_64.."_hold_style") == "last pressed" then
                  for j = #arp[bank_64].notes,1,-1 do
                    table.remove(arp[bank_64].notes,j)
                  end
                end
                arp[bank_64].time = b[b.id].arp_time
                arps.momentary(bank_64, b.id, "on")
                arp[bank_64].down = arp[bank_64].down + 1
              else
                if (transport.is_running and rytm.track[bank_64].k == 0) or (not transport.is_running) then
                  cheat(bank_64, b.id)
                end
              end
            else
              if arp[bank_64].enabled and grid_pat[bank_64].rec == 0 and not arp[bank_64].pause then
                if arp[bank_64].down == 0 and params:string("arp_"..bank_64.."_hold_style") == "last pressed" then
                  for j = #arp[bank_64].notes,1,-1 do
                    table.remove(arp[bank_64].notes,j)
                  end
                end
                arp[bank_64].time = b[b.id].arp_time
                arps.momentary(bank_64, b.id, "on")
                arp[bank_64].down = arp[bank_64].down + 1
              else
                if (transport.is_running and rytm.track[bank_64].k == 0) or (not transport.is_running) then
                  quantize_events[bank_64] = {["bank"] = bank_64, ["pad"] = bank[bank_64].id}
                end
              end
            end
            grid_pattern_watch(bank_64)
          else
            local released_pad = (4*(y-4))+x
            arps.momentary(i, released_pad, "off")
          end
        else
          if not grid_alt then
            b.focus_pad = (4*(y-4))+x
            mc.mft_redraw(b[b.focus_pad],"all")
          elseif grid_alt then
            if not pad_clipboard then
              pad_clipboard = {}
              b.focus_pad = (4*(y-4))+x
              pad_copy(pad_clipboard, b[b.focus_pad])
            else
              b.focus_pad = (4*(y-4))+x
              pad_copy(b[b.focus_pad], pad_clipboard)
              pad_clipboard = nil
            end
          end
        end
        if menu ~= 1 then screen_dirty = true end
      elseif z == 0 and x <= 4 and y >= 4 and y <= 7 then
        if not b.focus_hold then
          local released_pad = (4*(y-4))+x
          if b[released_pad].play_mode == "momentary" then
            softcut.rate(bank_64+1,0)
          end
          if (arp[bank_64].enabled and not arp[bank_64].hold) or (menu == 9 and not arp[bank_64].hold) then
            arps.momentary(bank_64, released_pad, "off")
            arp[bank_64].down = arp[bank_64].down - 1
          elseif (arp[bank_64].enabled and arp[bank_64].hold and not arp[bank_64].pause) or (menu == 9 and arp[bank_64].hold and not arp[bank_64].pause) then
            arp[bank_64].down = arp[bank_64].down - 1
          end
        end
      end
      
      -- zilchmo 3+4 handling
      -- if x == 4 or x == 5 or x == 9 or x == 10 or x == 14 or x == 15 then
      if y == 6 or y == 7 or y == 8 then
        if ((y == 6 and x >=7) or (y == 7 and x >= 6) or (y == 8 and x >= 5)) then
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

      if z == 0 and x == 8 and y == 5 then
        local i = bank_64
        if grid_pat[i].quantize == 0 then -- still relevant
          if bank[i].alt_lock and not grid_alt then
            if grid_pat[i].play == 1 then
              grid_pat[i].overdub = grid_pat[i].overdub == 0 and 1 or 0
            end
          else
            if grid_alt then -- still relevant
              if grid_pat[i].rec == 1 then
                -- grid_actions.rec_stop(i)
                grid_pat[i]:rec_stop()
              end
              -- grid_pat[i]:stop()
              stop_pattern(grid_pat[i])
              --grid_pat[i].external_start = 0
              grid_pat[i].tightened_start = 0
              grid_pat[i]:clear()
              pattern_saver[i].load_slot = 0
            elseif grid_pat[i].rec == 1 then -- still relevant
              -- grid_actions.rec_stop(i)
              grid_pat[i]:rec_stop()
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
                  if transport.is_running then
                    clock.transport.stop()
                  else
                    if params:string("clock_source") == "internal" then
                      -- clock.internal.start(3.9)
                      clock.internal.start(-0.1)
                    -- elseif params:string("clock_source") == "link" then
                    else
                      transport.cycle = 1
                      clock.transport.start()
                    end
                    transport.pending = true
                    -- clock.transport.start()
                  end
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
            -- grid_actions.rec_stop(i)
            grid_pat[i]:rec_stop()
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
      
      if x == 5 and y == 6 and z == 1 then
        grid_actions.toggle_pad_loop(bank_64)
      end
      
      if x == 1 and y == 8 then
        grid_alt = z == 1 and true or false
        arc_alt = z
        if menu ~= 1 then screen_dirty = true end
      end
      
      if x == 5 or x == 6 or x == 7 then
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

      if (y == 5 and (x == 5 or x == 6)) and z == 1 then
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
      
      if y == 2 and x <= 3 and z == 1 then
        if rec.focus ~= x then
          rec.focus = x
        else
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
      
      if y == 8 and x == 4 then
        if not grid_alt then
          bank[bank_64].alt_lock = z == 1 and true or false
        else
          if z == 1 then
            bank[bank_64].alt_lock = not bank[bank_64].alt_lock
          end
        end
      end
      
      if y == 6 and x == 6 and z == 1 then
        if not bank[bank_64].alt_lock and not grid_alt then
          grid_actions.arp_handler(bank_64)
        else
          grid_actions.kill_arp(bank_64)
        end
      end

      if y == 7 and x == 5 and z == 1 then
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
            bank[i][bank[i].focus_pad].crow_pad_execute = (bank[i][bank[i].focus_pad].crow_pad_execute + 1)%2
            for j = 1,16 do
              bank[i][j].crow_pad_execute = bank[i][bank[i].focus_pad].crow_pad_execute
            end
          end
        else
          if bank[i].focus_hold then
            bank[i][bank[i].focus_pad].crow_pad_execute = (bank[i][bank[i].focus_pad].crow_pad_execute + 1)%2
          end
        end
        screen_dirty = true
      end

      if y == 5 and x == 7 and z == 1 and (grid_alt or bank[bank_64].alt_lock) then
        random_grid_pat(bank_64,3)
      end

      if x == 8 and y == 1 and z == 1 then
        if grid_alt then
          last_grid_page_64 = grid_page_64
          grid_page_64 = 2
        else
          grid_page_64 = 1
        end
      end

    elseif grid_page_64 == 1 then

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
        -- elseif y == 9 then
        --   if grid_alt then
        --     del.quick_action(6-y, "clear")
        --   end
        --   del.quick_action(6-y,"feedback_mute",z)
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
        -- if x >= 10 and x <=14 then
        --   if z == 1 then
        --     del.set_value(y == 8 and 1 or 2,x-9,grid_alt == true and "send all" or "send")
        --   end
        -- elseif x == 15 then
        --   del.quick_action(y == 8 and 1 or 2,"send_mute",z)
        -- end
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
      end

      if x == 8 and y == 1 and z == 1 then
        if grid_alt then
          last_grid_page_64 = grid_page_64
          grid_page_64 = 2
        else
          grid_page_64 = 0
        end
      end

    elseif grid_page_64 == 2 then
      if x == 1 and y == 8 then
        grid_alt = z == 1 and true or false
      end
      if x == 8 and y == 1 and z == 1 then
        grid_page_64 = last_grid_page_64
      end
      if y >=2 and y<= 4 then
        y = y-1
        if z == 1 then
          saved_pat = pattern_saver[y].saved[x] -- hate that this is global...
          pattern_saver[y].source = y
          pattern_saver[y].save_slot = x
          if pattern_saver[y].clock ~= nil then
            clock.cancel(pattern_saver[y].clock)
          end
          pattern_saver[y].clock = clock.run(test_save,y)
          -- print("starting save "..pattern_saver[y].clock)
        elseif z == 0 then
          if pattern_saver[y].clock ~= nil then
            clock.cancel(pattern_saver[y].clock)
          end
          pattern_saver[y].active = false
          if not grid_alt and saved_pat == 1 then
            if pattern_saver[y].saved[x] == 1 then
              pattern_saver[y].load_slot = x
              test_load(x+(8*(y-1)),y)
            end
          end
        end
      elseif y == 6 and (x == 1 or x == 2 or x == 3) then
        if z == 1 and not global_mute_modifier[x] then
          last_global_level[x] = params:get("bank level "..x)
          params:set("bank level "..x,0)
          global_mute_modifier[x] = true
        elseif z == 0 then
          global_mute_modifier[x] = false
          params:set("bank level "..x,last_global_level[x])
        end
      end
    end
    grid_dirty = true
  end
end

function grid_actions.arp_handler(i)
  if not transport.is_running then
    print("arp enabled, starting transport...")
    if transport.is_running then
      clock.transport.stop()
    else
      if params:string("clock_source") == "internal" then
        clock.internal.start(-0.1)
      else
        transport.cycle = 1
        clock.transport.start()
      end
      transport.pending = true
    end
  end
  if not arp[i].enabled then
    arp[i].enabled = true
  elseif not arp[i].hold then
    if #arp[i].notes > 0 then
      arp[i].hold = true
    else
      arp[i].enabled = false
    end
  else
    if #arp[i].notes > 0 then
      if arp[i].playing == true then
        -- arp[i].pause = true
        -- arp[i].playing = false
        arps.toggle("stop",i)
      else
        arps.toggle("start",i)
      end
    end
  end
end

function grid_actions.kill_arp(i)
  page.arp_page_sel = i
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
  arp[i].enabled = false
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

function grid_actions.index_to_grid_pos(val,columns,i)
  local x = math.fmod(val-1,columns)+1
  local y = math.modf((val-1)/columns)+1
  return {x,y}
end

function grid_actions.pad_down(i,p)
  if (not grid_alt and not _live.enabled) or _live.enabled then
    selected[i].x = grid_actions.index_to_grid_pos(p,4,i)[2] + (5*(i-1))
    selected[i].y = 9 - grid_actions.index_to_grid_pos(p,4,i)[1]
    selected[i].id = p
    bank[i].id = selected[i].id
    page.loops.meta_pad[i] = bank[i].id
    which_bank = i
    if menu == 11 then
      help_menu = "banks"
    end
    pad_clipboard = nil
    if bank[i].quantize_press == 0 then
      if arp[i].enabled and grid_pat[i].rec == 0 and not arp[i].pause then
        if arp[i].down == 0 and params:string("arp_"..i.."_hold_style") == "last pressed" then
          for j = #arp[i].notes,1,-1 do
            table.remove(arp[i].notes,j)
          end
        end
        arp[i].time = bank[i][bank[i].id].arp_time
        arps.momentary(i, bank[i].id, "on")
        arp[i].down = arp[i].down + 1
      else
        if (transport.is_running and rytm.track[i].k == 0) or (not transport.is_running) then
          cheat(i, bank[i].id)
        end
      end
    else
      if arp[i].enabled and grid_pat[i].rec == 0 and not arp[i].pause then
        if arp[i].down == 0 and params:string("arp_"..i.."_hold_style") == "last pressed" then
          for j = #arp[i].notes,1,-1 do
            table.remove(arp[i].notes,j)
          end
        end
        arp[i].time = bank[i][bank[i].id].arp_time
        arps.momentary(i, bank[i].id, "on")
        arp[i].down = arp[i].down + 1
      else
        if (transport.is_running and rytm.track[i].k == 0) or (not transport.is_running) then
          quantize_events[i] = {["bank"] = i, ["pad"] = bank[i].id}
        end
      end
    end
    grid_pattern_watch(i)
  else
    local released_pad = p
    arps.momentary(i, released_pad, "off")
  end
end

function grid_actions.pad_up(i,p)
  local released_pad = p
  if bank[i][released_pad].play_mode == "momentary" then
    softcut.rate(i+1,0)
  end
  if (arp[i].enabled and not arp[i].hold) or (menu == 9 and not arp[i].hold) then
    arps.momentary(i, released_pad, "off")
    arp[i].down = arp[i].down - 1
  elseif (arp[i].enabled and arp[i].hold and not arp[i].pause) or (menu == 9 and arp[i].hold and not arp[i].pause) then
    arp[i].down = arp[i].down - 1
  end
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
          -- grid_actions.rec_stop(i)
          grid_pat[i]:rec_stop()
        end
        -- grid_pat[i]:stop()
        stop_pattern(grid_pat[i])
        --grid_pat[i].external_start = 0
        grid_pat[i].tightened_start = 0
        grid_pat[i]:clear()
        pattern_saver[i].load_slot = 0
      elseif grid_pat[i].rec == 1 then -- still relevant
        -- grid_actions.rec_stop(i)
        grid_pat[i]:rec_stop()
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
            if transport.is_running then
              clock.transport.stop()
            else
              if params:string("clock_source") == "internal" then
                -- clock.internal.start(3.9)
                clock.internal.start(-0.1)
              -- elseif params:string("clock_source") == "link" then
              else
                transport.cycle = 1
                clock.transport.start()
              end
              transport.pending = true
              -- clock.transport.start()
            end
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
      -- grid_actions.rec_stop(i)
      grid_pat[i]:rec_stop()
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