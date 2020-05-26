-- PostgreSQL logo for FreeBSD loader.
-- 
-- author: Luca Ferrari
--         fluca1978 (at) gmail (dot) com
--
-- This file provides a black-and-white PostgreSQL
-- logo for the FreeBSD lua-based loader.
--
-- In order to use this logo:
-- 1) place the file in the directory /boot/lua/
--    naming it 'logo-postgresqlbw.lua'
-- 2) ensure the file has read permissions
-- 3) in /boot/loader.conf add the option
--      loader_logo="postgresqlbw"
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

local postgresql_bw = {
"   ____  ______  ___   ",
"  /    )/      \\/   \\  ",
" (     / __    _\\    ) ",
"  \\    (/ o)  ( o)   ) ",
"   \\_  (_  )   \\ )  /  ",
"     \\  /\\_/    \\)_/   ",
"      \\/  //|  |\\\\     ",
"          v |  | v     ",
"            \\__/       ",
}

drawer.addLogo( "postgresqlbw", {
	requires_color = false,
	graphic = postgresql_bw,
	shift = {x = 2, y = 8},
})

return true
