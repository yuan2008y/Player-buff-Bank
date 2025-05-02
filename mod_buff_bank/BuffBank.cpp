#include "BuffBank.h"
#include "BuffBankConf.h"
#include "Chat.h"
#include "GossipDef.h"
#include "Language.h"
#include "ObjectMgr.h"
#include "ScriptedGossip.h"
#include "AuraMgr.h"
#include "DatabaseEnv.h"
#include "StringFormat.h"

void BuffBank::OnLogin(Player* player)
{
    // 登录时可以做初始化检查
}

bool BuffBank::OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/)
{
    ShowMainMenu(player, item);
    return true;
}

void BuffBank::AddSeparator(Player* player)
{
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::LINE + "------------------------------", 0, 0);
}

void BuffBank::AddTitle(Player* player, const std::string& title)
{
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::TITLE + title, 0, 0);
    AddSeparator(player);
}

std::pair<uint32, uint32> BuffBank::GetPlayerMaxBuffs(Player* player)
{
    uint32 baseLimit = BuffBankConf::BASE_MAX_STORED_BUFFS;
    uint32 accountId = player->GetSession()->GetAccountId();

    QueryResult result = CharacterDatabase.Query(
        "SELECT VIP等级 FROM {} WHERE 玩家账号id = {}",
        BuffBankConf::VIP_TABLE, accountId);

    uint32 vipLevel = result ? (*result)[0].Get<uint32>() : 0;
    return { baseLimit + vipLevel, vipLevel };
}

std::string BuffBank::GetSkillName(uint32 buffId)
{
    QueryResult result = WorldDatabase.Query(
        "SELECT 技能名字 FROM {} WHERE 技能ID = {}",
        BuffBankConf::SKILLS_TABLE, buffId);

    return result ? (*result)[0].Get<std::string>() : "未知技能";
}

void BuffBank::ShowMainMenu(Player* player, Item* item)
{
    ClearGossipMenuFor(player);

    uint32 accountId = player->GetSession()->GetAccountId();
    uint32 charId = player->GetGUID().GetCounter();

    QueryResult countResult = CharacterDatabase.Query(
        "SELECT COUNT(*) FROM {} WHERE 玩家账号id = {} AND 角色id = {}",
        BuffBankConf::BANK_TABLE, accountId, charId);

    uint32 buffCount = countResult ? (*countResult)[0].Get<uint32>() : 0;
    auto [maxAllowed, vipLevel] = GetPlayerMaxBuffs(player);

    std::string statusMsg = fmt::format("{}当前存储: {}{}/{}{}",
        BuffBankConf::Colors::MAIN,
        BuffBankConf::Colors::NORMAL,
        buffCount,
        maxAllowed,
        vipLevel > 0 ? fmt::format("{} (VIP+{})", BuffBankConf::Colors::VIP, vipLevel) : "");

    AddTitle(player, "玩家Buff 存储器 v2.0");
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, statusMsg, 0, 0);
    AddSeparator(player);

    AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, BuffBankConf::Colors::STORE + "■ 存储 Buff", 0, 1);
    AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, BuffBankConf::Colors::RETRIEVE + "■ 取出 Buff", 0, 2);
    AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, BuffBankConf::Colors::FORGET + "■ 遗忘 Buff", 0, 3);
    AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, BuffBankConf::Colors::ALL + "■ 查看所有可用 Buff", 0, 4);

    AddSeparator(player);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::GRAY + "使用说明:", 0, 0);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::GRAY + "1. 存储: 保存你当前的Buff", 0, 0);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::GRAY + "2. 取出: 应用已存储的Buff", 0, 0);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::GRAY + "3. 遗忘: 删除不需要的Buff", 0, 0);

    SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, item);
}

