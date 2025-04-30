-- 全局配置配置信息
local ITEM_ENTRY = 1179 -- 指定可以调用 Buff 存储器界面的物品 Entry ID

-- 引用的数据库表名
local SKILLS_TABLE = "_玩家buff存储器_可用技能" -- 存储允许保存的 Buff 列表
local BANK_TABLE = "_玩家buff存储器_银行" -- 存储玩家已保存的 Buff

-- 偏移量，用于不同功能查询的技能显示菜单 ID
local STORE_BUFF_OFFSET = 100000000
local RETRIEVE_BUFF_OFFSET = 200000000
local FORGET_BUFF_OFFSET = 300000000
local ALL_BUFF_OFFSET = 400000000
local PAGE_NAV_OFFSET = 500000000 -- 分页导航偏移量

-- 分页设置
local PAGE_SIZE = 20 -- 每页显示20个Buff

-- 颜色定义
local COLORS = {
    MAIN = "|cFF00CCFF",      -- 主色调(蓝色)
    TITLE = "|cFFFFFF00",     -- 标题色(橙色)
    STORE = "|cFF00FF00",     -- 存储功能色(绿色)
    RETRIEVE = "|cFF3399FF",  -- 取出功能色(亮蓝)
    FORGET = "|cFFFF3333",    -- 遗忘功能色(红色)
    ALL = "|cFF9933FF",       -- 展示功能色(紫色)
    PAGE = "|cFFFFFF00",      -- 页码色(黄色)
    WARNING = "|cFFFF0000",   -- 警告色(红色)
    NORMAL = "|cF0000FF",    -- 普通文本色(白色)
    GRAY = "|cFF007FFF",      -- 灰色文本
    LINE = "|cFF555555"       -- 分隔线色
}

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

-- 添加分隔线
local function AddSeparator(player)
    player:GossipMenuAddItem(0, COLORS.LINE.."--------------------------|r", 1, 0)
end

-- 添加标题
local function AddTitle(player, title)
    player:GossipMenuAddItem(0, COLORS.TITLE..title.."|r", 1, 0)
    AddSeparator(player)
end

