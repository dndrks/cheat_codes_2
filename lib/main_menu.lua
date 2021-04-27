local main_menu = {}

_p = include 'lib/_menus/pans'
_l = include 'lib/_menus/levels'
_r = include 'lib/_menus/rnd'
_f = include 'lib/_menus/filters'
_d = include 'lib/_menus/delays'
_loops = include 'lib/_menus/loops'
_arps = include 'lib/_menus/arps'

local dots = "."

function main_menu.init()
  page = {}
  page.loops = {}
  page.loops.frame = 1
  page.loops.sel = 1
  page.loops.meta_sel = 1
  page.loops.meta_option_set = {1,1,1,1}
  page.loops.top_option_set = {1,1,1,1}
  page.loops.focus_hold = {false, false, false, false}
  page.main_sel = 1
  page.loops_sel = 1
  page.loops_page = 0
  page.loops_view = {4,1,1,1}
  -- page.levels = {}
  -- page.levels.sel = 0
  _l.init()
  _p.init()
  -- page.filters = {}
  -- page.filters.sel = 0
  _f.init()
  _loops.init()
  _arps.init()
  -- page.filtering_sel = 0
  page.arc_sel = 0
  page.delay_sel = 0
  -- page.delay_section = 1
  -- page.delay_focus = 1
  page.delay = {{},{}}
  page.delay.section = 1
  page.delay.focus = 1
  for i = 1,2 do
    page.delay[i].menu = 1
    page.delay[i].menu_sel = {1,1,1}
  end
  page.delay.nav = 2
    
  page.time_sel = 1
  page.time_page = {}
  page.time_page_sel = {}
  page.time_scroll = {}
  for i = 1,6 do
    page.time_page[i] = 1
    page.time_page_sel[i] = 1
    page.time_scroll[i] = 1
  end
  page.time_arc_loop = {1,1,1}
  page.track_sel = {}
  page.track_page = 1
  page.track_page_section = {}
  for i = 1,4 do
    page.track_sel[i] = 1
    page.track_page_section[i] = 1
  end
  page.track_param_sel = {}
  for i = 1,3 do
    page.track_param_sel[i] = 1
  end
  page.rnd_page = 1
  page.rnd_page_section = 1
  page.rnd_page_sel = {}
  page.rnd_page_edit = {}
  for i = 1,3 do
    page.rnd_page_sel[i] = 1
    page.rnd_page_edit[i] = 1
  end
  page.midi_setup = 1
  page.midi_focus = "header"
  page.midi_bank = 1

  macros.UI_init()

  page.transport = {}
  page.transport.foci = {"TRANSPORT","TAP-TEMPO"}
  page.transport.focus = "TRANSPORT"
end

function main_menu.draw()
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
  elseif menu == 4 then
    _p.draw_menu()
  elseif menu == 5 then
    _f.draw_menu()
  elseif menu == 6 then
    _d.draw_menu()
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
      local pattern = get_grid_connected() and grid_pat[i] or midi_pat[i]
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
      -- local pattern = g.device ~= nil and grid_pat[page_line] or midi_pat[page_line]
      local pattern = get_grid_connected() and grid_pat[page_line] or midi_pat[page_line]
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
        local p_options = {state_option, "shuffle pat","P"..page_line.." sets bpm?","rand pat [K3]", "pat start", "pat end", "crow pulse"}
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
              screen.text("(/"..crow.count_execute[page_line]..")")
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
      local show_bottom = page.time_scroll[page_line] < 3 and true or false
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

    end

  elseif menu == 9 then
    _arps.draw_menu()

  elseif menu == 10 then
    _r.draw_menu()

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
  hardware_redraw:start()
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
  zilchmo_animation = nil
end

function load_screen()
  hardware_redraw:start()
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

function main_menu.process_encoder(target,n,d)
  local target_to_destination =
  {
    ["pans"] = _p.process_encoder,
    ["levels"] = _l.process_encoder,
    ["rnd"] = _r.process_encoder,
    ["filters"] = _f.process_encoder,
    ["loops"] = _loops.process_encoder,
    ["arps"] = _arps.process_encoder
  }
  target_to_destination[target](n,d)
end

function main_menu.process_key(target,n,z)
  local target_to_destination =
  {
    ["pans"] = _p.process_key,
    ["levels"] = _l.process_key,
    ["filters"] = _f.process_key,
    ["loops"] = _loops.process_key
  }
  target_to_destination[target](n,z)
end

function main_menu.reset_view(target)
  local target_to_destination =
  {
    ["pans"] = _p.reset_view,
    ["levels"] = _l.reset_view
  }
  target_to_destination[target]()
end

function main_menu.change_pad_focus(b,p)
  page.filters.meta_pad[b] = p
  page.levels.meta_pad[b] = p
  page.pans.meta_pad[b] = p
  page.loops.meta_pad[b] = p
end

return main_menu