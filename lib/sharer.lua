local sharer={}

local CCDATA_DIR=_path.data.."cheat_codes_yellow/"

function sharer.setup(script_name)
  -- only continue if norns.online exists
  if not util.file_exists(_path.code.."norns.online") then
    print("~~~~~~~~~~~~~~~ need to download norns.online ~~~~~~~~~~~~~~~")
    do return end
  elseif not util.file_exists(_path.code.."norns.online/lib/share.lua") then
    print("~~~~~~~~~~~~~~~ need to update norns.online ~~~~~~~~~~~~~~~")
    do return end
  end

  -- prevents initial bang for reloading directory
  preventbang=true
  clock.run(function()
    clock.sleep(2)
    preventbang=false 
  end)

  -- load norns.online lib
  local share=include("norns.online/lib/share")

  -- start uploader with name of your script
  local uploader=share:new{script_name=script_name}
  if uploader==nil then
    print("~~~~~~~~~~~~~~~ norns.online uploader failed, no username? ~~~~~~~~~~~~~~~")
    do return end
  end

  -- add parameters
  params:add_group("SHARE",4)

  -- uploader (CHANGE THIS TO FIT WHAT YOU NEED)
  -- select a save from the names folder
  local names_dir=CCDATA_DIR.."names/"
  params:add_file("share_upload","upload",names_dir)
  params:set_action("share_upload",function(y)
    -- prevent banging
    local x=y
    params:set("share_download",names_dir)
    if #x<=#names_dir then
      do return end
    end

    -- choose data name
    -- (here dataname is from the selector)
    local dataname=share.trim_prefix(x,CCDATA_DIR.."names/")
    dataname=dataname:gsub("%.cc2","") -- remove suffix
    params:set("share_message","uploading...")
    _menu.redraw()
    print("uploading "..x.." as "..dataname)

    -- get all of the files in the collection and upload them
    files=sharer.list_files(CCDATA_DIR.."collection-"..dataname.."/",{},true)
    for i,f in ipairs(files) do
      partial_path=sharer.trim_prefix(f,CCDATA_DIR.."collection-"..dataname.."/")
      target=CCDATA_DIR.."collection-"..uploader.upload_username.."_"..dataname.."/"..partial_path
      pathtofile=f
      msg=uploader:upload{dataname=dataname,pathtofile=pathtofile,target=target}
      if not string.match(msg,"OK") then
        params:set("share_message",msg)
        do return end
      end
    end

    -- create and upload the names file
    tmp_file=share.temp_file_name()
    local f=io.open(tmp_file,"w")
    f:write(uploader.upload_username.."_"..dataname)
    f:close()
    pathtofile=tmp_file
    target=CCDATA_DIR.."names/"..uploader.upload_username.."_"..dataname..".cc2"
    uploader:upload{dataname=dataname,pathtofile=pathtofile,target=target}
    os.remove(tmp_file)

    -- goodbye
    params:set("share_message","uploaded.")
  end)

  -- downloader
  download_dir=share.get_virtual_directory(script_name)
  params:add_file("share_download","download",download_dir)
  params:set_action("share_download",function(y)
    -- prevent banging
    local x=y
    params:set("share_download",download_dir)
    if #x<=#download_dir then
      do return end
    end

    -- download
    print("downloading!")
    params:set("share_message","downloading...")
    _menu.redraw()
    local msg=share.download_from_virtual_directory(x)
    params:set("share_message",msg)
  end)

  -- add a button to refresh the directory
  params:add{type='binary',name='refresh directory',id='share_refresh',behavior='momentary',action=function(v)
    if preventbang then
      do return end
    end
    print("updating directory")
    params:set("share_message","refreshing directory.")
    _menu.redraw()
    share.make_virtual_directory()
    params:set("share_message","directory updated.")
  end
}
params:add_text('share_message',">","")
end



function sharer.list_files(d,files,recursive)
  -- list files in a flat table
  if d=="." or d=="./" then
    d=""
  end
  if d~="" and string.sub(d,-1)~="/" then
    d=d.."/"
  end
  folders={}
  if recursive then
    local cmd="ls -ad "..d.."*/ 2>/dev/null"
    local f=assert(io.popen(cmd,'r'))
    local out=assert(f:read('*a'))
    f:close()
    for s in out:gmatch("%S+") do
      if not (string.match(s,"ls: ") or s=="../" or s=="./") then
        files=sharer.list_files(s,files,recursive)
      end
    end
  end
  do
    local cmd="ls -p "..d.." | grep -v /"
    local f=assert(io.popen(cmd,'r'))
    local out=assert(f:read('*a'))
    f:close()
    for s in out:gmatch("%S+") do
      table.insert(files,d..s)
    end
  end
  return files
end

sharer.trim_prefix=function(s,p)
  local t=(s:sub(0,#p)==p) and s:sub(#p+1) or s
  return t
end


return sharer