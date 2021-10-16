local flow_menu = {}

local f_m = flow_menu
local bank_names = {"a","b","c"}
local pattern_names = {"arp","grid","euclid"}
local pattern_banks = {"A","B","C","D","E","F","G","H"}

function f_m.init()
  page.flow = {}
  page.flow.pages = {"PATTERN","SCENES","SONG"}
  page.flow.selected_page = "PADS"
  page.flow.main_sel = 1
  page.flow.menu_layer = 1
  page.flow.bank_sel = 1
  page.flow.pads_page_sel = 1
  page.flow.song_line = {1,1,1}
  page.flow.song_col = {1,1,1}
  page.flow.scene_pad = {1,1,1}
  page.flow.alt = false
  _fm_ = page.flow
end

function f_m.draw_square(x,y)
  for i = 1,16 do
    screen.pixel(x+grid_actions.index_to_grid_pos(i,4)[1],y+grid_actions.index_to_grid_pos(i,4)[2])
  end
end

function f_m.draw_menu()
  screen.move(0,15)
  screen.font_size(15)
  screen.level(15)
  screen.text("flow")
  screen.font_size(8)
  if _fm_.menu_layer == 3 and _fm_.alt and _fm_.main_sel == 3 then
    screen.level(15)
    screen.move(0,30)
    screen.text("K1 + K2:")
    screen.move(0,40)
    screen.text("DELETE")
    screen.move(0,50)
    screen.text("K1 + K3:")
    screen.move(0,60)
    screen.text("DUPLICATE")
  else
    for i = 1,#_fm_.pages do
      screen.move(0,20+(10*i))
      screen.level(_fm_.main_sel == i and 15 or (_fm_.menu_layer == 1 and 3 or 1))
      screen.text(_fm_.main_sel == i and (_fm_.menu_layer == 1 and (_fm_.pages[i])) or _fm_.pages[i])
    end
  end
  if _fm_.menu_layer == 2 then
    for i = 1,3 do
      screen.move(40,20+(10*i))
      screen.level(_fm_.bank_sel == i and 15 or 3)
      screen.text(bank_names[i])
    end
  elseif _fm_.menu_layer == 3 then
    for i = 1,3 do
      screen.move(40,20+(10*i))
      screen.level(_fm_.bank_sel == i and 15 or 1)
      screen.text(bank_names[i])
    end
    screen.level(15)
    screen.move(56,0)
    screen.line(56,64)
    screen.stroke()
    if _fm_.main_sel == 1 then
      if _fm_.pads_page_sel <= 3 then
        screen.move(55,0)
        screen.line(55,32)
        screen.move(57,0)
        screen.line(57,32)
        screen.stroke()
        screen.level(_fm_.pads_page_sel == 1 and 15 or 3)
        screen.move(64,10)
        screen.text("quantization")
        screen.move(128,20)
        screen.text_right(string.upper(params:string("pattern_".._fm_.bank_sel.."_quantization")))
        screen.level(_fm_.pads_page_sel == 2 and 15 or 3)
        screen.move(64,30)
        screen.text("pattern mode")
        screen.move(128,40)
        local mode_options = {"loose","bars: "..string.format("%.4g", grid_pat[_fm_.bank_sel].rec_clock_time/4),"quant","quant+trim"}
        screen.text_right(string.upper(mode_options[grid_pat[_fm_.bank_sel].playmode]))
        screen.level(_fm_.pads_page_sel == 3 and 15 or 3)
        screen.move(64,50)
        screen.text("random style")
        screen.move(128,60)
        local mode_options = {"keep rates","low rates", "mid rates", "hi rates", "full range"}
        screen.text_right(string.upper(mode_options[grid_pat[_fm_.bank_sel].random_pitch_range]))
      elseif _fm_.pads_page_sel <= 6 then
        screen.move(55,32)
        screen.line(55,64)
        screen.move(57,32)
        screen.line(57,64)
        screen.stroke()
        screen.level(_fm_.pads_page_sel == 4 and 15 or 3)
        screen.move(64,10)
        screen.text("length -> bpm")
        screen.move(128,20)
        screen.text_right(string.upper(params:string("sync_clock_to_pattern_".._fm_.bank_sel)))
      end
    elseif _fm_.main_sel == 2 then
      for i = 1,4 do
        for j = 1,4 do
          screen.level(_fm_.scene_pad[_fm_.bank_sel] == (i*j) and 15 or 2)
          f_m.draw_square(58+((j-1)*6),0+((i-1)*6))
          screen.fill()
        end
      end
    elseif _fm_.main_sel == 3 then
      screen.level(15)
      screen.move(60,6)
      screen.text("#")
      screen.move(76,6)
      screen.circle(76,5,2)
      screen.fill()
      screen.move(78,6)
      screen.line(78,0)
      screen.stroke()
      screen.move(95,6)
      screen.text_center("P")
      screen.move(112,6)
      screen.text_center(_fm_.alt and "t" or "S")
      screen.level(3)
      local sel_x = 70+(grid_actions.index_to_grid_pos(_fm_.song_col[_fm_.bank_sel],3)[1]-1)*18
      local sel_y = 4+(10*util.wrap(_fm_.song_line[_fm_.bank_sel],1,5))
      screen.rect(sel_x,sel_y,13,7)
      screen.fill()
      screen.move(56,10)
      screen.line(128,10)
      screen.stroke()
      local bank_id = _fm_.bank_sel

      local page = grid_actions.index_to_grid_pos(_fm_.song_line[_fm_.bank_sel],5)[2] - 1 -- only minus 1 cuz of reasons...

      -- local min_max = {{1,20},{21,40},{41,60},{61,80}}
      for i = 1+(15*page), 15+(15*page) do
        screen.move(76+(grid_actions.index_to_grid_pos(util.wrap(i,1,15),3)[1]-1)*18,10+(10*grid_actions.index_to_grid_pos(util.wrap(i,1,15),3)[2]))
        screen.level((_fm_.song_col[_fm_.bank_sel] == grid_actions.index_to_grid_pos(i,3)[1] and _fm_.song_line[_fm_.bank_sel] == grid_actions.index_to_grid_pos(i,3)[2]) and 0 or 15)
        if grid_actions.index_to_grid_pos(util.wrap(i,1,15),3)[1] == 1 and grid_actions.index_to_grid_pos(i,3)[2] <= song_atoms.bank[bank_id].end_point then
          screen.text_center(song_atoms.bank[bank_id].lane[grid_actions.index_to_grid_pos(i,3)[2]].beats)
          screen.level(15)
          screen.move(60+(grid_actions.index_to_grid_pos(util.wrap(i,1,15),3)[1]-1)*18,10+(10*grid_actions.index_to_grid_pos(util.wrap(i,1,15),3)[2]))
          screen.text(grid_actions.index_to_grid_pos(i,3)[2])
        elseif grid_actions.index_to_grid_pos(util.wrap(i,1,15),3)[1] == 2 and grid_actions.index_to_grid_pos(i,3)[2] <= song_atoms.bank[bank_id].end_point then
        -- elseif grid_actions.index_to_grid_pos(i,3)[2] <= song_atoms.bank[bank_id].end_point then
          local target = song_atoms.bank[bank_id].lane[grid_actions.index_to_grid_pos(i,3)[2]][pattern_names[grid_actions.index_to_grid_pos(i,3)[1]-1]].target
          if target > 0 then
            -- target = (grid_actions.index_to_grid_pos(target,8)[1])
          else
            target = target == 0 and "-" or "xx"
          end
          screen.text_center(target)
        elseif grid_actions.index_to_grid_pos(util.wrap(i,1,15),3)[1] == 3 and grid_actions.index_to_grid_pos(i,3)[2] <= song_atoms.bank[bank_id].end_point then
          if _fm_.alt then
            local target = song_atoms.bank[_fm_.bank_sel].lane[grid_actions.index_to_grid_pos(i,3)[2]].snapshot_restore_mod_index
            if target > 0 then
            else
              target = target == 0 and "-" or "xx"
            end
            screen.text_center(target.."*")
          else
            local target = song_atoms.bank[bank_id].lane[grid_actions.index_to_grid_pos(i,3)[2]]["snapshot"].target
            if target > 0 then
            else
              target = target == 0 and "-" or "xx"
            end
            screen.text_center(target)
          end
        end
      end
      screen.level(15)
      if song_atoms.bank[_fm_.bank_sel].current > 5*page and song_atoms.bank[_fm_.bank_sel].current <= 5*(page+1) then
        screen.move(128,10+(10*(song_atoms.bank[_fm_.bank_sel].current - 5*page)))
        screen.text_right("<")
      end
      if page < grid_actions.index_to_grid_pos(song_atoms.bank[bank_id].end_point,5)[2]-1 then
        screen.move(128,8)
        screen.text_right("▼")
      end
      if page > grid_actions.index_to_grid_pos(song_atoms.bank[bank_id].start_point,5)[2]-1 then
        screen.move(128,4)
        screen.text_right("▲")
      end
    end
  end
