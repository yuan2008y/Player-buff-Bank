-- 全局配置配置信息
local ITEM_ENTRY = 1179 -- 指定可以调用 Buff 存储器界面的物品 Entry ID

-- 引用的数据库表名
local SKILLS_TABLE = "_玩家buff存储器_可用技能" -- 存储允许保存的 Buff 列表
local BANK_TABLE = "_玩家buff存储器_银行" -- 存储玩家已保存的 Buff

-- 偏移量，用于不同功能查询的技能显示菜单 ID
local STORE_BUFF_OFFSET = 100000000
local RETRIEVE_BUFF_OFFSET = 200000000
local FORGET_BUFF_OFFSET = 300000000

-- 获取技能名称的函数（从数据库读取）
local function GetSkillName(buffId)
    local query = string.format("SELECT 技能名字 FROM %s WHERE 技能ID = %d", SKILLS_TABLE, buffId)
    local result = WorldDBQuery(query)
    if result then
        return result:GetString(0) or "未知技能"
    else
        return "未知技能"
    end
end

-- 模块 1: 存储 Buff 功能
local function ShowStoreBuffMenu(event, player, item)
    player:GossipClearMenu()
    local query = string.format("SELECT 技能ID, 技能名字 FROM %s", SKILLS_TABLE)
    local result = WorldDBQuery(query)

    if not result then
        player:SendBroadcastMessage("未配置允许存储的技能列表！")
        return
    end

    local hasBuffToStore = false

    repeat
        local buffId = result:GetUInt32(0)
        local buffName = result:GetString(1) -- 从数据库中读取技能名字
        if player:HasAura(buffId) then
            player:GossipMenuAddItem(3, "存储 Buff: " .. buffId .. " [" .. buffName .. "]", 1, STORE_BUFF_OFFSET + buffId)
            hasBuffToStore = true
        end
    until not result:NextRow()

    if not hasBuffToStore then
        player:SendBroadcastMessage("你没有任何可存储的 Buff！")
        return
    end

    player:GossipSendMenu(1, item)
end

local function HandleStoreBuffSelection(player, intid, item)
    local buffId = intid - STORE_BUFF_OFFSET

    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()

    local query = string.format(
        "SELECT COUNT(*) FROM %s WHERE 玩家账号id = %d AND 角色id = %d AND 获得的buff法术id = %d",
        BANK_TABLE, accountId, charId, buffId
    )
    local result = WorldDBQuery(query)

    if result and result:GetUInt32(0) > 0 then
        player:SendBroadcastMessage("该 Buff 已存储过！")
        ShowStoreBuffMenu(nil, player, item)
        return
    end

    local insertQuery = string.format(
        "INSERT INTO %s (玩家账号id, 角色id, 获得的buff法术id) VALUES (%d, %d, %d)",
        BANK_TABLE, accountId, charId, buffId
    )
    WorldDBExecute(insertQuery)

    player:SendBroadcastMessage("成功存储 Buff: " .. buffId)
    ShowStoreBuffMenu(nil, player, item)
end

-- 模块 2: 取出 Buff 功能
local function ShowRetrieveBuffMenu(event, player, item)
    player:GossipClearMenu()
    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()

    local query = string.format(
        "SELECT 获得的buff法术id FROM %s WHERE 玩家账号id = %d AND 角色id = %d",
        BANK_TABLE, accountId, charId
    )
    local result = WorldDBQuery(query)

    if not result then
        player:SendBroadcastMessage("没有存储任何 Buff！")
        return
    end

    repeat
        local buffId = result:GetUInt32(0)
        local buffName = GetSkillName(buffId) -- 从数据库读取技能名字
        player:GossipMenuAddItem(4, "取出 Buff: " .. buffId .. " [" .. buffName .. "]", 1, RETRIEVE_BUFF_OFFSET + buffId)
    until not result:NextRow()

    player:GossipSendMenu(1, item)
end

local function HandleRetrieveBuffSelection(player, intid, item)
    local buffId = intid - RETRIEVE_BUFF_OFFSET
    player:AddAura(buffId, player)
    player:SendBroadcastMessage("你成功取出了 Buff: " .. buffId .. "，现在它已经应用到你的身上！")
    ShowRetrieveBuffMenu(nil, player, item)
end

-- 模块 3: 遗忘 Buff 功能
local function ShowForgetBuffMenu(event, player, item)
    player:GossipClearMenu()
    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()

    local query = string.format(
        "SELECT 获得的buff法术id FROM %s WHERE 玩家账号id = %d AND 角色id = %d",
        BANK_TABLE, accountId, charId
    )
    local result = WorldDBQuery(query)

    if not result then
        player:SendBroadcastMessage("没有存储任何 Buff！")
        return
    end

    repeat
        local buffId = result:GetUInt32(0)
        local buffName = GetSkillName(buffId) -- 从数据库读取技能名字
        player:GossipMenuAddItem(9, "遗忘 Buff: " .. buffId .. " [" .. buffName .. "]", 1, FORGET_BUFF_OFFSET + buffId)
    until not result:NextRow()

    player:GossipSendMenu(1, item)
end

local function HandleForgetBuffSelection(player, intid, item)
    local buffId = intid - FORGET_BUFF_OFFSET

    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()

    local deleteQuery = string.format(
        "DELETE FROM %s WHERE 玩家账号id = %d AND 角色id = %d AND 获得的buff法术id = %d",
        BANK_TABLE, accountId, charId, buffId
    )
    WorldDBExecute(deleteQuery)

    player:SendBroadcastMessage("你已经遗忘了 Buff: " .. buffId)
    ShowForgetBuffMenu(nil, player, item)
end

-- 模块 4: 主菜单
local function ShowMainMenu(event, player, item)
    player:GossipClearMenu()
    player:GossipMenuAddItem(3, "存储 Buff", 1, 1)
    player:GossipMenuAddItem(4, "取出 Buff", 1, 2)
    player:GossipMenuAddItem(9, "遗忘 Buff", 1, 3)
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
        HandleStoreBuffSelection(player, intid, item)
    elseif intid >= RETRIEVE_BUFF_OFFSET and intid < FORGET_BUFF_OFFSET then
        HandleRetrieveBuffSelection(player, intid, item)
    elseif intid >= FORGET_BUFF_OFFSET then
        HandleForgetBuffSelection(player, intid, item)
    else
        player:SendBroadcastMessage("未知的操作，请重试！")
    end
end

-- 注册事件
RegisterItemGossipEvent(ITEM_ENTRY, 1, ShowMainMenu)
RegisterItemGossipEvent(ITEM_ENTRY, 2, HandleGossipSelect)
