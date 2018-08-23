library.New "item"

-- Item Templates storage.
local stored = item.stored or {}
item.stored = stored

-- Actual items.
local instances = item.instances or {}
item.instances = instances

-- Instances table indexed by instance ID.
-- For quicker item lookups.
local sorted = item.sorted or {}
item.sorted = sorted

-- Items currently dropped and lying on the ground.
local entities = item.entities or {}
item.entities = entities

function item.GetAll()
  return stored
end

function item.GetInstances()
  return instances
end

function item.GetSorted()
  return sorted
end

function item.GetEntities()
  return entities
end

function item.register(id, data)
  if (!data) then return end

  if (!isstring(data.name) and isstring(data.print_name)) then
    data.name = data.print_name
  end

  if (!isstring(id) and !isstring(data.name)) then
    ErrorNoHalt("Attempt to register an item without a valid ID!")
    debug.Trace()

    return
  end

  fl.dev_print("Registering item: "..tostring(id))

  if (!id) then
    id = data.name:to_id()
  end

  data.id = id
  data.name = data.name or "Unknown Item"
  data.print_name = data.print_name or data.name
  data.description = data.description or "This item has no description!"
  data.weight = data.weight or 1
  data.stackable = data.stackable or false
  data.max_stack = data.max_stack or 64
  data.model = data.model or "models/props_lab/cactus.mdl"
  data.skin = data.skin or 0
  data.color = data.color or nil
  data.Cost = data.Cost or 0
  data.SpecialColor = data.SpecialColor or nil
  data.category = data.category or "#Item_Category_Other"
  data.isBase = data.isBase or false
  data.instanceID = ITEM_TEMPLATE
  data.data = data.data or {}
  data.customButtons = data.customButtons or {}
  data.actionSounds = data.actionSounds or {}
  data.use_text = data.use_text
  data.TakeText = data.TakeText
  data.CancelText = data.CancelText
  data.UseIcon = data.UseIcon
  data.TakeIcon = data.TakeIcon
  data.CancelIcon = data.CancelIcon

  stored[id] = data
  instances[id] = instances[id] or {}
end

function item.ToSave(itemTable)
  if (!itemTable) then return end

  return {
    id = itemTable.id,
    Name = itemTable.name,
    PrintName = itemTable.print_name,
    Description = itemTable.description,
    Weight = itemTable.weight,
    Stackable = itemTable.stackable,
    MaxStack = itemTable.max_stack,
    Model = itemTable.model,
    Skin = itemTable.skin,
    Color = itemTable.color,
    Cost = itemTable.Cost,
    SpecialColor = itemTable.SpecialColor,
    isBase = itemTable.isBase,
    instanceID = itemTable.instanceID,
    data = itemTable.data,
    actionSounds = itemTable.actionSounds,
    UseText = itemTable.use_text,
    TakeText = itemTable.TakeText,
    CancelText = itemTable.CancelText,
    UseIcon = itemTable.UseIcon,
    TakeIcon = itemTable.TakeIcon,
    CancelIcon = itemTable.CancelIcon
  }
end

-- Find item's template by it's ID.
function item.FindByID(id)
  for k, v in pairs(stored) do
    if (k == id or v.id == id) then
      return v
    end
  end
end

-- Find all instances of certain template ID.
function item.FindAllInstances(id)
  if (instances[id]) then
    return instances[id]
  end
end

-- Finds instance by it's ID.
function item.FindInstanceByID(instanceID)
  for k, v in pairs(instances) do
    if (istable(v)) then
      for k2, v2 in pairs(v) do
        if (k2 == instanceID) then
          return v2
        end
      end
    end
  end
end

-- Finds an item template that belongs to certain instance ID.
function item.FindByInstanceID(instanceID)
  if (!instanceID) then return end

  if (!sorted[instanceID]) then
    sorted[instanceID] = item.FindInstanceByID(instanceID)
  end

  return sorted[instanceID]
end

