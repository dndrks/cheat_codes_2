local sd = {}

local size;
-- local positions;

function sd.init()
  size = tonumber(params:string("grid_size"))
  if size == 128 then
    positions = 
    {
      [2] = {14,4},
      [3] = {15,4},
      [4] = {16,4},
      [5] = {14,3},
      [6] = {15,3},
      [7] = {16,3},
      [8] = {14,2},
      [9] = {15,2},
      [10] = {16,2},
      ["macro_config"] = {14,1},
      ["MIDI_config"] = {15,1}
    }
  end
end

-- 14,4 = 5,14
-- 8,7 = 2,8
-- x = 9-y, y = x

function sd.draw_grid()
  for k,v in pairs(positions) do
    g:led(positions[k][1],positions[k][2],4)
    if k == menu then
      g:led(positions[k][1],positions[k][2],12)
    end
  end
  g:led(16,5,menu == 1 and 12 or 4)
end

function sd.parse_press(x,y,z)
  local nx = sd.coordinate(x,y)[1]
  local ny = sd.coordinate(x,y)[2]
  -- print(nx,ny,(ny-12)+(nx-5))
  if nx >=5 and nx<=7 then
    local nx_to_menu = {[5] = nx-5, [6] = nx-3, [7] = nx-1}
    menu = (ny-12)+(nx_to_menu[nx])
  elseif nx == 4 and ny == 16 then
    menu = 1
  end
  screen_dirty = true
end

function sd.coordinate(x,y)
  if size == 128 then
    return {9-y,x}
  else
    return {x,y}
  end
end

return sd