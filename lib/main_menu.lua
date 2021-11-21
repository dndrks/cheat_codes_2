local main_menu = {}
_flow = include 'lib/flow'
_arps = include 'lib/_menus/arps'
_d = include 'lib/_menus/delays'
_l = include 'lib/_menus/levels'
_f = include 'lib/_menus/filters'
_loops = include 'lib/_menus/loops'
_rnd = include 'lib/_menus/rnd'

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
        , " flow"
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
    _loops.draw_menu()
    
  elseif menu == 3 then
    _l.draw_menu()
    -- screen.move(0,10)
    -- screen.level(3)
    -- screen.text("levels")
    -- screen.line_width(1)
    -- local level_options = {"levels","envelope enable","loop","time"}
    -- local focused_pad = nil
    -- for i = 1,3 do
    --   if bank[i].focus_hold == true then
    --     focused_pad = bank[i].focus_pad
    --   else
    --     focused_pad = bank[i].id
    --   end
    --   screen.level(3)
    --   screen.move(10,79-(i*20))
    --   local level_markers = {"0 -", "1 -", "2 -"}
    --   screen.text(level_markers[i])
    --   screen.move(10+(i*20),64)
    --   screen.level(level_options[page.levels.sel+1] == "levels" and 15 or 3)
    --   local level_to_screen_options = {"a", "b", "c"}
    --   if key1_hold or grid_alt or bank[i].alt_lock then
    --     screen.text("("..level_to_screen_options[i]..")")
    --   else
    --     screen.text(level_to_screen_options[i]..""..focused_pad)
    --   end
    --   screen.move(35+(20*(i-1)),57)
    --   local level_to_screen = ((key1_hold or grid_alt or bank[i].alt_lock) and util.linlin(0,2,0,40,bank[i].global_level) or util.linlin(0,2,0,40,bank[i][focused_pad].level))
    --   screen.line(35+(20*(i-1)),57-level_to_screen)
    --   screen.close()
    --   screen.stroke()
    --   screen.level(level_options[page.levels.sel+1] == "envelope enable" and 15 or 3)
    --   screen.move(85,10)
    --   screen.text("env?")
    --   screen.move(90+((i-1)*15),20)
    --   local shapes = {"\\","/","/\\"}
    --   if bank[i][focused_pad].enveloped then
    --     screen.text_center(shapes[bank[i][focused_pad].envelope_mode])
    --   else
    --     screen.text_center("-")
    --   end
    --   screen.level(level_options[page.levels.sel+1] == "loop" and 15 or 3)
    --   screen.move(90+((i-1)*15),30)
    --   if bank[i][focused_pad].envelope_loop then
    --     screen.text_center("∞")
    --   else
    --     screen.text_center("-")
    --   end
      
    --   screen.level(level_options[page.levels.sel+1] == "time" and 15 or 3)
    --   -- screen.move(85,30)
    --   -- screen.text("time")
    --   screen.move(85,34+((i)*10))
    --   local envelope_to_screen_options = {"a", "b", "c"}
    --   if key1_hold or grid_alt or bank[i].alt_lock then
    --     screen.text("("..envelope_to_screen_options[i]..")")
    --   else
    --     screen.text(envelope_to_screen_options[i]..""..focused_pad)
    --   end
    --   screen.move(103,34+((i)*10))
    --   if bank[i][focused_pad].enveloped then
    --     screen.text(string.format("%.2g", bank[i][focused_pad].envelope_time).."s")
    --   else
    --     screen.text("---")
    --   end
    -- end
    -- screen.level(3)
    -- screen.move(0,64)
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
    _f.draw_menu()

  elseif menu == 6 then
    _d.draw_menu()
  
  elseif menu == 7 then
    _flow.draw_menu()

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

    end

  elseif menu == 9 then
    _arps.draw_menu()
    -- local focus_arp = arp[page.arp_page_sel]
    -- screen.move(0,10)
    -- screen.level(3)
    -- screen.text("arp")
    -- local header = {"a","b","c"}
    -- for i = 1,3 do
    --   screen.level(page.arp_page_sel == i and 15 or 3)
    --   screen.move(75+(i*15),10)
    --   screen.text(header[i])
    -- end
    -- screen.level(page.arp_page_sel == page.arp_page_sel and 15 or 3)
    -- screen.move(75+(page.arp_page_sel*15),13)
    -- screen.text("_")
    -- screen.move(100,10)
    -- screen.move(0,60)
    -- screen.font_size(15)
    -- screen.level(15)
    -- if not key2_hold then
    --   screen.text((focus_arp.hold and focus_arp.playing) and "hold" or ((focus_arp.hold and not focus_arp.playing) and "pause" or ""))
    -- elseif #focus_arp.notes > 0 then
    --   screen.text("K3: CLEAR")
    -- end
    
    -- screen.font_size(40)
    -- screen.move(50,50)
    -- screen.level(arp[page.arp_page_sel].enabled and 15 or 3)
    -- screen.text(#focus_arp.notes > 0 and focus_arp.notes[focus_arp.step] or "...")

    -- screen.font_size(8)
    -- local deci_to_frac =
    -- { ["0.125"] = "1/32"
    -- , ["0.1667"] = "1/16t"
    -- , ["0.25"] = "1/16"
    -- , ["0.3333"] = "1/8t"
    -- , ["0.5"] = "1/8"
    -- , ["0.6667"] = "1/4t"
    -- , ["1.0"] = "1/4"
    -- , ["1.3333"] = "1/2t"
    -- , ["2.0"] = "1/2"
    -- , ["2.6667"] = "1t"
    -- , ["4.0"] = "1"
    -- }
    -- screen.move(125,20)
    -- screen.level(page.arp_param[page.arp_page_sel] == 1 and 15 or 3)
    -- local banks = {"a","b","c"}
    -- local pad = tostring(banks[page.arp_page_sel]..bank[page.arp_page_sel].id)
    -- -- screen.text_right((page.arp_alt[page.arp_page_sel] and (pad..": ") or "")..deci_to_frac[tostring(util.round(focus_arp.time, 0.0001))])
    -- screen.text_right((page.arp_alt[page.arp_page_sel] and (pad..": ") or "")..deci_to_frac[tostring(util.round(bank[page.arp_page_sel][bank[page.arp_page_sel].id].arp_time, 0.0001))])
    -- screen.move(125,30)
    -- screen.level(page.arp_param[page.arp_page_sel] == 2 and 15 or 3)
    -- screen.text_right(focus_arp.mode)
    -- screen.move(125,40)
    -- screen.level(page.arp_param[page.arp_page_sel] == 3 and 15 or 3)
    -- screen.text_right("s: "..focus_arp.start_point)
    -- screen.move(125,50)
    -- screen.level(page.arp_param[page.arp_page_sel] == 4 and 15 or 3)
    -- screen.text_right("e: "..(focus_arp.end_point > 0 and focus_arp.end_point or "1"))
    -- screen.move(125,60)
    -- screen.level(page.arp_param[page.arp_page_sel] == 5 and 15 or 3)
    -- screen.text_right("retrig: "..(tostring(focus_arp.retrigger) == "true" and "y" or "n"))

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
    screen.text("E2: nav | E3: mod | "..(tostring(current.playing) == "false" and "K1+K3: run" or "K1+K3: kill"))
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
    screen.text_center("name is taken")
    screen.move(62,50)
    screen.text_center("will not save")
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
  menu = "save screen"
  -- screen_dirty = true
  clock.sleep(0.05)
  screen_dirty = true
  clock.sleep(1)
  menu = 1
  screen_dirty = true
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