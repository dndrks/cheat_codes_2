local sd = {}
-- page.time_sel = 1
-- page.time_page = {}
-- page.time_page_sel = {}
-- page.time_scroll = {}
-- for i = 1,6 do
--   page.time_page[i] = 1
--   page.time_page_sel[i] = 1
--   page.time_scroll[i] = 1
-- end
-- page.time_arc_loop = {1,1,1}
-- page.track_sel = {}
-- page.track_page = 1
-- page.track_page_section = {}
-- for i = 1,4 do
--   page.track_sel[i] = 1
--   page.track_page_section[i] = 1
-- end
-- page.track_param_sel = {}
-- for i = 1,3 do
--   page.track_param_sel[i] = 1
-- end

-- ARP
-- page.arps.sel = 1
-- page.arps.param = {1,1,1}
-- page.arps.alt = {false,false,false}
-- page.arps.param_group = {}
-- for i = 1,3 do
--   page.arps.param_group[i] = 1
-- end

-- RND
-- page.rnd_page = 1
-- page.rnd_page_section = 1
-- page.rnd_page_sel = {}
-- page.rnd_page_edit = {}
-- for i = 1,3 do
--   page.rnd_page_sel[i] = 1
--   page.rnd_page_edit[i] = 1
-- end

-- MIDI SETUP
-- page.midi_setup = 1
-- page.midi_focus = "header"
-- page.midi_bank = 1

-- MACROS
-- page.macros = {}
-- page.macros.selected_macro = 1
-- page.macros.section = 1
-- page.macros.param_sel = {}
-- page.macros.edit_focus = {}
-- page.macros.mode = "setup"
-- for i = 1,8 do
--   page.macros.param_sel[i] = 1
--   page.macros.edit_focus[i] = 1
-- end

-- TRANSPORT
-- page.transport = {}
-- page.transport.foci = {"TRANSPORT","TAP-TEMPO"}
-- page.transport.focus = "TRANSPORT"

function sd:init()
  for i = 1,56 do
    self.stored = {}
  end
end

function sd:store(slot,menu)
  self.stored[slot] = deep_copy(menu)
end

function sd:lookup_page_data()
  if target == 2 then
    for k,v in pairs(page.loops) do
      print(k,v)
    end
  end
      -- page.loops.frame = 1
-- page.loops.sel = 1
-- page.loops.meta_sel = 1
-- page.loops.meta_option_set = {1,1,1,1}
-- page.loops.top_option_set = {1,1,1,1}
-- page.loops.focus_hold = {false, false, false, false}
-- page.main_sel = 1
-- page.loops_sel = 1
end

function sd:try_save(menu,slot)
  local stuff = {}
  if menu == 2 then
    stuff["sel"] = page.loops.sel
    stuff["frame"] = page.loops.frame
    stuff["meta_sel"] = page.loops.meta_sel
  elseif menu == 3 then
    stuff["sel"] = page.levels.sel
  elseif menu ==  4 then
  elseif menu == 5 then
    stuff["sel"] = page.filters.sel
  elseif menu == 6 then
    stuff = deep_copy(page.delay)
    -- stuff["section"] = page.delay.section
    -- stuff["focus"] = page.delay.focus
    -- stuff[1]["menu"] = page.delay[1].menu
    -- stuff[2]["menu"] = page.delay[2].menu
    -- stuff[1]["menu_sel"] = deep_copy(page.delay[1].menu_sel)
    -- stuff[2]["menu_sel"] = deep_copy(page.delay[2].menu_sel)
    -- stuff["L menu"] = page.delay[1].menu
    -- stuff["R menu"] = page.delay[2].menu
    -- stuff["L menu_sel"] = deep_copy(page.delay[1].menu_sel)
    -- stuff["R menu_sel"] = deep_copy(page.delay[2].menu_sel)
  elseif menu == 7 then
  end
  stuff["menu"] = menu
  if stuff ~= nil then
    self.stored[slot] = deep_copy(stuff)
  end
end

function sd:try_restore(slot)
  if self.stored[slot].menu == 2 then
    self:translate_data(self.stored[slot],page.loops)
  elseif self.stored[slot].menu == 3 then
    self:translate_data(self.stored[slot],page.levels)
  elseif self.stored[slot].menu == 4 then
    self:translate_data(self.stored[slot],page.pans)
  elseif self.stored[slot].menu == 5 then
    self:translate_data(self.stored[slot],page.filters)
  elseif self.stored[slot].menu == 6 then
    print("this happening?")
    -- self:deep_translate_data(self.stored[slot],page.delay)
    -- page.delay = deep_copy(speed_dial.stored[slot])
  end

end

function sd:translate_data(source,target)
  for k,v in pairs(source) do
    if k ~= "menu" then
      target[k] = v
    else
      menu = v
    end
  end
  screen_dirty = true
end

function sd:deep_translate_data(source,target)
  menu = source.menu
  target = deep_copy(source)
  tab.print(target)
end

return sd