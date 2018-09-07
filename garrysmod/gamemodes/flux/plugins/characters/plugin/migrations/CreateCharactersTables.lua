ActiveRecord.define_model('ammo', function(t)
  t:string 'type'
  t:integer 'amount'
  t:integer 'character_id'
end)

ActiveRecord.define_model('characters', function(t)
  t:string { 'steam_id', null = false }
  t:string { 'name', null = false }
  t:string 'model'
  t:text 'phys_desc'
  t:integer 'money'
  t:integer 'character_id'
  t:integer 'user_id'
end)

ActiveRecord.define_model('data', function(t)
  t:string 'key'
  t:text 'value'
  t:integer 'character_id'
end)

ActiveRecord.define_model('inventories', function(t)
  t:integer 'character_id'
end)

ActiveRecord.define_model('character_items', function(t)
  t:integer 'item_id'
  t:integer 'inventory_id'
  t:integer 'character_id'
end)