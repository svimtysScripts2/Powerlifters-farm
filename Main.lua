local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Vim = game:GetService("VirtualInputManager")
local workspace = game:GetService("Workspace")

local state = {
    recording = false,
    macroPlaying = false,
    autoCleaning = false,
    cleaning = false,
    running = false,
    recordedActions = {},
    recordStart = nil,
    endDelay = 0,
    lastGUI = nil,
}

local config = {
    puddleNames = {
        "puddle",
        "water",
        "mud",
        "pool",
    },
    trashNames = {
        "trash",
        "random trash",
        "garbage",
        "waste",
        "clean",
        "junk",
    },
    blacklist = {
        "bench",
        "press",
        "curl",
        "rack",
        "seat",
        "weight",
        "barbell",
        "dumbbell",
        "machine",
        "equipment",
        "use",
        "lift",
        "deadlift",
        "overhead",
        "squat",
        "rep",
    },
}

local function clampText(text)
    return text and tostring(text) or ""
end

local function toLower(str)
    return string.lower(clampText(str))
end

local function isBlacklisted(str)
    local s = toLower(str)
    for _, word in ipairs(config.blacklist) do
        if s:find(word, 1, true) then
            return true
        end
    end
    return false
end

local function makeGui()
    if playerGui:FindFirstChild("PowerliftersFarmGui") then
        playerGui.PowerliftersFarmGui:Destroy()
    end

    local ui = Instance.new("ScreenGui")
    ui.Name = "PowerliftersFarmGui"
    ui.ResetOnSpawn = false
    ui.IgnoreGuiInset = true
    ui.Parent = playerGui

    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Parent = ui
    main.Size = UDim2.new(0, 270, 0, 300)
    main.Position = UDim2.new(0.5, -135, 0.12, 0)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    main.BorderSizePixel = 0
    main.Active = true
    main.ClipsDescendants = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", main)
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 90, 90)

    local title = Instance.new("TextLabel")
    title.Parent = main
    title.Size = UDim2.new(1, -20, 0, 36)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "Powerlifters Farm"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left

    local status = Instance.new("TextLabel")
    status.Parent = main
    status.Size = UDim2.new(1, -20, 0, 26)
    status.Position = UDim2.new(0, 10, 0, 266)
    status.BackgroundTransparency = 1
    status.Text = "Status: Idle"
    status.TextColor3 = Color3.fromRGB(230, 230, 230)
    status.Font = Enum.Font.SourceSans
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Left
    state.status = status

    local layout = Instance.new("UIListLayout")
    layout.Parent = main
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local function addButton(text, yPos)
        local btn = Instance.new("TextButton")
        btn.Parent = main
        btn.Size = UDim2.new(1, -20, 0, 40)
        btn.Position = UDim2.new(0, 10, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 15
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        return btn
    end

    local buttons = {}
    buttons.record = addButton("REC", 50)
    buttons.stopRecord = addButton("STOP REC", 50)
    buttons.play = addButton("PLAY", 98)
    buttons.stopPlay = addButton("STOP", 98)
    buttons.teleportTrash = addButton("TP TRASH", 146)
    buttons.teleportPuddle = addButton("TP PUDDLE", 146)
    buttons.clean = addButton("AUTO CLEAN", 194)
    buttons.stopClean = addButton("STOP CLEAN", 194)

    local drag = false
    local dragStart, startPos
    local inputConn

    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = true
            dragStart = input.Position
            startPos = main.Position

            local movedConn
            local endedConn

            movedConn = UserInputService.InputChanged:Connect(function(move)
                if drag and (move.UserInputType == Enum.UserInputType.MouseMovement or move.UserInputType == Enum.UserInputType.Touch) then
                    local delta = move.Position - dragStart
                    main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)

            endedConn = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                    drag = false
                    if movedConn then movedConn:Disconnect() end
                    if endedConn then endedConn:Disconnect() end
                end
            end)
        end
    end)

    return ui, main, status, buttons
end

local function setStatus(text)
    if state.status then
        state.status.Text = "Status: " .. text
    end
end

local function getRoot()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local function getTargetPart(target)
    if not target then return nil end
    if target:IsA("BasePart") then return target end
    if target:IsA("Model") and target.PrimaryPart then return target.PrimaryPart end
    return target:FindFirstChildWhichIsA("BasePart", true)
