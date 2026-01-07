-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1
-- Généré le : mer. 07 jan. 2026 à 19:42
-- Version du serveur : 10.4.32-MariaDB
-- Version de PHP : 8.3.27

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

CREATE DATABASE IF NOT EXISTS `lego_app`;
USE `lego_app`;

--
-- Base de données : `lego_app`
--

DELIMITER $$
--
-- Procédures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_add_item_to_basket` (IN `p_basket_id` INT, IN `p_user_id` INT, IN `p_unique_id` BIGINT)   BEGIN
    DECLARE v_basket_user INT;

    SELECT user_id INTO v_basket_user
    FROM basket
    WHERE basket_id = p_basket_id;

    IF v_basket_user IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Panier inexistant';
    END IF;

    IF v_basket_user <> p_user_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ce panier n''appartient pas à cet utilisateur';
    END IF;

    INSERT INTO basket_item (basket_id, user_id, unique_id)
    VALUES (p_basket_id, p_user_id, p_unique_id);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_basket` (IN `p_user_id` INT, OUT `p_basket_id` INT)   BEGIN
    INSERT INTO basket (user_id)
    VALUES (p_user_id);

    SET p_basket_id = LAST_INSERT_ID();
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_manufactured_brick` (IN `p_serial_number` VARCHAR(100), IN `p_certif_num` VARCHAR(100), IN `p_image_id` INT, IN `p_color_id` INT, IN `p_stock_id` INT, IN `p_spec_id` INT, OUT `p_unique_id` BIGINT)   BEGIN
    INSERT INTO manufactured_brick (
        serial_number,
        certif_num,
        image_id,
        color_id,
        stock_id,
        spec_id
    )
    VALUES (
        p_serial_number,
        p_certif_num,
        p_image_id,
        p_color_id,
        p_stock_id,
        p_spec_id
    );

    SET p_unique_id = LAST_INSERT_ID();
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_user` (IN `p_nickname` VARCHAR(50), IN `p_email` VARCHAR(255), IN `p_password` VARCHAR(255), OUT `p_user_id` INT)   BEGIN
    INSERT INTO users (nickname, email, password, verified)
    VALUES (p_nickname, p_email, p_password, 0);

    SET p_user_id = LAST_INSERT_ID();
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `address`
--

