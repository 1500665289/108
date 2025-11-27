local mymod = GameMain:NewMod("mymod")

function mymod:OnEnter()
    xlua.private_accessible(CS.CangJingGeMgr)
    --藏经阁建筑上限
    CS.CangJingGeMgr.Instance.BOOK_SHELF_MEMORY = 10000
    CS.CangJingGeMgr.Instance:ResetBookSelf()
    
    --绑定选择事件（为手机优化）
    local Event = GameMain:GetMod("_Event")
    Event:RegisterEvent(g_emEvent.SelectNpc,  
    function(evt, item, objs) 
        if item ~= self.last_item then
            self.last_item = item
            self:AddBtn2Npc(evt, item, objs)
            self:AddBtn2Item(evt, item, objs)  -- 新增物品按钮
        end
    end, "mymod")
    
    -- 注册长按事件（手机专用）
    self:RegisterTouchEvents()
end

-- 注册触摸事件
function mymod:RegisterTouchEvents()
    -- 这里需要根据游戏具体的触摸事件API来调整
    -- 假设游戏有长按事件支持
    if CS.UnityEngine.Input then
        -- 可以添加长按识别逻辑
    end
end

-- 为NPC添加按钮（傀儡专用）
function mymod:AddBtn2Npc(evt, thing, objs)
    if thing ~= nil and thing.ThingType == g_emThingType.Npc and thing.IsPuppet and not thing.IsDeath then 
        thing:RemoveBtnData("装备道具")
        thing:AddBtnData(
            "装备道具", 
            "res/Sprs/ui/icon_zhuangbeidaoju01", 
            "GameMain:GetMod('mymod'):EquipItem(bind)", 
            "装备或者拾取一个道具（傀儡用）", 
            nil
        )
        
        -- 为手机添加更多便捷按钮
        thing:RemoveBtnData("打断工作")
        thing:AddBtnData(
            "打断工作", 
            "res/Sprs/ui/icon_stop", 
            "GameMain:GetMod('mymod'):ClearPuppetJob(bind)", 
            "立即停止傀儡当前工作", 
            nil
        )
    end
end

-- 为物品添加手机专用按钮
function mymod:AddBtn2Item(evt, thing, objs)
    if thing ~= nil and thing.ThingType ~= g_emThingType.Npc then
        -- 移除旧按钮
        thing:RemoveBtnData("移动物品")
        thing:RemoveBtnData("拆分物品")
        thing:RemoveBtnData("刷新法宝")
        
        -- 添加移动按钮
        thing:AddBtnData(
            "移动物品", 
            "res/Sprs/ui/icon_move", 
            "GameMain:GetMod('mymod'):ShowMoveUI(bind)", 
            "移动此物品到指定位置", 
            nil
        )
        
        -- 如果是可堆叠物品，添加拆分按钮
        if thing.def.MaxStack > 1 then
            thing:AddBtnData(
                "拆分物品", 
                "res/Sprs/ui/icon_split", 
                "GameMain:GetMod('mymod'):ShowSplitUI(bind)", 
                "拆分此物品", 
                nil
            )
        end
        
        -- 如果是法宝，添加刷新按钮
        if thing.IsFaBao then
            thing:AddBtnData(
                "刷新属性", 
                "res/Sprs/ui/icon_refresh", 
                "GameMain:GetMod('mymod'):ShowFabaoUI(bind)", 
                "刷新法宝属性", 
                nil
            )
        end
    end
end

-- 傀儡装备道具功能
function mymod:EquipItem(npc)
    list = CS.ThingUICommandDefine.sThingUICommands[CS.XiaWorld.g_emSelectThingSort.Npc]
    equip = list[7]
    equip.Act(npc, nil)
end

-- 打断傀儡工作
function mymod:ClearPuppetJob(npc)
    if npc ~= nil and npc.IsPuppet then
        npc.JobEngine:ClearJob()
        world:ShowMsgBox("已打断傀儡工作", "提示")
    end
end

-- 显示移动物品UI（手机专用）
function mymod:ShowMoveUI(item)
    if item == nil then return end
    
    -- 简单的方向选择界面
    local options = {
        "向上移动", "向下移动", "向左移动", "向右移动",
        "放到鼠标位置", "取消"
    }
    
    world:ShowOptionBox("选择移动方向", "移动物品", options, function(index)
        if index == 1 then self:MoveItem(item, 0, 1) end     -- 上
        if index == 2 then self:MoveItem(item, 0, -1) end    -- 下
        if index == 3 then self:MoveItem(item, -1, 0) end    -- 左
        if index == 4 then self:MoveItem(item, 1, 0) end   -- 右
        if index == 5 then self:MoveToMouse(item) end       -- 鼠标位置
    end)
