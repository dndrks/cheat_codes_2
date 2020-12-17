local Patterning = {}

local function pattern_clock(t)
  while true do
    clock.sync(1/48 * t.playback_rate)
    if t.playing then
      t:advance_tick()
    end
  end
end

function Patterning:new(id)
  local t = setmetatable({}, { 
    __index = Patterning
  })
  -- steps and substeps are more for translating ticks...
  t.step = 1
  t.sub_step = 1
  t.tick = 1 -- ticks are the base counter
  t.total_ticks = (32*4*48) -- default total pattern length is 32 bars at 4/4, 48 ticks per quarter note
  t.start_tick = 1
  t.end_tick = (32*4*48) -- end point should be equal to total ticks...
  t.recording = false
  t.playing = false
  t.overdubbing = false
  t.record_launch_quant = "bar"
  t.loop = true
  t.quantized = false
  t.quantization = "1/4"
  t.playback_rate = 1
  t.dirty = false
  t.event = {}
  t.process = function(_) print("event") end
  return t
end

function Patterning:clear()
  if self.iterator ~= nil then
    clock.cancel(self.iterator)
  end
  self.recording = false
  self.playing = false
  self.overdubbing = false
  self.step = 1
  self.sub_step = 1
  self.tick = 1 -- ticks are the base counter
  self.total_ticks = (32*4*48) -- default total pattern length is 32 bars at 4/4, 48 ticks per quarter note
  self.start_tick = 1
  self.end_tick = 1
  self.recording = false
  self.playing = false
  self.overdubbing = false
  self.record_launch_quant = "bar"
  self.play_launch_quant = "bar"
  self.stop_launch_quant = "none"
  self.loop = true
  self.quantized = false
  self.quantization = "1/4"
  self.playback_rate = 1
  self.dirty = false
  self.event = {}
end

-- API actions/
function Patterning:record()
  if not self.get_play_state then
    self.dirty = true
    self:play()
  end
  clock.run(self:record_toggle())
end

function Patterning:play()
  if self.dirty then
    self.iterator = clock.run(pattern_clock,self)
    self.set_play_state(true)
  end
end

function Patterning:stop()
  clock.cancel(self.iterator)
  self:set_play_state(false)
  self:set_record_state(false)
end

function Patterning:capture_event(event_table)
  if self.recording or self.overdubbing then
    self.event[self:get_tick()] = event_table
  end
end
-- /API actions

function Patterning:record_toggle()
  clock.sync(self.record_launch_quant == "bar" and 4 or (self.record_launch_quant == "beat" and 1 or 0))
  self.set_record_state(not self.recording)
  if not self.get_record_state then
    self:set_end_tick(self:get_tick())
  end
end

function Patterning:cycle(value,min,max)
  if value > max then
    return min
  elseif value < min then
    return max
  else
    return value
  end
end

function Patterning:get_tick()
  return self.tick
end

function Patterning:set_tick(i)
  self.tick = self:cycle(i,1,self.total_ticks)
end

function Patterning:advance_tick()
  self:set_tick(self:get_tick + 1)
  if self.event[self:get_tick()] ~= nil then
    self.process(self.event[self:get_tick()])
  end
end


function Patterning:set_record_state(i)
  self.recording = i
end

function Patterning:get_record_state()
  return self.recording
end

function Patterning:overdub_toggle()
  if self.get_play_state then
    self.set_record_state(true)
  end
end

function Patterning:set_play_state(i)
  self.playing = i
end

function Patterning:get_play_state()
  return self.playing
end

function Patterning:get_start_tick()
  return self.start_tick
end

function Patterning:get_end_tick()
  return self.end_tick
end

function Patterning:set_end_tick(i)
  self.end_tick = i
end

function Patterning:get_step()
  return self.step
end

function Patterning:set_step(i)
  self.step = self:cycle(i,self:get_start_tick(),self:get_end_tick())
end

function Patterning:get_sub_step()
  return self.sub_step
end

function Patterning:set_sub_step(i)
  self.sub_step = self:cycle(i,1,48)
  if self.sub_step == 1 then
    self:advance_step()
  end
end


-- local tracktions = {}

-- tracker = {}

-- function tracktions.init(target)
--   tracker[target] = {}
--   tracker[target].step = 1
--   tracker[target].runner = 1
--   tracker[target].start_point = 1
--   tracker[target].end_point = 1
--   tracker[target].recording = false
--   tracker[target].playing = false
--   -- tracker[target].snake = 1
--   for i = 1,tracker[target].max_memory do
--     tracker[target][i] = {}
--     tracker[target][i].pad = nil
--     tracker[target][i].trigger = true
--   end
-- end

-- local snakes = 
-- { [1] = { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16 }
-- , [2] = { 1,2,3,4,8,7,6,5,9,10,11,12,16,15,14,13 }
-- , [3] = { 1,5,9,13,2,6,10,14,3,7,11,15,4,8,12,16 }
-- , [4] = { 1,5,9,13,14,10,6,2,3,7,11,15,16,12,8,4 }
-- , [5] = { 1,2,3,4,8,12,16,15,14,13,9,5,6,7,11,10 }
-- , [6] = { 13,14,15,16,12,8,4,3,2,1,5,9,10,11,7,6 }
-- , [7] = { 1,2,5,9,6,3,4,7,10,13,14,11,8,12,15,16 }
-- , [8] = { 1,6,11,16,15,10,5,2,7,12,8,3,9,14,13,4 }
-- }

