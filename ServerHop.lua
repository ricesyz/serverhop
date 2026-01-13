local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Load via: loadstring(game:HttpGet("https://raw.githubusercontent.com/ricesyz/serverhop/refs/heads/main/ServerHop.lua"))()

-- Ensure this runs only on the client (LocalScript)
if not game:GetService("RunService"):IsClient() then
	error("This script must be a LocalScript running on the client!")
end

local GAME_ID = game.PlaceId
local AllIDs = {}
local foundAnything = ""
local actualHour = os.date("!*t").hour

-- Load previous server IDs
local File = pcall(function()
	AllIDs = game:GetService('HttpService'):JSONDecode(readfile("NotSameServers.json"))
end)
if not File then
	table.insert(AllIDs, actualHour)
	writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
end

local hopActive = false
local timeRemaining = 10

-- Create GUI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerHopGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 150)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Text = "Server Hop"
title.BorderSizePixel = 0
title.Parent = mainFrame

-- Timer Label
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, 0, 0, 40)
timerLabel.Position = UDim2.new(0, 0, 0, 35)
timerLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
timerLabel.TextSize = 14
timerLabel.Text = "Ready"
timerLabel.BorderSizePixel = 0
timerLabel.Parent = mainFrame

-- Start Button
local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(1, -10, 0, 35)
startButton.Position = UDim2.new(0, 5, 0, 110)
startButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextSize = 14
startButton.Text = "Start Hop"
startButton.BorderSizePixel = 0
startButton.Parent = mainFrame

-- Stop Button
local stopButton = Instance.new("TextButton")
stopButton.Name = "StopButton"
stopButton.Size = UDim2.new(0, 0, 0, 35)
stopButton.Position = UDim2.new(0, 5, 0, 110)
stopButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.TextSize = 14
stopButton.Text = "Stop"
stopButton.BorderSizePixel = 0
stopButton.Visible = false
stopButton.Parent = mainFrame

-- Server hopping function (defined after GUI creation so timerLabel exists)
local function TPReturner()
	local Site
	if foundAnything == "" then
		Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. GAME_ID .. '/servers/Public?sortOrder=Asc&limit=100'))
	else
		Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. GAME_ID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
	end
	local ID = ""
	if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
		foundAnything = Site.nextPageCursor
	end
	local num = 0
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
			if Possible == true then
				table.insert(AllIDs, ID)
				wait()
				pcall(function()
					writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
					wait()
					timerLabel.Text = "Hopping..."
					game:GetService("TeleportService"):TeleportToPlaceInstance(GAME_ID, ID, game.Players.LocalPlayer)
				end)
				wait(4)
				return true
			end
		end
	end
	return false
end

local function hopServer()
	print("Attempting to server hop...")
	timerLabel.Text = "Hopping..."
	
	local success = pcall(function()
		TPReturner()
		if foundAnything ~= "" then
			TPReturner()
		end
	end)
	
	if not success then
		warn("Teleport failed")
		timerLabel.Text = "Teleport failed"
	else
		print("Teleport initiated")
	end
end

-- Start button clicked
startButton.MouseButton1Click:Connect(function()
	hopActive = true
	timeRemaining = 10
	startButton.Visible = false
	stopButton.Visible = true
	
	for i = 10, 0, -1 do
		if not hopActive then break end
		timeRemaining = i
		local minutes = math.floor(i / 60)
		local seconds = i % 60
		timerLabel.Text = string.format("Hopping in: %d:%02d", minutes, seconds)
		wait(1)
	end
	
	if hopActive then
		hopServer()
		hopActive = false
		startButton.Visible = true
		stopButton.Visible = false
		timerLabel.Text = "Ready"
	end
end)

-- Stop button clicked
stopButton.MouseButton1Click:Connect(function()
	hopActive = false
	startButton.Visible = true
	stopButton.Visible = false
	timerLabel.Text = "Cancelled"
	wait(1)
	timerLabel.Text = "Ready"
end)