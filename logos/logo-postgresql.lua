-- PostgreSQL logo for FreeBSD loader.
-- 
-- author: Luca Ferrari
--         fluca1978 (at) gmail (dot) com
--
-- This file provides a coloured PostgreSQL
-- logo for the FreeBSD lua-based loader.
--
-- In order to use this logo:
-- 1) place the file in the directory /boot/lua/
--    naming it 'logo-postgresql.lua'
-- 2) ensure the file has read permissions
-- 3) in /boot/loader.conf add the option
--      loader_logo="postgresql"
--
-- Initial ASCII-art based on the proposal
-- by Charles Clavadetscher
-- <https://www.postgresql.org/message-id/57386570.8090703%40swisspug.org>
-- even if I'm pretty sure there was something
-- older by Oleg Bartunov.

local drawer = require("drawer")

-- Escape sequences:
-- \027[36m cyan
-- \027[39m white
-- \027[34m blue

local postgresql_color = {
"\027[36m   ____  ______  ___   ",
"  /    )/      \\/   \\  ",
" (     / __    _\\    ) ",
"  \\    (/ \027[39mo\027[36m)  ( \027[39mo\027[36m)   ) ",
"   \\_  (_  )   \\ )  /  ",
"     \\  /\\_/    \\)_/   ",
"      \\/  \027[39m//\027[36m|  |\027[39m\\\\\027[36m     ",
"          \027[39mv \027[36m|  |\027[39m v\027[36m     ",
"            \\__/       ",
"\027[39m"
}

drawer.addLogo("postgresql", {
	requires_color = true,
	graphic = postgresql_color,
	shift = {x = 2, y = 8},
})

return true
