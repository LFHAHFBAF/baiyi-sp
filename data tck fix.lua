-- 专属自我治疗（长按X触发）- 独立脚本
-- 放置位置：StarterPlayerScripts 或 StarterCharacterScripts

-- 1. 获取核心服务和对象
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 2. 初始化核心变量（独立脚本需自行获取，无需依赖外部变量）
local Character = nil
local CooldownFolder = nil
local Humanoid = nil
local mouse = LocalPlayer:GetMouse()
local isSelfHealing = false  -- 替代原有var9_upvw，标记是否正在自我治疗
local healLoop = nil  -- 新增：治疗循环变量，用于控制长按持续发送请求
game.ReplicatedStorage.HoldSkill3.OnClientInvoke = function() return isSelfHealing end  -- 服务器查这个值，必须加

-- 新增：移动端按钮相关变量（适配手机）
local mobileGui = nil
local healButton = nil

-- 3. 等待角色加载 + 监听角色变化（防止角色销毁后脚本失效）
local function setupCharacter()
    -- 等待角色加载完成
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    -- 等待冷却文件夹加载
    CooldownFolder = Character:WaitForChild("CooldownFolder", 10)
    -- 等待人形对象加载
    Humanoid = Character:WaitForChild("Humanoid", 10)
    
    -- 新增↓↓↓ 角色死亡监听（核心：死亡时停止治疗+销毁脚本）
    Humanoid.Died:Connect(function()
        isSelfHealing = false  -- 立即停止治疗状态
        if healLoop then task.cancel(healLoop) end  -- 终止治疗循环
        if healButton then healButton:Destroy() end  -- 销毁移动端按钮
        script:Destroy()  -- 销毁当前脚本，避免残留
        print("角色死亡，自我治疗脚本已销毁")
    end)
    
    -- 原有逻辑不动↓↓↓
    -- 监听人形对象销毁
    Humanoid.Destroying:Connect(function()
        isSelfHealing = false
    end)
    -- 监听角色销毁，重建后重新初始化
    Character.Destroying:Connect(function()
        isSelfHealing = false
        setupCharacter()  -- 角色重建后重新初始化
    end)

    -- 新增↓↓↓ 检测移动端并创建按钮
    if UserInputService.TouchEnabled then
        setupMobileButton()
    end
end

-- 新增↓↓↓ 移动端按钮创建函数（适配手机）
local function setupMobileButton()
    -- 获取/创建移动端UI容器
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local mobileSupport = playerGui:FindFirstChild("MobileSupport")
    if not mobileSupport then
        mobileSupport = Instance.new("ScreenGui")
        mobileSupport.Name = "MobileSupport"
        mobileSupport.Parent = playerGui

        -- 创建按钮容器（右下角）
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "Main"
        mainFrame.Size = UDim2.new(0, 200, 0, 200)
        mainFrame.Position = UDim2.new(1, -220, 1, -220)
        mainFrame.BackgroundTransparency = 1
        mainFrame.Parent = mobileSupport
    end

    -- 创建自我治疗按钮（X键）
    healButton = Instance.new("TextButton")
    healButton.Name = "XButton"
    healButton.Size = UDim2.new(0, 80, 0, 80)
    healButton.Position = UDim2.new(0, 0, 0, 0)
    healButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    healButton.Text = "X\n自我治疗"
    healButton.TextColor3 = Color3.new(1,1,1)
    healButton.Font = Enum.Font.SourceSansBold
    healButton.TextSize = 16
    -- 按钮圆角（美观）
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 40)
    corner.Parent = healButton
    healButton.Parent = mobileSupport.Main

    -- 绑定按钮长按逻辑
    healButton.MouseButton1Down:Connect(function()
        startSelfHeal()
        healButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200) -- 按下变深
    end)
    healButton.MouseButton1Up:Connect(function()
        stopSelfHeal()
        healButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- 松开恢复
    end)
    healButton.MouseLeave:Connect(function()
        stopSelfHeal()
        healButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- 移开恢复
    end)

    print("移动端自我治疗按钮已创建")
end

-- 首次执行角色初始化（删掉了重复的那一行）
setupCharacter()

-- 4. 开始自我治疗逻辑（按下X时执行，修改为持续发送请求）
local function startSelfHeal()
    -- 防重复触发
    if isSelfHealing then return end
    
    -- 核心校验（保留原有逻辑）
    if CooldownFolder and CooldownFolder:FindFirstChild("SelfHeal_Cooldown") then
        if CooldownFolder.SelfHeal_Cooldown.Value == true then
            warn("专属自我治疗正在冷却中！")
            return
        end
    else
        warn("未找到SelfHeal_Cooldown冷却变量！")
        return
    end
    
    if CooldownFolder and CooldownFolder:FindFirstChild("ActiveM1") then
        if CooldownFolder.ActiveM1.Value == true then
            warn("正在普通攻击，无法触发自我治疗！")
            return
        end
    end
    
    if not Character or not Humanoid or Humanoid.Health <= 0 then
        warn("角色无效或已死亡，无法触发自我治疗！")
        return
    end
    
    -- 标记治疗状态
    isSelfHealing = true
    print("专属自我治疗已开始，长按期间持续治疗")
    
    -- 新增↓↓↓ 循环发送治疗请求（每0.1秒1次，可调整）
    healLoop = task.spawn(function()
        while isSelfHealing and Humanoid.Health > 0 do
            local selfHealEvent = ReplicatedStorage:FindFirstChild("SelfHealTitanClockMan")
            if selfHealEvent then
                selfHealEvent:FireServer(mouse.Hit.Position)
            end
            task.wait(0.1) -- 发送间隔，别太小（避免服务器卡顿）
        end
    end)
end

-- 5. 停止自我治疗逻辑（松开X时执行，新增终止循环）
local function stopSelfHeal()
    if not isSelfHealing then return end
    
    -- 新增↓↓↓ 终止治疗循环
    if healLoop then
        task.cancel(healLoop)
        healLoop = nil
    end
    
    -- 重置本地治疗状态
    isSelfHealing = false
    print("专属自我治疗已停止")
    
    -- 可选：若服务器需要接收“停止治疗”指令，取消下面注释
    -- local stopSelfHealEvent = ReplicatedStorage:FindFirstChild("StopSelfHealTitanClockMan")
    -- if stopSelfHealEvent then
    --     stopSelfHealEvent:FireServer()
    -- end
end

-- 6. 绑定长按X键的输入监听
-- 监听按键按下（开始治疗）
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.X then
        startSelfHeal()
    end
end)

-- 监听按键松开（停止治疗）
UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.X then
        stopSelfHeal()
    end
end)

print("专属自我治疗脚本已加载完成，长按X键触发治疗，松开停止！")
