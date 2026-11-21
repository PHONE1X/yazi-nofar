--- @since 25.5.31
-- Google Drive по требованию: rclone-mount поднимается, когда заходишь в
-- ~/Google Drive, и гасится, когда выходишь оттуда (юнит rclone-drive.service,
-- автозапуск выключен). Подстраховка — rclone-drive-idle.timer.
-- Общий для основного конфига и файлпикера: require("gdrive-mount"):setup()

local function setup()
	local GD = os.getenv("HOME") .. "/Google Drive"
	local up = false
	ps.sub("cd", function()
		local cwd = tostring(cx.active.current.cwd)
		local inside = cwd == GD or cwd:sub(1, #GD + 1) == GD .. "/"
		if inside and not up then
			up = true
			ya.async(function()
				Command("systemctl"):arg({ "--user", "start", "rclone-drive.service" }):status()
				ya.emit("reload", {})
			end)
		elseif not inside and up then
			up = false
			Command("systemctl"):arg({ "--user", "stop", "rclone-drive.service" }):spawn()
		end
	end)
end

return { setup = setup }
