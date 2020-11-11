util.AddNetworkString( "createNewCrafting" )
util.AddNetworkString( "updateCraftings" )
util.AddNetworkString( "removeCrafting" )
util.AddNetworkString( "craftItem" )

local loaded = false

local function isValidItem( itemID )
	if Pointshop2:GetRegisteredItems()[itemID] != nil then
		return true
	end
	return false
end

local function sendCraftings( target )
	net.Start( "updateCraftings" )
		net.WriteString( util.TableToJSON( CraftSystem.Craftings ) )
	if target then
		net.Send( target )
	else
		net.Broadcast()	
	end
end

local function createNewCraftings( inputs, outputs )
	table.insert( CraftSystem.Craftings, 1, { i = inputs, o = outputs } )
	file.Write( "crafts.dat", util.TableToJSON( CraftSystem.Craftings ) )
	sendCraftings()
end

local function tableIsEmpty( table )
	for k, v in pairs( table ) do return false end return true
end

hook.Add("PS2_PlayerFullyLoaded", "LoadCraftings", function(ply) 
	timer.Simple(2, function() 
		sendCraftings(ply)
	end)
end)

timer.Simple( 0.1, function() CraftSystem.Craftings = util.JSONToTable( file.Read( "crafts.dat", "DATA" ) or "[]" ) end )

net.Receive( "createNewCrafting", function( len, ply )
	local data = util.JSONToTable( net.ReadString() )
	for k, v in pairs( data.input.i ) do if !isValidItem(k) then return false end end
	for k, v in pairs( data.output.i ) do if !isValidItem(k) then return false end end
	if tableIsEmpty( data.input.i ) or tableIsEmpty( data.output.i ) then return false end
	if data.input.m and not isnumber(data.input.m) then
		ply:ChatPrint( "Invalid money input" )
		return false
	end
	if data.output.m and not isnumber(data.output.m) then
		ply:ChatPrint( "Invalid money output" )
		return false
	end
	createNewCraftings( data.input, data.output )
end )

net.Receive( "removeCrafting", function()
	table.remove( CraftSystem.Craftings, net.ReadInt( 10 ) )
	file.Write( "crafts.dat", util.TableToJSON( CraftSystem.Craftings ) )
	sendCraftings()
end )

local function craft( ply, craftingId )
	local restInputs = ply.PS2_Inventory:getItems()
	if (table.Count( restInputs ) <= 0) then return false end
	local tbl = CraftSystem.Craftings[craftingId]
	local restCraftInputs = table.Copy( tbl.i.i )
	local localRestInputs = table.Copy( restInputs )
	for k, v in pairs( table.Copy( tbl.i.i ) ) do
		for i, d in pairs( localRestInputs ) do
			if v.i == d.class.name then
				restCraftInputs[k] = nil
				localRestInputs[i] = nil
				break
			end
		end
	end

	if table.Count( restCraftInputs ) <= 0 and (tbl.i.m and tbl.i.m <= ply.PS2_Wallet.points or !tbl.i.m) then
		if tbl.i.m != nil then
			ply:PS2_AddStandardPoints( -tbl.i.m )
		end
		for k, v in pairs( CraftSystem.Craftings[craftingId].i.i ) do
			ply:PS2_EasyRemoveItem( GetItemByClassName( v.i ).__instanceDict.PrintName )
		end
		if tbl.o.m then
			ply:PS2_AddStandardPoints( tbl.o.m )
		end
		for k, v in pairs( CraftSystem.Craftings[craftingId].o.i ) do
			if v.p then
				if math.random( 0, 100 ) < v.p then
					ply:PS2_EasyAddItem( GetItemByClassName( v.i ).className )
				end
			else
				ply:PS2_EasyAddItem( GetItemByClassName( v.i ).className )
			end
		end
	end
end

net.Receive( "craftItem", function( len, ply )
	local craftId = net.ReadInt( 10 )
	craft( ply, craftId )
end )

local Player = FindMetaTable( "Player" )
function Player:PS2_EasyRemoveItem( displayName )
    local itemClass
    for _, class in pairs(KInventory.Items) do
        if class.PrintName and string.lower(class.PrintName) == string.lower(displayName) then
            itemClass = class.className
            break
        end
    end      
    if not itemClass then Promise.Reject( 1, "Cant't remove item. Item does not exist: "..displayName ) return false end
 
    local items = self.PS2_Inventory:getItems()
 
    local item
    for k,v in pairs(items) do
        if (tonumber(v.class.className) == tonumber(itemClass)) then item = v break end
    end
 
    if not item then Promise.Reject( 1, string.format("Can't remove %s from %s (%s). They don't have any of this item.",displayName,self:Nick(),self:SteamID())) return false end
    local def
    if self.PS2_Inventory:containsItem( item ) then
        def = self.PS2_Inventory:removeItem( item )
    end
   
    def:Then( function( )
        item:OnHolster( )
        item:OnSold( )
    end )
    :Then( function( )
        KInventory.ITEMS[item.id] = nil
        return item:remove( )
    end )
    return true
end