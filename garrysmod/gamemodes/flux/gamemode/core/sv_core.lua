DeriveGamemode("sandbox")

fileio.OldWrite = fileio.OldWrite or fileio.Write

function fileio.Write(file_name, file_nameContents)
  local exploded = string.Explode("/", file_name)
  local curPath = ""

  for k, v in ipairs(exploded) do
    if string.GetExtensionFromFilename(v) != nil then
      break
    end

    curPath = curPath..v.."/"

    if !file.Exists(curPath, "GAME") then
      fileio.MakeDirectory(curPath)
    end
  end

  fileio.OldWrite(file_name, file_nameContents)
end

oldServerLog = oldServerLog or ServerLog

function ServerLog(...)
  oldServerLog(...)
  print("")
end

function hook.runClient(player, strHookName, ...)
  netstream.Start(player, "Hook_RunCL", strHookName, ...)
end
