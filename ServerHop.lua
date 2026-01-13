local PlaceID = game.PlaceId
local AllIDs = {}
local foundAnything = ""
local actualHour = os.date("!*t").hour
local hopActive = false
local timerActive = false

-- Validate that this script is only running in Blox Fruits
local GAME_ID = 7449423635 -- Blox Fruits main game ID
if PlaceID ~= GAME_ID then
	error("This server hopper is exclusive to Blox Fruits (Game ID: " .. GAME_ID .. "). Current game ID: " .. PlaceID)
end

local File = pcall(function()
    AllIDs = game:GetService('HttpService'):JSONDecode(readfile("NotSameServers.json"))
end)
if not File then
    table.insert(AllIDs, actualHour)
    writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
end

-- Create Modern GUI
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerHopperGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main Frame (Modern Dark Theme)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BorderSizePixel = 0
mainFrame.CornerRadius = UDim.new(0, 12)
mainFrame.Parent = screenGui

-- Add shadow effect with UIStroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 120, 215)
stroke.Thickness = 2
stroke.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.TextWeight = Enum.FontWeight.Bold
title.Text = "⚡ Server Hopper"
title.BorderSizePixel = 0
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = title

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 50)
statusLabel.Position = UDim2.new(0, 10, 0, 50)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.TextSize = 14
statusLabel.Text = "Status: Ready"
statusLabel.BorderSizePixel = 0
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Timer Label
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, -20, 0, 35)
timerLabel.Position = UDim2.new(0, 10, 0, 105)
timerLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
timerLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
timerLabel.TextSize = 13
timerLabel.Text = "Timer: --"
timerLabel.BorderSizePixel = 0
timerLabel.Font = Enum.Font.Gotham
timerLabel.TextXAlignment = Enum.TextXAlignment.Center
timerLabel.Parent = mainFrame

-- Start Button
local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(0.45, -5, 0, 35)
startButton.Position = UDim2.new(0, 10, 0, 155)
startButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextSize = 14
startButton.Text = "▶ Start"
startButton.BorderSizePixel = 0
startButton.Font = Enum.Font.GothamBold
startButton.Parent = mainFrame

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 8)
startCorner.Parent = startButton

-- Stop Button
local stopButton = Instance.new("TextButton")
stopButton.Name = "StopButton"
stopButton.Size = UDim2.new(0.45, -5, 0, 35)
stopButton.Position = UDim2.new(0.55, 0, 0, 155)
stopButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.TextSize = 14
stopButton.Text = "⏹ Stop"
stopButton.BorderSizePixel = 0
stopButton.Font = Enum.Font.GothamBold
stopButton.Visible = false
stopButton.Parent = mainFrame

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 8)
stopCorner.Parent = stopButton

-- Add hover effects
local function addHoverEffect(button)
	local originalColor = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(
			math.min(originalColor.R * 255 + 20, 255) / 255,
			math.min(originalColor.G * 255 + 20, 255) / 255,
			math.min(originalColor.B * 255 + 20, 255) / 255
		)
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = originalColor
	end)
end

addHoverEffect(startButton)
addHoverEffect(stopButton)

function TPReturner()
    local Site;
    if foundAnything == "" then
        Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
    else
        Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
    end
    local ID = ""
    if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
        foundAnything = Site.nextPageCursor
    end
    local num = 0;
    for i,v in pairs(Site.data) do
        local Possible = true
        ID = tostring(v.id)
        if tonumber(v.maxPlayers) > tonumber(v.playing) then
            for _,Existing in pairs(AllIDs) do
                if num ~= 0 then
                    if ID == tostring(Existing) then
                        Possible = false
                    end
                else
                    if tonumber(actualHour) ~= tonumber(Existing) then
                        local delFile = pcall(function()
                            delfile("NotSameServers.json")
                            AllIDs = {}
                            table.insert(AllIDs, actualHour)
                        end)
                    end
                end
                num = num + 1
            end
            if Possible == true and hopActive then
                table.insert(AllIDs, ID)
                wait()
                pcall(function()
                    writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
                    wait()
                    game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, game.Players.LocalPlayer)
                end)
                wait(4)
            end
        end
    end
end

function startHopping()
    hopActive = true
    timerActive = true
    startButton.Visible = false
    stopButton.Visible = true
    statusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
    
    -- 10 second timer
    for i = 10, 0, -1 do
        if not timerActive then return end
        timerLabel.Text = "Timer: " .. i .. "s"
        statusLabel.Text = "Status: Hopping in " .. i .. "s..."
        wait(1)
    end
    
    if timerActive then
        statusLabel.Text = "Status: Hopping..."
        timerLabel.Text = "Timer: Hopping..."
        while hopActive and timerActive do
            pcall(function()
                TPReturner()
                if foundAnything ~= "" then
                    TPReturner()
                end
            end)
        end
    end
end

startButton.MouseButton1Click:Connect(function()
    startHopping()
end)

stopButton.MouseButton1Click:Connect(function()
    hopActive = false
    timerActive = false
    startButton.Visible = true
    stopButton.Visible = false
    timerLabel.Text = "Timer: --"
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusLabel.Text = "Status: Stopped"
end)