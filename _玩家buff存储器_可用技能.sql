/*
 Navicat Premium Dump SQL

 Source Server         : 127.0.0.1
 Source Server Type    : MySQL
 Source Server Version : 80040 (8.0.40)
 Source Host           : localhost:3306
 Source Schema         : acore_world

 Target Server Type    : MySQL
 Target Server Version : 80040 (8.0.40)
 File Encoding         : 65001

 Date: 30/04/2025 14:37:28
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for _玩家buff存储器_可用技能
-- ----------------------------
DROP TABLE IF EXISTS `_玩家buff存储器_可用技能`;
CREATE TABLE `_玩家buff存储器_可用技能`  (
  `ID` int NOT NULL AUTO_INCREMENT,
  `技能ID` int NOT NULL,
  `技能名字` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
  `备注` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL,
  PRIMARY KEY (`ID`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 38 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of _玩家buff存储器_可用技能
-- ----------------------------
INSERT INTO `_玩家buff存储器_可用技能` VALUES (3, 32182, '嗜血', '部落');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (4, 2825, '英勇', '联盟');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (5, 1719, '鲁莽', '战士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (6, 871, '盾墙', '战士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (7, 31884, '复仇之怒', '圣骑士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (8, 31801, '复仇圣印', '圣骑士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (9, 20165, '光明圣印', '圣骑士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (10, 48934, '强效力量', '圣骑士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (11, 25899, '强效庇护', '圣骑士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (12, 25898, '强效王者', '圣骑士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (13, 48942, '虔诚光环', '圣骑士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (14, 54043, '惩戒光环', '圣骑士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (15, 19746, '专注光环', '圣骑士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (16, 61847, '龙鹰守护', '猎人');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (17, 19506, '强击光环', '猎人');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (18, 1784, '潜行', '潜行者');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (19, 6346, '防控结界', '牧师');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (20, 49362, '坚韧祷言', '牧师');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (21, 48266, '鲜血灵气', '死亡骑士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (22, 48263, '冰霜灵气', '死亡骑士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (23, 48265, '邪恶灵气', '死亡骑士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (24, 2825, '嗜血', '萨满祭司');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (25, 2645, '幽灵狼', '萨满祭司');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (26, 49281, '闪电之盾', '萨满祭司');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (27, 57960, '水之护盾', '萨满祭司');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (28, 43008, '冰甲术', '法师');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (29, 7301, '霜甲术', '法师');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (30, 43002, '奥术光辉', '法师');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (31, 73024, '法师护甲', '法师');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (32, 43046, '熔岩护甲', '法师');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (33, 47889, '魔甲术', '术士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (34, 47893, '邪甲术', '术士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (35, 47241, '恶魔变身', '术士');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (36, 53307, '荆棘术', '德鲁伊');
INSERT INTO `_玩家buff存储器_可用技能` VALUES (37, 48470, '野性赐福', '德鲁伊');

SET FOREIGN_KEY_CHECKS = 1;
