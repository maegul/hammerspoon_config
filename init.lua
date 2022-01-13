-- > Constants

local hyper = {"ctrl", "alt", "cmd"}
local superhyper = {"control", "alt", "command", "shift"}
local subl_cli = "/Applications/Sublime Text 4.app/Contents/SharedSupport/bin/subl"
local subl_app_name = "Sublime Text 4"

-- >> backup paths
local phd_backup_since_script_path = '/Users/errollloyd/bin/backup_since'
local dev_backup_since_script_path = '~/bin/bin_links/python /Users/errollloyd/bin/dev_backup_since.py'


-- > Load Spoons
-- hs.loadSpoon("MiroWindowsManager")
hs.loadSpoon("RecursiveBinder")
hs.loadSpoon("WindowHalfsAndThirds")
hs.loadSpoon("WindowScreenLeftAndRight")


-- > Utility Functions

-- >> copy
-- Function to wait until copy is performed before executing callback
-- copyKeyStroke allows key stroke as table to be controlled: {{MODIFER}, KEY}
-- can also pass a whole copyFunc as a discrete function if necessary
local function withCopiedValue(callbackFn, copyKeyStroke, copyFn)
	local initialCount = hs.pasteboard.changeCount()

	-- fire the copy command
	if (not copyFn) then
		local copyKeyStroke = copyKeyStroke or {{"cmd"}, "c"}
		hs.eventtap.keyStroke(copyKeyStroke[1], copyKeyStroke[2], 0)
		-- hs.eventtap.keyStroke({"cmd", "alt"}, "c", 0)
	else
		copyFn()
	end

	local clipboardHasUpdated = function()
		return initialCount ~= hs.pasteboard.changeCount()
	end

	-- how often should we check for the clipboard to have updated?
	local waitInterval = 10 / 1000 -- every 10ms

	local copyTimer = hs.timer.waitUntil(
		clipboardHasUpdated,
		function()
		  -- once the clipboard is updated, get the value and call your
		  -- callbackFn with it.
		  local clipboardValue = hs.pasteboard.getContents()
		  callbackFn(clipboardValue)
		end,
		waitInterval
	)

	-- Kill waitUntil if nothing after 0.5 seconds
	hs.timer.doAfter(0.5, function()
		copyTimer:stop()
	end)
end


-- >> Get backup since times

function get_phd_backup_time_since(raw_time)
	if raw_time then
		time_since = hs.execute(phd_backup_since_script_path)
	else
		time_since = math.floor(
			hs.execute(phd_backup_since_script_path)
			)
	end

	return time_since
end

function get_dev_backup_time_since(raw_time)
	if raw_time then
		time_since = hs.execute(dev_backup_since_script_path)
	else
		time_since = math.floor(
			hs.execute(dev_backup_since_script_path)
			)
	end

	return time_since
end

-- >> Zotero (proto)

function zotero_bbt_cayw(format)
	local citation_format = format or 'cite'
	local current_app = hs.application.frontmostApplication()
	local url = 'http://127.0.0.1:23119/better-bibtex/cayw?format=' .. citation_format
	status, resp, head = hs.http.get(url, {nil})
	-- print(status, resp)

	if status == 200 then
		hs.pasteboard.setContents(resp)
	else
		hs.alert("Zotero CAYW Failed (status code:" .. status)
	end

	-- zotero takes focus, focus back on initial app
	current_app:activate()
end
-- >> Update Menu Bar function constructor

-- returns function with provided menubar item as enclosed variable
function mkBackupMenuBarFunction(menubarItem)
	return function()
		-- Adding date and time for testing / prototyping
		-- PRESUMES menubar item variable name is backup_mb
		menubarItem:setTitle(get_phd_backup_time_since() .. "|" .. get_dev_backup_time_since() .. "(" .. os.date('%H %a') .. ")")
	end
end

-- >> Menu Bar onclick callback

-- generates function, taking the title update function as an enclosing variable
function mkBackupMenuBarMenuFunction(menubarItem_update_fn)
	return function()
		menubarItem_update_fn()  -- update title of menubar
		-- return menu table
		return {
			{title = "Phd: " .. get_phd_backup_time_since(true) .. " days"},
			{title = "Dev: " .. get_dev_backup_time_since(true) .. " days"}
		}
	end
end


-- > Backup Since Menubar

