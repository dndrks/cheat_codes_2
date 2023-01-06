local encoder_actions = {}

local ea = encoder_actions
ea.sc = {}

function encoder_actions.init(n,d)

  if menu == "macro_config" then
    macros.enc(n,d)
  elseif menu == "MIDI_config" then
    mc.midi_config_enc(n,d)
  elseif menu == "transport_config" then
    transport.enc(n,d)
  end

  local function returns_target(i)
    if bank[i].focus_hold then
      return bank[i].focus_pad
    elseif page.loops.frame == 1 then
      return bank[i].id
    elseif page.loops.frame == 2 then
      if grid_pat[i].play == 0 and midi_pat[i].play == 0 and not arp[i].playing and rytm.track[i].k == 0 then
        return bank[i].id
      else
        if key1_hold and page.loops.meta_sel == i then
          return bank[i].focus_pad
        else
          return bank[i].id
        end
      end
    end
  end
  
  local function adjust_loops(d,func)

    if page.loops.frame == 2 then
      if page.loops.meta_sel ~= 4 then
        local i = page.loops.meta_sel
        local resolution = key1_hold and 100 or 10
        ea[func](bank[i][returns_target(i)],d/resolution)
        if bank[i].focus_hold == false or bank[i].focus_pad == bank[i].id then
          ea.sc[func](i)
        end
      else
        if func == "move_start" then
          ea.move_rec_start(d)
        elseif func == "move_end" then
          ea.move_rec_end(d)
        elseif func == "move_play_window" then
          ea.move_rec_window(rec[rec.focus],d)
          if rec.play_segment == rec.focus then
            ea.sc.move_rec_window(rec[rec.focus])
          end
        end
      end
    end

  end

  if n == 1 then

    if menu == 1 then
      page.main_sel = util.clamp(page.main_sel+d,1,9)
    elseif menu == 2 then

      if page.loops.frame == 1 then
        if key1_hold then
          page.loops.top_option_set[page.loops.sel] = util.clamp(page.loops.top_option_set[page.loops.sel] + d,1,2)
        else
          page.loops.sel = util.clamp(page.loops.sel+d,1,5)
        end
      elseif page.loops.frame == 2 then
        local id = page.loops.sel
        if id < 4 then
          if key1_hold then
            ea.change_pad(id,d)
          elseif key2_hold then
            page.loops.top_option_set[page.loops.sel] = util.clamp(page.loops.top_option_set[page.loops.sel] + d,1,2)
          else
            -- local which_pad = nil
            -- if bank[id].focus_hold == false then
            --   which_pad = bank[id].id
            -- else
            --   which_pad = bank[id].focus_pad
            -- end
            local which_pad;
            if bank[id].focus_hold then
              which_pad = bank[id].focus_pad
            elseif grid_pat[id].play == 0 and midi_pat[id].play == 0 and not arp[id].playing and rytm.track[id].k == 0 then
              which_pad = bank[id].id
            else
              which_pad = bank[id].focus_pad
            end
            local resolution = loop_enc_resolution[id]
            ea.move_play_window(bank[id][which_pad],d/resolution)
            if bank[id].focus_hold == false then
              ea.sc.move_play_window(id)
            end
          end
        elseif id == 4 then
          if key1_hold then
            ea.change_buffer(rec[rec.focus],d)
          else
            ea.move_rec_window(rec[rec.focus],d)
            if rec.play_segment == rec.focus then
              ea.sc.move_rec_window(rec[rec.focus])
            end
          end
        elseif id == 5 then
          if key1_hold and not key2_hold then
            if page.loops.meta_sel < 4 then
              ea.change_pad(page.loops.meta_sel,d)
            elseif page.loops.meta_sel == 4 then
              rec.focus = util.clamp(rec.focus + d,1,3)
            end
            grid_dirty = true
          elseif not key1_hold and not key2_hold then
            page.loops.meta_sel = util.clamp(page.loops.meta_sel + d,1,4)
          elseif key2_hold and not key1_hold then
            adjust_loops(d,"move_play_window")
          end
        end
      end
    elseif menu == 6 then
      page.delay.focus = util.clamp(page.delay.focus+d,1,2)
    elseif menu == 7 then
      page.time_sel = util.clamp(page.time_sel+d,1,6)
    elseif menu == 8 then
      rytm.track_edit = util.clamp(rytm.track_edit+d,1,3)
    elseif menu == 9 then
      page.arp_page_sel = util.clamp(page.arp_page_sel+d,1,3)
    elseif menu == 10 then
      page.rnd_page = util.clamp(page.rnd_page+d,1,3)
    -- elseif menu == "MIDI_config" then
    --   if page.midi_focus == "header" then
    --     page.midi_bank = util.clamp(page.midi_bank + d,1,3)
    --   else
    --     local i = page.midi_bank
    --     mc.numbers[i]:set_index_delta(d)
    --     mc.midi_notes[i]:set_index_delta(d)
    --     mc.midi_notes_channels[i]:set_index_delta(d)
    --     mc.midi_notes_velocities[i]:set_index_delta(d)
    --     mc.midi_ccs[i]:set_index_delta(d)
    --     mc.midi_ccs_channels[i]:set_index_delta(d)
    --     mc.midi_ccs_values[i]:set_index_delta(d)
    --   end
    end
  end
  if n == 2 then
    if menu == 1 then
      page.main_sel = util.clamp(page.main_sel+d,1,9)
    elseif menu == 2 then

      local focused_pad;
      local id = page.loops.sel

      if id < 4 then -- if banks

        if bank[page.loops.sel].focus_hold then
          focused_pad = bank[id].focus_pad
        elseif grid_pat[page.loops.sel].play == 0 and midi_pat[page.loops.sel].play == 0 and not arp[page.loops.sel].playing and rytm.track[page.loops.sel].k == 0 then
          focused_pad = bank[id].id
        else
          focused_pad = bank[id].focus_pad
        end

        if page.loops.frame == 1 then
          if page.loops.top_option_set[page.loops.sel] == 1 then
            ea.change_pad_clip(id,d)
            -- if key1_hold then
              for i = 1,16 do
                if i ~= focused_pad then
                  if bank[id][focused_pad].mode ~= bank[id][i].mode then
                    local old_mode = bank[id][i].mode
                    bank[id][i].mode = bank[id][focused_pad].mode
                    change_mode(bank[id][i],old_mode)
                  end
                  jump_clip(id,i,bank[id][focused_pad].clip)
                end
              end
            -- end
          elseif page.loops.top_option_set[page.loops.sel] == 2 then
            -- if not bank[id].focus_hold then
            if bank[id].focus_hold then
              local rates ={-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
              if bank[id][focused_pad].fifth then
                bank[id][focused_pad].fifth = false
              end
              if tab.key(rates,bank[id][focused_pad].rate) == nil then
                bank[id][focused_pad].rate = 1
              end
              bank[id][focused_pad].rate = rates[util.clamp(tab.key(rates,bank[id][focused_pad].rate)+d,1,#rates)]
              if bank[id][focused_pad].pause == false and bank[id].id == focused_pad then
                softcut.rate(id+1, bank[id][focused_pad].rate*bank[id][focused_pad].offset)
              end
            elseif grid_pat[id].play == 0 and midi_pat[id].play == 0 and not arp[id].playing and rytm.track[id].k == 0 then
              params:delta("rate "..id,d)
            else
              local rates ={-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
              if bank[id][focused_pad].fifth then
                bank[id][focused_pad].fifth = false
              end
              if tab.key(rates,bank[id][focused_pad].rate) == nil then
                bank[id][focused_pad].rate = 1
              end
              bank[id][focused_pad].rate = rates[util.clamp(tab.key(rates,bank[id][focused_pad].rate)+d,1,#rates)]
              if bank[id][focused_pad].pause == false and bank[id].id == focused_pad then
                softcut.rate(id+1, bank[id][focused_pad].rate*bank[id][focused_pad].offset)
              end
            end
            -- if key1_hold then
              for i = 1,16 do
                if i ~= focused_pad then
                  bank[id][i].rate = bank[id][focused_pad].rate
                end
              end
            -- end
          end
        elseif page.loops.frame == 2 then
          if key2_hold then
            if page.loops.top_option_set[page.loops.sel] == 1 then
              ea.change_pad_clip(id,d)
            elseif page.loops.top_option_set[page.loops.sel] == 2 then
              if bank[id].focus_hold then
                local rates ={-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
                if bank[id][focused_pad].fifth then
                  bank[id][focused_pad].fifth = false
                end
                if tab.key(rates,bank[id][focused_pad].rate) == nil then
                  bank[id][focused_pad].rate = 1
                end
                bank[id][focused_pad].rate = rates[util.clamp(tab.key(rates,bank[id][focused_pad].rate)+d,1,#rates)]
                if bank[id][focused_pad].pause == false and bank[id].id == focused_pad then
                  softcut.rate(id+1, bank[id][focused_pad].rate*bank[id][focused_pad].offset)
                end
              elseif grid_pat[id].play == 0 and midi_pat[id].play == 0 and not arp[id].playing and rytm.track[id].k == 0 then
                params:delta("rate "..id,d)
              else
                local rates ={-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
                if bank[id][focused_pad].fifth then
                  bank[id][focused_pad].fifth = false
                end
                if tab.key(rates,bank[id][focused_pad].rate) == nil then
                  bank[id][focused_pad].rate = 1
                end
                bank[id][focused_pad].rate = rates[util.clamp(tab.key(rates,bank[id][focused_pad].rate)+d,1,#rates)]
                if bank[id][focused_pad].pause == false and bank[id].id == focused_pad then
                  softcut.rate(id+1, bank[id][focused_pad].rate*bank[id][focused_pad].offset)
                end
              end
            end
          else
            local resolution = loop_enc_resolution[id] * (key1_hold and 10 or 1)
            local rs = {1,2,4}
            local rate_mod = rs[params:get("live_buff_rate")]
            ea.move_start(bank[id][focused_pad],d/(resolution * rate_mod))
            if bank[id].focus_hold == false then
              ea.sc.move_start(id)
            end
          end
        end

      elseif id == 4 then
        if page.loops.frame == 1 and page.loops.top_option_set[id] == 1 then
          params:delta("live_rec_feedback_"..rec.focus,d)
        elseif page.loops.frame == 1 and page.loops.top_option_set[id] == 2 then
          params:delta("rec_loop_"..rec.focus,d)
        elseif page.loops.frame == 2 then
          ea.move_rec_start(d)
          if key1_hold then
            update_waveform(1,rec[rec.focus].start_point,rec[rec.focus].end_point,128)
          end
        end
      
      elseif id == 5 then
        adjust_loops(d,"move_start")
      end

    elseif menu == 6 then

      if page.delay.section == 1 then
        page.delay[page.delay.focus].menu = util.clamp(page.delay[page.delay.focus].menu+d,1,3)
      elseif page.delay.section == 2 then
        local max_items = {5,6,7}
        local target = page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu]
        page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu] = util.clamp(target+d,1,max_items[page.delay[page.delay.focus].menu])
      end
      
    elseif menu == 7 then
      local page_line = page.time_page_sel
      local pattern_page = page.time_sel

      if pattern_page < 4 then
        page_line[pattern_page] = util.clamp(page_line[pattern_page]+d,1,6)
        if page_line[pattern_page] < 4 then
          page.time_scroll[pattern_page] = 1
        elseif page_line[pattern_page] < 7 then
          page.time_scroll[pattern_page] = 2
        elseif page_line[pattern_page] >= 7 then
          page.time_scroll[pattern_page] = 3
        end

      elseif pattern_page >=4 then
        page_line[pattern_page] = util.clamp(page_line[pattern_page]+d,1,7)
        local target = page.time_sel-3
        if g.device == nil and page_line[pattern_page] <= 4 then
          if page_line[pattern_page] == 1 then
            arc_param[target] = page.time_arc_loop[pattern_page-3]
          else
            arc_param[target] = page_line[pattern_page]+2
          end
        end
      end
    elseif menu == 8 then
      if not key1_hold then
        if rytm.screen_focus == "right" then
          -- rytm.track[rytm.track_edit].rotation = util.clamp(rytm.track[rytm.track_edit].rotation + d, 0, 16)
          -- rytm.track[rytm.track_edit].s = rytm.rotate_pattern(rytm.track[rytm.track_edit].s, rytm.track[rytm.track_edit].rotation)
          params:delta("euclid_rotation_"..rytm.track_edit,d)
        else
          params:delta("euclid_pulses_"..rytm.track_edit,d)
          -- rytm.track[rytm.track_edit].k = util.clamp(rytm.track[rytm.track_edit].k+d,0,rytm.track[rytm.track_edit].n)
        end
      elseif key1_hold then
        if rytm.screen_focus == "left" then
          -- if d > 0 then
          --   rytm.track[rytm.track_edit].mode = "span"
          -- elseif d < 0 then
          --   rytm.track[rytm.track_edit].mode = "single"
          -- end
          params:delta("euclid_mode_"..rytm.track_edit,d)
        else
          params:delta("euclid_auto_rotation_"..rytm.track_edit,d)
          -- rytm.track[rytm.track_edit].auto_rotation = util.clamp(rytm.track[rytm.track_edit].auto_rotation + d, 0, 16)
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
        local reasonable_max = (current_param == "semitone offset" and 5) or ((current_param == "loop" or current_param == "delay send") and 4 or 6)
        page.rnd_page_edit[page.rnd_page] = util.clamp(page.rnd_page_edit[page.rnd_page]+d,1,reasonable_max)
      end
    -- elseif menu == "MIDI_config" then
    --   local i = page.midi_bank
    --   if page.midi_focus == "notes" then
    --     ea.delta_MIDI_values(mc.midi_notes[i],d)
    --   elseif page.midi_focus == "ccs" then
    --     ea.delta_MIDI_values(mc.midi_ccs[i],d)
    --   elseif page.midi_focus == "alt" then
    --     ea.delta_MIDI_values(mc.midi_notes_channels[i],d)
    --   end
    end
  end
  if n == 3 then
    
    if menu == 2 then

      local focused_pad;
      local id = page.loops.sel

      if id < 4 then -- if banks

        if bank[page.loops.sel].focus_hold then
          focused_pad = bank[id].focus_pad
        elseif grid_pat[page.loops.sel].play == 0 and midi_pat[page.loops.sel].play == 0 and not arp[page.loops.sel].playing and rytm.track[page.loops.sel].k == 0 then
          focused_pad = bank[id].id
        else
          focused_pad = bank[id].focus_pad
        end

        if page.loops.frame == 1 then
          if page.loops.top_option_set[page.loops.sel] == 1 then
            local current_offset = (math.log(bank[id][focused_pad].offset)/math.log(0.5))*-12
            current_offset = util.clamp(current_offset+d/32,-36,24)
            if current_offset > -0.0001 and current_offset < 0.0001 then
              current_offset = 0
            end
            bank[id][focused_pad].offset = math.pow(0.5, -current_offset / 12)
            if grid_pat[id].play == 0 and grid_pat[id].tightened_start == 0 and not arp[id].playing and midi_pat[id].play == 0 then
              -- if params:get("preview_clip_change") == 1 then
                -- cheat(id,bank[id].id)
                softcut.rate(id+1, bank[id][focused_pad].rate*bank[id][focused_pad].offset)
              -- end
            end
            -- if key1_hold then
              for i = 1,16 do
                if i ~= focused_pad then
                  bank[id][i].offset = bank[id][focused_pad].offset
                end
              end
            -- end
          elseif page.loops.top_option_set[page.loops.sel] == 2 then
            bank[id][focused_pad].rate_slew = util.clamp(bank[id][focused_pad].rate_slew+d/10,0,4)
            softcut.rate_slew_time(id+1,bank[id][focused_pad].rate_slew)
            -- if key1_hold then
              for i = 1,16 do
                if i ~= focused_pad then
                  bank[id][i].rate_slew = bank[id][focused_pad].rate_slew
                end
              end
            -- end
          end

        elseif page.loops.frame == 2 then
          if key2_hold then
            if page.loops.top_option_set[page.loops.sel] == 1 then
              local current_offset = (math.log(bank[id][focused_pad].offset)/math.log(0.5))*-12
              current_offset = util.clamp(current_offset+d/32,-36,24)
              if current_offset > -0.0001 and current_offset < 0.0001 then
                current_offset = 0
              end
              bank[id][focused_pad].offset = math.pow(0.5, -current_offset / 12)
              if grid_pat[id].play == 0 and grid_pat[id].tightened_start == 0 and not arp[id].playing and midi_pat[id].play == 0 then
                -- if params:get("preview_clip_change") == 1 then
                  -- cheat(id,bank[id].id)
                -- end
                softcut.rate(id+1, bank[id][focused_pad].rate*bank[id][focused_pad].offset)
              end
            elseif page.loops.top_option_set[page.loops.sel] == 2 then
              bank[id][focused_pad].rate_slew = util.clamp(bank[id][focused_pad].rate_slew+d/10,0,4)
              softcut.rate_slew_time(id+1,bank[id][focused_pad].rate_slew)
            end
          else
            local resolution = loop_enc_resolution[id] * (key1_hold and 10 or 1)
            local rs = {1,2,4}
            local rate_mod = rs[params:get("live_buff_rate")]
            ea.move_end(bank[id][focused_pad],d/(resolution*rate_mod))
            if bank[id].focus_hold == false then
              ea.sc.move_end(id)
            end
          end
        end

      elseif id == 4 then
        if page.loops.frame == 1 and page.loops.top_option_set[id] == 1 then
          params:delta("random_rec_clock_prob_"..rec.focus,d)
        elseif page.loops.frame == 1 and page.loops.top_option_set[id] == 2 then
          params:delta("live_buff_rate",d)
        elseif page.loops.frame == 2 then
          ea.move_rec_end(d)
          if key1_hold then
            update_waveform(1,rec[rec.focus].start_point,rec[rec.focus].end_point,128)
          end
        end
      
      elseif id == 5 then
        adjust_loops(d,"move_end")
      end

    elseif menu == 6 then

      local item = page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu]
      local delay_name = page.delay.focus == 1 and "L" or "R"
      local focused_menu = page.delay[page.delay.focus].menu
      if page.delay.section == 2 then
        if focused_menu == 1 then
          if item == 1 then
            ea.delta_delay_param(delay_name,"mode",d)
            -- params:delta("delay "..delay_name..": mode",d)
          elseif item == 2 then
            local divisor;
            if delay[page.delay.focus].mode == "free" and key1_hold then
              divisor = 3
            elseif delay[page.delay.focus].mode == "free" and not key1_hold then
              divisor = 1/(100/3)
            else
              divisor = 1
            end
            ea.delta_delay_param(delay_name,delay[page.delay.focus].mode == "clocked" and "div/mult" or "free length",d/divisor)
            -- params:delta(delay[page.delay.focus].mode == "clocked" and "delay "..delay_name..": div/mult" or "delay "..delay_name..": free length",d/divisor)
          elseif item == 3 then
            local divisor = (delay[page.delay.focus].mode == "free" and key1_hold) and 10 or 0.2
            ea.delta_delay_param(delay_name,"fade time",d/divisor)
            -- params:delta("delay "..delay_name..": fade time",d/divisor)
          elseif item == 4 then
            if key1_hold then
              ea.delta_delay_param(delay_name,"rate",d)
              -- params:delta("delay "..delay_name..": rate",d)
            else
              if params:get("delay "..delay_name..": rate") < 1.0 then
                if d > 0 then
                  if params:get("delay "..delay_name..": rate") * 2 < 1.0 then
                    ea.set_delay_param(delay_name,"rate",params:get("delay "..delay_name..": rate") * 2)
                    -- params:set("delay "..delay_name..": rate",params:get("delay "..delay_name..": rate") * 2)
                  else
                    ea.set_delay_param(delay_name,"rate",1)
                    -- params:set("delay "..delay_name..": rate",1)
                  end
                else
                  if params:get("delay "..delay_name..": rate") / 2 >= 0.25 then
                    ea.set_delay_param(delay_name,"rate",params:get("delay "..delay_name..": rate") / 2)
                    -- params:set("delay "..delay_name..": rate",params:get("delay "..delay_name..": rate") / 2)
                  else
                    ea.set_delay_param(delay_name,"rate",1)
                    -- params:set("delay "..delay_name..": rate",1)
                  end
                end
              else
                ea.delta_delay_param(delay_name,"rate",d*100)
                -- params:delta("delay "..delay_name..": rate",d*100)
                if params:get("delay "..delay_name..": rate") < 1.0 then
                  ea.set_delay_param(delay_name,"rate",1)
                  -- params:set("delay "..delay_name..": rate",1)
                end
              end
            end
          elseif item == 5 then
            ea.delta_delay_param(delay_name,"feedback",d)
            -- params:delta("delay "..delay_name..": feedback",d)
          end
        elseif focused_menu == 2 then
          if item == 1 then
            ea.delta_delay_param(delay_name,"filter cut",d/10)
            -- params:delta("delay "..delay_name..": filter cut",d/10)
          elseif item == 2 then
            ea.delta_delay_param(delay_name,"filter q",d/10)
            -- params:delta("delay "..delay_name..": filter q",d/10)
          elseif item == 3 then
            ea.delta_delay_param(delay_name,"filter lp",d)
            -- params:delta("delay "..delay_name..": filter lp",d)
          elseif item == 4 then
            ea.delta_delay_param(delay_name,"filter hp",d)
            -- params:delta("delay "..delay_name..": filter hp",d)
          elseif item == 5 then
            ea.delta_delay_param(delay_name,"filter bp",d)
            -- params:delta("delay "..delay_name..": filter bp",d)
          elseif item == 6 then
            ea.delta_delay_param(delay_name,"filter dry",d)
            -- params:delta("delay "..delay_name..": filter dry",d)
          end
        elseif focused_menu == 3 then
          if item < 7 then
            if item == 1 or item == 3 or item == 5 then
              local k = page.delay[page.delay.focus].menu
              local v = page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu]
              local target = bank[util.round(item/2)]
              local prm = {"left_delay_level","right_delay_level"}
              if key1_hold then
                for i = 1,16 do
                  target[i][prm[page.delay.focus]] = util.clamp(target[i][prm[page.delay.focus]] + d/10,0,1)
                  if delay_links[del.lookup_prm(k,v)] then
                    target[i][prm[page.delay.focus == 1 and 2 or 1]] = target[i][prm[page.delay.focus]]
                  end
                end
              else
                target[target.id][prm[page.delay.focus]] = util.clamp(target[target.id][prm[page.delay.focus]] + d/10,0,1)
                if delay_links[del.lookup_prm(k,v)] then
                  target[target.id][prm[page.delay.focus == 1 and 2 or 1]] = target[target.id][prm[page.delay.focus]]
                end
              end
              grid_dirty = true
              if target[target.id].enveloped == false then
                softcut.level_cut_cut(util.round(item/2)+1,page.delay.focus+4,(target[target.id][prm[page.delay.focus]]*target[target.id].level)*target.global_level)
                if delay_links[del.lookup_prm(k,v)] then
                  local this_one = page.delay.focus == 1 and 2 or 1
                  softcut.level_cut_cut(util.round(item/2)+1,(this_one)+4,(target[target.id][prm[this_one]]*target[target.id].level)*target.global_level)
                end
              end
              
            else
              local target = bank[item/2]
              local prm = {"left_delay_thru","right_delay_thru"}
              local current_thru = target[target.id][prm[page.delay.focus]] == true and 1 or 0
              current_thru = util.clamp(current_thru + d,0,1)
              if key1_hold then
                for i = 1,16 do
                  target[i][prm[page.delay.focus]] = current_thru == 1 and true or false
                end
              else
                target[target.id][prm[page.delay.focus]] = current_thru == 1 and true or false
              end
            end
          elseif item == 7 then
            ea.delta_delay_param(delay_name,"global level",d)
          end
        end
      end

    elseif menu == 7 then
      local page_line = page.time_page_sel
      local pattern_page = page.time_sel
      -- local pattern = g.device ~= nil and grid_pat[pattern_page] or midi_pat[pattern_page]
      local pattern

      if get_grid_connected() or osc_communication then
        pattern = grid_pat[pattern_page]
      else
        pattern =  midi_pat[pattern_page]
      end
      
      if pattern_page < 4 then
        if page_line[pattern_page] == 7 then
          bank[pattern_page].crow_execute = util.clamp(bank[pattern_page].crow_execute+d,0,1)
        elseif page_line[pattern_page] == 1 then
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
        elseif page_line[pattern_page] == 8 and bank[pattern_page].crow_execute ~= 1 then
          _crow.count_execute[pattern_page] = util.clamp(_crow.count_execute[pattern_page]+d,1,16)
        elseif page_line[pattern_page] == 3 then
          params:delta("sync_clock_to_pattern_"..pattern_page,d)
        elseif page_line[pattern_page] == 4 then
         pattern.random_pitch_range = util.clamp(pattern.random_pitch_range+d,1,5)
        elseif page_line[pattern_page] == 5 then
          if pattern.rec ~= 1 and pattern.count > 0 then
            pattern.start_point = util.clamp(pattern.start_point+d,1,pattern.end_point)
            --pattern_length_to_bars(pattern, "non-destructive")
            if quantized_grid_pat[pattern_page].current_step < pattern.start_point then
              quantized_grid_pat[pattern_page].current_step = pattern.start_point
              quantized_grid_pat[pattern_page].sub_step = 1
            end
          end
        elseif page_line[pattern_page] == 6 then
          if pattern.rec ~= 1 and pattern.count > 0 then
            pattern.end_point = util.clamp(pattern.end_point+d,pattern.start_point,pattern.count)
            --pattern_length_to_bars(pattern, "non-destructive")
            if quantized_grid_pat[pattern_page].current_step > pattern.end_point then
              quantized_grid_pat[pattern_page].current_step = pattern.start_point
              quantized_grid_pat[pattern_page].sub_step = 1
            end
          end
        end
      else
        if not key1_hold then
          if page_line[pattern_page] == 1 then
            page.time_arc_loop[pattern_page-3] = util.clamp(page.time_arc_loop[pattern_page-3]+d,1,3)
            -- if g.device == nil then
              arc_param[pattern_page-3] = page.time_arc_loop[pattern_page-3]
              grid_dirty = true
            -- end
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
          -- rytm.track[rytm.track_edit].pad_offset = util.clamp(rytm.track[rytm.track_edit].pad_offset+d,-15,15)
          params:delta("euclid_pad_offset_"..rytm.track_edit,d)
        else
          -- rytm.track[rytm.track_edit].n = util.clamp(rytm.track[rytm.track_edit].n+d,1,16)
          -- rytm.track[rytm.track_edit].k = util.clamp(rytm.track[rytm.track_edit].k,0,rytm.track[rytm.track_edit].n)
          params:delta("euclid_duration_"..rytm.track_edit,d)
        end
      elseif key1_hold then
        if rytm.screen_focus == "left" then
          -- local deci = {"0.25","0.5","1","2","4"}
          -- local lookup = string.format("%.4g",rytm.track[rytm.track_edit].clock_div)
          -- local current = (tab.key(deci, lookup))
          -- local new_value = util.clamp(current+d,1,#deci)
          -- rytm.track[rytm.track_edit].clock_div = tonumber(deci[new_value])
          params:delta("euclid_clock_div_"..rytm.track_edit,d)
        else
          -- rytm.track[rytm.track_edit].auto_pad_offset = util.clamp(rytm.track[rytm.track_edit].auto_pad_offset+d,-15,15)
          params:delta("euclid_auto_offset_"..rytm.track_edit,d)
        end
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
        local rounded = arp[page.arp_page_sel].alt and util.round(bank[id][bank[id].id].arp_time,0.0001) or util.round(focus_arp.time,0.0001)
        local working = deci_to_int[tostring(rounded)]
        working = util.clamp(working+d,1,11)
        local int_to_deci = {0.125,1/6,0.25,1/3,0.5,2/3,1,4/3,2,8/3,4}
        if arp[page.arp_page_sel].alt then
          bank[page.arp_page_sel][bank[page.arp_page_sel].id].arp_time = int_to_deci[working]
          focus_arp.time = bank[page.arp_page_sel][bank[page.arp_page_sel].id].arp_time
        else
          -- focus_arp.time = int_to_deci[working]
          -- for i = 1,16 do
          --   bank[page.arp_page_sel][i].arp_time = focus_arp.time
          -- end
          params:delta("arp_"..page.arp_page_sel.."_rate",d)
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
          -- current.time = current.num / current.denom
          rnd.update_time(page.rnd_page,page.rnd_page_sel[page.rnd_page])
        elseif page.rnd_page_edit[page.rnd_page] == 4 then
          current.denom = util.clamp(current.denom+d,1,32)
          -- current.time = current.num / current.denom
          rnd.update_time(page.rnd_page,page.rnd_page_sel[page.rnd_page])
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
    -- elseif menu == "MIDI_config" then
    --   local i = page.midi_bank
    --   if page.midi_focus == "notes" then
    --     ea.delta_MIDI_values(mc.midi_notes_velocities[i],d)
    --   elseif page.midi_focus == "ccs" then
    --     ea.delta_MIDI_values(mc.midi_ccs_values[i],d)
    --   elseif page.midi_focus == "alt" then
    --     ea.delta_MIDI_values(mc.midi_ccs_channels[i],d)
    --   elseif page.midi_focus == "header" then
    --     params:delta(i.."_pad_to_midi_note_scale",d)
    --   end
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
    if page.levels.sel == 0 then
      if key1_hold or grid_alt or bank[n].alt_lock then
        bank[n].global_level = util.clamp(bank[n].global_level+d/10,0,2)
      else
        bank[n][focused_pad].level = util.clamp(bank[n][focused_pad].level+d/10,0,2)
        if bank[n][focused_pad].enveloped and not bank[n][focused_pad].pause then
          if bank[n][focused_pad].level > 0.05 then
          -- if bank[n][focused_pad].envelope_time/(bank[n][focused_pad].level/0.05) ~= inf then
            env_counter[n].time = (bank[n][focused_pad].envelope_time/(bank[n][focused_pad].level/0.05))
          end
        end
      end
      if bank[n][bank[n].id].envelope_mode == 2 or bank[n][bank[n].id].enveloped == false then
        if bank[n].focus_hold == false then
          softcut.level_slew_time(n+1,1.0)
          softcut.level(n+1,bank[n][bank[n].id].level*bank[n].global_level)
          softcut.level_cut_cut(n+1,5,(bank[n][bank[n].id].left_delay_level*bank[n][bank[n].id].level)*bank[n].global_level)
          softcut.level_cut_cut(n+1,6,(bank[n][bank[n].id].right_delay_level*bank[n][bank[n].id].level)*bank[n].global_level)
        end
      end
    elseif page.levels.sel == 1 then

      local pre_enveloped = bank[n][focused_pad].enveloped
      local pre_mode = bank[n][focused_pad].envelope_mode
      bank[n][focused_pad].envelope_mode = util.clamp(bank[n][focused_pad].envelope_mode + d,0,3)
      
      if bank[n][focused_pad].envelope_mode == 0 then
        bank[n][focused_pad].enveloped = false
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

      if key1_hold or grid_alt or bank[n].alt_lock then
        for j = 1,16 do
          if j ~= focused_pad then
            bank[n][j].envelope_mode = bank[n][focused_pad].envelope_mode
            bank[n][j].enveloped = bank[n][focused_pad].enveloped
          end
        end
      end

    elseif page.levels.sel == 2 then
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
      if key1_hold or grid_alt or bank[n].alt_lock then
        for j = 1,16 do
          if j ~= focused_pad then
            bank[n][j].envelope_loop = bank[n][focused_pad].envelope_loop
          end
        end
      end

    elseif page.levels.sel == 3 then
        if bank[n][focused_pad].enveloped then
          bank[n][focused_pad].envelope_time = util.explin(0.05,60,0.05,60,bank[n][focused_pad].envelope_time)
          bank[n][focused_pad].envelope_time = util.clamp(bank[n][focused_pad].envelope_time+d/10,0.05,60)
          bank[n][focused_pad].envelope_time = util.linexp(0.05,60,0.05,60,bank[n][focused_pad].envelope_time)
        end
        if key1_hold or grid_alt or bank[n].alt_lock then
          for j = 1,16 do
            if j ~= focused_pad then
              if bank[n][j].enveloped then
                bank[n][j].envelope_time = bank[n][focused_pad].envelope_time
              end
            end
          end
        end
      if bank[n][focused_pad].level > 0.05 then
        env_counter[n].time = (bank[n][focused_pad].envelope_time/(bank[n][focused_pad].level/0.05))
      end
    end
  end
  if menu == 4 then
    local focused_pad = nil
    if key1_hold or grid_alt then
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
    local filt_page = page.filters.sel + 1
    if filt_page == 1 then
      if bank[n][bank[n].id].filter_type == 4 then
        if key1_hold or grid_alt then
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
          ea.set_filter_cutoff(n,d)
        end
      end
    elseif filt_page == 2 then
      if key1_hold or grid_alt then
        bank[n][bank[n].id].tilt_ease_time = util.clamp(bank[n][bank[n].id].tilt_ease_time+(d/1), 5, 15000)
      else
        for j = 1,16 do
          bank[n][j].tilt_ease_time = util.clamp(bank[n][j].tilt_ease_time+(d/1), 5, 15000)
        end
      end
    elseif filt_page == 3 then
      params:delta("filter "..n.." q",d*-1)
    elseif filt_page == 4 then
      if key1_hold or grid_alt then
        bank[n][bank[n].id].tilt_ease_type = util.clamp(bank[n][bank[n].id].tilt_ease_type+d, 1, 2)
      else
        for j = 1,16 do
          bank[n][j].tilt_ease_type = util.clamp(bank[n][j].tilt_ease_type+d, 1, 2)
        end
      end
    end
  end
  screen_dirty = true
end

function ea.move_play_window(target,delta)
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local current_difference = (target.end_point - target.start_point)
  local s_p = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  local current_clip = duration*(target.clip-1)
  local reasonable_max = target.mode == 1 and live[target.clip].max or clip[target.clip].max

  if params:get("loop_enc_resolution_"..target.bank_id) > 2 then

    if delta > 0 then
      if util.round(target.end_point + current_difference,0.01) <= reasonable_max then
        target.start_point = util.clamp(target.start_point + (current_difference * (delta > 0 and 1 or -1)), s_p,reasonable_max)
        target.end_point = target.start_point + current_difference
      end
    else
      if util.round(target.start_point - current_difference,0.01) >= s_p then
        target.end_point = util.clamp(target.end_point + current_difference * (delta>0 and 1 or -1), s_p, reasonable_max)
        target.start_point = target.end_point - current_difference
      end
    end

  else
    if target.start_point + current_difference <= reasonable_max then
      target.start_point = util.clamp(target.start_point + delta, s_p, reasonable_max)
      target.end_point = target.start_point + current_difference
    else
      target.end_point = reasonable_max
      target.start_point = target.end_point - current_difference
    end
    if target.end_point > reasonable_max then
      target.end_point = reasonable_max
      target.start_point = target.end_point - current_difference
    end
  end


end

function ea.move_rec_window(target,delta)
  local current_difference = (target.end_point - target.start_point)
  local current_clip = 8*(rec.focus-1)
  if delta >=0 then
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
    if not pad.focus_hold then
      local pre_pad = pad.id
      pad.id = util.clamp(pad.id + delta,1,16)
      selected[target].x = (math.ceil(pad.id/4)+(5*(target-1)))
      selected[target].y = 8-((pad.id-1)%4)
      if pre_pad ~= pad.id then
        cheat(target,pad.id)
      end
    else
      pad.focus_pad = util.clamp(pad.focus_pad + delta,1,16)
    end
    if menu == 2 and page.loops.sel < 4 and key1_hold then
      update_waveform(pad[pad.id].mode,pad[pad.id].start_point,pad[pad.id].end_point,128)
    end
  else
    pad.focus_pad = util.clamp(pad.focus_pad + delta,1,16)
    if menu == 2 and page.loops.sel < 4 and key1_hold then
      update_waveform(pad[pad.focus_pad].mode,pad[pad.focus_pad].start_point,pad[pad.focus_pad].end_point,128)
    end
  end
  grid_dirty = true
end

function ea.change_buffer(target,delta)
  local pre_adjust = target.clip
  local current_difference = (target.end_point - target.start_point)
  if target ~= rec[rec.focus] then
    target.clip = util.clamp(target.clip+delta,1,3)
  else
    rec.focus = util.clamp(rec.focus+delta,1,3)
  end
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
    change_mode(pad,1)
    -- pad.clip = 1
    jump_clip(target,focused_pad,1)
  elseif pad.mode == 2 and pad.clip + delta < 1 then
    pad.mode = 1
    change_mode(pad,2)
    -- pad.clip = 3
    jump_clip(target,focused_pad,3)
  else
    local tryit = util.clamp(pad.clip+delta,1,3)
    jump_clip(target,focused_pad,tryit)
  end
 
  if grid_pat[target].play == 0 and grid_pat[target].tightened_start == 0 and not arp[target].playing and midi_pat[target].play == 0 then
    if params:get("preview_clip_change") == 1 or bank[target][bank[target].id].loop then
      cheat(target,bank[target].id)
    end
  end
  
  -- if focused_pad == 16 then
  --   for i = 1,15 do
  --     if bank[target][16].mode ~= bank[target][i].mode then
  --       bank[target][i].mode = bank[target][16].mode
  --       change_mode(bank[target][i],bank[target][i].mode == 2 and 1 or 2)
  --     end
  --     jump_clip(target,i,bank[target][16].clip)
  --   end
  -- end
  
  grid_dirty = true

end

function ea.move_start(target,delta)
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local s_p = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  if target.start_point+delta < (target.end_point - 0.04) then
    target.start_point = util.clamp(target.start_point+delta,s_p,s_p+duration)
  end
  if menu == 2 and page.loops.sel < 4 and key1_hold then
    update_waveform(target.mode,target.start_point,target.end_point,128)
  end
end

function ea.move_rec_start(d)
  local lbr = {1,2,4}
  local res;
  if params:get("rec_loop_enc_resolution") == 1 then
    res = key1_hold and d/100 or d/10
  else
    res = d/rec_loop_enc_resolution
  end
  if d >= 0 and util.round(rec[rec.focus].start_point + ((res)/lbr[params:get("live_buff_rate")]),0.01) < util.round(rec[rec.focus].end_point,0.01) then
    rec[rec.focus].start_point = util.clamp(rec[rec.focus].start_point+((res)/lbr[params:get("live_buff_rate")]),(1+(8*(rec.focus-1))),(8.9+(8*(rec.focus-1))))
  elseif d < 0 then
    rec[rec.focus].start_point = util.clamp(rec[rec.focus].start_point+((res)/lbr[params:get("live_buff_rate")]),(1+(8*(rec.focus-1))),(8.9+(8*(rec.focus-1))))
  end
  if rec.play_segment == rec.focus then
    softcut.loop_start(1, rec[rec.focus].start_point)
  end
end

function ea.move_end(target,delta)
  local duration = target.mode == 1 and live[target.clip].max or clip[target.clip].max
  local s_p = target.mode == 1 and live[target.clip].min or clip[target.clip].min

  if delta > 0 then
    if util.round(target.end_point + delta,0.01) <= duration then
      target.end_point = util.clamp(util.round(target.end_point + delta,0.01),s_p,duration)
    end
  else
    if target.start_point < ((target.end_point+delta) - 0.04) then
      target.end_point = util.clamp(util.round(target.end_point + delta,0.01),s_p,s_p+duration)
    end
  end
  if menu == 2 and page.loops.sel < 4 and key1_hold then
    update_waveform(target.mode,target.start_point,target.end_point,128)
  end
end

function ea.move_rec_end(d)
  local lbr = {1,2,4}
  local res;
  if params:get("rec_loop_enc_resolution") == 1 then
    res = key1_hold and d/100 or d/10
  else
    res = d/rec_loop_enc_resolution
  end
  if d <= 0 and util.round(rec[rec.focus].start_point,0.01) < util.round(rec[rec.focus].end_point + ((res)/lbr[params:get("live_buff_rate")]),0.01) then
    rec[rec.focus].end_point = util.clamp(rec[rec.focus].end_point+((res)/lbr[params:get("live_buff_rate")]),(1+(8*(rec.focus-1))),(9+(8*(rec.focus-1))))
  elseif d > 0 then
    if rec[rec.focus].end_point+((res)/lbr[params:get("live_buff_rate")]) <= 9+(8*(rec.focus-1)) then -- FIXME: weak point?
      rec[rec.focus].end_point = util.clamp(rec[rec.focus].end_point+((res)/lbr[params:get("live_buff_rate")]),(1+(8*(rec.focus-1))),(9+(8*(rec.focus-1))))
    else
      if params:get("rec_loop_enc_resolution") < 3 then
        rec[rec.focus].end_point = 9+(8*(rec.focus-1))
      end
    end
  end
  if rec.play_segment == rec.focus then
    softcut.loop_end(1, rec[rec.focus].end_point-0.01)
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

function ea.sc.move_end(target)
  pad = bank[target][bank[target].id]
  softcut.loop_end(target+1, pad.end_point)
end

function ea.check_delay_links(orig,dest,prm)
  if delay_links[prm] then
    params:set("delay "..dest..": "..prm,params:get("delay "..orig..": "..prm))
  end
  grid_dirty = true
end

function ea.delta_delay_param(target,prm,d)
  params:delta("delay "..target..": "..prm,d)
end

function ea.set_delay_param(target,prm,val)
  params:set("delay "..target..": "..prm,val)
end

function ea.set_filter_cutoff(target,d)
  if slew_counter[target] ~= nil then
    slew_counter[target].prev_tilt = bank[target][bank[target].id].tilt
  end
  for j = 1,16 do
    bank[target][j].tilt = util.clamp(bank[target][j].tilt+(d/100),-1,1)
    if d < 0 then
      if util.round(bank[target][j].tilt*100) < 0 and util.round(bank[target][j].tilt*100) > -9 then
        bank[target][j].tilt = -0.10
      elseif util.round(bank[target][j].tilt*100) > 0 and util.round(bank[target][j].tilt*100) < 32 then
        bank[target][j].tilt = 0.0
      end
    elseif d > 0 and util.round(bank[target][j].tilt*100) > 0 and util.round(bank[target][j].tilt*100) < 32 then
      bank[target][j].tilt = 0.32
    end
  end
  slew_filter(target,slew_counter[target].prev_tilt,bank[target][bank[target].id].tilt,bank[target][bank[target].id].q,bank[target][bank[target].id].q,15)
  params:set("filter tilt "..tonumber(string.format("%.0f",target)),bank[target][bank[target].id].tilt,"true")
end

function ea.delta_MIDI_values(target,d) -- this is changing all, somehow TODO
  -- target = mc.midi_notes_velocities[i]
  local c = target.index
  target.entries[c] = mc.flip_from_text(target.entries[c])
  target.entries[c] = util.clamp(target.entries[c]+d,-1,127)
  target.entries[c] = mc.flip_to_text(target.entries[c])
end

return encoder_actions