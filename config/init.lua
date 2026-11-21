-- Какое приложение чем открывать (Enter / l), и в каком состоянии Yazi
-- стартует (режим клавиш, число панелей, скрытые файлы, сортировка).
-- Штатный [opener] в yazi.toml иногда теряет путь (nvim открывает
-- приветственный экран) — поэтому Enter/l открывают файлы через свой
-- plugins/doc-open.yazi, путь он подставляет сам. Список «чем что
-- открывать» — из plugins/openers.yazi (файл openers-data.lua).
-- Жми F в файловом менеджере:
-- страница Openers (a — добавить, e/Enter — изменить программу, d/x —
-- удалить) и страница Startup settings (Tab — переключить страницу,
-- h/l или Enter/Space — переключить значение). Руками файлы редактировать
-- не нужно. `editor` ниже — чем открывать всё, что не попало ни в одно
-- правило из окна Openers.
require("doc-open"):setup {
	editor = "nvim",
}

-- zip
require("relative-motions"):setup({ show_numbers="relative", show_motion = true, enter_mode ="first" })




-- чёто для миниатюр фото 
 require("allmytoes"):setup {
    -- By default, all sizes are generated. Remove the ones you don't need.
    sizes = {"n", "l", "x", "xx"},
}
require("full-border"):setup()


--tresh
require("recycle-bin"):setup({
  -- Optional: Override automatic trash directory discovery
  -- trash_dir = "~/.local/share/Trash/",  -- Uncomment to use specific directory
})

--zoxide
pcall(function() require("zoxide"):setup { update_db = true } end)

-- git status в списке файлов
require("git"):setup {
	order = 1500,
}

-- телефон через KDE Connect: просмотр (g p) и отправка (c s), свой модуль
-- вместо kdeconnect-send.yazi — умеет и то, и другое через kdeconnect-cli
require("kdeconnect"):setup {
	auto_select_single = true,
}

-- быстрый undo последнего удаления (u / U), напарник recycle-bin
require("restore"):setup {
	show_confirm = true,
	suppress_success_notification = false,
}


-- ===== PHASE 0 TEST ONLY =====
-- DISABLED (incompatible): require("dual-pane"):setup()

-- split-tabs: preload so the module (and its SPLIT_TABS global) exists before
-- anything else at startup; loading it lazily on the first `plugin split-tabs`
-- call costs a disk read and can land out of order.
require("split-tabs")

-- Apply the saved "start in dual-pane" preference (plugins/openers.yazi),
-- if any -- a no-op when it's "single" (the default).
ya.emit("plugin", { "openers", "boot" })


-- Google Drive по требованию: rclone-mount поднимается, когда заходишь в
-- ~/Google Drive, и гасится, когда выходишь оттуда (plugins/gdrive-mount.yazi).
require("gdrive-mount"):setup()

-- Файлпикер: тот же yazi, запущенный из окна «Открыть» / «Сохранить»
-- (filepicker/yazi-wrapper.sh ставит YAZI_PICK). В шапке — что нужно и что
-- жать; Enter/l в этом режиме обрабатывает plugins/picker.yazi.
if os.getenv("YAZI_PICK") then
	require("picker"):setup()
end
