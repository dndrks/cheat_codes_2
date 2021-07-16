local _gleds = {}

local lit = {}

function _gleds.clear_lit()
  lit = {}
end

function _gleds.grid_entry(e)
  if e.state > 0 then
    lit[e.id] = {}
    lit[e.id].x = e.x
    lit[e.id].y = e.y
  else
    if lit[e.id] ~= nil then
      lit[e.id] = nil
    end
  end
  -- grid_redraw()
  grid_dirty = true
end

led_maps =
--                    {   VB,4S,GS  }
{
  -- main page
  ["square_off"]          =   {3,4,15}
  , ["square_selected"]   =   {15,15,0}
  , ["square_held"]       =   {8,12,0}
  , ["square_dim"]        =   {5,8,0}
  , ["zilchmo_off"]       =   {3,4,15} -- is this right?
  , ["zilchmo_on"]        =   {15,12,0}
  , ["pad_pause"]         =   {15,12,15}
  , ["pad_play"]          =   {3,4,0}
  , ["rec_record"]        =   {9,8,15}
  , ["rec_overdub"]       =   {9,8,15}
  , ["rec_play"]          =   {15,12,15}
  , ["rec_pause"]         =   {5,4,0}
  , ["rec_off"]           =   {3,0,0}
  , ["arc_rec_rec"]       =   {15,12,15}
  , ["arc_rec_play"]      =   {9,8,15}
  , ["arc_rec_pause"]     =   {5,4,0}
  , ["arc_rec_off"]       =   {0,0,0}
  , ["arc_param_show"]    =   {5,4,0}
  , ["grid_alt_on"]       =   {15,12,15}
  , ["grid_alt_off"]      =   {3,4,0}
  , ["clip"]              =   {8,8,15}
  , ["mode"]              =   {6,8,15}
  , ["loop_on"]           =   {4,8,15}
  , ["loop_off"]          =   {2,4,0}
  , ["arp_on"]            =   {4,4,0}
  , ["arp_pause"]         =   {4,8,15}
  , ["arp_play"]          =   {10,12,15}
  , ["live_empty"]        =   {3,4,0}
  , ["live_rec"]          =   {10,12,15}
  , ["live_pause"]        =   {5,8,0}
  , ["alt_on"]            =   {15,12,15}
  , ["alt_off"]           =   {3,4,0}
  , ["focus_on"]          =   {10,8,15}

  -- filters page
  , ["filter_page_sel"]   =   {10,8,15}
  , ["filter_engaged"]    =   {10,12,15}
  , ["filter_disengaged"] =   {4,4,0}
  , ["filter_level_on"]   =   {8,8,15}
  , ["filter_level_on_disengaged"]   =   {4,0,0}
  , ["filter_level_off"]  =   {2,4,0}
  -- , ["focus_soft"]        =   {10,8,15}

  -- seq page
  , ["step_no_data"]      =   {2,4,0}
  , ["step_yes_data"]     =   {4,8,15}
  , ["step_loops"]        =   {4,8,15}
  , ["slot_saved"]        =   {7,8,0}
  , ["slot_empty"]        =   {2,4,0}
  , ["slot_loaded"]       =   {15,15,15}
  , ["step_current"]      =   {15,15,15}
  , ["step_held"]         =   {9,8,15}
  , ["loop_duration"]     =   {4,4,0}
  , ["meta_duration"]     =   {4,4,15}
  , ["meta_step_hi"]      =   {6,8,15}
  , ["meta_step_lo"]      =   {2,4,0}
  , ["loop_mod_hi"]       =   {12,12,15}
  , ["loop_mod_lo"]       =   {3,4,0}

  -- delay page
  , ["bundle_empty"]      =   {2,4,0}
  , ["bundle_saved"]      =   {7,8,0}
  , ["bundle_loaded"]     =   {15,12,15}
  , ["time_to_led.5"]     =   {5,4,15}
  , ["time_to_led.25"]    =   {10,8,15}
  , ["time_to_led.125"]   =   {15,12,15}
  , ["time_to_led2"]      =   {3,4,15}
  , ["time_to_led4"]      =   {6,8,15}
  , ["time_to_led8"]      =   {12,12,15}
  , ["time_to_led16"]     =   {15,12,15}
  , ["reverse_on"]        =   {7,8,15}
  , ["reverse_off"]       =   {3,4,0}
  , ["wobble_on"]         =   {15,12,15}
  , ["wobble_off"]        =   {0,0,0}
  , ["level_lo"]          =   {2,4,0}
  , ["level_hi"]          =   {7,8,15}
  , ["selected_bank"]     =   {7,8,15}
  , ["unselected_bank"]   =   {2,4,0}
  , ["64_bank_send"]      =   {4,8,15}

  -- euclid
  , ["rytm_current_step_active"]      =   {15,15,15}
  , ["rytm_current_step_inactive"]    =   {8,12,0}
  , ["rytm_step_active"]    =   {5,8,15}
  , ["rytm_step_inactive"]    =   {3,3,0}
  
  -- misc
  , ["page_led"]          =   {{0,0,0},{15,15,15},{15,15,15}}
  , ["off"]               =   {0,0,0}
}

