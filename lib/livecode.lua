local lc = {}

lc.enabled = true

-- call a function repetitively in time
-- the arg to the function is interpolated fps times per second
-- dest_ms is a table of `to()` calls for ASL-like sequences
function lc.fnl(fn, origin, dest_ms, fps)
  return clock.run(function()
      fps = fps or 15 -- default
      local spf = 1 / fps -- seconds per frame
      fn(origin)
      for _,v in ipairs(dest_ms) do
          local count = math.floor(v[2] * fps) -- number of iterations
          print(count,v[2],fps)
          local stepsize = (v[1]-origin) / count -- how much to increment by each iteration
          while util.round(count,0.0001) > 0 do
              clock.sleep(spf)
              origin = origin + stepsize -- move toward destination
              count = count - 1 -- count iteration
              fn(origin)
          end
      end  
  end)
end

function lc.metro_fnl(fn, origin, dest_ms, fps)
    fps = fps or 15 -- default
    local spf = 1 / fps -- seconds per frame
    fn(origin)
    for _,v in ipairs(dest_ms) do
        local count = math.floor(v[2] * fps) -- number of iterations
        local stepsize = (v[1]-origin) / count -- how much to increment by each iteration
        while util.round(count,0.0001) > 0 do
            clock.sleep(spf)
            origin = origin + stepsize -- move toward destination
            count = count - 1 -- count iteration
            fn(origin)
        end
    end
  end

return lc