-- 全局配置配置信息
local ITEM_ENTRY = 1179 -- 指定可以调用 Buff 储存器界面的物品 Entry ID

-- 引用的数据库表名

local SKILLS_TABLE = "_玩家buff存储器_可用技能" -- 存储允许保存的 Buff 列表
local BANK_TABLE = "_玩家buff存储器_银行" -- 存储玩家已保存的 Buff

-- 偏移量，用于不同功能查询的技能显示菜单 ID
local STORE_BUFF_OFFSET = 100000000
local RETRIEVE_BUFF_OFFSET = 200000000
local FORGET_BUFF_OFFSET = 300000000

-- 调试日志函数
local function DebugLog(message)
    print("[DEBUG] " .. tostring(message))
end

-- 模块 1: 存储 Buff 功能
local function ShowStoreBuffMenu(event, player, item)
    DebugLog("玩家选择 存储 Buff 菜单")

    player:GossipClearMenu()
    local query = string.format("SELECT 技能ID FROM %s", SKILLS_TABLE)
    DebugLog("SQL 查询 - 获取允许存储的技能列表: " .. query)

    local result = WorldDBQuery(query)
    if not result then
        player:SendBroadcastMessage("未配置允许存储的技能列表！")
        return
    end

    repeat
        local buffId = result:GetUInt32(0)
        if player:HasAura(buffId) then
            player:GossipMenuAddItem(0, "存储 Buff: " .. buffId, 1, STORE_BUFF_OFFSET + buffId)
		else
		player:SendBroadcastMessage("你的大脑袋上没有可存储的buff！")
			return
        end
    until not result:NextRow()

    player:GossipSendMenu(1, item)
end

local function HandleStoreBuffSelection(player, intid)
    local buffId = intid - STORE_BUFF_OFFSET
    DebugLog("玩家选择存储 Buff: " .. tostring(buffId))


	-- 查询玩家是否已存储该 Buff
	local accountId = player:GetAccountId()
	local charId = player:GetGUIDLow()

	local query = string.format(
		"SELECT COUNT(*) FROM %s WHERE 玩家账号id = %d AND 角色id = %d AND 获得的buff法术id = %d",
		BANK_TABLE, accountId, charId, buffId
	)
	DebugLog("SQL 查询 - 检查是否已存储该 Buff: " .. query)

	-- 执行查询
	local result = WorldDBQuery(query)
	if result and result:GetUInt32(0) > 0 then
		player:SendBroadcastMessage("已存储过该 Buff！")
		return
	end
	   
	    local insertQuery = string.format(
        "INSERT INTO %s (玩家账号id, 角色id, 获得的buff法术id) VALUES (%d, %d, %d)",
        BANK_TABLE, accountId, charId, buffId
    )
	
	
    DebugLog(" 存储 Buff: " .. insertQuery)
    WorldDBExecute(insertQuery)

    --player:RemoveAura(buffId)    -- 从玩家身上中移除 Buff[先取消这个移除功能，让buff可以依旧可用]
    player:SendBroadcastMessage("成功存储 Buff: " .. buffId)
	

	
end

-- 模块 2: 取出 Buff 功能
local function ShowRetrieveBuffMenu(event, player, item)
    DebugLog("玩家选择 取出 Buff 菜单")

    player:GossipClearMenu()
    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()

    local query = string.format(
        "SELECT 获得的buff法术id FROM %s WHERE 玩家账号id = %d AND 角色id = %d",
        BANK_TABLE, accountId, charId
    )
    DebugLog("SQL 查询 - 查询玩家存储的 Buff: " .. query)

    local result = WorldDBQuery(query)
    if not result then
        player:SendBroadcastMessage("没有存储任何 Buff！")
        return
    end

    repeat
        local buffId = result:GetUInt32(0)
        player:GossipMenuAddItem(0, "取出 Buff: " .. buffId, 1, RETRIEVE_BUFF_OFFSET + buffId)
    until not result:NextRow()

    player:GossipSendMenu(1, item)