void BuffBank::ShowStoreBuffMenu(Player* player, Item* item, uint32 page)
{
    ClearGossipMenuFor(player);
    AddTitle(player, "存储 Buff 列表");

    uint32 accountId = player->GetSession()->GetAccountId();
    uint32 charId = player->GetGUID().GetCounter();

    QueryResult countResult = CharacterDatabase.Query(
        "SELECT COUNT(*) FROM {} WHERE 玩家账号id = {} AND 角色id = {}",
        BuffBankConf::BANK_TABLE, accountId, charId);

    uint32 buffCount = countResult ? (*countResult)[0].Get<uint32>() : 0;
    auto [maxAllowed, vipLevel] = GetPlayerMaxBuffs(player);

    std::string statusMsg = fmt::format("{}当前存储: {}{}/{}{}",
        BuffBankConf::Colors::MAIN,
        BuffBankConf::Colors::NORMAL,
        buffCount,
        maxAllowed,
        vipLevel > 0 ? fmt::format("{} (VIP+{})", BuffBankConf::Colors::VIP, vipLevel) : "");

    AddGossipItemFor(player, GOSSIP_ICON_CHAT, statusMsg, 0, 0);
    AddSeparator(player);

    QueryResult result = WorldDatabase.Query(
        "SELECT id, 技能ID, 技能名字 FROM {} ORDER BY 技能ID",
        BuffBankConf::SKILLS_TABLE);

    if (!result)
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::WARNING + "未配置允许存储的技能列表！", 0, 0);
        AddSeparator(player);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "返回主菜单", 0, 0);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, item);
        return;
    }

    std::vector<std::tuple<uint32, uint32, std::string, std::string>> availableBuffs;

    do
    {
        Field* fields = result->Fetch();
        uint32 rowId = fields[0].Get<uint32>();
        uint32 buffId = fields[1].Get<uint32>();
        std::string buffName = fields[2].Get<std::string>();

        if (player->HasAura(buffId))
        {
            QueryResult checkResult = CharacterDatabase.Query(
                "SELECT COUNT(*) FROM {} WHERE 玩家账号id = {} AND 角色id = {} AND 获得的buff法术id = {}",
                BuffBankConf::BANK_TABLE, accountId, charId, buffId);

            std::string storedMark = "";
            if (checkResult && (*checkResult)[0].Get<uint32>() > 0)
            {
                storedMark = BuffBankConf::Colors::GRAY + " [已存储]";
            }

            availableBuffs.emplace_back(rowId, buffId, buffName, storedMark);
        }
    } while (result->NextRow());

    if (availableBuffs.empty())
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::WARNING + "你没有任何可存储的 Buff！", 0, 0);
        AddSeparator(player);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "返回主菜单", 0, 0);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, item);
        return;
    }

    uint32 totalCount = availableBuffs.size();
    uint32 totalPages = (totalCount + BuffBankConf::PAGE_SIZE - 1) / BuffBankConf::PAGE_SIZE;
    uint32 startIndex = (page - 1) * BuffBankConf::PAGE_SIZE;
    uint32 endIndex = std::min(page * BuffBankConf::PAGE_SIZE, totalCount);

    for (uint32 i = startIndex; i < endIndex; ++i)
    {
        auto const& [rowId, buffId, buffName, storedMark] = availableBuffs[i];
        std::string menuItem = fmt::format("{}存储{} {} - [{}]{}",
            BuffBankConf::Colors::STORE,
            BuffBankConf::Colors::NORMAL,
            buffId,
            buffName,
            storedMark);

        AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, menuItem, 0, BuffBankConf::STORE_BUFF_OFFSET + rowId);
    }

    AddSeparator(player);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, 
        fmt::format("{}第 {} 页 / 共 {} 页", BuffBankConf::Colors::PAGE, page, totalPages), 
        0, 0);

    if (page > 1)
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "<< 上一页", 0, BuffBankConf::PAGE_NAV_OFFSET + (page - 1) * 10 + 1);
    }

    if (page < totalPages)
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "下一页 >>", 0, BuffBankConf::PAGE_NAV_OFFSET + (page + 1) * 10 + 1);
    }

    AddSeparator(player);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "返回主菜单", 0, 0);
    SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, item);
}