end

function f_m.process_encoder(n,d)
  if _fm_.menu_layer == 1 then
    if n == 2 then
      page.flow.main_sel = util.clamp(page.flow.main_sel + d,1,#_fm_.pages)
    end
  -- elseif _fm_.menu_layer == 2 then
  --   if n == 2 then
  --     page.flow.bank_sel = util.clamp(page.flow.bank_sel + d,1,3)
  --   end
  elseif _fm_.menu_layer == 3 then
    if n == 1 then
      page.flow.bank_sel = util.clamp(page.flow.bank_sel + d,1,3)
    end
    if _fm_.main_sel == 1 then
      local pattern = get_grid_connected() and grid_pat[page.flow.bank_sel] or midi_pat[page.flow.bank_sel]
      if n == 2 then
        _fm_.pads_page_sel = util.clamp(_fm_.pads_page_sel + d,1,4)
      elseif n == 3 then
        if _fm_.pads_page_sel == 1 then
          params:delta("pattern_"..page.flow.bank_sel.."_quantization",d)
        elseif _fm_.pads_page_sel == 2 then
          if pattern.rec ~= 1 then
            if not _fm_.alt then
              if pattern.play == 1 then -- actually, we won't want to allow change...
              else
                pattern.playmode = util.clamp(pattern.playmode+d,1,2)
              end
            elseif _fm_.alt and pattern.playmode == 2 then
              key1_hold_and_modify = true
              pattern.rec_clock_time = util.clamp(pattern.rec_clock_time+d,1,64)
            end
          end
        elseif _fm_.pads_page_sel == 3 then
          pattern.random_pitch_range = util.clamp(pattern.random_pitch_range+d,1,5)
        elseif _fm_.pads_page_sel == 4 then
          params:delta("sync_clock_to_pattern_"..page.flow.bank_sel,d)
        end
      end
    elseif _fm_.main_sel == 2 then

    elseif _fm_.main_sel == 3 then
      if n == 1 then
        -- _fm_.song_line[_fm_.bank_sel] = util.clamp(_fm_.song_line[_fm_.bank_sel] + d,1,song_atoms.bank[_fm_.bank_sel].end_point)
      elseif n == 2 then
        if _fm_.song_col[_fm_.bank_sel] == 3 then
          if d > 0 then
            local current_line = _fm_.song_line[_fm_.bank_sel]
            _fm_.song_line[_fm_.bank_sel] = util.clamp(_fm_.song_line[_fm_.bank_sel] + d,1,song_atoms.bank[_fm_.bank_sel].end_point)
            if (_fm_.song_line[_fm_.bank_sel] ~= song_atoms.bank[_fm_.bank_sel].start_point) and (_fm_.song_line[_fm_.bank_sel] ~= song_atoms.bank[_fm_.bank_sel].end_point) then
              _fm_.song_col[_fm_.bank_sel] = 1
            elseif current_line ~= _fm_.song_line[_fm_.bank_sel] then
              _fm_.song_col[_fm_.bank_sel] = 1
            end
          else
            _fm_.song_col[_fm_.bank_sel] = util.clamp(_fm_.song_col[_fm_.bank_sel] + d,1,3)
          end
        elseif _fm_.song_col[_fm_.bank_sel] == 2 then
          _fm_.song_col[_fm_.bank_sel] = util.clamp(_fm_.song_col[_fm_.bank_sel] + d,1,3)
        else
          if d < 0 then
            local current_line = _fm_.song_line[_fm_.bank_sel]
            _fm_.song_line[_fm_.bank_sel] = util.clamp(_fm_.song_line[_fm_.bank_sel] + d,1,song_atoms.bank[_fm_.bank_sel].end_point)
            if (_fm_.song_line[_fm_.bank_sel] ~= song_atoms.bank[_fm_.bank_sel].start_point) and (_fm_.song_line[_fm_.bank_sel] ~= song_atoms.bank[_fm_.bank_sel].end_point) then
              _fm_.song_col[_fm_.bank_sel] = 3
            elseif current_line ~= _fm_.song_line[_fm_.bank_sel] then
              _fm_.song_col[_fm_.bank_sel] = 3
            end
          else
            _fm_.song_col[_fm_.bank_sel] = util.clamp(_fm_.song_col[_fm_.bank_sel] + d,1,3)
          end
        end
      elseif n == 3 then
        if _fm_.song_col[_fm_.bank_sel] == 1 then
          song_atoms.bank[_fm_.bank_sel].lane[_fm_.song_line[_fm_.bank_sel]].beats = util.clamp(song_atoms.bank[_fm_.bank_sel].lane[_fm_.song_line[_fm_.bank_sel]].beats + d,1,128)
        elseif _fm_.song_col[_fm_.bank_sel] == 2 then
          song_atoms.bank[_fm_.bank_sel].lane[_fm_.song_line[_fm_.bank_sel]][pattern_names[_fm_.song_col[_fm_.bank_sel]-1]].target = util.clamp(song_atoms.bank[_fm_.bank_sel].lane[_fm_.song_line[_fm_.bank_sel]][pattern_names[_fm_.song_col[_fm_.bank_sel]-1]].target + d,-1,8)
        elseif _fm_.song_col[_fm_.bank_sel] == 3 then
          if _fm_.alt then
            song_atoms.bank[_fm_.bank_sel].lane[_fm_.song_line[_fm_.bank_sel]].snapshot_restore_mod_index = util.clamp(song_atoms.bank[_fm_.bank_sel].lane[_fm_.song_line[_fm_.bank_sel]].snapshot_restore_mod_index + d, 0,8)
          else
            song_atoms.bank[_fm_.bank_sel].lane[_fm_.song_line[_fm_.bank_sel]].snapshot.target = util.clamp(song_atoms.bank[_fm_.bank_sel].lane[_fm_.song_line[_fm_.bank_sel]].snapshot.target + d,-1,16)
          end
        end
      end
    end
  end
end

function f_m.process_key(n,z)
  if n == 3 and z == 1 then
    if _fm_.menu_layer == 1 then
      _fm_.menu_layer = 3
    elseif _fm_.menu_layer == 3 then
      if _fm_.main_sel == 3 then
        if not _fm_.alt then
          _song.add_line(_fm_.bank_sel,_fm_.song_line[_fm_.bank_sel])
        else
          _song.duplicate_line(_fm_.bank_sel,_fm_.song_line[_fm_.bank_sel])
        end
      end
    end
  elseif n == 2 and z == 1 then
    if _fm_.menu_layer == 1 then
      menu = 1
    elseif _fm_.menu_layer == 3 then
      if not _fm_.alt then
        _fm_.menu_layer = 1
      end
      if _fm_.main_sel == 3 then
        if _fm_.alt then
          _song.remove_line(_fm_.bank_sel,_fm_.song_line[_fm_.bank_sel])
        end
      end
    end
  elseif n == 1 then
    _fm_.alt = z == 1 and true or false
  end
end

return flow_menu