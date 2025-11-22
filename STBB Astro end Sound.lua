local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://105458046205538"
sound.Volume = 3
sound.Parent = game.Workspace

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "STBBNotification"
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 280)
frame.Position = UDim2.new(0.5, -200, 0.5, -140)
frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.new(0.8, 0.2, 0.2)
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "STBB:Astro end Sound"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.new(1, 0.3, 0.3)
title.Parent = frame

local content = Instance.new("TextLabel")
content.Size = UDim2.new(1, -20, 0, 80)
content.Position = UDim2.new(0, 10, 0, 30)
content.BackgroundTransparency = 1
content.Text = "由于此音频为STBB官方私人音频，请在STBB里运行此脚本，否则无效"
content.Font = Enum.Font.SourceSans
content.TextSize = 16
content.TextColor3 = Color3.new(1, 1, 1)
content.TextWrapped = true
content.Parent = frame

local playOnceBtn = Instance.new("TextButton")
playOnceBtn.Size = UDim2.new(0, 110, 0, 40)
playOnceBtn.Position = UDim2.new(0.5, -190, 1, -80)
playOnceBtn.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
playOnceBtn.Text = "播放单次"
playOnceBtn.Font = Enum.Font.SourceSansBold
playOnceBtn.TextSize = 16
playOnceBtn.TextColor3 = Color3.new(1, 1, 1)
playOnceBtn.Parent = frame

local authorLabel = Instance.new("TextLabel")
authorLabel.Size = UDim2.new(0, 110, 0, 20)
authorLabel.Position = UDim2.new(0.5, -55, 1, -125)
authorLabel.BackgroundTransparency = 1
authorLabel.Text = "脚本BY：白羽"
authorLabel.Font = Enum.Font.SourceSansItalic
authorLabel.TextSize = 12
authorLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
authorLabel.Parent = frame

local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(0, 110, 0, 40)
cancelBtn.Position = UDim2.new(0.5, -55, 1, -80)
cancelBtn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
cancelBtn.Text = "取消"
cancelBtn.Font = Enum.Font.SourceSansBold
cancelBtn.TextSize = 16
cancelBtn.TextColor3 = Color3.new(1, 1, 1)
cancelBtn.Parent = frame

local loopPlayBtn = Instance.new("TextButton")
loopPlayBtn.Size = UDim2.new(0, 110, 0, 40)
loopPlayBtn.Position = UDim2.new(0.5, 80, 1, -80)
loopPlayBtn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.6)
loopPlayBtn.Text = "循环播放"
loopPlayBtn.Font = Enum.Font.SourceSansBold
loopPlayBtn.TextSize = 16
loopPlayBtn.TextColor3 = Color3.new(1, 1, 1)
loopPlayBtn.Parent = frame

local volumeLabel = Instance.new("TextLabel")
volumeLabel.Size = UDim2.new(0, 80, 0, 20)
volumeLabel.Position = UDim2.new(0.5, -120, 1, -35)
volumeLabel.BackgroundTransparency = 1
volumeLabel.Text = "音量："
volumeLabel.Font = Enum.Font.SourceSansBold
volumeLabel.TextSize = 14
volumeLabel.TextColor3 = Color3.new(1, 1, 1)
volumeLabel.Parent = frame

local volumeInput = Instance.new("TextBox")
volumeInput.Size = UDim2.new(0, 80, 0, 25)
volumeInput.Position = UDim2.new(0.5, -30, 1, -38)
volumeInput.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
volumeInput.BorderColor3 = Color3.new(0.8, 0.2, 0.2)
volumeInput.Text = "3"
volumeInput.Font = Enum.Font.SourceSans
volumeInput.TextSize = 14
volumeInput.TextColor3 = Color3.new(1, 1, 1)
volumeInput.PlaceholderText = "输入音量"
volumeInput.ClearTextOnFocus = false
volumeInput.Parent = frame

volumeInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local num = tonumber(volumeInput.Text)
        if num then
            num = math.clamp(num, 0, 10)
            sound.Volume = num
            volumeInput.Text = tostring(num)
        else
            volumeInput.Text = "3"
            sound.Volume = 3
        end
    end
end)

playOnceBtn.MouseButton1Click:Connect(function()
    local num = tonumber(volumeInput.Text) or 3
    sound.Volume = num
    sound.Looped = false
    sound:Stop()
    sound:Play()
    screenGui:Destroy()
end)

loopPlayBtn.MouseButton1Click:Connect(function()
    local num = tonumber(volumeInput.Text) or 3
    sound.Volume = num
    sound.Looped = true
    sound:Stop()
    sound:Play()
    screenGui:Destroy()
    
    StarterGui:SetCore("SendNotification", {
        Title = "循环播放", 
        Text = "循环播放开启\n重进来取消",
        Duration = 8,
        Icon = "rbxassetid://0"
    })
end)

cancelBtn.MouseButton1Click:Connect(function()
    sound:Stop()
    screenGui:Destroy()
end)
