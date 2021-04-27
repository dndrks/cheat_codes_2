local rnd_menu = {}

local _r = rnd_menu

function _r.draw_menu()
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
  if not key1_hold then
    if page.rnd_page_section == 1 then
      screen.text(tostring(current.playing) == "false" and "E2: sel / K3: edit / K1+K3: run" or "K1+K3: stop / K3: edit / E2: sel")
    elseif page.rnd_page_section == 2 then
      screen.text("E2: nav / E3: mod / K3: <-")
    end
  else
    screen.text(tostring(current.playing) == "false" and "press K3 to run" or "press K3 to stop")
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
end

function _r.process_encoder(n,d)
  local selected_slot = page.rnd_page_sel[page.rnd_page]

  if n == 1 then
    page.rnd_page = util.clamp(page.rnd_page+d,1,3)
  elseif n == 2 then
    if page.rnd_page_section == 1 and d > 0 then
      page.rnd_page_section = 2
    elseif page.rnd_page_section == 2 then
      if page.rnd_page_edit[page.rnd_page] == 1 and d < 0 then page.rnd_page_section = 1 end
      local current_param = rnd[page.rnd_page][selected_slot].param
      local reasonable_max = (current_param == "semitone offset" and 5) or ((current_param == "loop" or current_param == "delay send") and 4 or 6)
      page.rnd_page_edit[page.rnd_page] = util.clamp(page.rnd_page_edit[page.rnd_page]+d,1,reasonable_max)
    end
  elseif n == 3 then
    local current = rnd[page.rnd_page][page.rnd_page_sel[page.rnd_page]]
    if page.rnd_page_section == 1 then
      page.rnd_page_sel[page.rnd_page] = util.clamp(selected_slot+d,1,#rnd[page.rnd_page])
      page.rnd_page_edit[page.rnd_page] = 1
    elseif page.rnd_page_section == 2 then
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
  end

end

return rnd_menu