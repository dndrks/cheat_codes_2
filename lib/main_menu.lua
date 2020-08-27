local main_menu = {}

local dots = "."

function main_menu.init()
  if menu == 1 then
    screen.move(0,10)
    screen.text("cheat codes")
    screen.move(10,30)
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
      , " ?"
      }
      screen.text(page.main_sel == i and (">"..options[i]) or options[i])
    end
    screen.move(128,10)
    screen.level(3)
    local target = midi_dev[params:get("midi_control_device")]
    if target.device ~= nil and target.device.port == params:get("midi_control_device") and params:get("midi_control_enabled") == 2 then
      screen.text_right("("..util.trim_string_to_width(target.device.name,70)..")")
    elseif target.device == nil and params:get("midi_control_enabled") == 2 then
      screen.text_right("no midi device!")
    end
  elseif menu == 2 then

    screen.move(0,10)
    screen.level(3)
    screen.text("loops")
    local bank_rate = {}
    for i = 1,3 do
      bank_rate[i] = string.format("%.4g",bank[i][bank[i].id].rate)
    end
    screen.move(120,10)
    screen.text_right(bank_rate[1].."x | "..bank_rate[2].."x | "..bank_rate[3].."x")

    for i = 1,3 do
      local which_pad = nil
      screen.line_width(1)
      if bank[i].focus_hold == false then
        which_pad = bank[i].id
      else
        which_pad = bank[i].focus_pad
      end
      screen.move(0,8+(i*14))
      screen.level(page.loops_sel == i and 15 or 3)

      -- local loops_to_screen_options = {"a", "b", "c"}
      -- screen.text(loops_to_screen_options[i]..""..which_pad)

      if grid.alt == 0 then
        local loops_to_screen_options = {"a", "b", "c"}
        screen.text(loops_to_screen_options[i]..""..which_pad)
      else
        local loops_to_screen_options = {"(a)","(b)","(c)"}
        screen.text(loops_to_screen_options[i])
      end


      if page.loops_view[i] == 1 then
        screen.move(15,8+(i*14))
        screen.line(120,8+(i*14))
        screen.close()
        screen.stroke()
        if bank[i].focus_hold == false then
          which_pad = bank[i].id
        else
          which_pad = bank[i].focus_pad
        end
        screen.level(page.loops_sel == i and 15 or 3)
        local duration = bank[i][which_pad].mode == 1 and 8 or clip[bank[i][which_pad].clip].sample_length
        local s_p = bank[i][which_pad].mode == 1 and live[bank[i][which_pad].clip].min or clip[bank[i][which_pad].clip].min
        local e_p = bank[i][which_pad].mode == 1 and live[bank[i][which_pad].clip].max or clip[bank[i][which_pad].clip].max
        local start_to_screen = util.linlin(s_p,e_p,15,120,bank[i][which_pad].start_point)
        screen.move(start_to_screen,21+(14*(i-1)))
        screen.text("|")
        local end_to_screen = util.linlin(s_p,e_p,15,120,bank[i][which_pad].end_point)
        screen.move(end_to_screen,27+(14*(i-1)))
        screen.text("|")
        if bank[i].focus_hold == false or bank[i].id == bank[i].focus_pad then
          local current_to_screen = util.linlin(s_p,e_p,15,120,poll_position_new[i+1])
          screen.move(current_to_screen,24+(14*(i-1)))
          screen.text("|")
        end
      elseif page.loops_view[i] == 2 then

        local id = page.loops_sel
        local focused_pad = nil
        if grid_pat[i].play == 0 and grid_pat[i].tightened_start == 0 and not arp[i].playing and midi_pat[i].play == 0 then
          focused_pad = bank[i].id
        else
          focused_pad = bank[i].focus_pad
        end
        screen.move(0,8+(i*14))
        screen.level(page.loops_sel == i and 15 or 3)
        if grid.alt == 0 then
          local loops_to_screen_options = {"a", "b", "c"}
          screen.text(loops_to_screen_options[i]..""..focused_pad)
        else
          local loops_to_screen_options = {"(a)","(b)","(c)"}
          screen.text(loops_to_screen_options[i])
        end
        screen.move(20,8+(i*14))
        screen.text("rate: "..string.format("%.4g",bank[i][bank[i].id].rate).."x")
        screen.move(75,8+(i*14))
        screen.text("slew: "..string.format("%.1f",bank[i][bank[i].id].rate_slew).."s")

      elseif page.loops_view[i] == 3 then
        screen.move(15,8+(i*14))
        local id = page.loops_sel
        local focused_pad = nil
        -- if grid.alt == 1 then
        --   screen.move(0,20)
        --   screen.level(6)
        --   screen.text("(grid-ALT sets offset for all)")
        -- end
      
        if grid_pat[i].play == 0 and grid_pat[i].tightened_start == 0 and not arp[i].playing and midi_pat[i].play == 0 then
          focused_pad = bank[i].id
        else
          focused_pad = bank[i].focus_pad
        end
        -- if page.loops_sel == i-1 then
        --   if page.loops_sel < 3 and focused_pad == 16 and grid.alt == 0 then
        --     screen.move(0,20)
        --     screen.level(6)
        --     screen.text("(pad 16 overwrites bank!)")
        --   end
        --   if grid_pat[i].play == 1 or grid_pat[i].tightened_start == 1 or arp[i].playing or midi_pat[i].play == 1 then
        --     screen.move(0,10)
        --     screen.level(3)
        --     screen.text("loops: bank "..i.." is pad-locked")
        --   end
        -- end
        screen.move(0,8+(i*14))
        screen.level(page.loops_sel == i and 15 or 3)
        if grid.alt == 0 then
          local loops_to_screen_options = {"a", "b", "c"}
          screen.text(loops_to_screen_options[i]..""..focused_pad)
        else
          local loops_to_screen_options = {"(a)","(b)","(c)"}
          screen.text(loops_to_screen_options[i])
        end
        screen.move(25,8+(i*14))
        screen.text((bank[i][focused_pad].mode == 1 and "Live" or "Clip")..": "..bank[i][focused_pad].clip)
        screen.move(60,8+(i*14))
        screen.text("offset: "..string.format("%.0f",((math.log(bank[i][focused_pad].offset)/math.log(0.5))*-12)).." st")
      end
    end

    screen.level(page.loops_sel == 4 and 15 or 3)
    if page.loops_view[4] == 1 then
      local recording_playhead = util.linlin(1,9,15,120,(poll_position_new[1] - (8*(rec.clip-1))))
      if rec.state == 1 then
        screen.font_size(4)
        screen.move(recording_playhead,62)
        screen.text(">")
        screen.font_size(8)
      elseif rec.state == 0 then
        screen.font_size(8)
        screen.move(recording_playhead,62)
        screen.text_center(".")
        screen.font_size(8)
      end
      local recording_start = util.linlin(1,9,15,120,(rec.start_point - (8*(rec.clip-1))))
      screen.move(recording_start,62)
      screen.text("|")
      local recording_end = util.linlin(1,9,15,120,rec.end_point - (8*(rec.clip-1)))
      screen.move(recording_end,62)
      screen.text("|")
      screen.move(0,62)
      screen.text("L"..rec.clip)
    elseif page.loops_view[4] == 2 then
      screen.move(0,62)
      screen.text("L"..rec.clip)
      screen.move(15,62)
      local rate_options = {"8 s","16 s","32 s"}
      screen.text(rate_options[params:get"live_buff_rate"])
      screen.move(45,62)
      screen.text("offset: "..string.format("%.0f",((math.log(rec.rate_offset)/math.log(0.5))*-12)).." st")
      screen.move(111,62)
      screen.level(3)
      screen.text(string.format("%0.f",util.linlin(rec.start_point-(8*(rec.clip-1)),rec.end_point-(8*(rec.clip-1)),0,100,(poll_position_new[1] - (8*(rec.clip-1))))).."%")
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
      screen.level(level_options[page.levels_sel+1] == "levels" and 15 or 3)
      local level_to_screen_options = {"a", "b", "c"}
      if key1_hold or grid.alt == 1 then
        screen.text("("..level_to_screen_options[i]..")")
      else
        screen.text(level_to_screen_options[i]..""..focused_pad)
      end
      screen.move(35+(20*(i-1)),57)
      local level_to_screen = ((key1_hold or grid.alt == 1) and util.linlin(0,2,0,40,bank[i].global_level) or util.linlin(0,2,0,40,bank[i][focused_pad].level))
      screen.line(35+(20*(i-1)),57-level_to_screen)
      screen.close()
      screen.stroke()
      screen.level(level_options[page.levels_sel+1] == "envelope enable" and 15 or 3)
      screen.move(85,10)
      screen.text("env?")
      screen.move(90+((i-1)*15),20)
      local shapes = {"\\","/","/\\"}
      if bank[i][focused_pad].enveloped then
        screen.text_center(shapes[bank[i][focused_pad].envelope_mode])
      else
        screen.text_center("-")
      end
      screen.level(level_options[page.levels_sel+1] == "loop" and 15 or 3)
      screen.move(90+((i-1)*15),30)
      if bank[i][focused_pad].envelope_loop then
        screen.text_center("∞")
      else
        screen.text_center("-")
      end
      
      screen.level(level_options[page.levels_sel+1] == "time" and 15 or 3)
      -- screen.move(85,30)
      -- screen.text("time")
      screen.move(85,34+((i)*10))
      local envelope_to_screen_options = {"a", "b", "c"}
      if key1_hold or grid.alt == 1 then
        screen.text("("..envelope_to_screen_options[i]..")")
      else
        screen.text(envelope_to_screen_options[i]..""..focused_pad)
      end
      screen.move(105,34+((i)*10))
      if bank[i][focused_pad].enveloped then
        screen.text(string.format("%.2g", bank[i][focused_pad].envelope_time).."s")
      else
        screen.text("---")
      end
    end
    screen.level(3)
    screen.move(0,64)
    screen.text("...")
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
      if key1_hold or grid.alt == 1 then
        screen.text("("..pan_to_screen_options[i]..")")
      else
        screen.text(pan_to_screen_options[i]..""..focused_pad)
      end
    end
    screen.level(3)
    screen.move(0,64)
    screen.text("...")
  elseif menu == 5 then
    screen.move(0,10)
    screen.level(3)
    screen.text("filters")
    
    for i = 1,3 do
      screen.move(17+((i-1)*45),25)
      screen.level(15)
      local filters_to_screen_options = {"a", "b", "c"}
      if key1_hold or grid.alt == 1 then
        screen.text_center(filters_to_screen_options[i]..""..bank[i].id)
      else
        screen.text_center("("..filters_to_screen_options[i]..")")
      end
      screen.move(17+((i-1)*45),35)
      
      screen.level(page.filtering_sel+1 == 1 and 15 or 3)
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
      screen.move(17+((i-1)*45),45)
      screen.level(page.filtering_sel+1 == 2 and 15 or 3)
      local ease_time_to_screen = bank[i][bank[i].id].tilt_ease_time
      screen.text_center(string.format("%.2f",ease_time_to_screen/100).."s")
      screen.move(17+((i-1)*45),55)
      screen.level(page.filtering_sel+1 == 3 and 15 or 3)
      local ease_type_to_screen = bank[i][bank[i].id].tilt_ease_type
      local ease_types = {"cont","jumpy"}
      screen.text_center(ease_types[ease_type_to_screen])
    end
    screen.level(3)
    screen.move(0,64)
    screen.text("...")
  elseif menu == 6 then
    screen.move(0,10)
    screen.level(3)
    screen.text("delays")
    local focused_menu = page.delay[page.delay_focus].menu
    if key1_hold then
      screen.move(128,10)
      if page.delay_section == 3 and focused_menu == 1 then
        if page.delay[page.delay_focus].menu_sel[focused_menu] == 1 or page.delay[page.delay_focus].menu_sel[focused_menu] == 2 then
          screen.text_right(page.delay[page.delay_focus].menu_sel[focused_menu] == 1 and "enc3: fine-tune" or "enc2+3: fine-tune")
        end
      elseif page.delay_section == 3 and focused_menu == 3 then
        if page.delay[page.delay_focus].menu_sel[focused_menu] < 4 then
          screen.text_right("map changes to bank")
        end
      end
    end
    screen.level(page.delay_section == 1 and 15 or 3)
    screen.font_size(40)
    screen.move(0,50)
    screen.text(page.delay_focus == 1 and "L" or "R")
    screen.font_size(8)
    -- local focused_menu = page.delay[page.delay_focus].menu
    local options = {"ctl","flt","mix"}
    for i = 1,3 do
      screen.level((page.delay_section == 2 and focused_menu == i) and 15 or 3)
      screen.move(30+(40*(i-1)),20)
      screen.text(options[i])
    end
    screen.level((page.delay_section == 2 and focused_menu == focused_menu) and 15 or 3)
    screen.move(30+(40*(focused_menu-1)),23)
    screen.line((focused_menu == 3 and 41 or 40)+(40*(focused_menu-1)),23)
    screen.stroke()
    local delay_name = page.delay_focus == 1 and "L" or "R"
    screen.level((page.delay_section == 3 and focused_menu == focused_menu) and 15 or 3)
    local selected = page.delay[page.delay_focus].menu_sel[focused_menu]
    if focused_menu == 1 then
      screen.level((page.delay_section == 3 and selected == 1) and 15 or 3)
      screen.move(30,30)
      screen.text(params:string("delay "..delay_name..": mode"))
      screen.move(75,30)
      if delay[page.delay_focus].mode == "clocked" then
        if delay[page.delay_focus].modifier ~= 1 then
          screen.text(params:string("delay "..delay_name..": div/mult").."*"..string.format("%.4g",delay[page.delay_focus].modifier))
        else
          screen.text(params:string("delay "..delay_name..": div/mult"))
        end
      else
        screen.text(string.format("%.4g",params:get("delay "..delay_name..": free length")).." sec")
      end
      screen.level((page.delay_section == 3 and selected == 2) and 15 or 3)
      screen.move(30,40)
      screen.text("fade: "..string.format("%.4g",params:get("delay "..delay_name..": fade time")))
      screen.move(85,40)
      screen.text("rate: "..string.format("%.4g",params:string("delay "..delay_name..": rate")))
      screen.level((page.delay_section == 3 and selected == 3) and 15 or 3)
      screen.move(30,50)
      screen.text("feedback: "..string.format("%.4g",params:get("delay "..delay_name..": feedback")).."%")
    elseif focused_menu == 2 then
      screen.level((page.delay_section == 3 and selected == 1) and 15 or 3)
      screen.move(30,30)
      screen.text(params:string("delay "..delay_name..": filter cut"))
      screen.move(85,30)
      screen.text("q: "..params:string("delay "..delay_name..": filter q"))
      screen.level((page.delay_section == 3 and selected == 2) and 15 or 3)
      screen.move(30,40)
      screen.text("LP: "..params:string("delay "..delay_name..": filter lp"))
      screen.move(85,40)
      screen.text("HP: "..params:string("delay "..delay_name..": filter hp"))
      screen.level((page.delay_section == 3 and selected == 3) and 15 or 3)
      screen.move(30,50)
      screen.text("BP: "..params:string("delay "..delay_name..": filter bp"))
      screen.move(85,50)
      screen.text("dry: "..params:string("delay "..delay_name..": filter dry"))
    elseif focused_menu == 3 then
      screen.level((page.delay_section == 3 and selected == 1) and 15 or 3)
      screen.move(30,30)
      screen.text("a"..bank[1].id)
      screen.move(50,30)
      screen.text("in: "..string.format("%.1f",(page.delay_focus == 1 and bank[1][bank[1].id].left_delay_level or bank[1][bank[1].id].right_delay_level)))
      screen.move(80,30)
      screen.text("thru: "..(page.delay_focus == 1 and tostring(bank[1][bank[1].id].left_delay_thru) or tostring(bank[1][bank[1].id].right_delay_thru)))
      screen.level((page.delay_section == 3 and selected == 2) and 15 or 3)
      screen.move(30,40)
      screen.text("b"..bank[2].id)
      screen.move(50,40)
      screen.text("in: "..string.format("%.1f",(page.delay_focus == 1 and bank[2][bank[2].id].left_delay_level or bank[2][bank[2].id].right_delay_level)))
      screen.move(80,40)
      screen.text("thru: "..(page.delay_focus == 1 and tostring(bank[2][bank[2].id].left_delay_thru) or tostring(bank[2][bank[2].id].right_delay_thru)))
      screen.level((page.delay_section == 3 and selected == 3) and 15 or 3)
      screen.move(30,50)
      screen.text("c"..bank[3].id)
      screen.move(50,50)
      screen.text("in: "..string.format("%.1f",(page.delay_focus == 1 and bank[3][bank[3].id].left_delay_level or bank[3][bank[3].id].right_delay_level)))
      screen.move(80,50)
      screen.text("thru: "..(page.delay_focus == 1 and tostring(bank[3][bank[3].id].left_delay_thru) or tostring(bank[3][bank[3].id].right_delay_thru)))
      screen.level((page.delay_section == 3 and selected == 4) and 15 or 3)
      screen.move(30,60)
      screen.text("main output level: "..string.format("%.2f", params:get("delay "..delay_name..": global level")))
    end
    screen.level(3)
    screen.move(0,64)
    screen.text("...")
  elseif menu == 7 then
    screen.move(0,10)
    screen.level(3)
    screen.text("timing")
    screen.level(3)
    screen.move(110,10)
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
    screen.text((math.modf(show_me_beats)+1).."."..show_me_frac)
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
      local pattern = g.device ~= nil and grid_pat[i] or midi_pat[i]
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
      local pattern = g.device ~= nil and grid_pat[page_line] or midi_pat[page_line]
      if pattern.sync_hold ~= nil and pattern.sync_hold then
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
        local p_options = {state_option, "shuffle pat","crow output"," ", "rand pat [K3]", "pat start", "pat end"}
        local p_options_rand = {"low rates", "mid rates", "hi rates", "full range", "keep rates"}
        if page.time_scroll[page_line] == 1 then
          for j = 1,3 do
            screen.level(time_page[page_line] == j and 15 or 3)
            screen.move(10,40+(10*(j-1)))
            screen.text(p_options[j])
            local mode_options = {"loose","distro "..string.format("%.4g", pattern.rec_clock_time/4),"quant","quant+trim"}
            local show_state = pattern.play == 1 and pattern.step or mode_options[pattern.playmode]
            local fine_options = {show_state, pattern.count > 0 and pattern.rec == 0 and "[K3]" or "(no pat!)", bank[page_line].crow_execute == 1 and "pads" or "clk"}
            screen.move(80,40+(10*(j-1)))
            screen.text(fine_options[j])
            if bank[page_line].crow_execute ~= 1 then
              screen.move(97,60)
              screen.level(time_page[page_line] == 4 and 15 or 3)
              screen.text("(/"..crow.count_execute[page_line]..")")
            end
          end
        else
          for j = 5,7 do
            screen.level(time_page[page_line] == j and 15 or 3)
            screen.move(10,40+(10*(j-5)))
            screen.text(p_options[j])
            screen.move(80,40+(10*(j-5)))
            local fine_options = {p_options_rand[pattern.random_pitch_range], pattern.count > 0 and pattern.rec == 0 and pattern.start_point or "(no pat!)", pattern.count > 0 and pattern.rec == 0 and pattern.end_point or "(no pat!)"}
            screen.text(fine_options[j-4])
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
    screen.move(0,64)
    screen.text("...")

  elseif menu == 8 then
    screen.move(0,10)
    screen.level(3)
    screen.text("euclid")
    if key1_hold then
      screen.level(15)
      screen.move(40,10)
      local track_edit_to_banks = {"a","b","c"}
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
    end
    local labels = {"(k","n)","o","+/-"}
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
        screen.level((rytm.track[i].pos == x and not rytm.reset) and 15 or 2)
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
    screen.text((focus_arp.hold and focus_arp.playing) and "hold" or ((focus_arp.hold and not focus_arp.playing) and "pause" or ""))
    
    screen.font_size(40)
    screen.move(50,50)
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
    screen.text_right((page.arp_alt[page.arp_page_sel] and (pad..": ") or "")..deci_to_frac[tostring(util.round(focus_arp.time, 0.0001))])
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

  elseif menu == 11 then
    screen.move(0,10)
    screen.level(3)
    screen.text("help")
    if help_menu == "welcome" then
      help_menus.welcome()
    elseif help_menu == "banks" then
      help_menus.banks()
    elseif help_menu == "zilchmo_4" then
      help_menus.zilchmo4()
    elseif help_menu == "zilchmo_3" then
      help_menus.zilchmo3()
    elseif help_menu == "zilchmo_2" then
      help_menus.zilchmo2()
    elseif help_menu == "grid patterns" then
      help_menus.grid_pattern()
    elseif help_menu == "alt" then
      help_menus.alt()
    elseif help_menu == "loop" then
      help_menus.loop()
    elseif help_menu == "mode" then
      help_menus.mode()
    elseif help_menu == "buffer jump" then
      help_menus.buffer_jump()
    elseif help_menu == "buffer switch" then
      help_menus.buffer_switch()
    elseif help_menu == "arc params" then
      help_menus.arc_params()
    elseif help_menu == "arc patterns" then
      help_menus.arc_pattern()
    elseif help_menu == "meta page" then
      help_menus.meta_page()
    elseif help_menu == "meta: slots" then
      help_menus.meta_slots()
    elseif help_menu == "meta: clock" then
      help_menus.meta_clock()
    elseif help_menu == "meta: step" then
      help_menus.meta_step()
    elseif help_menu == "meta: duration" then
      help_menus.meta_duration()
    elseif help_menu == "meta: alt" then
      help_menus.meta_alt()
    elseif help_menu == "meta: toggle" then
      help_menus.meta_toggle()
    elseif help_menu == "meta: loop mod" then
      help_menus.meta_loop_mod()
    end
    screen.level(3)
    screen.move(0,64)
    screen.text("...")
  
  elseif menu == "load screen" then
    screen.level(15)
    screen.move(62,15)
    screen.font_size(10)
    if collection_loaded then
      screen.text_center("loading collection "..selected_coll)
      screen.font_size(40)
      screen.move(62,50)
      screen.text_center(dots)
      screen.font_size(8)
    else
      screen.move(62,40)
      screen.font_size(20)
      screen.text_center("no data!")
      screen.font_size(8)
    end
  elseif menu == "save screen" then
    screen.level(15)
    screen.move(62,15)
    screen.font_size(10)
    screen.text_center("saving collection "..tonumber(string.format("%.0f",params:get("collection"))))
    screen.font_size(40)
    screen.move(62,50)
    screen.text_center(dots)
    screen.move(10,64)
    screen.font_size(10)
    if dots ~= "saved!" then
      screen.text("K2 or K3 to cancel")
    end
    screen.font_size(8)
  elseif menu == "canceled screen" then
    screen.level(15)
    screen.move(62,30)
    screen.font_size(20)
    screen.text_center("save")
    screen.move(62,50)
    screen.text_center("canceled")
  end
end

function load_screen()
  dots = "..."
  menu = "load screen"
  clock.sleep(0.33)
  dots = ".."
  clock.sleep(0.33)
  dots = "."
  clock.sleep(0.33)
  dots = "ready!"
  clock.sleep(0.75)
  menu = 1
  if not collection_loaded then
    _norns.key(1,1)
    _norns.key(1,0)
  end
end

function save_screen()
  dots = "3"
  menu = "save screen"
  clock.sleep(0.75)
  dots = "2"
  clock.sleep(0.75)
  dots = "1"
  clock.sleep(0.75)
  dots = "saved!"
  clock.sleep(0.33)
  savestate()
  menu = 1
end

function canceled_save()
  menu = "canceled screen"
  clock.sleep(0.75)
  menu = 1
end

return main_menu