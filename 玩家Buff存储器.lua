-- =============================================
-- 玩家Buff存储器 - 最终数据库配置版
-- 版本: 2.0
-- 作者: 法能
-- =============================================
-- 初始化配置表
local Config = {}

-- 从数据库加载主配置
local function LoadMainConfig()
    local query = "SELECT * FROM `_玩家buff存储器_配置`"
    local result = WorldDBQuery(query)
    
    if not result then
        error(">> [Buff存储器] 错误: 无法加载主配置")
    end
    
    repeat
        local key = result:GetString(0)
        local valueType = result:GetString(1)
        
        if valueType == "int" then
            Config[key] = result:GetUInt32(2)
        elseif valueType == "string" then
            Config[key] = result:GetString(3)
        end
    until not result:NextRow()
end

-- 从数据库加载颜色配置
local function LoadColorConfig()
    Config.COLORS = {}
    local query = "SELECT * FROM `_玩家buff存储器_颜色配置`"
    local result = WorldDBQuery(query)
    
    if not result then
        error(">> [Buff存储器] 错误: 无法加载颜色配置")
    end
    
    repeat
        local colorName = result:GetString(0)
        local colorCode = result:GetString(1)
        Config.COLORS[colorName] = "|c"..colorCode
    until not result:NextRow()
end

-- 加载所有配置
LoadMainConfig()
LoadColorConfig()

-- =============================================
-- 工具函数
-- =============================================

-- 添加分隔线
local function AddSeparator(player)
    player:GossipMenuAddItem(0, Config.COLORS.LINE.."------------------------------|r", 1, 0)
end

-- 添加标题
local function AddTitle(player, title)
    player:GossipMenuAddItem(0, Config.COLORS.TITLE..title.."|r", 1, 0)
    AddSeparator(player)
end

-- 获取玩家最大可存储Buff数量
local function GetPlayerMaxBuffs(player)
    local baseLimit = Config.BASE_MAX_STORED_BUFFS
    local accountId = player:GetAccountId()
    
    local query = string.format(
        "SELECT VIP等级 FROM %s WHERE 玩家账号id = %d",
        Config.VIP_TABLE, accountId
    )
    local result = WorldDBQuery(query)
    
    local vipLevel = result and result:GetUInt32(0) or 0
    return baseLimit + vipLevel, vipLevel
end

-- 获取技能名称
local function GetSkillName(buffId)
    local query = string.format(
        "SELECT 技能名字 FROM %s WHERE 技能ID = %d", 
        Config.SKILLS_TABLE, buffId
    )
    local result = WorldDBQuery(query)
    return result and result:GetString(0) or "未知技能"
end

-- =============================================
-- 模块1: 存储Buff功能
-- =============================================

