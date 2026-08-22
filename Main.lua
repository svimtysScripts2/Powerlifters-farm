local PlatoBoost = loadstring(game:HttpGet("https://dash.platoboost.app/api/sdk/29792"))()

local function startScript()
    _G.MacroPlaying = false
    _G.Recording = false
    _G.AutoCleaning = false

    local isRunning = false
    local isCleaning = false

    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local UserInputService = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")
    local Vim = game:GetService("VirtualInputManager")

    local recordedActions = {}
    local recordStartTime = nil
    local recordedEndDelay = 0

    local trashNames = { "puddle", "random trash", "trash", "clean" }
    local blacklist = { "bench", "press", "curl", "rack", "seat", "weight", "barbell", "dumbbell", "machine", "equipment", "use", "lift", "deadlift", "overhead", "squat" }

    if playerGui:FindFirstChild("PowerLiftersGui") then 
        playerGui.PowerLiftersGui:Destroy() 
    end

    local screenGui = Instance.new("ScreenGui", playerGui)
    screenGui.Name = "PowerLiftersGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local frame = Instance.new("Frame", screenGui)
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 260, 0, 260)
    frame.Position = UDim2.new(0.5, -130, 0.15, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.ClipsDescendants = true
    frame.ZIndex = 1

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local frameStroke = Instance.new("UIStroke", frame)
    frameStroke.Thickness = 2

    local titleBar = Instance.new("Frame", frame)
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.ZIndex = 2

    local toggleBtn = Instance.new("TextButton", titleBar)
    toggleBtn.Size = UDim2.new(0, 40, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = "[#]"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.TextSize = 18
    toggleBtn.ZIndex = 10

    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Position = UDim2.new(0, 45, 0, 0)
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "svimtysScripts"
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 3

    local btnContainer = Instance.new("Frame", frame)
    btnContainer.Position = UDim2.new(0, 0, 0, 40)
    btnContainer.Size = UDim2.new(1, 0, 0, 175)
    btnContainer.BackgroundTransparency = 1
    btnContainer.ZIndex = 3

    local statusLabel = Instance.new("TextLabel", frame)
    statusLabel.Position = UDim2.new(0, 10, 0, 215)
    statusLabel.Size = UDim2.new(1, -20, 0, 35)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Idle"
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextSize = 14
    statusLabel.ZIndex = 3

    toggleBtn.Activated:Connect(function()
        btnContainer.Visible = not btnContainer.Visible
        statusLabel.Visible = not statusLabel.Visible
        if btnContainer.Visible then 
            frame.Size = UDim2.new(0, 260, 0, 260)
        else 
            frame.Size = UDim2.new(0, 260, 0, 40) 
        end
    end)

    local function createBtn(text, pos, size)
        local btn = Instance.new("TextButton", btnContainer)
        btn.Size = size or UDim2.new(0, 115, 0, 45)
        btn.Position = pos
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 15
        btn.ZIndex = 10
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Thickness = 2
        return btn, stroke
    end

    local startButton, startStroke = createBtn("START", UDim2.new(0, 10, 0, 10))
    local stopButton, stopStroke = createBtn("STOP", UDim2.new(0, 135, 0, 10))
    local recButton, recStroke = createBtn("REC", UDim2.new(0, 10, 0, 65))
    local stopRecButton, stopRecStroke = createBtn("STOP REC", UDim2.new(0, 135, 0, 65))
    local cleanButton, cleanStroke = createBtn("AUTO CLEAN", UDim2.new(0, 10, 0, 120))
    local stopCleanButton, stopCleanStroke = createBtn("STOP CLEAN", UDim2.new(0, 135, 0, 120))

    local dragging = false
    local dragStart, startPos

    titleBar.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            local connChanged, connEnded
            connChanged = UserInputService.InputChanged:Connect(function(moveInput)
                if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                    local delta = moveInput.Position - dragStart
                    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            
            connEnded = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    if connChanged then connChanged:Disconnect() end
                    if connEnded then connEnded:Disconnect() end
                end
            end)
        end
    end)

    task.spawn(function()
        local hue = 0
        while screenGui and screenGui.Parent do
            hue = (hue + 0.005) % 1
            local rgbColor = Color3.fromHSV(hue, 0.8, 1)
            frameStroke.Color = rgbColor
            toggleBtn.TextColor3 = rgbColor
            titleLabel.TextColor3 = rgbColor
            startStroke.Color = rgbColor
            stopStroke.Color = rgbColor
            recStroke.Color = rgbColor
            stopRecStroke.Color = rgbColor
            cleanStroke.Color = rgbColor
            stopCleanStroke.Color = rgbColor
            startButton.TextColor3 = rgbColor
            stopButton.TextColor3 = rgbColor
            recButton.TextColor3 = rgbColor
            stopRecButton.TextColor3 = rgbColor
            cleanButton.TextColor3 = rgbColor
            stopCleanButton.TextColor3 = rgbColor
            task.wait(0.03)
        end
    end)

    local function clickGameButton(btnName)
        local guiOffset = GuiService:GetGuiInset()
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "PowerLiftersGui" and gui.Enabled then
                for _, obj in pairs(gui:GetDescendants()) do
                    if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
                        local name = string.lower(obj.Name)
                        local text = obj:IsA("TextButton") and string.lower(obj.Text) or ""
                        if name:find(btnName) or text:find(btnName) then
                            local absPos = obj.AbsolutePosition
                            local absSize = obj.AbsoluteSize
                            local center = Vector2.new(absPos.X + absSize.X / 2, absPos.Y + absSize.Y / 2 + guiOffset.Y)
                            
                            Vim:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
                            task.wait(0.05)
                            Vim:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not _G.Recording then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local guiPos = frame.AbsolutePosition
            local guiSize = frame.AbsoluteSize
            if input.Position and input.Position.X >= guiPos.X and input.Position.X <= (guiPos.X + guiSize.X) and
               input.Position.Y >= guiPos.Y and input.Position.Y <= (guiPos.Y + guiSize.Y) then
                return
            end
        end

        if not recordStartTime then return end
        local delayTime = tick() - recordStartTime

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.Position then
                local exactPos = Vector2.new(input.Position.X, input.Position.Y)
                table.insert(recordedActions, {type = "tap", time = delayTime, pos = exactPos})
            end
        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            table.insert(recordedActions, {type = "key", time = delayTime, keyCode = input.KeyCode})
        end
    end)

    local function playMacro()
        task.spawn(function()
            local guiOffset = GuiService:GetGuiInset()
            while _G.MacroPlaying do
                if #recordedActions > 0 then
                    for index, act in ipairs(recordedActions) do
                        if not _G.MacroPlaying then break end

                        local waitTime = act.delay or 0
                        if waitTime > 0 then
                            statusLabel.Text = "Status: Waiting (" .. string.format("%.2f", waitTime) .. "s)"
                            task.wait(waitTime)
                        end

                        if not _G.MacroPlaying then break end

                        statusLabel.Text = "Status: Executing " .. index .. "/" .. #recordedActions
                        if act.type == "tap" and act.pos then
                            local clickX = act.pos.X
                            local clickY = act.pos.Y + guiOffset.Y

                            Vim:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
                            task.wait(0.05)
                            Vim:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
                        elseif act.type == "key" and act.keyCode then
                            Vim:SendKeyEvent(true, act.keyCode, false, game)
                            task.wait(0.05)
                            Vim:SendKeyEvent(false, act.keyCode, false, game)
                        end
                    end

                    if _G.MacroPlaying and recordedEndDelay and recordedEndDelay > 0 then
                        statusLabel.Text = "Status: Cycle Resting (" .. string.format("%.2f", recordedEndDelay) .. "s)"
                        task.wait(recordedEndDelay)
                    end
                else
                    clickGameButton("use")
                    task.wait(0.3)
                    clickGameButton("rep")
                    task.wait(0.2)
                end

                task.wait(0.1)
            end
            isRunning = false
            statusLabel.Text = "Status: Idle"
        end)
    end

    local function isBlacklisted(str)
        if not str then return false end
        local lowerStr = string.lower(str)
        for _, word in pairs(blacklist) do
            if string.find(lowerStr, word) then return true end
        end
        return false
    end

    local function triggerTrashPrompt(prompt)
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

    local function cleanObject(target)
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or not target or not target.Parent then return end
        
        isCleaning = true
        statusLabel.Text = "Status: Walking to target..."
        
        local targetPos = target:IsA("BasePart") and target.Position or (target.PrimaryPart and target.PrimaryPart.Position)
        if not targetPos then
            local part = target:FindFirstChildWhichIsA("BasePart", true)
            if part then targetPos = part.Position end
        end
        
        if targetPos then
            hum:MoveTo(targetPos)
            local reached = false
            local conn = hum.MoveToFinished:Connect(function() reached = true end)
            task.spawn(function() task.wait(3.5) reached = true end)
            repeat task.wait(0.1) until reached or not target.Parent or not _G.AutoCleaning
            if conn then conn:Disconnect() end
        end
        
        if not _G.AutoCleaning then isCleaning = false return end
        
        statusLabel.Text = "Status: Cleaning..."
        local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
        local attempts = 0
        while target and target.Parent and _G.AutoCleaning and attempts < 12 do
            if prompt then triggerTrashPrompt(prompt) end
            attempts = attempts + 1
            task.wait(0.25)
        end
        isCleaning = false
    end

    local function findNearestTrash()
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local nearest, minDist = nil, 250
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if (obj:IsA("BasePart") or obj:IsA("Model")) and not isBlacklisted(obj.Name) then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    local actionText = prompt.ActionText or ""
                    local objectText = prompt.ObjectText or ""
                    
                    if not isBlacklisted(actionText) and not isBlacklisted(objectText) then
                        local objName = string.lower(obj.Name)
                        local isTrash = false
                        
                        for _, tName in pairs(trashNames) do
                            if string.find(objName, tName) or string.find(string.lower(actionText), tName) or string.find(string.lower(objectText), tName) then
                                isTrash = true
                                break
                            end
                        end
                        
                        if isTrash then
                            local pos = obj:IsA("BasePart") and obj.Position or (obj.PrimaryPart and obj.PrimaryPart.Position)
                            if not pos then
                                local p = obj:FindFirstChildWhichIsA("BasePart", true)
                                if p then pos = p.Position end
                            end
                            if pos then
                                local d = (root.Position - pos).Magnitude
                                if d < minDist then minDist = d; nearest = obj end
                            end
                        end
                    end
                end
            end
        end
        return nearest
    end

    local function startAutoCleaning()
        task.spawn(function()
            while _G.AutoCleaning do
                if not isCleaning then
                    local target = findNearestTrash()
                    if target then cleanObject(target) 
                    else 
                        statusLabel.Text = "Status: Scanning..."
                        task.wait(0.8) 
                    end
                end
                task.wait(0.2)
            end
            statusLabel.Text = "Status: Idle"
        end)
    end

    local function bindButton(btn, callback)
        btn.Activated:Connect(callback)
        btn.MouseButton1Click:Connect(callback)
    end

    bindButton(startButton, function()
        if not isRunning and not _G.Recording and not _G.AutoCleaning then
            _G.MacroPlaying = true
            isRunning = true
            statusLabel.Text = "Status: Playing Macro"
            playMacro()
        end
    end)

    bindButton(stopButton, function()
        _G.MacroPlaying = false
        isRunning = false
        _G.Recording = false
        _G.AutoCleaning = false
        isCleaning = false
        recButton.Text = "REC"
        statusLabel.Text = "Status: Idle"
    end)

    bindButton(recButton, function()
        if not _G.Recording and not isRunning and not _G.AutoCleaning then
            _G.MacroPlaying = false
            recordedActions = {}
            recordStartTime = tick()
            recordedEndDelay = 0
            _G.Recording = true
            recButton.Text = "REC 🔴"
            statusLabel.Text = "Status: Recording..."
        end
    end)

    bindButton(stopRecButton, function()
        if _G.Recording then
            _G.Recording = false
            recButton.Text = "REC"

            if #recordedActions > 0 then
                table.remove(recordedActions, #recordedActions)
            end

            local prevTime = 0
            for i, act in ipairs(recordedActions) do
                local t = act.time or 0
                local delta = t - prevTime
                if delta < 0 then delta = 0 end
                act.delay = delta
                prevTime = t
            end

            if recordStartTime then
                local totalRecTime = tick() - recordStartTime
                local lastActionTime = (recordedActions[#recordedActions] and recordedActions[#recordedActions].time) or 0
                recordedEndDelay = math.max(0, totalRecTime - lastActionTime)
            else
                recordedEndDelay = 0
            end

            recordStartTime = nil

            statusLabel.Text = "Status: Idle"
        end
    end)

    bindButton(cleanButton, function()
        if not _G.AutoCleaning and not _G.Recording and not isRunning then
            _G.AutoCleaning = true
            startAutoCleaning()
            statusLabel.Text = "Status: AutoCleaning"
        end
    end)

    bindButton(stopCleanButton, function()
        _G.AutoCleaning = false
        isCleaning = false
        statusLabel.Text = "Status: Idle"
    end)
end

if PlatoBoost.ValidateKey() then
    startScript()
else
    PlatoBoost.PromptKey()
end