void BuffBank::HandleStoreBuffSelection(Player* player, Item* item, uint32 rowId)
{
    QueryResult result = WorldDatabase.Query(
        "SELECT 技能ID, 技能名字 FROM {} WHERE id = {}",
        BuffBankConf::SKILLS_TABLE, rowId);

    if (!result)
    {
        player->GetSession()->SendNotification("错误：找不到对应的Buff！");
        ShowStoreBuffMenu(player, item);
        return;
    }

    Field* fields = result->Fetch();
    uint32 buffId = fields[0].Get<uint32>();
    std::string buffName = fields[1].Get<std::string>();

    uint32 accountId = player->GetSession()->GetAccountId();
    uint32 charId = player->GetGUID().GetCounter();

    QueryResult checkResult = CharacterDatabase.Query(
        "SELECT COUNT(*) FROM {} WHERE 玩家账号id = {} AND 角色id = {} AND 获得的buff法术id = {}",
        BuffBankConf::BANK_TABLE, accountId, charId, buffId);

    if (checkResult && (*checkResult)[0].Get<uint32>() > 0)
    {
        player->GetSession()->SendNotification("提示：你已经存储过 [%s] 这个Buff了！", buffName.c_str());
        ShowStoreBuffMenu(player, item);
        return;
    }

    QueryResult countResult = CharacterDatabase.Query(
        "SELECT COUNT(*) FROM {} WHERE 玩家账号id = {} AND 角色id = {}",
        BuffBankConf::BANK_TABLE, accountId, charId);

    uint32 currentCount = countResult ? (*countResult)[0].Get<uint32>() : 0;
    auto [maxAllowed, _] = GetPlayerMaxBuffs(player);

    if (currentCount >= maxAllowed)
    {
        player->GetSession()->SendNotification("错误：你已经存储了 %u 个Buff，达到了上限 %u！", currentCount, maxAllowed);
        player->GetSession()->SendNotification("提示：请先遗忘一些不需要的Buff再尝试存储新的。");
        ShowStoreBuffMenu(player, item);
        return;
    }

    CharacterDatabase.Execute(
        "INSERT INTO {} (玩家账号id, 角色id, 获得的buff法术id) VALUES ({}, {}, {})",
        BuffBankConf::BANK_TABLE, accountId, charId, buffId);

    player->GetSession()->SendNotification("成功存储！已将 [%s] 存入你的Buff银行。", buffName.c_str());
    ShowStoreBuffMenu(player, item);
}

void BuffBank::ShowRetrieveBuffMenu(Player* player, Item* item, uint32 page)
{
    ClearGossipMenuFor(player);
    AddTitle(player, "取出 Buff 列表");

    uint32 accountId = player->GetSession()->GetAccountId();
    uint32 charId = player->GetGUID().GetCounter();

    QueryResult result = CharacterDatabase.Query(
        "SELECT b.id, b.获得的buff法术id FROM {} b "
        "WHERE b.玩家账号id = {} AND b.角色id = {} "
        "ORDER BY b.获得的buff法术id",
        BuffBankConf::BANK_TABLE, accountId, charId);

    if (!result)
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::WARNING + "你的 Buff 银行是空的！", 0, 0);
        AddSeparator(player);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "返回主菜单", 0, 0);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, item);
        return;
    }

    std::vector<std::pair<uint32, uint32>> availableBuffs;

    do
    {
        Field* fields = result->Fetch();
        availableBuffs.emplace_back(fields[0].Get<uint32>(), fields[1].Get<uint32>());
    } while (result->NextRow());

    uint32 totalCount = availableBuffs.size();
    uint32 totalPages = (totalCount + BuffBankConf::PAGE_SIZE - 1) / BuffBankConf::PAGE_SIZE;
    uint32 startIndex = (page - 1) * BuffBankConf::PAGE_SIZE;
    uint32 endIndex = std::min(page * BuffBankConf::PAGE_SIZE, totalCount);

    for (uint32 i = startIndex; i < endIndex; ++i)
    {
        auto const& [rowId, buffId] = availableBuffs[i];
        std::string buffName = GetSkillName(buffId);
        std::string menuItem = fmt::format("{}取出{} {} - [{}]",
            BuffBankConf::Colors::RETRIEVE,
            BuffBankConf::Colors::NORMAL,
            buffId,
            buffName);

        AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, menuItem, 0, BuffBankConf::RETRIEVE_BUFF_OFFSET + rowId);
    }

    AddSeparator(player);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, 
        fmt::format("{}第 {} 页 / 共 {} 页", BuffBankConf::Colors::PAGE, page, totalPages), 
        0, 0);

    if (page > 1)
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "<< 上一页", 0, BuffBankConf::PAGE_NAV_OFFSET + (page - 1) * 10 + 2);
    }

    if (page < totalPages)
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "下一页 >>", 0, BuffBankConf::PAGE_NAV_OFFSET + (page + 1) * 10 + 2);
    }

    AddSeparator(player);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "返回主菜单", 0, 0);
    SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, item);
}

