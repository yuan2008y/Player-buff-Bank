#pragma once

#include "ScriptMgr.h"
#include "Player.h"
#include "GossipDef.h"
#include "DatabaseEnv.h"

class BuffBank : public PlayerScript, public ItemScript
{
public:
    BuffBank() : PlayerScript("BuffBank"), ItemScript("BuffBank") {}

    // PlayerScript
    void OnLogin(Player* player) override;

    // ItemScript
    bool OnUse(Player* player, Item* item, SpellCastTargets const& targets) override;
    
    // 主菜单
    void ShowMainMenu(Player* player, Item* item);
    
    // 各功能模块
    void ShowStoreBuffMenu(Player* player, Item* item, uint32 page = 1);
    void HandleStoreBuffSelection(Player* player, Item* item, uint32 rowId);
    
    void ShowRetrieveBuffMenu(Player* player, Item* item, uint32 page = 1);
    void HandleRetrieveBuffSelection(Player* player, Item* item, uint32 rowId);
    
    void ShowForgetBuffMenu(Player* player, Item* item, uint32 page = 1);
    void HandleForgetBuffSelection(Player* player, Item* item, uint32 rowId);
    
    void ShowAllBuffMenu(Player* player, Item* item, uint32 page = 1);

    // 工具函数
    std::pair<uint32, uint32> GetPlayerMaxBuffs(Player* player);
    std::string GetSkillName(uint32 buffId);
    void AddSeparator(Player* player);
    void AddTitle(Player* player, const std::string& title);
    
    // 处理选择
    void HandleSelection(Player* player, uint32 action, uint32 selection, Item* item);
};