function _gleds.draw_zilch(x,y,z)
  g:led(x,y,z == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
end

function _gleds.grid_redraw()
  -- if g.device ~= nil then
  if get_grid_connected() then
    if params:string("grid_size") == "128" then
      g:all(0)
      local edition = params:get("LED_style")
      if not speed_dial_active then
        if grid_page == 0 then
          
          for j = 0,2 do
            for k = 1,4 do
              k = k+(5*j)
              for i = 8,5,-1 do
                if not rytm.grid.ui[j+1] then
                  g:led(k,i,led_maps["square_off"][edition])
                end
              end
            end
          end
          
          for i = 0,1 do
            for x = 4+i,14+i,5 do
              for j = 1,3+i do
                if not rytm.grid.ui[util.round(x/5)] then
                  g:led(x,j,zilch_leds[i == 0 and 3 or 4][util.round(x/5)][j] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
                end
              end
            end
          end

          for x = 3,13,5 do
            for j = 1,2 do
              if not rytm.grid.ui[util.round(x/5)] then
                g:led(x,j,zilch_leds[2][util.round(x/5)][j] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
              end
            end
          end
          
          for i = 1,3 do
            if not rytm.grid.ui[i] then
              local target = grid_pat[i]
              if target.rec == 1 then
                g:led(2+(5*(i-1)),1,(9*target.led))
              elseif (target.quantize == 0 and target.play == 1) or (target.quantize == 1 and target.tightened_start == 1) then
                if target.overdub == 0 then
                  g:led(2+(5*(i-1)),1,9)
                else
                  g:led(2+(5*(i-1)),1,15)
                end
              elseif target.count > 0 then
                g:led(2+(5*(i-1)),1,5)
              else
                g:led(2+(5*(i-1)),1,3)
              end
            end
          end
          
          for i = 1,3 do
            local a_p; -- this will index the arc encoder recorders
            if arc_param[i] == 1 or arc_param[i] == 2 or arc_param[i] == 3 then
              a_p = 1
            else
              a_p = arc_param[i] - 2
            end
            if arc_pat[i][a_p].rec == 1 then
              g:led(16,5-i,led_maps["arc_rec_rec"][edition])
            elseif arc_pat[i][a_p].play == 1 then
              g:led(16,5-i,led_maps["arc_rec_play"][edition])
            elseif arc_pat[i][a_p].count > 0 then
              g:led(16,5-i,led_maps["arc_rec_pause"][edition])
            else
              g:led(16,5-i,led_maps["arc_rec_off"][edition])
            end
          end
          
          -- if a.device ~= nil then
          --   for i = 1,3 do
          --     for j = 5,15,5 do
          --       g:led(j,8,arc_param[j/5] == 1 and 5 or 0)
          --       g:led(j,7,arc_param[j/5] == 2 and 5 or 0)
          --       g:led(j,6,arc_param[j/5] == 3 and 5 or 0)
          --       if arc_param[j/5] == 4 then
          --         for k = 8,6,-1 do
          --           g:led(j,k,led_maps["arc_param_show"][edition])
          --         end
          --       elseif arc_param[j/5] == 5 then
          --         g:led(j,8,led_maps["arc_param_show"][edition])
          --         g:led(j,7,led_maps["arc_param_show"][edition])
          --       elseif arc_param[j/5] == 6 then
          --         g:led(j,7,led_maps["arc_param_show"][edition])
          --         g:led(j,6,led_maps["arc_param_show"][edition])
          --       end
          --     end
          --   end
          -- end

          for j = 5,15,5 do
            g:led(j,8,(params:get("SOS_enabled_"..util.round(j/5)) == 1 and led_maps["live_rec"][edition] or 0))
          end
          
          for i = 1,3 do
            if not rytm.grid.ui[i] then
              if bank[i].focus_hold == false then
                g:led(selected[i].x, selected[i].y, led_maps["square_selected"][edition])
                if tab.count(held_keys[i]) > 0 then
                  for j = 1,#held_keys[i] do
                    local ghost_x = (5*(i-1)+1)+(math.ceil(held_keys[i][j]/4)-1)
                    local ghost_y;
                    if (held_keys[i][j] % 4) ~= 0 then
                      ghost_y = 9-(held_keys[i][j] % 4)
                    else
                      ghost_y = 5
                    end
                    g:led(ghost_x,ghost_y,8)
                    -- print(held_keys[i][j],selected[i].id,ghost_x,ghost_y,selected[i].x,selected[i].y)
                  end
                else
                end
                for j = 1,16 do
                  if bank[i][j].drone then
                    local ghost_x = (5*(i-1)+1)+(math.ceil(j/4)-1)
                    local ghost_y;
                    if (j % 4) ~= 0 then
                      ghost_y = 9-(j % 4)
                    else
                      ghost_y = 5
                    end
                    g:led(ghost_x,ghost_y,8)
                  end
                end
                if i == nil then print("2339") end
                if bank[i].id == nil then print("2340", i) end
                if bank[i][bank[i].id].pause == nil then print("2341") end
                if bank[i][bank[i].id].pause == true then
                  g:led(3+(5*(i-1)),1,led_maps["pad_pause"][edition])
                  g:led(3+(5*(i-1)),2,led_maps["pad_pause"][edition])
                else
                  g:led(3+(5*(i-1)),1,zilch_leds[2][i][1] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
                  g:led(3+(5*(i-1)),2,zilch_leds[2][i][2] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
                end
              else
                local focus_x = (math.ceil(bank[i].focus_pad/4)+(5*(i-1)))
                local focus_y = 8-((bank[i].focus_pad-1)%4)
                g:led(selected[i].x, selected[i].y, led_maps["square_dim"][edition])
                g:led(focus_x, focus_y, led_maps["square_selected"][edition])
                if bank[i][bank[i].focus_pad].pause == true then
                  g:led(3+(5*(i-1)),1,led_maps["square_selected"][edition])
                  g:led(3+(5*(i-1)),2,led_maps["square_selected"][edition])
                else
                  g:led(3+(5*(i-1)),1,led_maps["square_off"][edition])
                  g:led(3+(5*(i-1)),2,led_maps["square_off"][edition])
                end
              end
            end
          end
          
          for i = 1,3 do
            if not rytm.grid.ui[i] then
              if bank[i].focus_hold then
                g:led(4+(5*(i-1)),4,(10*(bank[i][bank[i].focus_pad].send_pad_note and 1 or 0))+5)
              end
            end
            local alt = bank[i].alt_lock and 1 or 0
            g:led(5*i,5,15*alt)
          end
          
          for i,e in pairs(lit) do
            if not rytm.grid.ui[e.id] then
              g:led(e.x, e.y,led_maps["zilchmo_on"][edition])
            end
          end
          
          g:led(16,8,(grid_alt and led_maps["alt_on"][edition] or led_maps["alt_off"][edition]))
          
          for i = 1,3 do
            if not rytm.grid.ui[i] then
            
              local focused = bank[i].focus_hold == false and bank[i][bank[i].id] or bank[i][bank[i].focus_pad]

              g:led(1 + (5*(i-1)), math.abs(focused.clip-5),led_maps["clip"][edition])
              g:led(2 + (5*(i-1)), math.abs(focused.mode-5),led_maps["mode"][edition])
              g:led(1+(5*(i-1)),1,bank[i].focus_hold == false and led_maps["off"][edition] or led_maps["focus_on"][edition])
              if focused.loop == false then
                g:led(3+(5*(i-1)),4,led_maps["loop_off"][edition])
              elseif focused.loop == true then
                g:led(3+(5*(i-1)),4,led_maps["loop_on"][edition])
              end

              if params:string("arp_"..i.."_hold_style") ~= "sequencer" then
                local arp_button = 3+(5*(i-1))
                local arp_writer = 4+(5*(i-1))
                if arp[i].enabled and tab.count(arp[i].notes) == 0 then
                  g:led(arp_button,3,led_maps["arp_on"][edition])
                elseif arp[i].playing then
                  if arp[i].hold then
                    g:led(arp_button,3,led_maps["arp_play"][edition])
                  else
                    if not arp[i].pause then
                      g:led(arp_button,3,led_maps["arp_pause"][edition]) -- i know, i know...
                    end
                  end
                  if arp[i].enabled then
                    g:led(arp_writer,4,led_maps["arp_play"][edition])
                  else
                    g:led(arp_writer,4,led_maps["arp_on"][edition])
                  end
                else
                  if arp[i].hold then
                    -- g:led(arp_button,3,led_maps["arp_pause"][edition])
                  end
                  if tab.count(arp[i].notes) > 0 then
                    g:led(arp_button,3,led_maps["arp_pause"][edition])
                  end
                end
              else
                local arp_button = 3+(5*(i-1))
                local arp_writer = 4+(5*(i-1))
                if arp[i].playing then
                  g:led(arp_button,3,led_maps["arp_play"][edition])
                  if arp[i].enabled then
                    g:led(arp_writer,4,led_maps["arp_play"][edition])
                  else
                    g:led(arp_writer,4,led_maps["arp_on"][edition])
                  end
                else
                  g:led(arp_button,3,led_maps["off"][edition])
                  if tab.count(arp[i].notes) > 0 then
                    g:led(arp_button,3,led_maps["arp_pause"][edition])
                  end
                end
              end

            end
          end
          
          if rec[rec.focus].clear == 0 then
            g:led(16,8-rec.focus,rec[rec.focus].state == 1 and led_maps["live_rec"][edition] or (rec[rec.focus].queued and 15 or led_maps["live_pause"][edition]))
          elseif rec[rec.focus].clear == 1 then
            g:led(16,8-rec.focus,rec[rec.focus].queued and 9 or led_maps["live_empty"][edition])
          end

          --euclid draw

          local function get_xpos(i,p)
            return p+(5*(i-1))
          end
          for i = 1,3 do
            if rytm.grid.ui[i] then
              for j = 1,8 do
                if rytm.track[i].n >= j then
                  g:led(get_xpos(i,1),9-j,rytm.track[i].s[j]
                  and (rytm.track[i].pos == j and 15 or 8)
                  or (rytm.track[i].pos == j and 5 or 3))
                end
              end
              for j = 9,16 do
                if rytm.track[i].n >= j then
                  g:led(get_xpos(i,2),17-j,rytm.track[i].s[j]
                  and (rytm.track[i].pos == j and 15 or 8)
                  or (rytm.track[i].pos == j and 5 or 3))
                end
              end
              local which_param = {"k","n","rotation"}
              local r_p = rytm.grid.page[i]
              for j = 1,8 do
                if rytm.track[i][which_param[r_p]] >= j then
                  g:led(get_xpos(i,3),9-j,5)
                end
              end
              for j = 9,16 do
                if rytm.track[i][which_param[r_p]] >= j then
                  g:led(get_xpos(i,4),17-j,5)
                end
              end
              for j = 1,3 do
                if rytm.grid.page[i] == j then
                  g:led(get_xpos(i,5),4-j,12)
                else
                  g:led(get_xpos(i,5),4-j,4)
                end
              end
              g:led(get_xpos(i,5),8,8)
            end
          end

          for i = 1,3 do
            g:led(5+(5*(i-1)),8,pattern_gate[i][1].active == true and 8 or 0)
            g:led(5+(5*(i-1)),7,pattern_gate[i][2].active == true and 8 or 0)
            g:led(5+(5*(i-1)),6,pattern_gate[i][3].active == true and 8 or 0)
          end
        
        elseif grid_page == 1 then
          
          -- if we're on page 2...

          _ps.draw_grid()
          g:led(16,8,grid_alt and led_maps["alt_on"][edition] or led_maps["alt_off"][edition])
          
          -- for i = 1,3 do

          --   for j = step_seq[i].start_point,step_seq[i].end_point do
          --     local xval = j < 9 and (i*5)-2 or (i*5)-1
          --     local yval = j < 9 and 9 or 17

          --     g:led(xval,yval-j,led_maps["step_no_data"][edition])

          --     if grid_loop_mod == 1 then
          --       g:led(xval,yval-step_seq[i].start_point,led_maps["step_loops"][edition])
          --       g:led(xval,yval-step_seq[i].end_point,led_maps["step_loops"][edition])
          --     end

          --   end

          --   for j = 1,16 do
          --     if step_seq[i][j].assigned_to ~= 0 then
          --       local xval = j < 9 and (i*5)-2 or (i*5)-1
          --       local yval = j < 9 and 9 or 17
          --       g:led(xval,yval-j,led_maps["step_yes_data"][edition])
          --     end
          --   end

          --   if step_seq[i].current_step < 9 then
          --     g:led((i*5)-2,9-step_seq[i].current_step,led_maps["step_current"][edition])
          --   elseif step_seq[i].current_step >=9 then
          --     g:led((i*5)-1,9-(step_seq[i].current_step-8),led_maps["step_current"][edition])
          --   end

          --   if step_seq[i].held < 9 then
          --     g:led((i*5)-2,9-step_seq[i].held,led_maps["step_held"][edition])
          --   elseif step_seq[i].held >= 9 then
          --     g:led((i*5)-1,9-(step_seq[i].held-8),led_maps["step_held"][edition])
          --   end

          --   g:led((i*5)-3, 9-step_seq[i].meta_duration,led_maps["meta_duration"][edition])
          --   g:led((i*5)-3, 9-step_seq[i].meta_step,led_maps["meta_step_hi"][edition])

          --   if step_seq[i].held == 0 then
          --     g:led((i*5), 9-step_seq[i][step_seq[i].current_step].meta_meta_duration,led_maps["meta_duration"][edition])
          --     g:led((i*5), 9-step_seq[i].meta_meta_step,led_maps["meta_step_hi"][edition])
          --   else
          --     g:led((i*5), 9-step_seq[i].meta_meta_step,led_maps["meta_step_lo"][edition])
          --     g:led((i*5), 9-step_seq[i][step_seq[i].held].meta_meta_duration,led_maps["meta_duration"][edition])
          --   end
          --   if step_seq[i].held == 0 then
          --     g:led(16,8-i,edition == 3 and (15*step_seq[i].active) or ((step_seq[i].active*6)+2))
          --   else
          --     g:led(16,8-i,step_seq[i][step_seq[i].held].loop_pattern*4)
          --   end

          -- end
          
          -- for i = 1,11,5 do
          --   for j = 1,8 do
          --     local current = math.floor(i/5)+1
          --     local show = step_seq[current].held == 0 and pattern_saver[current].load_slot or step_seq[current][step_seq[current].held].assigned_to
          --     g:led(i,j,edition == 3 and (15*pattern_saver[current].saved[9-j]) or ((5*pattern_saver[current].saved[9-j])+2))
          --     g:led(i,j,j == (9 - show) and 15 or (edition == 3 and (15*pattern_saver[current].saved[9-j]) or ((5*pattern_saver[current].saved[9-j])+2)))
          --   end
          -- end
        
          -- g:led(16,2,grid_loop_mod == 1 and led_maps["loop_mod_hi"][edition] or led_maps["loop_mod_lo"][edition])
        
        elseif grid_page == 2 then
          -- delay page!
          for i = 1,8 do
            local check = {i+8, i}
            for j = 1,2 do
              g:led(i,j,delay[2].selected_bundle == check[j] and 15 or (delay_bundle[2][check[j]].saved == true and led_maps["bundle_saved"][edition] or led_maps["bundle_empty"][edition]))
              g:led(i,j+6,delay[1].selected_bundle == check[j] and 15 or (delay_bundle[1][check[j]].saved == true and led_maps["bundle_saved"][edition] or led_maps["bundle_empty"][edition]))
            end
          end

          -- delay time modifiers
          local time_to_led = {{},{},{},{}}
          local time = {delay[1].modifier, delay[2].modifier}
          for i = 1,2 do
            time_to_led[i] = 0
            time_to_led[i+2] = 0
            if time[i] == 0.5 then
              time_to_led[i+2] = led_maps["time_to_led.5"][edition]
            elseif time[i] == 0.25 then
              time_to_led[i+2] = led_maps["time_to_led.25"][edition]
            elseif time[i] == 0.125 then
              time_to_led[i+2] = led_maps["time_to_led.125"][edition]
            elseif time[i] == 2 then
              time_to_led[i] = led_maps["time_to_led2"][edition]
            elseif time[i] == 4 then
              time_to_led[i] = led_maps["time_to_led4"][edition]
            elseif time[i] == 8 then
              time_to_led[i] = led_maps["time_to_led8"][edition]
            elseif time[i] == 16 then
              time_to_led[i] = led_maps["time_to_led16"][edition]
            end
          end
          g:led(1,3,time_to_led[2])
          g:led(2,3,time_to_led[4])
          g:led(1,6,time_to_led[1])
          g:led(2,6,time_to_led[3])
          g:led(3,3,delay[2].reverse and led_maps["reverse_on"][edition] or led_maps["reverse_off"][edition])
          g:led(3,6,delay[1].reverse and led_maps["reverse_on"][edition] or led_maps["reverse_off"][edition])

          rate_to_led = {{},{},{},{}}
          local rate = {params:get("delay L: rate"), params:get("delay R: rate")}
          for i = 1,2 do
            rate_to_led[i] = 0
            rate_to_led[i+2] = 0
            for j = 1,24 do
              if math.modf(rate[i]) >= j then
                rate_to_led[i] = math.modf(util.linlin(0,24,3,15,j))
              end
            end
            for j = 0.25,1,0.05 do
              if rate[i] >= j then
                rate_to_led[i+2] = math.modf(util.linlin(0.25,1,15,0,j))
              end
            end
            if rate[i] == 1 then
              rate_to_led[i+2] = 3
            end
          end
          g:led(1,4,rate_to_led[2])
          g:led(2,4,rate_to_led[4])
          g:led(3,4,delay[2].wobble_hold and led_maps["wobble_on"][edition] or led_maps["wobble_off"][edition])
          g:led(1,5,rate_to_led[1])
          g:led(2,5,rate_to_led[3])
          g:led(3,5,delay[1].wobble_hold and led_maps["wobble_on"][edition] or led_maps["wobble_off"][edition])
          
          -- delay levels
          local level_to_led = {{},{}}
          local delay_level = {params:get("delay L: global level"), params:get("delay R: global level")}
          for i = 1,2 do
            if delay_level[i] <= 0.125 then
              level_to_led[i] = 0
            elseif delay_level[i] <= 0.375 then
              level_to_led[i] = 1
            elseif delay_level[i] <= 0.625 then
              level_to_led[i] = 2
            elseif delay_level[i] <= 0.875 then
              level_to_led[i] = 3
            elseif delay_level[i] <= 1 then
              level_to_led[i] = 4
            end
          end
          for i = 8,4,-1 do
            g:led(i,6,led_maps["level_lo"][edition])
            g:led(i,3,led_maps["level_lo"][edition])
          end
          for i = 1,2 do
            if not delay[i].level_mute then
              for j = 8,4+(4-level_to_led[i]),-1 do
                g:led(j,i==1 and 6 or 3,led_maps["level_hi"][edition])
              end
            else
              if params:get(i == 1 and "delay L: global level" or "delay R: global level") == 0 then
                for j = 8,4,-1 do
                  g:led(j,i==1 and 6 or 3,led_maps["level_hi"][edition])
                end
              end
            end
          end

          -- feedback levels
          local feed_to_led = {{},{}}
          local feedback_level = {params:get("delay L: feedback"), params:get("delay R: feedback")}
          for i = 1,2 do
            if feedback_level[i] <= 12.5 then
              feed_to_led[i] = 0
            elseif feedback_level[i] <= 37.5 then
              feed_to_led[i] = 1
            elseif feedback_level[i] <= 62.5 then
              feed_to_led[i] = 2
            elseif feedback_level[i] <= 87.5 then
              feed_to_led[i] = 3
            elseif feedback_level[i] <= 100 then
              feed_to_led[i] = 4
            end
          end
          for i = 8,4,-1 do
            g:led(i,5,led_maps["level_lo"][edition])
            g:led(i,4,led_maps["level_lo"][edition])
          end
          for i = 1,2 do
            if not delay[i].feedback_mute then
              for j = 8,4+(4-feed_to_led[i]),-1 do
                g:led(j,i==1 and 5 or 4,led_maps["level_hi"][edition])
              end
            else
              if params:get(i == 1 and "delay L: feedback" or "delay R: feedback") == 0 then
                for j = 8,4,-1 do
                  g:led(j,i==1 and 5 or 4,led_maps["level_hi"][edition])
                end
              end
            end
          end

          for k = 10,13 do
            for i = 6,3,-1 do
              g:led(k,i,led_maps["square_off"][edition])
            end
          end

          local shifted_x = (selected[delay_grid.bank].x - (5*(delay_grid.bank-1)))+9
          local shifted_y = selected[delay_grid.bank].y - 2
          g:led(shifted_x, shifted_y, led_maps["square_selected"][edition])

          for i = 4,6 do
            g:led(14,i,delay_grid.bank == 7-i and led_maps["selected_bank"][edition] or led_maps["unselected_bank"][edition])
          end

          -- send levels

          local send_to_led = {{},{}}
          local send_level = {bank[delay_grid.bank][bank[delay_grid.bank].id].left_delay_level, bank[delay_grid.bank][bank[delay_grid.bank].id].right_delay_level}
          for i = 1,2 do
            if send_level[i] <= 0.125 then
              send_to_led[i] = 0
            elseif send_level[i] <= 0.375 then
              send_to_led[i] = 1
            elseif send_level[i] <= 0.625 then
              send_to_led[i] = 2
            elseif send_level[i] <= 0.875 then
              send_to_led[i] = 3
            elseif send_level[i] <= 1.0 then
              send_to_led[i] = 4
            end
          end

          for i = 1,2 do
            if not delay[i].send_mute then
              for j = 14,10+(4-send_to_led[i]),-1 do
                g:led(j,i==1 and 8 or 1,led_maps["level_hi"][edition])
              end
            else
              if (i == 1 and bank[delay_grid.bank][bank[delay_grid.bank].id].left_delay_level or bank[delay_grid.bank][bank[delay_grid.bank].id].right_delay_level) == 0 then
                for j = 14,10,-1 do
                  g:led(j,i==1 and 8 or 1,led_maps["level_hi"][edition])
                end
              end
            end
          end

          --arp button
          if params:string("arp_"..delay_grid.bank.."_hold_style") ~= "sequencer" then
            if not arp[delay_grid.bank].enabled then
              g:led(12,2,led_maps["off"][edition])
            else
              if arp[delay_grid.bank].playing and arp[delay_grid.bank].hold then
                g:led(12,2,led_maps["arp_play"][edition])
              elseif arp[delay_grid.bank].hold then
                g:led(12,2,led_maps["arp_pause"][edition])
              else
                g:led(12,2,led_maps["arp_on"][edition])
              end
            end
          else
            if arp[delay_grid.bank].playing then
              g:led(12,2,led_maps["arp_play"][edition])
            else
              g:led(12,2,led_maps["off"][edition])
            end
          end

          if bank[delay_grid.bank][bank[delay_grid.bank].id].loop == false then
            g:led(13,2,led_maps["loop_off"][edition])
          else
            g:led(13,2,led_maps["loop_on"][edition])
          end



          g:led(16,8,(grid_alt and led_maps["alt_on"][edition] or led_maps["alt_off"][edition]))

          for j = 1,4 do
            g:led(15,math.abs(j-7),zilch_leds[4][delay_grid.bank][j] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
          end
        end
        if grid_page ~= nil and grid_page ~= "speed_dial" then
          if grid_page ~= 2 then
            g:led(16,1,led_maps["page_led"][grid_page+1][edition])
          elseif grid_page == 2 then
            g:led(16,2,led_maps["page_led"][grid_page+1][edition])
          end
        end
      else
        speed_dial.draw_grid()
      end

      
      
      g:refresh()

    --64 grid / grid 64
    elseif params:string("grid_size") == "64" then
      g:all(0)
      local edition = params:get("LED_style")

      g:led(8,1,led_maps["square_off"][edition])
      
      if grid_page_64 == 0 then

        for x = 1,3 do
          g:led(x,1,x == bank_64 and 12 or 4)
        end

        --arc recorders
        local a_p; -- this will index the arc encoder recorders
        if arc_param[bank_64] == 1 or arc_param[bank_64] == 2 or arc_param[bank_64] == 3 then
          a_p = 1
        else
          a_p = arc_param[bank_64] - 2
        end
        if arc_pat[bank_64][a_p].rec == 1 then
          g:led(8,3,led_maps["arc_rec_rec"][edition])
        elseif arc_pat[bank_64][a_p].play == 1 then
          g:led(8,3,led_maps["arc_rec_play"][edition])
        elseif arc_pat[bank_64][a_p].count > 0 then
          g:led(8,3,led_maps["arc_rec_pause"][edition])
        else
          g:led(8,3,led_maps["arc_rec_off"][edition])
        end
        
        --main playable grid
        for x = 1,4 do
          for y = 4,7 do
            if not rytm.grid.ui[bank_64] then
              g:led(x,y,led_maps["square_off"][edition])
            end
          end
        end

        --zilchmos
        for x = 5,8 do
          if not rytm.grid.ui[bank_64] then
            g:led(x,8,zilch_leds[4][bank_64][x-4] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
          end
        end

        for x = 6,8 do
          if not rytm.grid.ui[bank_64] then
            g:led(x,7,zilch_leds[3][bank_64][x-5] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
          end
        end

        --pattern rec
        local target = grid_pat[bank_64]
        if not rytm.grid.ui[bank_64] then
          if target.rec == 1 then
            g:led(8,5,(9*target.led))
          elseif (target.quantize == 0 and target.play == 1) or (target.quantize == 1 and target.tightened_start == 1) then
            if target.overdub == 0 then
              g:led(8,5,9)
            else
              g:led(8,5,15)
            end
          elseif target.count > 0 then
            g:led(8,5,5)
          else
            g:led(8,5,3)
          end
        end
        
        --arc rec
        -- local a_p; -- this will index the arc encoder recorders
        -- if arc_param[bank_64] == 1 or arc_param[bank_64] == 2 or arc_param[bank_64] == 3 then
        --   a_p = 1
        -- else
        --   a_p = arc_param[bank_64] - 2
        -- end
        -- if arc_pat[bank_64][a_p].rec == 1 then
        --   g:led(7,8,led_maps["arc_rec_rec"][edition])
        -- elseif arc_pat[bank_64][a_p].play == 1 then
        --   g:led(7,8,led_maps["arc_rec_play"][edition])
        -- elseif arc_pat[bank_64][a_p].count > 0 then
        --   g:led(7,8,led_maps["arc_rec_pause"][edition])
        -- else
        --   g:led(7,8,led_maps["arc_rec_off"][edition])
        -- end
        
        -- arc control
        if a.device ~= nil then
          g:led(6,2,arc_param[bank_64] == 1 and led_maps["arc_param_show"][edition] or 0)
          g:led(7,2,arc_param[bank_64] == 2 and led_maps["arc_param_show"][edition] or 0)
          g:led(8,2,arc_param[bank_64] == 3 and led_maps["arc_param_show"][edition] or 0)
          if arc_param[bank_64] == 4 then
            for x = 6,8 do
              g:led(x,2,led_maps["arc_param_show"][edition])
            end
          elseif arc_param[bank_64] == 5 then
            g:led(6,2,led_maps["arc_param_show"][edition])
            g:led(7,2,led_maps["arc_param_show"][edition])
          elseif arc_param[bank_64] == 6 then
            g:led(7,2,led_maps["arc_param_show"][edition])
            g:led(8,2,led_maps["arc_param_show"][edition])
          end
        end
        
        --4x4 pads
        if not rytm.grid.ui[bank_64] then
          if bank[bank_64].focus_hold == false then
            local x_64 = (9-selected[bank_64].y)
            local y_64 = selected[bank_64].x - (5*(bank_64-1))
            g:led(x_64, y_64+3, led_maps["square_selected"][edition])
            if bank[bank_64][bank[bank_64].id].pause == true then
              g:led(8,6,led_maps["pad_pause"][edition])
              g:led(7,6,led_maps["pad_pause"][edition])
            else
              g:led(7,6,zilch_leds[2][bank_64][1] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
              g:led(8,6,zilch_leds[2][bank_64][2] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
            end
          else
            local x_64 = (9-selected[bank_64].y)
            local y_64 = selected[bank_64].x - (5*(bank_64-1))
            local focus_x_64 = bank[bank_64].focus_pad - (4*(math.ceil(bank[bank_64].focus_pad/4)-1))
            local focus_y_64 = math.ceil(bank[bank_64].focus_pad/4)
            g:led(x_64, y_64+3, led_maps["square_dim"][edition])
            g:led(focus_x_64, focus_y_64+3, led_maps["square_selected"][edition])
            if bank[bank_64][bank[bank_64].focus_pad].pause == true then
              g:led(8,6,led_maps["square_selected"][edition])
              g:led(7,6,led_maps["square_selected"][edition])
            else
              g:led(7,6,led_maps["square_off"][edition])
              g:led(8,6,led_maps["square_off"][edition])
            end
          end
        end
        
        -- crow pad execute
        if not rytm.grid.ui[bank_64] then
          if bank[bank_64].focus_hold then
            g:led(5,7,(10*(bank[bank_64][bank[bank_64].focus_pad].send_pad_note and 1 or 0))+5)
          end
        end
        local alt = bank[bank_64].alt_lock and 1 or 0
        g:led(4,8,15*alt)
        
        -- for i,e in pairs(lit) do
        --   g:led(e.x, e.y,led_maps["zilchmo_on"][edition])
        -- end
        
        --alt
        g:led(1,8,(grid_alt and led_maps["alt_on"][edition] or led_maps["alt_off"][edition]))
          
        
        if not rytm.grid.ui[bank_64] then
          local focused = bank[bank_64].focus_hold == false and bank[bank_64][bank[bank_64].id] or bank[bank_64][bank[bank_64].focus_pad]
          --clips + stuff
          g:led(focused.clip+4,4,led_maps["clip"][edition])
          g:led(focused.mode+4,5,led_maps["mode"][edition])
          g:led(8,4,bank[bank_64].focus_hold == false and led_maps["off"][edition] or led_maps["focus_on"][edition])
          if focused.loop == false then
            g:led(5,6,led_maps["loop_off"][edition])
          elseif focused.loop == true then
            g:led(5,6,led_maps["loop_on"][edition])
          end
          
          --arps
          if params:string("arp_"..bank_64.."_hold_style") ~= "sequencer" then
            if not arp[bank_64].enabled then
              g:led(6,6,led_maps["off"][edition])
            else
              if arp[bank_64].playing and arp[bank_64].hold then
                g:led(6,6,led_maps["arp_play"][edition])
              elseif arp[bank_64].hold then
                g:led(6,6,led_maps["arp_pause"][edition])
              else
                g:led(6,6,led_maps["arp_on"][edition])
              end
            end
          else
            if arp[bank_64].playing then
              g:led(6,6,led_maps["arp_play"][edition])
              if arp[bank_64].enabled then
                g:led(3,8,led_maps["arp_play"][edition])
              else
                g:led(3,8,led_maps["arp_on"][edition])
              end
            else
              g:led(6,6,led_maps["off"][edition])
              if tab.count(arp[bank_64].notes) > 0 then
                g:led(3,8,led_maps["arp_pause"][edition])
              end
            end
          end
        end
        -- Live buffers
        
        -- if rec[rec.focus].clear == 0 then
        --   g:led(rec.focus,2,rec[rec.focus].state == 1 and led_maps["live_rec"][edition] or (rec[rec.focus].queued and 15 or led_maps["live_pause"][edition]))
        -- elseif rec[rec.focus].clear == 1 then
        --   g:led(rec.focus,2,rec[rec.focus].queued and 9 or led_maps["live_empty"][edition])
        -- end
        for i = 1,3 do
          if rec[rec.focus].clear == 0 then
            g:led(rec.focus,2,rec[rec.focus].state == 1 and led_maps["live_rec"][edition] or (rec[rec.focus].queued and 15 or led_maps["live_pause"][edition]))
          elseif rec[rec.focus].clear == 1 then
            g:led(rec.focus,2,rec[rec.focus].queued and 9 or led_maps["live_empty"][edition])
          end
          g:led(i,3,(params:get("SOS_enabled_"..i) == 1 and led_maps["live_rec"][edition] or 0))
        end
        
        --euclid!!

        if rytm.grid.ui[bank_64] then
          for j = 1,8 do
            if rytm.track[bank_64].n >= j then
              g:led(j,4,rytm.track[bank_64].s[j]
              and (rytm.track[bank_64].pos == j and led_maps["rytm_current_step_active"][edition] or led_maps["rytm_current_step_inactive"][edition])
              or (rytm.track[bank_64].pos == j and led_maps["rytm_step_active"][edition] or led_maps["rytm_step_inactive"][edition]))
            end
          end
          for j = 9,16 do
            if rytm.track[bank_64].n >= j then
              g:led(j-8,5,rytm.track[bank_64].s[j]
              and (rytm.track[bank_64].pos == j and led_maps["rytm_current_step_active"][edition] or led_maps["rytm_current_step_inactive"][edition])
              or (rytm.track[bank_64].pos == j and led_maps["rytm_step_active"][edition] or led_maps["rytm_step_inactive"][edition]))
            end
          end
          local which_param = {"k","n","rotation"}
          local r_p = rytm.grid.page[bank_64]
          for j = 1,8 do
            if rytm.track[bank_64][which_param[r_p]] >= j then
              g:led(j,6,5)
            end
          end
          for j = 9,16 do
            if rytm.track[bank_64][which_param[r_p]] >= j then
              g:led(j-8,7,5)
            end
          end
          for j = 1,3 do
            if rytm.grid.page[bank_64] == j then
              g:led(j+5,8,12)
            else
              g:led(j+5,8,4)
            end
          end
          g:led(8,2,8)
        end

        g:led(2,8,pattern_gate[bank_64][2].active == true and 8 or 0)
        g:led(3,8,pattern_gate[bank_64][3].active == true and 8 or 0)
      
      elseif grid_page_64 == 2 then

        -- delay page!
        for i = 1,5 do
          g:led(8,i+2,delay[2].selected_bundle == i and 15 or (delay_bundle[2][i].saved == true and led_maps["bundle_saved"][edition] or 0))
          g:led(1,i+2,delay[1].selected_bundle == i and 15 or (delay_bundle[1][i].saved == true and led_maps["bundle_saved"][edition] or 0))
        end

        for i = 1,3 do
          g:led(2,i,bank[i][bank[i].id].left_delay_level > 0 and led_maps["64_bank_send"][edition] or 0)
          g:led(7,i,bank[i][bank[i].id].right_delay_level > 0 and led_maps["64_bank_send"][edition] or 0)
        end

        g:led(2,4,params:get("delay L: external input") > 0 and led_maps["64_bank_send"][edition] or 0)
        g:led(7,4,params:get("delay R: external input") > 0 and led_maps["64_bank_send"][edition] or 0)

        -- delay time modifiers
        local time_to_led = {{},{},{},{}}
        local time = {delay[1].modifier, delay[2].modifier}
        for i = 1,2 do
          time_to_led[i] = 0
          time_to_led[i+2] = 0
          if time[i] == 0.5 then
            time_to_led[i+2] = led_maps["time_to_led.5"][edition]
          elseif time[i] == 0.25 then
            time_to_led[i+2] = led_maps["time_to_led.25"][edition]
          elseif time[i] == 0.125 then
            time_to_led[i+2] = led_maps["time_to_led.125"][edition]
          elseif time[i] == 2 then
            time_to_led[i] = led_maps["time_to_led2"][edition]
          elseif time[i] == 4 then
            time_to_led[i] = led_maps["time_to_led4"][edition]
          elseif time[i] == 8 then
            time_to_led[i] = led_maps["time_to_led8"][edition]
          elseif time[i] == 16 then
            time_to_led[i] = led_maps["time_to_led16"][edition]
          end
        end
        g:led(6,1,time_to_led[2])
        g:led(6,2,time_to_led[4])
        g:led(3,1,time_to_led[1])
        g:led(3,2,time_to_led[3])
        g:led(6,3,delay[2].reverse and led_maps["reverse_on"][edition] or led_maps["reverse_off"][edition])
        g:led(3,3,delay[1].reverse and led_maps["reverse_on"][edition] or led_maps["reverse_off"][edition])

        rate_to_led = {{},{},{},{}}
        local rate = {params:get("delay L: rate"), params:get("delay R: rate")}
        for i = 1,2 do
          rate_to_led[i] = 0
          rate_to_led[i+2] = 0
          for j = 1,24 do
            if math.modf(rate[i]) >= j then
              rate_to_led[i] = math.modf(util.linlin(0,24,3,15,j))
            end
          end
          for j = 0.25,1,0.05 do
            if rate[i] >= j then
              rate_to_led[i+2] = math.modf(util.linlin(0.25,1,15,0,j))
            end
          end
          if rate[i] == 1 then
            rate_to_led[i+2] = 3
          end
        end
        g:led(5,1,rate_to_led[2])
        g:led(5,2,rate_to_led[4])
        g:led(5,3,delay[2].wobble_hold and led_maps["wobble_on"][edition] or led_maps["wobble_off"][edition])
        g:led(4,1,rate_to_led[1])
        g:led(4,2,rate_to_led[3])
        g:led(4,3,delay[1].wobble_hold and led_maps["wobble_on"][edition] or led_maps["wobble_off"][edition])
        
        -- delay levels
        local level_to_led = {{},{}}
        local delay_level = {params:get("delay L: global level"), params:get("delay R: global level")}
        for i = 1,2 do
          if delay_level[i] <= 0.125 then
            level_to_led[i] = 0
          elseif delay_level[i] <= 0.375 then
            level_to_led[i] = 1
          elseif delay_level[i] <= 0.625 then
            level_to_led[i] = 2
          elseif delay_level[i] <= 0.875 then
            level_to_led[i] = 3
          elseif delay_level[i] <= 1 then
            level_to_led[i] = 4
          end
        end
        for i = 8,4,-1 do
          g:led(3,i,led_maps["level_lo"][edition])
          g:led(6,i,led_maps["level_lo"][edition])
        end
        for i = 1,2 do
          if not delay[i].level_mute then
            for j = 8,4+(4-level_to_led[i]),-1 do
              g:led(i==1 and 3 or 6,j,led_maps["level_hi"][edition])
            end
          else
            if params:get(i == 1 and "delay L: global level" or "delay R: global level") == 0 then
              for j = 8,4,-1 do
                g:led(i==1 and 3 or 6,j,led_maps["level_hi"][edition])
              end
            end
          end
        end

        -- feedback levels
        local feed_to_led = {{},{}}
        local feedback_level = {params:get("delay L: feedback"), params:get("delay R: feedback")}
        for i = 1,2 do
          if feedback_level[i] <= 12.5 then
            feed_to_led[i] = 0
          elseif feedback_level[i] <= 37.5 then
            feed_to_led[i] = 1
          elseif feedback_level[i] <= 62.5 then
            feed_to_led[i] = 2
          elseif feedback_level[i] <= 87.5 then
            feed_to_led[i] = 3
          elseif feedback_level[i] <= 100 then
            feed_to_led[i] = 4
          end
        end
        for i = 8,4,-1 do
          g:led(4,i,led_maps["level_lo"][edition])
          g:led(5,i,led_maps["level_lo"][edition])
        end
        for i = 1,2 do
          if not delay[i].feedback_mute then
            for j = 8,4+(4-feed_to_led[i]),-1 do
              g:led(i==1 and 4 or 5,j,led_maps["level_hi"][edition])
            end
          else
            if params:get(i == 1 and "delay L: feedback" or "delay R: feedback") == 0 then
              for j = 8,4,-1 do
                g:led(i==1 and 4 or 5,j,led_maps["level_hi"][edition])
              end
            end
          end
        end

        g:led(1,8,grid_alt and led_maps["alt_on"][edition] or led_maps["alt_off"][edition])

      elseif grid_page_64 == 1 then

        for x = 1,3 do
          g:led(x,1,x == bank_64 and 12 or 4)
        end
        
        -- if we're on page 3...
      
        local i = bank_64

        for j = step_seq[i].start_point,step_seq[i].end_point do
          local xval = j < 9 and 0 or 8
          local yval = j < 9 and 4 or 5
          g:led(j-xval,yval,led_maps["step_no_data"][edition])

        end

        if grid_loop_mod == 1 then
          local _start = step_seq[i].start_point < 9 and 0 or 8
          local _end = step_seq[i].end_point < 9 and 0 or 8
          local _start_y = _start == 0 and 4 or 5
          local _end_y = _end == 0 and 4 or 5
          g:led(step_seq[i].start_point-_start,_start_y,led_maps["step_loops"][edition])
          g:led(step_seq[i].end_point-_end,_end_y,led_maps["step_loops"][edition])
        end

        for j = 1,16 do
          if step_seq[i][j].assigned_to ~= 0 then
            local xval = j < 9 and 0 or 8
            local yval = j < 9 and 4 or 5
            g:led(j-xval,yval,led_maps["step_yes_data"][edition])
          end
        end

        if step_seq[i].current_step < 9 then
          g:led(step_seq[i].current_step,4,led_maps["step_current"][edition])
        elseif step_seq[i].current_step >=9 then
          g:led(step_seq[i].current_step-8,5,led_maps["step_current"][edition])
        end

        if step_seq[i].held ~= 0 and step_seq[i].held < 9 then
          g:led(step_seq[i].held,4,led_maps["step_held"][edition])
        elseif step_seq[i].held ~= 0 and step_seq[i].held >= 9 then
          g:led(step_seq[i].held-8,5,led_maps["step_held"][edition])
        end

        g:led(step_seq[i].meta_duration,3,led_maps["meta_duration"][edition])
        g:led(step_seq[i].meta_step,3,led_maps["meta_step_hi"][edition])

        if step_seq[i].held == 0 then
          g:led(step_seq[i][step_seq[i].current_step].meta_meta_duration,6,led_maps["meta_duration"][edition])
          g:led(step_seq[i].meta_meta_step,6,led_maps["meta_step_hi"][edition])
        else
          g:led(step_seq[i].meta_meta_step,6,led_maps["meta_step_lo"][edition])
          g:led(step_seq[i][step_seq[i].held].meta_meta_duration,6,led_maps["meta_duration"][edition])
        end
        
        for j = 1,3 do
          if step_seq[j].held == 0 then
            g:led(1+j,8,edition == 3 and (15*step_seq[j].active) or ((step_seq[j].active*6)+2))
          else
            g:led(1+j,8,step_seq[j][step_seq[j].held].loop_pattern*4)
          end
        end
        
        
        for j = 1,8 do
          local current = bank_64
          local show = step_seq[current].held == 0 and pattern_saver[current].load_slot or step_seq[current][step_seq[current].held].assigned_to
          g:led(j,2,edition == 3 and (15*pattern_saver[current].saved[j]) or ((5*pattern_saver[current].saved[j])+2))
          g:led(j,2,j == (show) and 15 or (edition == 3 and (15*pattern_saver[current].saved[j]) or ((5*pattern_saver[current].saved[j])+2)))
        end
        
        g:led(1,8,grid_alt and led_maps["alt_on"][edition] or led_maps["alt_off"][edition])
        g:led(8,8,grid_loop_mod == 1 and led_maps["loop_mod_hi"][edition] or led_maps["loop_mod_lo"][edition])
      
      end
      
      g:refresh()
    end
  end
end

return _gleds