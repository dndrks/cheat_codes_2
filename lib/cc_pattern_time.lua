--- pattern
-- @classmod pattern

local pattern = {}
pattern.__index = pattern

--- constructor
function pattern.new(id)
  local i = {}
  setmetatable(i, pattern)
  i.rec = 0
  i.play = 0
  i.overdub = 0
  i.prev_time = 0
  i.curr_time = {}
  i.event = {}
  i.time = {}
  i.time_beats = {}
  i.quantum = {}
  i.count = 0
  i.step = 0
  i.runner = 1
  i.time_factor = 1
  i.loop = 1
  i.start_point = 0
  i.end_point = 0
  i.clock = nil
  i.clock_time = 4
  i.rec_clock = nil
  i.mode = "unquantized"
  i.name = id

  i.metro = metro.init(function() i:next_event() end,1,1)

  i.process = function(_) print("event") end

  return i
end

--- clear this pattern
function pattern:clear()
  if self.mode == "unquantized" then
    self.metro:stop()
  else
    if self.quant_clock ~= nil then
      clock.cancel(self.quant_clock)
    end
  end
  if self.clock ~= nil then
    clock.cancel(self.clock)
  end
  self.rec = 0
  self.play = 0
  self.overdub = 0
  self.prev_time = 0
  self.curr_time = {}
  self.event = {}
  self.time = {}
  self.time_beats = {}
  self.quantum = {}
  self.count = 0
  self.step = 0
  self.runner = 1
  self.time_factor = 1
  self.start_point = 0
  self.end_point = 0
  self.clock = nil
  self.clock_time = 4
  self.rec_clock = nil
end

--- adjust the time factor of this pattern.
-- @tparam number f time factor
function pattern:set_time_factor(f)
  self.time_factor = f or 1
end

--- start recording
function pattern:rec_start()
  print("pattern rec start "..clock.get_beats())
  self.rec = 1
end

--- stop recording
function pattern:rec_stop()
  if self.rec == 1 then
    self.rec = 0
    if self.count ~= 0 then
      print("count "..self.count)
      local t = self.prev_time
      self.prev_time = util.time()
      self.time[self.count] = self.prev_time - t
      self.time_beats[self.count] = self.time[self.count] / clock.get_beat_sec()
      self.start_point = 1
      self.end_point = self.count
      for i = 1,self.count do
        self:calculate_quantum(i)
      end
      self:calculate_duration()
      if self.playmode == 1 then
        sync_clock_to_loop(self,"pattern")
      end
      --tab.print(self.time)
    else
      print("no events recorded")
    end
  -- else print("not recording")
  end
  --NEW STUFF
  if self.rec_clock ~= nil then
    print("canceling record clock")
    clock.cancel(self.rec_clock)
    clock.cancel(self.synced_pat_clock)
    self.rec_clock = nil
  end
  --/ NEW STUFF
end

--- watch
function pattern:watch(e)
  if self.rec == 1 then
    self:rec_event(e)
  elseif self.overdub == 1 then
    self:overdub_event(e)
  end
end

--- record event
function pattern:rec_event(e)
  local c = self.count + 1
  if c == 1 then
    self.prev_time = util.time()
    --print("first event")
  else
    local t = self.prev_time
    self.prev_time = util.time()
    self.time[c-1] = self.prev_time - t
    self.time_beats[c-1] = self.time[c-1] / clock.get_beat_sec()
    --print(self.time[c-1])
  end
  self.count = c
  self.event[c] = e
end

function pattern:calculate_quantum(target)
  self.quantum[target] = util.round(self.time_beats[target],0.25)
  --[[
  if target ~= self.count then
    self.time_beats[target+1] = self.time_beats[target+1] + (self.time_beats[target] - self.quantum[target])
  end
  --]]
end

function pattern:overdub_event(e)
  local c = self.step + 1
  local t = self.prev_time
  self.prev_time = util.time()
  local a = self.time[c-1]
  local q_a = self.time_beats[c-1]
  local previous_quantum_total = self.quantum[c-1]
  self.time[c-1] = self.prev_time - t
  self.time_beats[c-1] = self.time[c-1] / clock.get_beat_sec()
  table.insert(self.time, c, a - self.time[c-1])
  table.insert(self.event, c, e)
  print(c-1,c,self.time[c])
  table.insert(self.time_beats, c, self.time[c] / clock.get_beat_sec()) -- should work...
  print("new2: "..self.time_beats[c])
  local new = self.time_beats[c]
  if self.mode == "unquantized" then
    self.step = self.step + 1
  end
  self.count = self.count + 1
  self.end_point = self.count
  self.time_beats[c] = new
  --for i = 1,self.count do
  for i = 1,self.count do
    self.quantum[i] = util.round(self.time_beats[i],0.25)
    if self.quantum[i] == 0 then
      self.quantum[i] = 0.25
    end
  end
  self.quantum[c] = previous_quantum_total - self.quantum[c-1]
  --unsure...
  if self.runner > self.quantum[self.step]*4 then
    self.step = self.step + 1
    self.runner = 1
    print("runner was over...")
  end