-- 通用分页显示函数
local function ShowBuffList(player, item, menuType, baseOffset, query, currentPage)
    currentPage = currentPage or 1
    local offset = (currentPage - 1) * PAGE_SIZE
    
    -- 获取总数量
    local countQuery = query:gsub("SELECT.-FROM", "SELECT COUNT(*) FROM")
    local countResult = WorldDBQuery(countQuery)
    local totalCount = countResult and countResult:GetUInt32(0) or 0
    local totalPages = math.ceil(totalCount / PAGE_SIZE)
    
    player:GossipClearMenu()
    
    -- 添加菜单标题
    local titles = {
        store = "存储 Buff 列表",
        retrieve = "取出 Buff 列表",
        forget = "遗忘 Buff 列表",
        all = "所有可用 Buff 列表"
    }
    AddTitle(player, titles[menuType])
    
    if totalCount == 0 then
        local messages = {
            store = "你没有任何可存储的 Buff！",
            retrieve = "你的 Buff 银行是空的！",
            forget = "没有可以遗忘的 Buff！",
            all = "管理员尚未配置任何可用 Buff！"
        }
        player:GossipMenuAddItem(0, COLORS.WARNING..messages[menuType].."|r", 1, 0)
        AddSeparator(player)
        player:GossipMenuAddItem(0, COLORS.MAIN.."返回主菜单|r", 1, 0)
        player:GossipSendMenu(1, item)
        return
    end
    
    -- 获取当前页数据
    local pagedQuery = query .. string.format(" LIMIT %d, %d", offset, PAGE_SIZE)
    local result = WorldDBQuery(pagedQuery)
    
    -- 添加Buff列表
    if result then
        repeat
            local buffId = result:GetUInt32(0)
            local buffName = GetSkillName(buffId)
            
            if menuType == "store" then
                local accountId = player:GetAccountId()
                local charId = player:GetGUIDLow()
                local checkQuery = string.format(
                    "SELECT COUNT(*) FROM %s WHERE 玩家账号id = %d AND 角色id = %d AND 获得的buff法术id = %d",
                    BANK_TABLE, accountId, charId, buffId
                )
                local checkResult = WorldDBQuery(checkQuery)
                local storedMark = ""
                
                if checkResult and checkResult:GetUInt32(0) > 0 then
                    storedMark = COLORS.GRAY.." [已存储]|r"
                end
                
                player:GossipMenuAddItem(3, COLORS.STORE.."存储|r "..COLORS.NORMAL..buffId.."|r - ["..buffName.."]"..storedMark, 1, STORE_BUFF_OFFSET + buffId)
            elseif menuType == "retrieve" then
                player:GossipMenuAddItem(4, COLORS.RETRIEVE.."取出|r "..COLORS.NORMAL..buffId.."|r - ["..buffName.."]", 1, RETRIEVE_BUFF_OFFSET + buffId)
            elseif menuType == "forget" then
                player:GossipMenuAddItem(9, COLORS.FORGET.."遗忘|r "..COLORS.NORMAL..buffId.."|r - ["..buffName.."]", 1, FORGET_BUFF_OFFSET + buffId)
            elseif menuType == "all" then
                player:GossipMenuAddItem(6, COLORS.ALL.."查看|r "..COLORS.NORMAL..buffId.."|r - ["..buffName.."]", 1, ALL_BUFF_OFFSET + buffId)
            end
        until not result:NextRow()
    end
    
    AddSeparator(player)
    
    -- 添加分页导航
    player:GossipMenuAddItem(0, COLORS.PAGE.."第 "..currentPage.." 页 / 共 "..totalPages.." 页|r", 1, baseOffset)
    
    if currentPage > 1 then
        player:GossipMenuAddItem(0, COLORS.MAIN.."<< 上一页|r", 1, PAGE_NAV_OFFSET + (currentPage - 1) * 10 + baseOffset)
    end
    
    if currentPage < totalPages then
        player:GossipMenuAddItem(0, COLORS.MAIN.."下一页 >>|r", 1, PAGE_NAV_OFFSET + (currentPage + 1) * 10 + baseOffset)
    end
    
    AddSeparator(player)
    player:GossipMenuAddItem(0, COLORS.MAIN.."返回主菜单|r", 1, 0)
    player:GossipSendMenu(1, item)
end

