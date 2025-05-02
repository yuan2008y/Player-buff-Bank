# Copyright (C) 2016+ AzerothCore <www.azerothcore.org>
set(MODULE_NAME "mod_buff_bank")
set(MODULE_CPP_FILES
    BuffBank.cpp
    BuffBankConf.cpp
)

set(MODULE_HEADER_FILES
    BuffBank.h
    BuffBankConf.h
)

include(${CMAKE_SOURCE_DIR}/src/modules/CMakeMacros/ConfigureModule.cmake)
configure_acore_module()