-- function tracktions.snake(target,mode)
--   local prev_snake = tracker[target].snake
--   if #tracker[target] > 0 then
--     tracktions.clear(target) -- this becomes problematic for tracking snake mode...
--   end
--   tracker[target].snake = prev_snake
--   for i = 1,16 do
--     tracker[target][i] = {}
--     tracker[target][i].pad = snakes[mode][i]
--     tracker[target][i].time = 3
--     tracktions.map_to(target,i)
--   end
--   tracker[target].end_point = #snakes[mode]
-- end

-- function tracktions.adjust_param()
-- end

-- function tracktions.map_to(target,entry)
--   local i = entry
--   local t = target
--   local pad = bank[t][tracker[t][i].pad]
--   local parameters = 
--   { "rate"
--   , "start_point"
--   , "end_point"
--   , "tilt"
--   , "level"
--   , "clip"
--   , "mode"
--   , "loop"
--   , "pan"
--   , "left_delay_level"
--   , "right_delay_level"
--   }
--   for j = 1,#parameters do
--     if tracker[t][i][parameters[j]] ~= pad[parameters[j]] then
--       tracker[t][i][parameters[j]] = pad[parameters[j]]
--     end
--   end
-- end

-- function tracktions.map_from(target,entry)
--   local i = entry
--   local t = target
--   local pad = bank[t][tracker[t][i].pad]
--   for k,v in pairs(tracker[t][i]) do
--     pad[k] = v
--   end
-- end

-- function tracktions.map_similar(target,entry)
--   local i = entry
--   local t = target
--   for j = 1,#tracker[t] do
--     if tracker[t][j].pad == nil then break end
--     if tracker[t][j].pad == tracker[t][i].pad then
--       for k,v in pairs(tracker[t][i]) do
--         tracker[t][j][k] = v
--       end
--     end
--   end
-- end

-- function tracktions.inherit(target,pad)
--   local t = target
--   for i = 1,#tracker[t] do
--     if tracker[t][i].pad == nil then break end
--     if tracker[t][i].pad == pad then
--       tracktions.map_to(t,i)
--     end
--   end
-- end

-- --[[
-- function tracktions.inherit(target,pad)
--   local t = target
--   if tracker[t][tracker[t].step].pad == pad then
--     tracktions.map_to(t,tracker[t].step)
--   end
-- end
-- --]]

-- function tracktions.add(target,entry)
--   table.remove(tracker[target],page.track_sel[page.track_page])
--   table.insert(tracker[target],page.track_sel[page.track_page],entry)
--   local reasonable_max = nil
--   for i = 1,tracker[target].max_memory do
--     if tracker[page.track_page][i].pad ~= nil then
--       reasonable_max = i
--     end
--   end
--   tracker[target].end_point = reasonable_max
--   page.track_sel[page.track_page] = page.track_sel[page.track_page] + 1
--   if menu ~= 1 then screen_dirty = true end
-- end

-- function tracktions.append() -- TODO add arguments
--   if page.track_sel[page.track_page] > tracker[page.track_page].end_point then
--     tracker[page.track_page].end_point = page.track_sel[page.track_page]
--   end
-- end

-- function tracktions.remove(target,entry)
--   table.remove(tracker[target],page.track_sel[page.track_page])
--   if menu ~= 1 then screen_dirty = true end
-- end

-- function tracktions.clear(target)
--   if tracker[target].playing then
--     clock.cancel(tracker[target].clock)
--   end
--   tracktions.init(target)
-- end

-- function tracktions.transport(target)
--   if tracker[target][1].pad ~= nil then
--     if not tracker[target].playing then
--       tracker[target].runner = 1
--       tracker[target].clock = clock.run(tracktions.advance,target)
--       tracker[target].playing = true
--     else
--       clock.cancel(tracker[target].clock)
--       tracker[target].playing = false
--     end
--   end
-- end

-- function tracktions.advance(target)
--   clock.sync(4)
--   while true do
--     if #tracker[target] > 0 then
--       clock.sync(1/12) -- or here?
--       local step = tracker[target].step
--       if tracker[target].runner == 1 then
--         tracktions.cheat(target,step)
--       end
--       if tracker[target].runner == tracker[target][step].time then
--         tracker[target].step = tracker[target].step + 1
--         tracker[target].runner = 0
--       end
--       --clock.sync(tracker[target][step].time) -- here?
--       if tracker[target].step > tracker[target].end_point then
--         tracker[target].step = tracker[target].start_point
--       end
--       tracker[target].runner = tracker[target].runner + 1
--     end
--     if menu ~= 1 then screen_dirty = true end
--   end
-- end

-- function tracktions.sync(target)
--   tracker[target].step = tracker[target].start_point - 1
-- end

-- function tracktions.cheat(target,step)
--   bank[target].id = tracker[target][step].pad
--   selected[target].x = (5*(target-1)+1)+(math.ceil(bank[target].id/4)-1)
--   if (bank[target].id % 4) ~= 0 then
--     selected[target].y = 9-(bank[target].id % 4)
--   else
--     selected[target].y = 5
--   end
--   --tracktions.map_from(target,step)
--   cheat(target,bank[target].id)
-- end

-- function tracktions.copy_prev(source,destination)
--   for k,v in pairs(source) do
--     destination[k] = v
--   end
--   if menu ~= 1 then screen_dirty = true end
-- end

return tracktions