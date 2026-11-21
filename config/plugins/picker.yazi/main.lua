--- @since 25.5.31
-- Yazi в роли файлпикера (окна «Открыть» / «Сохранить» в Telegram, браузере,
-- Steam). Конфиг тот же, что у обычного yazi; этот плагин включается, только
-- когда yazi запустила обёртка портала (filepicker/yazi-wrapper.sh). Она
-- выставляет:
--   YAZI_PICK       open | multi | dir | save
--   YAZI_PICK_OUT   куда записать выбранные пути (этот файл читает портал)
--   YAZI_PICK_NAME  имя файла, которое предложило приложение (save)
--
-- Enter и l приходят сюда из doc-open:
--   save  Enter — сохранить в папку, где стоишь (неважно, что под курсором);
--         имя занято — 1 заменить / 2 другое имя / Esc отмена
--   dir   Enter — выбрать папку, где стоишь
--   open  Enter — файл выбрать, папку открыть; multi — то же для отмеченных
--   l     в папку (в save/dir на файле ничего не делает)
-- q (обычный выход) — отмена: портал не получает файла и ничего не делает.
-- setup() из init.lua рисует в шапке, что сейчас нужно и что жать.

local MODE = os.getenv("YAZI_PICK")
local OUT = os.getenv("YAZI_PICK_OUT")
local NAME = os.getenv("YAZI_PICK_NAME") or ""

local snapshot = ya.sync(function()
	local cur = cx.active.current
	local h = cur.hovered
	return {
		cwd = tostring(cur.cwd),
		hovered = h and tostring(h.url) or nil,
		is_dir = h and h.cha.is_dir or false,
	}
end)

local function say(content, level)
	ya.notify { title = "Файлпикер", content = content, timeout = 5, level = level or "info" }
end

local function finish(paths)
	if not OUT or OUT == "" then
		return say("yazi запущен не из файлпикера (нет YAZI_PICK_OUT)", "error")
	end
	local f, err = io.open(OUT, "w")
	if not f then
		return say("Не могу записать результат: " .. tostring(err), "error")
	end
	for _, p in ipairs(paths) do
		f:write(p, "\n")
	end
	f:close()
	ya.emit("quit", { ["no-cwd-file"] = true })
end

local function join(dir, name)
	if dir:sub(-1) == "/" then
		return dir .. name
	end
	return dir .. "/" .. name
end

-- «отчёт.pdf» -> «отчёт (1).pdf», первое свободное
local function free_name(dir, name)
	local stem, ext = name:match("^(.+)(%.[^.]+)$")
	if not stem then
		stem, ext = name, ""
	end
	for i = 1, 999 do
		local cand = string.format("%s (%d)%s", stem, i, ext)
		if not fs.cha(Url(join(dir, cand))) then
			return cand
		end
	end
	return name
end

local function ask_name(value)
	while true do
		local v, ev = ya.input {
			pos = { "center", w = 64 },
			title = "Сохранить под именем:",
			value = value,
		}
		if ev ~= 1 or not v then
			return nil
		end
		v = v:gsub("^%s+", ""):gsub("%s+$", "")
		if v == "" then
			return nil
		end
		if not v:find("/", 1, true) then
			return v
		end
		say("Только имя, без «/». В другую папку — перейди в неё и жми Enter.", "warn")
		value = v:gsub("/", "")
	end
end

-- сохранить в dir под именем name; если такое имя уже занято — спросить
local function save_into(dir, name)
	while true do
		local target = join(dir, name)
		local cha = fs.cha(Url(target))
		if not cha then
			return finish { target }
		end

		local choice = 2
		if cha.is_dir then
			say("«" .. name .. "» — это папка, нужно другое имя", "warn")
		else
			-- уведомление тут не показываем: оно ложится поверх меню
			choice = ya.which {
				cands = {
					{ on = "1", desc = "Заменить существующий «" .. name .. "»" },
					{ on = "2", desc = "Сохранить под другим именем" },
					{ on = "3", desc = "Отмена" },
				},
			}
		end

		if choice == 1 then
			return finish { target }
		elseif choice ~= 2 then
			return
		end
		name = ask_name(free_name(dir, name))
		if not name then
			return
		end
	end
end

local function enter(st)
	if MODE == "save" then
		return save_into(st.cwd, NAME ~= "" and NAME or "file")
	elseif MODE == "dir" then
		return finish { st.cwd }
	end
	if not st.hovered then
		return
	end
	if st.is_dir then
		return ya.emit("enter", {})
	end
	-- open/multi: встроенный open с --chooser-file пишет пути в файл портала
	-- и закрывает yazi (multi — все отмеченные пробелом)
	ya.emit("open", MODE == "open" and { hovered = true } or {})
end

local function nav(st)
	if not st.hovered then
		return
	end
	if st.is_dir then
		return ya.emit("enter", {})
	end
	if MODE == "open" or MODE == "multi" then
		return enter(st)
	end
end

local LABEL = {
	open = "ОТКРЫТЬ ФАЙЛ",
	multi = "ОТКРЫТЬ ФАЙЛЫ",
	dir = "ВЫБРАТЬ ПАПКУ",
	save = "СОХРАНИТЬ",
}

local KEYS = {
	open = { { "Enter", "выбрать" }, { "q", "отмена" } },
	multi = { { "Пробел", "отметить" }, { "Enter", "выбрать" }, { "q", "отмена" } },
	dir = { { "Enter", "выбрать эту папку" }, { "l h", "в папку / назад" }, { "q", "отмена" } },
	save = { { "Enter", "сохранить сюда" }, { "l h", "в папку / назад" }, { "q", "отмена" } },
}

local function setup()
	if not MODE then
		return
	end

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
end

return {
	setup = setup,
	entry = function(_, job)
		if not MODE then
			return
		end
		local st = snapshot()
		if job.args[1] == "nav" then
			nav(st)
		else
			enter(st)
		end
	end,
}