DROP TABLE IF EXISTS `address`;
CREATE TABLE `address` (
  `id` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `line1` varchar(255) NOT NULL,
  `city` varchar(100) NOT NULL,
  `postal_code` varchar(20) NOT NULL,
  `country` varchar(100) NOT NULL DEFAULT 'France',
  `is_default` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `basket`
--

DROP TABLE IF EXISTS `basket`;
CREATE TABLE `basket` (
  `basket_id` int(10) UNSIGNED NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `total_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `user_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `basket_item`
--

DROP TABLE IF EXISTS `basket_item`;
CREATE TABLE `basket_item` (
  `basket_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `unique_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déclencheurs `basket_item`
--
DROP TRIGGER IF EXISTS `trg_bi_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_bi_before_insert` BEFORE INSERT ON `basket_item` FOR EACH ROW BEGIN
    DECLARE v_basket_user INT;

    SELECT user_id INTO v_basket_user
    FROM basket
    WHERE basket_id = NEW.basket_id;

    IF v_basket_user IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Panier inexistant';
    END IF;

    IF v_basket_user <> NEW.user_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Utilisateur du panier incorrect';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `brick_spec`
--

DROP TABLE IF EXISTS `brick_spec`;
CREATE TABLE `brick_spec` (
  `spec_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `width` decimal(5,2) NOT NULL,
  `lenght` decimal(5,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `brick_spec`
--

INSERT INTO `brick_spec` (`spec_id`, `name`, `width`, `lenght`) VALUES
(1, '4-6', 4.00, 6.00),
(2, '4-8', 4.00, 8.00),
(3, '4-10', 4.00, 10.00),
(4, '1-12', 1.00, 12.00),
(5, '3-3-1245', 3.00, 3.00),
(6, '2-14', 2.00, 14.00),
(7, '6-8', 6.00, 8.00),
(8, '4-4', 4.00, 4.00),
(9, '1-2', 1.00, 2.00),
(10, '2-3', 2.00, 3.00),
(11, '1-8', 1.00, 8.00),
(12, '6-6', 6.00, 6.00),
(13, '2-2-1', 2.00, 2.00),
(14, '6-8', 6.00, 8.00),
(15, '2-12', 2.00, 12.00),
(16, '6-14', 6.00, 14.00),
(17, '2-16', 2.00, 16.00),
(18, '2-2', 2.00, 2.00),
(19, '1-1', 1.00, 1.00),
(20, '6-16', 6.00, 16.00),
(21, '1-4', 1.00, 4.00),
(22, '2-6', 2.00, 6.00),
(23, '2-4', 2.00, 4.00),
(24, '6-10', 6.00, 10.00),
(25, '8-8', 8.00, 8.00),
(26, '6-24', 6.00, 24.00),
(27, '1-1', 1.00, 1.00),
(28, '6-12', 6.00, 12.00),
(29, '2-3-1', 2.00, 3.00),
(30, '1-6', 1.00, 6.00),
(31, '2-10', 2.00, 10.00),
(32, '1-5', 1.00, 5.00),
(33, '3-3-0268', 3.00, 3.00),
(34, '4-12', 4.00, 12.00),
(35, '3-3', 3.00, 3.00),
(36, '1-3', 1.00, 3.00),
(37, '4-4-2367', 4.00, 4.00),
(38, '8-11', 8.00, 11.00),
(39, '1-10', 1.00, 10.00),
(40, '16-16', 16.00, 16.00),
(41, '2-8', 2.00, 8.00);

-- --------------------------------------------------------

--
-- Structure de la table `color`
--

DROP TABLE IF EXISTS `color`;
CREATE TABLE `color` (
  `color_id` int(10) UNSIGNED NOT NULL,
  `hex_code` char(7) NOT NULL,
  `color_name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `color`
--

INSERT INTO `color` (`color_id`, `hex_code`, `color_name`) VALUES
(1, '05131D', 'Black'),
(2, '237841', 'Green'),
(3, '008F9B', 'Dark Turquoise'),
(4, 'C91A09', 'Red'),
(5, 'C870A0', 'Dark Pink'),
(6, '583927', 'Brown'),
(7, '9BA19D', 'Light Gray'),
(8, '6D6E5C', 'Dark Gray'),
(9, 'B4D2E3', 'Light Blue'),
(10, '4B9F4A', 'Bright Green'),
(11, '55A5AF', 'Light Turquoise'),
(12, 'F2705E', 'Salmon'),
(13, 'FC97AC', 'Pink'),
(14, 'F2CD37', 'Yellow'),
(15, 'FFFFFF', 'White'),
(17, 'C2DAB8', 'Light Green'),
(18, 'FBE696', 'Light Yellow'),
(19, 'E4CD9E', 'Tan'),
(20, 'C9CAE2', 'Light Violet'),
(21, 'D4D5C9', 'Glow In Dark Opaque'),
(22, '81007B', 'Purple'),
(23, '2032B0', 'Dark Blue-Violet'),
(25, 'FE8A18', 'Orange'),
(26, '923978', 'Magenta'),
(27, 'BBE90B', 'Lime'),
(28, '958A73', 'Dark Tan'),
(29, 'E4ADC8', 'Bright Pink'),
(30, 'AC78BA', 'Medium Lavender'),
(31, 'E1D5ED', 'Lavender'),
(32, '635F52', 'Trans-Black IR Lens'),
(33, '0020A0', 'Trans-Dark Blue'),
(34, '84B68D', 'Trans-Green'),
(35, 'D9E4A7', 'Trans-Bright Green'),
(36, 'C91A09', 'Trans-Red'),
(40, '635F52', 'Trans-Brown'),
(41, 'AEEFEC', 'Trans-Light Blue'),
(42, 'F8F184', 'Trans-Neon Green'),
(43, 'C1DFF0', 'Trans-Very Lt Blue'),
(45, 'DF6695', 'Trans-Dark Pink'),
(46, 'F5CD2F', 'Trans-Yellow'),
(47, 'FCFCFC', 'Trans-Clear'),
(52, 'A5A5CB', 'Trans-Purple'),
(54, 'DAB000', 'Trans-Neon Yellow'),
(57, 'FF800D', 'Trans-Neon Orange'),
(60, '645A4C', 'Chrome Antique Brass'),
(61, '6C96BF', 'Chrome Blue'),
(62, '3CB371', 'Chrome Green'),
(63, 'AA4D8E', 'Chrome Pink'),
(64, '1B2A34', 'Chrome Black'),
(68, 'F3CF9B', 'Very Light Orange'),
(69, 'CD6298', 'Light Purple'),
(70, '582A12', 'Reddish Brown'),
(71, 'A0A5A9', 'Light Bluish Gray'),
(72, '6C6E68', 'Dark Bluish Gray'),
(73, '5A93DB', 'Medium Blue'),
(74, '73DCA1', 'Medium Green'),
(75, '05131D', 'Speckle Black-Copper'),
(76, '6C6E68', 'Speckle DBGray-Silver'),
(77, 'FECCCF', 'Light Pink'),
(78, 'F6D7B3', 'Light Nougat'),
(79, 'FFFFFF', 'Milky White'),
(80, 'A5A9B4', 'Metallic Silver'),
(81, '899B5F', 'Metallic Green'),
(82, 'DBAC34', 'Metallic Gold'),
(84, 'AA7D55', 'Medium Nougat'),
(85, '3F3691', 'Dark Purple'),
(86, '7C503A', 'Light Brown'),
(89, '4C61DB', 'Royal Blue'),
(92, 'D09168', 'Nougat'),
(100, 'FEBABD', 'Light Salmon'),
(110, '4354A3', 'Violet'),
(112, '6874CA', 'Medium Bluish Violet'),
(114, 'DF6695', 'Glitter Trans-Dark Pink'),
(115, 'C7D23C', 'Medium Lime'),
(117, 'FFFFFF', 'Glitter Trans-Clear'),
(118, 'B3D7D1', 'Aqua'),
(120, 'D9E4A7', 'Light Lime'),
(125, 'F9BA61', 'Light Orange'),
(129, 'A5A5CB', 'Glitter Trans-Purple'),
(132, '05131D', 'Speckle Black-Silver'),
(133, '05131D', 'Speckle Black-Gold'),
(134, 'AE7A59', 'Copper'),
(135, '9CA3A8', 'Pearl Light Gray'),
(137, '7988A1', 'Pearl Sand Blue'),
(142, 'DCBC81', 'Pearl Light Gold'),
(143, 'CFE2F7', 'Trans-Medium Blue'),
(148, '575857', 'Pearl Dark Gray'),
(150, 'ABADAC', 'Pearl Very Light Gray'),
(151, 'E6E3E0', 'Very Light Bluish Gray'),
(158, 'DFEEA5', 'Yellowish Green'),
(178, 'B48455', 'Flat Dark Gold'),
(179, '898788', 'Flat Silver'),
(182, 'F08F1C', 'Trans-Orange'),
(183, 'F2F3F2', 'Pearl White'),
(191, 'F8BB3D', 'Bright Light Orange'),
(212, '9FC3E9', 'Bright Light Blue'),
(216, 'B31004', 'Rust'),
(226, 'FFF03A', 'Bright Light Yellow'),
(230, 'E4ADC8', 'Trans-Pink'),
(232, '7DBFDD', 'Sky Blue'),
(236, '96709F', 'Trans-Light Purple'),
(272, '0A3463', 'Dark Blue'),
(288, '184632', 'Dark Green'),
(294, 'BDC6AD', 'Glow In Dark Trans'),
(297, 'AA7F2E', 'Pearl Gold'),
(308, '352100', 'Dark Brown'),
(313, '3592C3', 'Maersk Blue'),
(320, '720E0F', 'Dark Red'),
(321, '078BC9', 'Dark Azure'),
(322, '36AEBF', 'Medium Azure'),
(323, 'ADC3C0', 'Light Aqua'),
(326, '9B9A5A', 'Olive Green'),
(334, 'BBA53D', 'Chrome Gold'),
(335, 'D67572', 'Sand Red'),
(351, 'F785B1', 'Medium Dark Pink'),
(366, 'FA9C1C', 'Earth Orange'),
(373, '845E84', 'Sand Purple'),
(378, 'A0BCAC', 'Sand Green'),
(379, '6074A1', 'Sand Blue'),
(383, 'E0E0E0', 'Chrome Silver'),
(450, 'B67B50', 'Fabuland Brown'),
(462, 'FFA70B', 'Medium Orange'),
(484, 'A95500', 'Dark Orange'),
(503, 'E6E3DA', 'Very Light Gray'),
(1000, 'D9D9D9', 'Glow in Dark White'),
(1001, '9391E4', 'Medium Violet'),
(1002, 'C0F500', 'Glitter Trans-Neon Green'),
(1003, '68BCC5', 'Glitter Trans-Light Blue'),
(1004, 'FCB76D', 'Trans-Flame Yellowish Orange'),
(1005, 'FBE890', 'Trans-Fire Yellow'),
(1006, 'B4D4F7', 'Trans-Light Royal Blue'),
(1007, '8E5597', 'Reddish Lilac'),
(1008, '039CBD', 'Vintage Blue'),
(1009, '1E601E', 'Vintage Green'),
(1010, 'CA1F08', 'Vintage Red'),
(1011, 'F3C305', 'Vintage Yellow'),
(1012, 'EF9121', 'Fabuland Orange'),
(1013, 'F4F4F4', 'Modulex White'),
(1014, 'AfB5C7', 'Modulex Light Bluish Gray'),
(1015, '9C9C9C', 'Modulex Light Gray'),
(1016, '595D60', 'Modulex Charcoal Gray'),
(1017, '6B5A5A', 'Modulex Tile Gray'),
(1018, '4D4C52', 'Modulex Black'),
(1019, '330000', 'Modulex Tile Brown'),
(1020, '5C5030', 'Modulex Terracotta'),
(1021, '907450', 'Modulex Brown'),
(1022, 'DEC69C', 'Modulex Buff'),
(1023, 'B52C20', 'Modulex Red'),
(1024, 'F45C40', 'Modulex Pink Red'),
(1025, 'F47B30', 'Modulex Orange'),
(1026, 'F7AD63', 'Modulex Light Orange'),
(1027, 'FFE371', 'Modulex Light Yellow'),
(1028, 'FED557', 'Modulex Ochre Yellow'),
(1029, 'BDC618', 'Modulex Lemon'),
(1030, '7DB538', 'Modulex Pastel Green'),
(1031, '7C9051', 'Modulex Olive Green'),
(1032, '27867E', 'Modulex Aqua Green'),
(1033, '467083', 'Modulex Teal Blue'),
(1034, '0057A6', 'Modulex Tile Blue'),
(1035, '61AFFF', 'Modulex Medium Blue'),
(1036, '68AECE', 'Modulex Pastel Blue'),
(1037, 'BD7D85', 'Modulex Violet'),
(1038, 'F785B1', 'Modulex Pink'),
(1039, 'FFFFFF', 'Modulex Clear'),
(1040, '595D60', 'Modulex Foil Dark Gray'),
(1041, '9C9C9C', 'Modulex Foil Light Gray'),
(1042, '006400', 'Modulex Foil Dark Green'),
(1043, '7DB538', 'Modulex Foil Light Green'),
(1044, '0057A6', 'Modulex Foil Dark Blue'),
(1045, '68AECE', 'Modulex Foil Light Blue'),
(1046, '4B0082', 'Modulex Foil Violet'),
(1047, '8B0000', 'Modulex Foil Red'),
(1048, 'FED557', 'Modulex Foil Yellow'),
(1049, 'F7AD63', 'Modulex Foil Orange'),
(1050, 'FF698F', 'Coral'),
(1051, '5AC4DA', 'Pastel Blue'),
(1052, 'F08F1C', 'Glitter Trans-Orange'),
(1053, '68BCC5', 'Opal Trans-Light Blue'),
(1054, 'CE1D9B', 'Opal Trans-Dark Pink'),
(1055, 'FCFCFC', 'Opal Trans-Clear'),
(1056, '583927', 'Opal Trans-Brown'),
(1057, 'C9E788', 'Trans-Light Bright Green'),
(1058, '94E5AB', 'Trans-Light Green'),
(1059, '8320B7', 'Opal Trans-Purple'),
(1060, '84B68D', 'Opal Trans-Bright Green'),
(1061, '0020A0', 'Opal Trans-Dark Blue'),
(1062, 'EBD800', 'Vibrant Yellow'),
(1063, 'B46A00', 'Pearl Copper'),
(1064, 'FF8014', 'Fabuland Red'),
(1065, 'AC8247', 'Reddish Gold'),
(1066, 'DD982E', 'Curry'),
(1067, 'AD6140', 'Dark Nougat'),
(1068, 'EE5434', 'Bright Reddish Orange'),
(1069, 'D60026', 'Pearl Red'),
(1070, '0059A3', 'Pearl Blue'),
(1071, '008E3C', 'Pearl Green'),
(1072, '57392C', 'Pearl Brown'),
(1073, '0A1327', 'Pearl Black'),
(1074, '009ECE', 'Duplo Blue'),
(1075, '3E95B6', 'Duplo Medium Blue'),
(1076, 'FFF230', 'Duplo Lime'),
(1077, '78FC78', 'Fabuland Lime'),
(1078, '468A5F', 'Duplo Medium Green'),
(1079, '60BA76', 'Duplo Light Green'),
(1080, 'F3C988', 'Light Tan'),
(1081, '872B17', 'Rust Orange'),
(1082, 'FE78B0', 'Clikits Pink'),
(1083, '945148', 'Two-tone Copper'),
(1084, 'AB673A', 'Two-tone Gold'),
(1085, '737271', 'Two-tone Silver'),
(1086, '6A7944', 'Pearl Lime'),
(1087, 'FF879C', 'Duplo Pink'),
(1088, '755945', 'Medium Brown'),
(1089, 'CCA373', 'Warm Tan'),
(1090, '3FB69E', 'Duplo Turquoise'),
(1091, 'FFCB78', 'Warm Yellowish Orange'),
(1092, '764D3B', 'Metallic Copper'),
(1093, '9195CA', 'Light Lilac'),
(1094, '8D73B3', 'Trans-Medium Purple'),
(1095, '635F52', 'Trans-Black'),
(1096, 'D9E4A7', 'Glitter Trans-Bright Green'),
(1097, '8D73B3', 'Glitter Trans-Medium Purple'),
(1098, '84B68D', 'Glitter Trans-Green'),
(1099, 'E4ADC8', 'Glitter Trans-Pink'),
(1100, 'FFCF0B', 'Clikits Yellow'),
(1101, '5F27AA', 'Duplo Dark Purple'),
(1102, 'FF0040', 'Trans-Neon Red'),
(1103, '3E3C39', 'Pearl Titanium'),
(1104, 'B3D7D1', 'HO Aqua'),
(1105, '1591cb', 'HO Azure'),
(1106, '354e5a', 'HO Blue-gray'),
(1107, '5b98b3', 'HO Cyan'),
(1108, 'a7dccf', 'HO Dark Aqua'),
(1109, '0A3463', 'HO Dark Blue'),
(1110, '6D6E5C', 'HO Dark Gray'),
(1111, '184632', 'HO Dark Green'),
(1112, 'b2b955', 'HO Dark Lime'),
(1113, '631314', 'HO Dark Red'),
(1114, '627a62', 'HO Dark Sand Green'),
(1115, '10929d', 'HO Dark Turquoise'),
(1116, 'bb771b', 'HO Earth Orange'),
(1117, 'b4a774', 'HO Gold'),
(1118, 'a3d1c0', 'HO Light Aqua'),
(1119, '965336', 'HO Light Brown'),
(1120, 'cdc298', 'HO Light Gold'),
(1121, 'f9f1c7', 'HO Light Tan'),
(1122, 'f5fab7', 'HO Light Yellow'),
(1123, '7396c8', 'HO Medium Blue'),
(1124, 'c01111', 'HO Medium Red'),
(1125, '0d4763', 'HO Metallic Blue'),
(1126, '5e5e5e', 'HO Metallic Dark Gray'),
(1127, '879867', 'HO Metallic Green'),
(1128, '5f7d8c', 'HO Metallic Sand Blue'),
(1129, '9B9A5A', 'HO Olive Green'),
(1130, 'd06262', 'HO Rose'),
(1131, '6e8aa6', 'HO Sand Blue'),
(1132, 'A0BCAC', 'HO Sand Green'),
(1133, 'E4CD9E', 'HO Tan'),
(1134, '616161', 'HO Titanium'),
(1135, 'A5ADB4', 'Metal'),
(1136, 'CA4C0B', 'Reddish Orange'),
(1137, '915C3C', 'Sienna Brown'),
(1138, '5E3F33', 'Umber Brown'),
(1139, 'F5CD2F', 'Opal Trans-Yellow'),
(1140, 'EC4612', 'Neon Orange'),
(1141, 'D2FC43', 'Neon Green'),
(1142, '5d5c36', 'Dark Olive Green'),
(1143, 'FFFFFF', 'Glitter Milky White'),
(1144, 'CE3021', 'Chrome Red'),
(1145, 'DD9E47', 'Ochre Yellow'),
(9999, '05131D', '[No Color/Any Color]');

-- --------------------------------------------------------

--
-- Structure de la table `images`
--

DROP TABLE IF EXISTS `images`;
CREATE TABLE `images` (
  `image_id` int(10) UNSIGNED NOT NULL,
  `image` longtext NOT NULL,
  `upload_date` datetime NOT NULL DEFAULT current_timestamp(),
  `user_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déclencheurs `images`
--
DROP TRIGGER IF EXISTS `trg_images_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_images_before_insert` BEFORE INSERT ON `images` FOR EACH ROW BEGIN
    IF NEW.upload_date IS NULL THEN
        SET NEW.upload_date = NOW();
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `invoices`
--

DROP TABLE IF EXISTS `invoices`;
CREATE TABLE `invoices` (
  `id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `invoice_number` varchar(50) NOT NULL,
  `content_json` longtext NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `manufactured_brick`
--

DROP TABLE IF EXISTS `manufactured_brick`;
CREATE TABLE `manufactured_brick` (
  `unique_id` bigint(20) UNSIGNED NOT NULL,
  `serial_number` varchar(100) NOT NULL,
  `certif_num` varchar(100) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `image_id` int(10) UNSIGNED DEFAULT NULL,
  `color_id` int(10) UNSIGNED NOT NULL,
  `stock_id` int(10) UNSIGNED NOT NULL,
  `spec_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déclencheurs `manufactured_brick`
--
DROP TRIGGER IF EXISTS `trg_mb_after_insert`;
DELIMITER $$
CREATE TRIGGER `trg_mb_after_insert` AFTER INSERT ON `manufactured_brick` FOR EACH ROW BEGIN
    DECLARE v_quantity INT;

    SELECT quantity INTO v_quantity
    FROM stock
    WHERE stock_id = NEW.stock_id
    FOR UPDATE;

    IF v_quantity IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock introuvable';
    END IF;

    IF v_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuffisant';
    END IF;

    UPDATE stock
    SET quantity = quantity - 1
    WHERE stock_id = NEW.stock_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `mosaic`
--

DROP TABLE IF EXISTS `mosaic`;
CREATE TABLE `mosaic` (
  `id` int(11) NOT NULL,
  `uploads_id` int(11) NOT NULL,
  `filter_used` varchar(50) NOT NULL,
  `size_option` int(11) NOT NULL,
  `estimated_price` decimal(10,2) NOT NULL,
  `brick_data` longtext DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `orders`
--

DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
  `id` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `mosaic_id` int(11) NOT NULL,
  `shipping_address_id` int(11) NOT NULL,
  `order_number` varchar(50) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'paid',
  `total_amount` decimal(10,2) NOT NULL,
  `payment_method` varchar(50) NOT NULL DEFAULT 'card',
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `payment`
--

DROP TABLE IF EXISTS `payment`;
CREATE TABLE `payment` (
  `payment_id` int(10) UNSIGNED NOT NULL,
  `CB_code` varchar(19) NOT NULL,
  `CB_name` varchar(100) NOT NULL,
  `CB_CVV` char(4) NOT NULL,
  `CB_expirationdate` char(5) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `stock`
--

DROP TABLE IF EXISTS `stock`;
CREATE TABLE `stock` (
  `stock_id` int(10) UNSIGNED NOT NULL,
  `quantity` int(10) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `stock_color`
--

DROP TABLE IF EXISTS `stock_color`;
CREATE TABLE `stock_color` (
  `stock_id` int(10) UNSIGNED NOT NULL,
  `color_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `uploads`
--

DROP TABLE IF EXISTS `uploads`;
CREATE TABLE `uploads` (
  `id_upload` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `filename` varchar(255) NOT NULL,
  `image_data` longblob NOT NULL,
  `image_type` varchar(50) NOT NULL,
  `uploaded_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `user_id` int(10) UNSIGNED NOT NULL,
  `nickname` varchar(50) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `firstname` varchar(100) DEFAULT NULL,
  `lastname` varchar(100) DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `birth_year` int(11) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `role` varchar(20) DEFAULT 'user',
  `verified` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `two_factor_code` varchar(6) DEFAULT NULL,
  `two_factor_expires_at` datetime DEFAULT NULL,
  `reset_token` varchar(255) DEFAULT NULL,
  `reset_expires_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déclencheurs `users`
--
DROP TRIGGER IF EXISTS `trg_users_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_users_before_insert` BEFORE INSERT ON `users` FOR EACH ROW BEGIN
    IF NEW.created_at IS NULL THEN
        SET NEW.created_at = NOW();
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `user_log`
--

DROP TABLE IF EXISTS `user_log`;
CREATE TABLE `user_log` (
  `log_id` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED DEFAULT NULL,
  `level` varchar(50) NOT NULL,
  `message` text NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `address`
--
ALTER TABLE `address`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_addr_user` (`user_id`);

--
-- Index pour la table `basket`
--
ALTER TABLE `basket`
  ADD PRIMARY KEY (`basket_id`),
  ADD KEY `fk_basket_user` (`user_id`);

--
-- Index pour la table `basket_item`
--
ALTER TABLE `basket_item`
  ADD PRIMARY KEY (`basket_id`,`unique_id`),
  ADD KEY `fk_bi_user` (`user_id`),
  ADD KEY `fk_bi_brick` (`unique_id`);

--
-- Index pour la table `brick_spec`
--
ALTER TABLE `brick_spec`
  ADD PRIMARY KEY (`spec_id`);

--
-- Index pour la table `color`
--
ALTER TABLE `color`
  ADD PRIMARY KEY (`color_id`);

--
-- Index pour la table `images`
--
ALTER TABLE `images`
  ADD PRIMARY KEY (`image_id`),
  ADD KEY `fk_images_user` (`user_id`);

--
-- Index pour la table `invoices`
--
ALTER TABLE `invoices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `invoice_number` (`invoice_number`),
  ADD KEY `fk_invoice_order` (`order_id`);

--
-- Index pour la table `manufactured_brick`
--
ALTER TABLE `manufactured_brick`
  ADD PRIMARY KEY (`unique_id`),
  ADD UNIQUE KEY `serial_number` (`serial_number`),
  ADD KEY `fk_mb_image` (`image_id`),
  ADD KEY `fk_mb_color` (`color_id`),
  ADD KEY `fk_mb_stock` (`stock_id`),
  ADD KEY `fk_mb_spec` (`spec_id`);

--
-- Index pour la table `mosaic`
--
ALTER TABLE `mosaic`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_mosaic_upload` (`uploads_id`);

--
-- Index pour la table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `order_number` (`order_number`),
  ADD KEY `fk_order_user` (`user_id`),
  ADD KEY `fk_order_mosaic` (`mosaic_id`),
  ADD KEY `fk_order_addr` (`shipping_address_id`);

--
-- Index pour la table `payment`
--
ALTER TABLE `payment`
  ADD PRIMARY KEY (`payment_id`),
  ADD KEY `fk_payment_user` (`user_id`);

--
-- Index pour la table `stock`
--
ALTER TABLE `stock`
  ADD PRIMARY KEY (`stock_id`);

--
-- Index pour la table `stock_color`
--
ALTER TABLE `stock_color`
  ADD PRIMARY KEY (`stock_id`,`color_id`),
  ADD KEY `fk_sc_color` (`color_id`);

--
-- Index pour la table `uploads`
--
ALTER TABLE `uploads`
  ADD PRIMARY KEY (`id_upload`),
  ADD KEY `fk_uploads_user` (`user_id`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Index pour la table `user_log`
--
ALTER TABLE `user_log`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `fk_log_user` (`user_id`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `address`
--
ALTER TABLE `address`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `basket`
--
ALTER TABLE `basket`
  MODIFY `basket_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `brick_spec`
--
ALTER TABLE `brick_spec`
  MODIFY `spec_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `color`
--
ALTER TABLE `color`
  MODIFY `color_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `images`
--
ALTER TABLE `images`
  MODIFY `image_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `invoices`
--
ALTER TABLE `invoices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `manufactured_brick`
--
ALTER TABLE `manufactured_brick`
  MODIFY `unique_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `mosaic`
--
ALTER TABLE `mosaic`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `payment`
--
ALTER TABLE `payment`
  MODIFY `payment_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `stock`
--
ALTER TABLE `stock`
  MODIFY `stock_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `uploads`
--
ALTER TABLE `uploads`
  MODIFY `id_upload` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `user_log`
--
ALTER TABLE `user_log`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `address`
--
ALTER TABLE `address`
  ADD CONSTRAINT `fk_addr_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `basket`
--
ALTER TABLE `basket`
  ADD CONSTRAINT `fk_basket_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `basket_item`
--
ALTER TABLE `basket_item`
  ADD CONSTRAINT `fk_bi_basket` FOREIGN KEY (`basket_id`) REFERENCES `basket` (`basket_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_bi_brick` FOREIGN KEY (`unique_id`) REFERENCES `manufactured_brick` (`unique_id`),
  ADD CONSTRAINT `fk_bi_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `images`
--
ALTER TABLE `images`
  ADD CONSTRAINT `fk_images_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `invoices`
--
ALTER TABLE `invoices`
  ADD CONSTRAINT `fk_invoice_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `manufactured_brick`
--
ALTER TABLE `manufactured_brick`
  ADD CONSTRAINT `fk_mb_color` FOREIGN KEY (`color_id`) REFERENCES `color` (`color_id`),
  ADD CONSTRAINT `fk_mb_image` FOREIGN KEY (`image_id`) REFERENCES `images` (`image_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_mb_spec` FOREIGN KEY (`spec_id`) REFERENCES `brick_spec` (`spec_id`),
  ADD CONSTRAINT `fk_mb_stock` FOREIGN KEY (`stock_id`) REFERENCES `stock` (`stock_id`);

--
-- Contraintes pour la table `mosaic`
--
ALTER TABLE `mosaic`
  ADD CONSTRAINT `fk_mosaic_upload` FOREIGN KEY (`uploads_id`) REFERENCES `uploads` (`id_upload`) ON DELETE CASCADE;

--
-- Contraintes pour la table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_order_addr` FOREIGN KEY (`shipping_address_id`) REFERENCES `address` (`id`),
  ADD CONSTRAINT `fk_order_mosaic` FOREIGN KEY (`mosaic_id`) REFERENCES `mosaic` (`id`),
  ADD CONSTRAINT `fk_order_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Contraintes pour la table `payment`
--
ALTER TABLE `payment`
  ADD CONSTRAINT `fk_payment_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `stock_color`
--
ALTER TABLE `stock_color`
  ADD CONSTRAINT `fk_sc_color` FOREIGN KEY (`color_id`) REFERENCES `color` (`color_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_sc_stock` FOREIGN KEY (`stock_id`) REFERENCES `stock` (`stock_id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `uploads`
--
ALTER TABLE `uploads`
  ADD CONSTRAINT `fk_uploads_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `user_log`
--
ALTER TABLE `user_log`
  ADD CONSTRAINT `fk_log_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
