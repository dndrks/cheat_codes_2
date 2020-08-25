grid_actions = {}

held_query = {}
for i = 1,3 do
  held_query[i] = 0
end

zilch4 = {{},{},{}}
for i = 1,3 do
  zilch4[i].held = 0
  for j = 1,4 do
    zilch4[i][j] = false
  end
end

function grid_actions.init(x,y,z)
  
  if osc_communication == true then osc_communication = false end
  
  if grid_page == 0 then
    
    for i = 1,3 do
      if grid.alt == 1 then
        if x == 1+(5*(i-1)) and y == 1 and z == 1 then
          bank[i].focus_hold = not bank[i].focus_hold
        end
      end
    end
    
    for i = 1,3 do
      if z == 1 and x > 0 + (5*(i-1)) and x <= 4 + (5*(i-1)) and y >=5 then
        if bank[i].focus_hold == false then
          if grid.alt == 0 then
            selected[i].x = x
            selected[i].y = y
            selected[i].id = (math.abs(y-9)+((x-1)*4))-(20*(i-1))
            bank[i].id = selected[i].id
            which_bank = i
            if menu == 11 then
              help_menu = "banks"
            end
            pad_clipboard = nil
            if bank[i].quantize_press == 0 then
              -- if (arp[i].hold or (menu == 9)) and grid_pat[i].rec == 0 and not arp[i].pause then
              if (arp[i].enabled or (menu == 9)) and grid_pat[i].rec == 0 and not arp[i].pause then
                arp[i].time = bank[i][bank[i].id].arp_time
                arps.momentary(i, bank[i].id, "on")
              else
                cheat(i, bank[i].id)

                grid_pattern_watch(i)
                
                --[==[
                grid_p[i] = {}
                grid_p[i].action = "pads"
                grid_p[i].i = i
                grid_p[i].id = selected[i].id
                grid_p[i].x = selected[i].x
                grid_p[i].y = selected[i].y
                grid_p[i].rate = bank[i][bank[i].id].rate
                grid_p[i].start_point = bank[i][bank[i].id].start_point
                grid_p[i].end_point = bank[i][bank[i].id].end_point
                grid_p[i].rate_adjusted = false
                grid_p[i].loop = bank[i][bank[i].id].loop
                grid_p[i].pause = bank[i][bank[i].id].pause
                grid_p[i].mode = bank[i][bank[i].id].mode
                grid_p[i].clip = bank[i][bank[i].id].clip
                --[[
                if grid_pat[i].rec == 1 and grid_pat[i].count == 0 then
                  print("grid happening")
                  clock.run(synced_pattern_record,grid_pat[i])
                end
                --]]
                grid_pat[i]:watch(grid_p[i])
                --]==]

              end
            else
              table.insert(quantize_events[i],selected[i].id)
            end
          else
            local released_pad = (math.abs(y-9)+((x-1)*4))-(20*(i-1))
            arps.momentary(i, released_pad, "off")
          end
        else
          if grid.alt == 0 then
            bank[i].focus_pad = (math.abs(y-9)+((x-1)*4))-(20*(i-1))
            --[[
            if tracker[i].recording then
              add_to_tracker(i,{bank[i].focus_pad,0.25,"next"})
            end
            --]]
          elseif grid.alt == 1 then
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
        redraw()
      elseif z == 0 and x > 0 + (5*(i-1)) and x <= 4 + (5*(i-1)) and y >=5 then
        local released_pad = (math.abs(y-9)+((x-1)*4))-(20*(i-1))
        if bank[i][released_pad].play_mode == "momentary" then
          softcut.rate(i+1,0)
        end
        if (arp[i].enabled and not arp[i].hold) or (menu == 9 and not arp[i].hold) then
          arps.momentary(i, released_pad, "off")
        end
      end
    end
    
    -- if x == 5 or x == 10 or x == 15 then

    --   if z == 1 then
    --     zilch4[x/5][5-y] = true
    --     zilch4[x/5].held = zilch4[x/5].held + 1
    --   elseif z == 0 then
    --     if zilch4[x/5].held > 0 then
    --       local coll = {}
    --       for j = 1,4 do
    --         if zilch4[x/5][j] == true then
    --           table.insert(coll,j)
    --         end
    --       end
    --       coll = table.concat(coll)
    --       rightangleslice.actions[4][coll][1](bank[x/5][bank[x/5].id])
    --       rightangleslice.actions[4][coll][2](bank[x/5][bank[x/5].id],x/5)
    --       for j = 1,4 do
    --         zilch4[x/5][j] = false
    --       end
    --     end
    --     zilch4[x/5].held = 0
    --   end
    -- end

    for k = 4,2,-1 do
      for i = 1,3 do

        if z == 1 and x == (k+1)+(5*(i-1)) and y <=k then
          local t1 = util.time()
          fingers[k].dt = t1-fingers[k].t
          fingers[k].t = t1
          if fingers[k].dt > 0.1 then
            fingers[k][i] = {}
          end
          table.insert(fingers[k][i],math.abs(y-(k+1)))
          table.sort(fingers[k][i])
          fingers[k][i].con = table.concat(fingers[k][i])
          for j = 1,#fingers[k][i] do
            local e = {}
            e.state = 1
            e.id = (k+1)+(5*(i-1))+math.abs(fingers[k][i][j]-(k+1))
            e.x = (k+1)+(5*(i-1))
            e.y = math.abs(fingers[k][i][j]-(k+1))
            grid_entry(e)
          end
        elseif z == 0 and x == (k+1)+(5*(i-1)) and y<=k then
          if k == 4 then
            counter_four.key_up:stop()
            counter_four.key_up:start()
          elseif k == 3 then
            counter_three.key_up:stop()
            counter_three.key_up:start()
          elseif k == 2 then
            counter_two.key_up:stop()
            counter_two.key_up:start()
          elseif k == 1 then
            zilchmo(1,i)
          end
          selected_zilchmo_row = k
          selected_zilchmo_bank = i
        end
      end
    end
    
    for k = 1,1 do
      for i = 1,3 do
        if z == 0 and x == (k+1)+(5*(i-1)) and y<=k then
          if grid_pat[i].quantize == 0 then -- still relevant
            if bank[i].alt_lock and grid.alt == 0 then
              if grid_pat[i].play == 1 then
                grid_pat[i].overdub = grid_pat[i].overdub == 0 and 1 or 0
              end
            else
              if grid.alt == 1 then -- still relevant
                grid_pat[i]:rec_stop()
                grid_pat[i]:stop()
                --grid_pat[i].external_start = 0
                grid_pat[i].tightened_start = 0
                grid_pat[i]:clear()
                pattern_saver[i].load_slot = 0
              elseif grid_pat[i].rec == 1 then -- still relevant
                grid_pat[i]:rec_stop()
                midi_clock_linearize(i)
                if grid_pat[i].auto_snap == 1 then
                  print("auto-snap")
                  snap_to_bars(i,how_many_bars(i))
                end
                if grid_pat[i].mode ~= "quantized" then
                  --grid_pat[i]:start()
                  start_pattern(grid_pat[i])
                end
                grid_pat[i].loop = 1
              elseif grid_pat[i].count == 0 then
                if grid_pat[i].playmode ~= 2 then
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
            if grid.alt == 1 then
              grid_pat[i]:rec_stop()
              grid_pat[i]:stop()
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
        if grid.alt == 1 then
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
        if menu == 11 then
          help_menu = "arc patterns"
          which_bank = current
        end
      end
    end
    
    for i = 1,3 do
      if x == (3)+(5*(i-1)) and y == 4 and z == 1 then
        which_bank = i
        local which_pad = bank[i].focus_hold == true and bank[i].focus_pad or bank[i].id
        bank[i][which_pad].loop = not bank[i][which_pad].loop
        if bank[i].alt_lock or grid.alt == 1 then
          for j = 1,16 do
            bank[i][j].loop = bank[i][which_pad].loop
          end
        end
        if bank[i].focus_hold == false then
          softcut.loop(i+1,bank[i][which_pad].loop == true and 1 or 0)
        end
        if menu == 11 then
          help_menu = "loop"
        end
        --trackers.inherit(i,which_pad)
      end
      redraw()
    end
    
    if x == 16 and y == 8 then
      if grid.alt_pp == 1 then
        grid.alt_pp = 0
      end
      if grid.alt_delay then
        grid.alt_delay = false
      end
      grid.alt = z
      arc.alt = z
      if menu == 11 then
        if grid.alt == 1 then
          help_menu = "alt"
        elseif grid.alt == 0 then
          help_menu = "welcome"
        end
      end
      redraw()
      -- grid_redraw()
    end
    
    if y == 4 or y == 3 or y == 2 then
      if x == 1 or x == 6 or x == 11 then
        local which_pad = nil
        local current = util.round(math.sqrt(math.abs(x-2)))
        --if grid.alt == 0 then
        if not bank[current].alt_lock and grid.alt == 0 then
          if bank[current].focus_hold == false then
            --jump_live(current, bank[current].id, y, z)
            jump_clip(current, bank[current].id, y, z)
          else
            --jump_live(current, bank[current].focus_pad, y, z)
            jump_clip(current, bank[current].focus_pad, y, z)
          end
        elseif bank[current].alt_lock or grid.alt == 1 then
          for j = 1,16 do
            --jump_live(current, j, y, z)
            jump_clip(current, j, y, z)
            
            --trackers.inherit(current,j)
          end
        end
        --trackers.inherit(current,bank[current].focus_hold == true and bank[current].focus_pad or bank[current].id)
        if z == 0 then
          redraw()
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
        if x == j and y == i and z == 1 then
          local which_pad = nil
          --if grid.alt == 0 then
          if not bank[math.sqrt(math.abs(x-3))].alt_lock and grid.alt == 0 then
            local current = math.sqrt(math.abs(x-3))
            if bank[current].focus_hold == false then
              local old_mode = bank[current][bank[current].id].mode
              bank[current][bank[current].id].mode = math.abs(i-5)
              if old_mode ~= bank[current][bank[current].id].mode then
                change_mode(bank[current][bank[current].id], old_mode)
              end
            else
              local old_mode = bank[current][bank[current].focus_pad].mode
              bank[current][bank[current].focus_pad].mode = math.abs(i-5)
              if old_mode ~= bank[current][bank[current].focus_pad].mode then
                change_mode(bank[current][bank[current].focus_pad], old_mode)
              end
            end
          elseif bank[math.sqrt(math.abs(x-3))].alt_lock or grid.alt == 1 then
            for k = 1,16 do
              local current = math.sqrt(math.abs(x-3))
              local old_mode = bank[current][k].mode
              bank[current][k].mode = math.abs(i-5)
              if old_mode ~= bank[current][k].mode then
                change_mode(bank[current][k], old_mode)
              end
              --trackers.inherit(current,k)
            end
          end
          local current = math.sqrt(math.abs(x-3))
          if bank[current].focus_hold == false then
            which_pad = bank[current].id
          else
            which_pad = bank[current].focus_pad
          end

          --i don't think this is necessary:
          --[[
          if bank[current][which_pad].mode == 1 then
            bank[current][which_pad].sample_end = 8
          else
            bank[current][which_pad].sample_end = clip[bank[current][which_pad].clip].sample_length
          end
          --]]

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
          --trackers.inherit(current,bank[current].focus_hold == true and bank[current].focus_pad or bank[current].id)
        end
      end
    end
    
    for i = 7,5,-1 do
      if x == 16 and z == 1 and y == i then
        toggle_buffer(8-y)
        if grid.alt == 1 then
          buff_flush()
        end
        
        if menu == 11 then
          help_menu = "buffer switch"
        end
      end
    end
    

    for i = 8,6,-1 do
      if x == 5 or x == 10 or x == 15 then
        if y == i then
          if grid.alt == 0 then
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
          elseif grid.alt == 1 then
            if y == 8 then
              -- sixteen_slices(x/5)
            elseif y == 7 then
              rec_to_pad(x/5)
            elseif y == 6 then
              pad_to_rec(x/5)
            end
          end
        end
      end
    end
    
    if y == 5 then
      if z == 1 then
        for i = 1,3 do
          if bank[i].focus_hold == true then
            if x == i*5 then
              bank[i][bank[i].focus_pad].crow_pad_execute = (bank[i][bank[i].focus_pad].crow_pad_execute + 1)%2
              if grid.alt == 1 then
                for j = 1,16 do
                  bank[i][j].crow_pad_execute = bank[i][bank[i].focus_pad].crow_pad_execute
                end
              end
            end
          end
        end
      end
      if x == 5 or x == 10 or x == 15 then
        if grid.alt == 0 then
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
          --if grid.alt == 0 then
          if not bank[i].alt_lock and grid.alt == 0 then
            if y == 3 then

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
                    arp[i].pause = true
                    arp[i].playing = false
                  else
                    arp[i].step = arp[i].start_point-1
                    arp[i].pause = false
                    arp[i].playing = true
                  end
                end
              end
            else
              if key1_hold == true then key1_hold = false end
              if y == 4 then
                menu = 2
                page.loops_sel = math.floor((x/4))
              end
              redraw()
            end
          elseif bank[i].alt_lock or grid.alt == 1 then
            if y == 2 then
              if grid_pat[math.ceil(x/4)].playmode == 3 or grid_pat[math.ceil(x/4)].playmode == 4 then
                clock.run(random_grid_pat, math.ceil(x/4), 3)
              else
                random_grid_pat(math.ceil(x/4),3)
              end
            end
            if y == 3 then
              page.arp_page_sel = i
              arp[i].hold = not arp[i].hold
              if not arp[i].hold then
                arps.clear(i)
              end
              arp[i].enabled = false



              --arp[i].pause = not arp[i].pause
            end
            if y == 4 then
              local current = math.floor(x/5)+1
              for i = 1,16 do
                bank[current][i].rate = 1
                if bank[current][i].fifth == true then
                  bank[current][i].fifth = false
                end
              end
              softcut.rate(current+1,1*bank[current][bank[current].id].offset)
            end
          end
          ---
        end
      end
    end
    
  elseif grid_page == 1 then
    
    if grid.loop_mod == 0 then
    
      for i = 1,11,5 do
        for j = 1,8 do
          if x == i and y == j then
            local current = math.floor(x/5)+1
            if z == 1 then
              saved_pat = pattern_saver[current].saved[9-y] -- hate that this is global...
              if step_seq[current].held == 0 then
                pattern_saver[current].source = math.floor(x/5)+1
                pattern_saver[current].save_slot = 9-y
                pattern_saver[current].clock = clock.run(test_save,current)
                -- print("starting save "..pattern_saver[current].clock)
              else
                --if there's a pattern saved there...
                if pattern_saver[current].saved[9-y] == 1 then
                  if grid.alt_pp == 0 then
                    step_seq[current][step_seq[current].held].assigned_to = 9-y
                  end
                end
              end
            elseif z == 0 then
              if step_seq[current].held == 0 then
                if pattern_saver[math.floor(x/5)+1].clock then
                  clock.cancel(pattern_saver[math.floor(x/5)+1].clock)
                  clock.cancel(pattern_saver[math.floor(x/5)+1].clock-1)
                  clock.cancel(pattern_saver[math.floor(x/5)+1].clock-2)
                  -- print("killing save "..pattern_saver[math.floor(x/5)+1].clock)
                end
                pattern_saver[math.floor(x/5)+1].active = false
                if grid.alt_pp == 0 and saved_pat == 1 then
                  if pattern_saver[current].saved[9-y] == 1 then
                    pattern_saver[current].load_slot = 9-y
                    test_load((9-y)+(8*(current-1)),current)
                  end
                end
              end
            end
          end
        end
      end
      
      for i = 2,12,5 do
        for j = 1,8 do
          if z == 1 and x == i and y == j then
            local current = math.floor(x/5)+1
            step_seq[current].meta_duration = 9-y
          end
        end
      end
      
      for i = 3,13,5 do
        for j = 1,8 do
          if z == 1 and x == i and y == j then
            local current = math.floor(x/5)+1
            step_seq[current].held = 9-y
            if grid.alt_pp == 1 then
              step_seq[current][step_seq[current].held].assigned_to = 0
            end
          elseif z == 0 and x == i and y == j then
            local current = math.floor(x/5)+1
            step_seq[current].held = 0
          elseif z == 1 and x == i+1 and y == j then
            local current = math.floor(x/5)+1
            step_seq[current].held = (9-y)+8
            if grid.alt_pp == 1 then
              step_seq[current][step_seq[current].held].assigned_to = 0
            end
          elseif z == 0 and x == i+1 and y == j then
            local current = math.floor(x/5)+1
            step_seq[current].held = 0
          end
        end
      end
      
      for i = 5,15,5 do
        for j = 1,8 do
          if z == 1 and x == i and y == j then
            local current = x/5
            if step_seq[current].held == 0 then
              step_seq[current][step_seq[current].current_step].meta_meta_duration = 9-y
            else
              step_seq[current][step_seq[current].held].meta_meta_duration = 9-y
            end
            if grid.alt_pp == 1 then
              for k = 1,16 do
                step_seq[current][k].meta_meta_duration = 9-y
              end
            end
          end
        end
      end
      
      for i = 7,5,-1 do
        if x == 16 and y == i and z == 1 then
          if step_seq[8-i].held == 0 then
            if grid.alt_pp == 1 then
              step_seq[8-i].current_step = step_seq[8-i].start_point
              step_seq[8-i].meta_step = 1
              step_seq[8-i].meta_meta_step = 1
              if step_seq[8-i].active == 1 and step_seq[8-i][step_seq[8-i].current_step].assigned_to ~= 0 then
                test_load(step_seq[8-i][step_seq[8-i].current_step].assigned_to+(((8-i)-1)*8),8-i)
              end
            else
              step_seq[8-i].active = (step_seq[8-i].active + 1)%2
            end
          else
            step_seq[8-i][step_seq[8-i].held].loop_pattern = (step_seq[8-i][step_seq[8-i].held].loop_pattern + 1)%2
          end
        end
      end
      
      
      if x == 16 and y == 8 then
        grid.alt_pp = z
        redraw()
        -- grid_redraw()
      end
    
    elseif grid.loop_mod == 1 then
      for i = 3,13,5 do
        if x == i or x == i+1 then
          local current = math.floor(x/5)+1
          if z == 1 then
            step_seq[current].loop_held = step_seq[current].loop_held + 1
            if step_seq[current].loop_held == 1 then
              if x == i then
                step_seq[current].start_point = 9-y
              elseif x == i+1 then
                step_seq[current].start_point = 17-y
              end
              if step_seq[current].start_point > step_seq[current].current_step then
                step_seq[current].current_step = step_seq[current].start_point
              end
            elseif step_seq[current].loop_held == 2 then
              if x == i then
                step_seq[current].end_point = 9-y
              elseif x == i+1 then
                step_seq[current].end_point = 17-y
              end
            end
          elseif z == 0 then
            step_seq[current].loop_held = step_seq[current].loop_held - 1
          end
        end
      end
    end
    
    if x == 16 and y == 2 then
      grid.loop_mod = z
      redraw()
      -- grid_redraw()
    end
    
    if menu == 11 then
      if x == 1 or x == 6 or x == 11 then
        help_menu = "meta: slots"
      elseif x == 2 or x == 7 or x == 12 then
        help_menu = "meta: clock"
      elseif x == 3 or x == 4 or x == 8 or x == 9 or x == 13 or x == 14 then
        if grid.loop_mod == 0 then
          help_menu = "meta: step"
        end
      elseif x == 5 or x == 10 or x == 15 then
        help_menu = "meta: duration"
      elseif x == 16 then
        if y == 8 then
          if z == 1 then
            help_menu = "meta: alt"
          elseif z == 0 then
            help_menu = "welcome"
          end
        elseif y == 7 or y == 6 or y == 5 then
          help_menu = "meta: toggle"
        elseif y == 2 then
          if z == 1 then
            help_menu = "meta: loop mod"
          elseif z == 0 then
            help_menu = "welcome"
          end
        end
      end
      redraw()
    end
  
  elseif grid_page == 2 then
    if y == 3 or y == 6 then
      if x <= 3 and z == 1 then
        local changes = {"double", "halve", "sync"}
        del.change_duration(y == 6 and 1 or 2, y == 6 and 2 or 1, changes[x])
      elseif x >= 4 and x <= 8 then
        if z == 1 then
          del.set_value(math.abs(5-y), x-3, "level")
        end
      elseif x == 9 then
        del.quick_action(math.abs(y-5),"level mute")
      end
    elseif y == 4 or y == 5 then
      if x >= 4 and x <= 8 then
        if z == 1 then
          del.set_value(6-y, x-3, "feedback")
        end
      elseif x == 9 then
        if grid.alt_delay then
          del.quick_action(6-y, "clear")
        end
        del.quick_action(6-y,"feedback mute")
      end
    elseif y == 1 or y == 8 then
      if x >= 10 and x <=14 then
        if z == 1 then
          del.set_value(y == 8 and 1 or 2,x-9,grid.alt_delay == true and "send all" or "send")
        end
      elseif x == 15 then
        del.quick_action(y == 8 and 1 or 2,"send mute")
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
            if grid.alt_delay then
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

    if x >= 10 and x <= 13 and y >=3 and y <=6 then
      local id = delay_grid.bank
      if z == 1 then
        local xval = {9,4,-1}
        selected[id].x = x - xval[id]
        selected[id].y = y + 2
        selected[id].id = (math.abs(selected[id].y-9)+((selected[id].x-1)*4))-(20*(id-1))
        bank[id].id = selected[id].id
        -- if (arp[id].hold or (menu == 9)) and grid_pat[id].rec == 0 and not arp[id].pause then
        if (arp[id].enabled or (menu == 9)) and grid_pat[id].rec == 0 and not arp[id].pause then
          arp[id].time = bank[id][bank[id].id].arp_time
          arps.momentary(id, bank[id].id, "on")
        else
          cheat(id, bank[id].id)
          grid_pattern_watch(id)
        end
      else
        -- if not arp[id].hold then
        if arp[id].enabled and not arp[id].hold then
          local xval = {9,4,-1}
          local released_pad = (math.abs((y + 2)-9)+(((x - xval[id])-1)*4))-(20*(id-1))
          arps.momentary(id, released_pad, "off")
        end
      end
    end

    if x == 16 and y == 8 then
      grid.alt_delay = not grid.alt_delay
    end

  end
  
  if x == 16 and y == 1 and z == 1 then
    if grid_page == 0 then
      if grid.alt == 0 then
        grid_page = 1
        if menu == 11 then
          if grid_page == 1 then
            help_menu = "meta page"
          elseif grid_page == 0 then
            help_menu = "welcome"
          end
          redraw()
        end
      else
        grid_page = 2
        grid.alt_delay = true
        grid.alt = 0
      end
    elseif grid_page == 1 then
      if grid.alt_pp == 0 then
        grid_page = 2
      else
        grid_page = 0
        grid.alt = 1
        grid.alt_pp = 0
      end
    elseif grid_page == 2 then
      if not grid.alt_delay then
        grid_page = 0
      else
        grid_page = 1
        grid.alt_pp = 1
        grid.alt_delay = false
      end
    end
  end

  grid_dirty = true
    
end

return grid_actions