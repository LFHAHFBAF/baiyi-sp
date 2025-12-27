local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UIS = game:GetService("UserInputService")

local localEvacuate = false
local localIsActivated = false

local upwardForce
local downwardForce
local horizontalLock
local isApplyingUpward = false

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ControlPanel"
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainPanel"
MainFrame.Size = UDim2.new(0, 500, 0, 200)
MainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
MainFrame.BorderColor3 = Color3.new(0, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Parent = ScreenGui

local WarningLabel = Instance.new("TextLabel")
WarningLabel.Name = "Warning"
WarningLabel.Size = UDim2.new(0.48, 0, 0.4, 0)
WarningLabel.Position = UDim2.new(0.01, 0, 0.01, 0)
WarningLabel.BackgroundTransparency = 1
WarningLabel.Text = "在进入游戏后再点击启动\n启动后跳一下"
WarningLabel.TextColor3 = Color3.new(1, 0, 0)
WarningLabel.TextScaled = true
WarningLabel.TextWrapped = true
WarningLabel.Parent = MainFrame

local ButtonFrame = Instance.new("Frame")
ButtonFrame.Name = "Buttons"
ButtonFrame.Size = UDim2.new(0.48, 0, 0.4, 0)
ButtonFrame.Position = UDim2.new(0.01, 0, 0.42, 0)
ButtonFrame.BackgroundTransparency = 1
ButtonFrame.Parent = MainFrame

local StartBtn = Instance.new("TextButton")
StartBtn.Name = "StartBtn"
StartBtn.Size = UDim2.new(0.48, 0, 1, 0)
StartBtn.Position = UDim2.new(0, 0, 0, 0)
StartBtn.BackgroundColor3 = Color3.new(0.1, 0.7, 0.1)
StartBtn.BorderColor3 = Color3.new(0, 0, 0)
StartBtn.Text = "启动脚本"
StartBtn.TextScaled = true
StartBtn.TextColor3 = Color3.new(1, 1, 1)
StartBtn.Parent = ButtonFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseUI"
CloseBtn.Size = UDim2.new(0.48, 0, 1, 0)
CloseBtn.Position = UDim2.new(0.52, 0, 0)
CloseBtn.BackgroundColor3 = Color3.new(0.7, 0.1, 0.1)
CloseBtn.BorderColor3 = Color3.new(0, 0, 0)
CloseBtn.Text = "关闭脚本"
CloseBtn.TextScaled = true
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Parent = ButtonFrame

local TipLabel = Instance.new("TextLabel")
TipLabel.Name = "CenterTip"
TipLabel.Size = UDim2.new(0.48, 0, 0.15, 0)
TipLabel.Position = UDim2.new(0.01, 0, 0.83, 0)
TipLabel.BackgroundTransparency = 1
TipLabel.Text = "请走到中心点再点击启动"
TipLabel.TextColor3 = Color3.new(1, 1, 0)
TipLabel.TextScaled = true
TipLabel.TextWrapped = true
TipLabel.Parent = MainFrame

local DebugFrame = Instance.new("Frame")
DebugFrame.Name = "DebugInfo"
DebugFrame.Size = UDim2.new(0.49, 0, 0.98, 0)
DebugFrame.Position = UDim2.new(0.5, 0, 0.01, 0)
DebugFrame.BackgroundTransparency = 1
DebugFrame.Parent = MainFrame

local DebugTitle = Instance.new("TextLabel")
DebugTitle.Name = "DebugTitle"
DebugTitle.Size = UDim2.new(1, 0, 0.16, 0)
DebugTitle.Position = UDim2.new(0, 0, 0)
DebugTitle.BackgroundTransparency = 1
DebugTitle.Text = "调试消息:"
DebugTitle.TextColor3 = Color3.new(1, 1, 1)
DebugTitle.TextScaled = true
DebugTitle.Parent = DebugFrame

local ModeLabel = Instance.new("TextLabel")
ModeLabel.Name = "Mode"
ModeLabel.Size = UDim2.new(1, 0, 0.16, 0)
ModeLabel.Position = UDim2.new(0, 0, 0.17, 0)
ModeLabel.BackgroundTransparency = 1
ModeLabel.TextColor3 = Color3.new(1, 1, 1)
ModeLabel.TextScaled = true
ModeLabel.Parent = DebugFrame

local WaveLabel = Instance.new("TextLabel")
WaveLabel.Name = "Wave"
WaveLabel.Size = UDim2.new(1, 0, 0.16, 0)
WaveLabel.Position = UDim2.new(0, 0, 0.34, 0)
WaveLabel.BackgroundTransparency = 1
WaveLabel.Text = "波浪:B1"
WaveLabel.TextColor3 = Color3.new(1, 1, 1)
WaveLabel.TextScaled = true
WaveLabel.Parent = DebugFrame

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Name = "Timer"
TimerLabel.Size = UDim2.new(1, 0, 0.16, 0)
TimerLabel.Position = UDim2.new(0, 0, 0.51, 0)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Text = "计时器:J1"
TimerLabel.TextColor3 = Color3.new(1, 1, 1)
TimerLabel.TextScaled = true
TimerLabel.Parent = DebugFrame

local EvacLabel = Instance.new("TextLabel")
EvacLabel.Name = "Evac"
EvacLabel.Size = UDim2.new(1, 0, 0.16, 0)
EvacLabel.Position = UDim2.new(0, 0, 0.68, 0)
EvacLabel.BackgroundTransparency = 1
EvacLabel.Text = "准备撤离?:Z1"
EvacLabel.TextColor3 = Color3.new(1, 1, 1)
EvacLabel.TextScaled = true
EvacLabel.Parent = DebugFrame

local ActivateLabel = Instance.new("TextLabel")
ActivateLabel.Name = "Activate"
ActivateLabel.Size = UDim2.new(1, 0, 0.16, 0)
ActivateLabel.Position = UDim2.new(0, 0, 0.85, 0)
ActivateLabel.BackgroundTransparency = 1
ActivateLabel.Text = "是否启动?:S1"
ActivateLabel.TextColor3 = Color3.new(1, 1, 1)
ActivateLabel.TextScaled = true
ActivateLabel.Parent = DebugFrame

local dragging = false
local dragOffset = Vector2.new()

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragOffset = input.Position - MainFrame.AbsolutePosition
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        MainFrame.Position = UDim2.new(
            0, input.Position.X - dragOffset.X,
            0, input.Position.Y - dragOffset.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local function clearAllConstraints()
    if upwardForce then
        upwardForce:Destroy()
        upwardForce = nil
    end
    if downwardForce then
        downwardForce:Destroy()
        downwardForce = nil
    end
    if horizontalLock then
        horizontalLock:Destroy()
        horizontalLock = nil
    end
    isApplyingUpward = false
end

CloseBtn.MouseButton1Click:Connect(function()
    clearAllConstraints()
    ScreenGui:Destroy()
end)

task.spawn(function()
    while ScreenGui.Parent do
        local modeVal = workspace:FindFirstChild("Mode")
        ModeLabel.Text = "模式:" .. (modeVal and modeVal.Value or "错误")
        
        local waveVal = workspace:FindFirstChild("Wave")
        WaveLabel.Text = "波浪:" .. (waveVal and waveVal.Value or "错误")
        
        local timerVal = workspace:FindFirstChild("TimerWave")
        TimerLabel.Text = "计时器:" .. (timerVal and timerVal.Value or "错误")
        
        EvacLabel.Text = "准备撤离?: " .. (localEvacuate and "是" or "否")
        ActivateLabel.Text = "是否启动?: " .. (localIsActivated and "是" or "否")
        
        task.wait(1)
    end
end)

local hasStarted = false
StartBtn.MouseButton1Click:Connect(function()
    if hasStarted then return end
    hasStarted = true

    localEvacuate = false
    localIsActivated = true

    local char = Player.Character or Player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid", 10)
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    
    if not (humanoid and hrp and hrp.Parent) then
        warn("无法获取角色关键部件，无法施加持续力")
        return
    end

    humanoid.PlatformStand = false

    local initialHorizontalPos = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
    horizontalLock = Instance.new("BodyPosition")
    horizontalLock.Name = "HorizontalPositionLock"
    horizontalLock.Parent = hrp
    horizontalLock.Position = Vector3.new(hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
    horizontalLock.MaxForce = Vector3.new(1e9, 0, 1e9)
    horizontalLock.D = 500
    horizontalLock.P = 1e6

    clearAllConstraints()
    isApplyingUpward = true
    horizontalLock = Instance.new("BodyPosition")
    horizontalLock.Name = "HorizontalPositionLock"
    horizontalLock.Parent = hrp
    horizontalLock.Position = Vector3.new(hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
    horizontalLock.MaxForce = Vector3.new(1e9, 0, 1e9)
    horizontalLock.D = 500
    horizontalLock.P = 1e6

    upwardForce = Instance.new("BodyForce")
    upwardForce.Name = "UpwardContinuousForce"
    upwardForce.Parent = hrp
    upwardForce.Force = Vector3.new(0, 10000, 0)

    task.spawn(function()
        while ScreenGui.Parent do
            local jeffrey = workspace:FindFirstChild("Jeffrey")
            if jeffrey then jeffrey:Destroy() end
            task.wait(0.25)
        end
    end)

    task.spawn(function()
        while ScreenGui.Parent do
            if not (hrp and hrp.Parent and humanoid) then
                clearAllConstraints()
                break
            end

            local waveVal = workspace:FindFirstChild("Wave")
            local timerVal = workspace:FindFirstChild("TimerWave")
            
            if waveVal and timerVal then
                local wave = waveVal.Value
                local timer = timerVal.Value

                if wave == 4 and not localEvacuate and timer == 5 then
                    localEvacuate = true
                end

                if wave == 4 and localEvacuate and timer < 5 then
                    if isApplyingUpward then
                        if upwardForce then
                            upwardForce:Destroy()
                            upwardForce = nil
                        end
                        downwardForce = Instance.new("BodyForce")
                        downwardForce.Name = "DownwardContinuousForce"
                        downwardForce.Parent = hrp
                        downwardForce.Force = Vector3.new(0, -10000, 0)
                        isApplyingUpward = false
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end)

Player.CharacterRemoving:Connect(function()
    clearAllConstraints()
end)