function item.Find(name)
  if (isnumber(name)) then
    return item.FindInstanceByID(name)
  end

  if (stored[id]) then
    return stored[id]
  end

  for k, v in pairs(stored) do
    if (v.id and v.name and v.print_name) then
      if (v.id == name or v.name:find(name) or v.print_name:find(name)) then
        return v
      end

      if CLIENT then
        if (fl.lang:TranslateText(v.print_name):find(name)) then
          return v
        end
      end
    end
  end
end

function item.GenerateID()
  instances.count = instances.count or 0
  instances.count = instances.count + 1

  return instances.count
end

function item.New(id, data, forcedID)
  local itemTable = item.FindByID(id)

  if (itemTable) then
    local itemID = forcedID or item.GenerateID()

    instances[id] = instances[id] or {}
    instances[id][itemID] = table.Copy(itemTable)

    if (istable(data)) then
      table.Merge(instances[id][itemID], data)
    end

    instances[id][itemID].instanceID = itemID

    if SERVER then
      item.AsyncSave()
      netstream.Start(nil, "ItemNewInstance", id, (data or 1), itemID)
    end

    return instances[id][itemID]
  end
end

function item.Remove(instanceID)
  local itemTable = (istable(instanceID) and instanceID) or item.FindInstanceByID(instanceID)

  if (itemTable and item.IsInstance(itemTable)) then
    if (IsValid(itemTable.entity)) then
      itemTable.entity:Remove()
    end

    instances[itemTable.id][itemTable.instanceID] = nil

    if SERVER then
      item.AsyncSave()
    end

    fl.dev_print("Removed item instance ID: "..itemTable.instanceID)
  end
end

function item.IsInstance(itemTable)
  if (!istable(itemTable)) then return end

  return (itemTable.instanceID or ITEM_TEMPLATE) > ITEM_INVALID
end

function item.CreateBase(name)
  class(name, nil, Item)
end

pipeline.register("item", function(id, fileName, pipe)
  ITEM = Item(id)

  util.include(fileName)

  if (pipeline.IsAborted()) then ITEM = nil return end

  ITEM:register() ITEM = nil
end)

function item.IncludeItems(directory)
  pipeline.include_folder("item", directory)
end