end

local function HandleRetrieveBuffSelection(player, intid)
    local buffId = intid - RETRIEVE_BUFF_OFFSET
    DebugLog("玩家选择取出 Buff: " .. tostring(buffId))

    -- 从数据库中移除 Buff[先取消这个移除功能，让存储的buff可以一次存储，终身享用]
    -- local accountId = player:GetAccountId()
    -- local charId = player:GetGUIDLow()

    -- local deleteQuery = string.format(
        -- "DELETE FROM %s WHERE 玩家账号id = %d AND 角色id = %d AND 获得的buff法术id = %d",
        -- BANK_TABLE, accountId, charId, buffId
    -- )
    -- DebugLog("SQL 查询 - 取出 Buff: " .. deleteQuery)
    -- WorldDBExecute(deleteQuery)

    player:AddAura(buffId, player)
    player:SendBroadcastMessage("成功取出 Buff: " .. buffId)

end

-- 模块 3: 遗忘 Buff 功能
local function ShowForgetBuffMenu(event, player, item)
    DebugLog("玩家选择 遗忘 Buff 菜单")

    player:GossipClearMenu()
    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()

    local query = string.format(
        "SELECT 获得的buff法术id FROM %s WHERE 玩家账号id = %d AND 角色id = %d",
        BANK_TABLE, accountId, charId
    )
    DebugLog("SQL 查询 - 查询玩家存储的 Buff: " .. query)

    local result = WorldDBQuery(query)
    if not result then
        player:SendBroadcastMessage("没有存储任何 Buff！")
        return
    end

    repeat
        local buffId = result:GetUInt32(0)
        player:GossipMenuAddItem(0, "遗忘 Buff: " .. buffId, 1, FORGET_BUFF_OFFSET + buffId)
    until not result:NextRow()

    player:GossipSendMenu(1, item)
end

local function HandleForgetBuffSelection(player, intid)
    local buffId = intid - FORGET_BUFF_OFFSET
    DebugLog("玩家选择遗忘 Buff: " .. tostring(buffId))

    -- 从数据库中移除 Buff
    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()

    local deleteQuery = string.format(
        "DELETE FROM %s WHERE 玩家账号id = %d AND 角色id = %d AND 获得的buff法术id = %d",
        BANK_TABLE, accountId, charId, buffId
    )
    DebugLog("SQL 查询 - 遗忘 Buff: " .. deleteQuery)
    WorldDBExecute(deleteQuery)

    player:SendBroadcastMessage("成功遗忘 Buff: " .. buffId)

end

-- 模块 4: 主菜单

local function ShowMainMenu(event, player, item)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "存储 Buff", 1, 1)
    player:GossipMenuAddItem(0, "取出 Buff", 1, 2)
    player:GossipMenuAddItem(0, "遗忘 Buff", 1, 3)
    player:GossipSendMenu(1, item)

end

-- 模块 5: 菜单处理逻辑
local function HandleGossipSelect(event, player, item, sender, intid)

    if intid == 1 then
        ShowStoreBuffMenu(event, player, item)
    elseif intid == 2 then
        ShowRetrieveBuffMenu(event, player, item)
    elseif intid == 3 then
        ShowForgetBuffMenu(event, player, item)
    elseif intid >= STORE_BUFF_OFFSET and intid < RETRIEVE_BUFF_OFFSET then
        HandleStoreBuffSelection(player, intid)
    elseif intid >= RETRIEVE_BUFF_OFFSET and intid < FORGET_BUFF_OFFSET then
        HandleRetrieveBuffSelection(player, intid)
    elseif intid >= FORGET_BUFF_OFFSET then
        HandleForgetBuffSelection(player, intid)
    else
        DebugLog("未知的菜单选项: " .. tostring(intid))
    end
end

-- 注册事件
RegisterItemGossipEvent(ITEM_ENTRY, 1, ShowMainMenu)
RegisterItemGossipEvent(ITEM_ENTRY, 2, HandleGossipSelect)