end

local function clickOnScreenPosition(x, y)
    local guiOffset = GuiService:GetGuiInset()
    local realY = y + guiOffset.Y
    Vim:SendMouseButtonEvent(x, realY, 0, true, game, 0)
    task.wait(0.04)
    Vim:SendMouseButtonEvent(x, realY, 0, false, game, 0)
end

local function clickObjectByName(nameFragment)
    local lowerName = toLower(nameFragment)
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "PowerliftersFarmGui" then
            for _, obj in ipairs(gui:GetDescendants()) do
                if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
                    local text = toLower(obj.Text)
                    local objName = toLower(obj.Name)
                    if objName:find(lowerName, 1, true) or text:find(lowerName, 1, true) then
                        local pos = obj.AbsolutePosition
                        local size = obj.AbsoluteSize
                        local x = pos.X + size.X / 2
                        local y = pos.Y + size.Y / 2
                        clickOnScreenPosition(x, y)
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function findNearestByTerms(terms, maxDistance)
    local root = getRoot()
    if not root then return nil end

    local nearest = nil
    local best = maxDistance or 300

    for _, obj in ipairs(workspace:GetDescendants()) do
        local name = obj.Name
        if (obj:IsA("BasePart") or obj:IsA("Model")) and not isBlacklisted(name) then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                local actionText = toLower(prompt.ActionText)
                local objectText = toLower(prompt.ObjectText)
                local text = actionText .. " " .. objectText .. " " .. toLower(name)
                local matched = false

                for _, term in ipairs(terms) do
                    local lowerTerm = toLower(term)
                    if text:find(lowerTerm, 1, true) then
                        matched = true
                        break
                    end
                end

                if matched then
                    local part = getTargetPart(obj)
                    if part then
                        local dist = (root.Position - part.Position).Magnitude
                        if dist < best then
                            best = dist
                            nearest = obj
                        end
                    end
                end
            end
        end
    end

    return nearest
end

local function teleportTo(target)
    local root = getRoot()
    if not root or not target then return false end

    local part = getTargetPart(target)
    if not part then return false end

    root.CFrame = CFrame.new(part.Position + Vector3.new(0, 4, 0))
    return true
end

local function setPositionFromRecordedAction(act)
    if act.type == "tap" and act.pos then
        local x = act.pos.X
        local y = act.pos.Y
        clickOnScreenPosition(x, y)
    elseif act.type == "key" and act.keyCode then
        Vim:SendKeyEvent(true, act.keyCode, false, game)
        task.wait(0.05)
        Vim:SendKeyEvent(false, act.keyCode, false, game)
    end
end

