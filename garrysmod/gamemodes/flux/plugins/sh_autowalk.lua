PLUGIN:set_name('Auto Walk')
PLUGIN:set_author('NightAngel')
PLUGIN:set_description('Allows users to press a button to automatically walk forward.')

if SERVER then
  local check = {
    [IN_FORWARD] = true,
    [IN_BACK] = true,
    [IN_MOVELEFT] = true,
    [IN_MOVERIGHT] = true
  }

  function PLUGIN:SetupMove(player, moveData, cmdData)
    if !player:get_nv('auto_walk') then return end

    moveData:SetForwardSpeed(moveData:GetMaxSpeed())

    -- If they try to move, break the autowalk.
    for k, v in pairs(check) do
      if cmdData:KeyDown(k) then
        player:set_nv('auto_walk', false)

        break
      end
    end
  end

  -- So clients can bind this as they want.
  concommand.Add('toggleautowalk', function(player)
    local old_val = player:get_nv('auto_walk')

    if !old_val then
      old_val = false
    end

    player:set_nv('auto_walk', !old_val)
  end)
else
--  fl.hint:Add('Autowalk', 'Press 'B' to toggle auto walking.')

  -- We do this so there's no need to do an unnecessary check for if client or server in the hook itself.
  function PLUGIN:SetupMove(player, moveData, cmdData)
    if !player:get_nv('auto_walk') then return end

    moveData:SetForwardSpeed(moveData:GetMaxSpeed())
  end

  fl.binds:AddBind('ToggleAutoWalk', 'toggleautowalk', KEY_B)
end