local function ShowStoreBuffMenu(event, player, item, page)
    page = page or 1
    player:GossipClearMenu()
    
    AddTitle(player, "存储 Buff 列表")
    
    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()
    local countQuery = string.format(
        "SELECT COUNT(*) FROM %s WHERE 玩家账号id = %d AND 角色id = %d",
        Config.BANK_TABLE, accountId, charId
    )
    local countResult = WorldDBQuery(countQuery)
    local buffCount = countResult and countResult:GetUInt32(0) or 0
    local maxAllowed, vipLevel = GetPlayerMaxBuffs(player)
    
    if vipLevel > 0 then
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."当前存储: "..buffCount.."/"..maxAllowed..Config.COLORS.VIP.." (VIP+"..vipLevel..")|r", 1, 0)
    else
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."当前存储: "..buffCount.."/"..maxAllowed.."|r", 1, 0)
    end
    AddSeparator(player)
    
    local query = string.format(
        "SELECT id, 技能ID, 技能名字 FROM %s ORDER BY 技能ID",
        Config.SKILLS_TABLE
    )
    local result = WorldDBQuery(query)

    if not result then
        player:GossipMenuAddItem(0, Config.COLORS.WARNING.."未配置允许存储的技能列表！|r", 1, 0)
        AddSeparator(player)
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."返回主菜单|r", 1, 0)
        player:GossipSendMenu(1, item)
        return
    end

    local availableBuffs = {}
    repeat
        local rowId = result:GetUInt32(0)
        local buffId = result:GetUInt32(1)
        local buffName = result:GetString(2) or "未知技能"
        
        if player:HasAura(buffId) then
            local checkQuery = string.format(
                "SELECT COUNT(*) FROM %s WHERE 玩家账号id = %d AND 角色id = %d AND 获得的buff法术id = %d",
                Config.BANK_TABLE, accountId, charId, buffId
            )
            local checkResult = WorldDBQuery(checkQuery)
            local storedMark = ""
            
            if checkResult and checkResult:GetUInt32(0) > 0 then
                storedMark = Config.COLORS.GRAY.." [已存储]|r"
            end
            
            table.insert(availableBuffs, {
                rowId = rowId,
                id = buffId,
                name = buffName,
                storedMark = storedMark
            })
        end
    until not result:NextRow()

    if #availableBuffs == 0 then
        player:GossipMenuAddItem(0, Config.COLORS.WARNING.."你没有任何可存储的 Buff！|r", 1, 0)
        AddSeparator(player)
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."返回主菜单|r", 1, 0)
        player:GossipSendMenu(1, item)
        return
    end

    local totalCount = #availableBuffs
    local totalPages = math.ceil(totalCount / Config.PAGE_SIZE)
    local startIndex = (page - 1) * Config.PAGE_SIZE + 1
    local endIndex = math.min(page * Config.PAGE_SIZE, totalCount)

    for i = startIndex, endIndex do
        local buff = availableBuffs[i]
        player:GossipMenuAddItem(3, 
            Config.COLORS.STORE.."存储|r "..Config.COLORS.NORMAL..tostring(buff.id).."|r - ["..buff.name.."]"..buff.storedMark, 
            1, 
            Config.STORE_BUFF_OFFSET + buff.rowId
        )
    end

    AddSeparator(player)
    
    player:GossipMenuAddItem(0, Config.COLORS.PAGE.."第 "..page.." 页 / 共 "..totalPages.." 页|r", 1, 1)
    
    if page > 1 then
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."<< 上一页|r", 1, Config.PAGE_NAV_OFFSET + (page - 1) * 10 + 1)
    end
    
    if page < totalPages then
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."下一页 >>|r", 1, Config.PAGE_NAV_OFFSET + (page + 1) * 10 + 1)
    end
    
    AddSeparator(player)
    player:GossipMenuAddItem(0, Config.COLORS.MAIN.."返回主菜单|r", 1, 0)
    player:GossipSendMenu(1, item)
end

