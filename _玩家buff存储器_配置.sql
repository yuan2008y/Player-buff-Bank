-- 创建主配置表
CREATE TABLE IF NOT EXISTS `_玩家buff存储器_配置` (
  `配置项` VARCHAR(50) NOT NULL,
  `值类型` VARCHAR(10) NOT NULL COMMENT 'int/string',
  `整数值` INT DEFAULT NULL,
  `字符串值` VARCHAR(255) DEFAULT NULL,
  `备注` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`配置项`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 创建颜色配置表
CREATE TABLE IF NOT EXISTS `_玩家buff存储器_颜色配置` (
  `颜色名称` VARCHAR(20) NOT NULL,
  `颜色代码` CHAR(8) NOT NULL COMMENT '不带|c前缀的8位颜色代码',
  `备注` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`颜色名称`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 插入初始主配置
INSERT INTO `_玩家buff存储器_配置` (`配置项`, `值类型`, `整数值`, `字符串值`, `备注`) VALUES
('ITEM_ENTRY', 'int', 1179, NULL, '调用界面的物品ID'),
('BASE_MAX_STORED_BUFFS', 'int', 10, NULL, '基础存储限制数量'),
('SKILLS_TABLE', 'string', NULL, '_玩家buff存储器_可用技能', '可用技能表名'),
('BANK_TABLE', 'string', NULL, '_玩家buff存储器_银行', '银行表名'),
('VIP_TABLE', 'string', NULL, '_玩家buff存储器_vip', 'VIP表名'),
('STORE_BUFF_OFFSET', 'int', 100000000, NULL, '存储偏移量'),
('RETRIEVE_BUFF_OFFSET', 'int', 200000000, NULL, '取出偏移量'),
('FORGET_BUFF_OFFSET', 'int', 300000000, NULL, '遗忘偏移量'),
('ALL_BUFF_OFFSET', 'int', 400000000, NULL, '全部展示偏移量'),
('PAGE_NAV_OFFSET', 'int', 500000000, NULL, '分页导航偏移量'),
('PAGE_SIZE', 'int', 7, NULL, '每页显示数量');

-- 插入初始颜色配置
INSERT INTO `_玩家buff存储器_颜色配置` (`颜色名称`, `颜色代码`, `备注`) VALUES
('MAIN', 'FF00CCFF', '主色调(蓝色)'),
('TITLE', 'FFFFFF00', '标题色(橙色)'),
('STORE', 'FF00FF00', '存储功能色(绿色)'),
('RETRIEVE', 'FF3399FF', '取出功能色(亮蓝)'),
('FORGET', 'FFFF3333', '遗忘功能色(红色)'),
('ALL', 'FF9933FF', '展示功能色(紫色)'),
('PAGE', 'FFFFFF00', '页码色(黄色)'),
('WARNING', 'FFFF0000', '警告色(红色)'),
('NORMAL', 'F0000FFF', '普通文本色(白色)'),
('GRAY', 'FF007FFF', '灰色文本'),
('LINE', 'FF555555', '分隔线色'),
('VIP', 'FFFFA500', 'VIP颜色(橙色)');