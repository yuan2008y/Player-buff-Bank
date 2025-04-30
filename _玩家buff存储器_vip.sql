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

 Date: 30/04/2025 20:05:37
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for _玩家buff存储器_vip
-- ----------------------------
DROP TABLE IF EXISTS `_玩家buff存储器_vip`;
CREATE TABLE `_玩家buff存储器_vip`  (
  `玩家账号id` int UNSIGNED NOT NULL,
  `VIP等级` tinyint UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`玩家账号id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb3 COLLATE = utf8mb3_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of _玩家buff存储器_vip
-- ----------------------------
INSERT INTO `_玩家buff存储器_vip` VALUES (1, 2);

SET FOREIGN_KEY_CHECKS = 1;