-- 模块 1.1: 存储 Buff 功能-->列出玩家当前拥有的可以存储的所有buff
-- 模块 1.1: 存储 Buff 功能-->列出玩家当前拥有的可以存储的所有buff（带分页）
local function ShowStoreBuffMenu(event, player, item, page)
    page = page or 1
    player:GossipClearMenu()
    
    -- 添加标题
    AddTitle(player, "存储 Buff 列表")
    
    -- 查询所有可存储的技能
    local query = string.format("SELECT 技能ID, 技能名字 FROM %s", SKILLS_TABLE)
    local result = WorldDBQuery(query)

    if not result then
        player:GossipMenuAddItem(0, COLORS.WARNING.."未配置允许存储的技能列表！|r", 1, 0)
        AddSeparator(player)
        player:GossipMenuAddItem(0, COLORS.MAIN.."返回主菜单|r", 1, 0)
        player:GossipSendMenu(1, item)
        return
    end

    -- 收集玩家当前拥有的可存储Buff
    local availableBuffs = {}
    repeat
        local buffId = tonumber(result:GetUInt32(0)) -- 确保转换为数字
        local buffName = result:GetString(1) or "未知技能"
        if player:HasAura(buffId) then
            table.insert(availableBuffs, {
                id = buffId,
                name = buffName,
                -- 使用更安全的菜单ID生成方式
                menuId = STORE_BUFF_OFFSET + (buffId % 100000) -- 限制在合理范围内
            })
        end
    until not result:NextRow()

    -- 检查是否有可存储的Buff
    if #availableBuffs == 0 then
        player:GossipMenuAddItem(0, COLORS.WARNING.."你没有任何可存储的 Buff！|r", 1, 0)
        AddSeparator(player)
        player:GossipMenuAddItem(0, COLORS.MAIN.."返回主菜单|r", 1, 0)
        player:GossipSendMenu(1, item)
        return
    end

    -- 计算分页信息
    local totalCount = #availableBuffs
    local totalPages = math.ceil(totalCount / PAGE_SIZE)
    local startIndex = (page - 1) * PAGE_SIZE + 1
    local endIndex = math.min(page * PAGE_SIZE, totalCount)

    -- 显示当前页的Buff
    for i = startIndex, endIndex do
        local buff = availableBuffs[i]
        local accountId = player:GetAccountId()
        local charId = player:GetGUIDLow()
        
        -- 检查是否已存储
        local checkQuery = string.format(
            "SELECT COUNT(*) FROM %s WHERE 玩家账号id = %d AND 角色id = %d AND 获得的buff法术id = %d",
            BANK_TABLE, accountId, charId, buff.id
        )
        local checkResult = WorldDBQuery(checkQuery)
        local storedMark = ""
        
        if checkResult and checkResult:GetUInt32(0) > 0 then
            storedMark = COLORS.GRAY.." [已存储]|r"
        end
        
        -- 使用安全的菜单ID
        player:GossipMenuAddItem(3, COLORS.STORE.."存储|r "..COLORS.NORMAL..buff.id.."|r - ["..buff.name.."]"..storedMark, 
                               1, buff.menuId) -- 使用预先计算的安全ID
    end

    AddSeparator(player)
    
    -- 添加分页导航
    player:GossipMenuAddItem(0, COLORS.PAGE.."第 "..page.." 页 / 共 "..totalPages.." 页|r", 1, 1)
    
    if page > 1 then
        player:GossipMenuAddItem(0, COLORS.MAIN.."<< 上一页|r", 1, PAGE_NAV_OFFSET + (page - 1) * 10 + 1)
    end
    
    if page < totalPages then
        player:GossipMenuAddItem(0, COLORS.MAIN.."下一页 >>|r", 1, PAGE_NAV_OFFSET + (page + 1) * 10 + 1)
    end
    
    AddSeparator(player)
    player:GossipMenuAddItem(0, COLORS.MAIN.."返回主菜单|r", 1, 0)
    player:GossipSendMenu(1, item)
end

-- 模块 1.2: 存储 Buff 功能-->存储鼠标点击的buff到数据库
local function HandleStoreBuffSelection(player, intid, item)
    -- 修正buffId获取方式
    local menuOffset = intid - STORE_BUFF_OFFSET
    local buffId = 0
    
    -- 需要重新查询实际buffId，因为menuId可能是截断后的值
    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()
    local query = string.format(
        "SELECT s.技能ID, s.技能名字 FROM %s s WHERE (s.技能ID %% 100000) = %d AND s.技能ID IN "..
        "(SELECT DISTINCT spell FROM character_aura WHERE guid = %d) LIMIT 1",
        SKILLS_TABLE, menuOffset, charId
    )
    local result = WorldDBQuery(query)
    
    if not result then
        player:SendBroadcastMessage(COLORS.WARNING.."错误：|r"..COLORS.NORMAL.."找不到对应的Buff！|r")
        ShowStoreBuffMenu(nil, player, item)
        return
    end
    
    buffId = result:GetUInt32(0)
    local buffName = result:GetString(1) or "未知技能"
    
    -- 检查是否已存储
    local checkQuery = string.format(
        "SELECT COUNT(*) FROM %s WHERE 玩家账号id = %d AND 角色id = %d AND 获得的buff法术id = %d",
        BANK_TABLE, accountId, charId, buffId
    )
    local checkResult = WorldDBQuery(checkQuery)

    if checkResult and checkResult:GetUInt32(0) > 0 then
        player:SendBroadcastMessage(COLORS.WARNING.."提示：|r"..COLORS.NORMAL.."你已经存储过 ["..buffName.."] 这个Buff了！|r")
        ShowStoreBuffMenu(nil, player, item)
        return
    end

    local insertQuery = string.format(
        "INSERT INTO %s (玩家账号id, 角色id, 获得的buff法术id) VALUES (%d, %d, %d)",
        BANK_TABLE, accountId, charId, buffId
    )
    WorldDBExecute(insertQuery)

    player:SendBroadcastMessage(COLORS.STORE.."成功存储！|r"..COLORS.NORMAL.."已将 ["..buffName.."] 存入你的Buff银行。|r")
    ShowStoreBuffMenu(nil, player, item)
