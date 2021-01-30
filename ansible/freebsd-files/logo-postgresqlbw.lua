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
