local encoder_actions = {}

local ea = encoder_actions
ea.sc = {}

local pad; -- TODO, does this fuck things up?? it was global...

function meta_adjust_loops(d,func)

  if page.loops.meta_control then
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

function returns_target(i)
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

function encoder_actions.init(n,d)

  if menu == "macro_config" then
    macros.enc(n,d)
  elseif menu == "MIDI_config" then
    mc.midi_config_enc(n,d)
  elseif menu == "transport_config" then
    transport.enc(n,d)
  end

  if n == 1 then

    if menu == 1 then
      page.main_sel = util.clamp(page.main_sel+d,1,9)
    elseif menu == 2 then

      -- if page.loops.frame == 1 then
      --   if key1_hold then
      --     page.loops.top_option_set[page.loops.sel] = util.clamp(page.loops.top_option_set[page.loops.sel] + d,1,2)
      --   else
      --     page.loops.sel = util.clamp(page.loops.sel+d,1,5)
      --   end
      -- elseif page.loops.frame == 2 then
      --   local id = page.loops.sel
      --   if id < 4 then
      --     if key1_hold then
      --       ea.change_pad(id,d)
      --     elseif key2_hold then
      --       page.loops.top_option_set[page.loops.sel] = util.clamp(page.loops.top_option_set[page.loops.sel] + d,1,2)
      --     else
      --       -- local which_pad = nil
      --       -- if bank[id].focus_hold == false then
      --       --   which_pad = bank[id].id
      --       -- else
      --       --   which_pad = bank[id].focus_pad
      --       -- end
      --       local which_pad;
      --       if bank[id].focus_hold then
      --         which_pad = bank[id].focus_pad
      --       elseif grid_pat[id].play == 0 and midi_pat[id].play == 0 and not arp[id].playing and rytm.track[id].k == 0 then
      --         which_pad = bank[id].id
      --       else
      --         which_pad = bank[id].focus_pad
      --       end
      --       local resolution = loop_enc_resolution[id]
      --       ea.move_play_window(bank[id][which_pad],d/resolution)
      --       if bank[id].focus_hold == false then
      --         ea.sc.move_play_window(id)
      --       end
      --     end
      --   elseif id == 4 then
      --     if key1_hold then
      --       ea.change_buffer(rec[rec.focus],d)
      --     else
      --       ea.move_rec_window(rec[rec.focus],d)
      --       if rec.play_segment == rec.focus then
      --         ea.sc.move_rec_window(rec[rec.focus])
      --       end
      --     end
      --   elseif id == 5 then
      --     if key1_hold and not key2_hold then
      --       if page.loops.meta_sel < 4 then
      --         ea.change_pad(page.loops.meta_sel,d)
      --       elseif page.loops.meta_sel == 4 then
      --         rec.focus = util.clamp(rec.focus + d,1,3)
      --       end
      --       grid_dirty = true
      --     elseif not key1_hold and not key2_hold then
      --       page.loops.meta_sel = util.clamp(page.loops.meta_sel + d,1,4)
      --     elseif key2_hold and not key1_hold then
      --       adjust_loops(d,"move_play_window")
      --     end
      --   end
      -- end
    elseif menu == 6 then
      page.delay.nav = util.clamp(page.delay.nav+d,1,4)
      if page.delay.nav > 1 then
        for i = 1,2 do
          page.delay[i].menu = page.delay.nav - 1
        end
        page.delay.section = 2
      end
    elseif menu == 7 then
      page.time_sel = util.clamp(page.time_sel+d,1,6)
    elseif menu == 8 then
      rytm.track_edit = util.clamp(rytm.track_edit+d,1,3)
    elseif menu == 9 then
      -- page.arps.sel = util.clamp(page.arps.sel+d,1,3)
    end
  end
  if n == 2 then
    if menu == 1 then
      page.main_sel = util.clamp(page.main_sel+d,1,9)
    elseif menu == 2 then

      -- local focused_pad;
      -- local id = page.loops.sel

      -- if id < 4 then -- if banks

      --   if bank[page.loops.sel].focus_hold then
      --     focused_pad = bank[id].focus_pad
      --   elseif grid_pat[page.loops.sel].play == 0 and midi_pat[page.loops.sel].play == 0 and not arp[page.loops.sel].playing and rytm.track[page.loops.sel].k == 0 then
      --     focused_pad = bank[id].id
      --   else
      --     focused_pad = bank[id].focus_pad
      --   end

      --   if page.loops.frame == 1 then
      --     if page.loops.top_option_set[page.loops.sel] == 1 then
      --       ea.change_pad_clip(id,d)
      --       -- if key1_hold then
      --         for i = 1,16 do
      --           if i ~= focused_pad then
      --             if bank[id][focused_pad].mode ~= bank[id][i].mode then
      --               local old_mode = bank[id][i].mode
      --               bank[id][i].mode = bank[id][focused_pad].mode
      --               _ca.change_mode(bank[id][i],old_mode)
      --             end
      --             _ca.jump_clip(id,i,bank[id][focused_pad].clip)
      --           end
      --         end
      --       -- end
      --     elseif page.loops.top_option_set[page.loops.sel] == 2 then
      --       -- if not bank[id].focus_hold then
      --       if bank[id].focus_hold then
      --         local rates ={-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
      --         if bank[id][focused_pad].fifth then
      --           bank[id][focused_pad].fifth = false
      --         end
      --         if tab.key(rates,bank[id][focused_pad].rate) == nil then
      --           bank[id][focused_pad].rate = 1
      --         end
      --         bank[id][focused_pad].rate = rates[util.clamp(tab.key(rates,bank[id][focused_pad].rate)+d,1,#rates)]
      --         if bank[id][focused_pad].pause == false and bank[id].id == focused_pad then
      --           softcut.rate(id+1, bank[id][focused_pad].rate*bank[id][focused_pad].offset)
      --         end
      --       elseif grid_pat[id].play == 0 and midi_pat[id].play == 0 and not arp[id].playing and rytm.track[id].k == 0 then
      --         params:delta("rate "..id,d)
      --       else
      --         local rates ={-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
      --         if bank[id][focused_pad].fifth then
      --           bank[id][focused_pad].fifth = false
      --         end
      --         if tab.key(rates,bank[id][focused_pad].rate) == nil then
      --           bank[id][focused_pad].rate = 1
      --         end
      --         bank[id][focused_pad].rate = rates[util.clamp(tab.key(rates,bank[id][focused_pad].rate)+d,1,#rates)]
      --         if bank[id][focused_pad].pause == false and bank[id].id == focused_pad then
      --           softcut.rate(id+1, bank[id][focused_pad].rate*bank[id][focused_pad].offset)
      --         end
      --       end
      --       -- if key1_hold then
      --         for i = 1,16 do
      --           if i ~= focused_pad then
      --             bank[id][i].rate = bank[id][focused_pad].rate
      --           end
      --         end
      --       -- end
      --     end
      --   elseif page.loops.frame == 2 then
      --     if key2_hold then
      --       if page.loops.top_option_set[page.loops.sel] == 1 then
      --         ea.change_pad_clip(id,d)
      --       elseif page.loops.top_option_set[page.loops.sel] == 2 then
      --         if bank[id].focus_hold then
      --           local rates ={-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
      --           if bank[id][focused_pad].fifth then
      --             bank[id][focused_pad].fifth = false
      --           end
      --           if tab.key(rates,bank[id][focused_pad].rate) == nil then
      --             bank[id][focused_pad].rate = 1
      --           end
      --           bank[id][focused_pad].rate = rates[util.clamp(tab.key(rates,bank[id][focused_pad].rate)+d,1,#rates)]
      --           if bank[id][focused_pad].pause == false and bank[id].id == focused_pad then
      --             softcut.rate(id+1, bank[id][focused_pad].rate*bank[id][focused_pad].offset)
      --           end
      --         elseif grid_pat[id].play == 0 and midi_pat[id].play == 0 and not arp[id].playing and rytm.track[id].k == 0 then
      --           params:delta("rate "..id,d)
      --         else
      --           local rates ={-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
      --           if bank[id][focused_pad].fifth then
      --             bank[id][focused_pad].fifth = false
      --           end
      --           if tab.key(rates,bank[id][focused_pad].rate) == nil then
      --             bank[id][focused_pad].rate = 1
      --           end
      --           bank[id][focused_pad].rate = rates[util.clamp(tab.key(rates,bank[id][focused_pad].rate)+d,1,#rates)]
      --           if bank[id][focused_pad].pause == false and bank[id].id == focused_pad then
      --             softcut.rate(id+1, bank[id][focused_pad].rate*bank[id][focused_pad].offset)
      --           end
      --         end
      --       end
      --     else
      --       local resolution = loop_enc_resolution[id] * (key1_hold and 10 or 1)
      --       ea.move_start(bank[id][focused_pad],d/resolution)
      --       if bank[id].focus_hold == false then
      --         ea.sc.move_start(id)
      --       end
      --     end
      --   end

      -- elseif id == 4 then
      --   if page.loops.frame == 1 and page.loops.top_option_set[id] == 1 then
      --     params:delta("live_rec_feedback_"..rec.focus,d)
      --   elseif page.loops.frame == 1 and page.loops.top_option_set[id] == 2 then
      --     params:delta("rec_loop_"..rec.focus,d)
      --   elseif page.loops.frame == 2 then
      --     ea.move_rec_start(d)
      --     if key1_hold then
      --       update_waveform(1,rec[rec.focus].start_point,rec[rec.focus].end_point,128)
      --     end
      --   end
      
      -- elseif id == 5 then
      --   adjust_loops(d,"move_start")
      -- end

    elseif menu == 6 then

      -- if page.delay.section == 1 then
      --   page.delay[page.delay.focus].menu = util.clamp(page.delay[page.delay.focus].menu+d,1,3)
      -- elseif page.delay.section == 2 then
      if page.delay.nav > 1 then
        local max_items = {5,10,7}
        for i = 1,2 do
          local target = page.delay[i].menu_sel[page.delay[i].menu]
          page.delay[i].menu_sel[page.delay[i].menu] = util.clamp(target+d,1,max_items[page.delay[i].menu])
        end
      end
      
    elseif menu == 7 then
      local page_line = page.time_page_sel
      local pattern_page = page.time_sel

      if pattern_page < 4 then
        page_line[pattern_page] = util.clamp(page_line[pattern_page]+d,1,bank[pattern_page].crow_execute ~= 1 and 9 or 8)
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
          rytm.track[rytm.track_edit].rotation = util.clamp(rytm.track[rytm.track_edit].rotation + d, 0, 16)
          rytm.track[rytm.track_edit].s = rytm.rotate_pattern(rytm.track[rytm.track_edit].s, rytm.track[rytm.track_edit].rotation)
        else
          rytm.track[rytm.track_edit].k = util.clamp(rytm.track[rytm.track_edit].k+d,0,rytm.track[rytm.track_edit].n)
        end
      elseif key1_hold then
        if rytm.screen_focus == "left" then
          if d > 0 then
            rytm.track[rytm.track_edit].mode = "span"
          elseif d < 0 then
            rytm.track[rytm.track_edit].mode = "single"
          end
        else
          rytm.track[rytm.track_edit].auto_rotation = util.clamp(rytm.track[rytm.track_edit].auto_rotation + d, 0, 16)
        end
      end
    elseif menu == 9 then
      -- page.arps.param[page.arps.sel] = util.clamp(page.arps.param[page.arps.sel] + d,1,5)
    end
  end
  if n == 3 then
    
    if menu == 2 then

      -- local focused_pad;
      -- local id = page.loops.sel

      -- if id < 4 then -- if banks

      --   if bank[page.loops.sel].focus_hold then
      --     focused_pad = bank[id].focus_pad
      --   elseif grid_pat[page.loops.sel].play == 0 and midi_pat[page.loops.sel].play == 0 and not arp[page.loops.sel].playing and rytm.track[page.loops.sel].k == 0 then
      --     focused_pad = bank[id].id
      --   else
      --     focused_pad = bank[id].focus_pad
      --   end

      --   if page.loops.frame == 1 then
      --     if page.loops.top_option_set[page.loops.sel] == 1 then
      --       local current_offset = (math.log(bank[id][focused_pad].offset)/math.log(0.5))*-12
      --       current_offset = util.clamp(current_offset+d/32,-36,24)
      --       if current_offset > -0.0001 and current_offset < 0.0001 then
      --         current_offset = 0
      --       end
      --       bank[id][focused_pad].offset = math.pow(0.5, -current_offset / 12)
      --       if grid_pat[id].play == 0 and grid_pat[id].tightened_start == 0 and not arp[id].playing and midi_pat[id].play == 0 then
      --         -- if params:get("preview_clip_change") == 1 then
      --           -- cheat(id,bank[id].id)
      --           softcut.rate(id+1, bank[id][focused_pad].rate*bank[id][focused_pad].offset)
      --         -- end
      --       end
      --       -- if key1_hold then
      --         for i = 1,16 do
      --           if i ~= focused_pad then
      --             bank[id][i].offset = bank[id][focused_pad].offset
      --           end
      --         end
      --       -- end
      --     elseif page.loops.top_option_set[page.loops.sel] == 2 then
      --       bank[id][focused_pad].rate_slew = util.clamp(bank[id][focused_pad].rate_slew+d/10,0,4)
      --       softcut.rate_slew_time(id+1,bank[id][focused_pad].rate_slew)
      --       -- if key1_hold then
      --         for i = 1,16 do
      --           if i ~= focused_pad then
      --             bank[id][i].rate_slew = bank[id][focused_pad].rate_slew
      --           end
      --         end
      --       -- end
      --     end

      --   elseif page.loops.frame == 2 then
      --     if key2_hold then
      --       if page.loops.top_option_set[page.loops.sel] == 1 then
      --         local current_offset = (math.log(bank[id][focused_pad].offset)/math.log(0.5))*-12
      --         current_offset = util.clamp(current_offset+d/32,-36,24)
      --         if current_offset > -0.0001 and current_offset < 0.0001 then
      --           current_offset = 0
      --         end
      --         bank[id][focused_pad].offset = math.pow(0.5, -current_offset / 12)
      --         if grid_pat[id].play == 0 and grid_pat[id].tightened_start == 0 and not arp[id].playing and midi_pat[id].play == 0 then
      --           -- if params:get("preview_clip_change") == 1 then
      --             -- cheat(id,bank[id].id)
      --           -- end
      --           softcut.rate(id+1, bank[id][focused_pad].rate*bank[id][focused_pad].offset)
      --         end
      --       elseif page.loops.top_option_set[page.loops.sel] == 2 then
      --         bank[id][focused_pad].rate_slew = util.clamp(bank[id][focused_pad].rate_slew+d/10,0,4)
      --         softcut.rate_slew_time(id+1,bank[id][focused_pad].rate_slew)
      --       end
      --     else
      --       local resolution = loop_enc_resolution[id] * (key1_hold and 10 or 1)
      --       ea.move_end(bank[id][focused_pad],d/resolution)
      --       if bank[id].focus_hold == false then
      --         ea.sc.move_end(id)
      --       end
      --     end
      --   end

      -- elseif id == 4 then
      --   if page.loops.frame == 1 and page.loops.top_option_set[id] == 1 then
      --     params:delta("random_rec_clock_prob_"..rec.focus,d)
      --   elseif page.loops.frame == 1 and page.loops.top_option_set[id] == 2 then
      --     params:delta("live_buff_rate",d)
      --   elseif page.loops.frame == 2 then
      --     ea.move_rec_end(d)
      --     if key1_hold then
      --       update_waveform(1,rec[rec.focus].start_point,rec[rec.focus].end_point,128)
      --     end
      --   end
      
      -- elseif id == 5 then
      --   adjust_loops(d,"move_end")
      -- end

    elseif menu == 6 then

      local item = page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu]
      local delay_name = page.delay.focus == 1 and "L" or "R"
      local focused_menu = page.delay[page.delay.focus].menu
      -- if page.delay.section == 2 then
      if page.delay.nav > 1 then
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
          elseif item == 7 then
            ea.delta_delay_param(delay_name,"filter lfo active",d)
          elseif item == 8 then
            ea.delta_delay_param(delay_name,"filter lfo shape",d)
          elseif item == 9 then
            ea.delta_delay_param(delay_name,"filter lfo depth",d)
          elseif item == 10 then
            ea.delta_delay_param(delay_name,"filter lfo rate",d)
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
                -- softcut.level_cut_cut(util.round(item/2)+1,page.delay.focus+4,(target[target.id][prm[page.delay.focus]]*target[target.id].level)*target.global_level)
                softcut.level_cut_cut(util.round(item/2)+1,page.delay.focus+4,(target[target.id][prm[page.delay.focus]]*target[target.id].level)*_l.get_global_level(util.round(item/2)))
                if delay_links[del.lookup_prm(k,v)] then
                  local this_one = page.delay.focus == 1 and 2 or 1
                  -- softcut.level_cut_cut(util.round(item/2)+1,(this_one)+4,(target[target.id][prm[this_one]]*target[target.id].level)*target.global_level)
                  softcut.level_cut_cut(util.round(item/2)+1,(this_one)+4,(target[target.id][prm[this_one]]*target[target.id].level)*_l.get_global_level(util.round(item/2)))
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
      else
        page.delay.focus = util.clamp(page.delay.focus+d,1,2)
      end

    elseif menu == 7 then
      local page_line = page.time_page_sel
      local pattern_page = page.time_sel
      -- local pattern = g.device ~= nil and grid_pat[pattern_page] or midi_pat[pattern_page]
      local pattern = get_grid_connected() and grid_pat[pattern_page] or midi_pat[pattern_page]
      
      if pattern_page < 4 then
        if page_line[pattern_page] == 8 then
          bank[pattern_page].crow_execute = util.clamp(bank[pattern_page].crow_execute+d,0,1)
        elseif page_line[pattern_page] == 1 then
          if pattern.rec ~= 1 then
            if not key1_hold then
              if pattern.play == 1 then -- actually, we won't want to allow change...
              else
                pattern.playmode = util.clamp(pattern.playmode+d,1,2)
                params:set("grid_pat_"..pattern_page.."_playmode",pattern.playmode,true)
              end
            elseif key1_hold and pattern.playmode == 2 then
              key1_hold_and_modify = true
              pattern.rec_clock_time = util.clamp(pattern.rec_clock_time+d,1,64)
              params:set("grid_pat_"..pattern_page.."_rec_clock_time",pattern.rec_clock_time,true)
            end
          end
        elseif page_line[pattern_page] == 9 and bank[pattern_page].crow_execute ~= 1 then
          crow.count_execute[pattern_page] = util.clamp(crow.count_execute[pattern_page]+d,1,16)
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
        elseif page_line[pattern_page] == 7 then
          params:delta("pattern_"..pattern_page.."_quantization",d)
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
          rytm.track[rytm.track_edit].pad_offset = util.clamp(rytm.track[rytm.track_edit].pad_offset+d,-15,15)
        else
          rytm.track[rytm.track_edit].n = util.clamp(rytm.track[rytm.track_edit].n+d,1,16)
          rytm.track[rytm.track_edit].k = util.clamp(rytm.track[rytm.track_edit].k,0,rytm.track[rytm.track_edit].n)
        end
      elseif key1_hold then
        if rytm.screen_focus == "left" then
          local deci = {"0.125","0.25","0.5","1","2","4"}
          local lookup = string.format("%.4g",rytm.track[rytm.track_edit].clock_div)
          local current = (tab.key(deci, lookup))
          local new_value = util.clamp(current+d,1,#deci)
          rytm.track[rytm.track_edit].clock_div = tonumber(deci[new_value])
        else
          rytm.track[rytm.track_edit].auto_pad_offset = util.clamp(rytm.track[rytm.track_edit].auto_pad_offset+d,-15,15)
        end
      end
    end
  end

  if menu == 8 then
    rytm.reer(rytm.track_edit)
  end

  if menu == 2 then
    main_menu.process_encoder("loops",n,d)
  elseif menu == 3 then
    main_menu.process_encoder("levels",n,d)
  elseif menu == 4 then
    main_menu.process_encoder("pans",n,d)
  elseif menu == 5 then
    main_menu.process_encoder("filters",n,d)
  elseif menu == 9 then
    main_menu.process_encoder("arps",n,d)
    -- local filt_page = page.filters.sel + 1
    -- if filt_page == 1 then
    --   if bank[n][bank[n].id].filter_type == 4 then
    --     if key1_hold or grid_alt then
    --       if slew_counter[n] ~= nil then
    --         slew_counter[n].prev_tilt = bank[n][bank[n].id].tilt
    --       end
    --       bank[n][bank[n].id].tilt = util.clamp(bank[n][bank[n].id].tilt+(d/100),-1,1)
    --       if d < 0 then
    --         if util.round(bank[n][bank[n].id].tilt*100) < 0 and util.round(bank[n][bank[n].id].tilt*100) > -9 then
    --           bank[n][bank[n].id].tilt = -0.10
    --         elseif util.round(bank[n][bank[n].id].tilt*100) > 0 and util.round(bank[n][bank[n].id].tilt*100) < 32 then
    --           bank[n][bank[n].id].tilt = 0.0
    --         end
    --       elseif d > 0 and util.round(bank[n][bank[n].id].tilt*100) > 0 and util.round(bank[n][bank[n].id].tilt*100) < 32 then
    --         bank[n][bank[n].id].tilt = 0.32
    --       end
    --       slew_filter(n,slew_counter[n].prev_tilt,bank[n][bank[n].id].tilt,bank[n][bank[n].id].q,bank[n][bank[n].id].q,15)
    --     else
    --       ea.set_filter_cutoff(n,d)
    --     end
    --   end
    -- elseif filt_page == 2 then
    --   if key1_hold or grid_alt then
    --     bank[n][bank[n].id].tilt_ease_time = util.clamp(bank[n][bank[n].id].tilt_ease_time+(d/1), 5, 15000)
    --   else
    --     for j = 1,16 do
    --       bank[n][j].tilt_ease_time = util.clamp(bank[n][j].tilt_ease_time+(d/1), 5, 15000)
    --     end
    --   end
    -- elseif filt_page == 3 then
    --   params:delta("filter "..n.." q",d*-1)
    -- elseif filt_page == 4 then
    --   if key1_hold or grid_alt then
    --     bank[n][bank[n].id].tilt_ease_type = util.clamp(bank[n][bank[n].id].tilt_ease_type+d, 1, 2)
    --   else
    --     for j = 1,16 do
    --       bank[n][j].tilt_ease_type = util.clamp(bank[n][j].tilt_ease_type+d, 1, 2)
    --     end
    --   end
    -- end
  elseif menu == 10 then
    main_menu.process_encoder("rnd",n,d)
  end
  screen_dirty = true
end

function ea.move_play_window(target,delta)
  local duration = target.mode == 1 and 32 or clip[target.clip].sample_length
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

  if menu == 2 and page.loops.sel < 4 and key2_hold then
    update_waveform(target.mode,target.start_point,target.end_point,128)
  end

end

function ea.move_rec_window(target,delta)
  local current_difference = (target.end_point - target.start_point)
  local current_clip = 32*(rec.focus-1)
  if delta >=0 then
    -- MBUTZ
    if util.round(target.end_point + current_difference,0.01) <= (33+current_clip) then
      target.start_point = util.clamp(target.start_point + (current_difference * (delta > 0 and 1 or -1)), (1+current_clip),(33+current_clip))
      target.end_point = target.start_point + current_difference
    end
  else
    if util.round(target.start_point - current_difference,0.01) >= (1+current_clip) then
      target.end_point = util.clamp(target.end_point + current_difference * (delta>0 and 1 or -1), (1+current_clip),(33+current_clip))
      target.start_point = target.end_point - current_difference
    end
  end
end

function ea.change_pad(target,delta,silent)
  pad = bank[target]
  if grid_pat[target].play == 0 and grid_pat[target].tightened_start == 0 and not arp[target].playing and midi_pat[target].play == 0 then
    if not pad.focus_hold then
      local pre_pad = pad.id
      pad.id = util.clamp(pad.id + delta,1,16)
      selected[target].x = (math.ceil(pad.id/4)+(5*(target-1)))
      selected[target].y = 8-((pad.id-1)%4)
      if pre_pad ~= pad.id and not silent then
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
  target.start_point = target.start_point - ((pre_adjust - target.clip)*32)
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
    _ca.change_mode(pad,1)
    -- pad.clip = 1
    _ca.jump_clip(target,focused_pad,1)
  elseif pad.mode == 2 and pad.clip + delta < 1 then
    pad.mode = 1
    _ca.change_mode(pad,2)
    -- pad.clip = 3
    _ca.jump_clip(target,focused_pad,3)
  else
    local tryit = util.clamp(pad.clip+delta,1,3)
    _ca.jump_clip(target,focused_pad,tryit)
  end
 
  if grid_pat[target].play == 0 and grid_pat[target].tightened_start == 0 and not arp[target].playing and midi_pat[target].play == 0 then
    if params:string("preview_clip_change") == "yes" or bank[target][bank[target].id].loop then
      cheat(target,bank[target].id)
    end
  end
  
  -- if focused_pad == 16 then
  --   for i = 1,15 do
  --     if bank[target][16].mode ~= bank[target][i].mode then
  --       bank[target][i].mode = bank[target][16].mode
  --       _ca.change_mode(bank[target][i],bank[target][i].mode == 2 and 1 or 2)
  --     end
  --     _ca.jump_clip(target,i,bank[target][16].clip)
  --   end
  -- end
  
  grid_dirty = true

end

function ea.move_start(target,delta)
  local duration = target.mode == 1 and 32 or clip[target.clip].sample_length
  local s_p = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  if target.start_point+delta < (target.end_point - 0.04) then
    target.start_point = util.clamp(target.start_point+delta,s_p,s_p+duration)
  end
  if menu == 2 and page.loops.sel < 4 and key2_hold then
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
    rec[rec.focus].start_point = util.clamp(rec[rec.focus].start_point+((res)/lbr[params:get("live_buff_rate")]),(1+(32*(rec.focus-1))),(32.9+(32*(rec.focus-1))))
  elseif d < 0 then
    rec[rec.focus].start_point = util.clamp(rec[rec.focus].start_point+((res)/lbr[params:get("live_buff_rate")]),(1+(32*(rec.focus-1))),(32.9+(32*(rec.focus-1))))
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
  if menu == 2 and page.loops.sel < 4 and key2_hold then
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
    rec[rec.focus].end_point = util.clamp(rec[rec.focus].end_point+((res)/lbr[params:get("live_buff_rate")]),(1+(32*(rec.focus-1))),(33+(32*(rec.focus-1))))
  elseif d > 0 then
    if rec[rec.focus].end_point+((res)/lbr[params:get("live_buff_rate")]) <= 33+(32*(rec.focus-1)) then -- FIXME: weak point?
      rec[rec.focus].end_point = util.clamp(rec[rec.focus].end_point+((res)/lbr[params:get("live_buff_rate")]),(1+(32*(rec.focus-1))),(33+(32*(rec.focus-1))))
    else
      if params:get("rec_loop_enc_resolution") < 3 then
        rec[rec.focus].end_point = 33+(32*(rec.focus-1))
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
  params:delta("filter cutoff "..target, d/10)
end

function ea.delta_MIDI_values(target,d,quant_table)
  local c = target.index
  target.entries[c] = mc.flip_from_text(target.entries[c])
  if target.entries[c] >= 0 and quant_table then
    local current_index = tab.key(mc.midi_notes_all[quant_table[2]],target.entries[c])
    current_index = util.clamp(current_index+d,1,#mc.midi_notes_all[quant_table[2]])
    target.entries[c] = mc.midi_notes_all[quant_table[2]][current_index]
  else
    target.entries[c] = util.clamp(target.entries[c]+d,-1,127)
    target.entries[c] = mc.flip_to_text(target.entries[c])
  end
end

return encoder_actions