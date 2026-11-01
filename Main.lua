local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

if playerGui:FindFirstChild("PhoneMacroGui") then
    playerGui.PhoneMacroGui:Destroy()
end

local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "PhoneMacroGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 220, 0, 210)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active = true
frame.Draggable = true

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local function createButton(name, text, yPos, color)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 200, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local recBtn = createButton("Rec", "REC: OFF", 15, Color3.fromRGB(60, 60, 60))
local stopBtn = createButton("Stop", "STOP", 55, Color3.fromRGB(120, 40, 40))
local playBtn = createButton("Play", "START (1x)", 95, Color3.fromRGB(40, 100, 40))
local loopBtn = createButton("Loop", "START LOOP (∞)", 135, Color3.fromRGB(40, 60, 120))

local statusLbl = Instance.new("TextLabel", frame)
statusLbl.Size = UDim2.new(0, 200, 0, 20)
statusLbl.Position = UDim2.new(0, 10, 0, 175)
statusLbl.BackgroundTransparency = 1
statusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLbl.TextSize = 12
statusLbl.Font = Enum.Font.Gotham
statusLbl.Text = "Status: Ready"

local recordedActions = {}
local totalDuration = 0 -- Загальна тривалість запису до моменту натискання STOP
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

-- Зупинка запису: фіксуємо точний час, коли ти натиснув STOP
stopBtn.MouseButton1Click:Connect(function()
    if isRecording then
        isRecording = false
        recBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        recBtn.Text = "REC: OFF"
        
        -- Рахуємо загальний час від старту до моменту натискання STOP
        totalDuration = tick() - recordingStartTime
        
        statusLbl.Text = "Saved! Len: " .. string.format("%.2fs", totalDuration)
    end
    isPlaying = false
end)

-- Запис дотиків із точним часом від початку
UserInputService.InputBegan:Connect(function(input, gpe)
    if isRecording and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        local pos = input.Position
        
        -- Ігноруємо кліки по самому меню макросу
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

-- Відтворення з урахуванням повного часу сесії до STOP
local function playback(loop)
    if isPlaying or #recordedActions == 0 then return end
    isPlaying = true

    task.spawn(function()
        repeat
            local playStartTime = tick()
            
            -- Відтворюємо всі кліки за їхнім таймлайном
            for _, action in ipairs(recordedActions) do
                if not isPlaying then break end
                
                local targetTime = playStartTime + action.timeFromStart
                while tick() < targetTime do
                    if not isPlaying then break end
                    RunService.Heartbeat:Wait()
                end
                
                if not isPlaying then break end

                statusLbl.Text = "Playing: " .. string.format("%.2fs", action.timeFromStart)
                
                -- Симуляція кліку по елементу інтерфейсу під цими координатами
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
            
            -- Витримуємо паузу від останнього кліку до моменту, коли ти натиснув STOP
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