local function playMacro()
    if state.macroPlaying then return end
    state.macroPlaying = true
    setStatus("Playing Macro")

    task.spawn(function()
        local guiOffset = GuiService:GetGuiInset()
        while state.macroPlaying do
            if #state.recordedActions > 0 then
                for idx, act in ipairs(state.recordedActions) do
                    if not state.macroPlaying then break end

                    local waitTime = tonumber(act.delay) or 0
                    if waitTime > 0 then
                        setStatus(string.format("Waiting %.2fs", waitTime))
                        task.wait(waitTime)
                    end

                    if not state.macroPlaying then break end

                    setStatus("Executing " .. idx .. "/" .. #state.recordedActions)
                    setPositionFromRecordedAction(act)
                end

                if state.macroPlaying and state.endDelay > 0 then
                    setStatus(string.format("Cycle Rest %.2fs", state.endDelay))
                    task.wait(state.endDelay)
                end
            else
                setStatus("No macro")
                task.wait(0.2)
            end

            task.wait(0.05)
        end

        state.running = false
        setStatus("Idle")
    end)
end

local function stopMacro()
    state.macroPlaying = false
    state.running = false
    setStatus("Idle")
end

local function beginRecording()
    if state.recording or state.autoCleaning or state.running then return end

    state.recordedActions = {}
    state.recordStart = tick()
    state.endDelay = 0
    state.recording = true
    setStatus("Recording")
end

local function stopRecording()
    if not state.recording then return end

    state.recording = false
    if #state.recordedActions > 0 then
        table.remove(state.recordedActions)
    end

    local prevTime = 0
    for _, act in ipairs(state.recordedActions) do
        local t = tonumber(act.time) or 0
        local delta = t - prevTime
        if delta < 0 then delta = 0 end
        act.delay = delta
        prevTime = t
    end

    local totalRecTime = state.recordStart and (tick() - state.recordStart) or 0
    local lastActionTime = (state.recordedActions[#state.recordedActions] and state.recordedActions[#state.recordedActions].time) or 0
    state.endDelay = math.max(0, totalRecTime - lastActionTime)
    state.recordStart = nil

    setStatus("Idle")
end

local function triggerPrompt(target)
    if not target then return end
    local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then return end

    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        local key = prompt.KeyboardKeyCode or Enum.KeyCode.E
        Vim:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        Vim:SendKeyEvent(false, key, false, game)
    end
end

local function cleanNearestByTerms(terms)
    if state.autoCleaning then return end
    state.autoCleaning = true
    state.cleaning = false

    task.spawn(function()
        while state.autoCleaning do
            if not state.cleaning then
                local target = findNearestByTerms(terms, 220)
                if target then
                    state.cleaning = true
                    setStatus("Walking to target")

                    local root = getRoot()
                    local part = getTargetPart(target)
                    if root and part then
                        root.CFrame = CFrame.new(part.Position + Vector3.new(0, 4, 0))
                    end

                    local retries = 0
                    while state.autoCleaning and retries < 12 do
                        triggerPrompt(target)
                        retries += 1
                        task.wait(0.25)
                    end

                    state.cleaning = false
                else
                    setStatus("Scanning")
                    task.wait(0.8)
                end
            end
            task.wait(0.2)
        end

        state.cleaning = false
        setStatus("Idle")
    end)
end

local function stopCleaning()
    state.autoCleaning = false
    state.cleaning = false
    setStatus("Idle")
end

local function bindButton(button, callback)
    if button then
        button.Activated:Connect(callback)
        button.MouseButton1Click:Connect(callback)
    end
end

local function setupInputCapture()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if not state.recording then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local guiPos = state.lastGUI and state.lastGUI.AbsolutePosition or Vector2.new(0, 0)
            local guiSize = state.lastGUI and state.lastGUI.AbsoluteSize or Vector2.new(0, 0)
            if input.Position and input.Position.X >= guiPos.X and input.Position.X <= guiPos.X + guiSize.X and input.Position.Y >= guiPos.Y and input.Position.Y <= guiPos.Y + guiSize.Y then
                return
            end
        end

        if not state.recordStart then return end

        local delayTime = tick() - state.recordStart
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.Position then
                table.insert(state.recordedActions, { type = "tap", time = delayTime, pos = input.Position })
            end
        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            table.insert(state.recordedActions, { type = "key", time = delayTime, keyCode = input.KeyCode })
        end
    end)
end

local function buildUI()
    local ui, _, _, buttons = makeGui()
    state.lastGUI = ui:FindFirstChild("MainFrame")

    bindButton(buttons.record, function()
        beginRecording()
    end)

    bindButton(buttons.stopRecord, function()
        stopRecording()
    end)

    bindButton(buttons.play, function()
        if not state.recording then
            playMacro()
        end
    end)

    bindButton(buttons.stopPlay, function()
        stopMacro()
    end)

    bindButton(buttons.teleportTrash, function()
        local t = findNearestByTerms(config.trashNames, 500)
        if t then
            teleportTo(t)
            setStatus("Teleported to trash")
        else
            setStatus("No trash found")
        end
    end)

    bindButton(buttons.teleportPuddle, function()
        local t = findNearestByTerms(config.puddleNames, 500)
        if t then
            teleportTo(t)
            setStatus("Teleported to puddle")
        else
            setStatus("No puddle found")
        end
    end)

    bindButton(buttons.clean, function()
        if not state.autoCleaning then
            cleanNearestByTerms(config.trashNames)
        end
    end)

    bindButton(buttons.stopClean, function()
        stopCleaning()
    end)

    return ui
end

setupInputCapture()
buildUI()

setStatus("Ready")

print("Powerlifters Farm script loaded")
print("Add exact names to config.trashNames / config.puddleNames if needed")
print("Example: config.trashNames = { 'trash', 'random trash', 'waste' }")
print("Example: config.puddleNames = { 'puddle', 'mud', 'water' }")
