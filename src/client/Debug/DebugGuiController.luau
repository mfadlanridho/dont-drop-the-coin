local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local DebugGuiView = require(script.Parent:WaitForChild("DebugGuiView"))

local DebugGuiController = {}

local localPlayer = Players.LocalPlayer

local GUI_TITLE = "Developer Debug"
local GUI_SUBTITLE = "Studio-only debug panel"
local TOGGLE_KEY_CODE = Enum.KeyCode.P
local RENDER_INTERVAL_SECONDS = 0.1
local SHOW_IN_STUDIO = true
local ALLOWED_USER_IDS = {}

local started = false
local enabled = false
local visible = true
local dirty = false
local renderAccumulator = 0
local nextPanelOrder = 1
local view = nil
local renderConnection = nil
local inputConnection = nil
local selectedPanelKey = nil
local panelsByKey = {}

local function isUserAllowed()
	if SHOW_IN_STUDIO and RunService:IsStudio() then
		return true
	end

	for _, userId in ipairs(ALLOWED_USER_IDS) do
		if localPlayer.UserId == userId then
			return true
		end
	end

	return false
end

local function markDirty()
	dirty = true
end

local function compareEntries(left, right)
	if left.order ~= right.order then
		return left.order < right.order
	end

	return left.displayName < right.displayName
end

local function getOrderedPanels()
	local orderedPanels = {}

	for panelKey, panel in pairs(panelsByKey) do
		table.insert(orderedPanels, {
			key = panelKey,
			displayName = panel.displayName,
			order = panel.order,
			selected = panelKey == selectedPanelKey,
		})
	end

	table.sort(orderedPanels, compareEntries)

	return orderedPanels
end

local function getSelectedPanel()
	if selectedPanelKey == nil then
		return nil
	end

	return panelsByKey[selectedPanelKey]
end

local function selectFallbackPanel()
	local orderedPanels = getOrderedPanels()
	if #orderedPanels == 0 then
		selectedPanelKey = nil
		return
	end

	selectedPanelKey = orderedPanels[1].key
end

local function getRowsForSelectedPanel()
	local panel = getSelectedPanel()
	if panel == nil then
		return nil
	end

	local rows = {}
	for rowKey, row in pairs(panel.rowsByKey) do
		table.insert(rows, {
			key = rowKey,
			displayName = row.displayName,
			value = row.value,
			order = row.order,
			rowType = row.rowType,
			callback = row.callback,
		})
	end

	table.sort(rows, compareEntries)

	return rows
end

local function renderNow()
	if not enabled or view == nil then
		dirty = false
		return
	end

	local orderedPanels = getOrderedPanels()
	local rows = getRowsForSelectedPanel()
	local placeholderText = nil

	if #orderedPanels == 0 then
		placeholderText = "No debug panels have been registered."
	elseif rows == nil or #rows == 0 then
		placeholderText = "This panel does not have any values yet."
	end

	view:render({
		visible = visible,
		title = GUI_TITLE,
		subtitle = GUI_SUBTITLE,
		hintText = string.format("%s to toggle", TOGGLE_KEY_CODE.Name),
		panels = orderedPanels,
		rows = rows or {},
		placeholderText = placeholderText,
	})

	dirty = false
end

local function ensurePanel(panelKey, displayName, order)
	local panel = panelsByKey[panelKey]
	if panel ~= nil then
		if displayName ~= nil and panel.displayName ~= displayName then
			panel.displayName = displayName
			markDirty()
		end

		if order ~= nil and panel.order ~= order then
			panel.order = order
			markDirty()
		end

		return panel
	end

	panel = {
		displayName = displayName or panelKey,
		order = order or nextPanelOrder,
		nextRowOrder = 1,
		rowsByKey = {},
	}
	panelsByKey[panelKey] = panel
	nextPanelOrder += 1

	if selectedPanelKey == nil then
		selectedPanelKey = panelKey
	end

	markDirty()

	return panel
end

function DebugGuiController.start()
	if started then
		print("[DebugGui] start skipped", enabled)
		return enabled
	end

	started = true
	enabled = isUserAllowed()
	print("[DebugGui] start", enabled, "studio=", RunService:IsStudio(), "userId=", localPlayer.UserId)

	if not enabled then
		print("[DebugGui] disabled")
		return false
	end

	view = DebugGuiView.new(localPlayer:WaitForChild("PlayerGui"))
	print("[DebugGui] view created")
	view:setPanelSelectedCallback(function(panelKey)
		DebugGuiController.selectPanel(panelKey)
	end)

	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == TOGGLE_KEY_CODE then
			DebugGuiController.toggle()
		end
	end)

	renderConnection = RunService.Heartbeat:Connect(function(deltaTime)
		renderAccumulator += deltaTime
		if not dirty or renderAccumulator < RENDER_INTERVAL_SECONDS then
			return
		end

		renderAccumulator = 0
		renderNow()
	end)

	markDirty()
	renderNow()
	print("[DebugGui] initial render complete")

	return true
end

function DebugGuiController.isEnabled()
	return enabled
end

function DebugGuiController.addPanel(panelKey, displayName, order)
	print("[DebugGui] addPanel", panelKey, displayName, order)
	ensurePanel(panelKey, displayName, order)
