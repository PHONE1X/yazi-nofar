-- Yazi в роли системного файлпикера (окно «Открыть» / «Сохранить» в Telegram,
-- браузере, Steam...). Запускает его filepicker/yazi-wrapper.sh с
-- YAZI_CONFIG_HOME=~/.config/yazi-picker. Здесь свои init.lua и keymap.toml,
-- остальное (yazi.toml, тема, плагины, закладки) — ссылки на основной конфиг,
-- так что вид и превью те же, а клавиши пикера в обычный yazi не попадают.

require("full-border"):setup()
require("relative-motions"):setup({ show_numbers = "relative", show_motion = true, enter_mode = "first" })
require("git"):setup { order = 1500 }
pcall(function() require("zoxide"):setup { update_db = true } end)
require("kdeconnect"):setup { auto_select_single = true }
require("gdrive-mount"):setup()

-- Шапка: что от нас хотят и какие клавиши жать.
local MODE = os.getenv("YAZI_PICK") or "open"
local NAME = os.getenv("YAZI_PICK_NAME") or ""

local LABEL = {
	open = "ОТКРЫТЬ ФАЙЛ",
	multi = "ОТКРЫТЬ ФАЙЛЫ",
	dir = "ВЫБРАТЬ ПАПКУ",
	save = "СОХРАНИТЬ",
}

local KEYS = {
	open = { { "Enter", "выбрать" }, { "q", "отмена" } },
	multi = { { "Пробел", "отметить" }, { "Enter", "выбрать" }, { "q", "отмена" } },
	dir = { { "Enter", "войти" }, { "s", "выбрать эту папку" }, { "q", "отмена" } },
	save = { { "Enter", "войти в папку" }, { "s", "сохранить сюда" }, { "q", "отмена" } },
}

Header:children_add(function()
	local text = " " .. (LABEL[MODE] or LABEL.open)
	if MODE == "save" and NAME ~= "" then
		text = text .. " «" .. NAME .. "» в"
	end
	return ui.Line {
		ui.Span(text .. " "):fg("black"):bg("yellow"):bold(),
		ui.Span(" "),
	}
end, 500, Header.LEFT)

Header:children_add(function()
	local spans = {}
	for i, k in ipairs(KEYS[MODE] or KEYS.open) do
		if i > 1 then
			spans[#spans + 1] = ui.Span("  ")
		end
		spans[#spans + 1] = ui.Span(k[1]):fg("yellow"):bold()
		spans[#spans + 1] = ui.Span(" " .. k[2])
	end
	spans[#spans + 1] = ui.Span(" ")
	return ui.Line(spans)
end, 500, Header.RIGHT)
