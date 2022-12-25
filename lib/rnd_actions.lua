local rnd_actions = {}

rnd = {}

MusicUtil = include "lib/cc_musicutil"

rnd_lattice = lattice:new{
  auto = true,
  meter = 4,
  ppqn = 96
}

function rnd.init(t)
  rnd[t] = {}
  rnd.targets = {"pan","rate","rate slew","delay send","loop","semitone offset","filter tilt"}
  for i = 1,7 do
      rnd[t][i] = {}
      rnd[t][i].param = rnd.targets[i]
      rnd[t][i].playing = false
      rnd[t][i].num = 1
      rnd[t][i].denom = 1
      rnd[t][i].time = rnd[t][i].num / rnd[t][i].denom
      rnd[t][i].rate_slew_min = 0
      rnd[t][i].rate_slew_max = 1
      rnd[t][i].pan_min = -100
      rnd[t][i].pan_max = 100
      rnd[t][i].rate_min = 0.125
      rnd[t][i].rate_max = 4
      rnd[t][i].offset_scale = MusicUtil.SCALES[1].name
      rnd[t][i].offset_octave = 2
      rnd[t][i].filter_min = -1
      rnd[t][i].filter_max = 1
      rnd[t][i].mode = "non-destructive"
      rnd[t][i].lattice = rnd_lattice:new_sprocket{
        action = function() rnd.lattice_advance(t,i) end,
        division = rnd[t][i].time/4,
        enabled = true
      }
  end
  rnd_lattice:start()
  math.randomseed(os.time())
end

function rnd.update_time(t,i)
  rnd[t][i].time = rnd[t][i].num / rnd[t][i].denom
  rnd[t][i].lattice:set_division(rnd[t][i].time/4)
end

local param_targets =
{   ['rate slew'] = rnd.rate_slew
,   ['pan'] = rnd.pan
,   ['rate'] = rnd.rate
}

function rnd.transport(t,i,state)
  if state == "on" then
    if not rnd[t][i].playing then
      -- rnd[t][i].clock = clock.run(rnd.advance, t, i)
      rnd[t][i].playing = true
    end
  elseif state == "off" then
    if rnd[t][i].playing then
      -- clock.cancel(rnd[t][i].clock)
      rnd[t][i].playing = false
    end
  end
end

function rnd.lattice_advance(t,i)
  if rnd[t][i].playing then
    -- print(t,i, clock.get_beats())
    if rnd[t][i].param == "rate slew" then
        rnd.rate_slew(t,i)
    elseif rnd[t][i].param == "pan" then
        rnd.pan(t,i)
    elseif rnd[t][i].param == "delay send" then
        rnd.delay_send(t,i)
    elseif rnd[t][i].param == "rate" then
        rnd.rate(t,i)
    elseif rnd[t][i].param == "loop" then
        rnd.loop(t)
    elseif rnd[t][i].param == "semitone offset" then
        rnd.offset(t,i)
    elseif rnd[t][i].param == "filter tilt" then
      rnd.filter_tilt(t,i)
    end
  end
end

function rnd.advance(t,i)
  while true do
    clock.sync(rnd[t][i].time)
    print("tell dan if you see this: error 12908")
    if rnd[t][i].param == "rate slew" then
        rnd.rate_slew(t,i)
    elseif rnd[t][i].param == "pan" then
        rnd.pan(t,i)
    elseif rnd[t][i].param == "delay send" then
        rnd.delay_send(t,i)
    elseif rnd[t][i].param == "rate" then
        rnd.rate(t,i)
    elseif rnd[t][i].param == "loop" then
        rnd.loop(t)
    elseif rnd[t][i].param == "semitone offset" then
        rnd.offset(t,i)
    elseif rnd[t][i].param == "filter tilt" then
      rnd.filter_tilt(t,i)
    end
  end
end

function rnd.restore_default(t,i)
    if rnd[t][i].param == "rate slew" then
        -- softcut.rate_slew_time(t+1,params:get("rate slew time "..t))
        softcut.rate_slew_time(t+1,bank[t][bank[t].id].rate_slew)
    elseif rnd[t][i].param == "pan" then
        softcut.pan(t+1,bank[t][bank[t].id].pan)
    elseif rnd[t][i].param == "delay send" then
        
    elseif rnd[t][i].param == "rate" then
        softcut.rate(t+1,bank[t][bank[t].id].rate*bank[t][bank[t].id].offset)
    elseif rnd[t][i].param == "loop" then
        softcut.loop(t+1,bank[t][bank[t].id].loop == true and 1 or 0)
    elseif rnd[t][i].param == "semitone offset" then
        softcut.rate(t+1,bank[t][bank[t].id].rate*bank[t][bank[t].id].offset)
    end
end

function rnd.rate_slew(t,i)
    local min = util.round(rnd[t][i].rate_slew_min * 1000)
    local max = util.round(rnd[t][i].rate_slew_max * 1000)
    local random_slew = math.random(min,max)/1000
    if rnd[t][i].mode == "destructive" then
      bank[t][bank[t].id].rate_slew = random_slew
    end
    softcut.rate_slew_time(t+1,random_slew)
end

