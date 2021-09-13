local loops_menu = {}

local _loops = loops_menu

local focused_pad = {nil,nil,nil}
local _loops_;

local import_sides = {"[LEFT CH]","[RIGHT CH]","[FOLDER]"}
for j = 1,16 do
  table.insert(import_sides,"[PAD: "..tostring(j).."]")
end

function _loops.init()
  page.loops = {}
  page.loops.layer = "global" -- "global" or "clip" or "record"
  page.loops.bank_controls = {"cheat_pad","start_point","end_point","rate","semitone","cent","glide","buffer","loop_state","auto_chop","stretch_mode","stretch_step","stretch_duration","stretch_fade"}
  page.loops.selected_bank_control = "cheat_pad"
  page.loops.live_controls = {"segment","start_point","end_point","record","feedback","mode","duration","erase","random_rec"}
  page.loops.selected_live_control = "segment"
  page.loops.selected_clip_control = 1
  page.loops.sel = 1
  page.loops.alt_view = false
  page.loops.alt_view_sel = 1
  page.loops.meta_pad = {1,1,1}
  page.loops.zoomed_mode = false
  page.loops.frame = 1
  page.loops.meta_control = false
  page.loops.meta_sel = 1
  page.loops.dough_stretch = {}
  page.loops.dough_stretch.controls = {"mode","step","dur","fade"}
  page.loops.dough_stretch.selected_control = "mode"
  _loops_ = page.loops
end

function _loops.process_key(n,z)
  local pad = bank[util.clamp(page.loops.sel,1,3)][page.loops.meta_pad[util.clamp(1,3,page.loops.sel)]]
  if n == 1 then
    key1_hold = z == 1 and true or false
  elseif n == 2 and z == 1 and key1_hold then
    if page.loops.sel < 4 then
      if #arc_pat[page.loops.sel][1].event > 0 then
        arc_pat[page.loops.sel][1]:clear()
      end
    end
  elseif n == 2 and z == 1 and not key1_hold then
    key2_hold_counter:start()
    key2_hold_and_modify = false
  elseif n == 2 and z == 0 and not key1_hold then
    if key2_hold == false and not key1_hold then
      key2_hold_counter:stop()
      if page.loops.layer == "global" then
        menu = 1
      else
        page.loops.layer = "global"
      end
    elseif key2_hold_and_modify then
      key2_hold = false
      key2_hold_and_modify = false
    elseif not key2_hold_and_modify then
      key2_hold = false
      key2_hold_and_modify = false
    end
    if page.loops.sel < 5 then
      local mode = pad.mode
      local min =
        { live[pad.clip].min
        , clip[pad.clip].min
        }
      local max =
        { live[pad.clip].max
        , clip[pad.clip].max
        }
      page.loops.zoomed_mode = false
      update_waveform(mode,min[mode],max[mode],128)
    end
  elseif n == 3 and z == 1 and not key1_hold then
    if page.loops.sel < 4 then
      if page.loops.selected_bank_control == "cheat_pad"
      or page.loops.selected_bank_control == "start_point"
      or page.loops.selected_bank_control == "end_point"
      then
        bank[page.loops.sel].id = pad.pad_id
        cheat(page.loops.sel,pad.pad_id)
      elseif page.loops.selected_bank_control == "rate" then
        pad.rate = pad.rate * -1
        if pad.pause == false and bank[page.loops.sel].id == pad.pad_id then
          -- softcut.rate(page.loops.sel+1, pad.rate*pad.offset)
          softcut.rate(page.loops.sel+1, pad.rate*_loops.get_total_pitch_offset(page.loops.sel,pad.pad_id))
        end
      elseif page.loops.selected_bank_control == "auto_chop" then
        for i = 1,16 do
          rightangleslice.start_end_default(bank[page.loops.sel][i])
          if i == pad.pad_id and pad.pause == false and bank[page.loops.sel].id == pad.pad_id then
            rightangleslice.sc.start_end(pad,pad.bank_id)
          end
        end
      end
    elseif page.loops.sel == 4 then
      if page.loops.selected_live_control == "record" then
        if rec[rec.focus].loop == 0 and params:string("one_shot_clock_div") == "threshold" and not grid_alt then
          _ca.threshold_rec_handler()
        else
          _ca.toggle_buffer(rec.focus)
        end
      elseif page.loops.selected_live_control == "erase" then
        _ca.buff_flush()
      end
    elseif page.loops.sel == 5 then
      _norns.key(1,1)
      _norns.key(1,0)
      -- fileselect.enter(_path.audio,function(x) _ca.sample_callback(x,page.loops.selected_clip_control) end)
      if clip[page.loops.selected_clip_control].channel == 3 then
        fileselect.enter(_path.audio,function(x) _ca.folder_callback(x,page.loops.selected_clip_control) end)
      elseif clip[page.loops.selected_clip_control].channel < 3 then
        fileselect.enter(_path.audio,function(x) _ca.sample_callback(x,page.loops.selected_clip_control) end)
      else
        fileselect.enter(_path.audio,function(x) _ca.sample_to_pad_callback(x,page.loops.selected_clip_control,clip[page.loops.selected_clip_control].channel-3) end)
      end
      if key2_hold then key2_hold = false end
    elseif page.loops.sel == 6 then
      page.loops.meta_control = not page.loops.meta_control
    end
  elseif n == 3 and z == 1 and key1_hold then
    local sel = page.loops.selected_bank_control
    if page.loops.sel < 4 and tab.key(page.loops.bank_controls,sel) < 4 then
      _dough.toggle(page.loops.sel)
    elseif page.loops.sel < 4 and tab.key(page.loops.bank_controls,sel) > 3 then
      if sel == "rate" then
        _loops.inherit_rate()
      elseif sel == "semitone" then
        _loops.inherit_offset()
      elseif sel == "glide" then
        _loops.inherit_slew()
      elseif sel == "loop_state" then
        _loops.inherit_loop()
      elseif sel == "auto_chop" then
        sync_clock_to_loop(pad,"audio")
      end
    elseif page.loops.sel == 5 then
      if clip[page.loops.selected_clip_control].original_samplerate == 48 then
        sync_clock_to_loop(clip[page.loops.selected_clip_control],"imported_sample")
      end
    end
  end
  screen_dirty = true