end

-- 模块 2.1: 取出 Buff 功能--->列出数据库可以取出的所有buff
local function ShowRetrieveBuffMenu(event, player, item, page)
    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()
    
    local query = string.format(
        "SELECT 获得的buff法术id FROM %s WHERE 玩家账号id = %d AND 角色id = %d ORDER BY 获得的buff法术id",
        BANK_TABLE, accountId, charId
    )
    
    ShowBuffList(player, item, "retrieve", 2, query, page)
end

-- 模块 3.1: 遗忘 Buff 功能-->列出可以遗忘的所有buff
local function ShowForgetBuffMenu(event, player, item, page)
    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()
    
    local query = string.format(
        "SELECT 获得的buff法术id FROM %s WHERE 玩家账号id = %d AND 角色id = %d ORDER BY 获得的buff法术id",
        BANK_TABLE, accountId, charId
    )
    
    ShowBuffList(player, item, "forget", 3, query, page)
end

-- 模块 4: 列出可以存储的所有buff
local function ShowAllBuffMenu(event, player, item, page)
    local query = string.format("SELECT 技能ID FROM %s ORDER BY 技能ID", SKILLS_TABLE)
    ShowBuffList(player, item, "all", 4, query, page)
end

-- 模块 1.2: 存储 Buff 功能-->存储鼠标点击的buff到数据库
local function HandleStoreBuffSelection(player, intid, item)
    local buffId = intid - STORE_BUFF_OFFSET
    local buffName = GetSkillName(buffId)

    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()

    local query = string.format(
        "SELECT COUNT(*) FROM %s WHERE 玩家账号id = %d AND 角色id = %d AND 获得的buff法术id = %d",
        BANK_TABLE, accountId, charId, buffId
    )
    local result = WorldDBQuery(query)

    if result and result:GetUInt32(0) > 0 then
        player:SendBroadcastMessage(COLORS.WARNING.."提示：|r"..COLORS.NORMAL.."你已经存储过 ["..buffName.."] 这个Buff了！|r")
        ShowStoreBuffMenu(nil, player, item)
        return
    end

    local insertQuery = string.format(
        "INSERT INTO %s (玩家账号id, 角色id, 获得的buff法术id) VALUES (%d, %d, %d)",
        BANK_TABLE, accountId, charId, buffId
    )
    WorldDBExecute(insertQuery)

    player:SendBroadcastMessage(COLORS.STORE.."成功存储！|r"..COLORS.NORMAL.."已将 ["..buffName.."] 存入你的Buff银行。|r")
    ShowStoreBuffMenu(nil, player, item)
end

-- 模块 2.2: 取出 Buff 功能--->应用鼠标点击的buff到玩家身上
local function HandleRetrieveBuffSelection(player, intid, item)
    local buffId = intid - RETRIEVE_BUFF_OFFSET
    local buffName = GetSkillName(buffId)
    player:AddAura(buffId, player)
    player:SendBroadcastMessage(COLORS.RETRIEVE.."成功取出！|r"..COLORS.NORMAL.."Buff ["..buffName.."] 已应用到你的角色。|r")
    ShowRetrieveBuffMenu(nil, player, item)
end

-- 模块 3.2: 遗忘 Buff 功能-->遗忘鼠标点击的buff，从数据库删除
local function HandleForgetBuffSelection(player, intid, item)
    local buffId = intid - FORGET_BUFF_OFFSET
    local buffName = GetSkillName(buffId)

    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()

    local deleteQuery = string.format(
        "DELETE FROM %s WHERE 玩家账号id = %d AND 角色id = %d AND 获得的buff法术id = %d",
        BANK_TABLE, accountId, charId, buffId
    )
    WorldDBExecute(deleteQuery)

    player:SendBroadcastMessage(COLORS.FORGET.."成功遗忘！|r"..COLORS.NORMAL.."Buff ["..buffName.."] 已从你的银行中移除。|r")
    ShowForgetBuffMenu(nil, player, item)