local function HandleStoreBuffSelection(player, intid, item)
    local rowId = intid - Config.STORE_BUFF_OFFSET
    
    local query = string.format(
        "SELECT 技能ID, 技能名字 FROM %s WHERE id = %d",
        Config.SKILLS_TABLE, rowId
    )
    local result = WorldDBQuery(query)
    
    if not result then
        player:SendBroadcastMessage(Config.COLORS.WARNING.."错误：|r"..Config.COLORS.NORMAL.."找不到对应的Buff！|r")
        ShowStoreBuffMenu(nil, player, item)
        return
    end
    
    local buffId = result:GetUInt32(0)
    local buffName = result:GetString(1) or "未知技能"
    
    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()
    local checkQuery = string.format(
        "SELECT COUNT(*) FROM %s WHERE 玩家账号id = %d AND 角色id = %d AND 获得的buff法术id = %d",
        Config.BANK_TABLE, accountId, charId, buffId
    )
    local checkResult = WorldDBQuery(checkQuery)

    if checkResult and checkResult:GetUInt32(0) > 0 then
        player:SendBroadcastMessage(Config.COLORS.WARNING.."提示：|r"..Config.COLORS.NORMAL.."你已经存储过 ["..buffName.."] 这个Buff了！|r")
        ShowStoreBuffMenu(nil, player, item)
        return
    end
    
    local countQuery = string.format(
        "SELECT COUNT(*) FROM %s WHERE 玩家账号id = %d AND 角色id = %d",
        Config.BANK_TABLE, accountId, charId
    )
    local countResult = WorldDBQuery(countQuery)
    local currentCount = countResult and countResult:GetUInt32(0) or 0
    local maxAllowed = GetPlayerMaxBuffs(player)
    
    if currentCount >= maxAllowed then
        player:SendBroadcastMessage(Config.COLORS.WARNING.."错误：|r"..Config.COLORS.NORMAL.."你已经存储了 "..currentCount.." 个Buff，达到了上限 "..maxAllowed.."！|r")
        player:SendBroadcastMessage(Config.COLORS.WARNING.."提示：|r"..Config.COLORS.NORMAL.."请先遗忘一些不需要的Buff再尝试存储新的。|r")
        ShowStoreBuffMenu(nil, player, item)
        return
    end

    local insertQuery = string.format(
        "INSERT INTO %s (玩家账号id, 角色id, 获得的buff法术id) VALUES (%d, %d, %d)",
        Config.BANK_TABLE, accountId, charId, buffId
    )
    WorldDBExecute(insertQuery)

    player:SendBroadcastMessage(Config.COLORS.STORE.."成功存储！|r"..Config.COLORS.NORMAL.."已将 ["..buffName.."] 存入你的Buff银行。|r")
    ShowStoreBuffMenu(nil, player, item)
end

-- =============================================
-- 模块2: 取出Buff功能
-- =============================================

local function ShowRetrieveBuffMenu(event, player, item, page)
    page = page or 1
    player:GossipClearMenu()
    
    AddTitle(player, "取出 Buff 列表")
    
    local query = string.format(
        "SELECT b.id, b.获得的buff法术id FROM %s b "..
        "WHERE b.玩家账号id = %d AND b.角色id = %d "..
        "ORDER BY b.获得的buff法术id",
        Config.BANK_TABLE, player:GetAccountId(), player:GetGUIDLow()
    )
    local result = WorldDBQuery(query)

    if not result then
        player:GossipMenuAddItem(0, Config.COLORS.WARNING.."你的 Buff 银行是空的！|r", 1, 0)
        AddSeparator(player)
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."返回主菜单|r", 1, 0)
        player:GossipSendMenu(1, item)
        return
    end

    local availableBuffs = {}
    repeat
        local rowId = result:GetUInt32(0)
        local buffId = result:GetUInt32(1)
        local buffName = GetSkillName(buffId)
        table.insert(availableBuffs, {
            rowId = rowId,
            id = buffId,
            name = buffName
        })
    until not result:NextRow()

    local totalCount = #availableBuffs
    local totalPages = math.ceil(totalCount / Config.PAGE_SIZE)
    local startIndex = (page - 1) * Config.PAGE_SIZE + 1
    local endIndex = math.min(page * Config.PAGE_SIZE, totalCount)

    for i = startIndex, endIndex do
        local buff = availableBuffs[i]
        player:GossipMenuAddItem(4, Config.COLORS.RETRIEVE.."取出|r "..Config.COLORS.NORMAL..tostring(buff.id).."|r - ["..buff.name.."]", 
                               1, Config.RETRIEVE_BUFF_OFFSET + buff.rowId)
    end

    AddSeparator(player)
    
    player:GossipMenuAddItem(0, Config.COLORS.PAGE.."第 "..page.." 页 / 共 "..totalPages.." 页|r", 1, 2)
    
    if page > 1 then
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."<< 上一页|r", 1, Config.PAGE_NAV_OFFSET + (page - 1) * 10 + 2)
    end
    
    if page < totalPages then
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."下一页 >>|r", 1, Config.PAGE_NAV_OFFSET + (page + 1) * 10 + 2)
    end
    
    AddSeparator(player)
    player:GossipMenuAddItem(0, Config.COLORS.MAIN.."返回主菜单|r", 1, 0)
    player:GossipSendMenu(1, item)
