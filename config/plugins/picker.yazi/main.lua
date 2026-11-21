--- @since 25.5.31
-- Yazi в роли файлпикера: что делают Enter и s. Режим и куда писать
-- результат выставляет обёртка портала (filepicker/yazi-wrapper.sh):
--   YAZI_PICK       open | multi | dir | save
--   YAZI_PICK_OUT   файл с выбранными путями (его читает портал)
--   YAZI_PICK_NAME  имя файла, предложенное приложением (режим save)
-- Выход без записи в YAZI_PICK_OUT (q) — отмена.

local MODE = os.getenv("YAZI_PICK") or "open"
local OUT = os.getenv("YAZI_PICK_OUT")
local NAME = os.getenv("YAZI_PICK_NAME") or ""

local snapshot = ya.sync(function()
	local cur = cx.active.current
	local h = cur.hovered
	return {
		cwd = tostring(cur.cwd),
		hovered = h and tostring(h.url) or nil,
		name = h and h.name or nil,
		is_dir = h and h.cha.is_dir or false,
	}
end)

local function say(content, level)
	ya.notify { title = "Файлпикер", content = content, timeout = 4, level = level or "info" }
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

local function ask_overwrite(name)
	return ya.confirm {
		pos = { "center", w = 64, h = 7 },
		title = "Такой файл уже есть",
		body = "Заменить «" .. name .. "»? Старое содержимое пропадёт.",
	}
end

local function save_here(st)
	local value, event = ya.input {
		pos = { "center", w = 64 },
		title = "Сохранить в этой папке как:",
		value = NAME,
	}
	if event ~= 1 or not value then
		return
	end
	value = value:gsub("^%s+", ""):gsub("%s+$", "")
	if value == "" then
		return
	end
	if value:find("/", 1, true) then
		return say("Только имя файла, без «/». Папку выбирают переходом в неё.", "warn")
	end
	local target = join(st.cwd, value)
	local cha = fs.cha(Url(target))
	if cha then
		if cha.is_dir then
			return say("«" .. value .. "» — это папка, нужно имя файла", "warn")
		end
		if not ask_overwrite(value) then
			return
		end
	end
	finish { target }
end

local function enter(st)
	if not st.hovered then
		return
	end
	if st.is_dir then
		return ya.emit("enter", {})
	end
	if MODE == "open" then
		-- встроенный open с --chooser-file пишет путь в файл портала и закрывает yazi
		ya.emit("open", { hovered = true })
	elseif MODE == "multi" then
		ya.emit("open", {})
	elseif MODE == "dir" then
		say("Нужна папка: зайдите в неё и нажмите s")
	elseif MODE == "save" then
		if ask_overwrite(st.name) then
			finish { st.hovered }
		end
	end
end

local function here(st)
	if MODE == "dir" then
		finish { st.cwd }
	elseif MODE == "save" then
		save_here(st)
	else
		enter(st)
	end
end

return {
	entry = function(_, job)
		local st = snapshot()
		if job.args[1] == "here" then
			here(st)
		else
			enter(st)
		end
	end,
}