backup_mb = hs.menubar.new()
-- create callbacks
backup_mb_update = mkBackupMenuBarFunction(backup_mb)
backup_mb_menu = mkBackupMenuBarMenuFunction(backup_mb_update)
-- init menubar
backup_mb_update()
-- Set menu callback
backup_mb:setMenu(backup_mb_menu)
-- backup_mb:setTitle(get_phd_backup_time_since() .. "|" .. get_dev_backup_time_since())

-- >> Timers
backup_time_1 = hs.timer.doAt(
	'09:15', '1d', backup_mb_update)
backup_timer_2 = hs.timer.doAt(
	'18:15', '1d', backup_mb_update)


-- > Window Paramaters

hs.window.animationDuration = 0

hs.grid.ui.textSize = 60;

-- > Key Bindings

hs.hotkey.bind({"cmd","alt", "ctrl", "shift"}, "i", function()
	hs.alert("💖 LOVE YA 💖")
end)

-- hs.hotkey.bind(superhyper, 'n', function()
-- 	withCopiedValue(
-- 		function(filePath)
-- 			print(filePath)
-- 		end,
-- 		{{"cmd", "alt"}, "c"}
-- 	)
-- end
-- )

-- must use full modifier names for some reason, eg "command"
spoon.RecursiveBinder.showBindHelper = false