end

local function HandleRetrieveBuffSelection(player, intid, item)
    local rowId = intid - Config.RETRIEVE_BUFF_OFFSET
    
    local query = string.format(
        "SELECT 获得的buff法术id FROM %s WHERE id = %d",
        Config.BANK_TABLE, rowId
    )
    local result = WorldDBQuery(query)
    
    if not result then
        player:SendBroadcastMessage(Config.COLORS.WARNING.."错误：|r"..Config.COLORS.NORMAL.."找不到对应的Buff！|r")
        ShowRetrieveBuffMenu(nil, player, item)
        return
    end
    
    local buffId = result:GetUInt32(0)
    local buffName = GetSkillName(buffId)
    player:AddAura(buffId, player)
    player:SendBroadcastMessage(Config.COLORS.RETRIEVE.."成功取出！|r"..Config.COLORS.NORMAL.."Buff ["..buffName.."] 已应用到你的角色。|r")
    ShowRetrieveBuffMenu(nil, player, item)
end

-- =============================================
-- 模块3: 遗忘Buff功能
-- =============================================

local function ShowForgetBuffMenu(event, player, item, page)
    page = page or 1
    player:GossipClearMenu()
    
    AddTitle(player, "遗忘 Buff 列表")
    
    local query = string.format(
        "SELECT b.id, b.获得的buff法术id FROM %s b "..
        "WHERE b.玩家账号id = %d AND b.角色id = %d "..
        "ORDER BY b.获得的buff法术id",
        Config.BANK_TABLE, player:GetAccountId(), player:GetGUIDLow()
    )
    local result = WorldDBQuery(query)

    if not result then
        player:GossipMenuAddItem(0, Config.COLORS.WARNING.."没有可以遗忘的 Buff！|r", 1, 0)
        AddSeparator(player)
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."返回主菜单|r", 1, 0)
        player:GossipSendMenu(1, item)
        return
    end

    local availableBuffs = {}
    repeat
        local rowId = result:GetUInt32(0)
        local buffId = result:GetUInt32(1)
        local buffName = GetSkillName(buffId)
        table.insert(availableBuffs, {
            rowId = rowId,
            id = buffId,
            name = buffName
        })
    until not result:NextRow()

    local totalCount = #availableBuffs
    local totalPages = math.ceil(totalCount / Config.PAGE_SIZE)
    local startIndex = (page - 1) * Config.PAGE_SIZE + 1
    local endIndex = math.min(page * Config.PAGE_SIZE, totalCount)

    for i = startIndex, endIndex do
        local buff = availableBuffs[i]
        player:GossipMenuAddItem(9, Config.COLORS.FORGET.."遗忘|r "..Config.COLORS.NORMAL..tostring(buff.id).."|r - ["..buff.name.."]", 
                               1, Config.FORGET_BUFF_OFFSET + buff.rowId)
    end

    AddSeparator(player)
    
    player:GossipMenuAddItem(0, Config.COLORS.PAGE.."第 "..page.." 页 / 共 "..totalPages.." 页|r", 1, 3)
    
    if page > 1 then
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."<< 上一页|r", 1, Config.PAGE_NAV_OFFSET + (page - 1) * 10 + 3)
    end
    
    if page < totalPages then
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."下一页 >>|r", 1, Config.PAGE_NAV_OFFSET + (page + 1) * 10 + 3)
    end
    
    AddSeparator(player)
    player:GossipMenuAddItem(0, Config.COLORS.MAIN.."返回主菜单|r", 1, 0)
    player:GossipSendMenu(1, item)
end

