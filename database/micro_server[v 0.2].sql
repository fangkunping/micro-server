-- phpMyAdmin SQL Dump
-- version 4.6.5.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: 2019-02-25 03:39:47
-- 服务器版本： 10.1.21-MariaDB
-- PHP Version: 5.6.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `micro_server`
--

-- --------------------------------------------------------

--
-- 表的结构 `access_partys`
--

CREATE TABLE `access_partys` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL DEFAULT '',
  `app_id` varchar(32) NOT NULL DEFAULT '',
  `note` varchar(2048) NOT NULL DEFAULT '',
  `vip` int(11) NOT NULL DEFAULT '0',
  `type` int(11) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `users_id` bigint(20) UNSIGNED DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `access_partys`
--

INSERT INTO `access_partys` (`id`, `name`, `app_id`, `note`, `vip`, `type`, `is_active`, `users_id`, `inserted_at`, `updated_at`) VALUES
(1, 'test', 'e16427c387923c1e48ee17ef4ad3e2ac', '测试用', 80001, 1, 1, 1, '2018-11-08 03:38:52', '2018-11-08 03:38:52');

-- --------------------------------------------------------

--
-- 表的结构 `schema_migrations`
--

CREATE TABLE `schema_migrations` (
  `version` bigint(20) NOT NULL,
  `inserted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `schema_migrations`
--

INSERT INTO `schema_migrations` (`version`, `inserted_at`) VALUES
(20181106160028, '2018-11-15 02:08:52'),
(20181107082321, '2018-11-15 02:08:53'),
(20181107085847, '2018-11-15 02:08:53'),
(20181108022055, '2018-11-15 02:08:53'),
(20181108075850, '2018-11-15 02:08:53'),
(20181109053703, '2018-11-15 02:08:53');

-- --------------------------------------------------------

--
-- 表的结构 `scripts`
--

CREATE TABLE `scripts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL DEFAULT '',
  `note` varchar(2048) NOT NULL DEFAULT '',
  `content` varchar(10240) NOT NULL DEFAULT '',
  `type` int(11) NOT NULL DEFAULT '1',
  `access_partys_id` bigint(20) UNSIGNED DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `scripts`
--

INSERT INTO `scripts` (`id`, `name`, `note`, `content`, `type`, `access_partys_id`, `inserted_at`, `updated_at`) VALUES
(1, 'test', '测试脚本1', 'require(web, cache1)\r\ncache1_table(\"man\", id, name, age)\r\nfunction on_http(ticket, msg) \r\n  cache1.q_write(\"man\", {id=1, name=\"Max\", age=42})\r\n  cache1.q_write(\"man\", {id=2, name=\"Apple\", age=8})\r\n  cache1.q_write(\"man\", {id=3, name=\"Banana\", age=20})\r\n  cache1.q_write(\"man\", {id=4, name=\"Orange\", age=21})\r\n  print(msg)\r\n  pipe_send(2, \"hello world\")\r\nend\r\nfunction on_pipe_receive(ticket, from_server_id, ...)\r\n  print({...})\r\nend', 1, 1, '2018-11-09 02:38:09', '2019-02-21 16:12:16'),
(2, 'test script', '测试脚本2', 'require(cache1)\r\ncache1_table(\"man\", id, name, age)\r\ncache1_def_query(\"man\", \"selete by name\", [[name == \"1\"]] )\r\ncache1_def_query(\"man\", \"selete by age\", [[age >= \"1\"]] )\r\n\r\nfunction on_pipe_receive(ticket, from_server_id, ...)\r\n  print(cache1.q_select(\"selete by age\", 20))\r\n  print({...})\r\n  pipe_send(from_server_id, \"i have receive\", {1,2,3,4})\r\nend', 1, 1, '2019-02-17 04:13:09', '2019-02-21 16:12:43');

-- --------------------------------------------------------

--
-- 表的结构 `servers`
--

CREATE TABLE `servers` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL DEFAULT '',
  `note` varchar(2048) NOT NULL DEFAULT '',
  `type` int(11) NOT NULL DEFAULT '1',
  `access_partys_id` bigint(20) UNSIGNED DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `servers`
--

INSERT INTO `servers` (`id`, `name`, `note`, `type`, `access_partys_id`, `inserted_at`, `updated_at`) VALUES
(1, 'test', '测试服务器', 1, 1, '2018-11-08 08:42:24', '2018-11-09 02:49:59'),
(2, 'test2', '测试服务器2', 1, 1, '2018-11-08 08:42:24', '2018-11-09 02:49:59'),
(3, '03A5F5E591AFDE18', 'EBB713277751F594', 1, 1, '2019-02-22 04:10:03', '2019-02-22 04:10:03');

-- --------------------------------------------------------

--
-- 表的结构 `server_logs`
--

CREATE TABLE `server_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `servers_id` bigint(20) UNSIGNED DEFAULT NULL,
  `log` varchar(8192) NOT NULL DEFAULT '',
  `erl_log` varchar(10240) NOT NULL DEFAULT '',
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- 表的结构 `server_scripts`
--

CREATE TABLE `server_scripts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `servers_id` bigint(20) UNSIGNED DEFAULT NULL,
  `scripts_id` bigint(20) UNSIGNED DEFAULT NULL,
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `server_scripts`
--

INSERT INTO `server_scripts` (`id`, `servers_id`, `scripts_id`, `inserted_at`, `updated_at`) VALUES
(1, 1, 1, '2018-11-08 08:42:24', '2018-11-08 08:42:24'),
(3, 2, 2, '2019-02-21 15:01:04', '2019-02-21 15:01:04');

-- --------------------------------------------------------

--
-- 表的结构 `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `username` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `mobile` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `hidden` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `inserted_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `users`
--

INSERT INTO `users` (`id`, `username`, `email`, `mobile`, `password_hash`, `hidden`, `is_active`, `inserted_at`, `updated_at`) VALUES
(1, 'max', 'honeymax@21cn.com', '18666680129', '100d9e041bcd1fe2a7d0cba55303b8b4:1075', 0, 1, '2018-11-15 02:04:54', '2018-12-14 16:43:37');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `access_partys`
--
ALTER TABLE `access_partys`
  ADD PRIMARY KEY (`id`),
  ADD KEY `access_partys_users_id_fkey` (`users_id`);

--
-- Indexes for table `schema_migrations`
--
ALTER TABLE `schema_migrations`
  ADD PRIMARY KEY (`version`);

--
-- Indexes for table `scripts`
--
ALTER TABLE `scripts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `scripts_access_partys_id_fkey` (`access_partys_id`);

--
-- Indexes for table `servers`
--
ALTER TABLE `servers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `servers_access_partys_id_fkey` (`access_partys_id`);

--
-- Indexes for table `server_logs`
--
ALTER TABLE `server_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `server_logs_servers_id_fkey` (`servers_id`);

--
-- Indexes for table `server_scripts`
--
ALTER TABLE `server_scripts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `server_scripts_servers_id_fkey` (`servers_id`),
  ADD KEY `server_scripts_scripts_id_fkey` (`scripts_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_username_index` (`username`);

--
-- 在导出的表使用AUTO_INCREMENT
--

--
-- 使用表AUTO_INCREMENT `access_partys`
--
ALTER TABLE `access_partys`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
--
-- 使用表AUTO_INCREMENT `scripts`
--
ALTER TABLE `scripts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
--
-- 使用表AUTO_INCREMENT `servers`
--
ALTER TABLE `servers`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
--
-- 使用表AUTO_INCREMENT `server_logs`
--
ALTER TABLE `server_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;
--
-- 使用表AUTO_INCREMENT `server_scripts`
--
ALTER TABLE `server_scripts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
--
-- 使用表AUTO_INCREMENT `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
--
-- 限制导出的表
--

--
-- 限制表 `access_partys`
--
ALTER TABLE `access_partys`
  ADD CONSTRAINT `access_partys_users_id_fkey` FOREIGN KEY (`users_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- 限制表 `scripts`
--
ALTER TABLE `scripts`
  ADD CONSTRAINT `scripts_access_partys_id_fkey` FOREIGN KEY (`access_partys_id`) REFERENCES `access_partys` (`id`) ON DELETE CASCADE;

--
-- 限制表 `servers`
--
ALTER TABLE `servers`
  ADD CONSTRAINT `servers_access_partys_id_fkey` FOREIGN KEY (`access_partys_id`) REFERENCES `access_partys` (`id`) ON DELETE CASCADE;

--
-- 限制表 `server_logs`
--
ALTER TABLE `server_logs`
  ADD CONSTRAINT `server_logs_servers_id_fkey` FOREIGN KEY (`servers_id`) REFERENCES `servers` (`id`) ON DELETE CASCADE;

--
-- 限制表 `server_scripts`
--
ALTER TABLE `server_scripts`
  ADD CONSTRAINT `server_scripts_scripts_id_fkey` FOREIGN KEY (`scripts_id`) REFERENCES `scripts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `server_scripts_servers_id_fkey` FOREIGN KEY (`servers_id`) REFERENCES `servers` (`id`) ON DELETE CASCADE;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