end

function pattern:calculate_duration()
  local total_time = 0
  for i = 1,#self.time_beats do
    total_time = total_time + self.time_beats[i]
  end
  -- print("when does this happen??")
  -- self.rec_clock_time = util.round(total_time)
  self.rec_clock_time = self.rec_clock_time
end

function pattern:print()
  for i = 1,self.count do
    print(self.time_beats[i], self.time[i], self.quantum[i])
  end
end

--- start this pattern
function pattern:start()
  --if self.count > 0 then
  if self.count > 0 and self.rec == 0 then
    --print("start pattern ")
    if self.mode == "unquantized" then
      self.prev_time = util.time()
      self.process(self.event[self.start_point])
      self.play = 1
      self.step = self.start_point
      self.metro.time = self.time[self.start_point] * self.time_factor
      self.metro:start()
    else
      --clock.run(quantize_start, self)
      quantize_start(self)
    end
  end
end

function pattern:quant(state)

  if state == 0 then
    if self.quant_clock ~= nil then
      clock.cancel(self.quant_clock)
    end
    self.mode = "unquantized"
    if self.play == 1 then
      self.metro:start()
    end
  elseif state == 1 then
    self.mode = "quantized"
    self.runner = 1
    if self.play == 1 then
      self.metro:stop()
      self.quant_clock = clock.run(quantized_advance,self)
    end
  end
    
end

function quantize_start(target)
  --clock.sync(4)
  target.play = 1
  target.step = target.start_point
  target.runner = 1
  target.quant_clock = clock.run(quantized_advance,target)
end

function quantized_advance(target)
  while true do
    if target.count > 0 then
      local step = target.step
      if target.runner == 1 then
        target.process(target.event[step])
        target.prev_time = util.time()
      end
      clock.sync(1/4)
      target.runner = target.runner + 1
      if target.runner > target.quantum[step]*4 then
        target.step = target.step + 1
        target.runner = 1
      end
      if target.step > target.end_point then
        target.step = target.start_point
        target.runner = 1
      end
    end
  end
end

--- process next event
function pattern:next_event()
  local diff = nil
  self.prev_time = util.time()
  if self.count == self.end_point then diff = self.count else diff = self.end_point end
  if self.step == diff and self.loop == 1 then
    self.step = self.start_point
  elseif self.step > diff and self.loop == 1 then
    self.step = self.start_point
  else
    self.step = self.step + 1
  end
  self.process(self.event[self.step])
  self.metro.time = self.time[self.step] * self.time_factor
  self.curr_time[self.step] = util.time()
  --print("next time "..self.metro.time)
  if self.step == diff and self.loop == 0 then
    if self.play == 1 then
      self.play = 0
      self.metro:stop()
    end
  else
    self.metro:start()
  end
end

--- stop this pattern
function pattern:stop()
  if self.play == 1 then
    --print("stop pattern ")
    self.play = 0
    self.overdub = 0
    if self.mode == "unquantized" then
      self.metro:stop()
    else
      if self.quant_clock ~= nil then
        clock.cancel(self.quant_clock)
      end
      self.quant_clock = nil
    end
    
    --[[
    if self.playmode == 2 then
      clock.cancel(self.clock)
    end
    --]]
    
  else
    --print("not playing")
  end
end

function pattern:set_overdub(s)
  if s == 1 and self.play == 1 and self.rec == 0 then
    self.overdub = 1
  else
    self.overdub = 0
  end
end

function pattern:restore_defaults()
  self:clear()
  self.mode = "unquantized"
  if self.name == "midi_pat[1]" or self.name == "midi_pat[2]" or self.name == "midi_pat[3]" then
    -- print("resetting midi_pat")
    self.tightened_start = 0
    self.auto_snap = 0
    self.quantize = 0
    self.playmode = 1
    self.random_pitch_range = 5
    self.rec_clock_time = 8
    self.first_touch = false
  end
end

return pattern