local function HandleForgetBuffSelection(player, intid, item)
    local rowId = intid - Config.FORGET_BUFF_OFFSET
    
    local query = string.format(
        "SELECT 获得的buff法术id FROM %s WHERE id = %d",
        Config.BANK_TABLE, rowId
    )
    local result = WorldDBQuery(query)
    
    if not result then
        player:SendBroadcastMessage(Config.COLORS.WARNING.."错误：|r"..Config.COLORS.NORMAL.."找不到对应的Buff！|r")
        ShowForgetBuffMenu(nil, player, item)
        return
    end
    
    local buffId = result:GetUInt32(0)
    local buffName = GetSkillName(buffId)

    local deleteQuery = string.format(
        "DELETE FROM %s WHERE id = %d",
        Config.BANK_TABLE, rowId
    )
    WorldDBExecute(deleteQuery)

    player:SendBroadcastMessage(Config.COLORS.FORGET.."成功遗忘！|r"..Config.COLORS.NORMAL.."Buff ["..buffName.."] 已从你的银行中移除。|r")
    ShowForgetBuffMenu(nil, player, item)
end

-- =============================================
-- 模块4: 展示所有Buff
-- =============================================

local function ShowAllBuffMenu(event, player, item, page)
    page = page or 1
    player:GossipClearMenu()
    
    AddTitle(player, "所有可用 Buff 列表")
    
    local query = string.format(
        "SELECT id, 技能ID, 技能名字, 备注 FROM %s ORDER BY 技能ID",
        Config.SKILLS_TABLE
    )
    local result = WorldDBQuery(query)

    if not result then
        player:GossipMenuAddItem(0, Config.COLORS.WARNING.."管理员尚未配置任何可用 Buff！|r", 1, 0)
        AddSeparator(player)
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."返回主菜单|r", 1, 0)
        player:GossipSendMenu(1, item)
        return
    end

    local availableBuffs = {}
    repeat
        local rowId = result:GetUInt32(0)
        local buffId = result:GetUInt32(1)
        local buffName = result:GetString(2) or "未知技能"
        local buffRemark = result:GetString(3) or "未知备注"
        table.insert(availableBuffs, {
            rowId = rowId,
            id = buffId,
            name = buffName,
            remark = buffRemark
        })
    until not result:NextRow()

    local totalCount = #availableBuffs
    local totalPages = math.ceil(totalCount / Config.PAGE_SIZE)
    local startIndex = (page - 1) * Config.PAGE_SIZE + 1
    local endIndex = math.min(page * Config.PAGE_SIZE, totalCount)

    for i = startIndex, endIndex do
        local buff = availableBuffs[i]
        player:GossipMenuAddItem(6, Config.COLORS.ALL.."查看|r "..Config.COLORS.NORMAL..tostring(buff.id).."|r - ["..buff.name.."]".."|r - ["..buff.remark.."]", 
                               1, Config.ALL_BUFF_OFFSET + buff.rowId)
    end

    AddSeparator(player)
    
    player:GossipMenuAddItem(0, Config.COLORS.PAGE.."第 "..page.." 页 / 共 "..totalPages.." 页|r", 1, 4)
    
    if page > 1 then
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."<< 上一页|r", 1, Config.PAGE_NAV_OFFSET + (page - 1) * 10 + 4)
    end
    
    if page < totalPages then
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."下一页 >>|r", 1, Config.PAGE_NAV_OFFSET + (page + 1) * 10 + 4)
    end
    
    AddSeparator(player)
    player:GossipMenuAddItem(0, Config.COLORS.MAIN.."返回主菜单|r", 1, 0)
    player:GossipSendMenu(1, item)
end

-- =============================================
-- 模块5: 主菜单
-- =============================================

