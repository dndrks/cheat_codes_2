local tracktions = {}

tracker = {}

function tracktions.init(target)
  tracker[target] = {}
  tracker[target].step = 1
  tracker[target].runner = 1
  tracker[target].start_point = 1
  tracker[target].end_point = 1
  tracker[target].recording = false
  tracker[target].max_memory = 128
  tracker[target].playing = false
  tracker[target].snake = 1
  for i = 1,tracker[target].max_memory do
    tracker[target][i] = {}
    tracker[target][i].pad = nil
    tracker[target][i].time = nil
    tracker[target][i].rate = nil
    tracker[target][i].start_point = nil
    tracker[target][i].end_point = nil
    tracker[target][i].tilt = nil
    tracker[target][i].level = nil
    tracker[target][i].clip = nil
    tracker[target][i].mode = nil
    tracker[target][i].loop = nil
    tracker[target][i].pan = nil
    tracker[target][i].left_delay_level = nil
    tracker[target][i].right_delay_level = nil
    tracker[target][i].trigger = true
  end
end

local snakes = 
{ [1] = { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16 }
, [2] = { 1,2,3,4,8,7,6,5,9,10,11,12,16,15,14,13 }
, [3] = { 1,5,9,13,2,6,10,14,3,7,11,15,4,8,12,16 }
, [4] = { 1,5,9,13,14,10,6,2,3,7,11,15,16,12,8,4 }
, [5] = { 1,2,3,4,8,12,16,15,14,13,9,5,6,7,11,10 }
, [6] = { 13,14,15,16,12,8,4,3,2,1,5,9,10,11,7,6 }
, [7] = { 1,2,5,9,6,3,4,7,10,13,14,11,8,12,15,16 }
, [8] = { 1,6,11,16,15,10,5,2,7,12,8,3,9,14,13,4 }
}

function tracktions.snake(target,mode)
  local prev_snake = tracker[target].snake
  if #tracker[target] > 0 then
    tracktions.clear(target) -- this becomes problematic for tracking snake mode...
  end
  tracker[target].snake = prev_snake
  for i = 1,16 do
    tracker[target][i] = {}
    tracker[target][i].pad = snakes[mode][i]
    tracker[target][i].time = 3
    tracktions.map_to(target,i)
  end
  tracker[target].end_point = #snakes[mode]
end

function tracktions.adjust_param()
end

function tracktions.map_to(target,entry)
  local i = entry
  local t = target
  local pad = bank[t][tracker[t][i].pad]
  local parameters = 
  { "rate"
  , "start_point"
  , "end_point"
  , "tilt"
  , "level"
  , "clip"
  , "mode"
  , "loop"
  , "pan"
  , "left_delay_level"
  , "right_delay_level"
  }
  for j = 1,#parameters do
    if tracker[t][i][parameters[j]] ~= pad[parameters[j]] then
      tracker[t][i][parameters[j]] = pad[parameters[j]]
    end
  end
end

function tracktions.map_from(target,entry)
  local i = entry
  local t = target
  local pad = bank[t][tracker[t][i].pad]
  for k,v in pairs(tracker[t][i]) do
    pad[k] = v
  end
end

function tracktions.map_similar(target,entry)
  local i = entry
  local t = target
  for j = 1,#tracker[t] do
    if tracker[t][j].pad == nil then break end
    if tracker[t][j].pad == tracker[t][i].pad then
      for k,v in pairs(tracker[t][i]) do
        tracker[t][j][k] = v
      end
    end
  end
end

function tracktions.inherit(target,pad)
  local t = target
  for i = 1,#tracker[t] do
    if tracker[t][i].pad == nil then break end
    if tracker[t][i].pad == pad then
      tracktions.map_to(t,i)
    end
  end
end

--[[
function tracktions.inherit(target,pad)
  local t = target
  if tracker[t][tracker[t].step].pad == pad then
    tracktions.map_to(t,tracker[t].step)
  end
end
--]]

function tracktions.add(target,entry)
  table.remove(tracker[target],page.track_sel[page.track_page])
  table.insert(tracker[target],page.track_sel[page.track_page],entry)
  local reasonable_max = nil
  for i = 1,tracker[target].max_memory do
    if tracker[page.track_page][i].pad ~= nil then
      reasonable_max = i
    end
  end
  tracker[target].end_point = reasonable_max
  page.track_sel[page.track_page] = page.track_sel[page.track_page] + 1
  redraw()
end

function tracktions.append() -- TODO add arguments
  if page.track_sel[page.track_page] > tracker[page.track_page].end_point then
    tracker[page.track_page].end_point = page.track_sel[page.track_page]
  end
end

function tracktions.remove(target,entry)
  table.remove(tracker[target],page.track_sel[page.track_page])
  redraw()
end

function tracktions.clear(target)
  if tracker[target].playing then
    clock.cancel(tracker[target].clock)
  end
  tracktions.init(target)
end

function tracktions.transport(target)
  if tracker[target][1].pad ~= nil then
    if not tracker[target].playing then
      tracker[target].runner = 1
      tracker[target].clock = clock.run(tracktions.advance,target)
      tracker[target].playing = true
    else
      clock.cancel(tracker[target].clock)
      tracker[target].playing = false
    end
  end
end

function tracktions.advance(target)
  clock.sync(4)
  while true do
    if #tracker[target] > 0 then
      clock.sync(1/12) -- or here?
      local step = tracker[target].step
      if tracker[target].runner == 1 then
        tracktions.cheat(target,step)
      end
      if tracker[target].runner == tracker[target][step].time then
        tracker[target].step = tracker[target].step + 1
        tracker[target].runner = 0
      end
      --clock.sync(tracker[target][step].time) -- here?
      if tracker[target].step > tracker[target].end_point then
        tracker[target].step = tracker[target].start_point
      end
      tracker[target].runner = tracker[target].runner + 1
    end
    redraw()
  end
end

function tracktions.sync(target)
  tracker[target].step = tracker[target].start_point - 1
end

function tracktions.cheat(target,step)
  bank[target].id = tracker[target][step].pad
  selected[target].x = (5*(target-1)+1)+(math.ceil(bank[target].id/4)-1)
  if (bank[target].id % 4) ~= 0 then
    selected[target].y = 9-(bank[target].id % 4)
  else
    selected[target].y = 5
  end
  --tracktions.map_from(target,step)
  cheat(target,bank[target].id)
end

function tracktions.copy_prev(source,destination)
  for k,v in pairs(source) do
    destination[k] = v
  end
  redraw()
end

return tracktions