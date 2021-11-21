local rnd_menu = {}

function rnd_menu.process_key(n,z)
  if n == 3 and z == 1 then
    if key1_hold then
      local rnd_bank = page.rnd_page
      local rnd_slot = page.rnd_page_sel[rnd_bank]
      local state = tostring(rnd[rnd_bank][rnd_slot].playing)
      rnd.transport(rnd_bank,rnd_slot,state == "false" and "on" or "off")
      if state == "true" then
        rnd.restore_default(rnd_bank,rnd_slot)
      end
    else
      page.rnd_page_section = page.rnd_page_section == 1 and 2 or 1
    end
  elseif n == 2 and z == 0 and not key2_hold_and_modify then
    if key1_hold then
      for i = 1,#rnd.targets do
        rnd.transport(page.rnd_page,i,"off")
        rnd.restore_default(page.rnd_page,i)
      end
    else
      menu = 1
    end
  end
end

function rnd_menu.process_encoder(n,d)
  if n == 1 then
    page.rnd_page = util.clamp(page.rnd_page+d,1,3)
  elseif n == 2 then
    local selected_slot = page.rnd_page_sel[page.rnd_page]
    if page.rnd_page_section == 1 then
      if d > 0 then
        page.rnd_page_section = 2
      end
    elseif page.rnd_page_section == 2 then
      local selected_slot = page.rnd_page_sel[page.rnd_page]
      local current_param = rnd[page.rnd_page][selected_slot].param
      local reasonable_max = (current_param == "semitone offset" and 5) or ((current_param == "loop" or current_param == "delay send") and 4 or 6)
      if page.rnd_page_edit[page.rnd_page] == 1 and d < 0 then
        page.rnd_page_section = 1
      end
      page.rnd_page_edit[page.rnd_page] = util.clamp(page.rnd_page_edit[page.rnd_page]+d,1,reasonable_max)
    end
  elseif n == 3 then
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
    elseif page.rnd_page_section == 1 then
      local selected_slot = page.rnd_page_sel[page.rnd_page]
      page.rnd_page_sel[page.rnd_page] = util.clamp(selected_slot+d,1,#rnd[page.rnd_page])
      page.rnd_page_edit[page.rnd_page] = 1
    end
  end
end

return rnd_menu