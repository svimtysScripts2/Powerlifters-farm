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
    startedAt = 0,
    gui = nil,
    statusLabel = nil,
}

local function setStatus(text)
    if state.statusLabel then
        state.statusLabel.Text = "Status: " .. text
    end
end

local function insideGui(pos)
    if not state.gui then return false end
    local guiPos = state.gui.AbsolutePosition
    local guiSize = state.gui.AbsoluteSize
    return pos.X >= guiPos.X and pos.X <= guiPos.X + guiSize.X
        and pos.Y >= guiPos.Y and pos.Y <= guiPos.Y + guiSize.Y
end

local function findClosestVisibleButton(x, y, radius)
    radius = radius or 120
    local best = nil
    local bestDist = radius

    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, obj in ipairs(gui:GetDescendants()) do
                if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
                    local pos = obj.AbsolutePosition
                    local size = obj.AbsoluteSize
                    local cx = pos.X + size.X / 2
                    local cy = pos.Y + size.Y / 2
                    local dist = math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2)
                    if dist < bestDist then
                        bestDist = dist
                        best = {
                            x = cx,
                            y = cy + GuiService:GetGuiInset().Y,
                        }
                    end
                end
            end
        end
    end

    return best
end

local function sendTap(x, y)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.035)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

local function performAction(action)
    if action.type == "tap" then
        local x = action.x
        local y = action.y

        sendTap(x, y)

        task.wait(0.04)

        local fallback = findClosestVisibleButton(x, y, 90)
        if fallback then
            sendTap(fallback.x, fallback.y)
        end
    elseif action.type == "key" then
        VirtualInputManager:SendKeyEvent(true, action.keyCode, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, action.keyCode, false, game)
    end
end

local function createGui()
    if PlayerGui:FindFirstChild("MacroExactGui") then
        PlayerGui.MacroExactGui:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MacroExactGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 150)
    frame.Position = UDim2.new(0.5, -110, 0.15, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Active = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(1, -20, 0, 26)
    label.Position = UDim2.new(0, 10, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = "Exact Macro"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.TextXAlignment = Enum.TextXAlignment.Left

    local status = Instance.new("TextLabel")
    status.Parent = frame
    status.Size = UDim2.new(1, -20, 0, 20)
    status.Position = UDim2.new(0, 10, 0, 36)
    status.BackgroundTransparency = 1
    status.Text = "Status: Idle"
    status.TextColor3 = Color3.fromRGB(220, 220, 220)
    status.Font = Enum.Font.SourceSans
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Left

    local rec = Instance.new("TextButton")
    rec.Parent = frame
    rec.Size = UDim2.new(0, 90, 0, 36)
    rec.Position = UDim2.new(0, 10, 0, 70)
    rec.Text = "REC"
    rec.TextColor3 = Color3.fromRGB(255, 255, 255)
    rec.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    rec.Font = Enum.Font.SourceSansBold
    rec.TextSize = 15
    Instance.new("UICorner", rec).CornerRadius = UDim.new(0, 8)

    local play = Instance.new("TextButton")
    play.Parent = frame
    play.Size = UDim2.new(0, 90, 0, 36)
    play.Position = UDim2.new(0, 120, 0, 70)
    play.Text = "PLAY"
    play.TextColor3 = Color3.fromRGB(255, 255, 255)
    play.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    play.Font = Enum.Font.SourceSansBold
    play.TextSize = 15
    Instance.new("UICorner", play).CornerRadius = UDim.new(0, 8)

    local stop = Instance.new("TextButton")
    stop.Parent = frame
    stop.Size = UDim2.new(1, -20, 0, 36)
    stop.Position = UDim2.new(0, 10, 0, 110)
    stop.Text = "STOP"
    stop.TextColor3 = Color3.fromRGB(255, 255, 255)
    stop.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
    stop.Font = Enum.Font.SourceSansBold
    stop.TextSize = 15
    Instance.new("UICorner", stop).CornerRadius = UDim.new(0, 8)

    local function bind(button, callback)
        button.Activated:Connect(callback)
        button.MouseButton1Click:Connect(callback)
    end

    bind(rec, function()
        if state.recording or state.playing then return end
        state.recording = true
        state.actions = {}
        state.startedAt = tick()
        rec.Text = "REC •"
        setStatus("Recording")
    end)

    bind(play, function()
        if state.recording or state.playing then return end
        if #state.actions == 0 then
            setStatus("No macro")
            return
        end

        state.playing = true
        setStatus("Playing")

        task.spawn(function()
            local prevTime = 0
            for _, action in ipairs(state.actions) do
                if not state.playing then break end

                local waitTime = (action.time or 0) - prevTime
                if waitTime > 0 then
                    task.wait(waitTime)
                end
                prevTime = action.time or 0

                performAction(action)
            end

            state.playing = false
            rec.Text = "REC"
            setStatus("Idle")
        end)
    end)

    bind(stop, function()
        state.recording = false
        state.playing = false
        rec.Text = "REC"
        setStatus("Idle")
    end)

    state.gui = frame
    state.statusLabel = status
end

local function recordInput(input)
    if not state.recording then return end
    local now = tick() - state.startedAt

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position then
            local pos = input.Position
            if insideGui(pos) then return end

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
    recordInput(input)
end)

createGui()
setStatus("Ready")
print("Exact macro ready. REC -> do actions -> STOP -> PLAY")
