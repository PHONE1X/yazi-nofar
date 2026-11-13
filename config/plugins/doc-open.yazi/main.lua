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
	{ ext = { "mp3", "flac", "wav", "ogg", "m4a", "opus" }, cmd = "mpv" },
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

local function entry(self)
	local h = cx.active.current.hovered
	if not h then return end

	if h.cha.is_dir then
		ya.emit("enter", { hovered = not self.open_multi })
		return
	end

	local ext = h.name:match("%.([^.]+)$")
	ext = ext and ext:lower() or ""
	local path = tostring(h.url)
	local rule = build_lookup(load_data_file(data_path()) or DEFAULT_OPENERS)[ext]

	if rule then
		local args = {}
		for _, a in ipairs(rule.args or {}) do args[#args + 1] = a end
		args[#args + 1] = path
		local _, err = Command(rule.cmd):arg(args):spawn()
		if err then fail(rule.cmd, err) end
	else
		-- всё, для чего нет правила, считаем текстом и отдаём редактору;
		-- TUI-редактору нужен терминал yazi, поэтому через shell --block
		local editor = self.editor or "nvim"
		ya.emit("shell", { editor .. " " .. ya.quote(path), block = true })
	end
end

return { entry = entry, setup = setup }
