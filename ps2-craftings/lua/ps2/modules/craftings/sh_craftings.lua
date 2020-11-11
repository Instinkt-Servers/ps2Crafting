CraftSystem = {}
CraftSystem.Craftings = {}

function GetItemByClassName( className )
	for k, v in pairs( Pointshop2:GetRegisteredItems() ) do
		if v.name == className then
			return v
		end
	end
	return nil
end