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

 Date: 30/04/2025 14:37:35
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for _玩家buff存储器_银行
-- ----------------------------
DROP TABLE IF EXISTS `_玩家buff存储器_银行`;
CREATE TABLE `_玩家buff存储器_银行`  (
  `id` int NOT NULL DEFAULT 1 AUTO_INCREMENT,
  `玩家账号id` int NOT NULL,
  `角色id` int NOT NULL,
  `获得的buff法术id` int NOT NULL,
  `存储时间` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 15 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of _玩家buff存储器_银行
-- ----------------------------
INSERT INTO `_玩家buff存储器_银行` VALUES (1, 1, 1, 2, '2025-04-30 10:00:54');
INSERT INTO `_玩家buff存储器_银行` VALUES (2, 1, 1, 3, '2025-04-30 10:01:04');
INSERT INTO `_玩家buff存储器_银行` VALUES (3, 1, 1, 4, '2025-04-30 10:01:16');
INSERT INTO `_玩家buff存储器_银行` VALUES (4, 1, 1, 5, '2025-04-30 10:01:21');
INSERT INTO `_玩家buff存储器_银行` VALUES (5, 1, 1, 22, '2025-04-30 10:01:39');
INSERT INTO `_玩家buff存储器_银行` VALUES (7, 1, 1, 55, '2025-04-30 10:01:26');
INSERT INTO `_玩家buff存储器_银行` VALUES (8, 1, 1, 232, '2025-04-30 10:01:55');
INSERT INTO `_玩家buff存储器_银行` VALUES (9, 1, 1, 323, '2025-04-30 10:01:49');
INSERT INTO `_玩家buff存储器_银行` VALUES (10, 1, 1, 424, '2025-04-30 10:01:59');
INSERT INTO `_玩家buff存储器_银行` VALUES (11, 1, 1, 20165, '2025-04-29 17:29:04');
INSERT INTO `_玩家buff存储器_银行` VALUES (12, 1, 1, 23231, '2025-04-30 10:01:45');
INSERT INTO `_玩家buff存储器_银行` VALUES (13, 1, 1, 54043, '2025-04-29 22:17:37');
INSERT INTO `_玩家buff存储器_银行` VALUES (14, 1, 1, 32182, '2025-04-30 14:28:21');

SET FOREIGN_KEY_CHECKS = 1;
