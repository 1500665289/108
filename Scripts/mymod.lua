local mymod = GameMain:NewMod("mymod")

function mymod:OnEnter()
	xlua.private_accessible(CS.CangJingGeMgr)
	--藏经阁建筑上限
	CS.CangJingGeMgr.Instance.BOOK_SHELF_MEMORY = 100000
	CS.CangJingGeMgr.Instance:ResetBookSelf()
	--绑定傀儡装备道具按钮
	local Event = GameMain:GetMod("_Event");
	Event:RegisterEvent(g_emEvent.SelectNpc,  
	function(evt, item, objs) 
		if item ~= self.last_item then
			self.last_item = item
			self:AddBtn2Npc(evt, item, objs); 
		end
	end, "mymod");
end

function mymod:AddBtn2Npc(evt, thing, objs)
	if thing ~= nil and thing.ThingType == g_emThingType.Npc and thing.IsPuppet and not thing.IsDeath then 
		thing:RemoveBtnData("装备道具");
		thing:AddBtnData(
			"装备道具", 
			"res/Sprs/ui/icon_zhuangbeidaoju01", 
			"GameMain:GetMod('mymod'):EquipItem(bind)", 
			"装备或者拾取一个道具（傀儡用）", 
			nil
		);
	end
end

function mymod:EquipItem(npc)
	list=CS.ThingUICommandDefine.sThingUICommands[CS.XiaWorld.g_emSelectThingSort.Npc]
	equip = list[7]
	equip.Act(npc,nil)
end


function mymod:OnSetHotKey()  
	local HotKey = { {ID = "MoveItem" , Name = "移动物品" , Type = "Mod", InitialKey1 = "LeftAlt+C" },{ID = "MoveOneItem" , Name = "拆分移动物品" , Type = "Mod", InitialKey1 = "LeftAlt+X" },{ID = "ConbineItem" , Name = "合并物品" , Type = "Mod", InitialKey1 = "LeftAlt+D" },{ID = "FlushFabao" , Name = "刷新法宝属性" , Type = "Mod", InitialKey1 = "LeftAlt+R" },{ID = "FlushFabaoFixed" , Name = "标准法宝属性" , Type = "Mod", InitialKey1 = "LeftAlt+F" },{ID = "ClearJob" , Name = "打断傀儡工作" , Type = "Mod", InitialKey1 = "LeftAlt+S" }}
	return HotKey
end

function mymod:OnHotKey(ID,state)
	if state == "down" then
		if ID == "ClearJob" then
			local npc = world:GetSelectThing()
			if npc ~= nil and npc.IsPuppet then
				npc.JobEngine:ClearJob()
			end
		end
		if ID == "FlushFabao" then
			local item = world:GetSelectThing()
			if item == nil or item.IsFaBao == false then
				world:ShowMsgBox("请选择一个法宝","提示")
			else
				item.Fabao:RefuseFabaoData()
			end
		end
		if ID == "FlushFabaoFixed" then
			local item = world:GetSelectThing()
			if item == nil or item.IsFaBao == false then
				world:ShowMsgBox("请选择一个法宝","提示")
			else
				item.Fabao:RefuseFabaoData(nil,false)
				item.Fabao.PS[10] = item.Fabao.PS[10] * 0.8625
			end
		end
		if ID == "MoveItem" then
			local item = world:GetSelectThing()
			if item == nil or item.ThingType == g_emThingType.Npc then
				world:ShowMsgBox("请选择一个物品","提示")
			else
				local key = CS.UI_WorldLayer.Instance.MouseGridKey
				if CS.XiaWorld.World.Instance.map.Things:GetItemAtGrid(key) ~= nil then
					world:ShowMsgBox("鼠标所在的位置已有物品","提示")
					return
				end
				item:PickUp()
				item:SetPostion(key,false,true,true,true)
				item:FixPosition()
			end
		end
		if ID == "MoveOneItem" then
			local item = world:GetSelectThing()
			if item == nil or item.ThingType == g_emThingType.Npc then
				world:ShowMsgBox("请选择一个物品","提示")
				return
			end
			if item.def.MaxStack == 1 then
				world:ShowMsgBox("不可拆分的物品","提示")
				return
			end
			local key = CS.UI_WorldLayer.Instance.MouseGridKey
			if CS.XiaWorld.World.Instance.map.Things:GetItemAtGrid(key) ~= nil then
				world:ShowMsgBox("鼠标所在的位置已有物品","提示")
				return
			end
			item:SubCount(1)
			CS.XiaWorld.ThingMgr.Instance:AddItemThing(key,item.def.Name,nil)
		end
		if ID == "ConbineItem" then
			local Things = CS.XiaWorld.UILogicMode_Select.Instance.SelectThings
			if Things.Count == 0 then
				world:ShowMsgBox("请选择一个物品","提示")
				return
			end
			if Things.Count == 1 then
				world:ShowMsgBox("选择多个同类物品才可合并","提示")
				return
			end
			local allcount = 0
			local name = nil
			for i,v in pairs(Things) do
				if v.def.MaxStack == 1 then
					world:ShowMsgBox("不可合并的物品","提示")
					return
				end
				if name == nil then
					name = v.def.Name
				else
					if name ~= v.def.Name then
						world:ShowMsgBox("不是同类物品","提示")
						return	
					end
				end
			end
			local i = Things.Count
			while i > 0 do 
				i = i - 1
				allcount = Things[i].Count + allcount
				if i == 0 then
					Things[i]:ChangeCount(allcount)
				else
					Things[i]:ChangeCount(0)
				end
				
			end
		end
	end
end
