-- 专属自我治疗（长按X触发）- 独立脚本（手机已修复）
-- 放置位置：StarterPlayerScripts 或 StarterCharacterScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Character = nil
local CooldownFolder = nil
local Humanoid = nil
local mouse = LocalPlayer:GetMouse()
local isSelfHealing = false
local healLoop = nil

-- 服务器状态同步
game.ReplicatedStorage.HoldSkill3.OnClientInvoke = function()
    return isSelfHealing
end

-- 移动端按钮函数（放最前面，手机才能识别）
local mobileGui = nil
local healButton = nil

local function setupMobileButton()
    task.wait(0.5) -- 延迟加载，避免手机UI没好
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return end

    local mobileSupport = playerGui:FindFirstChild("MobileSupport")
    if not mobileSupport then
        mobileSupport = Instance.new("ScreenGui")
        mobileSupport.Name = "MobileSupport"
        mobileSupport.Parent = playerGui
    end

    local mainFrame = mobileSupport:FindFirstChild("Main")
    if not mainFrame then
        mainFrame = Instance.new("Frame")
        mainFrame.Name = "Main"
        mainFrame.Size = UDim2.new(0, 200, 0, 200)
        mainFrame.Position = UDim2.new(1, -220, 1, -220)
        mainFrame.BackgroundTransparency = 1
        mainFrame.Parent = mobileSupport
    end

    if healButton then healButton:Destroy() end
    healButton = Instance.new("TextButton")
    healButton.Name = "XButton"
    healButton.Size = UDim2.new(0, 80, 0, 80)
    healButton.Position = UDim2.new(0, 0, 0, 0)
    healButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    healButton.Text = "治疗"
    healButton.TextColor3 = Color3.new(1,1,1)
    healButton.Font = Enum.Font.SourceSansBold
    healButton.TextSize = 20

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 40)
    corner.Parent = healButton
    healButton.Parent = mainFrame

    -- 手机长按核心
    healButton.MouseButton1Down:Connect(function()
        startSelfHeal()
    end)
    healButton.MouseButton1Up:Connect(function()
        stopSelfHeal()
    end)
    healButton.MouseLeave:Connect(function()
        stopSelfHeal()
    end)

    print("手机治疗按钮加载成功")
end

-- 角色加载
local function setupCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    CooldownFolder = Character:WaitForChild("CooldownFolder", 10)
    Humanoid = Character:WaitForChild("Humanoid", 10)

    -- 死亡销毁
    Humanoid.Died:Connect(function()
        isSelfHealing = false
        if healLoop then task.cancel(healLoop) end
        if healButton then healButton:Destroy() end
        script:Destroy()
    end)

    Humanoid.Destroying:Connect(function()
        isSelfHealing = false
    end)

    Character.Destroying:Connect(function()
        isSelfHealing = false
        setupCharacter()
    end)

    -- 手机才创建按钮
    if UserInputService.TouchEnabled then
        setupMobileButton()
    end
end

-- 开始治疗（长按持续）
function startSelfHeal()
    if isSelfHealing then return end

    if CooldownFolder
    and CooldownFolder:FindFirstChild("SelfHeal_Cooldown")
    and CooldownFolder.SelfHeal_Cooldown.Value == true then
        return
    end

    if CooldownFolder
    and CooldownFolder:FindFirstChild("ActiveM1")
    and CooldownFolder.ActiveM1.Value == true then
        return
    end

    if not Character or not Humanoid or Humanoid.Health <= 0 then
        return
    end

    isSelfHealing = true

    healLoop = task.spawn(function()
        while isSelfHealing and Humanoid.Health > 0 do
            local evt = ReplicatedStorage:FindFirstChild("SelfHealTitanClockMan")
            if evt then
                evt:FireServer(mouse.Hit.Position)
            end
            task.wait(0.15)
        end
    end)
end

-- 停止治疗
function stopSelfHeal()
    if not isSelfHealing then return end
    isSelfHealing = false
    if healLoop then
        task.cancel(healLoop)
        healLoop = nil
    end
end

-- PC按键X
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.X then
        startSelfHeal()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.X then
        stopSelfHeal()
    end
end)

setupCharacter()
print("自我治疗脚本加载完成（手机已修复）")
