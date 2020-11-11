local adminFrame

local function genCraftingsList()
	local craftsList = vgui.Create( "DFrame" )
	craftsList:SetSize( 800, 600 )
	craftsList:SetTitle( "Crafts List" )
	craftsList:Center()
	function craftsList:OnRemove() RunConsoleCommand( "craftings_admin" ) end
	function craftsList.Paint( self, w, h )
		draw.RoundedBox( 5, 0, 0, w, h, Color( 25, 25, 25, 240 ) )
		draw.RoundedBoxEx( 5, 0, 0, w, 25, Color( 25, 25, 25, 255 ), true, true, false, false )
	end
	craftsList:MakePopup()

	local craftsListView = vgui.Create( "DListView", craftsList )
	craftsListView:Dock( FILL )
	craftsListView:SetMultiSelect( false )
	craftsListView:AddColumn( "UID" )
	craftsListView:AddColumn( "Inputs" )
	craftsListView:AddColumn( "Outputs" )
	function craftsListView.Paint( self, w, h )
		draw.RoundedBox( 5, 0, 0, w, h, Color( 125, 125, 125, 240 ) )
	end


	for k, v in pairs( CraftSystem.Craftings ) do
		local inputs, outputs = "[ '", "[ '"
		for uid, tbl in pairs( v.i.i ) do
			inputs = inputs..GetItemByClassName( tbl.i ).__instanceDict.PrintName.."' + '"
		end
		inputs = string.Left( inputs, string.len(inputs)-4 ).." ]"
		if v.i.m then
			inputs = inputs.." + Money = "..v.i.m
		end

		for uid, tbl in pairs( v.o.i ) do
			outputs = outputs..GetItemByClassName( tbl.i ).__instanceDict.PrintName
			if tbl.p then
				outputs = outputs.."("..tbl.p.."%)"
			end
			outputs = outputs .."' + '"
		end
		outputs = string.Left( outputs, string.len(outputs)-4 ).."' ]"
		if v.o.m then
			outputs = outputs.." + Money = "..v.o.m
		end

		craftsListView:AddLine( k, inputs, outputs )
	end

	craftsListView.OnRowSelected = function( lst, index, pnl )
		local dmenu = DermaMenu( craftsList )
		local option = dmenu:AddOption( "Remove", function()
			net.Start( "removeCrafting" )
				net.WriteInt( pnl:GetColumnText( 1 ), 10 )
			net.SendToServer()
			craftsList:Remove()
		end )
		option:SetIcon( "icon16/cancel.png" )
		dmenu:Open()
	end
end

