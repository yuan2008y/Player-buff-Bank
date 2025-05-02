#pragma once

#include "Config.h"

class BuffBankConf
{
public:
    static void LoadConfig();

    // 主配置
    static uint32 ITEM_ENTRY;
    static uint32 BASE_MAX_STORED_BUFFS;
    static std::string SKILLS_TABLE;
    static std::string BANK_TABLE;
    static std::string VIP_TABLE;
    static uint32 STORE_BUFF_OFFSET;
    static uint32 RETRIEVE_BUFF_OFFSET;
    static uint32 FORGET_BUFF_OFFSET;
    static uint32 ALL_BUFF_OFFSET;
    static uint32 PAGE_NAV_OFFSET;
    static uint32 PAGE_SIZE;

    // 颜色配置
    struct Colors
    {
        static std::string MAIN;
        static std::string TITLE;
        static std::string STORE;
        static std::string RETRIEVE;
        static std::string FORGET;
        static std::string ALL;
        static std::string PAGE;
        static std::string WARNING;
        static std::string NORMAL;
        static std::string GRAY;
        static std::string LINE;
        static std::string VIP;
    };
};