local delays_menu = {}

local _d = delays_menu

function _d.draw_menu()

  -- e1: move between delay,ctl,flt,mix
  -- e2: 

  local options = {"ctl","flt","mix"}
  screen.move(0,10)
  screen.level(3)
  screen.text("delays")
  local focused_menu = page.delay[page.delay.focus].menu
  if key1_hold then
    screen.move(122,10)
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

  screen.level(page.delay.nav == 1 and 15 or 3)
  screen.font_size(40)
  screen.move(0,50)
  screen.text(page.delay.focus == 1 and "L" or "R")
  -- if page.delay.nav == 1 then
  --   screen.level(page.delay.nav == 1 and 15 or 0)
  --   screen.move(2,55)
  --   screen.line(15,55)
  -- end

  screen.move(0,60)
  if page.delay.section == 2 and page.delay.nav > 1 then
    local k = page.delay[page.delay.focus].menu
    local v = page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu]
    if delay_links[del.lookup_prm(k,v)] then
      screen.font_size(8)
      screen.text("linked")
    end
    if key1_hold then
      if (page.delay[page.delay.focus].menu == 2 and page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu] < 7) or page.delay[page.delay.focus].menu ~= 2 then
        screen.font_size(8)
        screen.move(128,10)
        screen.text_right("*")
      end
    end
  elseif page.delay.section == 1 and page.delay.nav > 1 then
    if key1_hold then
      screen.font_size(8)
      if page.delay[page.delay.focus].menu == 1 then
        screen.move(0,60)
        screen.text("K3: toggle all links")
      else
        screen.move(128,10)
        screen.text_right("K3: toggle all links")
      end
    end
  end

  screen.font_size(8)
  for i = 1,3 do
    screen.level(page.delay.nav == i+1 and 15 or 3)
    screen.move(30+(40*(i-1)),20)
    screen.text(options[i])
  end

  if page.delay.nav > 1 then
    screen.level(page.delay.nav == page.delay.nav and 15 or 3)
    screen.move(30+(40*(page.delay.nav-2)),23)
    screen.line((page.delay.nav == 4 and 41 or 40)+(40*(page.delay.nav-2)),23)
    screen.stroke()
  end

  local delay_name = page.delay.focus == 1 and "L" or "R"
  -- screen.level((page.delay.section == 2 and focused_menu == focused_menu) and 15 or 3)
  local selected = page.delay[page.delay.focus].menu_sel[focused_menu]
  
  if focused_menu == 1 then
    screen.level((page.delay.nav== 2 and selected == 1) and 15 or 3)
    screen.move(30,30)
    screen.text(params:string("delay "..delay_name..": mode"))
    screen.move(75,30)
    screen.level((page.delay.nav == 2 and selected == 2) and 15 or 3)
    if delay[page.delay.focus].mode == "clocked" then
      if delay[page.delay.focus].modifier ~= 1 then
        screen.text(params:string("delay "..delay_name..": div/mult").."*"..string.format("%.4g",delay[page.delay.focus].modifier))
      else
        screen.text(params:string("delay "..delay_name..": div/mult"))
      end
    else
      screen.text(string.format("%.4g",params:get("delay "..delay_name..": free length")).." sec")
    end
    screen.level((page.delay.nav == 2 and selected == 3) and 15 or 3)
    screen.move(30,40)
    screen.text("fade: "..string.format("%.4g",params:get("delay "..delay_name..": fade time")))
    screen.level((page.delay.nav == 2 and selected == 4) and 15 or 3)
    screen.move(80,40)
    local rev = delay[page.delay.focus].reverse == true and 1 or 0
    screen.text("rate: "..(rev == 1 and "-" or "")..string.format("%.4g",params:string("delay "..delay_name..": rate")))
    screen.level((page.delay.nav == 2 and selected == 5) and 15 or 3)
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
    screen.level((page.delay.nav == 3 and selected == 1) and 15 or 3)
    screen.move(30,30)
    local current_freq = params:get("delay "..delay_name..": filter cut")
    local modified_freq = easingFunctions[params:string("delay "..delay_name..": curve")](current_freq/12000,10,11990,1)
    local show_freq = (page.delay.nav == 3 and selected > 6) and ("["..string.format("%.6g",modified_freq).." hz".."]") or (string.format("%.6g",modified_freq).." hz")
    screen.text(show_freq)
    screen.level((page.delay.nav == 3 and selected == 2) and 15 or 3)
    screen.move(85,30)
    screen.text("rq: "..params:string("delay "..delay_name..": filter q"))
    screen.level((page.delay.nav == 3 and selected == 3) and 15 or 3)
    screen.move(30,40)
    screen.text("LP: "..params:string("delay "..delay_name..": filter lp"))
    screen.level((page.delay.nav == 3 and selected == 4) and 15 or 3)
    screen.move(85,40)
    screen.text("HP: "..params:string("delay "..delay_name..": filter hp"))
    screen.level((page.delay.nav == 3 and selected == 5) and 15 or 3)
    screen.move(30,50)
    screen.text("BP: "..params:string("delay "..delay_name..": filter bp"))
    screen.level((page.delay.nav == 3 and selected == 6) and 15 or 3)
    screen.move(85,50)
    screen.text("dry: "..params:string("delay "..delay_name..": filter dry"))
    screen.level((page.delay.nav == 3 and selected > 6) and 15 or 3)
    screen.move(28,54)
    screen.line(128,54)
    screen.stroke()
    screen.move(28,64)
    screen.line(128,64)
    screen.stroke()
    screen.move(29,54)
    screen.line(29,64)
    screen.stroke()
    screen.move(128,54)
    screen.line(128,64)
    screen.stroke()
    local x_pos = {53,78,103}
    local stuff_to_display =
    {
      (delay[page.delay.focus].filter_lfo.active == true and "on" or "off"),
      delay[page.delay.focus].filter_lfo.waveform,
      delay[page.delay.focus].filter_lfo.depth,
      params:string("delay "..delay_name..": filter lfo rate")
    }
    for j = 1,#x_pos do
      screen.move(x_pos[j],54)
      screen.line(x_pos[j],64)
      screen.stroke()
    end
    local x_pos = {40,65,90,115}
    for j = 1,4 do
      screen.level((page.delay.nav == 3 and selected == 6+j) and 15 or 3)
      screen.move(x_pos[j],61)
      screen.text_center(stuff_to_display[j])
    end
  
  elseif focused_menu == 3 then
    local bank_names = {"a","b","c"}
    for i = 1,3 do
      screen.level(3)
      screen.move(30,20+(i*10))
      screen.text(bank_names[i]..""..bank[i].id)
      screen.level((page.delay.nav == 4 and selected == (i == 1 and 1 or (i == 2 and 3 or 5))) and 15 or 3)
      screen.move(50,20+(i*10))
      screen.text("in: "..string.format("%.1f",(page.delay.focus == 1 and bank[i][bank[i].id].left_delay_level or bank[i][bank[i].id].right_delay_level)))
      screen.level((page.delay.nav == 4 and selected == (i == 1 and 2 or (i == 2 and 4 or 6))) and 15 or 3)
      screen.move(80,20+(i*10))
      screen.text("thru: "..(page.delay.focus == 1 and tostring(bank[i][bank[i].id].left_delay_thru) or tostring(bank[i][bank[i].id].right_delay_thru)))
    end
    screen.level((page.delay.nav == 4 and selected == 7) and 15 or 3)
    screen.move(30,60)
    screen.text("main output level: "..string.format("%.2f", params:get("delay "..delay_name..": global level")))
  end
end

return delays_menu