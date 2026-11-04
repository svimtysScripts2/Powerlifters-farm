local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LuaProtectURL = "https://key.luaprotect.dev/0a10cc/576eb6"
local DiscordURL = "https://discord.gg/6A8GMTbZm"

local function verifyKey(key)
    if not key or key == "" then return false end
    
    key = string.gsub(key, "^%s*(.-)%s*$", "%1")
    
    if key == "master" then
        return true
    end
    
    local successHwid, hwid = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    hwid = (successHwid and hwid) and hwid or "unknown"
    
    local url = string.format("https://key.luaprotect.dev/api/v1/ad-rewards/check?key=%s&stream=576eb6&hwid=%s", key, hwid)
    
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and response then
        if string.find(response, '"valid":true') or string.find(response, '"success":true') or string.find(response, "true") then
            return true
        end
    end
    
    return false
end

pcall(function()
    if playerGui:FindFirstChild("VimtysKeySystem") then playerGui.VimtysKeySystem:Destroy() end
    if playerGui:FindFirstChild("vimtysscriptsGui") then playerGui.vimtysscriptsGui:Destroy() end
end)

local keyScreenGui = Instance.new("ScreenGui", playerGui)
keyScreenGui.Name = "VimtysKeySystem"
keyScreenGui.ResetOnSpawn = false

local keyFrame = Instance.new("Frame", keyScreenGui)
keyFrame.Size = UDim2.new(0, 360, 0, 210)
keyFrame.Position = UDim2.new(0.5, -180, 0.5, -105)
keyFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
keyFrame.Active = true
keyFrame.Draggable = true
Instance.new("UICorner", keyFrame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", keyFrame)
stroke.Color = Color3.fromRGB(45, 45, 55)
stroke.Thickness = 1.5

local keyTitle = Instance.new("TextLabel", keyFrame)
keyTitle.Size = UDim2.new(1, 0, 0, 35)
keyTitle.Position = UDim2.new(0, 0, 0, 5)
keyTitle.BackgroundTransparency = 1
keyTitle.Font = Enum.Font.GothamBold
keyTitle.Text = "vimtysscripts — Key System"
keyTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
keyTitle.TextSize = 15

local KeyInput = Instance.new("TextBox", keyFrame)
KeyInput.Size = UDim2.new(0.9, 0, 0, 48)
KeyInput.Position = UDim2.new(0.05, 0, 0.23, 0)
KeyInput.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
KeyInput.Font = Enum.Font.GothamBold
KeyInput.PlaceholderText = "Paste Key Here..."
KeyInput.Text = ""
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
KeyInput.TextSize = 14
KeyInput.ClearTextOnFocus = false
KeyInput.TextXAlignment = Enum.TextXAlignment.Center
Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 8)

local inputStroke = Instance.new("UIStroke", KeyInput)
inputStroke.Color = Color3.fromRGB(40, 40, 50)
inputStroke.Thickness = 1

local RedeemBtn = Instance.new("TextButton", keyFrame)
RedeemBtn.Size = UDim2.new(0.43, 0, 0, 42)
RedeemBtn.Position = UDim2.new(0.05, 0, 0.52, 0)
RedeemBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 80)
RedeemBtn.Font = Enum.Font.GothamBold
RedeemBtn.Text = "Redeem"
RedeemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RedeemBtn.TextSize = 14
Instance.new("UICorner", RedeemBtn).CornerRadius = UDim.new(0, 8)

local GetKeyBtn = Instance.new("TextButton", keyFrame)
GetKeyBtn.Size = UDim2.new(0.43, 0, 0, 42)
GetKeyBtn.Position = UDim2.new(0.52, 0, 0.52, 0)
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.Text = "Get Key"
GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKeyBtn.TextSize = 14
Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 8)

local StatusLabel = Instance.new("TextLabel", keyFrame)
StatusLabel.Size = UDim2.new(0.9, 0, 0, 22)
StatusLabel.Position = UDim2.new(0.05, 0, 0.82, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Enter key to proceed"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
StatusLabel.TextSize = 12

GetKeyBtn.MouseButton1Click:Connect(function()
    local targetURL = (LuaProtectURL ~= "") and LuaProtectURL or DiscordURL
    if setclipboard then
        setclipboard(targetURL)
        StatusLabel.Text = "Key link copied to clipboard!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    else
        StatusLabel.Text = "Link: " .. targetURL
    end
end)

RedeemBtn.MouseButton1Click:Connect(function()
    local userKey = KeyInput.Text
    StatusLabel.Text = "Checking key..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    task.spawn(function()
        if verifyKey(userKey) then
            StatusLabel.Text = "Success! Loading macro..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
            task.wait(1)
            keyScreenGui:Destroy()
            
            local screenGui = Instance.new("ScreenGui", playerGui)
            screenGui.Name = "vimtysscriptsGui"
            screenGui.ResetOnSpawn = false
            screenGui.IgnoreGuiInset = true

            local frame = Instance.new("Frame", screenGui)
            frame.Size = UDim2.new(0, 480, 0, 225)
            frame.Position = UDim2.new(0.05, 0, 0.3, 0)
            frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            frame.Active = true
            frame.Draggable = true
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

            local topBar = Instance.new("Frame", frame)
            topBar.Size = UDim2.new(0, 460, 0, 30)
            topBar.Position = UDim2.new(0, 10, 0, 8)
            topBar.BackgroundTransparency = 1

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

            local sunBtn = Instance.new("TextButton", topBar)
            sunBtn.Size = UDim2.new(0, 30, 0, 30)
            sunBtn.Position = UDim2.new(1, -30, 0, 0)
            sunBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
            sunBtn.Text = "卍"
            sunBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
            sunBtn.TextSize = 16
            sunBtn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", sunBtn).CornerRadius = UDim.new(1, 0)

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

            recBtn.MouseButton1Click:Connect(function()
                recordedActions = {}
                totalDuration = 0
                isRecording = true
                recordingStartTime = tick()
                recBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
                recBtn.Text = "REC: RECORDING..."
                statusLbl.Text = "Recording timeline..."
            end)

            stopBtn.MouseButton1Click:Connect(function()
                if isRecording then
                    isRecording = false
                    recBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    recBtn.Text = "REC: OFF"
                    totalDuration = tick() - recordingStartTime
                    statusLbl.Text = "Saved! Len: " .. string.format("%.2fs", totalDuration)
                end
                isPlaying = false
            end
            
