local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local state = {
    recording = false,
    playing = false,
    actions = {},
    recordStartedAt = 0,
    gui = nil,
    statusLabel = nil,
}

local function setStatus(text)
    if state.statusLabel then
        state.statusLabel.Text = "Status: " .. text
    end
end

local function isInsideGui(pos)
    if not state.gui then return false end
    local guiPos = state.gui.AbsolutePosition
    local guiSize = state.gui.AbsoluteSize
    return pos.X >= guiPos.X and pos.X <= guiPos.X + guiSize.X
        and pos.Y >= guiPos.Y and pos.Y <= guiPos.Y + guiSize.Y
end

local function createGui()
    if PlayerGui:FindFirstChild("PhoneMacroGui") then
        PlayerGui.PhoneMacroGui:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "PhoneMacroGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 240, 0, 170)
    frame.Position = UDim2.new(0.5, -120, 0.15, 0)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    frame.BorderSizePixel = 0
    frame.Active = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.Size = UDim2.new(1, -20, 0, 28)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "Macro"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = frame
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, 38)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Idle"
    statusLabel.TextColor3 = Color3.fromRGB(220,220,220)
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextSize = 13
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left

    local recBtn = Instance.new("TextButton")
    recBtn.Parent = frame
    recBtn.Size = UDim2.new(0, 90, 0, 36)
    recBtn.Position = UDim2.new(0, 10, 0, 70)
    recBtn.Text = "REC"
    recBtn.TextColor3 = Color3.fromRGB(255,255,255)
    recBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    recBtn.Font = Enum.Font.SourceSansBold
    recBtn.TextSize = 15
    Instance.new("UICorner", recBtn).CornerRadius = UDim.new(0, 8)

    local playBtn = Instance.new("TextButton")
    playBtn.Parent = frame
    playBtn.Size = UDim2.new(0, 90, 0, 36)
    playBtn.Position = UDim2.new(0, 120, 0, 70)
    playBtn.Text = "PLAY"
    playBtn.TextColor3 = Color3.fromRGB(255,255,255)
    playBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    playBtn.Font = Enum.Font.SourceSansBold
    playBtn.TextSize = 15
    Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 8)

    local stopBtn = Instance.new("TextButton")
    stopBtn.Parent = frame
    stopBtn.Size = UDim2.new(1, -20, 0, 36)
    stopBtn.Position = UDim2.new(0, 10, 0, 116)
    stopBtn.Text = "STOP"
    stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stopBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    stopBtn.Font = Enum.Font.SourceSansBold
    stopBtn.TextSize = 15
    Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

    local function bind(button, callback)
        button.Activated:Connect(callback)
        button.MouseButton1Click:Connect(callback)
    end

    bind(recBtn, function()
        if state.recording or state.playing then return end
        state.actions = {}
        state.recordStartedAt = tick()
        state.recording = true
        recBtn.Text = "REC •"
        setStatus("Recording")
    end)

    bind(playBtn, function()
        if state.recording or state.playing then return end
        if #state.actions == 0 then
            setStatus("No macro")
            return
        end

        state.playing = true
        setStatus("Playing")

        task.spawn(function()
            local previousTime = 0
            for _, action in ipairs(state.actions) do
                if not state.playing then break end

                local waitTime = (action.time or 0) - previousTime
                if waitTime > 0 then
                    task.wait(waitTime)
                end
                previousTime = action.time or 0

                if action.type == "tap" then
                    local x = action.x
                    local y = action.y + GuiService:GetGuiInset().Y

                    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                    task.wait(0.03)
                    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
                elseif action.type == "key" then
                    VirtualInputManager:SendKeyEvent(true, action.keyCode, false, game)
                    task.wait(0.03)
                    VirtualInputManager:SendKeyEvent(false, action.keyCode, false, game)
                end
            end

            state.playing = false
            recBtn.Text = "REC"
            setStatus("Idle")
        end)
    end)

    bind(stopBtn, function()
        state.playing = false
        state.recording = false
        recBtn.Text = "REC"
        setStatus("Idle")
    end)

    state.gui = frame
    state.statusLabel = statusLabel
    return gui
end

local function recordInputAt(input)
    if not state.recording then return end
    local now = tick() - state.recordStartedAt

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton2 then
        if input.Position then
            local pos = input.Position
            if isInsideGui(pos) then return end

            table.insert(state.actions, {
                type = "tap",
                time = now,
                x = pos.X,
                y = pos.Y,
            })
        end

    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        table.insert(state.actions, {
            type = "key",
            time = now,
            keyCode = input.KeyCode,
        })
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    recordInputAt(input)
end)

createGui()
setStatus("Ready")
print("Macro ready. Use REC -> do actions -> STOP -> PLAY")