end

-- 移动物品实现
function mymod:MoveItem(item, dx, dy)
    local currentPos = item.GridKey
    local newKey = currentPos + CS.XiaWorld.MapGrid.Key(dx, dy)
    
    if CS.XiaWorld.World.Instance.map.Things:GetItemAtGrid(newKey) ~= nil then
        world:ShowMsgBox("目标位置已有物品", "提示")
        return
    end
    
    item:PickUp()
    item:SetPostion(newKey, false, true, true, true)
    item:FixPosition()
end

-- 移动到鼠标位置
function mymod:MoveToMouse(item)
    local key = CS.UI_WorldLayer.Instance.MouseGridKey
    if CS.XiaWorld.World.Instance.map.Things:GetItemAtGrid(key) ~= nil then
        world:ShowMsgBox("鼠标所在的位置已有物品", "提示")
        return
    end
    item:PickUp()
    item:SetPostion(key, false, true, true, true)
    item:FixPosition()
end

-- 显示拆分UI
function mymod:ShowSplitUI(item)
    if item == nil or item.def.MaxStack == 1 then
        world:ShowMsgBox("不可拆分的物品", "提示")
        return
    end
    
    if item.Count <= 1 then
        world:ShowMsgBox("物品数量不足", "提示")
        return
    end
    
    -- 简单的数量选择
    local maxSplit = math.min(item.Count - 1, 10)  -- 最多拆分10个
    local options = {}
    for i = 1, maxSplit do
        table.insert(options, "拆分" .. i .. "个")
    end
    table.insert(options, "取消")
    
    world:ShowOptionBox("选择拆分数量", "拆分物品", options, function(index)
        if index <= maxSplit then
            self:SplitItem(item, index)
        end
    end)
end

-- 拆分物品实现
function mymod:SplitItem(item, count)
    local key = CS.UI_WorldLayer.Instance.MouseGridKey
    if CS.XiaWorld.World.Instance.map.Things:GetItemAtGrid(key) ~= nil then
        world:ShowMsgBox("鼠标所在的位置已有物品", "提示")
        return
    end
    
    item:SubCount(count)
    local newItem = CS.XiaWorld.ThingMgr.Instance:AddItemThing(key, item.def.Name, nil)
    if newItem then
        newItem:ChangeCount(count)
    end
end

-- 显示法宝操作UI
function mymod:ShowFabaoUI(item)
    if item == nil or not item.IsFaBao then
        world:ShowMsgBox("请选择法宝", "提示")
        return
    end
    
    local options = {
        "随机刷新属性",
        "标准属性刷新",
        "取消"
    }
    
    world:ShowOptionBox("法宝操作", "选择操作", options, function(index)
        if index == 1 then
            item.Fabao:RefuseFabaoData()
            world:ShowMsgBox("法宝属性已刷新", "提示")
        elseif index == 2 then
            item.Fabao:RefuseFabaoData(nil, false)
            item.Fabao.PS[10] = item.Fabao.PS[10] * 0.8625
            world:ShowMsgBox("法宝属性已标准化", "提示")
        end
    end)
end

-- 合并物品（手机优化版）
function mymod:CombineSelectedItems()
    local Things = CS.XiaWorld.UILogicMode_Select.Instance.SelectThings
    if Things.Count == 0 then
        world:ShowMsgBox("请选择物品", "提示")
        return
    end
    
    if Things.Count == 1 then
        world:ShowMsgBox("请选择多个同类物品", "提示")
        return
    end
    
    -- 检查物品类型
    local name = nil
    for i = 0, Things.Count - 1 do
        local v = Things[i]
        if v.def.MaxStack == 1 then
            world:ShowMsgBox("包含不可合并的物品", "提示")
            return
        end
        if name == nil then
            name = v.def.Name
        elseif name ~= v.def.Name then
            world:ShowMsgBox("物品类型不一致", "提示")
            return
        end
    end
    
    -- 执行合并
    local allcount = 0
    for i = 0, Things.Count - 1 do
        allcount = allcount + Things[i].Count
    end
    
    for i = Things.Count - 1, 0, -1 do
        if i == 0 then
            Things[i]:ChangeCount(allcount)
        else
            Things[i]:ChangeCount(0)
        end
    end
    
    world:ShowMsgBox("物品合并完成", "提示")
end

-- 为手机保留部分快捷键（可选）
function mymod:OnSetHotKey()  
    local HotKey = { 
        {ID = "QuickCombine", Name = "快速合并", Type = "Mod", InitialKey1 = "LeftAlt+D"}
    }
    return HotKey
end

function mymod:OnHotKey(ID, state)
    if state == "down" and ID == "QuickCombine" then
        self:CombineSelectedItems()
    end
end