end

-- 模块 4: 主菜单
local function ShowMainMenu(event, player, item)
    player:GossipClearMenu()
    
    -- 添加欢迎标题
    AddTitle(player, "玩家Buff 存储器 v 1.0 by 法能")
    
    -- 添加玩家信息
    local accountId = player:GetAccountId()
    local charId = player:GetGUIDLow()
    local countQuery = string.format(
        "SELECT COUNT(*) FROM %s WHERE 玩家账号id = %d AND 角色id = %d",
        BANK_TABLE, accountId, charId
    )
    local countResult = WorldDBQuery(countQuery)
    local buffCount = countResult and countResult:GetUInt32(0) or 0
    
    player:GossipMenuAddItem(0, COLORS.MAIN.."当前存储的Buff数量: |r"..COLORS.NORMAL..buffCount.."|r", 1, 0)
    AddSeparator(player)
    
    -- 添加功能菜单
    player:GossipMenuAddItem(3, COLORS.STORE.."■ 存储 Buff|r", 1, 1)
    player:GossipMenuAddItem(4, COLORS.RETRIEVE.."■ 取出 Buff|r", 1, 2)
    player:GossipMenuAddItem(9, COLORS.FORGET.."■ 遗忘 Buff|r", 1, 3)
    player:GossipMenuAddItem(6, COLORS.ALL.."■ 查看所有可用 Buff|r", 1, 4)
    
    AddSeparator(player)
    player:GossipMenuAddItem(0, COLORS.GRAY.."使用说明:|r", 1, 0)
    player:GossipMenuAddItem(0, COLORS.GRAY.."1. 存储: 保存你当前的Buff|r", 1, 0)
    player:GossipMenuAddItem(0, COLORS.GRAY.."2. 取出: 应用已存储的Buff|r", 1, 0)
    player:GossipMenuAddItem(0, COLORS.GRAY.."3. 遗忘: 删除不需要的Buff|r", 1, 0)
    
    player:GossipSendMenu(1, item)
end

-- 模块 5: 菜单处理逻辑
local function HandleGossipSelect(event, player, item, sender, intid)
    -- 处理分页导航
    if intid >= PAGE_NAV_OFFSET then
        local page = math.floor((intid - PAGE_NAV_OFFSET) / 10)
        local menuType = (intid - PAGE_NAV_OFFSET) % 10
        
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
        -- 返回主菜单
        ShowMainMenu(event, player, item)
    elseif intid == 1 then
        ShowStoreBuffMenu(event, player, item)
    elseif intid == 2 then
        ShowRetrieveBuffMenu(event, player, item)
    elseif intid == 3 then
        ShowForgetBuffMenu(event, player, item)
    elseif intid == 4 then
        ShowAllBuffMenu(event, player, item)
    elseif intid >= STORE_BUFF_OFFSET and intid < RETRIEVE_BUFF_OFFSET then
        HandleStoreBuffSelection(player, intid, item)
    elseif intid >= RETRIEVE_BUFF_OFFSET and intid < FORGET_BUFF_OFFSET then
        HandleRetrieveBuffSelection(player, intid, item)
    elseif intid >= FORGET_BUFF_OFFSET and intid < ALL_BUFF_OFFSET then
        HandleForgetBuffSelection(player, intid, item)
    else
        player:SendBroadcastMessage(COLORS.WARNING.."错误：|r"..COLORS.NORMAL.."无效的操作选项！|r")
        ShowMainMenu(event, player, item)
    end
end

-- 注册事件
RegisterItemGossipEvent(ITEM_ENTRY, 1, ShowMainMenu)
RegisterItemGossipEvent(ITEM_ENTRY, 2, HandleGossipSelect)
