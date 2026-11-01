local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

pcall(function()
    if playerGui:FindFirstChild("vimtysscriptsGui") then
        playerGui.vimtysscriptsGui:Destroy()
    end
end)

local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "vimtysscriptsGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

-- Головне вікно (збільшене по ширині для інструкції справа)
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 480, 0, 225)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Верхня панель (Заголовок)
local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(0, 460, 0, 30)
topBar.Position = UDim2.new(0, 10, 0, 8)
topBar.BackgroundTransparency = 1

-- Чорний прямокутник для імені vimtysscripts
local nameBg = Instance.new("Frame", topBar)
nameBg.Size = UDim2.new(0, 410, 0, 30)
nameBg.Position = UDim2.new(0, 0, 0, 0)
nameBg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Instance.new("UICorner", nameBg).CornerRadius = UDim.new(0, 6)

local nameLbl = Instance.new("TextLabel", nameBg)
nameLbl.Size = UDim2.new(1, 0, 1, 0)
nameLbl.BackgroundTransparency = 1
nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLbl.TextSize = 13
nameLbl.Font = Enum.Font.GothamBold
nameLbl.Text = "vimtysscripts"

-- Червоний круг зі знаком сонця у кінці заголовка
local sunBtn = Instance.new("TextButton", topBar)
sunBtn.Size = UDim2.new(0, 30, 0, 30)
sunBtn.Position = UDim2.new(1, -30, 0, 0)
sunBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
sunBtn.Text = "卍"
sunBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
sunBtn.TextSize = 16
sunBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", sunBtn).CornerRadius = UDim.new(1, 0)

-- Кнопки керування макросом (зліва)
local function createButton(text, yPos, color)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 210, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local recBtn = createButton("REC: OFF", 46, Color3.fromRGB(60, 60, 60))
local stopBtn = createButton("STOP", 84, Color3.fromRGB(120, 40, 40))
local playBtn = createButton("START (1x)", 122, Color3.fromRGB(40, 100, 40))
local loopBtn = createButton("START LOOP (∞)", 160, Color3.fromRGB(120, 80, 40))

local statusLbl = Instance.new("TextLabel", frame)
statusLbl.Size = UDim2.new(0, 210, 0, 20)
statusLbl.Position = UDim2.new(0, 10, 0, 200)
statusLbl.BackgroundTransparency = 1
statusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLbl.TextSize = 11
statusLbl.Font = Enum.Font.Gotham
statusLbl.Text = "Status: Ready"

-- Інструкція справа
local guideBg = Instance.new("Frame", frame)
guideBg.Size = UDim2.new(0, 230, 0, 146)
guideBg.Position = UDim2.new(0, 235, 0, 46)
guideBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", guideBg).CornerRadius = UDim.new(0, 6)

local guideLbl = Instance.new("TextLabel", guideBg)
guideLbl.Size = UDim2.new(1, -10, 1, -10)
guideLbl.Position = UDim2.new(0, 5, 0, 5)
guideLbl.BackgroundTransparency = 1
guideLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
guideLbl.TextSize = 11
guideLbl.Font = Enum.Font.Gotham
guideLbl.TextXAlignment = Enum.TextXAlignment.Left
guideLbl.TextYAlignment = Enum.TextYAlignment.Top
guideLbl.TextWrapped = true
guideLbl.Text = "First take weight tap Record then click how many times u want. Then wait regen stamina and press stop. Thank You!"

-- Логіка згортання/розгортання на знак сонця
local isMinimized = false
sunBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        frame.Size = UDim2.new(0, 480, 0, 46)
        recBtn.Visible = false
        stopBtn.Visible = false
        playBtn.Visible = false
        loopBtn.Visible = false
        statusLbl.Visible = false
        guideBg.Visible = false
    else
        frame.Size = UDim2.new(0, 480, 0, 225)
        recBtn.Visible = true
        stopBtn.Visible = true
        playBtn.Visible = true
        loopBtn.Visible = true
        statusLbl.Visible = true
        guideBg.Visible = true
    end
end)

local recordedActions = {}
local totalDuration = 0
local isRecording = false
local isPlaying = false
local recordingStartTime = 0

-- Запуск запису
recBtn.MouseButton1Click:Connect(function()
    recordedActions = {}
    totalDuration = 0
    isRecording = true
    recordingStartTime = tick()
    recBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    recBtn.Text = "REC: RECORDING..."
    statusLbl.Text = "Recording timeline..."
end)

-- Зупинка запису та фіксація часу
stopBtn.MouseButton1Click:Connect(function()
    if isRecording then
        isRecording = false
        recBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        recBtn.Text = "REC: OFF"
        
        totalDuration = tick() - recordingStartTime
        statusLbl.Text = "Saved! Len: " .. string.format("%.2fs", totalDuration)
    end
    isPlaying = false
end)

-- Запис дотиків
UserInputService.InputBegan:Connect(function(input, gpe)
    if isRecording and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        local pos = input.Position
        
        local absPos = frame.AbsolutePosition
        local absSize = frame.AbsoluteSize
        if not (pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y) then
            
            local timePassed = tick() - recordingStartTime
            
            table.insert(recordedActions, {
                pos = Vector2.new(pos.X, pos.Y),
                timeFromStart = timePassed
            })
            
            statusLbl.Text = "Time: " .. string.format("%.2fs", timePassed)
        end
    end
end)

-- Відтворення макросу
local function playback(loop)
    if isPlaying or #recordedActions == 0 then return end
    isPlaying = true

    task.spawn(function()
        repeat
            local playStartTime = tick()
            
            for _, action in ipairs(recordedActions) do
                if not isPlaying then break end
                
                local targetTime = playStartTime + action.timeFromStart
                while tick() < targetTime do
                    if not isPlaying then break end
                    RunService.Heartbeat:Wait()
                end
                
                if not isPlaying then break end

                statusLbl.Text = "Playing: " .. string.format("%.2fs", action.timeFromStart)
                
                pcall(function()
                    for _, guiObj in ipairs(playerGui:GetDescendants()) do
                        if guiObj:IsA("GuiButton") and guiObj.Visible then
                            local absPos = guiObj.AbsolutePosition
                            local absSize = guiObj.AbsoluteSize
                            
                            if action.pos.X >= absPos.X and action.pos.X <= absPos.X + absSize.X and
                               action.pos.Y >= absPos.Y and action.pos.Y <= absPos.Y + absSize.Y then
                                
                                for _, conn in ipairs(getconnections(guiObj.MouseButton1Click)) do
                                    conn:Fire()
                                end
                            end
                        end
                    end
                end)
            end
            
            if isPlaying and totalDuration > 0 then
                local stopTargetTime = playStartTime + totalDuration
                while tick() < stopTargetTime do
                    if not isPlaying then break end
                    RunService.Heartbeat:Wait()
                end
            end
            
        until not isPlaying or not loop
        
        isPlaying = false
        statusLbl.Text = "Status: Finished"
    end)
end

playBtn.MouseButton1Click:Connect(function()
    playback(false)
end)

loopBtn.MouseButton1Click:Connect(function()
    playback(true)
end)
