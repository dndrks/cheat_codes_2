local main_menu = {}

local dots = "."

function main_menu.metro_icon(x,y)
  screen.level(transport.is_running and 15 or 3)
  screen.move(x+2,y+5)
  screen.line(x+7,y)
  screen.line(x+12,y+5)
  screen.line(x+3,y+5)
  screen.stroke()
  screen.move(x+7,y+3)
  local pos =
  transport.is_running
  and ((viz_metro_advance == 1 or viz_metro_advance == 3)
  and (x+10)
  or (x+4))
  or (x+4)
  screen.line(pos,y)
  screen.stroke()
  if transport.pending then
    screen.move(x+18,63)
    screen.text_center("...")
  end
end

function main_menu.init()
  if menu == 1 then
    screen.move(0,10)
    screen.text("cheat codes")
    screen.move(10,30)
    if not key1_hold then
      for i = 1,10 do
        screen.level(page.main_sel == i and 15 or 3)
        if i < 4 then
          screen.move(5,20+(10*i))
        elseif i < 7 then
          screen.move(50,10*(i-1))
        elseif i < 10 then
          screen.move(95,30+(10*(i-7)))
        elseif i == 10 then
          screen.move(115,64)
        end
        local options =
        { " loops"
        , " levels"
        , " pans"
        , " filters"
        , " delays"
        , " timing"
        , " euclid"
        , " arp"
        , " rnd"
        , " "
        }
        screen.text(page.main_sel == i and (">"..options[i]) or options[i])
        main_menu.metro_icon(0,58)
      end
      screen.move(128,selected_coll ~= 0 and 20 or 10)
      screen.level(3)
      local target = midi_dev[params:get("midi_control_device")]
      if target.device ~= nil and target.device.port == params:get("midi_control_device") and params:get("midi_control_enabled") == 2 then
        screen.text_right("("..util.trim_string_to_width(target.device.name,70)..")")
      elseif target.device == nil and params:get("midi_control_enabled") == 2 then
        screen.text_right("(no midi device!)")
      end
      if mft_connected ~= nil and mft_connected then
        screen.move(128,60)
        screen.level(3)
        screen.text_right("(MFT)")
      end
      if ec4_connected ~= nil and ec4_connected then
        screen.move(128,60)
        screen.level(3)
        screen.text_right("(EC4)")
      end
      if selected_coll ~= 0 then
        screen.move(128,10)
        screen.level(3)
        screen.text_right("["..util.trim_string_to_width(selected_coll,68).."]")
      end
    else
      screen.move(60,35)
      screen.text_center("+K2: MACRO CONFIG")
      screen.move(60,45)
      screen.text_center("+K3: OUTGOING MIDI CONFIG")
    end
  elseif menu == 2 then
    screen.move(0,10)
    screen.level(3)
    screen.text("loops")
    if params:get("visual_metro") == 1 then
      metronome(28,10,15,3)
    end

    local screen_levels =
    {
      page.loops.frame == 2 and 15 or 3
    , page.loops.frame == 2 and 4 or 1
    , page.loops.frame == 2 and 10 or 2
    , page.loops.frame == 2 and 3 or 15
    }

    if page.loops.frame == 1 or (page.loops.frame == 2 and page.loops.sel == 5) then
    
      if page.loops.frame == 2 and page.loops.sel == 5 and key1_hold then
        screen.move(128,10)
        screen.level(15)
        screen.text_right("E1: pad, E2+E3: fine")
      elseif page.loops.frame == 2 and page.loops.sel == 5 and key2_hold then
        screen.move(128,10)
        screen.level(15)
        if page.loops.meta_sel < 4 then
          screen.text_right("E1: <->, K3: chop")
        elseif page.loops.meta_sel == 4 then
          screen.text_right("E1: <->, K3: rec "..(rec[rec.focus].state == 0 and "on" or "off"))
        end
      else
        local header = {"a","b","c","L","#"}
        for i = 1,#header do
          screen.level(page.loops.sel == i and screen_levels[4] or 3)
          screen.move(50+(i*15),10)
          screen.text_right(header[i])
        end
        screen.level(page.loops.sel == page.loops.sel and screen_levels[4] or 3)
        screen.move(50+(page.loops.sel*15),13)
        screen.text_right("_")
      end
    
    elseif page.loops.frame == 2 then

      screen.move(128,10)

      if page.loops.sel < 4 then
        local pad;
        if bank[page.loops.sel].focus_hold then
          pad = bank[page.loops.sel][bank[page.loops.sel].focus_pad]
        elseif grid_pat[page.loops.sel].play == 0 and midi_pat[page.loops.sel].play == 0 and not arp[page.loops.sel].playing and rytm.track[page.loops.sel].k == 0 then
          pad = bank[page.loops.sel][bank[page.loops.sel].id]
        else
          pad = bank[page.loops.sel][bank[page.loops.sel].focus_pad]
        end
        -- local pad = bank[page.loops.sel].focus_hold and bank[page.loops.sel][bank[page.loops.sel].focus_pad] or bank[page.loops.sel][bank[page.loops.sel].id]
        local off = pad.mode == 1 and (((pad.clip-1)*8)+1) or clip[pad.clip].min
        local rs = {1,2,4}
        local rate_mod = rs[params:get("live_buff_rate")]
        local display_start = pad.mode == 1 and ((util.round(pad.start_point,0.0001)-off)*rate_mod) or ((util.round(pad.start_point,0.0001))-off)
        local display_end = pad.mode == 1 and (((pad.end_point == 8.99 and 9 or pad.end_point)-off) * rate_mod) or (pad.end_point-off)
        screen.text_right("s: "..string.format("%.4g",display_start).."s | e: "..string.format("%.4g",display_end).."s")
      elseif page.loops.sel == 4 then
        local off = ((rec.focus-1)*8)+1
        local mults = {1,2,4}
        local mult = mults[params:get("live_buff_rate")]
        local display_live_start = string.format("%.4g",(util.round(rec[rec.focus].start_point,0.0001)-off)*mult)
        local display_live_end = string.format("%.4g",(rec[rec.focus].end_point-off)*mult)
        -- screen.text_right("s: "..display_live_start.."s | e: "..display_live_end.."s")
        if params:get("rec_loop_enc_resolution") <= 2 then
          screen.text_right("s: "..display_live_start.."s | e: "..display_live_end.."s")
        else
          screen.text_right("duration: "..util.round((display_live_end - display_live_start)/clock.get_beat_sec(),0.01).." beats" )
        end
      end
    end

    -- waveform testing
    if page.loops.sel < 4 then

      local pad;
      if bank[page.loops.sel].focus_hold then
        pad = bank[page.loops.sel][bank[page.loops.sel].focus_pad]
      elseif page.loops.frame == 1 then
        pad = bank[page.loops.sel][bank[page.loops.sel].id]
      elseif page.loops.frame == 2 then
        if grid_pat[page.loops.sel].play == 0 and midi_pat[page.loops.sel].play == 0 and not arp[page.loops.sel].playing and rytm.track[page.loops.sel].k == 0 then
          pad = bank[page.loops.sel][bank[page.loops.sel].id]
        else
          pad = bank[page.loops.sel][bank[page.loops.sel].focus_pad]
        end
      end

      -- elseif grid_pat[page.loops.sel].play == 0 and midi_pat[page.loops.sel].play == 0 and not arp[page.loops.sel].playing and rytm.track[page.loops.sel].k == 0 then
      --   pad = bank[page.loops.sel][bank[page.loops.sel].id]
      -- else
      --   pad = bank[page.loops.sel][bank[page.loops.sel].focus_pad]
      -- end

      -- local pad = bank[page.loops.sel].focus_hold and bank[page.loops.sel][bank[page.loops.sel].focus_pad] or bank[page.loops.sel][bank[page.loops.sel].id]
      
      if (page.loops.frame == 1 and key1_hold and not key2_hold) or (page.loops.frame == 2 and key2_hold and not key1_hold) then
        screen.level(3)
        screen.move(70,25)
        screen.text_center("E1: controls"..((page.loops.frame == 2 and key2_hold) and " / K3: loop pad" or ""))
        screen.level(((page.loops.frame == 1 and key1_hold and not key2_hold)) and screen_levels[4] or screen_levels[1])
        screen.move(0,25+(10*page.loops.top_option_set[page.loops.sel]))
        screen.text(">")
        screen.level(page.loops.top_option_set[page.loops.sel] == 1 and 15 or 3)
        screen.move(10,35)
        screen.text("E2: buff sel")
        screen.move(128,35)
        screen.text_right("E3: s/t offset")
        screen.move(10,45)
        screen.level(page.loops.top_option_set[page.loops.sel] == 2 and 15 or 3)
        screen.text("E2: rate")
        screen.move(128,45)
        screen.text_right("E3: rate slew")
        if pad.mode == 2 and page.loops.top_option_set[page.loops.sel] == 1 then
          screen.level(15)
          screen.move(0,55)
          screen.text(((page.loops.frame == 1 and key1_hold and not key2_hold)) and "(K3: load sample)" or "(K1: load sample)")
        end

      else
        screen.level(screen_levels[1])
        screen.move(0,40)
        local which_pad;
        if bank[page.loops.sel].focus_hold then
          which_pad = bank[page.loops.sel].focus_pad
        elseif page.loops.frame == 1 then
          which_pad = bank[page.loops.sel].id
        elseif page.loops.frame == 2 then
          if grid_pat[page.loops.sel].play == 0 and midi_pat[page.loops.sel].play == 0 and not arp[page.loops.sel].playing and rytm.track[page.loops.sel].k == 0 then
            which_pad = bank[page.loops.sel].id
          else
            which_pad = bank[page.loops.sel].focus_pad
          end
        end

        -- elseif grid_pat[page.loops.sel].play == 0 and midi_pat[page.loops.sel].play == 0 and not arp[page.loops.sel].playing and rytm.track[page.loops.sel].k == 0 then
        --   which_pad = bank[page.loops.sel].id
        -- else
        --   which_pad = bank[page.loops.sel].focus_pad
        -- end

        if not grid_alt then
          local loops_to_screen_options = {"a", "b", "c"}
          screen.text(loops_to_screen_options[page.loops.sel]..""..which_pad)
          screen.move(0,50)
          if which_pad ~= bank[page.loops.sel].id then
            screen.level(3)
            screen.text(loops_to_screen_options[page.loops.sel]..""..bank[page.loops.sel].id)
            screen.level(screen_levels[1])
          end
          if (bank[page.loops.sel].focus_hold) or (page.loops.frame == 2 and (grid_pat[page.loops.sel].play == 1 or midi_pat[page.loops.sel].play == 1 or arp[page.loops.sel].playing or rytm.track[page.loops.sel].k ~= 0)) then
            -- draw lock
            screen.level(screen_levels[1])
            for j = 1,6 do
              for k = 5,9 do
                screen.pixel(j,k+15)
              end
            end
            screen.pixel(2,19)
            screen.pixel(2,18)
            screen.pixel(3,17)
            screen.pixel(4,17)
            screen.pixel(5,18)
            screen.pixel(5,19)
            screen.fill()
          end
          screen.move(3,33)
          screen.text_center(bank[page.loops.sel][which_pad].loop == false and "" or "∞")
        else
          local loops_to_screen_options = {"(a)","(b)","(c)"}
          screen.text(loops_to_screen_options[page.loops.sel])
        end

        local modes =
        {
          rec[pad.clip]
        , clip[pad.clip]
        }

        local start_point =
        {
          live[pad.clip].min
        , clip[pad.clip].min
        }

        local end_point =
        {
          live[pad.clip].max
        , clip[pad.clip].max
        }

        local waves = modes[pad.mode].waveform_samples
        
        local x_pos = 0
        if #waves > 0 then
          x_pos = 0
          screen.level(screen_levels[2])
        
          for i,s in ipairs(waves) do
            local height = util.round(math.abs(s) * scale)
            screen.move(util.linlin(0,128,16,120,x_pos), 35 - height)
            screen.line_rel(0, 2 * height)
            x_pos = x_pos + 1
          end

          screen.stroke()

          local min = (key1_hold and page.loops.frame == 2) and pad.start_point or start_point[pad.mode]
          local max = (key1_hold and page.loops.frame == 2) and pad.end_point or end_point[pad.mode]
          local s_p = util.round(pad.start_point,0.01)
          local e_p = math.modf(pad.end_point*100)/100
          local sp_to_screen = util.linlin(min,max,15,120,s_p)
          local ep_to_screen = util.linlin(min,max,15,120,e_p)
          screen.level(screen_levels[1])
          screen.move(sp_to_screen,15)
          screen.line_rel(0,40)
          screen.move(ep_to_screen,15)
          screen.line_rel(0,40)
          screen.stroke()

          if (bank[page.loops.sel].focus_hold == false or bank[page.loops.sel].id == bank[page.loops.sel].focus_pad) then
            local pad_min = (key1_hold and page.loops.frame == 2) and pad.start_point or start_point[pad.mode]
            local pad_max = (key1_hold and page.loops.frame == 2) and pad.end_point or end_point[pad.mode]
            local current_to_screen = util.linlin(pad_min,pad_max,15,120,poll_position_new[page.loops.sel+1])
            screen.level(screen_levels[3])
            screen.move(current_to_screen,22)
            screen.line_rel(0,25)
            screen.stroke()
          end
        end
      end

      local sets =
      {
        [1] =
        {
          (pad.mode == 1 and ("Live"..(page.loops.frame == 1 and " (all): " or ": ")..pad.clip) or ("Clip"..(page.loops.frame == 1 and " (all): " or ": ")..pad.clip))
        , ("shft"..(page.loops.frame == 1 and " (all): " or ": ")..(string.format("%.2f",((math.log(pad.offset)/math.log(0.5))*-12))).." st")
        }
      , [2] =
        {
          ("rate"..(page.loops.frame == 1 and " (all): " or ": ")..string.format("%.4g",pad.rate).."x")
        , ("rmp"..(page.loops.frame == 1 and " (all): " or ": ")..string.format("%.1f",pad.rate_slew).."s")
        }
      , [3] =
        {
          ("E1: window")
        , ("E2: start")
        , ("E3: end")
        }
      }

      local key_gestures =
      {
        [1] =
        {
          ("K2: dur -> BPM")
        , ("K3: random")
        }
      }

      if page.loops.frame == 1 then
        screen.level(screen_levels[4])
        if key2_hold then
          screen.move(64,63)
          screen.text_center("K3: toggle looping, all pads")
        else
          screen.move(0,63)
          screen.text(sets[page.loops.top_option_set[page.loops.sel]][1])
          screen.move(128,63)
          screen.text_right(sets[page.loops.top_option_set[page.loops.sel]][2])
        end
      -- elseif page.loops.frame == 2 and key1_hold and not key2_hold then
      elseif page.loops.frame == 2 and key1_hold then
        screen.level(screen_levels[1])
        screen.move(0,63)
        screen.text(key_gestures[1][1])
        screen.move(128,63)
        screen.text_right(key_gestures[1][2])
      elseif page.loops.frame == 2 and key2_hold and not key1_hold then
        screen.level(screen_levels[1])
        screen.move(0,63)
        screen.text(sets[page.loops.top_option_set[page.loops.sel]][1])
        screen.move(128,63)
        screen.text_right(sets[page.loops.top_option_set[page.loops.sel]][2])
      elseif page.loops.frame == 2 and not key2_hold and not key1_hold then
        screen.level(screen_levels[1])
        screen.move(0,63)
        screen.text(sets[3][1])
        screen.move(68,63)
        screen.text_center(sets[3][2])
        screen.move(128,63)
        screen.text_right(sets[3][3])
      end
      

    elseif page.loops.sel == 4 then

      if (page.loops.frame == 1 and key1_hold and not key2_hold) then
        screen.level(screen_levels[4])
        screen.move(70,25)
        screen.text_center("E1: change control sets")
        screen.move(0,25+(10*page.loops.top_option_set[page.loops.sel]))
        screen.text(">")
        screen.level(page.loops.top_option_set[page.loops.sel] == 1 and 15 or 3)
        screen.move(10,35)
        screen.text("E2: feedback")
        screen.move(128,35)
        screen.text_right("E3: rnd rec")
        screen.move(10,45)
        screen.level(page.loops.top_option_set[page.loops.sel] == 2 and 15 or 3)
        screen.text("E2: mode")
        screen.move(128,45)
        screen.text_right("E3: duration")
      
      else

        screen.level(screen_levels[1])
        screen.move(0,40)
        screen.text("L"..rec.focus)
        screen.move(1,32)
        screen.text(rec[rec.focus].queued and "..." or "")

        local waves = rec[rec.focus].waveform_samples
        
        local x_pos = 0
        if #waves > 0 then
          x_pos = 0
          screen.level(screen_levels[2])
        
          for i,s in ipairs(waves) do
            local height = util.round(math.abs(s) * scale)
            screen.move(util.linlin(0,128,16,120,x_pos), 35 - height)
            screen.line_rel(0, 2 * height)
            x_pos = x_pos + 1
          end

          screen.stroke()

          local min = (key1_hold and page.loops.frame == 2) and rec[rec.focus].start_point or live[rec.focus].min
          local max = (key1_hold and page.loops.frame == 2) and rec[rec.focus].end_point or live[rec.focus].max
          local s_p = util.round(rec[rec.focus].start_point,0.01)
          local e_p = math.modf(rec[rec.focus].end_point*100)/100
          local sp_to_screen = util.linlin(min,max,15,120,s_p)
          local ep_to_screen = util.linlin(min,max,15,120,e_p)
          screen.level(screen_levels[1])
          screen.move(sp_to_screen,15)
          screen.line_rel(0,40)
          screen.move(ep_to_screen,15)
          screen.line_rel(0,40)
          screen.stroke()

          if poll_position_new[1] >= rec[rec.focus].start_point and poll_position_new[1] <= rec[rec.focus].end_point then
            local current_to_screen = util.linlin(min,max,15,120,poll_position_new[1])
            screen.level(screen_levels[3])
            screen.move(current_to_screen,22)
            screen.line_rel(0,25)
            screen.text(rec[rec.focus].state == 1 and ">" or "")
            screen.stroke()
          end

          local rate_options = {"8s","16s","32s"}
          local mode_options = {"loop","shot","shot+threshold"}
          local sets =
          {
            [1] =
            {
              ("feed: "..string.format("%0.f",params:get("live_rec_feedback_"..rec.focus)*100).."%")
            , ("rnd prob: "..params:get("random_rec_clock_prob_"..rec.focus).."%")
            }
          , [2] =
            {
              ("mode: "..(params:get("rec_loop_"..rec.focus) == 1 and "loop" or "shot"))
            , ("total: "..rate_options[params:get"live_buff_rate"])
            }
          , [3] =
            {
              ("E2: start")
            , ("E3: end")
            }
          }

          local key_gestures =
          {
            [1] =
            {
              ("K2: erase")
            , ("")
            }
          }

          if page.loops.frame == 1 then
            screen.level(screen_levels[4])
            if key2_hold then
              screen.move(64,63)
              screen.text_center("K3: toggle recording")
            else
              screen.move(0,63)
              screen.text(sets[page.loops.top_option_set[page.loops.sel]][1])
              screen.move(128,63)
              screen.text_right(sets[page.loops.top_option_set[page.loops.sel]][2])
            end
          elseif page.loops.frame == 2 then
            screen.level(screen_levels[1])
            if key2_hold then
              screen.move(64,63)
              screen.text_center("K3: toggle recording")
            else
              screen.move(0,63)
              screen.text(key1_hold and key_gestures[1][1] or sets[3][1])
              screen.move(128,63)
              screen.text_right(key1_hold and key_gestures[1][2] or sets[3][2])
            end
          end

        end
      
      end

    elseif page.loops.sel == 5 then
      for i = 1,4 do
        local id;
        local options;
        screen.line_width(1)
        if i < 4 then
          if bank[i].focus_hold then
            id = bank[i].focus_pad
          elseif page.loops.frame == 1 then
            id = bank[i].id
          elseif page.loops.frame == 2 then
            if grid_pat[i].play == 0 and midi_pat[i].play == 0 and not arp[i].playing and rytm.track[i].k == 0 then
              id = bank[i].id
            else
              if key1_hold and page.loops.meta_sel == i then
                id = bank[i].focus_pad
              else
                id = bank[i].id
              end
            end
          end

          local pad = bank[i][id]

          local off = pad.mode == 1 and (((pad.clip-1)*8)+1) or clip[pad.clip].min
          local display_end = pad.mode == 1 and (pad.end_point == 8.99 and 9 or pad.end_point) or pad.end_point


          screen.level(page.loops.frame == 2 and (page.loops.meta_sel == i and 15 or 3) or 3)
          screen.move(15,8+(i*14))
          screen.line(115,8+(i*14))
          screen.close()
          screen.stroke()
          local duration = bank[i][id].mode == 1 and 8 or clip[bank[i][id].clip].sample_length
          local s_p = bank[i][id].mode == 1 and live[bank[i][id].clip].min or clip[bank[i][id].clip].min
          local e_p = bank[i][id].mode == 1 and live[bank[i][id].clip].max or clip[bank[i][id].clip].max
          local start_to_screen = util.linlin(s_p,e_p,15,115,bank[i][id].start_point)
          screen.move(start_to_screen,21+(14*(i-1)))
          screen.text("|")
          local end_to_screen = util.linlin(s_p,e_p,15,115,bank[i][id].end_point)
          screen.move(end_to_screen,27+(14*(i-1)))
          screen.text("|")
          if bank[i].focus_hold == false or bank[i].id == bank[i].focus_pad then
            local current_to_screen = util.linlin(s_p,e_p,15,115,poll_position_new[i+1])
            screen.move(current_to_screen,24+(14*(i-1)))
            screen.text("|")
          end

        elseif i == 4 then
          id = rec.focus
          local off = ((id-1)*8)+1
          local mults = {1,2,4}
          local mult = mults[params:get("live_buff_rate")]
          
          local min = live[rec.focus].min
          local max = live[rec.focus].max
          local s_p = util.round(rec[rec.focus].start_point,0.01)
          local e_p = math.modf(rec[rec.focus].end_point*100)/100
          local sp_to_screen = util.linlin(min,max,15,115,s_p)
          local ep_to_screen = util.linlin(min,max,15,115,e_p)
          screen.level(page.loops.frame == 2 and (page.loops.meta_sel == i and 15 or 3) or 3)
          screen.move(sp_to_screen,64)
          screen.text("|")
          screen.move(ep_to_screen,64)
          screen.text("|")
          screen.stroke()

          if poll_position_new[1] >= rec[rec.focus].start_point and poll_position_new[1] <= rec[rec.focus].end_point then
            local current_to_screen = util.linlin(min,max,15,115,poll_position_new[1])
            screen.level(page.loops.frame == 2 and (page.loops.meta_sel == i and 15 or 3) or 3)
            screen.move(current_to_screen,64)
            screen.text(rec[rec.focus].state == 1 and ">" or "||")
            screen.stroke()
          end

          -- screen.level(page.loops_sel == 3 and 15 or 3)
          -- local recording_playhead = util.linlin(1,9,15,120,(poll_position_new[1] - (8*(rec.clip-1))))
          -- if rec.state == 1 then
          --   screen.move(recording_playhead,64)
          --   screen.text(".")
          -- elseif rec.state == 0 then
          --   screen.move(recording_playhead,67)
          --   screen.text_center("||")
          -- end
          -- local recording_start = util.linlin(1,9,15,120,(rec.start_point - (8*(rec.clip-1))))
          -- screen.move(recording_start,66)
          -- screen.text("|")
          -- local recording_end = util.linlin(1,9,15,120,rec.end_point - (8*(rec.clip-1)))
          -- screen.move(recording_end,66)
          -- screen.text("|")
          -- screen.move(123,64)
          -- screen.text(rec.clip)

        -- elseif menu == 2 then
        --   screen.move(0,10)
        --   screen.level(3)
        --   screen.text("loops")
        --   if key1_hold then
        --     local id = page.loops_sel+1
        --     local focused_pad = nil
        --     if grid_alt == 1 then
        --       screen.move(0,20)
        --       screen.level(6)
        --       screen.text("(grid-ALT sets offset for all)")
        --     end
        --     for i = 1,3 do
        --       --if grid_pat[i].play == 0 and grid_pat[i].tightened_start == 0 and grid_pat[i].external_start == 0 then
        --       if grid_pat[i].play == 0 and grid_pat[i].tightened_start == 0 then
        --         focused_pad = bank[i].id
        --       else
        --         focused_pad = bank[i].focus_pad
        --       end
        --       if page.loops_sel == i-1 then
        --         if page.loops_sel < 3 and focused_pad == 16 and grid_alt == 0 then
        --           screen.move(0,20)
        --           screen.level(6)
        --           screen.text("(pad 16 overwrites bank!)")
        --         end
        --         --if grid_pat[i].play == 1 or grid_pat[i].tightened_start == 1 or grid_pat[i].external_start == 1 then
        --         if grid_pat[i].play == 1 or grid_pat[i].tightened_start == 1 then
        --           screen.move(0,10)
        --           screen.level(3)
        --           screen.text("loops: bank "..i.." is pad-locked")
        --         end
        --       end
        --       screen.move(0,20+(i*10))
        --       screen.level(page.loops_sel == i-1 and 15 or 3)
        --       if grid_alt == 0 then
        --         local loops_to_screen_options = {"a", "b", "c"}
        --         screen.text(loops_to_screen_options[i]..""..focused_pad)
        --       else
        --         local loops_to_screen_options = {"(a)","(b)","(c)"}
        --         screen.text(loops_to_screen_options[i])
        --       end
        --       screen.move(20,20+(i*10))
        --       screen.text((bank[i][focused_pad].mode == 1 and "Live" or "Clip")..":")
        --       screen.move(40,20+(i*10))
        --       screen.text(bank[i][focused_pad].clip)
        --       screen.move(55,20+(i*10))
        --       screen.text("offset: "..string.format("%.0f",((math.log(bank[i][focused_pad].offset)/math.log(0.5))*-12)).." st")
        --     end
        --     screen.level(page.loops_sel == 3 and 15 or 3)
        --     screen.move(0,60)
        --     screen.text("L"..rec.clip)
        --     screen.move(20,60)
        --     screen.text(rec.state == 1 and "recording" or "not recording")
        --     screen.move(88,60)
        --     local rate_options = {"8 s","16 s","32 s"}
        --     screen.text(rate_options[params:get"live_buff_rate"])
        --     screen.move(111,60)
        --     screen.level(3)
        --     screen.text(string.format("%0.f",util.linlin(rec.start_point-(8*(rec.clip-1)),rec.end_point-(8*(rec.clip-1)),0,100,(poll_position_new[1] - (8*(rec.clip-1))))).."%")
        --   else
        --     local which_pad = nil
        --     screen.line_width(1)
        --     for i = 1,3 do
        --       if bank[i].focus_hold == false then
        --         which_pad = bank[i].id
        --       else
        --         which_pad = bank[i].focus_pad
        --       end
        --       screen.move(0,10+(i*15))
        --       screen.level(page.loops_sel == i-1 and 15 or 3)
        --       local loops_to_screen_options = {"a", "b", "c"}
        --       screen.text(loops_to_screen_options[i]..""..which_pad)
        --       screen.move(15,10+(i*15))
        --       screen.line(120,10+(i*15))
        --       screen.close()
        --       screen.stroke()
        --     end
        --     for i = 1,3 do
        --       if bank[i].focus_hold == false then
        --         which_pad = bank[i].id
        --       else
        --         which_pad = bank[i].focus_pad
        --       end
        --       screen.level(page.loops_sel == i-1 and 15 or 3)
        --       local start_to_screen = util.linlin(1,9,15,120,(bank[i][which_pad].start_point - (8*(bank[i][which_pad].clip-1))))
        --       screen.move(start_to_screen,24+(15*(i-1)))
        --       screen.text("|")
        --       local end_to_screen = util.linlin(1,9,15,120,bank[i][which_pad].end_point - (8*(bank[i][which_pad].clip-1)))
        --       screen.move(end_to_screen,30+(15*(i-1)))
        --       screen.text("|")
        --       if bank[i].focus_hold == false or bank[i].id == bank[i].focus_pad then
        --         local current_to_screen = util.linlin(1,9,15,120,(poll_position_new[i+1] - (8*(bank[i][bank[i].id].clip-1))))
        --         screen.move(current_to_screen,27+(15*(i-1)))
        --         screen.text("|")
        --       end
        --     end
        --     screen.level(page.loops_sel == 3 and 15 or 3)
        --     local recording_playhead = util.linlin(1,9,15,120,(poll_position_new[1] - (8*(rec.clip-1))))
        --     if rec.state == 1 then
        --       screen.move(recording_playhead,64)
        --       screen.text(".")
        --     elseif rec.state == 0 then
        --       screen.move(recording_playhead,67)
        --       screen.text_center("||")
        --     end
        --     local recording_start = util.linlin(1,9,15,120,(rec.start_point - (8*(rec.clip-1))))
        --     screen.move(recording_start,66)
        --     screen.text("|")
        --     local recording_end = util.linlin(1,9,15,120,rec.end_point - (8*(rec.clip-1)))
        --     screen.move(recording_end,66)
        --     screen.text("|")
        --     screen.move(123,64)
        --     screen.text(rec.clip)
        --   end
        --   screen.level(3)
        --   screen.move(0,64)
        --   screen.text("...")


        end

        screen.move(0,8+(i*14))
        screen.level(page.loops.meta_sel == i and screen_levels[1] or 3)
        local loops_to_screen_options = {"a", "b", "c", "L"}
        screen.text(loops_to_screen_options[i]..""..id)

        if i < 4 then
          if (bank[i].focus_hold) or (page.loops.frame == 2 and key1_hold and page.loops.meta_sel == i and (grid_pat[i].play == 1 or midi_pat[i].play == 1 or arp[i].playing or rytm.track[i].k ~= 0)) then
            -- draw lock
            screen.level(page.loops.meta_sel == i and 15 or 3)
            for j = 120,125 do
              for k = 5,9 do
                screen.pixel(j,k+(i*14))
              end
            end
            screen.pixel(121,4+(i*14))
            screen.pixel(121,3+(i*14))
            screen.pixel(122,2+(i*14))
            screen.pixel(123,2+(i*14))
            screen.pixel(124,4+(i*14))
            screen.pixel(124,3+(i*14))
            screen.fill()
          end
        end
        -- screen.move(27,8+(i*14))
        -- screen.text(options[1])
        -- screen.move(67,8+(i*14))
        -- screen.text(options[2])

      end
    end
    
  elseif menu == 3 then
    screen.move(0,10)
    screen.level(3)
    screen.text("levels")
    screen.line_width(1)
    local level_options = {"levels","envelope enable","loop","time"}
    local focused_pad = nil
    for i = 1,3 do
      if bank[i].focus_hold == true then
        focused_pad = bank[i].focus_pad
      else
        focused_pad = bank[i].id
      end
      screen.level(3)
      screen.move(10,79-(i*20))
      local level_markers = {"0 -", "1 -", "2 -"}
      screen.text(level_markers[i])
      screen.move(10+(i*20),64)
      screen.level(level_options[page.levels.sel+1] == "levels" and 15 or 3)
      local level_to_screen_options = {"a", "b", "c"}
      if key1_hold or grid_alt or bank[i].alt_lock then
        screen.text("("..level_to_screen_options[i]..")")
      else
        screen.text(level_to_screen_options[i]..""..focused_pad)
      end
      screen.move(35+(20*(i-1)),57)
      local level_to_screen = ((key1_hold or grid_alt or bank[i].alt_lock) and util.linlin(0,2,0,40,bank[i].global_level) or util.linlin(0,2,0,40,bank[i][focused_pad].level))
      screen.line(35+(20*(i-1)),57-level_to_screen)
      screen.close()
      screen.stroke()
      screen.level(level_options[page.levels.sel+1] == "envelope enable" and 15 or 3)
      screen.move(85,10)
      screen.text("env?")
      screen.move(90+((i-1)*15),20)
      local shapes = {"\\","/","/\\"}
      if bank[i][focused_pad].enveloped then
        screen.text_center(shapes[bank[i][focused_pad].envelope_mode])
      else
        screen.text_center("-")
      end
      screen.level(level_options[page.levels.sel+1] == "loop" and 15 or 3)
      screen.move(90+((i-1)*15),30)
      if bank[i][focused_pad].envelope_loop then
        screen.text_center("∞")
      else
        screen.text_center("-")
      end
      
      screen.level(level_options[page.levels.sel+1] == "time" and 15 or 3)
      -- screen.move(85,30)
      -- screen.text("time")
      screen.move(85,34+((i)*10))
      local envelope_to_screen_options = {"a", "b", "c"}
      if key1_hold or grid_alt or bank[i].alt_lock then
        screen.text("("..envelope_to_screen_options[i]..")")
      else
        screen.text(envelope_to_screen_options[i]..""..focused_pad)
      end
      screen.move(103,34+((i)*10))
      if bank[i][focused_pad].enveloped then
        screen.text(string.format("%.2g", bank[i][focused_pad].envelope_time).."s")
      else
        screen.text("---")
      end
    end
    screen.level(3)
    screen.move(0,64)
  elseif menu == 4 then
    screen.move(0,10)
    screen.level(3)
    screen.text("pans")
    local focused_pad = nil
    for i = 1,3 do
      if bank[i].focus_hold == true then
        focused_pad = bank[i].focus_pad
      else
        focused_pad = bank[i].id
      end
      screen.level(3)
      screen.move(10+((i-1)*53),25)
      local pan_options = {"L", "C", "R"}
      screen.text(pan_options[i])
      local pan_to_screen = util.linlin(-1,1,10,112,bank[i][focused_pad].pan)
      screen.move(pan_to_screen,35+(10*(i-1)))
      local pan_to_screen_options = {"a", "b", "c"}
      screen.level(15)
      if key1_hold or grid_alt then
        screen.text("("..pan_to_screen_options[i]..")")
      else
        screen.text(pan_to_screen_options[i]..""..focused_pad)
      end
    end
  elseif menu == 5 then
    screen.move(0,10)
    screen.level(3)
    screen.text("filters")
    
    for i = 1,3 do
      screen.move(17+((i-1)*45),20)
      screen.level(15)
      local filters_to_screen_options = {"a", "b", "c"}
      if key1_hold or grid_alt then
        screen.text_center(filters_to_screen_options[i]..""..bank[i].id)
      else
        screen.text_center("("..filters_to_screen_options[i]..")")
      end
      screen.move(17+((i-1)*45),30)
      
      screen.level(page.filters.sel+1 == 1 and 15 or 3)
      if slew_counter[i].slewedVal ~= nil then
        if slew_counter[i].slewedVal >= -0.04 and slew_counter[i].slewedVal <=0.04 then
        screen.text_center(".....|.....")
        elseif slew_counter[i].slewedVal < -0.04 then
          if slew_counter[i].slewedVal > -0.3 then
            screen.text_center("....||.....")
          elseif slew_counter[i].slewedVal > -0.45 then
            screen.text_center("...|||.....")
          elseif slew_counter[i].slewedVal > -0.65 then
            screen.text_center("..||||.....")
          elseif slew_counter[i].slewedVal > -0.8 then
            screen.text_center(".|||||.....")
          elseif slew_counter[i].slewedVal >= -1.01 then
            screen.text_center("||||||.....")
          end
        elseif slew_counter[i].slewedVal > 0 then
          if slew_counter[i].slewedVal < 0.5 then
            screen.text_center(".....||....")
          elseif slew_counter[i].slewedVal < 0.65 then
            screen.text_center(".....|||...")
          elseif slew_counter[i].slewedVal < 0.8 then
            screen.text_center(".....||||..")
          elseif slew_counter[i].slewedVal < 0.85 then
            screen.text_center(".....|||||.")
          elseif slew_counter[i].slewedVal <= 1.01 then
            screen.text_center(".....||||||")
          end
        end
      end
      screen.move(17+((i-1)*45),40)
      screen.level(page.filters.sel+1 == 2 and 15 or 3)
      local ease_time_to_screen = bank[i][bank[i].id].tilt_ease_time
      screen.text_center(string.format("%.2f",ease_time_to_screen/100).."s")
      screen.move(17+((i-1)*45),50)
      screen.level(page.filters.sel+1 == 3 and 15 or 3)
      local q_scaled = util.linlin(0.0005,4,100,0,params:get("filter "..i.." q"))
      screen.text_center(string.format("%.4g",q_scaled).."%")
      screen.move(17+((i-1)*45),60)
      screen.level(page.filters.sel+1 == 4 and 15 or 3)
      local ease_type_to_screen = bank[i][bank[i].id].tilt_ease_type
      local ease_types = {"cont","jumpy"}
      screen.text_center(ease_types[ease_type_to_screen])
    end

  elseif menu == 6 then
    screen.move(0,10)
    screen.level(3)
    screen.text("delays")
    local focused_menu = page.delay[page.delay.focus].menu
    if key1_hold then
      screen.move(128,10)
      if page.delay.section == 2 and focused_menu == 1 then
        local focused_prm = page.delay[page.delay.focus].menu_sel[focused_menu]
        if (delay[page.delay.focus].mode == "free" and focused_prm == 2) or (delay[page.delay.focus].mode == "free" and focused_prm == 3) or focused_prm == 4 then
          screen.text_right("fine-tune enabled")
        elseif focused_prm == 5 then
          screen.text_right("quick-jump!!")
        end
      elseif page.delay.section == 2 and focused_menu == 3 then
        if page.delay[page.delay.focus].menu_sel[focused_menu] < 7 then
          screen.text_right("map changes to bank")
        end
      end
    end
    screen.level(15)
    screen.font_size(40)
    screen.move(0,50)
    screen.text(page.delay.focus == 1 and "L" or "R")
    screen.move(0,60)
    if page.delay.section == 2 then
      local k = page.delay[page.delay.focus].menu
      local v = page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu]
      if delay_links[del.lookup_prm(k,v)] then
        screen.font_size(8)
        screen.text("linked")
      end
    elseif page.delay.section == 1 then
      if key1_hold then
        screen.font_size(8)
        if page.delay[page.delay.focus].menu ~= 3 then
          screen.move(0,60)
          screen.text("K3: toggle all links")
        else
          screen.move(128,10)
          screen.text_right("K3: toggle all links")
        end
      end
    end
    screen.font_size(8)
    local options = {"ctl","flt","mix"}
    for i = 1,3 do
      screen.level((page.delay.section == 1 and focused_menu == i) and 15 or 3)
      screen.move(30+(40*(i-1)),20)
      screen.text(options[i])
    end
    screen.level((page.delay.section == 1 and focused_menu == focused_menu) and 15 or 3)
    screen.move(30+(40*(focused_menu-1)),23)
    screen.line((focused_menu == 3 and 41 or 40)+(40*(focused_menu-1)),23)
    screen.stroke()
    local delay_name = page.delay.focus == 1 and "L" or "R"
    screen.level((page.delay.section == 2 and focused_menu == focused_menu) and 15 or 3)
    local selected = page.delay[page.delay.focus].menu_sel[focused_menu]
    if focused_menu == 1 then
      screen.level((page.delay.section == 2 and selected == 1) and 15 or 3)
      screen.move(30,30)
      screen.text(params:string("delay "..delay_name..": mode"))
      screen.move(75,30)
      screen.level((page.delay.section == 2 and selected == 2) and 15 or 3)
      if delay[page.delay.focus].mode == "clocked" then
        if delay[page.delay.focus].modifier ~= 1 then
          screen.text(params:string("delay "..delay_name..": div/mult").."*"..string.format("%.4g",delay[page.delay.focus].modifier))
        else
          screen.text(params:string("delay "..delay_name..": div/mult"))
        end
      else
        screen.text(string.format("%.4g",params:get("delay "..delay_name..": free length")).." sec")
      end
      screen.level((page.delay.section == 2 and selected == 3) and 15 or 3)
      screen.move(30,40)
      screen.text("fade: "..string.format("%.4g",params:get("delay "..delay_name..": fade time")))
      screen.level((page.delay.section == 2 and selected == 4) and 15 or 3)
      screen.move(80,40)
      local rev = delay[page.delay.focus].reverse == true and 1 or 0
      screen.text("rate: "..(rev == 1 and "-" or "")..string.format("%.4g",params:string("delay "..delay_name..": rate")))
      screen.level((page.delay.section == 2 and selected == 5) and 15 or 3)
      screen.move(30,50)
      if delay[page.delay.focus].feedback_mute then
        if params:get(page.delay.focus == 1 and "delay L: feedback" or "delay R: feedback") == 0 then
          screen.text("feedback: 100%")
        else
          screen.text("feedback: 0%")
        end
      else
        screen.text("feedback: "..string.format("%.4g",params:get("delay "..delay_name..": feedback")).."%")
      end
    elseif focused_menu == 2 then
      screen.level((page.delay.section == 2 and selected == 1) and 15 or 3)
      screen.move(30,30)
      local current_freq = params:get("delay "..delay_name..": filter cut")
      local modified_freq = easingFunctions[params:string("delay "..delay_name..": curve")](current_freq/12000,10,11990,1)
      screen.text(string.format("%.6g",modified_freq).." hz")
      screen.level((page.delay.section == 2 and selected == 2) and 15 or 3)
      screen.move(85,30)
      screen.text("q: "..params:string("delay "..delay_name..": filter q"))
      screen.level((page.delay.section == 2 and selected == 3) and 15 or 3)
      screen.move(30,40)
      screen.text("LP: "..params:string("delay "..delay_name..": filter lp"))
      screen.level((page.delay.section == 2 and selected == 4) and 15 or 3)
      screen.move(85,40)
      screen.text("HP: "..params:string("delay "..delay_name..": filter hp"))
      screen.level((page.delay.section == 2 and selected == 5) and 15 or 3)
      screen.move(30,50)
      screen.text("BP: "..params:string("delay "..delay_name..": filter bp"))
      screen.level((page.delay.section == 2 and selected == 6) and 15 or 3)
      screen.move(85,50)
      screen.text("dry: "..params:string("delay "..delay_name..": filter dry"))
    elseif focused_menu == 3 then
      local bank_names = {"a","b","c"}
      for i = 1,3 do
        screen.level(3)
        screen.move(30,20+(i*10))
        screen.text(bank_names[i]..""..bank[i].id)
        screen.level((page.delay.section == 2 and selected == (i == 1 and 1 or (i == 2 and 3 or 5))) and 15 or 3)
        screen.move(50,20+(i*10))
        screen.text("in: "..string.format("%.1f",(page.delay.focus == 1 and bank[i][bank[i].id].left_delay_level or bank[i][bank[i].id].right_delay_level)))
        screen.level((page.delay.section == 2 and selected == (i == 1 and 2 or (i == 2 and 4 or 6))) and 15 or 3)
        screen.move(80,20+(i*10))
        screen.text("thru: "..(page.delay.focus == 1 and tostring(bank[i][bank[i].id].left_delay_thru) or tostring(bank[i][bank[i].id].right_delay_thru)))
      end
      screen.level((page.delay.section == 2 and selected == 7) and 15 or 3)
      screen.move(30,60)
      screen.text("main output level: "..string.format("%.2f", params:get("delay "..delay_name..": global level")))
    end
  
  elseif menu == 7 then
    screen.move(0,10)
    screen.level(3)
    screen.text("timing")
    screen.move(66,10)
    screen.text_center("bpm: "..params:get("clock_tempo"))
    metronome(110,10,15,3)
    screen.level(10)
    screen.move(10,30)
    screen.line(123,30)
    screen.stroke()
    if key1_hold and (page.time_page_sel[page.time_sel] == 1 or page.time_page_sel[page.time_sel] == 5) and page.time_sel < 4 then
      screen.level(15)
      screen.move(5,40)
      screen.text("*")
    end
    local playing = {}
    local display_step = {}

    local time_page = page.time_page_sel
    local page_line = page.time_sel

    for i = 1,3 do
      screen.level(page_line == i and 15 or 3)
      -- local pattern = g.device ~= nil and grid_pat[i] or midi_pat[i]
      local pattern
      if get_grid_connected() or osc_communication then
        pattern = grid_pat[i]
      else
        pattern =  midi_pat[i]
      end
      screen.move(10+(20*(i-1)),25)
      screen.text("P"..i)
      screen.move(5+(20*(i-1)),25)
      screen.level(3)
      if pattern.play == 1 then
        screen.text(pattern.overdub == 0 and (">") or "o")
      elseif pattern.play == 0 and pattern.count > 0 and pattern.rec == 0 then
        screen.text("x")
      end
    end
    
    if page.time_sel < 4 then
      local pattern
      if get_grid_connected() or osc_communication then
        pattern = grid_pat[page_line]
      else
        pattern =  midi_pat[page_line]
      end
      if pattern.sync_hold ~= nil and pattern.sync_hold then
        local show_me_beats = clock.get_beats() % 4
        local show_me_frac = math.fmod(clock.get_beats(),1)
        if show_me_frac <= 0.25 then
          show_me_frac = 1
        elseif show_me_frac <= 0.5 then
          show_me_frac = 2
        elseif show_me_frac <= 0.75 then
          show_me_frac = 3
        else
          show_me_frac = 4
        end
        screen.level(3)
        screen.move(45,55)
        screen.font_size(30)
        screen.text_center(" -"..math.modf(4-show_me_beats).."."..math.modf(4-show_me_frac,1))
        screen.font_size(8)
      elseif pattern.rec == 1 then
        screen.level(15)
        screen.move(65,55)
        screen.font_size(30)
        screen.text_center("rec")
        screen.font_size(8)
      else
        local state_option = pattern.play == 1 and "current step" or "rec mode"
        local p_options = {state_option, "shuffle pat","P"..page_line.." sets bpm?","rand pat [K3]", "pat start", "pat end"}
        local p_options_rand = {"low rates", "mid rates", "hi rates", "full range", "keep rates"}

        if page.time_scroll[page_line] == 1 then
          for j = 1,3 do
            screen.level(time_page[page_line] == j and 15 or 3)
            screen.move(10,40+(10*(j-1)))
            screen.text(p_options[j])
            local mode_options = {"loose","bars: "..string.format("%.4g", pattern.rec_clock_time/4),"quant","quant+trim"}
            local show_state = pattern.play == 1 and pattern.step or mode_options[pattern.playmode]
            local fine_options = {show_state, pattern.count > 0 and pattern.rec == 0 and "[K3]" or "(no pat!)", params:string("sync_clock_to_pattern_"..page_line)}
            screen.move(80,40+(10*(j-1)))
            screen.text(fine_options[j])
          end
        elseif page.time_scroll[page_line] == 2 then
          for j = 4,6 do
            screen.level(time_page[page_line] == j and 15 or 3)
            screen.move(10,40+(10*(j-4)))
            screen.text(p_options[j])
            screen.move(80,40+(10*(j-4)))
            local fine_options = {p_options_rand[pattern.random_pitch_range], pattern.count > 0 and pattern.rec == 0 and pattern.start_point or "(no pat!)", pattern.count > 0 and pattern.rec == 0 and pattern.end_point or "(no pat!)"}
            screen.text(fine_options[j-3])
          end
        elseif page.time_scroll[page_line] == 3 then
          for j = 7,7 do
            screen.level(time_page[page_line] == j and 15 or 3)
            screen.move(10,40+(10*(j-7)))
            screen.text(p_options[j])
            screen.move(80,40+(10*(j-7)))
            screen.text(bank[page_line].crow_execute == 1 and "pads" or "clk")
            if bank[page_line].crow_execute ~= 1 then
              screen.move(97,40)
              screen.level(time_page[page_line] == 8 and 15 or 3)
              screen.text("(/".._crow.count_execute[page_line]..")")
            end
          end
        end

      end
    end

    screen.level(3)
    screen.move(65,25)
    screen.text("/")

    for i = 4,6 do
      local id = i-3
      local time_page = page.time_page_sel
      local page_line = page.time_sel
      
      screen.level(page_line == i and 15 or 3)
      screen.move(75+(20*(id-1)),25)
      screen.text("A"..id)
    end

    if page.time_sel >= 4 then
      if a.device == nil then
        screen.move(10,40)
        screen.level(15)
        screen.text("no arc connected")
      else
        local id = page.time_sel-3
        local loop_options = {"loop(w)", "loop(s)", "loop(e)"}
        local loop_selected = loop_options[page.time_arc_loop[id]]
        local param_options = {loop_selected, "filter", "level", "pan"}
        for j = 1,4 do
          local focus = page.time_page_sel[page.time_sel]
          if key1_hold and focus <= 4 then
            screen.level(15)
            screen.move((focus == 1 or focus == 3) and 5 or 70, (focus == 1 or focus == 2) and 40 or 50)
            screen.text("*")
          end
          screen.move((j==1 or j==3) and 10 or 75,(j==1 or j==2) and 40 or 50)
          screen.level(focus == j and 15 or 3)
          local pattern = arc_pat[id][j]
          screen.text(param_options[j]..": ")
          screen.move((j==1 or j==3) and 45 or 100,(j==1 or j==2) and 40 or 50)
          if not key1_hold then
            if (arc_pat[id][j].rec == 0 and arc_pat[id][j].play == 0 and arc_pat[id][j].count == 0) then
              screen.text("none")
            elseif arc_pat[id][j].play == 1 then
              screen.text("active")
            elseif arc_pat[id][j].rec == 1 then
              screen.text("rec")
            elseif (arc_pat[id][j].rec == 0 and arc_pat[id][j].play == 0 and arc_pat[id][j].count > 0) then
              screen.text("idle")
            end
          else
            screen.text(string.format("%.1f",arc_pat[id][j].time_factor).."x")
          end
        end
        for i = 5,7 do
          local scaled = i-4
          screen.move(10,60)
          screen.level(page.time_page_sel[page.time_sel]>4 and 15 or 3)
          screen.text("all: ")
          screen.move(30+((scaled-1)*35), 60)
          local options = {"play", "stop", "clear"}
          screen.level(page.time_page_sel[page.time_sel] == i and 15 or 3)
          screen.text(options[scaled])
        end
      end
    end


    screen.level(3)
    if page.time_sel < 4 then
      local show_top = page.time_scroll[page_line] ~= 1 and true or false
      local show_bottom = page.time_scroll[page_line] == 1 and true or false
      screen.move(0,64)
      screen.text(show_bottom and "..." or "")
      screen.move(0,34)
      screen.text(show_top and "..." or "")
    end

  elseif menu == 8 then
    screen.move(0,10)
    screen.level(3)
    screen.text("euclid")
    if key1_hold then
      screen.level(15)
      screen.move(40,10)
      local track_edit_to_banks = {"a","b","c"}
      if rytm.screen_focus == "left" then
        screen.text(track_edit_to_banks[rytm.track_edit].." mode: "..rytm.track[rytm.track_edit].mode)
        screen.move(40,20)
        local divs_to_frac =
        { ["0.25"] = "1/16"
        , ["0.5"] = "1/8"
        , ["1"] = "1/4"
        , ["2"] = "1/2"
        , ["4"] = "1"
        }
        local lookup = string.format("%.4g",rytm.track[rytm.track_edit].clock_div)
        screen.text(track_edit_to_banks[rytm.track_edit].." rate: "..divs_to_frac[lookup])
      else
        screen.text(track_edit_to_banks[rytm.track_edit].." auto rot: "..rytm.track[rytm.track_edit].auto_rotation)
        screen.move(40,20)
        screen.text(track_edit_to_banks[rytm.track_edit].." auto off: "..rytm.track[rytm.track_edit].auto_pad_offset)
      end
    end
    local labels = {"(k","n)","r","+/-"}
    local spaces = {5,20,105,120}
    for i = 1,2 do
      screen.level((not key1_hold and rytm.screen_focus == "left") and 15 or 3)
      screen.move(spaces[i],20)
      screen.text_center(labels[i])
      screen.move(13,20)
      screen.text_center(",")
    end
    for i = 3,4 do
      screen.level((not key1_hold and rytm.screen_focus == "right") and 15 or 3)
      screen.move(spaces[i],20)
      screen.text_center(labels[i])
    end
    for i = 1,3 do
      screen.level((i == rytm.track_edit and rytm.screen_focus == "left" and not key1_hold) and 15 or 4)
      screen.move(5, i*12 + 20)
      screen.text_center(rytm.track[i].k)
      screen.move(20, i*12 + 20)
      screen.text_center(rytm.track[i].n)
  
      for x = 1,rytm.track[i].n do
        screen.level((rytm.track[i].pos == x and not rytm.reset[i]) and 15 or 2)
        screen.move(x*4 + 30, i*12 + 20)
        if rytm.track[i].s[x] then
          screen.line_rel(0,-8)
        else
          screen.line_rel(0,-2)
        end
        screen.stroke()
      end
      
      screen.level((i == rytm.track_edit and rytm.screen_focus == "right" and not key1_hold) and 15 or 4)
      screen.move(105, i*12 + 20)
      screen.text_center(rytm.track[i].rotation)
      screen.move(120, i*12 + 20)
      screen.text_center(rytm.track[i].pad_offset)

      if rytm.track[i].mute then
        screen.level(i == rytm.track_edit and 15 or 2)
        for j = 0,128,6 do
          screen.move(j, i*12 + 20)
          screen.text("-")
        end
      end

    end

  elseif menu == 9 then
    local focus_arp = arp[page.arp_page_sel]
    screen.move(0,10)
    screen.level(3)
    screen.text("arp")
    local header = {"a","b","c"}
    for i = 1,3 do
      screen.level(page.arp_page_sel == i and 15 or 3)
      screen.move(75+(i*15),10)
      screen.text(header[i])
    end
    screen.level(page.arp_page_sel == page.arp_page_sel and 15 or 3)
    screen.move(75+(page.arp_page_sel*15),13)
    screen.text("_")
    screen.move(100,10)
    screen.move(0,60)
    screen.font_size(15)
    screen.level(15)
    if not key2_hold then
      screen.text((focus_arp.hold and focus_arp.playing) and "hold" or ((focus_arp.hold and not focus_arp.playing) and "pause" or ""))
    elseif #focus_arp.notes > 0 then
      screen.text("K3: CLEAR")
    end
    
    screen.font_size(40)
    screen.move(50,50)
    screen.level(arp[page.arp_page_sel].enabled and 15 or 3)
    screen.text(#focus_arp.notes > 0 and focus_arp.notes[focus_arp.step] or "...")

    screen.font_size(8)
    local deci_to_frac =
    { ["0.125"] = "1/32"
    , ["0.1667"] = "1/16t"
    , ["0.25"] = "1/16"
    , ["0.3333"] = "1/8t"
    , ["0.5"] = "1/8"
    , ["0.6667"] = "1/4t"
    , ["1.0"] = "1/4"
    , ["1.3333"] = "1/2t"
    , ["2.0"] = "1/2"
    , ["2.6667"] = "1t"
    , ["4.0"] = "1"
    }
    screen.move(125,20)
    screen.level(page.arp_param[page.arp_page_sel] == 1 and 15 or 3)
    local banks = {"a","b","c"}
    local pad = tostring(banks[page.arp_page_sel]..bank[page.arp_page_sel].id)
    screen.text_right((arp[page.arp_page_sel].alt and (pad..": ") or "")..deci_to_frac[tostring(util.round(bank[page.arp_page_sel][bank[page.arp_page_sel].id].arp_time, 0.0001))])
    screen.move(125,30)
    screen.level(page.arp_param[page.arp_page_sel] == 2 and 15 or 3)
    screen.text_right(focus_arp.mode)
    screen.move(125,40)
    screen.level(page.arp_param[page.arp_page_sel] == 3 and 15 or 3)
    screen.text_right("s: "..focus_arp.start_point)
    screen.move(125,50)
    screen.level(page.arp_param[page.arp_page_sel] == 4 and 15 or 3)
    screen.text_right("e: "..(focus_arp.end_point > 0 and focus_arp.end_point or "1"))
    screen.move(125,60)
    screen.level(page.arp_param[page.arp_page_sel] == 5 and 15 or 3)
    screen.text_right("retrig: "..(tostring(focus_arp.retrigger) == "true" and "y" or "n"))

  elseif menu == 10 then
    screen.move(0,10)
    screen.level(3)
    screen.text("rnd")
    local header = {"a","b","c"}
    -- screen.move(30,10)
    -- screen.text("E1: sel bank")
    for i = 1,3 do
      screen.level(page.rnd_page == i and 15 or 3)
      screen.move(75+(i*15),10)
      screen.text(header[i])
    end
    screen.level(page.rnd_page == page.rnd_page and 15 or 3)
    screen.move(75+(page.rnd_page*15),13)
    screen.text("_")
    screen.level(3)
    screen.move(0,20)
    if page.rnd_page_section == 1 then
      local some_playing = {}
      some_playing[page.rnd_page] = false
      for j = 1,#rnd.targets do
        if rnd[page.rnd_page][j].playing then
          some_playing[page.rnd_page] = true
          break
        end
      end
      -- screen.text(tostring(some_playing[page.rnd_page]) == "true" and ("K1+K3 to kill all active in "..page.rnd_page) or "")
    end
    screen.level(3)
    screen.level(page.rnd_page_section == 1 and 15 or 3)
    screen.font_size(40)
    screen.move(0,50)
    screen.text(page.rnd_page_sel[page.rnd_page])
    local current = rnd[page.rnd_page][page.rnd_page_sel[page.rnd_page]]
    local edit_line = page.rnd_page_edit[page.rnd_page] -- this is key!
    screen.font_size(8)
    screen.move(0,60)
    screen.text(tostring(current.playing) == "true" and "active" or "")
    screen.level(3)
    screen.move(0,20)
    if page.rnd_page_section == 1 then
      screen.text(tostring(current.playing) == "false" and "E2: sel / K3: edit / K1+K3: run" or "K1+K3: kill / K3: edit / E2: sel")
    elseif page.rnd_page_section == 2 then
      screen.text("E2: nav / E3: mod / K3: <-")
    end
    screen.font_size(8)
    screen.move(30,30)
    screen.level(page.rnd_page_section == 2 and (edit_line == 1 and 15 or 3) or 3)
    screen.text("param: "..current.param)
    screen.move(30,40)
    screen.level(page.rnd_page_section == 2 and (edit_line == 2 and 15 or 3) or 3)
    screen.text("mode: "..current.mode)
    screen.move(30,50)
    screen.level(page.rnd_page_section == 2 and ((edit_line == 3 or edit_line == 4) and 15 or 3) or 3)
    screen.text("clock: ")
    screen.level(page.rnd_page_section == 2 and (edit_line == 3 and 15 or 3) or 3)
    screen.move(55,50)
    screen.text(current.num)
    screen.move_rel(1,0)
    screen.level(page.rnd_page_section == 2 and ((edit_line == 3 or edit_line == 4) and 15 or 3) or 3)
    screen.text("/")
    screen.level(page.rnd_page_section == 2 and (edit_line == 4 and 15 or 3) or 3)
    screen.move_rel(1,0)
    screen.text(current.denom)
    local params_to_mins =
    { ["pan"] = {"min: "..(current.pan_min < 0 and "L " or "R ")..math.abs(current.pan_min)}
    , ["rate"] = {"min: "..current.rate_min}
    , ["rate slew"] = {"min: "..string.format("%.1f",current.rate_slew_min)}
    , ["delay send"] = {""}
    , ["loop"] = {""}
    , ["semitone offset"] = {current.offset_scale:lower()}
    , ["filter tilt"] = {"min: "..string.format("%.2f",current.filter_min)}
    }
    local params_to_maxs = 
    { ["pan"] = {"max: "..(current.pan_max > 0 and "R " or "L ")..math.abs(current.pan_max)}
    , ["rate"] = {"max: "..current.rate_max}
    , ["rate slew"] = {"max: "..string.format("%.1f",current.rate_slew_max)}
    , ["delay send"] = {""}
    , ["loop"] = {""}
    , ["semitone offset"] = {""}
    , ["filter tilt"] = {"max: "..string.format("%.2f",current.filter_max)}
    }
    screen.level(page.rnd_page_section == 2 and (edit_line == 5 and 15 or 3) or 3)
    screen.move(30,60)
    screen.text(params_to_mins[current.param][1])
    screen.move_rel(5,0)
    screen.level(page.rnd_page_section == 2 and (edit_line == 6 and 15 or 3) or 3)
    screen.text(params_to_maxs[current.param][1])
  
  elseif menu == "load screen" then
    screen.level(15)
    screen.move(62,15)
    screen.font_size(10)
    if collection_loaded then
      screen.text_center("loading collection")
      if #selected_coll < 8 then
        screen.font_size(30)
      elseif #selected_coll < 11 then
        screen.font_size(20)
      elseif #selected_coll < 14 then
        screen.font_size(15)
      else
        screen.font_size(10)
      end
      screen.move(62,43)
      screen.text_center(selected_coll)
      screen.font_size(15)
      screen.move(62,60)
      screen.text_center(dots)
      screen.font_size(8)
    end
  elseif menu == "default load screen" then
    -- if dots == "zilchmo time!" then
    --   screen.font_size(18)
    --   screen.move(62,35)
    -- else
    --   screen.font_size(8)
    --   screen.move(62,30)
    -- end
    -- screen.text_center(dots)
    if dots == "tossin' the dough" then
      for i = 1,4 do
        screen.rect(30+(10*i),42,5,5)
        screen.fill()
      end
    elseif dots == "spreadin' the sauce" then
      for i = 1,4 do
        screen.rect(30+(10*i),42,5,5)
      end
      for i = 1,3 do
        screen.rect(40+(10*i),32,5,5)
      end
      screen.fill()
    elseif dots == "sprinklin' cheese" then
      for i = 1,4 do
        screen.rect(30+(10*i),42,5,5)
      end
      for i = 1,3 do
        screen.rect(40+(10*i),32,5,5)
      end
      for i = 1,2 do
        screen.rect(50+(10*i),22,5,5)
      end
      screen.fill()
    elseif dots == "zilchmo time!" then
      for i = 1,4 do
        screen.rect(30+(10*i),42,5,5)
      end
      for i = 1,3 do
        screen.rect(40+(10*i),32,5,5)
      end
      for i = 1,2 do
        screen.rect(50+(10*i),22,5,5)
      end
      screen.rect(60+(10),12,5,5)
      screen.fill()
    end
    screen.font_size(8)
  elseif menu == "save screen" then
    screen.level(15)
    screen.move(62,43)
    screen.font_size(40)
    screen.text_center("saved!")
    screen.font_size(8)
  elseif menu == "load fail screen" then
    screen.level(15)
    screen.move(62,32)
    screen.font_size(20)
    screen.text_center("no load")
    screen.font_size(8)
  elseif menu == "overwrite screen" then
    screen.level(15)
    screen.move(62,15)
    screen.font_size(10)
    screen.text_center("saving collection")
    screen.font_size(40)
    screen.move(62,50)
    screen.text_center(dots)
    screen.move(62,64)
    screen.font_size(10)
    if dots ~= "saved!" then
      screen.text_center("K3 to cancel")
    end
    screen.font_size(8)
  elseif menu == "delete screen" then
    screen.level(15)
    screen.move(62,15)
    screen.font_size(10)
    screen.text_center("deleting collection")
    screen.font_size(40)
    screen.move(62,50)
    screen.text_center(dots)
    screen.move(62,64)
    screen.font_size(10)
    if dots ~= "deleted!" then
      screen.text_center("K3 to cancel")
    end
    screen.font_size(8)
  elseif menu == "canceled overwrite screen" or menu == "canceled delete screen" then
    screen.level(15)
    screen.move(62,30)
    screen.font_size(20)
    screen.text_center(menu == "canceled overwrite screen" and "overwrite" or "delete")
    screen.move(62,50)
    screen.text_center("canceled")
  elseif menu == "save fail screen" then
    screen.level(15)
    screen.move(62,30)
    screen.font_size(10)
    screen.text_center("error: name is taken")
    screen.move(62,50)
    screen.text_center("will not save")
  elseif menu == "cannot save screen" then
    -- print("shoudl show cannot save menu")
    screen.level(15)
    screen.move(62,30)
    screen.font_size(10)
    screen.text_center("error: bad filename")
    screen.move(62,50)
    screen.text_center("will not save")
    selected_coll = 0
  elseif menu == "MIDI_config" then
    mc.midi_config_redraw(page.midi_bank)
  elseif menu == "macro_config" then
    macros.UI()
  elseif menu == "transport_config" then
    transport.UI()
  else
    screen.move(62,30)
    -- screen.text_center("hi!")
  end
end

function save_screen(text)
  named_savestate(text)
  local file = util.file_exists(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/midi3.data")
  if file then
    menu = "save screen"
    -- screen_dirty = true
    clock.sleep(0.05)
    screen_dirty = true
    clock.sleep(1)
    menu = 1
    screen_dirty = true
    print("saved collection '"..text..'"')
  else
    if not save_fail_state then
      -- print("save screen doesn't know, running from save screen")
      save_fail_state = true
      clock.run(cannot_save_screen,text)
      _norns.key(1,1)
      _norns.key(1,0)
    end
  end
end

function save_fail_screen(text)
  local return_to = menu
  menu = "save fail screen"
  clock.sleep(1)
  menu = return_to
  screen_dirty = true
  _norns.key(1,1)
  _norns.key(1,0)
end

function cannot_save_screen(text)
  print("CANNOT SAVE COLLECTION WITH THAT NAME")
  local return_to = menu
  menu = "cannot save screen"
  _norns.key(1,1)
  _norns.key(1,0)
  screen_dirty = true
  clock.sleep(1)
  menu = return_to
  screen_dirty = true
  _norns.key(1,1)
  _norns.key(1,0)
  
  -- print("got to end of cannot save")
  save_fail_state = false
end

function default_load_screen()
  _norns.key(1,1)
  _norns.key(1,0)
  dots = "tossin' the dough"
  menu = "default load screen"
  clock.sleep(0.5)
  screen_dirty = true
  dots = "spreadin' the sauce"
  screen_dirty = true
  clock.sleep(0.5)
  dots = "sprinklin' cheese"
  screen_dirty = true
  clock.sleep(0.5)
  dots = "zilchmo time!"
  screen_dirty = true
  clock.sleep(0.75)
  menu = 1
  splash_done = true
  screen_dirty = true
end

function load_screen()
  dots = "..."
  menu = "load screen"
  clock.sleep(0.33)
  screen_dirty = true
  dots = ".."
  clock.sleep(0.33)
  screen_dirty = true
  dots = "."
  clock.sleep(0.33)
  screen_dirty = true
  dots = "loaded!"
  clock.sleep(0.75)
  menu = 1
  screen_dirty = true
  if not collection_loaded then
    _norns.key(1,1)
    _norns.key(1,0)
  end
end

function load_fail_screen()
  menu = "load fail screen"
  clock.sleep(1)
  menu = 1
  screen_dirty = true
  if not collection_loaded then
    _norns.key(1,1)
    _norns.key(1,0)
  end
end

function overwrite_screen(text)
  dots = "3"
  menu = "overwrite screen"
  screen_dirty = true
  clock.sleep(0.75)
  screen_dirty = true
  dots = "2"
  clock.sleep(0.75)
  screen_dirty = true
  dots = "1"
  clock.sleep(0.75)
  screen_dirty = true
  dots = "saved!"
  clock.sleep(0.33)
  named_savestate(text)
  menu = 1
  screen_dirty = true
end

function canceled_save()
  menu = "canceled overwrite screen"
  clock.sleep(0.75)
  menu = 1
  screen_dirty = true
end

function delete_screen(text)
  dots = "3"
  menu = "delete screen"
  screen_dirty = true
  clock.sleep(0.75)
  dots = "2"
  screen_dirty = true
  clock.sleep(0.75)
  dots = "1"
  screen_dirty = true
  clock.sleep(0.75)
  dots = "(x_x)"
  screen_dirty = true
  clock.sleep(0.33)
  named_delete(text)
  menu = 1
  screen_dirty = true
end

function canceled_delete()
  menu = "canceled delete screen"
  screen_dirty = true
  clock.sleep(0.75)
  menu = 1
  screen_dirty = true
end

function metronome(x,y,hi,lo)
  local show_me_beats = clock.get_beats() % 4
  local show_me_frac = math.fmod(clock.get_beats(),1)
  if show_me_frac <= 0.25 then
    show_me_frac = 1
  elseif show_me_frac <= 0.5 then
    show_me_frac = 2
  elseif show_me_frac <= 0.75 then
    show_me_frac = 3
  else
    show_me_frac = 4
  end
  if show_me_frac == 1 then
    screen.level(hi)
  else
    screen.level(lo)
  end
  screen.move(x,y)
  if transport.is_running then
    screen.text((math.modf(show_me_beats)+1).."."..show_me_frac)
  else
    screen.text("X.X")
  end
end

return main_menu