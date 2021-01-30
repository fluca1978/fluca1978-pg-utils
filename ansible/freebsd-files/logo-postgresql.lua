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
