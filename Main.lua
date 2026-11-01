local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local state = {
    isRecording = false,
    isPlaying = false,
    actions = {},
    recordStart = nil,
    endDelay = 0,
    gui = nil,
    status = nil,
}

local function setStatus(text)
    if state.status then
        state.status.Text = "Status: " .. text
    end
end

local function insideGui(pos)
    if not state.gui then return false end
    local guiPos = state.gui.AbsolutePosition
    local guiSize = state.gui.AbsoluteSize
    return pos.X >= guiPos.X and pos.X <= guiPos.X + guiSize.X
        and pos.Y >= guiPos.Y and pos.Y <= guiPos.Y + guiSize.Y
end

local function makeGui()
    if playerGui:FindFirstChild("MacroOnlyGui") then
        playerGui.MacroOnlyGui:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MacroOnlyGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 240, 0, 150)
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
    title.Text = "Macro Only"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left

    local status = Instance.new("TextLabel")
    status.Parent = frame
    status.Size = UDim2.new(1, -20, 0, 20)
    status.Position = UDim2.new(0, 10, 0, 36)
    status.BackgroundTransparency = 1
    status.Text = "Status: Idle"
    status.TextColor3 = Color3.fromRGB(200,200,200)
    status.Font = Enum.Font.SourceSans
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Left

    local recBtn = Instance.new("TextButton")
    recBtn.Parent = frame
    recBtn.Size = UDim2.new(0, 90, 0, 36)
    recBtn.Position = UDim2.new(0, 10, 0, 60)
    recBtn.Text = "REC"
    recBtn.TextColor3 = Color3.fromRGB(255,255,255)
    recBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
    recBtn.Font = Enum.Font.SourceSansBold
    recBtn.TextSize = 15
    Instance.new("UICorner", recBtn).CornerRadius = UDim.new(0, 8)

    local playBtn = Instance.new("TextButton")
    playBtn.Parent = frame
    playBtn.Size = UDim2.new(0, 90, 0, 36)
    playBtn.Position = UDim2.new(0, 120, 0, 60)
    playBtn.Text = "PLAY"
    playBtn.TextColor3 = Color3.fromRGB(255,255,255)
    playBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
    playBtn.Font = Enum.Font.SourceSansBold
    playBtn.TextSize = 15
    Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 8)

    local stopBtn = Instance.new("TextButton")
    stopBtn.Parent = frame
    stopBtn.Size = UDim2.new(1, -20, 0, 36)
    stopBtn.Position = UDim2.new(0, 10, 0, 104)
    stopBtn.Text = "STOP"
    stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stopBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    stopBtn.Font = Enum.Font.SourceSansBold
    stopBtn.TextSize = 15
    Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

    frame.Parent = gui
    state.gui = frame
    state.status = status

    local function bind(button, callback)
        button.Activated:Connect(callback)
        button.MouseButton1Click:Connect(callback)
    end

    bind(recBtn, function()
        if state.isRecording or state.isPlaying then return end
        state.actions = {}
        state.recordStart = tick()
        state.endDelay = 0
        state.isRecording = true
        setStatus("Recording")
        recBtn.Text = "REC •"
    end)

    bind(playBtn, function()
        if state.isPlaying or state.isRecording then return end
        if #state.actions == 0 then
            setStatus("No macro")
            return
        end
        state.isPlaying = true
        setStatus("Playing")

        task.spawn(function()
            for i, act in ipairs(state.actions) do
                if not state.isPlaying then break end

                local waitTime = act.delay or 0
                if waitTime > 0 then
                    setStatus("Wait " .. string.format("%.2f", waitTime) .. "s")
                    task.wait(waitTime)
                end

                if not state.isPlaying then break end

                if act.type == "tap" and act.x and act.y then
                    local x = act.x
                    local y = act.y + GuiService:GetGuiInset().Y
                    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                    task.wait(0.04)
                    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
                elseif act.type == "key" and act.keyCode then
                    VirtualInputManager:SendKeyEvent(true, act.keyCode, false, game)
                    task.wait(0.04)
                    VirtualInputManager:SendKeyEvent(false, act.keyCode, false, game)
                end
            end

            if state.isPlaying and state.endDelay > 0 then
                setStatus("Cycle rest")
                task.wait(state.endDelay)
            end

            state.isPlaying = false
            setStatus("Idle")
        end)
    end)

    bind(stopBtn, function()
        state.isPlaying = false
        state.isRecording = false
        if recBtn then recBtn.Text = "REC" end
        setStatus("Idle")
    end)

    return gui
end

local function finalizeRecording()
    if not state.isRecording then return end

    state.isRecording = false
    if state.recordStart then
        local totalTime = tick() - state.recordStart
        local lastTime = (state.actions[#state.actions] and state.actions[#state.actions].time) or 0
        state.endDelay = math.max(0, totalTime - lastTime)
    else
        state.endDelay = 0
    end

    local prevTime = 0
    for _, act in ipairs(state.actions) do
        local t = act.time or 0
        local delta = t - prevTime
        if delta < 0 then delta = 0 end
        act.delay = delta
        prevTime = t
    end

    state.recordStart = nil
    setStatus("Idle")
    if state.gui then
        local recButton = state.gui:FindFirstChild("Main"):FindFirstChildOfClass("TextButton")
        if recButton then recButton.Text = "REC" end
    end
end

local function recordInput(input)
    if not state.isRecording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position then
            local pos = input.Position
            if insideGui(pos) then return end
            local delayTime = tick() - (state.recordStart or tick())
            table.insert(state.actions, {
                type = "tap",
                time = delayTime,
                x = pos.X,
                y = pos.Y,
            })
        end
    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        local delayTime = tick() - (state.recordStart or tick())
        table.insert(state.actions, {
            type = "key",
            time = delayTime,
            keyCode = input.KeyCode,
        })
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.Keyboard then
        recordInput(input)
    end
end)

local function stopRecordingButton()
    finalizeRecording()
end

local gui = makeGui()
state.gui = gui:FindFirstChild("Main")

local recButton = state.gui:FindFirstChildOfClass("TextButton")
local stopButton = state.gui:FindFirstChildOfClass("TextButton")

local allButtons = state.gui:GetChildren()
for _, child in ipairs(allButtons) do
    if child:IsA("TextButton") then
        if child.Text == "REC" then
            recButton = child
        elseif child.Text == "STOP" then
            stopButton = child
        end
    end
end

if recButton then
    recButton.Activated:Connect(function()
        if state.isRecording or state.isPlaying then return end
        state.actions = {}
        state.recordStart = tick()
        state.endDelay = 0
        state.isRecording = true
        setStatus("Recording")
        recButton.Text = "REC •"
    end)
end

if stopButton then
    stopButton.Activated:Connect(function()
        state.isPlaying = false
        stopRecordingButton()
    end)
end

setStatus("Ready")
print("Macro only script loaded")
print("Use REC -> PLAY")