if SERVER then
  function item.Load()
    local loaded = data.LoadSchema("items/instances", {})

    if (loaded and table.Count(loaded) > 0) then
      -- Returns functions to instances table after loading.
      for id, instanceTable in pairs(loaded) do
        local itemTable = item.FindByID(id)

        if (itemTable) then
          for k, v in pairs(instanceTable) do
            local newItem = table.Copy(itemTable)

            table.Merge(newItem, v)

            loaded[id][k] = newItem
          end
        end
      end

      instances = loaded
      item.instances = loaded
    end

    local loaded = data.LoadSchema("items/entities", {})

    if (loaded and table.Count(loaded) > 0) then
      for id, instanceTable in pairs(loaded) do
        for k, v in pairs(instanceTable) do
          if (instances[id] and instances[id][k]) then
            item.Spawn(v.position, v.angles, instances[id][k])
          else
            loaded[id][k] = nil
          end
        end
      end

      entities = loaded
      item.entities = loaded
    end
  end

  function item.SaveInstances()
    local toSave = {}

    for k, v in pairs(instances) do
      if (k == "count") then
        toSave[k] = v
      else
        toSave[k] = {}
      end

      if (istable(v)) then
        for k2, v2 in pairs(v) do
          if (istable(v2)) then
            toSave[k][k2] = item.ToSave(v2)
          end
        end
      end
    end

    data.SaveSchema("items/instances", toSave)
  end

  function item.SaveEntities()
    local itemEnts = ents.FindByClass("fl_item")

    entities = {}

    for k, v in ipairs(itemEnts) do
      if (IsValid(v) and v.item) then
        entities[v.item.id] = entities[v.item.id] or {}

        entities[v.item.id][v.item.instanceID] = {
          position = v:GetPos(),
          angles = v:GetAngles()
        }
      end
    end

    data.SaveSchema("items/entities", entities)
  end

  function item.SaveAll()
    item.SaveInstances()
    item.SaveEntities()
  end

  function item.AsyncSave()
    local handle = coroutine.create(item.SaveAll)
    coroutine.resume(handle)
  end

  function item.AsyncSaveInstances()
    local handle = coroutine.create(item.SaveInstances)
    coroutine.resume(handle)
  end

  function item.AsyncSaveEntities()
    local handle = coroutine.create(item.SaveEntities)
    coroutine.resume(handle)
  end

  function item.NetworkItemData(player, itemTable)
    if (item.IsInstance(itemTable)) then
      netstream.Start(player, "ItemData", itemTable.id, itemTable.instanceID, itemTable.data)
    end
  end

  function item.NetworkItem(player, instanceID)
    netstream.Start(player, "NetworkItem", instanceID, item.ToSave(item.FindInstanceByID(instanceID)))
  end

  function item.NetworkEntityData(player, ent)
    if (IsValid(ent)) then
      netstream.Start(player, "ItemEntData", ent:EntIndex(), ent.item.id, ent.item.instanceID)
    end
  end

  -- A function to send info about items in the world.
  function item.SendToPlayer(player)
    local itemEnts = ents.FindByClass("fl_item")

    for k, v in ipairs(itemEnts) do
      if (v.item) then
        item.NetworkItem(player, v.item.instanceID)
      end
    end

    hook.RunClient(player, "OnItemDataReceived")
  end

  function item.Spawn(position, angles, itemTable)
    if (!position or !istable(itemTable)) then
      ErrorNoHalt("[Flux:Item] No position or item table is not a table!\n")

      return
    end

    if (!item.IsInstance(itemTable)) then
      ErrorNoHalt("[Flux:Item] Cannot spawn non-instantiated item!\n")

      return
    end

    local ent = ents.Create("fl_item")

    ent:SetItem(itemTable)

    local mins, maxs = ent:GetCollisionBounds()

    ent:SetPos(position + Vector(0, 0, maxs.z))

    if (angles) then
      ent:SetAngles(angles)
    end

    ent:Spawn()

    itemTable:set_entity(ent)
    item.NetworkItem(player, itemTable.instanceID)

    entities[itemTable.id] = entities[itemTable.id] or {}
    entities[itemTable.id][itemTable.instanceID] = entities[itemTable.id][itemTable.instanceID] or {}
    entities[itemTable.id][itemTable.instanceID] = {
      position = position,
      angles = angles
    }

    item.AsyncSaveEntities()

    return ent, itemTable
  end

  netstream.Hook("RequestItemData", function(player, entIndex)
    local ent = Entity(entIndex)

    if (IsValid(ent)) then
      item.NetworkEntityData(player, ent)
    end
  end)
else
  netstream.Hook("ItemData", function(id, instanceID, data)
    if (istable(instances[id][instanceID])) then
      instances[id][instanceID].data = data
    end
  end)

  netstream.Hook("NetworkItem", function(instanceID, itemTable)
    if (itemTable and stored[itemTable.id]) then
      local newTable = table.Copy(stored[itemTable.id])
      table.Merge(newTable, itemTable)

      instances[newTable.id][instanceID] = newTable

      print("Received instance ID "..tostring(newTable))
    else
      print("FAILED TO RECEIVE INSTANCE ID "..instanceID)
    end
  end)

  netstream.Hook("ItemEntData", function(entIndex, id, instanceID)
    local ent = Entity(entIndex)

    if (IsValid(ent)) then
      local itemTable = instances[id][instanceID]

      -- Client has to know this shit too I guess?
      ent:SetModel(itemTable:GetModel())
      ent:SetSkin(itemTable.skin)
      ent:SetColor(itemTable:GetColor())

      -- Restore item's functions. For some weird reason they aren't properly initialized.
      table.Merge(ent, scripted_ents.Get("fl_item"))

      ent.item = itemTable
    end
  end)

  netstream.Hook("ItemNewInstance", function(id, data, itemID)
    item.New(id, data, itemID)
  end)
end