end

function _loops.key2_activate()
  _loops.zoomed_draw()
end

function _loops.zoomed_draw()
  if page.loops.sel < 4
  -- and (page.loops.selected_bank_control == "start_point" or page.loops.selected_bank_control == "end_point" or page.loops.selected_bank_control == "cheat_pad")
  then
    page.loops.zoomed_mode = true
    local pad = bank[page.loops.sel][page.loops.meta_pad[page.loops.sel]]
    local mode = pad.mode
    local min = pad.start_point
    local max = pad.end_point
    update_waveform(mode,min,max,128)
  end
end

_loops.get_total_pitch_offset = function(i,j)
  local total_offset;
  total_offset = bank[i][j].new_offset.semitone + (bank[i][j].new_offset.cent/100)
  if bank[i][j].mode == 1 then
    local live_offset = {0,-12,-24,-36}
    total_offset = total_offset + live_offset[params:get("live_buff_rate")]
  end
  return math.pow(0.5, -total_offset / 12)
end

_loops.delta_offset = function(i,j,style,d)
  if style == "semitone" then
    bank[i][j].new_offset[style] = util.clamp(bank[i][j].new_offset[style] + d,-48,48)
  elseif style == "cent" then
    bank[i][j].new_offset[style] = util.clamp(bank[i][j].new_offset[style] + d,-100,100)
  end
end

function _loops.inherit_rate()
  local pad = bank[page.loops.sel][page.loops.meta_pad[page.loops.sel]]
  for i = 1,16 do
    if i ~= pad.pad_id then
      bank[page.loops.sel][i].rate = pad.rate
    end
    if bank[page.loops.sel][i].pause == false and bank[page.loops.sel].id == i then
      -- softcut.rate(page.loops.sel+1, bank[page.loops.sel][i].rate*bank[page.loops.sel][i].offset)
      softcut.rate(page.loops.sel+1, bank[page.loops.sel][i].rate*_loops.get_total_pitch_offset(page.loops.sel,i))
    end
  end
end

function _loops.inherit_offset()
  local pad = bank[page.loops.sel][page.loops.meta_pad[page.loops.sel]]
  for i = 1,16 do
    if i ~= pad.pad_id then
      bank[page.loops.sel][i].offset = pad.offset
    end
    if bank[page.loops.sel].id == i then
      softcut.rate(page.loops.sel+1, bank[page.loops.sel][i].rate*bank[page.loops.sel][i].offset)
    end
  end
end

function _loops.inherit_slew()
  local pad = bank[page.loops.sel][page.loops.meta_pad[page.loops.sel]]
  for i = 1,16 do
    if i ~= pad.pad_id then
      bank[page.loops.sel][i].rate_slew = pad.rate_slew
    end
    if bank[page.loops.sel].id == i then
      softcut.rate_slew_time(page.loops.sel+1,bank[page.loops.sel][i].rate_slew)
    end
  end
end

function _loops.inherit_loop()
  local pad = bank[page.loops.sel][page.loops.meta_pad[page.loops.sel]]
  for i = 1,16 do
    if i ~= pad.pad_id then
      bank[page.loops.sel][i].loop = pad.loop
    end
    if bank[page.loops.sel].id == i then
      softcut.loop(page.loops.sel+1,bank[page.loops.sel][i].loop == true and 1 or 0)
    end
  end
end