concommand.Add( "craftings_admin", function( ply )
	if ply != LocalPlayer() then return false end
	if ply:IsAdmin() then
		if adminFrame then adminFrame:Remove() end
		adminFrame = vgui.Create( "DFrame" )
		adminFrame:SetTitle( "PS2 Crafting Admin Panel" )
		adminFrame:SetSize( 400, 650 )
		adminFrame:SetDraggable( false )
		adminFrame:Center()
		function adminFrame:OnRemove() adminFrame = nil end
		function adminFrame.Paint( self, w, h )
			draw.RoundedBox( 5, 0, 0, w, h, Color( 25, 25, 25, 240 ) )
			draw.RoundedBoxEx( 5, 0, 0, w, 25, Color( 25, 25, 25, 255 ), true, true, false, false )
		end
		adminFrame:MakePopup()

		adminFrame.items = {}
		for d=1, 8 do
			local itemLabel = vgui.Create( "DLabel", adminFrame )
			itemLabel:SetPos( 5, 5+27*d )
			itemLabel:SetWide( adminFrame:GetWide()*0.25 )
			itemLabel:SetText( "Item Input "..d..":" )
			itemLabel:SetFont( "HudHintTextLarge" )

			adminFrame.items[d] = vgui.Create( "DComboBox", adminFrame )
			adminFrame.items[d]:Dock( TOP )
			adminFrame.items[d]:DockMargin( adminFrame:GetWide()*0.25, 5, 5, 0 )
			adminFrame.items[d]:SetValue( "None" )
			adminFrame.items[d]:AddChoice( "None" )

			for k, v in pairs( Pointshop2:GetRegisteredItems( ) ) do
				adminFrame.items[d]:AddChoice( v.__instanceDict.PrintName, Pointshop2.GetItemClassByPrintName( v.__instanceDict.PrintName ) )
			end
			local itm = adminFrame.items[d]
			function itm:OnSelect( index, text, data )
				if data == "None" then itm.selected = nil return end
				itm.selected = data.name
			end
		end

		local itemLabel = vgui.Create( "DLabel", adminFrame )
		itemLabel:SetPos( 5, 248 )
		itemLabel:SetWide( adminFrame:GetWide()*0.25 )
		itemLabel:SetText( "Money Input:" )
		itemLabel:SetFont( "HudHintTextLarge" )

		adminFrame.moneyInput = vgui.Create( "DNumberWang", adminFrame )
		adminFrame.moneyInput:Dock( TOP )
		adminFrame.moneyInput:DockMargin( adminFrame:GetWide()*0.25, 5, 5, 0 )

		local inputEnd = vgui.Create( "DLabel", adminFrame )
		inputEnd:SetPos( 0, 280 )
		inputEnd:SetContentAlignment( 5 )
		inputEnd:SetWide( adminFrame:GetWide()-50 )
		inputEnd:SetText( "-----Output-----" )
		inputEnd:SetFont( "Trebuchet24" )

		adminFrame.itemsOut = {}
		adminFrame.prob = {}

		local initMargin = 40
		for d=1, 8 do
			local itemLabel = vgui.Create( "DLabel", adminFrame )
			itemLabel:SetPos( 5, 280+27*d )
			itemLabel:SetText( "Item Output "..d..":" )
			itemLabel:SetFont( "HudHintTextLarge" )
			itemLabel:SetWide( adminFrame:GetWide()*0.25 )

			adminFrame.itemsOut[d] = vgui.Create( "DComboBox", adminFrame )
			adminFrame.itemsOut[d]:Dock( TOP )
			adminFrame.itemsOut[d]:DockMargin( adminFrame:GetWide()*0.25, initMargin, 50, 0 )
			adminFrame.itemsOut[d]:SetValue( "None" )
			adminFrame.itemsOut[d]:AddChoice( "None" )
			initMargin = 5
			for k, v in pairs( Pointshop2:GetRegisteredItems() ) do
				adminFrame.itemsOut[d]:AddChoice( v.__instanceDict.PrintName, Pointshop2.GetItemClassByPrintName( v.__instanceDict.PrintName ) )
			end
			local itm = adminFrame.itemsOut[d]
			function itm:OnSelect( index, text, data )
				if data == "None" then itm.selected = nil return end
				itm.selected = data.name
			end
			adminFrame.prob[d] = vgui.Create( "DNumberWang", adminFrame )
			adminFrame.prob[d]:SetPos( 355, 284+27*d )
			adminFrame.prob[d]:SetWidth( 40 )
		end
		
		local probLabel = vgui.Create( "DLabel", adminFrame )
		probLabel:SetPos( 270, 280 )
		probLabel:SetText( "Probab. (1-100)%" )
		probLabel:SetFont( "HudHintTextLarge" )
		probLabel:SetWide( adminFrame:GetWide()*0.45 )

		local itemLabel = vgui.Create( "DLabel", adminFrame )
		itemLabel:SetPos( 5, 523 )
		itemLabel:SetWide( adminFrame:GetWide()*0.25 )
		itemLabel:SetText( "Money Output:" )
		itemLabel:SetFont( "HudHintTextLarge" )

		adminFrame.moneyOutput = vgui.Create( "DNumberWang", adminFrame )
		adminFrame.moneyOutput:Dock( TOP )
		adminFrame.moneyOutput:DockMargin( adminFrame:GetWide()*0.25, 5, 5, 0 )

		local addButton = vgui.Create( "DButton", adminFrame )
		addButton:SetTall( 40 )
		addButton:Dock( TOP )
		addButton:DockMargin( 5, 10, 5, 0 )
		addButton:SetText( "Add Crafting" )
		addButton:SetFont( "DermaLarge" )
		function addButton.Paint( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, self:IsHovered() and Color( 45, 45, 45, 255 ) or Color( 35, 35, 35, 255 ) ) end
		function addButton.DoClick()
			local data = { input = { i = {} }, output = { i = {} } }
			for k, v in pairs( adminFrame.items ) do
				if v.selected then
					table.insert( data.input.i, 1, { i = v.selected } )
				end
			end
			if adminFrame.moneyInput:GetValue() != 0 then data.input.m = adminFrame.moneyInput:GetValue() end
			for k, v in pairs( adminFrame.itemsOut ) do
				if v.selected then
					table.insert( data.output.i, 1, { i = v.selected, p = ( ( adminFrame.prob[k]:GetValue() != 0 and adminFrame.prob[k]:GetValue() ) or 100) } )
				end
			end
			if adminFrame.moneyOutput:GetValue() != 0 then data.output.m = adminFrame.moneyOutput:GetValue() end
			net.Start( "createNewCrafting" )
				net.WriteString( util.TableToJSON( data ) )
			net.SendToServer()
			adminFrame:Remove()
			RunConsoleCommand( "craftings_admin" )
		end

		local craftingsList = vgui.Create( "DButton", adminFrame )
		craftingsList:SetTall( 40 )
		craftingsList:Dock( TOP )
		craftingsList:DockMargin( 5, 5, 5, 0 )
		craftingsList:SetText( "Crafts List" )
		craftingsList:SetFont( "DermaLarge" )
		function craftingsList.Paint( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, self:IsHovered() and Color( 45, 45, 45, 255 ) or Color( 35, 35, 35, 255 ) ) end
		function craftingsList.DoClick()
			genCraftingsList()
			adminFrame:Remove()
		end
	end
end )