function rnd.pan(t,i)
  local min = util.round(rnd[t][i].pan_min)
  local max = util.round(rnd[t][i].pan_max)
  local rand_pan = math.random(min,max)/100
  if rnd[t][i].mode == "destructive" then
    bank[t][bank[t].id].pan = rand_pan
  end
  softcut.pan(t+1,rand_pan)
  if menu == 4 then
    screen_dirty = true
  end
end

function rnd.rate(t,i)
    local rates = {0.125,0.25,0.5,1,2,4}
    local rates_to_int =
    {   [0.125] = 1
    ,   [0.25] = 2
    ,   [0.5] = 3
    ,   [1] = 4
    ,   [2] = 5
    ,   [4] = 6
    }
    local min = rates_to_int[rnd[t][i].rate_min]
    local max = rates_to_int[rnd[t][i].rate_max]
    local rand_rate = rates[math.random(min,max)]
    local rev = math.random(0,1)
    if rnd[t][i].mode == "destructive" then
        bank[t][bank[t].id].rate = rand_rate*(rev == 0 and -1 or 1)
    end
    softcut.rate(t+1,(rand_rate*(rev == 0 and -1 or 1))*bank[t][bank[t].id].offset)
end

function rnd.loop(t)
    local pre_loop = bank[t][bank[t].id].loop
    local loop = math.random(0,1)
    if loop == 0 then
        bank[t][bank[t].id].loop = true
        cheat(t,bank[t].id)
    else
        bank[t][bank[t].id].loop = false
        softcut.loop(t+1,0)
    end
    grid_dirty = true
end

function rnd.delay_send(t,i)
  local delay_send = math.random(0,1)
  for j = 1,16 do
      bank[t][j].left_delay_level = delay_send
      bank[t][j].right_delay_level = delay_send
  end
  softcut.level_slew_time(5,1)
  softcut.level_slew_time(6,1)
  if bank[t][bank[t].id].left_delay_thru then
    softcut.level_cut_cut(t+1,5,bank[t][bank[t].id].left_delay_level)
  else
    softcut.level_cut_cut(t+1,5,(bank[t][bank[t].id].left_delay_level*bank[t][bank[t].id].level)*bank[t].global_level)
  end
  if bank[t][bank[t].id].right_delay_thru then
    softcut.level_cut_cut(t+1,6,bank[t][bank[t].id].right_delay_level)
  else
    softcut.level_cut_cut(t+1,6,(bank[t][bank[t].id].right_delay_level*bank[t][bank[t].id].level)*bank[t].global_level)
  end
  grid_dirty = true
  if menu == 6 then
    screen_dirty = true
  end
end

function rnd.offset(t,i)
  local scale = MusicUtil.generate_scale(0,rnd[t][i].offset_scale,rnd[t][i].offset_octave)
  local rand_offset = scale[math.random(1,#scale)]
  if rnd[t][i].mode == "destructive" then
      bank[t][bank[t].id].offset = math.pow(0.5, -rand_offset / 12)
  end
  softcut.rate(t+1,bank[t][bank[t].id].rate*(math.pow(0.5, -rand_offset / 12)))
end

function rnd.filter_tilt(t,i)
  local filt_min = math.modf(rnd[t][i].filter_min*100)
  local filt_max = math.modf(rnd[t][i].filter_max*100)
  local rand_tilt = math.random(filt_min,filt_max)/100
  if rnd[t][i].mode == "destructive" then
    if slew_counter[t] ~= nil then
      slew_counter[t].prev_tilt = bank[t][bank[t].id].tilt
    end
    bank[t][bank[t].id].tilt = rand_tilt
  else
    for j = 1,16 do
      local target = bank[t][j]
      if slew_counter[t] ~= nil then
        slew_counter[t].prev_tilt = target.tilt
      end
      target.tilt = rand_tilt
    end
  end
  slew_filter(t,slew_counter[t].prev_tilt,bank[t][bank[t].id].tilt,bank[t][bank[t].id].q,bank[t][bank[t].id].q,bank[t][bank[t].id].tilt_ease_time)
end

function rnd.savestate()
  local collection = params:get("collection")
  local dirname = _path.data.."cheat_codes_2/rnd/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  
  local dirname = _path.data.."cheat_codes_2/rnd/collection-"..collection.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  for i = 1,3 do
    tab.save(rnd[i],_path.data .. "cheat_codes_2/rnd/collection-"..collection.."/"..i..".data")
  end
end

function rnd.loadstate()
  local collection = params:get("collection")
  for i = 1,3 do
    if tab.load(_path.data .. "cheat_codes_2/rnd/collection-"..collection.."/"..i..".data") ~= nil then
      rnd[i] = tab.load(_path.data .. "cheat_codes_2/rnd/collection-"..collection.."/"..i..".data")
      for j = 1,#rnd[i] do
        if rnd[i][j].lattice == nil then
          rnd[i][j].lattice = rnd_lattice:new_sprocket{
            action = function() rnd.lattice_advance(i,j) end,
            division = rnd[i][j].time/4,
            enabled = true
          }
        end
        -- rnd[i][j].clock = nil
        -- if rnd[i][j].playing then
        --   rnd[i][j].clock = clock.run(rnd.advance, i, j)
        -- end
      end
    end
  end
end

return rnd