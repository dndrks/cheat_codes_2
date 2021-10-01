local flow_menu = {}

local f_m = flow_menu
local bank_names = {"a","b","c"}
local pattern_names = {"arp","grid","euclid"}

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
  _fm_ = page.flow
end

function f_m.draw_menu()
  screen.move(0,15)
  screen.font_size(15)
  screen.level(15)
  screen.text("flow")
  screen.font_size(8)
  for i = 1,#_fm_.pages do
    screen.move(0,20+(10*i))
    screen.level(_fm_.main_sel == i and 15 or (_fm_.menu_layer == 1 and 3 or 1))
    screen.text(_fm_.main_sel == i and (_fm_.menu_layer == 1 and (_fm_.pages[i])) or _fm_.pages[i])
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
        local mode_options = {"low rates", "mid rates", "hi rates", "full range", "keep rates"}
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
    elseif _fm_.main_sel == 3 then
      local mode_options = {"#","A", "P", "E"}
      for i = 1,#mode_options do
        screen.level(15)
        screen.move(64+(16*(i-1)),6)
        screen.text_center(mode_options[i])
      end
      screen.level(3)
      local sel_x = 61+(_arps.index_to_grid_pos(_fm_.song_col[_fm_.bank_sel],4)[1]-1)*16
      local sel_y = 4+(10*util.wrap(_fm_.song_line[_fm_.bank_sel],1,5))
      screen.rect(sel_x,sel_y,7,7)
      screen.fill()
      screen.move(56,10)
      screen.line(128,10)
      screen.stroke()
      local bank_id = _fm_.bank_sel

      local page = _arps.index_to_grid_pos(_fm_.song_line[_fm_.bank_sel],5)[2] - 1 -- only minus 1 cuz of reasons...

      -- local min_max = {{1,20},{21,40},{41,60},{61,80}}
      for i = 1+(20*page), 20+(20*page) do
        screen.move(64+(_arps.index_to_grid_pos(util.wrap(i,1,20),4)[1]-1)*16,10+(10*_arps.index_to_grid_pos(util.wrap(i,1,20),4)[2]))
        screen.level((_fm_.song_col[_fm_.bank_sel] == _arps.index_to_grid_pos(i,4)[1] and _fm_.song_line[_fm_.bank_sel] == _arps.index_to_grid_pos(i,4)[2]) and 0 or 15)
        if _arps.index_to_grid_pos(util.wrap(i,1,20),4)[1] == 1 then
          screen.text_center(song_atoms.bank[bank_id].lane[_arps.index_to_grid_pos(i,4)[2]].beats)
        else
          local target = song_atoms.bank[bank_id].lane[_arps.index_to_grid_pos(i,4)[2]][pattern_names[_arps.index_to_grid_pos(i,4)[1]-1]].target
          screen.text_center(target == 0 and "-" or target)
        end
      end
      screen.level(15)
      if song_atoms.bank[_fm_.bank_sel].current > 5*page and song_atoms.bank[_fm_.bank_sel].current <= 5*(page+1) then
        screen.move(128,10+(10*(song_atoms.bank[_fm_.bank_sel].current - 5*page)))
        screen.text_right("<")
      end
    end
  end
end

function f_m.process_encoder(n,d)
  if _fm_.menu_layer == 1 then
    if n == 2 then
      page.flow.main_sel = util.clamp(page.flow.main_sel + d,1,#_fm_.pages)
    end
  elseif _fm_.menu_layer == 2 then
    if n == 2 then
      page.flow.bank_sel = util.clamp(page.flow.bank_sel + d,1,3)
    end
  elseif _fm_.menu_layer == 3 then
    if _fm_.main_sel == 1 then
      if n == 2 then
        _fm_.pads_page_sel = util.clamp(_fm_.pads_page_sel + d,1,4)
      end
    elseif _fm_.main_sel == 3 then
      if n == 1 then
        _fm_.song_line[_fm_.bank_sel] = util.clamp(_fm_.song_line[_fm_.bank_sel] + d,1,song_atoms.bank[_fm_.bank_sel].end_point)
      elseif n == 2 then
        _fm_.song_col[_fm_.bank_sel] = util.clamp(_fm_.song_col[_fm_.bank_sel] + d,1,4)
      elseif n == 3 then
        if _fm_.song_col[_fm_.bank_sel] == 1 then
          song_atoms.bank[_fm_.bank_sel].lane[_fm_.song_line[_fm_.bank_sel]].beats = util.clamp(song_atoms.bank[_fm_.bank_sel].lane[_fm_.song_line[_fm_.bank_sel]].beats + d,1,128)
        else
          song_atoms.bank[_fm_.bank_sel].lane[_fm_.song_line[_fm_.bank_sel]][pattern_names[_fm_.song_col[_fm_.bank_sel]-1]].target = util.clamp(song_atoms.bank[_fm_.bank_sel].lane[_fm_.song_line[_fm_.bank_sel]][pattern_names[_fm_.song_col[_fm_.bank_sel]-1]].target + d,0,8)
        end
      end
    end
  end
end

function f_m.process_key(n,z)
  if n == 3 and z == 1 then
    if _fm_.menu_layer == 1 then
      _fm_.menu_layer = 2
    elseif _fm_.menu_layer == 2 then
      _fm_.menu_layer = 3
    end
  elseif n == 2 and z == 1 then
    if _fm_.menu_layer == 1 then
      menu = 1
    elseif _fm_.menu_layer == 2 then
      _fm_.menu_layer = 1
    elseif _fm_.menu_layer == 3 then
      _fm_.menu_layer = 2
    end
  end
end

return flow_menu