function _loops.process_encoder(n,d)
  if not page.loops.meta_control and not page.loops.zoomed_mode then
    if n == 1 then
      page.loops.sel = util.clamp(page.loops.sel+d,1,6)
    elseif n == 2 then
      if page.loops.sel < 5 then
        local ctrls={"bank_controls","bank_controls","bank_controls","live_controls"}
        local sel_ctrl = {"selected_bank_control","selected_bank_control","selected_bank_control","selected_live_control"}
        local current_region = tab.key(page.loops[ctrls[page.loops.sel]], page.loops[sel_ctrl[page.loops.sel]])
        current_region = util.clamp(current_region+d,1,#page.loops[ctrls[page.loops.sel]])
        page.loops[sel_ctrl[page.loops.sel]] = page.loops[ctrls[page.loops.sel]][current_region]
      elseif page.loops.sel == 5 then
        page.loops.selected_clip_control = util.clamp(page.loops.selected_clip_control+d,1,3)
      end
    elseif n == 3 then
      if page.loops.sel < 4 then
        local pad = bank[page.loops.sel][page.loops.meta_pad[page.loops.sel]]
        local resolution = loop_enc_resolution[page.loops.sel]
        if page.loops.selected_bank_control == "cheat_pad" then
          if not key1_hold then
            _loops.change_pad(page.loops.sel,d)
          elseif key1_hold then
            for i = 1,16 do
              _loops.move_loop_points(bank[page.loops.sel][i],d,resolution,"move_play_window")
            end
          end
        elseif page.loops.selected_bank_control == "start_point" then
          if not key1_hold then
            _loops.move_loop_points(pad,d,resolution,"move_start")
          elseif key1_hold then
            for i = 1,16 do
              _loops.move_loop_points(bank[page.loops.sel][i],d,resolution,"move_start")
            end
          end
        elseif page.loops.selected_bank_control == "end_point" then
          if not key1_hold then
            _loops.move_loop_points(pad,d,resolution,"move_end")
          elseif key1_hold then
            for i = 1,16 do
              _loops.move_loop_points(bank[page.loops.sel][i],d,resolution,"move_end")
            end
          end
        elseif page.loops.selected_bank_control == "rate" then
          local rates ={-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
          if pad.fifth then
            pad.fifth = false
          end
          if tab.key(rates,pad.rate) == nil then
            pad.rate = 1
          end
          pad.rate = rates[util.clamp(tab.key(rates,pad.rate)+d,1,#rates)]
          if key1_hold then
            _loops.inherit_rate()
          end
          if pad.pause == false and bank[page.loops.sel].id == pad.pad_id then
            -- softcut.rate(page.loops.sel+1, pad.rate*pad.offset)
            softcut.rate(page.loops.sel+1, pad.rate*_loops.get_total_pitch_offset(page.loops.sel,pad.pad_id))
          end
        elseif page.loops.selected_bank_control == "semitone" then
          -- local current_offset = (math.log(pad.offset)/math.log(0.5))*-12
          -- current_offset = util.clamp(current_offset+d/32,-36,24)
          -- if current_offset > -0.0001 and current_offset < 0.0001 then
          --   current_offset = 0
          -- end
          -- pad.offset = math.pow(0.5, -current_offset / 12)
          -- if key1_hold then
          --   _loops.inherit_offset()
          -- end
          -- if bank[page.loops.sel].id == pad.pad_id then
          --   softcut.rate(page.loops.sel+1, pad.rate*pad.offset)
          -- end
          _loops.delta_offset(page.loops.sel,pad.pad_id,"semitone",d)
          if key1_hold then
            _loops.inherit_offset()
          end
          if bank[page.loops.sel].id == pad.pad_id then
            softcut.rate(page.loops.sel+1, pad.rate*_loops.get_total_pitch_offset(page.loops.sel,pad.pad_id))
          end
        elseif page.loops.selected_bank_control == "cent" then
          _loops.delta_offset(page.loops.sel,pad.pad_id,"cent",d)
          if key1_hold then
            _loops.inherit_offset()
          end
          if bank[page.loops.sel].id == pad.pad_id then
            softcut.rate(page.loops.sel+1, pad.rate*_loops.get_total_pitch_offset(page.loops.sel,pad.pad_id))
          end
        elseif page.loops.selected_bank_control == "glide" then
          pad.rate_slew = util.clamp(pad.rate_slew+d/10,0,4)
          if bank[page.loops.sel].id == pad.pad_id then
            softcut.rate_slew_time(page.loops.sel+1,pad.rate_slew)
          end
          if key1_hold then
            _loops.inherit_slew()
          end
        elseif page.loops.selected_bank_control == "buffer" then
          if not key1_hold then
            if pad.mode == 1 and pad.clip + d > 3 then
              pad.mode = 2
              _ca.change_mode(pad,1)
              -- pad.clip = 1
              _ca.jump_clip(page.loops.sel,pad.pad_id,1)
            elseif pad.mode == 2 and pad.clip + d < 1 then
              pad.mode = 1
              _ca.change_mode(pad,2)
              -- pad.clip = 3
              _ca.jump_clip(page.loops.sel,pad.pad_id,3)
            else
              local tryit = util.clamp(pad.clip+d,1,3)
              _ca.jump_clip(page.loops.sel,pad.pad_id,tryit)
            end
            for i = 1,16 do
              if i ~= pad.pad_id then
                if pad.mode ~= bank[page.loops.sel][i].mode then
                  local old_mode = bank[page.loops.sel][i].mode
                  bank[page.loops.sel][i].mode = bank[page.loops.sel][pad.pad_id].mode
                  _ca.change_mode(bank[page.loops.sel][i],old_mode)
                end
                _ca.jump_clip(page.loops.sel,i,bank[page.loops.sel][pad.pad_id].clip)
              end
            end
            if bank[page.loops.sel].id == pad.pad_id then
              if pad.loop then
                cheat(page.loops.sel,pad.pad_id)
              end
            end
          elseif key1_hold then
            _ca.SOS_toggle(page.loops.sel)
          end
          grid_dirty = true
        elseif page.loops.selected_bank_control == "loop_state" then
          if d > 0 and not pad.loop then
            pad.loop = true
          elseif d < 0 and pad.loop then
            pad.loop = false
          end
          grid_dirty = true
          if key1_hold then
            _loops.inherit_loop()
          end
          if bank[page.loops.sel].id == pad.pad_id then
            softcut.loop(page.loops.sel+1,pad.loop == true and 1 or 0)
          end
        elseif page.loops.selected_bank_control == "stretch_mode" then
          params:delta("doughstretch_mode_"..page.loops.sel,d)
        elseif page.loops.selected_bank_control == "stretch_step" then
          params:delta("doughstretch_step_"..page.loops.sel,d)
        elseif page.loops.selected_bank_control == "stretch_duration" then
          params:delta("doughstretch_duration_"..page.loops.sel,d)
        elseif page.loops.selected_bank_control == "stretch_fade" then
          params:delta("doughstretch_fade_"..page.loops.sel,d)
        end
      elseif page.loops.sel == 4 then
        if page.loops.selected_live_control == "segment" then
          encoder_actions.change_buffer(rec[rec.focus],d)
        elseif page.loops.selected_live_control == "start_point" then
          encoder_actions.move_rec_start(d)
        elseif page.loops.selected_live_control == "end_point" then
          encoder_actions.move_rec_end(d)
        elseif page.loops.selected_live_control == "feedback" then
          params:delta("live_rec_feedback_"..rec.focus,d)
        elseif page.loops.selected_live_control == "mode" then
          params:delta("rec_loop_"..rec.focus,d)
        elseif page.loops.selected_live_control == "duration" then
          params:delta("live_buff_rate",d)
        elseif page.loops.selected_live_control == "random_rec" then
          params:delta("random_rec_clock_prob_"..rec.focus,d)
        end
      elseif page.loops.sel == 5 then
        clip[page.loops.selected_clip_control].channel =
          util.clamp(clip[page.loops.selected_clip_control].channel+d,1,19)
      end
    end
  elseif not page.loops.meta_control and page.loops.zoomed_mode then
    local resolution = loop_enc_resolution[page.loops.sel] * 10
    local pad = bank[page.loops.sel][page.loops.meta_pad[page.loops.sel]]
    if n == 1 then
      _loops.move_loop_points(pad,d,resolution,"move_play_window")
    elseif n == 2 then
      _loops.move_loop_points(pad,d,resolution,"move_start")
    elseif n == 3 then
      _loops.move_loop_points(pad,d,resolution,"move_end")
    end
  elseif page.loops.meta_control then
    if n == 1 then
      if key1_hold and not key2_hold then
        if page.loops.meta_sel < 4 then
          encoder_actions.change_pad(page.loops.meta_sel,d)
        elseif page.loops.meta_sel == 4 then
          rec.focus = util.clamp(rec.focus + d,1,3)
        end
        grid_dirty = true
      elseif not key1_hold and not key2_hold then
        page.loops.meta_sel = util.clamp(page.loops.meta_sel + d,1,4)
      elseif key2_hold and not key1_hold then
        meta_adjust_loops(d,"move_play_window")
      end
    elseif n == 2 then
      meta_adjust_loops(d,"move_start")
    elseif n == 3 then
      meta_adjust_loops(d,"move_end")
    end
  end
end

function _loops.move_loop_points(pad,d,resolution,style)
  encoder_actions[style](pad,d/resolution)
  if bank[page.loops.sel].id == pad.pad_id then
    encoder_actions.sc[style](page.loops.sel)
  end
  if style == "move_play_window"
  or style == "move_start"
  or style == "move_end"
  and arc_pat[pad.bank_id][1].rec == 1 then
    arc_actions.record(pad.bank_id)
  end
end

function _loops.change_pad(target,delta)
  local pad = bank[target]
  page.loops.meta_pad[target] = util.clamp(page.loops.meta_pad[target] + delta,1,16)
  if menu == 2 and page.loops.sel < 4 and page.loops.zoomed_mode then
    update_waveform(pad[page.loops.meta_pad[target]].mode,pad[page.loops.meta_pad[target]].start_point,pad[page.loops.meta_pad[target]].end_point,128)
  end
  grid_dirty = true
end

function _loops.draw_menu()
  screen.move(0,10)
  screen.level(3)
  screen.text("loops")
  if params:get("visual_metro") == 1 then
    metronome(28,10,15,3)
  end

  local header = {"a","b","c","L","C","#"}
  for i = 1,#header do
    screen.level(page.loops.sel == i and (page.loops.meta_control and 3 or 15) or 3)
    screen.move(35+(i*15),10)
    screen.text_right(header[i])
  end
  screen.level(page.loops.sel == page.loops.sel and (page.loops.meta_control and 3 or 15) or 3)
  screen.move(35+(page.loops.sel*15),13)
  screen.text_right("_")

  if page.loops.layer == "global" then
    if page.loops.sel < 4 then

      local sel = page.loops.selected_bank_control

      local pad = bank[page.loops.sel][page.loops.meta_pad[page.loops.sel]]

      if (key1_hold and (tab.key(page.loops.bank_controls,sel) < 4 or tab.key(page.loops.bank_controls,sel) > 9)) or not key1_hold then

        local loops_to_screen_options = {"a", "b", "c"}
        screen.move(0,31)
        screen.level(sel == "cheat_pad" and 15 or 3)
        screen.text(loops_to_screen_options[page.loops.sel]..""..page.loops.meta_pad[page.loops.sel])
        screen.move(0,41)
        screen.level(3)
        screen.text(":"..bank[page.loops.sel].id)

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
        
        local x_pos;

        local min = page.loops.zoomed_mode and pad.start_point or start_point[pad.mode]
        local max = page.loops.zoomed_mode and pad.end_point or end_point[pad.mode]
        local s_p = util.round(pad.start_point,0.01)
        local e_p = math.modf(pad.end_point*100)/100
        local sp_to_screen = util.linlin(min,max,16,125,s_p)
        local ep_to_screen = util.linlin(min,max,16,125,e_p)

        if #waves > 0  and math.max(table.unpack(waves)) > 0 then
          x_pos = 0
          screen.level(4)
        
          for i,s in ipairs(waves) do
            local height = util.round(math.abs(s) * bank_waveform_scale)
            screen.move(util.linlin(0,128,17,125,x_pos), 28 - height)
            screen.line_rel(0, 2 * height)
            x_pos = x_pos + 1
          end

          screen.stroke()

          x_pos = 0

          screen.level(1)
          for i,s in ipairs(waves) do
            if util.linlin(0,128,17,125,x_pos) < sp_to_screen or util.linlin(0,128,17,125,x_pos) > ep_to_screen then
              local height = util.round(math.abs(s) * bank_waveform_scale)
              screen.move(util.linlin(0,128,17,125,x_pos), 28 - height)
              screen.line_rel(0, 2 * height)
            end
            x_pos = x_pos + 1
          end
          
          screen.stroke()
          
        end

        if (bank[page.loops.sel].focus_hold == false or bank[page.loops.sel].id == bank[page.loops.sel].focus_pad)
          and not playhead_at_endpoint[page.loops.sel]
          then
          local pad_min = page.loops.zoomed_mode and pad.start_point or start_point[pad.mode]
          local pad_max = page.loops.zoomed_mode and pad.end_point or end_point[pad.mode]
          local current_to_screen = util.linlin(pad_min,pad_max,16,125,poll_position_new[page.loops.sel+1])
          if current_to_screen > sp_to_screen and current_to_screen < ep_to_screen then
            screen.level(5)
          else
            screen.level(0)
          end
          screen.move(current_to_screen,19)
          screen.line_rel(0,19)
          screen.stroke()
        end

        screen.level((sel == "start_point" or sel == "window" or page.loops.zoomed_mode) and (#waves > 0 and 3 or 5) or 2)
        screen.move(sp_to_screen,17)
        screen.line_rel(0,23)
        screen.stroke()
        if sel == "start_point" or sel == "window" or page.loops.zoomed_mode then
          screen.level(15)
          screen.pixel(sp_to_screen,16)
          screen.pixel(sp_to_screen+1,15)
          screen.pixel(sp_to_screen+2,14)
          screen.pixel(sp_to_screen,40)
          screen.pixel(sp_to_screen+1,41)
          screen.pixel(sp_to_screen+2,42)
          screen.fill()
        end
        screen.level((sel == "end_point" or sel == "window" or page.loops.zoomed_mode)  and (#waves > 0 and 3 or 5) or 2)
        screen.move(ep_to_screen,17)
        screen.line_rel(0,23)
        screen.stroke()
        if sel == "end_point" or sel == "window" or page.loops.zoomed_mode then
          screen.level(15)
          screen.pixel(ep_to_screen-1,16)
          screen.pixel(ep_to_screen-2,15)
          screen.pixel(ep_to_screen-3,14)
          screen.pixel(ep_to_screen-1,40)
          screen.pixel(ep_to_screen-2,41)
          screen.pixel(ep_to_screen-3,42)
          screen.fill()
        end
      end
      
      screen.level(15)
      screen.move(0,46)
      screen.line(128,46)
      screen.stroke()

      if page.loops.zoomed_mode then
        local off = pad.mode == 1 and live[pad.clip].min or clip[pad.clip].min
        local display_end = pad.mode == 1 and (pad.end_point == 8.99 and 9 or pad.end_point) or pad.end_point
        screen.move(0,54)
        screen.text("start: "..string.format("%.4g",(util.round(pad.start_point,0.0001))-off).."s")
        screen.move(128,54)
        screen.text_right("end: "..string.format("%.4g",(display_end)-off).."s")
        screen.move(64,64)
        screen.text_center("duration: "..string.format("%.2f",pad.end_point-pad.start_point).."s")
        -- screen.text_center("K3: toggle looping, all pads")
        --new//
      elseif not key1_hold or (key1_hold and tab.key(page.loops.bank_controls,sel) > 3) then
        if tab.key(page.loops.bank_controls,page.loops.selected_bank_control) < 11 then
          screen.level(sel == "rate" and 15 or 3)
          screen.move(0,54)
          screen.text(string.format("%.4g",pad.rate).."x")
          screen.level(sel == "semitone" and 15 or 3)
          screen.move(48,54)
          -- screen.text_center((string.format("%.2f",((math.log(pad.offset)/math.log(0.5))*-12))).." st")
          local sign = pad.new_offset.semitone > 0 and "+" or ""
          screen.text_center(sign..pad.new_offset.semitone.." st")
          screen.level(sel == "cent" and 15 or 3)
          screen.move(82,54)
          local sign = pad.new_offset.cent > 0 and "+" or ""
          screen.text_center(sign..pad.new_offset.cent.." ct")
          screen.level(sel == "glide" and 15 or 3)
          screen.move(128,54)
          screen.text_right("~"..string.format("%.1f",pad.rate_slew).."s")
          screen.level(sel == "buffer" and 15 or 3)
          screen.move(0,64)
          screen.text("["..header[page.loops.sel].."] "..(pad.mode == 1 and ("LIVE "..pad.clip) or ("CLIP "..pad.clip)))
          screen.level(sel == "loop_state" and 15 or 3)
          screen.move(64,64)
          screen.text_center(pad.loop == false and "1-SHOT" or "∞")
          screen.level(sel == "auto_chop" and 15 or 3)
          screen.move(128,64)
          screen.text_right("CHOP")
          if key1_hold and tab.key(page.loops.bank_controls,sel) > 3 then
            screen.level(15)
            screen.move(64,25)
            screen.text_center((sel ~= "buffer" and sel ~= "auto_chop") and "K3/E3:" or "K3:")
            local texts =
            {
              ["rate"] = "set all pads to "..string.format("%.4g",pad.rate).."x"
            , ["semitone"] = "offset all pads to "..(string.format("%.2f",((math.log(pad.offset)/math.log(0.5))*-12))).." st"
            , ["glide"] = "set all pitch slews to "..string.format("%.1f",pad.rate_slew).."s"
            , ["buffer"] = (params:get("SOS_enabled_"..page.loops.sel) == 1 and "turn SOS off" or "turn SOS on")
            , ["loop_state"] = "set all pad loops to "..(pad.loop == false and "1-SHOT" or "∞")
            , ["auto_chop"] = "set bpm from pad "..pad.pad_id
            }
            screen.level(15)
            screen.move(64,35)
            if texts[sel] ~= nil then
              screen.text_center(texts[sel])
            end
          end
        else
          local textline_1 = "STRETCH: "..params:string("doughstretch_mode_"..page.loops.sel)
          -- local textline_2 = 
          -- dough_stretch[page.loops.sel].mode == "chi" and "FADE: 1/"..dough_stretch[page.loops.sel].fade_time
          -- or ""
          local textline_2 = "STEP: 1/"..dough_stretch[page.loops.sel].inc
          local textline_3 = "DUR: 1/"..dough_stretch[page.loops.sel].time
          local textline_4 = "FADE: "..(params:get("doughstretch_fade_"..page.loops.sel)/100).."s"
          
          screen.level(sel == "stretch_mode" and 15 or 3)
          screen.move(0,54)
          screen.text(textline_1 ~= nil and textline_1 or "")
          screen.level(sel == "stretch_step" and 15 or 3)
          screen.move(128,54)
          screen.text_right(textline_2 ~= nil and textline_2 or "")
          screen.level(sel == "stretch_duration" and 15 or 3)
          screen.move(0,64)
          screen.text(textline_3 ~= nil and textline_3 or "")
          screen.level(sel == "stretch_fade" and 15 or 3)
          screen.move(128,64)
          screen.text_right(textline_4 ~= nil and textline_4 or "")
        end
        --//new
      elseif key1_hold and tab.key(page.loops.bank_controls,sel) < 4 then
        screen.level(15)
        screen.move(64,54)
        if page.loops.selected_bank_control == "cheat_pad" then
          screen.text_center("E3: delta all pad windows")
        elseif page.loops.selected_bank_control == "start_point" then
          screen.text_center("E3: delta all pad start points")
        elseif page.loops.selected_bank_control == "end_point" then
          screen.text_center("E3: delta all pad end points")
        end
        -- local textline_1 = "STRETCH: "..params:string("doughstretch_mode_"..page.loops.sel)
        -- local textline_2 = 
        -- dough_stretch[page.loops.sel].mode == "chi" and "FADE: 1/"..dough_stretch[page.loops.sel].fade_time
        -- or ""
        -- local textline_3 = "STEP: 1/"..dough_stretch[page.loops.sel].inc
        -- local textline_4 = "DUR: 1/"..dough_stretch[page.loops.sel].time
        
        -- screen.level(sel == "stretch_mode" and 15 or 3)
        -- screen.move(0,54)
        -- screen.text(textline_1 ~= nil and textline_1 or "")
        -- screen.move(128,54)
        -- screen.text_right(textline_2 ~= nil and textline_2 or "")
        -- screen.level(sel == "stretch_step" and 15 or 3)
        -- screen.move(0,64)
        -- screen.text(textline_3 ~= nil and textline_3 or "")
        -- screen.level(sel == "stretch_duration" and 15 or 3)
        -- screen.move(128,64)
        -- screen.text_right(textline_4 ~= nil and textline_4 or "")
      end
        
    elseif page.loops.sel == 4 then
      local sel = page.loops.selected_live_control
      screen.move(0,31)
      screen.level(sel == "segment" and 15 or 3)
      screen.text("L"..rec.focus)
      screen.move(1,23)
      screen.text(rec[rec.focus].queued and "..." or "")

      local waves = rec[rec.focus].waveform_samples
      
      local x_pos = 0

      local min = page.loops.zoomed_mode and rec[rec.focus].start_point or live[rec.focus].min
      local max = page.loops.zoomed_mode and rec[rec.focus].end_point or live[rec.focus].max
      local s_p = util.round(rec[rec.focus].start_point,0.01)
      local e_p = math.modf(rec[rec.focus].end_point*100)/100
      local sp_to_screen = util.linlin(min,max,16,125,s_p)
      local ep_to_screen = util.linlin(min,max,16,125,e_p)

      if #waves > 0  and math.max(table.unpack(waves)) > 0 then
        x_pos = 0
        screen.level(4)
      
        for i,s in ipairs(waves) do
          local height = util.round(math.abs(s) * live_waveform_scale)
          screen.move(util.linlin(0,128,17,125,x_pos), 28 - height)
          screen.line_rel(0, 2 * height)
          x_pos = x_pos + 1
        end

        screen.stroke()

        x_pos = 0
        screen.level(1)

        for i,s in ipairs(waves) do
          if util.linlin(0,128,17,125,x_pos) < sp_to_screen or util.linlin(0,128,17,125,x_pos) > ep_to_screen then
            local height = util.round(math.abs(s) * live_waveform_scale)
            screen.move(util.linlin(0,128,17,125,x_pos), 28 - height)
            screen.line_rel(0, 2 * height)
          end
          x_pos = x_pos + 1
        end
        
        screen.stroke()
      end

      --then, we move onto loop point drawing:

      if poll_position_new[1] >= rec[rec.focus].start_point and poll_position_new[1] <= rec[rec.focus].end_point then
        local current_to_screen = util.linlin(min,max,16,125,poll_position_new[1])
        if current_to_screen > sp_to_screen and current_to_screen < ep_to_screen then
          screen.level(5)
        else
          screen.level(0)
        end
        screen.move(current_to_screen,19)
        screen.line_rel(0,19)
        screen.text(rec[rec.focus].state == 1 and ">" or "")
        screen.stroke()
      end
      screen.level(15)
      screen.move(0,46)
      screen.line(128,46)
      screen.stroke()

      screen.level((sel == "start_point" or sel == "window" or page.loops.zoomed_mode) and (#waves > 0 and 3 or 5) or 2)
      screen.move(sp_to_screen,17)
      screen.line_rel(0,23)
      screen.stroke()
      if sel == "start_point" or sel == "window" or page.loops.zoomed_mode then
        screen.level(15)
        screen.pixel(sp_to_screen,16)
        screen.pixel(sp_to_screen+1,15)
        screen.pixel(sp_to_screen+2,14)
        screen.pixel(sp_to_screen,40)
        screen.pixel(sp_to_screen+1,41)
        screen.pixel(sp_to_screen+2,42)
        screen.fill()
      end
      screen.level((sel == "end_point" or sel == "window" or page.loops.zoomed_mode)  and (#waves > 0 and 3 or 5) or 2)
      screen.move(ep_to_screen,17)
      screen.line_rel(0,23)
      screen.stroke()
      if sel == "end_point" or sel == "window" or page.loops.zoomed_mode then
        screen.level(15)
        screen.pixel(ep_to_screen-1,16)
        screen.pixel(ep_to_screen-2,15)
        screen.pixel(ep_to_screen-3,14)
        screen.pixel(ep_to_screen-1,40)
        screen.pixel(ep_to_screen-2,41)
        screen.pixel(ep_to_screen-3,42)
        screen.fill()
      end
      
      -- then, loop controls:

      -- {"segment","start_point","end_point","feedback","duration","random_rec","record","mode"}
      screen.level(sel == "record" and 15 or 3)
      screen.move(0,54)
      screen.text(rec[rec.focus].state == 1 and "turn rec off" or "turn rec on")

      screen.level(sel == "feedback" and 15 or 3)
      screen.move(58,54)
      screen.text(string.format("%0.f",params:get("live_rec_feedback_"..rec.focus)*100).."%")

      local rec_mode = params:get("rec_loop_"..rec.focus) == 1 and "∞"
      or (params:get("one_shot_clock_div") == 4 and "thresh" or "1-shot")
      screen.level(sel == "mode" and 15 or 3)
      -- screen.move(64,54)
      screen.move(96,54)
      screen.text_center(rec_mode)

      screen.level(sel == "duration" and 15 or 3)
      screen.move(128,54)
      screen.text_right(params:string"live_buff_rate")

      screen.level(sel == "erase" and 15 or 3)
      screen.move(0,64)
      screen.text("ERASE LOOP")
      screen.level(sel == "random_rec" and 15 or 3)
      screen.move(128,64)
      screen.text_right("RND: "..params:get("random_rec_clock_prob_"..rec.focus).."%")
      
    elseif page.loops.sel == 5 then
      for i = 1,3 do
        screen.level(page.loops.selected_clip_control == i and 15 or 3)
        screen.move(0,10+(i*10)+(8*(i-1)))
        screen.text("CLIP "..i..": "..("K3: load, E3: "..import_sides[clip[i].channel]))
        screen.level(page.loops.selected_clip_control == i and 8 or 3)
        screen.move(0,18+(i*10)+(8*(i-1)))
        if params:get("clip "..i.." sample") == "-" and not clip[i].collage then
          screen.text("(no clip loaded)")
        elseif params:get("clip "..i.." sample") == "-" and clip[i].collage then
          screen.text("collaged audio")
        elseif params:get("clip "..i.." sample") ~= "-" and clip[i].collage then
          screen.text("collaged audio")
        elseif params:get("clip "..i.." sample") ~= "-" and not clip[i].collage then
          screen.text(params:get("clip "..i.." sample"):match("^.+/(.+)$"))
        end
        -- if clip[i].channel ~= 3 then
        -- local text_to_display = params:get("clip "..i.." sample") == "-"
        -- and ("K3: load, E3: "..import_sides[clip[i].channel])
        -- or params:get("clip "..i.." sample"):match("^.+/(.+)$")
        -- screen.text("CLIP "..i..": "..text_to_display)
        -- end
      end
      if key1_hold and params:get("clip "..page.loops.selected_clip_control.." sample") ~= "-" then
        screen.level(8)
        screen.rect(0,14,128,7)
        screen.fill()
        screen.level(0)
        screen.move(2,20)
        screen.text("SR: "..
        string.format("%.4g",clip[page.loops.selected_clip_control].original_samplerate)
        .."khz"
        )
        local chs = {"L","R"}
        screen.move(64,20)
        screen.text_center("CH: "..chs[clip[page.loops.selected_clip_control].channel])
        screen.move(126,20)
        screen.text_right("BPM: "..clip[page.loops.selected_clip_control].original_bpm)
        if clip[page.loops.selected_clip_control].original_samplerate == 48 then
          screen.level(8)
          screen.rect(0,54,128,7)
          screen.fill()
          screen.level(0)
          screen.move(64,60)
          screen.text_center("K3: set project BPM to "..clip[page.loops.selected_clip_control].original_bpm)
        else
          screen.level(8)
          screen.rect(0,54,128,7)
          screen.fill()
          screen.level(0)
          screen.move(64,60)
          screen.text_center("sample rate is not 48khz :(")
        end
      end
    elseif page.loops.sel == 6 then
      for i = 1,4 do
        local id;
        local options;
        screen.line_width(1)
        if i < 4 then
          if bank[i].focus_hold then
            id = bank[i].focus_pad
          elseif not page.loops.meta_control then
            id = bank[i].id
          elseif page.loops.meta_control then
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

          local off = bank[i][id].mode == 1 and clip[bank[i][id].clip].min or clip[bank[i][id].clip].min
          local display_end = bank[i][id].mode == 1 and (bank[i][id].end_point == 8.99 and 9 or bank[i][id].end_point) or bank[i][id].end_point


          screen.level(page.loops.meta_control and (page.loops.meta_sel == i and 15 or 3) or 3)
          screen.move(15,8+(i*14))
          screen.line(115,8+(i*14))
          screen.close()
          screen.stroke()
          local duration = bank[i][id].mode == 1 and 32 or clip[bank[i][id].clip].sample_length
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
          local off = ((id-1)*32)+1
          local mults = {1,2,4,8}
          local mult = mults[params:get("live_buff_rate")]
          
          local min = live[rec.focus].min
          local max = live[rec.focus].max
          local s_p = util.round(rec[rec.focus].start_point,0.01)
          local e_p = math.modf(rec[rec.focus].end_point*100)/100
          local sp_to_screen = util.linlin(min,max,15,115,s_p)
          local ep_to_screen = util.linlin(min,max,15,115,e_p)
          screen.level(page.loops.meta_control and (page.loops.meta_sel == i and 15 or 3) or 3)
          screen.move(sp_to_screen,64)
          screen.text("|")
          screen.move(ep_to_screen,64)
          screen.text("|")
          screen.stroke()

          if poll_position_new[1] >= rec[rec.focus].start_point and poll_position_new[1] <= rec[rec.focus].end_point then
            local current_to_screen = util.linlin(min,max,15,115,poll_position_new[1])
            screen.level(page.loops.meta_control and (page.loops.meta_sel == i and 15 or 3) or 3)
            screen.move(current_to_screen,64)
            screen.text(rec[rec.focus].state == 1 and ">" or "||")
            screen.stroke()
          end
        end

        screen.move(0,8+(i*14))
        screen.level(page.loops.meta_control and (page.loops.meta_sel == i and 15 or 3) or 3)
        local loops_to_screen_options = {"a", "b", "c", "L"}
        screen.text(loops_to_screen_options[i]..""..id)

        if i < 4 then
          if (bank[i].focus_hold) or (page.loops.meta_control and key1_hold and page.loops.meta_sel == i and (grid_pat[i].play == 1 or midi_pat[i].play == 1 or arp[i].playing or rytm.track[i].k ~= 0)) then
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

      end
    end
  end
end

return loops_menu