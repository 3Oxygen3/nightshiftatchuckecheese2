local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()

local Window = ReGui:TabsWindow({
    Title = "Night Shift At ChuckECheeses 2 GUI V1",
    Size = UDim2.fromOffset(400, 300)
})

local TabNames = {"Game", "Other and Credits"}

local npcNames = {"ChuckMove", "HenMove", "JasperMove", "MunchMove", "PasquallyMove"}
local npcFolder = workspace:WaitForChild("Npc")
local chams = {}

local Lighting = game:GetService("Lighting")
local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local function addCham(model)
    if chams[model] then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = model
    highlight.Parent = game.CoreGui
    chams[model] = highlight
end

local function removeCham(model)
    if chams[model] then
        chams[model]:Destroy()
        chams[model] = nil
    end
end

local function toggleESP(enabled)
    for _, name in ipairs(npcNames) do
        local model = npcFolder:FindFirstChild(name)
        if model then
            if enabled then addCham(model) else removeCham(model) end
        end
    end
end

local function toggleDarkness(removeDarkness)
    if removeDarkness then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
    else
        Lighting.Brightness = originalBrightness
        Lighting.Ambient = originalAmbient
    end
end

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local walkspeedValue = 16

local function setWalkSpeed(speed)
    walkspeedValue = speed
    if humanoid and humanoid.Parent then
        humanoid.WalkSpeed = speed
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = walkspeedValue
end)

local noclipEnabled = false
RunService.Heartbeat:Connect(function()
    if noclipEnabled and character then
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

local function toggleNoclip(enabled)
    noclipEnabled = enabled
end

local flyEnabled, flying = false, false
local bodyVelocity, bodyGyro

local function toggleFly(enabled)
    flyEnabled = enabled
    if enabled then
        if not character or not character.Parent then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bodyVelocity.Parent = root

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bodyGyro.CFrame = root.CFrame
        bodyGyro.Parent = root

        flying = true

        RunService:BindToRenderStep("Fly", Enum.RenderPriority.Character.Value + 1, function()
            if not flying then return end
            local moveVec = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec += workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec -= workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec -= workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec += workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVec -= Vector3.new(0, 1, 0) end

            bodyVelocity.Velocity = moveVec.Unit * 50
            bodyGyro.CFrame = workspace.CurrentCamera.CFrame
        end)
    else
        flying = false
        RunService:UnbindFromRenderStep("Fly")
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
    end
end

local instantProximityConn
local originalDurations = {}

local function toggleInstantProximity(enabled)
    if enabled then
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                originalDurations[prompt] = prompt.HoldDuration
                prompt.HoldDuration = 0
            end
        end
        instantProximityConn = workspace.DescendantAdded:Connect(function(desc)
            if desc:IsA("ProximityPrompt") then
                task.wait()
                originalDurations[desc] = desc.HoldDuration
                desc.HoldDuration = 0
            end
        end)
    else
        for prompt, duration in pairs(originalDurations) do
            if prompt and prompt.Parent then prompt.HoldDuration = duration end
        end
        originalDurations = {}
        if instantProximityConn then instantProximityConn:Disconnect() instantProximityConn = nil end
    end
end

for _, Name in ipairs(TabNames) do
    local Tab = Window:CreateTab({Name = Name})

    if Name == "Game" then
        Tab:Checkbox({
            Label = "Instant Clean Table",
            Value = false,
            Callback = function(self, value) toggleInstantProximity(value) end
        })
        Tab:Checkbox({
            Label = "Animatronic ESP",
            Value = false,
            Callback = function(self, value) toggleESP(value) end
        })
        Tab:Checkbox({
            Label = "Fullbright",
            Value = false,
            Callback = function(self, value) toggleDarkness(value) end
        })
        Tab:Checkbox({
            Label = "Noclip",
            Value = false,
            Callback = function(self, value) toggleNoclip(value) end
        })
        Tab:Checkbox({
            Label = "Fly",
            Value = false,
            Callback = function(self, value) toggleFly(value) end
        })
        Tab:SliderInt({
            Label = "WalkSpeed",
            Value = 16,
            Minimum = 8,
            Maximum = 100,
            Callback = function(self, value) setWalkSpeed(value) end
        })

    elseif Name == "Other and Credits" then
        Tab:Button({
            Text = "Infinite Yield",
            Callback = function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
            end
        })
        Tab:Button({
            Text = "Dex++",
            Callback = function()
                loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
            end
        })
        Tab:Label({
            Text = "Script made with Dear-ReGUI, made by coldsaucee on discord, early version"
        })
    end
end