end

function DebugGuiController.removePanel(panelKey)
	if panelsByKey[panelKey] == nil then
		return
	end

	panelsByKey[panelKey] = nil
	if selectedPanelKey == panelKey then
		selectFallbackPanel()
	end

	markDirty()
end

function DebugGuiController.selectPanel(panelKey)
	if panelsByKey[panelKey] == nil or selectedPanelKey == panelKey then
		return
	end

	selectedPanelKey = panelKey
	markDirty()
end

function DebugGuiController.setValue(panelKey, rowKey, value, panelDisplayName, panelOrder, rowDisplayName, rowOrder)
	local panel = ensurePanel(panelKey, panelDisplayName, panelOrder)
	local normalizedValue = if value == nil then "nil" else tostring(value)
	local normalizedRowDisplayName = rowDisplayName or rowKey
	local row = panel.rowsByKey[rowKey]

	if row == nil then
		print("[DebugGui] setValue new", panelKey, rowKey, normalizedValue)
		row = {
			displayName = normalizedRowDisplayName,
			order = rowOrder or panel.nextRowOrder,
			value = normalizedValue,
		}
		panel.rowsByKey[rowKey] = row
		panel.nextRowOrder += 1
		markDirty()
		return
	end

	local changed = false

	if row.value ~= normalizedValue then
		row.value = normalizedValue
		changed = true
	end

	if row.displayName ~= normalizedRowDisplayName then
		row.displayName = normalizedRowDisplayName
		changed = true
	end

	if rowOrder ~= nil and row.order ~= rowOrder then
		row.order = rowOrder
		changed = true
	end

	if changed then
		markDirty()
	end
end

function DebugGuiController.setToggleRow(panelKey, rowKey, displayName, value, callback, panelDisplayName, panelOrder, rowOrder)
	local panel = ensurePanel(panelKey, panelDisplayName, panelOrder)
	local row = panel.rowsByKey[rowKey]

	if row == nil then
		row = {
			displayName = displayName or rowKey,
			order = rowOrder or panel.nextRowOrder,
			value = value,
			rowType = "toggle",
			callback = callback,
		}
		panel.rowsByKey[rowKey] = row
		panel.nextRowOrder += 1
		markDirty()
		return
	end

	local changed = false
	if row.value ~= value then row.value = value; changed = true end
	if row.callback ~= callback then row.callback = callback; changed = true end
	if row.displayName ~= displayName then row.displayName = displayName; changed = true end
	if changed then markDirty() end
end

function DebugGuiController.setInputRow(panelKey, rowKey, displayName, value, callback, panelDisplayName, panelOrder, rowOrder)
	local panel = ensurePanel(panelKey, panelDisplayName, panelOrder)
	local row = panel.rowsByKey[rowKey]

	if row == nil then
		row = {
			displayName = displayName or rowKey,
			order = rowOrder or panel.nextRowOrder,
			value = value,
			rowType = "input",
			callback = callback,
		}
		panel.rowsByKey[rowKey] = row
		panel.nextRowOrder += 1
		markDirty()
		return
	end

	local changed = false
	if row.value ~= value then row.value = value; changed = true end
	if row.callback ~= callback then row.callback = callback; changed = true end
	if row.displayName ~= displayName then row.displayName = displayName; changed = true end
	if changed then markDirty() end
end

function DebugGuiController.setButtonRow(panelKey, rowKey, displayName, buttonText, callback, panelDisplayName, panelOrder, rowOrder)
	local panel = ensurePanel(panelKey, panelDisplayName, panelOrder)
	local row = panel.rowsByKey[rowKey]

	if row == nil then
		row = {
			displayName = displayName or rowKey,
			order = rowOrder or panel.nextRowOrder,
			value = buttonText or "RUN",
			rowType = "button",
			callback = callback,
		}
		panel.rowsByKey[rowKey] = row
		panel.nextRowOrder += 1
		markDirty()
		return
	end

	local changed = false
	if row.value ~= buttonText then row.value = buttonText; changed = true end
	if row.callback ~= callback then row.callback = callback; changed = true end
	if row.displayName ~= displayName then row.displayName = displayName; changed = true end
	if changed then markDirty() end
end

function DebugGuiController.removeValue(panelKey, rowKey)
	local panel = panelsByKey[panelKey]
	if panel == nil or panel.rowsByKey[rowKey] == nil then
		return
	end

	panel.rowsByKey[rowKey] = nil
	markDirty()
end

function DebugGuiController.setVisible(nextVisible)
	if visible == nextVisible then
		return
	end

	visible = nextVisible
	markDirty()
	renderNow()
end

function DebugGuiController.toggle()
	DebugGuiController.setVisible(not visible)
end

function DebugGuiController.destroy()
	if inputConnection ~= nil then
		inputConnection:Disconnect()
		inputConnection = nil
	end

	if renderConnection ~= nil then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if view ~= nil then
		view:destroy()
		view = nil
	end

	table.clear(panelsByKey)
	selectedPanelKey = nil
	started = false
	enabled = false
	visible = true
	dirty = false
	renderAccumulator = 0
	nextPanelOrder = 1
end

return DebugGuiController