recursiveKeyBindings = {
	[{{}, 'h', '|- '}] = function()
		spoon.WindowHalfsAndThirds:leftHalf()
	end,
	[{{}, 'l', ' -|'}] = function()
		spoon.WindowHalfsAndThirds:rightHalf()
	end,
	[{{}, 'y', '|--'}] = function()
		spoon.WindowHalfsAndThirds:leftThird()
	end,
	[{{}, 'o', '--|'}] = function()
		spoon.WindowHalfsAndThirds:rightThird()
	end,
	[{{'shift'}, 'y', '|. '}] = function()
		spoon.WindowHalfsAndThirds:leftTwoThird()
	end,
	[{{'shift'}, 'o', ' .|'}] = function()
		spoon.WindowHalfsAndThirds:rightTwoThird()
	end,
	[{{}, 'j', ' V '}] = function()
		spoon.WindowHalfsAndThirds:bottomHalf()
	end,
	[{{}, 'k', ' ∆ '}] = function()
		spoon.WindowHalfsAndThirds:topHalf()
	end,
	[{{}, 'u', ' ↖ ︎'}] = function()
		spoon.WindowHalfsAndThirds:topLeft()
	end,
	[{{}, 'i', ' ↗ ︎'}] = function()
		spoon.WindowHalfsAndThirds:topRight()
	end,
	[{{}, 'n', ' ↙ ︎'}] = function()
		spoon.WindowHalfsAndThirds:bottomLeft()
	end,
	[{{}, 'm', ' ↘ ︎'}] = function()
		spoon.WindowHalfsAndThirds:bottomRight()
	end,
	[{{}, 'c', '-|-'}] = function()
		spoon.WindowHalfsAndThirds:center()
	end,
	[{{}, 'f', ' ⚀ '}] = function()
		spoon.WindowHalfsAndThirds:maximize()
	end,
	[{{}, ';', 'tmx'}] = function()
		spoon.WindowHalfsAndThirds:toggleMaximized()
	end,
	[{{}, 'left', '⚀← '}] = function()
		spoon.WindowScreenLeftAndRight:oneScreenLeft()
	end,
	[{{}, 'right', ' →⚀'}] = function()
		spoon.WindowScreenLeftAndRight:oneScreenRight()
	end,
	[{{}, 's', 'sbl'}] = function()
		hs.application.launchOrFocus(subl_app_name)
		local app = hs.application.frontmostApplication()

		hs.timer.doAfter(0.1, function()
			local wins = app:focusedWindow()
			if not wins then
				hs.eventtap.keyStroke({"cmd", "shift"}, "n", 0)
				-- app:selectMenuItem({
				-- 	"File", "New Window"
				-- })
			end
		end)
	end,
	[{{}, 't', 'trm'}] = function()
		hs.application.launchOrFocus('Terminal')
		local app = hs.application.frontmostApplication()
		-- The above creates a new window when there are none at all?

		hs.timer.doAfter(0.1, function()
			local wins = app:focusedWindow()
			if (not wins) then
				hs.eventtap.keyStroke({"cmd"}, "n", 0)
			end
		end)
	end,
	[{{}, 'w', 'web'}] = function()
		hs.application.launchOrFocus('Safari')
		local app = hs.application.frontmostApplication()
		local wins = app:focusedWindow()

		if (not wins) then
			hs.eventtap.keyStroke({"cmd"}, 'n', 0)
			-- app:selectMenuItem({
			-- 	"Shell", "New Window", "errolDark"
			-- })
		end
	end,
	[{{}, 'e', 'fil'}] = function()
		hs.application.launchOrFocus('Finder')
		local app = hs.application.frontmostApplication()
		local wins = app:focusedWindow()

		if (not wins) then
			hs.eventtap.keyStroke({"cmd"}, 'n', 0)
			-- app:selectMenuItem({
			-- 	"Shell", "New Window", "errolDark"
			-- })
		end
	end,
	[{{}, 'r', 'fil'}] = function()
		hs.application.launchOrFocus('Notes')
		local app = hs.application.frontmostApplication()
		local wins = app:focusedWindow()

		if (not wins) then
			hs.eventtap.keyStroke({"cmd"}, 'n', 0)
		end
	end,
	[{{}, 'p', 'sks'}] = function()
		hs.application.launchOrFocus('Stickies')
		local app = hs.application.frontmostApplication()
		-- local wins = app:focusedWindow()
		-- always create a new post it for stickies (?)
		hs.eventtap.keyStroke({"cmd"}, 'n', 0)
	end,
	[{{'shift'}, 's', 'osb'}] = function()
		local app = hs.application.frontmostApplication()
		-- print(app:title())
		if (app:title() == 'Finder') then
			withCopiedValue(function(filePath)
				hs.task.new(
					-- A full path is required, don't know how to get around
					subl_cli,
					function(c, o, e) end,
					{'-n', filePath}
				):start()
				end,
				{{"cmd", "alt"}, "c"} -- copy command for getting path from finder
			)
		end
	end,
	[{{'option'}, 's', 'asb'}] = function() -- add to an existing window instead
		local app = hs.application.frontmostApplication()
		-- print(app:title())
		if (app:title() == 'Finder') then
			withCopiedValue(function(filePath)
				hs.task.new(
					subl_cli,
					function(c, o, e) end,
					{'-a', filePath}
				):start()
				end,
				{{"cmd", "alt"}, "c"} -- copy command for getting path from finder
			)
		end
	end,
	[{{}, 'a', 'mic'}] = function() -- Toggle Audio unmuted of zoom conf call
		zoom_app = hs.application.get('zoom.us')  -- Need to be precise with app name (?)
		-- Could extend to move through a list of predefined apps
		-- Check whether running, and if so, mute with appropriate menu item or keybinding
		if (zoom_app:isRunning() == true) then
			-- Item is either "Unmute Audio" or "Mute Audio"
			zoom_app:selectMenuItem('Unmute Audio', true)
		end
	end,
	[{{}, 'q', 'mut'}] = function() -- Toggle Audio unmuted of zoom conf call
		zoom_app = hs.application.get('zoom.us')  -- Need to be precise with app name (?)
		-- Could extend to move through a list of predefined apps
		-- Check whether running, and if so, mute with appropriate menu item or keybinding
		if (zoom_app:isRunning() == true) then
			-- Item is either "Unmute Audio" or "Mute Audio"
			zoom_app:selectMenuItem('Mute Audio', true)
		end
	end,
	[{{}, 'z', 'cite'}] = {
		[{{}, 'c', 'inline'}] = function() zotero_bbt_cayw('cite') end,
		[{{}, 'p', 'parens'}] = function() zotero_bbt_cayw('citep') end,
		[{{}, 'b', 'full'}] = function() zotero_bbt_cayw('formatted-bibliography') end,
	}
	-- [{{}, 'z', '???'}] = function()
	-- 	print('dump key info inner')
	-- 	message_string = ""
	-- 	for k, v in pairs(recursiveKeyBindings) do
	-- 		-- print(k[2], k[3])
	-- 		message_string = message_string .. k[2] .. '\t\t\t' .. k[3] .. '\n'
	-- 		-- for k1,v1 in pairs(k) do
	-- 		-- 	print(k1)
	-- 		-- end
	-- 	end
	-- 	-- print(message_string)
	-- 	hs.alert.show(message_string, 'infty')
	-- 	-- use hs.hotkey.modal for modal escape
	-- 	control = hs.hotkey.new('ctrl', 'z', function()
	-- 		print('close keybind help')
	-- 		hs.alert.closeAll()
	-- 		control:delete()
	-- 	end)
	-- 	control:enable()
	-- end
}

hs.hotkey.bind(superhyper, 'k', spoon.RecursiveBinder.recursiveBind(recursiveKeyBindings)
)