void BuffBank::HandleRetrieveBuffSelection(Player* player, Item* item, uint32 rowId)
{
    QueryResult result = CharacterDatabase.Query(
        "SELECT 获得的buff法术id FROM {} WHERE id = {}",
        BuffBankConf::BANK_TABLE, rowId);

    if (!result)
    {
        player->GetSession()->SendNotification("错误：找不到对应的Buff！");
        ShowRetrieveBuffMenu(player, item);
        return;
    }

    uint32 buffId = (*result)[0].Get<uint32>();
    std::string buffName = GetSkillName(buffId);

    player->AddAura(buffId, player);
    player->GetSession()->SendNotification("成功取出！Buff [%s] 已应用到你的角色。", buffName.c_str());
    ShowRetrieveBuffMenu(player, item);
}

void BuffBank::ShowForgetBuffMenu(Player* player, Item* item, uint32 page)
{
    ClearGossipMenuFor(player);
    AddTitle(player, "遗忘 Buff 列表");

    uint32 accountId = player->GetSession()->GetAccountId();
    uint32 charId = player->GetGUID().GetCounter();

    QueryResult result = CharacterDatabase.Query(
        "SELECT b.id, b.获得的buff法术id FROM {} b "
        "WHERE b.玩家账号id = {} AND b.角色id = {} "
        "ORDER BY b.获得的buff法术id",
        BuffBankConf::BANK_TABLE, accountId, charId);

    if (!result)
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::WARNING + "没有可以遗忘的 Buff！", 0, 0);
        AddSeparator(player);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "返回主菜单", 0, 0);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, item);
        return;
    }

    std::vector<std::pair<uint32, uint32>> availableBuffs;

    do
    {
        Field* fields = result->Fetch();
        availableBuffs.emplace_back(fields[0].Get<uint32>(), fields[1].Get<uint32>());
    } while (result->NextRow());

    uint32 totalCount = availableBuffs.size();
    uint32 totalPages = (totalCount + BuffBankConf::PAGE_SIZE - 1) / BuffBankConf::PAGE_SIZE;
    uint32 startIndex = (page - 1) * BuffBankConf::PAGE_SIZE;
    uint32 endIndex = std::min(page * BuffBankConf::PAGE_SIZE, totalCount);

    for (uint32 i = startIndex; i < endIndex; ++i)
    {
        auto const& [rowId, buffId] = availableBuffs[i];
        std::string buffName = GetSkillName(buffId);
        std::string menuItem = fmt::format("{}遗忘{} {} - [{}]",
            BuffBankConf::Colors::FORGET,
            BuffBankConf::Colors::NORMAL,
            buffId,
            buffName);

        AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, menuItem, 0, BuffBankConf::FORGET_BUFF_OFFSET + rowId);
    }

    AddSeparator(player);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, 
        fmt::format("{}第 {} 页 / 共 {} 页", BuffBankConf::Colors::PAGE, page, totalPages), 
        0, 0);

    if (page > 1)
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "<< 上一页", 0, BuffBankConf::PAGE_NAV_OFFSET + (page - 1) * 10 + 3);
    }

    if (page < totalPages)
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "下一页 >>", 0, BuffBankConf::PAGE_NAV_OFFSET + (page + 1) * 10 + 3);
    }

    AddSeparator(player);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "返回主菜单", 0, 0);
    SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, item);
}

void BuffBank::HandleForgetBuffSelection(Player* player, Item* item, uint32 rowId)
{
    QueryResult result = CharacterDatabase.Query(
        "SELECT 获得的buff法术id FROM {} WHERE id = {}",
        BuffBankConf::BANK_TABLE, rowId);

    if (!result)
    {
        player->GetSession()->SendNotification("错误：找不到对应的Buff！");
        ShowForgetBuffMenu(player, item);
        return;
    }

    uint32 buffId = (*result)[0].Get<uint32>();
    std::string buffName = GetSkillName(buffId);

    CharacterDatabase.Execute(
        "DELETE FROM {} WHERE id = {}",
        BuffBankConf::BANK_TABLE, rowId);

    player->GetSession()->SendNotification("成功遗忘！Buff [%s] 已从你的银行中移除。", buffName.c_str());
    ShowForgetBuffMenu(player, item);
}

