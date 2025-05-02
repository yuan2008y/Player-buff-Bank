#include "BuffBank.h"
#include "ScriptMgr.h"

class BuffBank_WorldScript : public WorldScript
{
public:
    BuffBank_WorldScript() : WorldScript("BuffBank_WorldScript") {}

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        BuffBankConf::LoadConfig();
    }
};

void AddSC_BuffBank()
{
    new BuffBank();
    new BuffBank_WorldScript();
}