local function ShowMainMenu(event, player, item)
    player:GossipClearMenu()
    
    AddTitle(player, "玩家Buff 存储器 v 2.0 by 法能")
    
    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()
    local countQuery = string.format(
        "SELECT COUNT(*) FROM %s WHERE 玩家账号id = %d AND 角色id = %d",
        Config.BANK_TABLE, accountId, charId
    )
    local countResult = WorldDBQuery(countQuery)
    local buffCount = countResult and countResult:GetUInt32(0) or 0
    local maxAllowed, vipLevel = GetPlayerMaxBuffs(player)
    
    if vipLevel > 0 then
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."当前存储的Buff数量: |r"..Config.COLORS.NORMAL..buffCount.."/"..maxAllowed..Config.COLORS.VIP.." (VIP+"..vipLevel..")|r", 1, 0)
    else
        player:GossipMenuAddItem(0, Config.COLORS.MAIN.."当前存储的Buff数量: |r"..Config.COLORS.NORMAL..buffCount.."/"..maxAllowed.."|r", 1, 0)
    end
    AddSeparator(player)
    
    player:GossipMenuAddItem(3, Config.COLORS.STORE.."■ 存储 Buff|r", 1, 1)
    player:GossipMenuAddItem(4, Config.COLORS.RETRIEVE.."■ 取出 Buff|r", 1, 2)
    player:GossipMenuAddItem(9, Config.COLORS.FORGET.."■ 遗忘 Buff|r", 1, 3)
    player:GossipMenuAddItem(6, Config.COLORS.ALL.."■ 查看所有可用 Buff|r", 1, 4)
    
    AddSeparator(player)
    player:GossipMenuAddItem(0, Config.COLORS.GRAY.."使用说明:|r", 1, 0)
    player:GossipMenuAddItem(0, Config.COLORS.GRAY.."1. 存储: 保存你当前的Buff|r", 1, 0)
    player:GossipMenuAddItem(0, Config.COLORS.GRAY.."2. 取出: 应用已存储的Buff|r", 1, 0)
    player:GossipMenuAddItem(0, Config.COLORS.GRAY.."3. 遗忘: 删除不需要的Buff|r", 1, 0)
    
    player:GossipSendMenu(1, item)
end

-- =============================================
-- 模块6: 菜单处理逻辑
-- =============================================

local function HandleGossipSelect(event, player, item, sender, intid)
    if intid >= Config.PAGE_NAV_OFFSET then
        local page = math.floor((intid - Config.PAGE_NAV_OFFSET) / 10)
        local menuType = (intid - Config.PAGE_NAV_OFFSET) % 10
        
        if menuType == 1 then
            ShowStoreBuffMenu(event, player, item, page)
        elseif menuType == 2 then
            ShowRetrieveBuffMenu(event, player, item, page)
        elseif menuType == 3 then
            ShowForgetBuffMenu(event, player, item, page)
        elseif menuType == 4 then
            ShowAllBuffMenu(event, player, item, page)
        end
        return
    end
    
    if intid == 0 then
        ShowMainMenu(event, player, item)
    elseif intid == 1 then
        ShowStoreBuffMenu(event, player, item)
    elseif intid == 2 then
        ShowRetrieveBuffMenu(event, player, item)
    elseif intid == 3 then
        ShowForgetBuffMenu(event, player, item)
    elseif intid == 4 then
        ShowAllBuffMenu(event, player, item)
    elseif intid >= Config.STORE_BUFF_OFFSET and intid < Config.RETRIEVE_BUFF_OFFSET then
        HandleStoreBuffSelection(player, intid, item)
    elseif intid >= Config.RETRIEVE_BUFF_OFFSET and intid < Config.FORGET_BUFF_OFFSET then
        HandleRetrieveBuffSelection(player, intid, item)
    elseif intid >= Config.FORGET_BUFF_OFFSET and intid < Config.ALL_BUFF_OFFSET then
        HandleForgetBuffSelection(player, intid, item)
    elseif intid >= Config.ALL_BUFF_OFFSET then
        player:SendBroadcastMessage("别点了，我就是个你可以获得的技能展示！|r")
        ShowAllBuffMenu(event, player, item)
    else
        player:SendBroadcastMessage(Config.COLORS.WARNING.."错误：|r"..Config.COLORS.NORMAL.."无效的操作选项！|r")
        ShowMainMenu(event, player, item)
    end
end

-- =============================================
-- 注册事件
-- =============================================

RegisterItemGossipEvent(Config.ITEM_ENTRY, 1, ShowMainMenu)
RegisterItemGossipEvent(Config.ITEM_ENTRY, 2, HandleGossipSelect)

print(">> [Buff存储器] 初始化完成 - 物品ID:"..Config.ITEM_ENTRY)
