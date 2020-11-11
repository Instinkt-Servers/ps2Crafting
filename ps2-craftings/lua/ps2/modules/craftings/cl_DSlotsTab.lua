local PANEL = {}

local generatedGuideFunc

function PANEL:Init()
	local function checkIfValidCraft()
		if self.topContainer.creaftButton then
			local restInputs = {}
			restInputs.i = {}
			//i save all the ids of items the player has inside the crafting slots
			for k, v in pairs(self.item) do
				if v.itemStack and v.itemStack.items and v.itemStack.items[1] and v.itemStack.items[1].class then
					table.insert( restInputs.i, 1, v.itemStack.items[1].class.name )
				end
			end
			if (table.Count( restInputs.i ) <= 0) then self.topContainer.creaftButton:SetEnabled( false ) return false end
			restInputs.m = self.topContainer.moneyInput:GetValue()
			for index, tbl in pairs( CraftSystem.Craftings ) do
				local restCraftInputs = table.Copy( tbl.i.i )
				local localRestInputs = table.Copy( restInputs.i )
				for k, v in pairs( table.Copy( tbl.i.i ) ) do
					for i, d in pairs( localRestInputs ) do
						if v.i == d then
							restCraftInputs[k] = nil
							localRestInputs[i] = nil
							break
						end
					end
				end
				if table.Count( localRestInputs ) <= 0 and table.Count( restCraftInputs ) <= 0 and (tbl.i.m == restInputs.m or !tbl.i.m) then
					self.topContainer.creaftButton.craft = index
					self.topContainer.creaftButton:SetEnabled( true )
					return true
				end
			end
			self.topContainer.creaftButton:SetEnabled( false )
			return false
		end
	end
	self:DockPadding( 10, 10, 10, 10 )
	self:SetSkin( Pointshop2.Config.DermaSkin )

	self.left = vgui.Create( "DPanel", self )
	self.left:Dock( LEFT )
	self.left:SizeToContents()
	self.left:DockMargin( 0, 0, 5, 0 )
	self.left:DockPadding( 10, 5, 10, 5 )
	Derma_Hook( self.left, "Paint", "Paint", "InnerPanel" )

	self.left.label = vgui.Create( "DLabel", self.left )
	self.left.label:SetText( "Crafting" )
	self.left.label:SizeToContents( )
	self.left.label:Dock( TOP )
	self.left.label:DockMargin( 0, 0, 0, 5 )

	self.topContainer = vgui.Create( "DPanel", self.left )
	self.topContainer:Dock( TOP )
	self.topContainer:SetTall( 260 )
	self.topContainer.Paint = function( ) end
	Derma_Hook( self.topContainer, "Paint", "Paint", "InnerPanelBright" )

	self.item = {}
	self.plus = {}
	self.topContainer.itemName = {}

	local wide = 470

	for k = 1, 8 do
		self.item[k] = vgui.Create( "DItemSlot", self.topContainer )
		local d = k
		local hPos = 10
		if k > 4 then
			hPos = hPos+94
			d = d-4
		end
		self.item[k]:SetPos( (wide/5*d)-32, hPos )
		self.item[k]:SetSize( 64, 64 )
		local item = self.item[k]
		function item:OnModified()
			generateCraftGuide()
			checkIfValidCraft()
			if table.Count( self.itemStack.items ) == 0 then
				self:GetParent().itemName[k]:SetText( "Item "..k )
			elseif self.itemStack.items[1].class then
				self:GetParent().itemName[k]:SetText( self.itemStack.items[1].class.__instanceDict.PrintName )
			end
		end

		if k < 4 then
			self.plus[k] = vgui.Create( "DLabel", self.topContainer )
			self.plus[k]:SetText( "+" )
			self.plus[k]:SetContentAlignment( 5 )
			self.plus[k]:SetFont( "CloseCaption_Bold" )
			self.plus[k]:SetPos( wide/5*k+32, 80 )
			self.plus[k]:SetSize( 32, 32 )
		end

		self.topContainer.itemName[k] = vgui.Create( "DLabel", self.topContainer )
		self.topContainer.itemName[k]:SetText( "Item "..k )
		self.topContainer.itemName[k]:SetContentAlignment( 5 )
		self.topContainer.itemName[k]:SetFont( "HudHintTextLarge" )
		self.topContainer.itemName[k]:SetPos( (wide/5*d)-50, hPos+64 )
		self.topContainer.itemName[k]:SetSize( 100, 20 )
	end

	self.topContainer.moneyLabel = vgui.Create( "DLabel", self.topContainer )
	self.topContainer.moneyLabel:SetPos( 470/2-70, self.topContainer:GetTall()-70 )
	self.topContainer.moneyLabel:SetText( "Money: " )

	self.topContainer.moneyInput = vgui.Create( "DNumberWang", self.topContainer )
	self.topContainer.moneyInput:SetSize( 60, 20 )
	self.topContainer.moneyInput:SetPos( 470/2-30, self.topContainer:GetTall()-70 )
	function self.topContainer.moneyInput:OnValueChanged()
		generateCraftGuide()
		checkIfValidCraft()
	end

	self.topContainer.creaftButton = vgui.Create( "DButton", self.topContainer )
	self.topContainer.creaftButton:SetSize( 100, 40 )
	self.topContainer.creaftButton:SetPos( 470/2-50, self.topContainer:GetTall()-45 )
	self.topContainer.creaftButton:SetDisabled( true )
	self.topContainer.creaftButton:SetText( "Craft" )
	local cooldown = 0
	function self.topContainer.creaftButton.DoClick()
		if CurTime() < cooldown then return end
		if !checkIfValidCraft() then return end
		cooldown = CurTime() + 2
		self.topContainer.creaftButton:SetEnabled( false )
		for k, v in pairs( self.item ) do
			v:removeItem()
			self.topContainer.itemName[k]:SetText( "Item "..k )

			self.invPanel:setItems( LocalPlayer( ).PS2_Inventory:getItems( ) )
			self.invPanel:initSlots( LocalPlayer( ).PS2_Inventory:getNumSlots( ) )
			self.bottomContainer.dscroll:Remove()
			timer.Simple( 1, function()
				generateCraftGuide()
			end )
		end
		net.Start( "craftItem" )
			net.WriteInt( self.topContainer.creaftButton.craft or -1, 10 )
		net.SendToServer()
	end

	self.right = vgui.Create( "DPanel", self )
	self.right:Dock( RIGHT )
	self.right:DockMargin( 5, 0, 0, 0 )
	self.right:DockPadding( 10, 5, 10, 5 )
	Derma_Hook( self.right, "Paint", "Paint", "InventoryBackground" )

	self.right.label = vgui.Create( "DLabel", self.right )
	self.right.label:SetText( "Inventory" )
	self.right.label:SizeToContents( )
	self.right.label:Dock( TOP )
	self.right.label:DockMargin( 0, 0, 0, 5 )

	local invScroll = vgui.Create( "DScrollPanel", self.right )
	invScroll:Dock( FILL )
	self.right.invScroll = invScroll

	self.invPanel = vgui.Create( "DItemsContainer", invScroll )
	self.invPanel:Dock( FILL )
	self.invPanel:setCategoryName( "Pointshop2_Global" )
	self.invPanel:SetDropPos( "1" )
	self.invPanel:setItems( LocalPlayer( ).PS2_Inventory:getItems( ) )
	self.invPanel:initSlots( LocalPlayer( ).PS2_Inventory:getNumSlots( ) )
	function self.invPanel:Paint( )
	end
	hook.Add( "PS2_InvUpdate", self, function( self )
		self.invPanel:setItems( LocalPlayer( ).PS2_Inventory:getItems( ) )
		self.invPanel:initSlots( LocalPlayer( ).PS2_Inventory:getNumSlots( ) )
	end )

	hook.Add( "PS2_ItemRemoved", self, function( self, item )
		if inventory.id != LocalPlayer( ).PS2_Inventory.id then
			return
		end
		self.invPanel:itemRemoved( item.id )
		self.invPanel:setItems( LocalPlayer( ).PS2_Inventory:getItems( ) )
		self.invPanel:initSlots( LocalPlayer( ).PS2_Inventory:getNumSlots( ) )
	end )

	hook.Add( "KInv_ItemRemoved", self, function( self, inventory, itemId )
		if inventory.id != LocalPlayer( ).PS2_Inventory.id then
			return
		end
		self.invPanel:itemRemoved( itemId )
	end )

	hook.Add( "KInv_ItemAdded", self, function( self, inventory, item )
		self.invPanel:setItems( LocalPlayer( ).PS2_Inventory:getItems( ) )
		self.invPanel:initSlots( LocalPlayer( ).PS2_Inventory:getNumSlots( ) )
	end )

	self.bottomContainer = vgui.Create( "DPanel", self.left )
	self.bottomContainer:Dock( BOTTOM )
	self.bottomContainer:SetTall( 300 )
	self.bottomContainer.Paint = function() end
	Derma_Hook( self.bottomContainer, "Paint", "Paint", "InnerPanelBright" )

	self.bottomContainer.label = vgui.Create( "DLabel", self.left )
	self.bottomContainer.label:SetText( "Crafting Guide" )
	self.bottomContainer.label:SizeToContents( )
	self.bottomContainer.label:Dock( TOP )
	self.bottomContainer.label:DockMargin( 0, 0, 0, 5 )

	function generateCraftGuide()
		if self.bottomContainer.dscroll then self.bottomContainer.dscroll:Remove() self.bottomContainer.dscroll = nil end
		self.bottomContainer.dscroll = vgui.Create( "DScrollPanel", self.bottomContainer )
		self.bottomContainer.dscroll:Dock( FILL )


		for k, v in pairs( CraftSystem.Craftings ) do

			local restInputs = {}
			restInputs.i = {}
			//i save all the ids of items the player has inside the crafting slots
			for k, v in pairs(self.item) do
				if v.itemStack and v.itemStack.items and v.itemStack.items[1] and v.itemStack.items[1].class then
					table.insert( restInputs.i, 1, v.itemStack.items[1].class.name )
				end
			end
			local inputCoutner = table.Count( v.i.i )

			if v.i.m then
				inputCoutner = inputCoutner + 1
			end

			local craftItemsOutput = ""

			for index, tbl in pairs( v.o.i ) do
				craftItemsOutput = craftItemsOutput.."+"..GetItemByClassName(tbl.i).__instanceDict.PrintName.." (probabiltiy "..tbl.p.."%)\n"
			end


			local outputCoutner = table.Count( v.o.i )

			if v.o.m then
				outputCoutner = outputCoutner + 1
				craftItemsOutput = craftItemsOutput.."+"..v.o.m.."$"
			end

			local maxRowNumbers = ((inputCoutner > outputCoutner) and inputCoutner) or outputCoutner

			inputCoutner, outputCoutner = nil, nil

			local ItemPanel = self.bottomContainer.dscroll:Add( "DPanel" )
			ItemPanel:Dock( TOP )
			ItemPanel:SetTall( 13.33*maxRowNumbers+10 )
			ItemPanel:DockMargin( 5, 5, 5, 0 )
			Derma_Hook( ItemPanel, "Paint", "Paint", "InnerPanel" )

			local inputLabel = vgui.Create( "RichText", ItemPanel )
			inputLabel:InsertColorChange( 240, 42, 42, 255 )
			inputLabel:SetPos( 10, 5 )
			inputLabel:SetTall( ItemPanel:GetTall() )
			inputLabel:SetWide( 225 )
			inputLabel:SetVerticalScrollbarEnabled( false )

			for index, tbl in pairs( v.i.i ) do
				if table.HasValue( restInputs.i, tbl.i ) then
					restInputs.i [table.KeyFromValue( restInputs.i, tbl.i )] = nil
					inputLabel:InsertColorChange( 42, 240, 42, 255 )
				end
				inputLabel:AppendText( "-"..GetItemByClassName(tbl.i).__instanceDict.PrintName.."\n" )
				inputLabel:InsertColorChange( 240, 42, 42, 255 )
			end

			if v.i.m then
				if self.topContainer.moneyInput:GetValue() >= v.i.m then
					inputLabel:InsertColorChange( 42, 240, 42, 255 )			
				end
				inputLabel:AppendText( "-"..v.i.m.."$" )
			end

			local equalLabel = vgui.Create( "DLabel", ItemPanel )
			equalLabel:SetText( "=" )
			equalLabel:SetPos( 215, ItemPanel:GetTall()/2-5 )
			equalLabel:SetSize( 10, 10 )
			equalLabel:SetFont("Trebuchet24")
			equalLabel:SetContentAlignment( 5 )
			equalLabel:SetTextColor( Color( 245, 245, 245, 255 ) )

			local outpurLabel = vgui.Create( "RichText", ItemPanel )
			outpurLabel:InsertColorChange( 42, 240, 42, 255 )
			outpurLabel:AppendText( craftItemsOutput )
			outpurLabel:SetPos( 245, 5 )
			outpurLabel:SetTall( ItemPanel:GetTall() )
			outpurLabel:SetWide( 225 )
			outpurLabel:SetVerticalScrollbarEnabled( false )
		end
	end
	generateCraftGuide()
	generatedGuideFunc = true
end

net.Receive( "updateCraftings", function()
	CraftSystem.Craftings = util.JSONToTable( net.ReadString() )
	if generatedGuideFunc then
		generateCraftGuide()
	end
end )

function PANEL:PerformLayout( )
	if not self.left or not self.right then return end
	self.left:SetWide( self:GetWide( ) / 2 - 15 )
	self.right:SetWide( self:GetWide( ) / 2 - 15 )
end

function PANEL:Paint()
end

vgui.Register( "DCraftingTab", PANEL, "DPanel" )
Pointshop2:AddInventoryPanel( "Crafting", "pointshop2/small43.png", "DCraftingTab" )
