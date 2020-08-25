local encoder_actions = {}

local ea = encoder_actions
ea.sc = {}

function encoder_actions.init(n,d)
  if n == 1 then
    if menu == 1 then
      page.main_sel = util.clamp(page.main_sel+d,1,10)
    elseif menu == 2 then
      local id = page.loops_sel
      if not key1_hold then
        page.loops_sel = util.clamp(page.loops_sel+d,1,4)
        id = page.loops_sel
      end
      if id ~= 4 then
        if key1_hold then
          if page.loops_view[id] > 1 then
            ea.change_pad(id,d)
          else
            local which_pad = nil
            if bank[id].focus_hold == false then
              which_pad = bank[id].id
            else
              which_pad = bank[id].focus_pad
            end
            local resolution = loop_enc_resolution
            ea.move_play_window(bank[id][which_pad],d/resolution)
            if bank[id].focus_hold == false then
              ea.sc.move_play_window(id)
            end
          end
        end
      elseif id == 4 then
        if key1_hold then
          if page.loops_view[id] == 2 then
            ea.change_buffer(rec,d)
          else
            ea.move_rec_window(rec,d)
          end
          ea.sc.move_rec_window(rec)
        end
      end
    elseif menu == 6 then
      if page.delay_section == 1 then
        page.delay_focus = util.clamp(page.delay_focus+d,1,2)
      elseif page.delay_section == 2 then
        page.delay[page.delay_focus].menu = util.clamp(page.delay[page.delay_focus].menu+d,1,3)
      elseif page.delay_section == 3 then
        local max_lines = {3,3,4}
        local target = page.delay[page.delay_focus].menu_sel[page.delay[page.delay_focus].menu]
        page.delay[page.delay_focus].menu_sel[page.delay[page.delay_focus].menu] = util.clamp(target+d,1,max_lines[page.delay[page.delay_focus].menu])
      end
    elseif menu == 7 then
      page.time_sel = util.clamp(page.time_sel+d,1,6)
    elseif menu == 8 then
      rytm.track_edit = util.clamp(rytm.track_edit+d,1,3)
    elseif menu == 9 then
      page.arp_page_sel = util.clamp(page.arp_page_sel+d,1,3)
    elseif menu == 10 then
      page.rnd_page = util.clamp(page.rnd_page+d,1,3)
    end
  end
  if n == 2 then
    if menu == 1 then
      page.main_sel = util.clamp(page.main_sel+d,1,10)
    elseif menu == 2 then
      local id = page.loops_sel
      if id ~=4 then
        if page.loops_view[id] == 2 then
          local focused_pad = nil
          if grid_pat[id].play == 0 and grid_pat[id].tightened_start == 0 and not arp[id].playing and midi_pat[id].play == 0 then
            focused_pad = bank[id].id
          else
            focused_pad = bank[id].focus_pad
          end
          params:delta("rate "..id,d)
          if focused_pad == 16 then
            for i = 1,15 do
              bank[id][i].rate = bank[id][16].rate
            end
          end
          if grid.alt == 1 then
            for i = 1,16 do
              bank[id][i].rate = bank[id][focused_pad].rate
            end
          end
        elseif page.loops_view[id] == 3 then
          ea.change_pad_clip(id,d)
        elseif page.loops_view[id] == 1 then
          local which_pad = nil
          if bank[id].focus_hold == false then
            which_pad = bank[id].id
          else
            which_pad = bank[id].focus_pad
          end
          local resolution = loop_enc_resolution * (key1_hold and 10 or 1)
          ea.move_start(bank[id][which_pad],d/resolution)
          if bank[id].focus_hold == false then
            ea.sc.move_start(id)
          end
        end
      elseif id == 4 then
        if page.loops_view[id] == 2 then
          params:delta("live_buff_rate",d)
        elseif page.loops_view[id] == 1 then
          local lbr = {1,2,4}
          if d >= 0 and util.round(rec.start_point + ((d/rec_loop_enc_resolution)/lbr[params:get("live_buff_rate")]),0.01) < util.round(rec.end_point,0.01) then
            rec.start_point = util.clamp(rec.start_point+((d/rec_loop_enc_resolution)/lbr[params:get("live_buff_rate")]),(1+(8*(rec.clip-1))),(8.9+(8*(rec.clip-1))))
          elseif d < 0 then
            rec.start_point = util.clamp(rec.start_point+((d/rec_loop_enc_resolution)/lbr[params:get("live_buff_rate")]),(1+(8*(rec.clip-1))),(8.9+(8*(rec.clip-1))))
          end
          softcut.loop_start(1, rec.start_point)
        end
      end
    elseif menu == 6 then
      -- local line = page.delay_sel
      -- if line == 0 then
      --   local divisor = (delay[1].mode == "free" and key1_hold) and 100 or 1
      --   params:delta(delay[1].mode == "clocked" and "delay L: div/mult" or "delay L: free length",d/divisor)
      -- elseif line == 1 then
      --   params:delta("delay L: feedback",d)
      -- elseif line ==  2 then
      --   params:delta("delay L: filter cut",d/10)
      -- elseif line == 3 then
      --   params:delta("delay L: filter q",d/2)
      -- elseif line == 4 then
      --   params:delta("delay L: global level",d)
      -- end
      local line = page.delay[page.delay_focus].menu_sel[page.delay[page.delay_focus].menu]
      local delay_name = page.delay_focus == 1 and "L" or "R"
      local focused_menu = page.delay[page.delay_focus].menu
      if page.delay_section == 3 then
        if focused_menu == 1 then
          if line == 1 then
            params:delta("delay "..delay_name..": mode",d)
          elseif line == 2 then
            local divisor = (delay[page.delay_focus].mode == "free" and key1_hold) and 10 or 0.2
            params:delta("delay "..delay_name..": fade time",d/divisor)
          elseif line == 3 then
            params:delta("delay "..delay_name..": feedback",d)
          end
        elseif focused_menu == 2 then
          if line == 1 then
            params:delta("delay "..delay_name..": filter cut",d/10)
          elseif line == 2 then
            params:delta("delay "..delay_name..": filter lp",d)
          elseif line == 3 then
            params:delta("delay "..delay_name..": filter bp",d)
          end

        -- elseif focused_menu == 3 then
        --   if line == 1 then
        --     params:delta("delay "..delay_name..": (a) send",d*2)
        --   elseif line == 2 then
        --     params:delta("delay "..delay_name..": (b) send",d*2)
        --   elseif line == 3 then
        --     params:delta("delay "..delay_name..": (c) send",d*2)
        --   end
        elseif focused_menu == 3 then
          if line < 4 then
            if page.delay_focus == 1 then
              if key1_hold then
                for i = 1,16 do
                  bank[line][i].left_delay_level = util.clamp(bank[line][i].left_delay_level + d/10,0,1)
                end
              else
                bank[line][bank[line].id].left_delay_level = util.clamp(bank[line][bank[line].id].left_delay_level + d/10,0,1)
              end
            elseif page.delay_focus == 2 then
              if key1_hold then
                for i = 1,16 do
                  bank[line][i].right_delay_level = util.clamp(bank[line][i].right_delay_level + d/10,0,1)
                end
              else
                bank[line][bank[line].id].right_delay_level = util.clamp(bank[line][bank[line].id].right_delay_level + d/10,0,1)
              end
            end
          elseif line == 4 then
            params:delta("delay "..delay_name..": global level",d)
          end
        end
      end
    elseif menu == 7 then
      local time_page = page.time_page_sel
      local page_line = page.time_sel
      if page_line >= 1 and page_line < 4 and bank[page_line].crow_execute ~= 1 then
        time_page[page_line] = util.clamp(time_page[page_line]+d,1,7)
        if time_page[page_line] > 4 then
          page.time_scroll[page_line] = 2
        else
          page.time_scroll[page_line] = 1
        end
      elseif page_line >= 1 and page_line < 4 then
        time_page[page_line] = util.clamp(time_page[page_line]+d,1,7)
        if time_page[page_line] < 4 then
          page.time_scroll[page_line] = 1
        elseif time_page[page_line] == 4 and bank[page_line].crow_execute == 1 then
          if page.time_scroll[page_line] == 1 then
            time_page[page_line] = 5
            page.time_scroll[page_line] = 2
          else
            time_page[page_line] = 3
            page.time_scroll[page_line] = 1
          end
        elseif time_page[page_line] > 4 and bank[page_line].crow_execute == 1 then
          page.time_scroll[page_line] = 2
        end
      elseif page_line >=4 then
        time_page[page_line] = util.clamp(time_page[page_line]+d,1,7)
        local target = page.time_sel-3
        if g.device == nil and time_page[page_line] <= 4 then
          if time_page[page_line] == 1 then
            arc_param[target] = page.time_arc_loop[page_line-3]
          else
            arc_param[target] = time_page[page_line]+2
          end
        end
      end
    elseif menu == 8 then
      if not key1_hold then
        if rytm.screen_focus == "right" then
          rytm.track[rytm.track_edit].rotation = util.clamp(rytm.track[rytm.track_edit].rotation + d, 0, 16)
          rytm.track[rytm.track_edit].s = rytm.rotate_pattern(rytm.track[rytm.track_edit].s, rytm.track[rytm.track_edit].rotation)
        else
          rytm.track[rytm.track_edit].k = util.clamp(rytm.track[rytm.track_edit].k+d,0,rytm.track[rytm.track_edit].n)
        end
      elseif key1_hold then
        if d > 0 then
          rytm.track[rytm.track_edit].mode = "span"
        elseif d < 0 then
          rytm.track[rytm.track_edit].mode = "single"
        end
      end
    elseif menu == 9 then
      page.arp_param[page.arp_page_sel] = util.clamp(page.arp_param[page.arp_page_sel] + d,1,5)
    elseif menu == 10 then
      local selected_slot = page.rnd_page_sel[page.rnd_page]
      if page.rnd_page_section == 1 then
        page.rnd_page_sel[page.rnd_page] = util.clamp(selected_slot+d,1,#rnd[page.rnd_page])
        page.rnd_page_edit[page.rnd_page] = 1
      elseif page.rnd_page_section == 2 then
        local selected_slot = page.rnd_page_sel[page.rnd_page]
        local current_param = rnd[page.rnd_page][selected_slot].param
        local reasonable_max = (current_param == "loop" or current_param == "delay send") and 4 or 6
        page.rnd_page_edit[page.rnd_page] = util.clamp(page.rnd_page_edit[page.rnd_page]+d,1,reasonable_max)
      end
    end
  end
  if n == 3 then
    if menu == 2 then
      local id = page.loops_sel
      if id ~= 4 then
        if page.loops_view[id] == 3 then
          local focused_pad = nil
          if grid_pat[id].play == 0 and grid_pat[id].tightened_start == 0 and not arp[id].playing and midi_pat[id].play == 0 then
            focused_pad = bank[id].id
          else
            focused_pad = bank[id].focus_pad
          end
          local current_offset = (math.log(bank[id][focused_pad].offset)/math.log(0.5))*-12
          current_offset = util.clamp(current_offset+d,-36,24)
          if current_offset > -1 and current_offset < 1 then
            current_offset = 0
          end
          bank[id][focused_pad].offset = math.pow(0.5, -current_offset / 12)
          if grid_pat[id].play == 0 and grid_pat[id].tightened_start == 0 and not arp[id].playing and midi_pat[id].play == 0 then
            cheat(id,bank[id].id)
          end
          if focused_pad == 16 then
            for i = 1,15 do
              bank[id][i].offset = bank[id][16].offset
            end
          end
          if grid.alt == 1 then
            for i = 1,16 do
              bank[id][i].offset = bank[id][focused_pad].offset
            end
          end
        
        elseif page.loops_view[id] == 2 then
          local focused_pad = nil
          if grid_pat[id].play == 0 and grid_pat[id].tightened_start == 0 and not arp[id].playing and midi_pat[id].play == 0 then
            focused_pad = bank[id].id
          else
            focused_pad = bank[id].focus_pad
          end
          bank[id][focused_pad].rate_slew = util.clamp(bank[id][focused_pad].rate_slew+d/10,0,4)
          softcut.rate_slew_time(id+1,bank[id][focused_pad].rate_slew)
          if focused_pad == 16 then
            for i = 1,15 do
              bank[id][i].rate_slew = bank[id][16].rate_slew
            end
          end
          if grid.alt == 1 then
            for i = 1,16 do
              bank[id][i].rate_slew = bank[id][focused_pad].rate_slew
            end
          end
          
        elseif page.loops_view[id] == 1 then
          local which_pad = nil
          if bank[id].focus_hold == false then
            which_pad = bank[id].id
          else
            which_pad = bank[id].focus_pad
          end
          local resolution = loop_enc_resolution * (key1_hold and 10 or 1)
          ea.move_end(bank[id][which_pad],d/resolution)
          if bank[id].focus_hold == false then
            softcut.loop_end(id+1, bank[id][bank[id].id].end_point)
          end
        end
      elseif id == 4 then
        if page.loops_view[id] == 2 then
          
        else
          local lbr = {1,2,4}
          if d <= 0 and util.round(rec.start_point,0.01) < util.round(rec.end_point + ((d/rec_loop_enc_resolution)/lbr[params:get("live_buff_rate")]),0.01) then
            rec.end_point = util.clamp(rec.end_point+((d/rec_loop_enc_resolution)/lbr[params:get("live_buff_rate")]),(1+(8*(rec.clip-1))),(9+(8*(rec.clip-1))))
          elseif d > 0 and rec.end_point+((d/rec_loop_enc_resolution)/lbr[params:get("live_buff_rate")]) <= 9+(8*(rec.clip-1)) then
            rec.end_point = util.clamp(rec.end_point+((d/rec_loop_enc_resolution)/lbr[params:get("live_buff_rate")]),(1+(8*(rec.clip-1))),(9+(8*(rec.clip-1))))
          end
          softcut.loop_end(1, rec.end_point-0.01)
        end
      end
    elseif menu == 6 then
      -- local line = page.delay_sel
      -- if line == 0 then
      --   params:delta(delay[2].mode == "clocked" and "delay R: div/mult" or "delay R: free length",d)
      -- elseif line == 1 then
      --   params:delta("delay R: feedback",d)
      -- elseif line ==  2 then
      --   params:delta("delay R: filter cut",d/10)
      -- elseif line == 3 then
      --   params:delta("delay R: filter q",d/2)
      -- elseif line == 4 then
      --   params:delta("delay R: global level",d)
      -- end
      local line = page.delay[page.delay_focus].menu_sel[page.delay[page.delay_focus].menu]
      local delay_name = page.delay_focus == 1 and "L" or "R"
      local focused_menu = page.delay[page.delay_focus].menu
      if page.delay_section == 3 then
        if focused_menu == 1 then
          if line == 1 then
            -- local divisor = (delay[page.delay_focus].mode == "free" and key1_hold) and (1/(33+(1/3)))*100 or 1/(33+(1/3))
            local divisor;
            if delay[page.delay_focus].mode == "free" and key1_hold then
              divisor = 3
            elseif delay[page.delay_focus].mode == "free" and not key1_hold then
              divisor = 1/(100/3)
            else
              divisor = 1
            end
            params:delta(delay[page.delay_focus].mode == "clocked" and "delay "..delay_name..": div/mult" or "delay "..delay_name..": free length",d/divisor)
          elseif line == 2 then
            if key1_hold then
              params:delta("delay "..delay_name..": rate",d)
            else
              params:delta("delay "..delay_name..": rate",d*100)
              if params:get("delay "..delay_name..": rate") < 1.0 then
                params:set("delay "..delay_name..": rate",1)
              end
            end
          end
        elseif focused_menu == 2 then
          if line == 1 then
            params:delta("delay "..delay_name..": filter q",d/10)
          elseif line == 2 then
            params:delta("delay "..delay_name..": filter hp",d)
          elseif line == 3 then
            params:delta("delay "..delay_name..": filter dry",d)
          end
        elseif focused_menu == 3 then
          if page.delay_focus == 1 then
            local current_thru = bank[line][bank[line].id].left_delay_thru == true and 1 or 0
            current_thru = util.clamp(current_thru + d,0,1)
            if key1_hold then
              for i = 1,16 do
                bank[line][i].left_delay_thru = current_thru == 1 and true or false
              end
            else
              bank[line][bank[line].id].left_delay_thru = current_thru == 1 and true or false
            end
          elseif page.delay_focus == 2 then
            local current_thru = bank[line][bank[line].id].right_delay_thru == true and 1 or 0
            current_thru = util.clamp(current_thru + d,0,1)
            if key1_hold then
              for i = 1,16 do
                bank[line][i].right_delay_thru = current_thru == 1 and true or false
              end
            else
              bank[line][bank[line].id].right_delay_thru = current_thru == 1 and true or false
            end
          end
        end
      end
    elseif menu == 7 then
      local time_page = page.time_page_sel
      local page_line = page.time_sel
      local pattern = g.device ~= nil and grid_pat[page_line] or midi_pat[page_line]
      if page_line < 4 then
        if time_page[page_line] == 3 then
          bank[page_line].crow_execute = util.clamp(bank[page_line].crow_execute+d,0,1)
        elseif time_page[page_line] == 1 then
          if pattern.rec ~= 1 then
            if not key1_hold then
              if pattern.play == 1 then -- actually, we won't want to allow change...
                -- local pre_adjust_mode = pattern.playmode
                -- pattern.playmode = util.clamp(pattern.playmode+d,1,2)
                -- if pattern.playmode ~= pre_adjust_mode then
                --   stop_pattern(pattern)
                --   start_pattern(pattern)
                -- end
              else
                pattern.playmode = util.clamp(pattern.playmode+d,1,2)
              end
            elseif key1_hold and pattern.playmode == 2 then
              key1_hold_and_modify = true
              pattern.rec_clock_time = util.clamp(pattern.rec_clock_time+d,1,64)
            end
          end
        elseif time_page[page_line] == 4 and bank[page_line].crow_execute ~= 1 then
          crow.count_execute[page_line] = util.clamp(crow.count_execute[page_line]+d,1,16)
        elseif time_page[page_line] == 5 then
         pattern.random_pitch_range = util.clamp(pattern.random_pitch_range+d,1,5)
        elseif time_page[page_line] == 6 then
          if pattern.rec ~= 1 and pattern.count > 0 then
            pattern.start_point = util.clamp(pattern.start_point+d,1,pattern.end_point)
            --pattern_length_to_bars(pattern, "non-destructive")
            if quantized_grid_pat[page_line].current_step < pattern.start_point then
              quantized_grid_pat[page_line].current_step = pattern.start_point
              quantized_grid_pat[page_line].sub_step = 1
            end
          end
        elseif time_page[page_line] == 7 then
          if pattern.rec ~= 1 and pattern.count > 0 then
            pattern.end_point = util.clamp(pattern.end_point+d,pattern.start_point,pattern.count)
            --pattern_length_to_bars(pattern, "non-destructive")
            if quantized_grid_pat[page_line].current_step > pattern.end_point then
              quantized_grid_pat[page_line].current_step = pattern.start_point
              quantized_grid_pat[page_line].sub_step = 1
            end
          end
        end
      else
        if not key1_hold then
          if time_page[page_line] == 1 then
            page.time_arc_loop[page_line-3] = util.clamp(page.time_arc_loop[page_line-3]+d,1,3)
            if g.device == nil then
              arc_param[page_line-3] = page.time_arc_loop[page_line-3]
            end
          end
        else
          if page.time_page_sel[page.time_sel] <= 4 then
            local id = page.time_sel-3
            local val = page.time_page_sel[page.time_sel]
            arc_pat[id][val].time_factor = util.clamp(arc_pat[id][val].time_factor + d/10,0.1,10)
          end
        end
      end
    elseif menu == 8 then
      if not key1_hold then
        if rytm.screen_focus == "right" then
          rytm.track[rytm.track_edit].pad_offset = util.clamp(rytm.track[rytm.track_edit].pad_offset+d,-15,15)
        else
          rytm.track[rytm.track_edit].n = util.clamp(rytm.track[rytm.track_edit].n+d,1,16)
          rytm.track[rytm.track_edit].k = util.clamp(rytm.track[rytm.track_edit].k,0,rytm.track[rytm.track_edit].n)
        end
      elseif key1_hold then
        local deci = {"0.25","0.5","1","2","4"}
        local lookup = string.format("%.4g",rytm.track[rytm.track_edit].clock_div)
        local current = (tab.key(deci, lookup))
        local new_value = util.clamp(current+d,1,#deci)
        rytm.track[rytm.track_edit].clock_div = tonumber(deci[new_value])
      end

    elseif menu == 9 then
      local focus_arp = arp[page.arp_page_sel]
      local id = page.arp_page_sel
      if page.arp_param[id] == 1 then
        local deci_to_int =
        { ["0.125"] = 1 --1/32
        , ["0.1667"] = 2 --1/16T
        , ["0.25"] = 3 -- 1/16
        , ["0.3333"] = 4 -- 1/8T
        , ["0.5"] = 5 -- 1/8
        , ["0.6667"] = 6 -- 1/4T
        , ["1.0"] = 7 -- 1/4
        , ["1.3333"] = 8 -- 1/2T
        , ["2.0"] = 9 -- 1/2
        , ["2.6667"] = 10  -- 1T
        , ["4.0"] = 11 -- 1
        }
        local rounded = util.round(focus_arp.time,0.0001)
        local working = deci_to_int[tostring(rounded)]
        working = util.clamp(working+d,1,11)
        local int_to_deci = {0.125,1/6,0.25,1/3,0.5,2/3,1,4/3,2,8/3,4}
        if page.arp_alt[page.arp_page_sel] then
          bank[page.arp_page_sel][bank[page.arp_page_sel].id].arp_time = int_to_deci[working]
          focus_arp.time = bank[page.arp_page_sel][bank[page.arp_page_sel].id].arp_time
        else
          focus_arp.time = int_to_deci[working]
          for i = 1,16 do
            bank[page.arp_page_sel][i].arp_time = focus_arp.time
          end
        end
      elseif page.arp_param[id] == 2 then
        local dir_to_int =
        { ["fwd"] = 1
        , ["bkwd"] = 2
        , ["pend"] = 3
        , ["rnd"] = 4
        }
        local dir = dir_to_int[focus_arp.mode]
        dir = util.clamp(dir+d,1,4)
        local int_to_dir = {"fwd","bkwd","pend","rnd"}
        focus_arp.mode = int_to_dir[dir]
      elseif page.arp_param[id] == 3 then
        focus_arp.start_point = util.clamp(focus_arp.start_point+d,1,focus_arp.end_point)
      elseif page.arp_param[id] == 4 then
        if #focus_arp.notes > 0 then
          focus_arp.end_point = util.clamp(focus_arp.end_point+d,focus_arp.start_point,#focus_arp.notes)
        end
      elseif page.arp_param[id] == 5 then
        local working = arp[page.arp_page_sel].retrigger and 0 or 1
        working = util.clamp(working+d,0,1)
        arp[page.arp_page_sel].retrigger = (working == 0 and true or false)
      end

    elseif menu == 10 then
      local current = rnd[page.rnd_page][page.rnd_page_sel[page.rnd_page]]
      if page.rnd_page_section == 2 then

        if page.rnd_page_edit[page.rnd_page] == 1 then
          if not current.playing then
            current.param = rnd.targets[util.clamp(find_the_key(rnd.targets,current.param)+d,1,#rnd.targets)]
          end
        elseif page.rnd_page_edit[page.rnd_page] == 2 then
          if d > 0 then
            current.mode = "destructive"
          elseif d < 0 then
            current.mode = "non-destructive"
          end
        elseif page.rnd_page_edit[page.rnd_page] == 3 then
          current.num = util.clamp(current.num+d,1,32)
          current.time = current.num / current.denom
        elseif page.rnd_page_edit[page.rnd_page] == 4 then
          current.denom = util.clamp(current.denom+d,1,32)
          current.time = current.num / current.denom
        elseif page.rnd_page_edit[page.rnd_page] == 5 then
          if current.param == "pan" then
            current.pan_min = util.clamp(current.pan_min+d,-100,current.pan_max-1)
          elseif current.param == "rate" then
            local rates_to_mins = 
            { [0.125] = 1
            , [0.25] = 2
            , [0.5] = 3
            , [1] = 4
            , [2] = 5
            , [4] = 6
            }
            local working = util.clamp(rates_to_mins[current.rate_min]+d,1,rates_to_mins[current.rate_max])
            local mins_to_rates = {0.125,0.25,0.5,1,2,4}
            current.rate_min = mins_to_rates[working]
          elseif current.param == "rate slew" then
            current.rate_slew_min = util.clamp(current.rate_slew_min+d/10,0,current.rate_slew_max-0.1)
          elseif current.param == "semitone offset" then
            local which_scale = nil
            for i = 1,#MusicUtil.SCALES do
              if MusicUtil.SCALES[i].name == current.offset_scale then
                which_scale = i
              end
            end
            local working = util.clamp(which_scale+d,1,#MusicUtil.SCALES)
            current.offset_scale = MusicUtil.SCALES[working].name
          elseif current.param == "filter tilt" then
            current.filter_min = util.clamp(current.filter_min+d/100,-1,current.filter_max-0.01)
          end
        elseif page.rnd_page_edit[page.rnd_page] == 6 then
          if current.param == "pan" then
            current.pan_max = util.clamp(current.pan_max+d,current.pan_min+1,100)
          elseif current.param == "rate" then
            local rates_to_mins = 
            { [0.125] = 1
            , [0.25] = 2
            , [0.5] = 3
            , [1] = 4
            , [2] = 5
            , [4] = 6
            }
            local working = util.clamp(rates_to_mins[current.rate_max]+d,rates_to_mins[current.rate_min],6)
            local maxes_to_rates = {0.125,0.25,0.5,1,2,4}
            current.rate_max = maxes_to_rates[working]
          elseif current.param == "rate slew" then
            current.rate_slew_max = util.clamp(current.rate_slew_max+d/10,current.rate_slew_min+0.1,20)
          elseif current.param == "semitone offset" then
          elseif current.param == "filter tilt" then
            current.filter_max = util.clamp(current.filter_max+d/100,current.filter_min+0.01,1)
          end
        end
      end
    end
  end

  if menu == 8 then
    rytm.reer(rytm.track_edit)
  end

  if menu == 3 then
    local focused_pad = nil
    if bank[n].focus_hold == true then
      focused_pad = bank[n].focus_pad
    else
      focused_pad = bank[n].id
    end
    if page.levels_sel == 0 then
      if key1_hold or grid.alt == 1 then
        -- for i = 1,16 do
        --   bank[n][i].level = util.clamp(bank[n][i].level+d/10,0,2)
        -- end
        bank[n].global_level = util.clamp(bank[n].global_level+d/10,0,2)
      else
        bank[n][focused_pad].level = util.clamp(bank[n][focused_pad].level+d/10,0,2)
      end
      -- TODO figure out of this is necessary:
      -- it wouldn't let you adjust the volume on an enveloped
      -- if bank[n][bank[n].id].enveloped == false then
      if bank[n][bank[n].id].envelope_mode == 2 or bank[n][bank[n].id].enveloped == false then
        if bank[n].focus_hold == false then
          softcut.level_slew_time(n+1,1.0)
          softcut.level(n+1,bank[n][bank[n].id].level*bank[n].global_level)
          softcut.level_cut_cut(n+1,5,(bank[n][bank[n].id].left_delay_level*bank[n][bank[n].id].level)*bank[n].global_level)
          softcut.level_cut_cut(n+1,6,(bank[n][bank[n].id].right_delay_level*bank[n][bank[n].id].level)*bank[n].global_level)
        end
      end
    elseif page.levels_sel == 1 then

      if key1_hold or grid.alt == 1 then
        for j = 1,16 do
          local pre_enveloped = bank[n][j].enveloped
          local pre_mode = bank[n][j].envelope_mode

          bank[n][j].envelope_mode = util.clamp(bank[n][j].envelope_mode + d,0,3)

          if bank[n][j].envelope_mode == 0 then
            bank[n][j].enveloped = false
            -- TODO: figure out if this is necessary
            -- if pre_enveloped ~= bank[n][j].enveloped then
            --   cheat(n, bank[n].id)
            -- end
          else
            bank[n][j].enveloped = true
            if pre_enveloped ~= bank[n][j].enveloped then
              cheat(n, bank[n].id)
            end
          end

          -- if bank[n][j].enveloped then
          --   if d < 0 then
          --     bank[n][j].enveloped = false
          --     if pre_enveloped ~= bank[n][j].enveloped then
          --       cheat(n, bank[n].id)
          --     end
          --   end
          -- else
          --   if d > 0 then
          --     bank[n][j].enveloped = true
          --     if pre_enveloped ~= bank[n][j].enveloped then
          --       cheat(n, bank[n].id)
          --     end
          --   end
          -- end
          
        end

      else

        local pre_enveloped = bank[n][focused_pad].enveloped
        local pre_mode = bank[n][focused_pad].envelope_mode
        bank[n][focused_pad].envelope_mode = util.clamp(bank[n][focused_pad].envelope_mode + d,0,3)
        
        if bank[n][focused_pad].envelope_mode == 0 then
          bank[n][focused_pad].enveloped = false
          -- if pre_enveloped ~= bank[n][bank[n].id].enveloped then
          --   if bank[n].focus_hold == false then
          --     cheat(n, bank[n].id)
          --   end
          -- end
        else
          bank[n][focused_pad].enveloped = true
          if pre_enveloped ~= bank[n][focused_pad].enveloped then
            if bank[n].focus_hold == false then
              cheat(n, bank[n].id)
            end
          elseif pre_mode ~= bank[n][focused_pad].envelope_mode then
            if bank[n].focus_hold == false then
              cheat(n, bank[n].id)
            end
          end
        end

      end

    elseif page.levels_sel == 2 then
      if key1_hold or grid.alt == 1 then
        for j = 1,16 do
          if bank[n][j].enveloped then
            if d>0 then
              bank[n][j].envelope_loop = true
            else
              bank[n][j].envelope_loop = false
            end
          end
        end
      else
        if bank[n][focused_pad].enveloped then
          local pre_loop = bank[n][focused_pad].envelope_loop
          if d>0 then
            bank[n][focused_pad].envelope_loop = true
            if pre_loop ~= bank[n][focused_pad].envelope_loop then
              if bank[n].focus_hold == false then
                cheat(n, bank[n].id)
              end
            end
          else
            bank[n][focused_pad].envelope_loop = false
          end
        end
      end

    elseif page.levels_sel == 3 then
      if key1_hold or grid.alt == 1 then
        for j = 1,16 do
          if bank[n][j].enveloped then
            bank[n][j].envelope_time = util.explin(0.1,60,0.1,60,bank[n][j].envelope_time)
            bank[n][j].envelope_time = util.clamp(bank[n][j].envelope_time+d/10,0.1,60)
            bank[n][j].envelope_time = util.linexp(0.1,60,0.1,60,bank[n][j].envelope_time)
          end
        end
      else
        if bank[n][focused_pad].enveloped then
          bank[n][focused_pad].envelope_time = util.explin(0.05,60,0.05,60,bank[n][focused_pad].envelope_time)
          bank[n][focused_pad].envelope_time = util.clamp(bank[n][focused_pad].envelope_time+d/10,0.05,60)
          bank[n][focused_pad].envelope_time = util.linexp(0.05,60,0.05,60,bank[n][focused_pad].envelope_time)
        end
      end
      env_counter[n].time = (bank[n][focused_pad].envelope_time/(bank[n][focused_pad].level/0.05))
    end
  end
  if menu == 4 then
    local focused_pad = nil
    if key1_hold or grid.alt == 1 then
      for i = 1,16 do
        bank[n][i].pan = util.clamp(bank[n][i].pan+d/10,-1,1)
      end
    else
      if bank[n].focus_hold == true then
        focused_pad = bank[n].focus_pad
      else
        focused_pad = bank[n].id
      end
      bank[n][focused_pad].pan = util.clamp(bank[n][focused_pad].pan+d/10,-1,1)
    end
    softcut.pan(n+1, bank[n][bank[n].id].pan)
  elseif menu == 5 then
    local filt_page = page.filtering_sel + 1
    if filt_page == 1 then
      if bank[n][bank[n].id].filter_type == 4 then
        if key1_hold or grid.alt == 1 then
          if slew_counter[n] ~= nil then
            slew_counter[n].prev_tilt = bank[n][bank[n].id].tilt
          end
          bank[n][bank[n].id].tilt = util.clamp(bank[n][bank[n].id].tilt+(d/100),-1,1)
          if d < 0 then
            if util.round(bank[n][bank[n].id].tilt*100) < 0 and util.round(bank[n][bank[n].id].tilt*100) > -9 then
              bank[n][bank[n].id].tilt = -0.10
            elseif util.round(bank[n][bank[n].id].tilt*100) > 0 and util.round(bank[n][bank[n].id].tilt*100) < 32 then
              bank[n][bank[n].id].tilt = 0.0
            end
          elseif d > 0 and util.round(bank[n][bank[n].id].tilt*100) > 0 and util.round(bank[n][bank[n].id].tilt*100) < 32 then
            bank[n][bank[n].id].tilt = 0.32
          end
          slew_filter(n,slew_counter[n].prev_tilt,bank[n][bank[n].id].tilt,bank[n][bank[n].id].q,bank[n][bank[n].id].q,15)
        else
          if slew_counter[n] ~= nil then
            slew_counter[n].prev_tilt = bank[n][bank[n].id].tilt
          end
          for j = 1,16 do
            bank[n][j].tilt = util.clamp(bank[n][j].tilt+(d/100),-1,1)
            if d < 0 then
              if util.round(bank[n][j].tilt*100) < 0 and util.round(bank[n][j].tilt*100) > -9 then
                bank[n][j].tilt = -0.10
              elseif util.round(bank[n][j].tilt*100) > 0 and util.round(bank[n][j].tilt*100) < 32 then
                bank[n][j].tilt = 0.0
              end
            elseif d > 0 and util.round(bank[n][j].tilt*100) > 0 and util.round(bank[n][j].tilt*100) < 32 then
              bank[n][j].tilt = 0.32
            end
          end
          slew_filter(n,slew_counter[n].prev_tilt,bank[n][bank[n].id].tilt,bank[n][bank[n].id].q,bank[n][bank[n].id].q,15)
        end
      end
    elseif filt_page == 2 then
      if key1_hold or grid.alt == 1 then
        bank[n][bank[n].id].tilt_ease_time = util.clamp(bank[n][bank[n].id].tilt_ease_time+(d/1), 5, 15000)
      else
        for j = 1,16 do
          bank[n][j].tilt_ease_time = util.clamp(bank[n][j].tilt_ease_time+(d/1), 5, 15000)
        end
      end
    elseif filt_page == 3 then
      if key1_hold or grid.alt == 1 then
        bank[n][bank[n].id].tilt_ease_type = util.clamp(bank[n][bank[n].id].tilt_ease_type+d, 1, 2)
      else
        for j = 1,16 do
          bank[n][j].tilt_ease_type = util.clamp(bank[n][j].tilt_ease_type+d, 1, 2)
        end
      end
    end
  end
  redraw()
end

function ea.move_play_window(target,delta)
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local current_difference = (target.end_point - target.start_point)
  local s_p = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  local current_clip = duration*(target.clip-1)
  if target.start_point + current_difference <= s_p+duration then
    target.start_point = util.clamp(target.start_point + delta, s_p, s_p+duration)
    target.end_point = target.start_point + current_difference
  else
    target.end_point = s_p+duration
    target.start_point = target.end_point - current_difference
  end
end

function ea.move_rec_window(target,delta)
  local current_difference = (target.end_point - target.start_point)
  local current_clip = 8*(target.clip-1)
  if delta >=0 then
    --if util.round(target.end_point + current_difference,0.01) < (9+current_clip) then
    -- MBUTZ
    if util.round(target.end_point + current_difference,0.01) <= (9+current_clip) then
      target.start_point = util.clamp(target.start_point + (current_difference * (delta > 0 and 1 or -1)), (1+current_clip),(9+current_clip))
      target.end_point = target.start_point + current_difference
    end
  else
    if util.round(target.start_point - current_difference,0.01) >= (1+current_clip) then
      target.end_point = util.clamp(target.end_point + current_difference * (delta>0 and 1 or -1), (1+current_clip),(9+current_clip))
      target.start_point = target.end_point - current_difference
    end
  end
end

function ea.change_pad(target,delta)
  pad = bank[target]
  if grid_pat[target].play == 0 and grid_pat[target].tightened_start == 0 and not arp[target].playing and midi_pat[target].play == 0 then
    pad.id = util.clamp(pad.id + delta,1,16)
    selected[target].x = (math.ceil(pad.id/4)+(5*(target-1)))
    selected[target].y = 8-((pad.id-1)%4)
    cheat(target,pad.id)
  else
    pad.focus_pad = util.clamp(pad.focus_pad + delta,1,16)
  end
  grid_dirty = true
end

function ea.change_buffer(target,delta)
  local pre_adjust = target.clip
  local current_difference = (target.end_point - target.start_point)
  target.clip = util.clamp(target.clip+delta,1,3)
  target.start_point = target.start_point - ((pre_adjust - target.clip)*8)
  target.end_point = target.start_point + current_difference
  grid_dirty = true
end

function ea.change_pad_clip(target,delta)
  local focused_pad = nil
  if grid_pat[target].play == 0 and grid_pat[target].tightened_start == 0 and not arp[target].playing and midi_pat[target].play == 0 then
    focused_pad = bank[target].id
  else
    focused_pad = bank[target].focus_pad
  end
  pad = bank[target][focused_pad]
  local pre_adjust = pad.clip
  local current_difference = (pad.end_point - pad.start_point)
  if pad.mode == 1 and pad.clip + delta > 3 then
    pad.mode = 2
    pad.clip = 1
  elseif pad.mode == 2 and pad.clip + delta < 1 then
    pad.mode = 1
    pad.clip = 3
  else
    pad.clip = util.clamp(pad.clip+delta,1,3)
  end
  pad.start_point = pad.start_point - ((pre_adjust - pad.clip)*8)
  pad.end_point = pad.start_point + current_difference
  if grid_pat[target].play == 0 and grid_pat[target].tightened_start == 0 and not arp[target].playing and midi_pat[target].play == 0 then
    cheat(target,bank[target].id)
  end
  if focused_pad == 16 then
    for i = 1,15 do
      local pre_adjust = bank[target][i].clip
      bank[target][i].mode = bank[target][16].mode
      bank[target][i].clip = bank[target][16].clip
      local current_difference = (bank[target][i].end_point - bank[target][i].start_point)
      bank[target][i].start_point = bank[target][i].start_point - ((pre_adjust - bank[target][i].clip)*8)
      bank[target][i].end_point = bank[target][i].start_point + current_difference
    end
  end
  grid_dirty = true
end

function ea.move_start(target,delta)
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local s_p = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  if delta >= 0 and target.start_point < (target.end_point - delta) then
    target.start_point = util.clamp(target.start_point+delta,s_p,s_p+duration)
  elseif delta < 0 then
    target.start_point = util.clamp(target.start_point+delta,s_p,s_p+duration)
  end
end

function ea.move_end(target,delta)
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local s_p = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  if delta <= 0 and target.start_point < target.end_point + delta then
    target.end_point = util.clamp(target.end_point+delta,s_p,s_p+duration)
  elseif delta > 0 then
    target.end_point = util.clamp(target.end_point+delta,s_p,s_p+duration)
  end
end

function ea.sc.move_play_window(target)
  pad = bank[target][bank[target].id]
  softcut.loop_start(target+1,pad.start_point)
  softcut.loop_end(target+1,pad.end_point)
end

function ea.sc.move_rec_window(target)
  softcut.loop_start(1,target.start_point)
  softcut.loop_end(1,target.end_point-0.01)
end

function ea.sc.move_start(target)
  pad = bank[target][bank[target].id]
  softcut.loop_start(target+1, pad.start_point)
end

return encoder_actions