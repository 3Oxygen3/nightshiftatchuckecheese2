local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local npcFolder = workspace:WaitForChild("Npc")
local chams, itemChams, originalDurations = {}, {}, {}
local npcNames = {"ChuckMove", "HenMove", "JasperMove", "MunchMove", "PasquallyMove", "MascotMove", "BillyMove"}
local itemNames = {
    "Backstage Key", "Closet Key", "Emergency_Exit", "Gas Can",
    "Manager's Office Key", "Parts&Service", "VHS Tape", "VHS Tape 2"
}
local itemESPEnabled, noclipEnabled, flyEnabled = false, false, false
local character, humanoid, bodyVelocity, bodyGyro
local walkspeedValue = 16
local originalBrightness, originalAmbient = Lighting.Brightness, Lighting.Ambient

local Window = ReGui:TabsWindow({ Title = "NightShift GUI V2", Size = UDim2.fromOffset(185, 225) })
local TabNames = {"Game", "Other and Credits"}

local function addCham(model)
    if chams[model] then return end
    local success, highlight = pcall(function()
        local h = Instance.new("Highlight")
        h.FillColor = Color3.fromRGB(255, 0, 0)
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.FillTransparency = 0.5
        h.OutlineTransparency = 0
        h.Adornee = model
        h.Parent = game:GetService("CoreGui")
        return h
    end)
    if success and highlight then chams[model] = highlight end
end

local function removeCham(model)
    if chams[model] then chams[model]:Destroy() chams[model] = nil end
end

local function toggleESP(enabled)
    for _, name in ipairs(npcNames) do
        local model = npcFolder:FindFirstChild(name)
        if model then
            if enabled then addCham(model) else removeCham(model) end
        end
    end
end

local function getItemColor(name)
    if name:lower():find("key") or name == "Parts&Service" then
        return Color3.fromRGB(0, 255, 0)
    elseif name:lower():find("vhs") then
        return Color3.fromRGB(180, 0, 255)
    else
        return Color3.fromRGB(0, 180, 255)
    end
end

local function addItemCham(item)
    if itemChams[item] then return end
    local success, highlight = pcall(function()
        local h = Instance.new("Highlight")
        h.FillColor = getItemColor(item.Name)
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.FillTransparency = 0.5
        h.OutlineTransparency = 0
        h.Adornee = item
        h.Parent = game:GetService("CoreGui")
        return h
    end)
    if success and highlight then
        itemChams[item] = highlight
        item.AncestryChanged:Connect(function(_, parent)
            if not parent then removeItemCham(item) end
        end)
    end
end

local function removeItemCham(item)
    if itemChams[item] then itemChams[item]:Destroy() itemChams[item] = nil end
end

local function updateItemESP()
    for _, name in ipairs(itemNames) do
        local success, item = pcall(function()
            return workspace:FindFirstChild(name, true)
        end)
        if success and item then
            if itemESPEnabled then addItemCham(item) else removeItemCham(item) end
        end
    end
end

local function toggleItemESP(enabled)
    itemESPEnabled = enabled
    updateItemESP()
end

workspace.DescendantAdded:Connect(function(desc)
    if itemESPEnabled and table.find(itemNames, desc.Name) then
        task.wait()
        addItemCham(desc)
    end
end)

local function toggleDarkness(removeDarkness)
    Lighting.Brightness = removeDarkness and 2 or originalBrightness
    Lighting.Ambient = removeDarkness and Color3.fromRGB(180, 180, 180) or originalAmbient
end

RunService.Stepped:Connect(function()
    if humanoid and humanoid.Parent and humanoid.WalkSpeed ~= walkspeedValue then
        humanoid.WalkSpeed = walkspeedValue
    end
end)

local function setWalkSpeed(speed)
    walkspeedValue = speed
end

local function toggleNoclip(state)
    noclipEnabled = state
end

RunService.Heartbeat:Connect(function()
    if noclipEnabled and character then
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

local function toggleFly(enabled)
    flyEnabled = enabled
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character:FindFirstChild("HumanoidRootPart")

    if enabled then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bodyVelocity.Parent = root

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bodyGyro.CFrame = root.CFrame
        bodyGyro.Parent = root

        RunService:BindToRenderStep("Fly", Enum.RenderPriority.Character.Value + 1, function()
            if not flyEnabled then return end
            local moveVec = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec += workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec -= workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec -= workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec += workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVec -= Vector3.new(0, 1, 0) end

            bodyVelocity.Velocity = moveVec.Magnitude > 0 and moveVec.Unit * 50 or Vector3.zero
            bodyGyro.CFrame = workspace.CurrentCamera.CFrame
        end)
    else
        RunService:UnbindFromRenderStep("Fly")
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
    end
end

local function toggleInstantProximity(enabled)
    if enabled then
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                originalDurations[prompt] = prompt.HoldDuration
                prompt.HoldDuration = 0
            end
        end
        originalDurations.Connection = workspace.DescendantAdded:Connect(function(desc)
            if desc:IsA("ProximityPrompt") then
                task.wait()
                originalDurations[desc] = desc.HoldDuration
                desc.HoldDuration = 0
            end
        end)
    else
        for prompt, duration in pairs(originalDurations) do
            if typeof(prompt) == "Instance" and prompt:IsA("ProximityPrompt") then
                prompt.HoldDuration = duration
            end
        end
        if originalDurations.Connection then originalDurations.Connection:Disconnect() end
        originalDurations = {}
    end
end

local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    humanoid.WalkSpeed = walkspeedValue

    humanoid.Died:Connect(function()
        toggleFly(false)
        toggleNoclip(false)
    end)
end

setupCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
LocalPlayer.CharacterAdded:Connect(setupCharacter)

for _, Name in ipairs(TabNames) do
    local Tab = Window:CreateTab({ Name = Name })

    if Name == "Game" then
        Tab:Checkbox({ Label = "Instant Open Door\n/Clean Table", Value = false, Callback = function(_, v) toggleInstantProximity(v) end })
        Tab:Checkbox({ Label = "Animatronic ESP", Value = false, Callback = function(_, v) toggleESP(v) end })
        Tab:Checkbox({ Label = "Item ESP", Value = false, Callback = function(_, v) toggleItemESP(v) end })
        Tab:Checkbox({ Label = "Fullbright", Value = false, Callback = function(_, v) toggleDarkness(v) end })
        Tab:Checkbox({ Label = "Noclip", Value = false, Callback = function(_, v) toggleNoclip(v) end })
        Tab:Checkbox({ Label = "Fly", Value = false, Callback = function(_, v) toggleFly(v) end })
        Tab:SliderInt({
            Label = "WalkSpeed",
            Value = 16,
            Minimum = 8,
            Maximum = 100,
            Callback = function(_, v) setWalkSpeed(v) end
        })

    elseif Name == "Other and Credits" then
        Tab:Button({
            Text = "Infinite Yield",
            Callback = function()
                pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
                end)
            end
        })
        Tab:Button({
            Text = "Dex++",
            Callback = function()
                pcall(function()
                    loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
                end)
            end
        })
        Tab:Label({
            Text = "Script made with \nDear-ReGUI \nMade By 3Oxy"
        })
    end
end
