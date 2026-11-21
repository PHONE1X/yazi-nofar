--- @since 25.5.31
--- @sync entry

-- Открытие файла по Enter/l (и Enter/Right в far-режиме).
-- Обходит штатный [opener]/[open] yazi: он иногда теряет путь, и тогда
-- nvim (AstroNvim) показывает приветственный экран вместо документа.
-- Здесь путь подставляется прямо в команду через ya.quote().
-- Список «чем открывать что» — тот же файл openers-data.lua, который
-- правит попап F -> Openers (plugins/openers.yazi).

local DEFAULT_OPENERS = {
	{ ext = { "jpg", "jpeg", "png", "gif", "bmp", "webp", "svg", "ico", "tiff", "tif", "heic", "avif" }, cmd = "gwenview" },
	{ ext = { "mp4", "mkv", "webm", "avi", "mov", "flv", "wmv", "m4v" }, cmd = "haruna" },
	-- без pseudo-gui mpv, запущенный не из терминала, играет звук без окна,
	-- и его нечем остановить
	{ ext = { "mp3", "flac", "wav", "ogg", "m4a", "opus" }, cmd = "mpv", args = { "--player-operation-mode=pseudo-gui" } },
	{ ext = { "pdf" }, cmd = "okular" },
	{ ext = { "doc", "docx", "odt" }, cmd = "libreoffice", args = { "--writer" } },
	{ ext = { "xls", "xlsx", "ods" }, cmd = "libreoffice", args = { "--calc" } },
	{ ext = { "ppt", "pptx", "odp" }, cmd = "libreoffice", args = { "--impress" } },
	{ ext = { "zip", "tar", "gz", "bz2", "7z", "rar", "xz", "zst", "jar" }, cmd = "ouch", args = { "decompress" } },
	{ ext = { "exe", "msi", "bat", "lnk" }, cmd = "portproton" },
}

local function config_dir()
	return os.getenv("YAZI_CONFIG_HOME") or (os.getenv("HOME") .. "/.config/yazi")
end

local function data_path()
	return config_dir() .. "/openers-data.lua"
end

local function read_file(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local content = f:read("*a")
	f:close()
	return content
end

local function load_data_file(path)
	local content = read_file(path)
	if not content then return nil end
	local chunk = load(content, "@" .. path)
	if not chunk then return nil end
	local ok, result = pcall(chunk)
	if ok and type(result) == "table" then return result end
	return nil
end

local function build_lookup(openers)
	local map = {}
	for _, rule in ipairs(openers) do
		for _, ext in ipairs(rule.ext) do
			map[ext:lower()] = rule
		end
	end
	return map
end

local function fail(cmd, err)
	ya.notify({ title = "Open", content = string.format("Failed to launch %s: %s", cmd, tostring(err)), level = "error", timeout = 5 })
end

local function setup(self, opts)
	opts = opts or {}
	self.open_multi = opts.open_multi
	self.editor = opts.editor or "nvim"
end

-- Расширения, которые открываем редактором. Всё, чего нет ни здесь, ни в
-- списке опенеров (F), уходит системным ассоциациям (xdg-open), а не в nvim:
-- иначе .torrent/.iso и прочее открывались как текст.
local TEXT_EXT = {}
for _, e in ipairs {
	"txt", "md", "markdown", "rst", "log", "conf", "cfg", "ini", "toml", "yaml", "yml",
	"json", "jsonc", "xml", "csv", "tsv", "lua", "py", "sh", "bash", "zsh", "fish",
	"c", "h", "cc", "cpp", "hpp", "rs", "go", "js", "ts", "jsx", "tsx", "css", "scss",
	"html", "htm", "php", "java", "kt", "rb", "pl", "sql", "service", "desktop", "env",
	"diff", "patch", "tex", "org", "nix", "vim", "el", "ex", "srt", "ass", "vtt",
} do TEXT_EXT[e] = true end

local function entry(self, job)
	-- yazi открыт как файлпикер (окно «Открыть» / «Сохранить» из приложения):
	-- Enter и l решает plugins/picker.yazi (ему нужен async — там вопросы).
	if os.getenv("YAZI_PICK") then
		local action = job and job.args and job.args[1] or "enter"
		ya.emit("plugin", { "picker", action })
		return
	end

	local h = cx.active.current.hovered
	if not h then return end

	if h.cha.is_dir then
		ya.emit("enter", { hovered = not self.open_multi })
		return
	end

	local ext = h.name:match("%.([^.]+)$")
	ext = ext and ext:lower() or ""
	-- именно tostring(Url): .path отдаёт userdata, и Command:arg() на нём падает
	local path = tostring(h.url)
	local rule = build_lookup(load_data_file(data_path()) or DEFAULT_OPENERS)[ext]
	local args = {}
	if rule then
		for _, a in ipairs(rule.args or {}) do args[#args + 1] = a end
		args[#args + 1] = path
		local _, err = Command(rule.cmd):arg(args):spawn()
		if err then fail(rule.cmd, err) end
	elseif TEXT_EXT[ext] then
		-- текстовые файлы — в редактор (TUI-редактору нужен терминал yazi,
		-- поэтому через shell --block)
		local editor = self.editor or "nvim"
		ya.emit("shell", { editor .. " " .. ya.quote(path), block = true })
	else
		-- всё остальное (torrent, iso, deb и т.п.) — системным ассоциациям.
		-- Встроенный open звать нельзя: на этой машине он теряет путь и запускает
		-- xdg-open без аргументов, поэтому зовём xdg-open сами, с путём.
		local _, err = Command("xdg-open"):arg({ path }):spawn()
		if err then fail("xdg-open", err) end
	end
end

return { entry = entry, setup = setup }