void BuffBank::ShowAllBuffMenu(Player* player, Item* item, uint32 page)
{
    ClearGossipMenuFor(player);
    AddTitle(player, "所有可用 Buff 列表");

    QueryResult result = WorldDatabase.Query(
        "SELECT id, 技能ID, 技能名字, 备注 FROM {} ORDER BY 技能ID",
        BuffBankConf::SKILLS_TABLE);

    if (!result)
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::WARNING + "管理员尚未配置任何可用 Buff！", 0, 0);
        AddSeparator(player);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "返回主菜单", 0, 0);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, item);
        return;
    }

    std::vector<std::tuple<uint32, uint32, std::string, std::string>> availableBuffs;

    do
    {
        Field* fields = result->Fetch();
        availableBuffs.emplace_back(
            fields[0].Get<uint32>(),
            fields[1].Get<uint32>(),
            fields[2].Get<std::string>(),
            fields[3].Get<std::string>());
    } while (result->NextRow());

    uint32 totalCount = availableBuffs.size();
    uint32 totalPages = (totalCount + BuffBankConf::PAGE_SIZE - 1) / BuffBankConf::PAGE_SIZE;
    uint32 startIndex = (page - 1) * BuffBankConf::PAGE_SIZE;
    uint32 endIndex = std::min(page * BuffBankConf::PAGE_SIZE, totalCount);

    for (uint32 i = startIndex; i < endIndex; ++i)
    {
        auto const& [rowId, buffId, buffName, buffRemark] = availableBuffs[i];
        std::string menuItem = fmt::format("{}查看{} {} - [{}] - [{}]",
            BuffBankConf::Colors::ALL,
            BuffBankConf::Colors::NORMAL,
            buffId,
            buffName,
            buffRemark);

        AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, menuItem, 0, BuffBankConf::ALL_BUFF_OFFSET + rowId);
    }

    AddSeparator(player);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, 
        fmt::format("{}第 {} 页 / 共 {} 页", BuffBankConf::Colors::PAGE, page, totalPages), 
        0, 0);

    if (page > 1)
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "<< 上一页", 0, BuffBankConf::PAGE_NAV_OFFSET + (page - 1) * 10 + 4);
    }

    if (page < totalPages)
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "下一页 >>", 0, BuffBankConf::PAGE_NAV_OFFSET + (page + 1) * 10 + 4);
    }

    AddSeparator(player);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, BuffBankConf::Colors::MAIN + "返回主菜单", 0, 0);
    SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, item);
}

void BuffBank::HandleSelection(Player* player, uint32 action, uint32 selection, Item* item)
{
    if (selection >= BuffBankConf::PAGE_NAV_OFFSET)
    {
        uint32 page = (selection - BuffBankConf::PAGE_NAV_OFFSET) / 10;
        uint32 menuType = (selection - BuffBankConf::PAGE_NAV_OFFSET) % 10;
        
        switch (menuType)
        {
            case 1: ShowStoreBuffMenu(player, item, page); break;
            case 2: ShowRetrieveBuffMenu(player, item, page); break;
            case 3: ShowForgetBuffMenu(player, item, page); break;
            case 4: ShowAllBuffMenu(player, item, page); break;
        }
        return;
    }

    switch (selection)
    {
        case 0: ShowMainMenu(player, item); break;
        case 1: ShowStoreBuffMenu(player, item); break;
        case 2: ShowRetrieveBuffMenu(player, item); break;
        case 3: ShowForgetBuffMenu(player, item); break;
        case 4: ShowAllBuffMenu(player, item); break;
        default:
            if (selection >= BuffBankConf::STORE_BUFF_OFFSET && selection < BuffBankConf::RETRIEVE_BUFF_OFFSET)
            {
                HandleStoreBuffSelection(player, item, selection - BuffBankConf::STORE_BUFF_OFFSET);
            }
            else if (selection >= BuffBankConf::RETRIEVE_BUFF_OFFSET && selection < BuffBankConf::FORGET_BUFF_OFFSET)
            {
                HandleRetrieveBuffSelection(player, item, selection - BuffBankConf::RETRIEVE_BUFF_OFFSET);
            }
            else if (selection >= BuffBankConf::FORGET_BUFF_OFFSET && selection < BuffBankConf::ALL_BUFF_OFFSET)
            {
                HandleForgetBuffSelection(player, item, selection - BuffBankConf::FORGET_BUFF_OFFSET);
            }
            else if (selection >= BuffBankConf::ALL_BUFF_OFFSET)
            {
                player->GetSession()->SendNotification("别点了，我就是个你可以获得的技能展示！");
                ShowAllBuffMenu(player, item);
            }
            else
            {
                player->GetSession()->SendNotification("错误：无效的操作选项！");
                ShowMainMenu(player, item);
            }
            break;
    }
}