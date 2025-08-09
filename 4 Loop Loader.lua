local Panel = script.Parent.Panel.MainPanel
local Hinge = script.Parent.Panel.Hinge.HingeConstraint
local Config = require(script.Parent.Parent.Parent.Config)

local previousFaults = {}

local InEvac = false

local InLevel

local MenuToOpen = ""

local UsersConfig = require(script.Parent.Parent.Parent.Users)

local ProgramConfig = require(script.Parent.Parent.Parent.Programming)
local UserMenus_Levels = ProgramConfig.MenuLevels

local PriorityList = ProgramConfig.Priority

local PanelConfig = require(script.Parent.PanelConfig)
local Functions = PanelConfig.Functions

local SpecOutputDevices_List_OrigPos

local newZoneInput = ""
local previousZone = ""

local MainsFault = false
local previousAmountOfFaults = 0

local OutputsDisabled = {}

local AmountOfZonesINTEST = 0

local zoneswithDisablements = {}

local FunctionToComplete = ""

local InvestDelayONCE = false
local inInvest = false

local ZonesInFault = 0

local FaultTable = {}

local ZoneLocations = require(script.Parent.Parent.Parent.ZoneLocations)

local viewMenu_Input = "Fires"
local viewMenu2_Input = "Panel"

local function removeLFromString(str)
	return string.gsub(str, "L", "")
end

local LoopDevicesOrigPos


local LoopSelectInput = "L1"
local LoopInfoInput = "View"

local testSelect_SoundersInput = "Without"
local testSelect_InTest = "Finish"

local ZoneFunction_Input = "AllInputs"

local DisablementMenu_Input = "ZoneInputs"

local OutputDisablement_Input = "AllOutputs"
local OutputDisablement2_Input = "FireProtection"

local PreAlarmCount = 0

local tools_Input = "Commission"
local Commission_Input1 = "Loops"
local Commission_Input2 = "Passwords"

local Investigation = Config.InvestigationDelay.Active
local InvestigationDelay = Config.InvestigationDelay.InvestigationTime

local InvesActive = false

local LCD = Panel.LCD.SurfaceGui
local LEDs = Panel.LEDs
local Buttons = Panel.Buttons

local Countdown

local InFault = false

local InTrouble = false

local Press = LCD.Parent.Press
local Fault = LCD.Parent.Fault
local Buzzer = LCD.Parent.Buzzer

local DevicesFolder = script.Parent.Parent.Parent.Devices

function adjustString(inputString)
	-- Split the input into parts (e.g., "1 Zone" and "More>")
	local numberPart, textPart = inputString:match("^(%S+ %S+)%s*(.*)")

	if not numberPart or not textPart then
		return inputString -- Return the original if the format doesn't match
	end

	-- Trim the text part to remove leading/trailing spaces
	local trimmedTextPart = textPart:match("^%s*(.-)%s*$")

	-- Calculate the difference in space length between the original text part and the trimmed part
	local spacesToRemove = #textPart - #trimmedTextPart

	-- If there are spaces to remove, reduce it by 1
	if spacesToRemove > 0 then
		trimmedTextPart = trimmedTextPart .. string.rep(" ", spacesToRemove - 1)
	end

	-- Rebuild the string with the unchanged number part and adjusted text part
	local adjustedString = numberPart .. " " .. trimmedTextPart

	return adjustedString
end

local AllOutputsDisabled = false
local AllSoundersDisabled = false
local AllBeaconsDisabled = false
local AllOtherRelaysDisabled = false

local FaultRoutingDisabled = false
local FireProtectionDisabled = false
local FireRoutingDisabled = false

local Whitelist = Config.Whitelist.Active
local GID = Config.Whitelist.GroupID
local GR = Config.Whitelist.GroupRank

local DelayInput = "NoInvestigation"

local DelayTime = Config.Delay

local DeviceID = script.Parent:GetAttribute("DeviceID")
local DeviceName = script.Parent:GetAttribute("DeviceName")
local DeviceZone = script.Parent:GetAttribute("DeviceZone")
local Password = script.Parent:GetAttribute("Password")

local DownClickCount_INPUT = 0
local UpClickCount_INPUT = 0

local UpClickCount_INPUT_DIS = 0

local SoundersDisableList = 0

local LoggedIn = false

local InTest = false
local Test_Input = "Zones"

local L2_Input = ""

local InAlarm = false
local InClassChange = false

local MenuInput = "Enable_Controls"
local Level2MenuInput = "View"

local Panels = script.Parent.Parent

local DisabledDevice_Amount = 0

local Providers = require(121914423994681) -- Ensure this ID points to the correct module script
local ProviderVal = LCD.Home.FaultContact.Provider.Value -- This should match the expected key format in Providers

local provider = Providers[ProviderVal] -- Fetch the provider details


if provider and provider.Logo then
	LCD.Home.Logo.Image = provider.Logo

	LCD.Home.FaultContact.Text = "FOR SERVICE CONTACT<br />" .. provider.NAme
else
	warn("Provider or Logo not found for ProviderVal: " .. tostring(ProviderVal))
	LCD.Home.Logo.Image = "rbxassetid://118103660548946"
end


local NetAPI = script.Parent.Parent.Parent.NetAPI

function CheckPriority(newState)
	local activeStates = {
		Evacuation = InEvac,
		Trouble = InTrouble,
		ClassChange = InClassChange,
		Custom = (InAlarm and not InClassChange)
	}

	-- Map "Evac" to "Evacuation" if needed
	local priorityKey = (newState == "Evac") and "Evacuation" or newState
	local newPriority = PriorityList[priorityKey]

	if not newPriority then
		-- If unknown priority, allow by default or deny? Adjust as needed
		return true
	end

	for stateName, isActive in pairs(activeStates) do
		if isActive then
			local currentPriority = PriorityList[stateName]
			if currentPriority then
				-- Deny if newPriority is higher (less urgent) than any active priority
				if newPriority > currentPriority then
					return false
				end
			end
		end
	end

	-- No active state with higher priority, allow
	return true
end




function MakeFramesVisible(visible)
	LCD.Alarm.Visible = visible
	LCD.AutoLearn.Visible = visible
	LCD.Booting.Visible = visible
	LCD.Calibrate.Visible = visible
	LCD.Commission.Visible = visible
	LCD.Delay.Visible = visible
	LCD.DisablementMenu.Visible = visible
	LCD.EN54.Visible = visible
	LCD.Fault.Visible = visible
	LCD.Home.Visible = visible
	LCD.Level2Menu.Visible = visible
	LCD.LoopDevices.Visible = visible
	LCD.LoopInfo.Visible = visible
	LCD.LoopSelect.Visible = visible
	LCD.Menu.Visible = visible
	LCD.OutputDisablement.Visible = visible
	LCD.Password.Visible = visible
	LCD.TestMenu.Visible = visible
	LCD.TestSelection.Visible = visible
	LCD.Tools.Visible = visible
	LCD.View.Visible = visible
	LCD.ZoneInput.Visible = visible
	LCD.PreAlarm.Visible = visible
	LCD.ZoneInput_Test.Visible = visible
	LCD.MoreAlarms.Visible = visible
	LCD.MoreAlarms_Zone.Visible = visible
	LCD.FaultView.Visible = visible
	LCD.FaultView_Zone.Visible = visible
	LCD.AlarmCondition.Visible = visible
end

function origPos()
	LoopDevicesOrigPos = LCD.LoopDevices.List.Position
	SpecOutputDevices_List_OrigPos = LCD.SpecificOutputDevices.List.Position
end

origPos()

local CurrentDelay

function getCurrentDelay()
	CurrentDelay = Config.Delay
end

getCurrentDelay()

-- LOGGED IN
if Config.AlwaysLoggedIn == true then
	LoggedIn = true
else
	LoggedIn = false
end

function LoopSelection()
	local lsval = LCD.LoopSelect.AmountOfLoops.Value

	if lsval == "1" then
		LCD.LoopSelect.LoopSelect.Loop1.Visible = true
		LCD.LoopSelect.LoopSelect.Loop2.Visible = false
		LCD.LoopSelect.LoopSelect.Loop3.Visible = false
		LCD.LoopSelect.LoopSelect.Loop4.Visible = false
		LCD.LoopSelect.LoopSelect.Loop5.Visible = false
		LCD.LoopSelect.LoopSelect.Loop6.Visible = false
		LCD.LoopSelect.LoopSelect.Loop7.Visible = false
		LCD.LoopSelect.LoopSelect.Loop8.Visible = false
	elseif lsval == "2" then
		LCD.LoopSelect.LoopSelect.Loop1.Visible = true
		LCD.LoopSelect.LoopSelect.Loop2.Visible = true
		LCD.LoopSelect.LoopSelect.Loop3.Visible = false
		LCD.LoopSelect.LoopSelect.Loop4.Visible = false
		LCD.LoopSelect.LoopSelect.Loop5.Visible = false
		LCD.LoopSelect.LoopSelect.Loop6.Visible = false
		LCD.LoopSelect.LoopSelect.Loop7.Visible = false
		LCD.LoopSelect.LoopSelect.Loop8.Visible = false
	elseif lsval == "4" then
		LCD.LoopSelect.LoopSelect.Loop1.Visible = true
		LCD.LoopSelect.LoopSelect.Loop2.Visible = true
		LCD.LoopSelect.LoopSelect.Loop3.Visible = true
		LCD.LoopSelect.LoopSelect.Loop4.Visible = true
		LCD.LoopSelect.LoopSelect.Loop5.Visible = false
		LCD.LoopSelect.LoopSelect.Loop6.Visible = false
		LCD.LoopSelect.LoopSelect.Loop7.Visible = false
		LCD.LoopSelect.LoopSelect.Loop8.Visible = false
	elseif lsval == "8" then
		LCD.LoopSelect.LoopSelect.Loop1.Visible = true
		LCD.LoopSelect.LoopSelect.Loop2.Visible = true
		LCD.LoopSelect.LoopSelect.Loop3.Visible = true
		LCD.LoopSelect.LoopSelect.Loop4.Visible = true
		LCD.LoopSelect.LoopSelect.Loop5.Visible = true
		LCD.LoopSelect.LoopSelect.Loop6.Visible = true
		LCD.LoopSelect.LoopSelect.Loop7.Visible = true
		LCD.LoopSelect.LoopSelect.Loop8.Visible = true
	end

end

LoopSelection()

-- Devices

local ZoneDifDev = {}

local MCP = 0
local Sounders = 0
local Opt = 0
local Heat = 0
local Multi = 0
local ION = 0
local Other = 0
local IO = 0
local Beacon = 0
local Relays = 0
local ZoneMonitorUnit = 0

local ZoneData = {}


for _, model in pairs(DevicesFolder:GetChildren()) do
	if model:IsA("Model") and model:GetAttribute("DeviceZone") then

		local zone = model:GetAttribute("DeviceZone")


		if not ZoneData[zone] then
			ZoneData[zone] = {
				MCP = 0,
				Sounders = 0,
				Opt = 0,
				Heat = 0,
				Multi = 0,
				ION = 0,
				IO = 0,
				ZoneMonitorUnit = 0,
				Beacon = 0,
				Relays = 0,
				Other = 0
			}
		end


		local ModelScript = model:FindFirstChildOfClass("Script")
		if ModelScript then
			local stringVal = ModelScript:FindFirstChildOfClass("StringValue")
			if stringVal then

				if stringVal.Name == "MCP" then
					ZoneData[zone].MCP += 1
				elseif stringVal.Name == "SOUNDER" then
					ZoneData[zone].Sounders += 1
				elseif stringVal.Name == "OPTICALDETECTOR" then
					ZoneData[zone].Opt += 1
				elseif stringVal.Name == "HEATDETECTOR" then
					ZoneData[zone].Heat += 1
				elseif stringVal.Name == "MULTISENSOR" then
					ZoneData[zone].Multi += 1
				elseif stringVal.Name == "ION" then
					ZoneData[zone].ION += 1
				elseif stringVal.Name == "IO" then
					ZoneData[zone].IO += 1
				elseif stringVal.Name == "ZMU" then
					ZoneData[zone].ZoneMonitorUnit += 1
				elseif stringVal.Name == "BEACON" then
					ZoneData[zone].Beacon += 1
				elseif stringVal.Name == "RELAY" then
					ZoneData[zone].Relays +=1
				elseif stringVal.Name == "OTHER" then
					ZoneData[zone].Other += 1
				end
			end
		end
	end
end


-- STARTUPLED

function Boot()

	LCD.Enabled = true

	if Config.CauseEffectEnabled == false then
		NetAPI:Fire("Disable", "AllOtherRelay")
	end

	for c, d in pairs(Buttons:GetDescendants()) do
		if d:IsA("ClickDetector") then
			d.MaxActivationDistance = 0
		end
	end

	LCD.Parent.Buzzer:Play()

	for i, v in ipairs(LEDs:GetDescendants()) do
		if v:IsA("BasePart") and v.Name:sub(1, 1) == "Z" then
			v.Color = Color3.new(1, 0, 0)
		end
	end

	for i, v in ipairs(LEDs:GetDescendants()) do
		if v:IsA("BasePart") and v.Name:sub(1, 1) == "F" then
			v.Color = Color3.new(1, 0.52549, 0.184314)
		end
	end


	for i, v in ipairs(LEDs:GetDescendants()) do
		if v:IsA("BasePart") and v.Name:sub(1, 1) == "S" then
			v.Color = Color3.new(1, 0.52549, 0.184314)
		end
	end

	for i, v in ipairs(LEDs:GetDescendants()) do
		if v:IsA("BasePart") and v.Name:sub(1, 1) == "T" then
			v.Color = Color3.new(1, 0.52549, 0.184314)
		end
	end

	for i, v in ipairs(LEDs:GetDescendants()) do
		if v:IsA("BasePart") and v.Name:sub(1, 1) == "D" then
			v.Color = Color3.new(1, 0.52549, 0.184314)
		end
	end

	LEDs.Fire.Color = Color3.new(1, 0, 0)
	LEDs.MoreAlarms.Color = Color3.new(1, 0, 0)
	LEDs.PreAlarm.Color = Color3.new(1, 0.52549, 0.184314)

	LEDs.FireProtection.Color = Color3.new(1, 0, 0)

	wait(5)
	Buzzer:Stop()
	for i, v in pairs(LEDs:GetChildren()) do
		if v:IsA("BasePart") then
			v.Color = Color3.new(0.192157, 0.192157, 0.196078)

			if v.Name == "Power" then
				v.Color = Color3.new(0.411765, 0.886275, 0.0980392)
			end

		end
	end



	--[[
	elseif v.Name == "Delay" and InvestigationDelay == true then
				LEDs.Delay.Color = Color3.new(1, 0.52549, 0.184314)
			elseif v.Name == "FireRouting_Activated" then
				LEDs.FireRouting_Activated.Color = Color3.new(0.192157, 0.192157, 0.196078)
				
				if DisabledDevice_Amount > 0 then
		LEDs.Disablement.Color = Color3.new(1, 0.52549, 0.184314)
	end

	if SoundersDisableList > 0 then
		LEDs.SounderDisabled.Color = Color3.new(1, 0.52549, 0.184314)
	end
				
	]]

	LCD.Booting.Visible = true
	LCD.Booting.S1.Visible = true
	LCD.Booting.S2.Visible = false

	wait(10)

	LCD.Booting.S1.Visible = false
	LCD.Booting.S2.Visible = true

	wait(5)

	LCD.Booting.Visible = false

	if InAlarm == false then

		if InFault == false then
			LCD.Home.Visible = true
		else
			LCD.Fault.Visible = true
		end

	else
		LCD.Alarm.Visible = true
	end

	for a, b in pairs(LEDs:GetChildren()) do
		if b:IsA("BasePart") then
			b.Color = Color3.new(0.192157, 0.192157, 0.196078)

			if b.Name == "Power" then
				b.Color = Color3.new(0.411765, 0.886275, 0.0980392)
			elseif b.Name == "Delay" and InvestigationDelay == true then
				LEDs.Delay.Color = Color3.new(1, 0.52549, 0.184314)
			elseif b.Name == "FireRouting_Activated" then
				LEDs.FireRouting_Activated.Color = Color3.new(0.192157, 0.192157, 0.196078)
			end

		end
	end

	if DisabledDevice_Amount > 0 then
		LEDs.Disablement.Color = Color3.new(1, 0.52549, 0.184314)
	end

	if SoundersDisableList > 0 then
		LEDs.SounderDisabled.Color = Color3.new(1, 0.52549, 0.184314)
	end

	script.PoweredOn.Value = true

	for c, d in pairs(Buttons:GetDescendants()) do
		if d:IsA("ClickDetector") then
			d.MaxActivationDistance = 32
		end
	end

	

end


if script.Parent:GetAttribute("Power") == true then
	Boot()
end

script.Parent.AttributeChanged:Connect(function()
	if script.Parent:GetAttribute("Power") == true then
		Boot()
	elseif script.Parent:GetAttribute("Power") == false then
		script.PoweredOn.Value = false
		LCD.Enabled = false
		script.Access.Value = false
		script.Flash.Value = false
		script.Flash_Fault.Value = false
		wait(0.1)
		FlashRed_Fire()
		FlashOrange_Fault()

		for i, v in pairs(LEDs:GetChildren()) do
			if v:IsA("Part") then
				v.Color = Color3.new(0.192157, 0.192157, 0.196078)
			end
		end

	end
end)



-- KEYSWITCH ACCESS VAL

script.Access.Changed:Connect(function()
	if script.Access.Value == true then
		LoggedIn = true
		InLevel = 2
		LCD.Home.Level.Text = "LEVEL 2<br />"
		LCD.Menu.EnableControls.Text = "DISABLE-CONTROLS"
		if LCD.Menu.Visible == true then
			LCD.Menu.Visible = false
			LCD.Level2Menu.Visible = true
		end

	else
		LCD.Home.Level.Text = "LEVEL 1<br />"
		LoggedIn = false
		LCD.Menu.EnableControls.Text = "ENABLE-CONTROLS"
		InLevel = 1
		MakeFramesVisible(false)

		if InAlarm == true then
			LCD.Alarm.Visible = true
		else
			LCD.Home.Visible = true
		end

	end
end)

script.Level3.Changed:Connect(function()
	if script.Level3.Value == true then
		LoggedIn = true
		InLevel = 3
		LCD.Home.Level.Text = "LEVEL 3<br />"
		LCD.Menu.EnableControls.Text = "DISABLE-CONTROLS"
		if LCD.Menu.Visible == true then
			LCD.Menu.Visible = false
			LCD.Level2Menu.Visible = true
		end

	else
		LCD.Home.Level.Text = "LEVEL 1<br />"
		LoggedIn = false
		LCD.Menu.EnableControls.Text = "ENABLE-CONTROLS"

		MakeFramesVisible(false)
		InLevel = 1
		if InAlarm == true then
			LCD.Alarm.Visible = true
		else
			LCD.Home.Visible = true
		end

	end
end)

-- CONVERT STRING TO 0000
local function convert0000Format(input)
	local maxLength = 4
	local zeroCount = maxLength - #input
	local formattedString = string.rep("0", zeroCount) .. input
	return formattedString
end

local function convert000Format(input)
	local maxLength = 3
	local zeroCount = maxLength - #input
	local formattedString = string.rep("0", zeroCount) .. input
	return formattedString
end

local function evaluateZoneState(zone)
	local hasDisabled = false
	local hasEnabled = false

	-- Check each output in the zone
	for _, output in ipairs(OutputsDisabled) do
		if output.Zone == zone then
			if output.Disabled then
				hasDisabled = true
			else
				hasEnabled = true
			end
		end
	end

	-- Determine state
	if hasDisabled and hasEnabled then
		return "Part-Disabled"
	elseif hasDisabled then
		return "Disabled"
	else
		return "Enabled"
	end
end

local function updateFaultState(data1, data2)

	LCD.Fault.Information.Text = data1
	LCD.Fault.Location.Text = convert0000Format(data2)
	Fault:Play()
	LCD.Home.Info.Fault.Visible = true
	LCD.Home.Logo.Visible = false
	LCD.Home.FaultContact.Visible = true
	LCD.Home.Instructions.Visible = false
	script.Flash_Fault.Value = true
	InFault = true
	FlashOrange_Fault()
end

-- VIEW TAB


-- LOOP

local currentFrameIndex_LOOPS = 1
local totalFrames_LOOPS = 0
local frames_LOOPS = {}
local Loopdevices_models = {}

if not DevicesFolder or not LCD then
	error("DevicesFolder or LCD is not defined.")
end

local function initializeListUI()
	for i, frame in ipairs(frames_LOOPS) do
		if i == currentFrameIndex_LOOPS then
			frame.BackgroundTransparency = 0
			frame.Address.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			frame.Type.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
		else
			frame.BackgroundTransparency = 1
			frame.Address.TextColor3 = Color3.new(0, 0, 0)
			frame.Zone.TextColor3 = Color3.new(0, 0, 0)
			frame.Type.TextColor3 = Color3.new(0, 0, 0)
		end
	end

	LCD.LoopDevices.List.Position = LoopDevicesOrigPos

end

local function getLoopDevices(Loop)
	totalFrames_LOOPS = 0
	currentFrameIndex_LOOPS = 1
	frames_LOOPS = {}
	Loopdevices_models = {}

	LCD.LoopDevices.Header.ZoneController.Text = "[ Loop " .. Loop .. " Devices ]"

	for i, v in pairs(LCD.LoopDevices.List:GetChildren()) do
		if v:IsA("Frame") then
			if v.Name == "Template" then
				v.Visible = false
			else
				v:Destroy()
			end
		end
	end

	for _, model in ipairs(DevicesFolder:GetChildren()) do
		if model:IsA("Model") then
			local loopAtr = model:GetAttribute("Loop")

			if loopAtr == Loop then
				totalFrames_LOOPS = totalFrames_LOOPS + 1
				local Clone = LCD.LoopDevices.List.Template:Clone()
				Clone.Parent = LCD.LoopDevices.List

				Clone.Address.Text = model:GetAttribute("DeviceAddress") or "N/A"
				Clone.Zone.Text = convert000Format(model:GetAttribute("DeviceZone") or "N/A")

				local ModelScript = model:FindFirstChildOfClass("Script")
				if ModelScript then
					local stringVal = ModelScript:FindFirstChildOfClass("StringValue")
					if stringVal then
						local deviceTypeMapping = {
							MCP = "Call Point",
							SOUNDER = "Sounder",
							MULTISENSOR = "Multi Sensor",
							OPTICALDETECTOR = "Optical Detector",
							HEATDETECTOR = "Heat Detector",
							IO = "IO Device",
							ZMU = "ZMU",
							ION = "ION Detector",
						}

						Clone.Type.Text = deviceTypeMapping[stringVal.Name] or "Unknown Device"
					end
				end

				Clone.Visible = true
				table.insert(Loopdevices_models, model)
				table.insert(frames_LOOPS, Clone)
			end
		end
	end

	initializeListUI()
end




local function shiftFramesDown_LOOPS()
	if currentFrameIndex_LOOPS < totalFrames_LOOPS then
		currentFrameIndex_LOOPS = currentFrameIndex_LOOPS + 1

		local frameHeight_dis = LCD.LoopDevices.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_LOOPS) do
			if i == currentFrameIndex_LOOPS then
				frame.BackgroundTransparency = 0
				frame.Address.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Type.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			else
				frame.BackgroundTransparency = 1
				frame.Address.TextColor3 = Color3.new(0, 0, 0)
				frame.Zone.TextColor3 = Color3.new(0, 0, 0)
				frame.Type.TextColor3 = Color3.new(0, 0, 0)
			end
		end

		LCD.LoopDevices.List.Position = UDim2.new(
			LCD.LoopDevices.List.Position.X.Scale,
			LCD.LoopDevices.List.Position.X.Offset,
			LCD.LoopDevices.List.Position.Y.Scale,
			LCD.LoopDevices.List.Position.Y.Offset - frameHeight_dis
		)
	end
end

local function shiftFramesUp_LOOPS()

	if currentFrameIndex_LOOPS > 1 then
		currentFrameIndex_LOOPS = currentFrameIndex_LOOPS - 1

		local frameHeight = LCD.LoopDevices.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_LOOPS) do
			if i == currentFrameIndex_LOOPS then
				frame.BackgroundTransparency = 0
				frame.Address.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Type.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			else
				frame.BackgroundTransparency = 1
				frame.Address.TextColor3 = Color3.new(0, 0, 0)
				frame.Zone.TextColor3 = Color3.new(0, 0, 0)
				frame.Type.TextColor3 = Color3.new(0, 0, 0)
			end
		end

		LCD.LoopDevices.List.Position = UDim2.new(
			LCD.LoopDevices.List.Position.X.Scale,
			LCD.LoopDevices.List.Position.X.Offset,
			LCD.LoopDevices.List.Position.Y.Scale,
			LCD.LoopDevices.List.Position.Y.Offset + frameHeight
		)
	end
end


-- ZONE FRAMES


local currentFrameIndex_ZONES = 1
local totalFrames_ZONES = 0
local frames_ZONES = {}
local Zonedevices_models = {}
local zonesTable = {}
local ZoneDisablementTable = {}

if not DevicesFolder or not LCD then
	error("DevicesFolder or LCD is not defined.")
end

local function initializeFrames2()
	for i, frame in ipairs(frames_ZONES) do
		if i == currentFrameIndex_ZONES then
			frame.BackgroundTransparency = 0
			frame.Location.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			frame.Mode.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
		else
			frame.BackgroundTransparency = 1
			frame.Location.TextColor3 = Color3.new(0, 0, 0)
			frame.Mode.TextColor3 = Color3.new(0, 0, 0)
			frame.Zone.TextColor3 = Color3.new(0, 0, 0)
		end
	end
end



currentFrameIndex_ZONES = 1





local function addZoneToList()
	for _, model in ipairs(DevicesFolder:GetChildren()) do
		if model:IsA("Model") then
			local DeviceZoneq = model:GetAttribute("DeviceZone")

			if DeviceZoneq then
				if not table.find(zonesTable, DeviceZoneq) then
					table.insert(zonesTable, DeviceZoneq)
					table.insert(Zonedevices_models, model)
					table.insert(ZoneDisablementTable, {
						Zone = DeviceZoneq,
						Callpoints = false,
						Detectors = false,
						allInputs = false,
						Disabled = false,
					})

					totalFrames_ZONES += 1
					LCD.Home.Info.Disablements.Text = "  " .. totalFrames_ZONES .. " ZONE WITH DISABLEMENTS"
					local Clone = LCD.ZoneInput.List.Template:Clone()
					Clone.Name = "ZoneFrame_" .. DeviceZoneq
					Clone.Parent = LCD.ZoneInput.List
					Clone.Visible = true

					Clone.Zone.Text = DeviceZoneq
					Clone.Mode.Text = "Enabled"
					Clone.Location.Text = ZoneLocations[DeviceZoneq] or "CANNOT FIND"

					table.insert(frames_ZONES, Clone)
				end
			else
				warn(
					string.format(
						"NXPRO - DEVICE: %s ID: %s does not have a Zone.",
						model.Name,
						model:GetAttribute("DeviceID") or "UNKNOWN"
					)
				)
			end
		end
	end
end

addZoneToList()
initializeFrames2()

local function shiftFramesDown_ZONES()
	if currentFrameIndex_ZONES < totalFrames_ZONES then
		currentFrameIndex_ZONES = currentFrameIndex_ZONES + 1

		local frameHeight_dis = LCD.ZoneInput.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_ZONES) do
			if i == currentFrameIndex_ZONES then
				frame.BackgroundTransparency = 0
				frame.Location.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Mode.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			else
				frame.BackgroundTransparency = 1
				frame.Location.TextColor3 = Color3.new(0, 0, 0)
				frame.Mode.TextColor3 = Color3.new(0, 0, 0)
				frame.Zone.TextColor3 = Color3.new(0, 0, 0)
			end
		end

		LCD.ZoneInput.List.Position = UDim2.new(
			LCD.ZoneInput.List.Position.X.Scale,
			LCD.ZoneInput.List.Position.X.Offset,
			LCD.ZoneInput.List.Position.Y.Scale,
			LCD.ZoneInput.List.Position.Y.Offset - frameHeight_dis
		)
	end
end

local function shiftFramesUp_ZONES()
	if currentFrameIndex_ZONES > 1 then
		currentFrameIndex_ZONES = currentFrameIndex_ZONES - 1

		local frameHeight = LCD.ZoneInput.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_ZONES) do
			if i == currentFrameIndex_ZONES then
				frame.BackgroundTransparency = 0
				frame.Location.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Mode.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			else
				frame.BackgroundTransparency = 1
				frame.Location.TextColor3 = Color3.new(0, 0, 0)
				frame.Mode.TextColor3 = Color3.new(0, 0, 0)
				frame.Zone.TextColor3 = Color3.new(0, 0, 0)
			end
		end

		LCD.ZoneInput.List.Position = UDim2.new(
			LCD.ZoneInput.List.Position.X.Scale,
			LCD.ZoneInput.List.Position.X.Offset,
			LCD.ZoneInput.List.Position.Y.Scale,
			LCD.ZoneInput.List.Position.Y.Offset + frameHeight
		)
	end
end

-- ZONE TEST FRAMES


local currentFrameIndex_ZONESTEST = 1
local totalFrames_ZONESTEST = 0
local frames_ZONESTEST = {}
local zonesTableTEST = {}
local ZoneTestTable = {}
local ZoneDisablementTableTEST = {}
local ZonesInTest = {}

if not DevicesFolder or not LCD then
	error("DevicesFolder or LCD is not defined.")
end

local function initializeFrames3()
	for i, frame in ipairs(frames_ZONESTEST) do
		if i == currentFrameIndex_ZONESTEST then
			frame.Mode.BackgroundTransparency = 0

			frame.Mode.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)

		else
			frame.Mode.BackgroundTransparency = 1

			frame.Mode.TextColor3 = Color3.new(0, 0, 0)

		end
	end
end



currentFrameIndex_ZONESTEST = 1





local function addZoneTestToList()
	for _, model in ipairs(DevicesFolder:GetChildren()) do
		if model:IsA("Model") then
			local DeviceZoneq = model:GetAttribute("DeviceZone")

			if DeviceZoneq then
				if not table.find(zonesTableTEST, DeviceZoneq) then
					table.insert(zonesTableTEST, DeviceZoneq)
					table.insert(ZoneDisablementTableTEST, {
						DeviceZoneq
					})

					totalFrames_ZONESTEST += 1
					local Clone = LCD.ZoneInput_Test.List.Template:Clone()
					Clone.Name = "ZoneFrame_" .. DeviceZoneq
					Clone.Parent = LCD.ZoneInput_Test.List
					Clone.Visible = true

					Clone.Zone.Text = convert0000Format(DeviceZoneq)
					Clone.Mode.Text = "   -"
					Clone.Location.Text = ZoneLocations[DeviceZoneq] or "CANNOT FIND"

					table.insert(frames_ZONESTEST, Clone)
				end
			else
				warn(
					string.format(
						"NXPRO - DEVICE: %s ID: %s does not have a Zone.",
						model.Name,
						model:GetAttribute("DeviceID") or "UNKNOWN"
					)
				)
			end
		end
	end
end

addZoneTestToList()
initializeFrames3()

local function shiftFramesDown_ZONESTEST()
	if currentFrameIndex_ZONESTEST < totalFrames_ZONESTEST then
		currentFrameIndex_ZONESTEST = currentFrameIndex_ZONESTEST + 1

		local frameHeight_dis = LCD.ZoneInput_Test.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_ZONESTEST) do
			if i == currentFrameIndex_ZONESTEST then
				frame.Mode.BackgroundTransparency = 0

				frame.Mode.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)

			else
				frame.Mode.BackgroundTransparency = 1

				frame.Mode.TextColor3 = Color3.new(0, 0, 0)

			end
		end

		LCD.ZoneInput_Test.List.Position = UDim2.new(
			LCD.ZoneInput_Test.List.Position.X.Scale,
			LCD.ZoneInput_Test.List.Position.X.Offset,
			LCD.ZoneInput_Test.List.Position.Y.Scale,
			LCD.ZoneInput_Test.List.Position.Y.Offset - frameHeight_dis
		)
	end
end

local function shiftFramesUp_ZONESTEST()
	if currentFrameIndex_ZONESTEST > 1 then
		currentFrameIndex_ZONESTEST = currentFrameIndex_ZONESTEST - 1

		local frameHeight_dis = LCD.ZoneInput_Test.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_ZONESTEST) do
			if i == currentFrameIndex_ZONESTEST then
				frame.Mode.BackgroundTransparency = 0

				frame.Mode.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)

			else
				frame.Mode.BackgroundTransparency = 1

				frame.Mode.TextColor3 = Color3.new(0, 0, 0)

			end
		end

		LCD.ZoneInput_Test.List.Position = UDim2.new(
			LCD.ZoneInput_Test.List.Position.X.Scale,
			LCD.ZoneInput_Test.List.Position.X.Offset,
			LCD.ZoneInput_Test.List.Position.Y.Scale,
			LCD.ZoneInput_Test.List.Position.Y.Offset + frameHeight_dis
		)
	end
end

local function ChangeTestStatus()
	for i, frame in ipairs(frames_ZONESTEST) do
		if i == currentFrameIndex_ZONESTEST then

			local ZoneNumber = frame.Name:gsub("^ZoneFrame_", "")




			local found = false


			for a, zone in ipairs(ZonesInTest) do



				if zone == frame then
					found = true

					frame.Mode.Text = "   -"


					NetAPI:Fire("TestMode", false, ZoneNumber)
					NetAPI:Fire("FinishedTest")

					print(#ZonesInTest)

					if #ZonesInTest == 0 then
						InTest = false
						LEDs.Test.Color = Color3.new(0.192157, 0.192157, 0.196078)
					end

					LCD.ZoneInput_Test.Header.ZoneController.Text = "[  " .. AmountOfZonesINTEST .. " ZONE(s) in Test ]"

					break
				end
			end


			if not found then

				frame.Mode.Text = "IN TEST"

				--table.insert(ZonesInTest, {frame})


				if not InTest then
					NetAPI:Fire("TestMode", true, ZoneNumber)

					if testSelect_SoundersInput	== "With" then
						NetAPI:Fire("Test", "WithSounders", ZoneNumber)
					elseif  testSelect_SoundersInput == "Without" then
						NetAPI:Fire("Test", "WithoutSounders", ZoneNumber)
					end				

					LEDs.Test.Color = Color3.new(1, 0.52549, 0.184314)
				end
			end

			LCD.ZoneInput_Test.Header.ZoneController.Text = "[  " .. AmountOfZonesINTEST .. " ZONE(s) in Test ]"

			if #ZonesInTest == 0 or AmountOfZonesINTEST <= 0 then
				InTest = false
				LEDs.Test.Color = Color3.new(0.192157, 0.192157, 0.196078)
			end

		end
	end
end

local function ClearTestTables()

	for i, frame in ipairs(frames_ZONESTEST) do


		local ZoneNumber = frame.Name:gsub("^ZoneFrame_", "")




		local found = false


		for a, zone in ipairs(ZonesInTest) do



			if zone == frame then
				found = true

				frame.Mode.Text = "   -"



				NetAPI:Fire("TestMode", false, ZoneNumber)
				NetAPI:Fire("Test", "WithSounders", ZoneNumber)

				if #ZonesInTest == 0 then
					InTest = false
					LEDs.Test.Color = Color3.new(0.192157, 0.192157, 0.196078)
				end


			end

		end
	end

	LCD.ZoneInput_Test.Header.ZoneController.Text = "[  " .. AmountOfZonesINTEST .. " ZONE(s) in Test ]"


	InTest = false
	LEDs.Test.Color = Color3.new(0.192157, 0.192157, 0.196078)


end


-- MORE ALARMS

local currentFrameIndex_MOREALARMS = 1
local totalFrames_MOREALARM = 0
local frames_MOREALARM = {}
local ZonesInAlarm = {}


local function initializeFrames4()
	for i, frame in ipairs(frames_MOREALARM) do
		if i == currentFrameIndex_MOREALARMS then
			frame.BackgroundTransparency = 0
			frame.Location.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
		else
			frame.BackgroundTransparency = 1
			frame.Location.TextColor3 = Color3.new(0, 0, 0)
			frame.Zone.TextColor3 = Color3.new(0, 0, 0)
		end
	end
end


local function addZoneToList_MoreAlarms()

	if #ZonesInAlarm > 1 then
		LEDs.MoreAlarms.Color = Color3.new(1, 0, 0)
	end

	for i, v in pairs(LCD.MoreAlarms.List:GetChildren()) do
		if v:IsA("Frame") then

			if v.Name ~= "Template" then
				v:Destroy()
			end

		end
	end

	frames_MOREALARM = {}
	totalFrames_MOREALARM = 0

	currentFrameIndex_MOREALARMS = 1

	for _, alarm in ipairs(ZonesInAlarm) do
		totalFrames_MOREALARM += 1



		local Clone = LCD.MoreAlarms.List.Template:Clone()
		Clone.Name = "AlarmFrame_" .. alarm
		Clone.Parent = LCD.MoreAlarms.List
		Clone.Visible = true

		Clone.Zone.Text = convert0000Format(alarm)
		Clone.Location.Text = ZoneLocations[alarm] or "CANNOT FIND"

		local ZoneVal = Instance.new("StringValue")
		ZoneVal.Value = alarm
		ZoneVal.Name = "ZONE"
		ZoneVal.Parent = Clone

		table.insert(frames_MOREALARM, Clone)
	end

	initializeFrames4()
end


local function shiftFramesDown_MOREALARMS()
	if currentFrameIndex_MOREALARMS < totalFrames_MOREALARM then
		currentFrameIndex_MOREALARMS += 1

		local frameHeight_dis = LCD.MoreAlarms.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_MOREALARM) do
			if i == currentFrameIndex_MOREALARMS then
				frame.BackgroundTransparency = 0
				frame.Location.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			else
				frame.BackgroundTransparency = 1
				frame.Location.TextColor3 = Color3.new(0, 0, 0)
				frame.Zone.TextColor3 = Color3.new(0, 0, 0)
			end
		end


		LCD.MoreAlarms.List.Position = UDim2.new(
			LCD.MoreAlarms.List.Position.X.Scale,
			LCD.MoreAlarms.List.Position.X.Offset,
			LCD.MoreAlarms.List.Position.Y.Scale,
			LCD.MoreAlarms.List.Position.Y.Offset - frameHeight_dis
		)
	end
end


local function shiftFramesUp_MOREALARMS()
	if currentFrameIndex_MOREALARMS > 1 then
		currentFrameIndex_MOREALARMS -= 1

		local frameHeight_dis = LCD.MoreAlarms.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_MOREALARM) do
			if i == currentFrameIndex_MOREALARMS then
				frame.BackgroundTransparency = 0
				frame.Location.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			else
				frame.BackgroundTransparency = 1
				frame.Location.TextColor3 = Color3.new(0, 0, 0)
				frame.Zone.TextColor3 = Color3.new(0, 0, 0)
			end
		end


		LCD.MoreAlarms.List.Position = UDim2.new(
			LCD.MoreAlarms.List.Position.X.Scale,
			LCD.MoreAlarms.List.Position.X.Offset,
			LCD.MoreAlarms.List.Position.Y.Scale,
			LCD.MoreAlarms.List.Position.Y.Offset + frameHeight_dis
		)
	end
end

-- MORE ALARMS ZONE

local currentFrameIndex_MOREALARMS_ZONE = 1
local totalFrames_MOREALARM_ZONE = 0
local frames_MOREALARM_ZONE = {}
local DeviceTextInAlarm = {}

local function initializeFrames5()
	for i, frame in ipairs(frames_MOREALARM_ZONE) do
		if i == currentFrameIndex_MOREALARMS_ZONE then
			frame.BackgroundTransparency = 0
			frame.Mld.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			frame.DeviceText.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
		else
			frame.BackgroundTransparency = 1
			frame.Mld.TextColor3 = Color3.new(0, 0, 0)
			frame.DeviceText.TextColor3 = Color3.new(0, 0, 0)
		end
	end
end

local function addZoneToList_MoreAlarms_Zone(zone)

	if InAlarm then
		LCD.MoreAlarms_Zone.Header.ZoneController.Text = "[ FIRES IN ZONE ".. convert0000Format(zone) .."]     Scroll ?      <More"
	else
		LCD.MoreAlarms_Zone.Header.ZoneController.Text = "[ ALARM IN ZONE ".. convert0000Format(zone) .."]     Scroll ?      <More"
	end

	-- Clear old frames
	for _, v in pairs(LCD.MoreAlarms_Zone.List:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "Template" then
			v:Destroy()
		end
	end

	currentFrameIndex_MOREALARMS_ZONE = 1
	frames_MOREALARM_ZONE = {}
	totalFrames_MOREALARM_ZONE = 0

	for _, alarm in ipairs(DeviceTextInAlarm) do
		if alarm.Name == zone then
			totalFrames_MOREALARM_ZONE += 1

			local Clone = LCD.MoreAlarms_Zone.List.Template:Clone()
			Clone.Name = "AlarmFrame_" .. alarm.Name
			Clone.Parent = LCD.MoreAlarms_Zone.List
			Clone.Visible = true

			local found = false

			for a, device in pairs(DevicesFolder:GetChildren()) do
				if device:IsA("Model") then



					if device:GetAttribute("DeviceID") == alarm.ID then

						found = true
						Clone.DeviceText.Text = device:GetAttribute("DeviceName")

					else

						found = false

						break
					end

				end
			end

			if not found then

				for b, panel in pairs(Panels:GetChildren()) do

					if panel:IsA("Model") then

						if panel:GetAttribute("DeviceID") == alarm.ID then
							found = true
							Clone.DeviceText.Text = panel:GetAttribute("DeviceName")
							break
						end

					end

				end

			end

			Clone.Mld.Text = "/" .. alarm.ID

			table.insert(frames_MOREALARM_ZONE, Clone)
		end



	end

	initializeFrames5()
end


local function shiftFramesDown_MOREALARMSZONES()
	if currentFrameIndex_MOREALARMS_ZONE < totalFrames_MOREALARM_ZONE then
		currentFrameIndex_MOREALARMS_ZONE += 1

		local frameHeight_dis = LCD.MoreAlarms_Zone.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_MOREALARM_ZONE) do
			if i == currentFrameIndex_MOREALARMS_ZONE then
				frame.BackgroundTransparency = 0
				frame.DeviceText.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Mld.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			else
				frame.BackgroundTransparency = 1
				frame.DeviceText.TextColor3 = Color3.new(0, 0, 0)
				frame.Mld.TextColor3 = Color3.new(0, 0, 0)
			end
		end


		LCD.MoreAlarms_Zone.List.Position = UDim2.new(
			LCD.MoreAlarms_Zone.List.Position.X.Scale,
			LCD.MoreAlarms_Zone.List.Position.X.Offset,
			LCD.MoreAlarms_Zone.List.Position.Y.Scale,
			LCD.MoreAlarms_Zone.List.Position.Y.Offset - frameHeight_dis
		)
	end
end


local function shiftFramesUp_MOREALARMSZONES()
	if currentFrameIndex_MOREALARMS_ZONE > 1 then
		currentFrameIndex_MOREALARMS_ZONE -= 1

		local frameHeight_dis = LCD.MoreAlarms_Zone.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_MOREALARM_ZONE) do
			if i == currentFrameIndex_MOREALARMS_ZONE then
				frame.BackgroundTransparency = 0
				frame.DeviceText.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Mld.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			else
				frame.BackgroundTransparency = 1
				frame.DeviceText.TextColor3 = Color3.new(0, 0, 0)
				frame.Mld.TextColor3 = Color3.new(0, 0, 0)
			end
		end


		LCD.MoreAlarms_Zone.List.Position = UDim2.new(
			LCD.MoreAlarms_Zone.List.Position.X.Scale,
			LCD.MoreAlarms_Zone.List.Position.X.Offset,
			LCD.MoreAlarms_Zone.List.Position.Y.Scale,
			LCD.MoreAlarms_Zone.List.Position.Y.Offset + frameHeight_dis
		)
	end
end

-- FAULTS VIEW

local currentFrameIndex_FAULTSVIEW = 1
local totalFrames_FAULTSVIEW = 0
local frames_FAULTSVIEW = {}
local DevicesInFault = {}

local function initializeFrames6()
	for i, frame in ipairs(frames_FAULTSVIEW) do
		if i == currentFrameIndex_FAULTSVIEW then
			frame.BackgroundTransparency = 0
			frame.Location.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
		else
			frame.BackgroundTransparency = 1
			frame.Location.TextColor3 = Color3.new(0, 0, 0)
			frame.Zone.TextColor3 = Color3.new(0, 0, 0)
		end
	end
end

local function addZoneToList_FaultView()
	local faultCount = #FaultTable

	-- Header Update
	local faultHeaderText = adjustString(
		"[ " .. tostring(MainsFault and totalFrames_ZONES or previousAmountOfFaults) .. " Zone(s) in Fault]                   More>", 45
	)
	LCD.FaultView.Header.ZoneController.Text = faultHeaderText

	-- Clear previous frames
	for _, child in ipairs(LCD.FaultView.List:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "Template" then
			child:Destroy()
		end
	end

	-- Reset tracking variables
	currentFrameIndex_FAULTSVIEW = 1
	frames_FAULTSVIEW = {}
	totalFrames_FAULTSVIEW = 0

	-- Populate list with FaultTable entries
	for _, faultData in ipairs(FaultTable) do
		totalFrames_FAULTSVIEW += 1

		-- Clone and configure the template
		local clone = LCD.FaultView.List.Template:Clone()
		clone.Name = "Fault_" .. tostring(faultData.Zone)
		clone.Parent = LCD.FaultView.List
		clone.Visible = true
		clone.Zone.Text = convert0000Format(faultData.Zone)
		clone.Location.Text = ZoneLocations[faultData.Zone] or "CANNOT FIND"

		-- Attach zone data
		local zoneVal = Instance.new("StringValue")
		zoneVal.Value = tostring(faultData.Zone)
		zoneVal.Name = "ZONE"
		zoneVal.Parent = clone

		-- Track the frame
		table.insert(frames_FAULTSVIEW, clone)
	end

	-- Initialize frames
	initializeFrames6()
end


local function shiftFramesDown_FAULTVIEW()
	if currentFrameIndex_FAULTSVIEW < totalFrames_FAULTSVIEW then
		currentFrameIndex_FAULTSVIEW += 1

		local frameHeight_dis = LCD.FaultView.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_FAULTSVIEW) do
			if i == currentFrameIndex_FAULTSVIEW then
				frame.BackgroundTransparency = 0
				frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Location.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			else
				frame.BackgroundTransparency = 1
				frame.Zone.TextColor3 = Color3.new(0, 0, 0)
				frame.Location.TextColor3 = Color3.new(0, 0, 0)
			end
		end


		LCD.FaultView.List.Position = UDim2.new(
			LCD.FaultView.List.Position.X.Scale,
			LCD.FaultView.List.Position.X.Offset,
			LCD.FaultView.List.Position.Y.Scale,
			LCD.FaultView.List.Position.Y.Offset - frameHeight_dis
		)
	end
end


local function shiftFramesUp_FAULTVIEW()
	if currentFrameIndex_FAULTSVIEW > 1 then
		currentFrameIndex_FAULTSVIEW -= 1

		local frameHeight_dis = LCD.FaultView.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_FAULTSVIEW) do
			if i == currentFrameIndex_FAULTSVIEW then
				frame.BackgroundTransparency = 0
				frame.Location.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			else
				frame.BackgroundTransparency = 1
				frame.Location.TextColor3 = Color3.new(0, 0, 0)
				frame.Zone.TextColor3 = Color3.new(0, 0, 0)
			end
		end


		LCD.FaultView.List.Position = UDim2.new(
			LCD.FaultView.List.Position.X.Scale,
			LCD.FaultView.List.Position.X.Offset,
			LCD.FaultView.List.Position.Y.Scale,
			LCD.FaultView.List.Position.Y.Offset + frameHeight_dis
		)
	end
end

-- FAULTS VIEW ZONE

local currentFrameIndex_FAULTSVIEW_ZONE = 1
local totalFrames_FAULTSVIEW_ZONE = 0
local frames_FAULTSVIEW_ZONE = {}


local function initializeFrames7()
	for i, frame in ipairs(frames_FAULTSVIEW_ZONE) do
		if i == currentFrameIndex_FAULTSVIEW_ZONE then
			frame.BackgroundTransparency = 0
			frame.State.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			frame.DeviceText.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
		else
			frame.BackgroundTransparency = 1
			frame.State.TextColor3 = Color3.new(0, 0, 0)
			frame.DeviceText.TextColor3 = Color3.new(0, 0, 0)
		end
	end
end

local function addZoneToList_FaultView_ZONE(zone)

	LCD.FaultView_Zone.Header.ZoneController.Text = "[ Faults in Zone ".. convert0000Format(zone) .."]                  <More"

	-- Clear old frames
	for _, v in pairs(LCD.FaultView_Zone.List:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "Template" then
			v:Destroy()
		end
	end

	currentFrameIndex_FAULTSVIEW_ZONE = 1
	frames_FAULTSVIEW_ZONE = {}
	totalFrames_FAULTSVIEW_ZONE = 0

	for i, v in ipairs(FaultTable) do

		if v.Zone == zone and v.Zone ~= "ALL" then

			totalFrames_FAULTSVIEW_ZONE +=1

			local Clone = LCD.FaultView_Zone.List.Template:Clone()
			Clone.Name = "Fault_" .. v.Zone
			Clone.Parent = LCD.FaultView_Zone.List
			Clone.Visible = true

			for a, device in pairs(DevicesFolder:GetChildren()) do
				if device:IsA("Model") then

					if device:GetAttribute("DeviceAddress") == v.Add then

						Clone.DeviceText.Text = device:GetAttribute("DeviceName")

					end

				end
			end

			Clone.State.Text = v.Fault


			local ZoneVal = Instance.new("StringValue")
			ZoneVal.Value = v.Zone
			ZoneVal.Name = "ZONE"
			ZoneVal.Parent = Clone

			table.insert(frames_FAULTSVIEW_ZONE, Clone)

		elseif v.Zone == "ALL" and MainsFault == true then

			totalFrames_FAULTSVIEW_ZONE +=1

			local Clone = LCD.FaultView_Zone.List.Template:Clone()
			Clone.Name = "Fault_" .. v.Zone
			Clone.Parent = LCD.FaultView_Zone.List
			Clone.Visible = true

			Clone.DeviceText.Text = "PSU"

			Clone.State.Text = v.Fault

			table.insert(frames_FAULTSVIEW_ZONE, Clone)

		end
	end

	initializeFrames7()
end


local function shiftFramesDown_FAULTVIEW_ZONE()
	if currentFrameIndex_FAULTSVIEW_ZONE < totalFrames_FAULTSVIEW_ZONE then
		currentFrameIndex_FAULTSVIEW_ZONE += 1

		local frameHeight_dis = LCD.FaultView_Zone.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_FAULTSVIEW_ZONE) do
			if i == currentFrameIndex_FAULTSVIEW_ZONE then
				frame.BackgroundTransparency = 0
				frame.State.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.DeviceText.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			else
				frame.BackgroundTransparency = 1
				frame.State.TextColor3 = Color3.new(0, 0, 0)
				frame.DeviceText.TextColor3 = Color3.new(0, 0, 0)
			end
		end


		LCD.FaultView_Zone.List.Position = UDim2.new(
			LCD.FaultView_Zone.List.Position.X.Scale,
			LCD.FaultView_Zone.List.Position.X.Offset,
			LCD.FaultView_Zone.List.Position.Y.Scale,
			LCD.FaultView_Zone.List.Position.Y.Offset - frameHeight_dis
		)
	end
end


local function shiftFramesUp_FAULTVIEW_ZONE()
	if currentFrameIndex_FAULTSVIEW_ZONE > 1 then
		currentFrameIndex_FAULTSVIEW_ZONE -= 1

		local frameHeight_dis = LCD.FaultView_Zone.List.Template.Size.Y.Offset
		for i, frame in ipairs(frames_FAULTSVIEW_ZONE) do
			if i == currentFrameIndex_FAULTSVIEW_ZONE then
				frame.BackgroundTransparency = 0
				frame.State.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				frame.DeviceText.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			else
				frame.BackgroundTransparency = 1
				frame.State.TextColor3 = Color3.new(0, 0, 0)
				frame.DeviceText.TextColor3 = Color3.new(0, 0, 0)
			end
		end


		LCD.FaultView_Zone.List.Position = UDim2.new(
			LCD.FaultView_Zone.List.Position.X.Scale,
			LCD.FaultView_Zone.List.Position.X.Offset,
			LCD.FaultView_Zone.List.Position.Y.Scale,
			LCD.FaultView_Zone.List.Position.Y.Offset + frameHeight_dis
		)
	end
end

-- OUTPUT ZONES

local currentFrameIndex_OUTPUTZONES = 1
local totalFrames_OUTPUTZONES = 0
local frames_OUTPUTZONES = {}
local zonesTable_OUTPUT = {}
local ZoneDisablementTable_OUTPUT = {}

if not DevicesFolder or not LCD then
	error("DevicesFolder or LCD is not defined.")
end

local function initializeFrames8()
	for i, frame in ipairs(frames_OUTPUTZONES) do
		if i == currentFrameIndex_OUTPUTZONES then
			frame.BackgroundTransparency = 0
			frame.Location.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			frame.Mode.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			frame.Zone.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
		else
			frame.BackgroundTransparency = 1
			frame.Location.TextColor3 = Color3.new(0, 0, 0)
			frame.Mode.TextColor3 = Color3.new(0, 0, 0)
			frame.Zone.TextColor3 = Color3.new(0, 0, 0)
		end
	end
end

local function addZoneToListOUTPUT()
	if not DevicesFolder then
		warn("[ERROR] DevicesFolder is not found!")
		return
	end

	for _, model in ipairs(DevicesFolder:GetChildren()) do
		if model:IsA("Model") then
			local deviceZone = model:GetAttribute("DeviceZone")

			if deviceZone then
				-- Ensure zone isn't already in zonesTable_OUTPUT
				if not table.find(zonesTable_OUTPUT, deviceZone) then
					table.insert(zonesTable_OUTPUT, deviceZone)

					local template = LCD.OutputDevices.List.Template
					if template then
						-- Clone and set up new zone
						local clone = template:Clone()

						local ZoneVal = Instance.new("StringValue")
						ZoneVal.Name = "ZONE"
						ZoneVal.Parent = clone
						ZoneVal.Value = deviceZone

						clone.Parent = LCD.OutputDevices.List
						clone.Visible = true
						clone.Name = "Zone_" .. deviceZone
						clone.Location.Text = ZoneLocations[deviceZone] or "CANNOT FIND"
						clone.Zone.Text = convert0000Format(deviceZone)
						clone.Mode.Text = "Enabled"

						-- Attach StringValue for zone identification


						-- Track the clone in frames_OUTPUTZONES
						table.insert(frames_OUTPUTZONES, clone)
						totalFrames_OUTPUTZONES = totalFrames_OUTPUTZONES + 1
					else
						warn("[ERROR] Template not found in LCD.OutputDevices.List")
					end
				end
			else
				-- Log device missing a zone
				warn(string.format(
					"[WARNING] Device '%s' (ID: %s) does not have a DeviceZone.",
					model.Name,
					model:GetAttribute("DeviceID") or "UNKNOWN"
					))
			end
		end
	end
end


-- Function to shift frames down
local function shiftFramesDown_OUTPUTZONES()
	if currentFrameIndex_OUTPUTZONES < totalFrames_OUTPUTZONES then
		currentFrameIndex_OUTPUTZONES = currentFrameIndex_OUTPUTZONES + 1
		local frameHeight = LCD.OutputDevices.List.Template.Size.Y.Offset

		for i, frame in ipairs(frames_OUTPUTZONES) do
			if i == currentFrameIndex_OUTPUTZONES then
				frame.BackgroundTransparency = 0
				frame.Location.TextColor3 = Color3.new(0.627, 0.702, 0.976)
				frame.Mode.TextColor3 = Color3.new(0.627, 0.702, 0.976)
				frame.Zone.TextColor3 = Color3.new(0.627, 0.702, 0.976)
			else
				frame.BackgroundTransparency = 1
				frame.Location.TextColor3 = Color3.new(0, 0, 0)
				frame.Mode.TextColor3 = Color3.new(0, 0, 0)
				frame.Zone.TextColor3 = Color3.new(0, 0, 0)
			end
		end

		LCD.OutputDevices.List.Position = LCD.OutputDevices.List.Position + UDim2.new(0, 0, 0, -frameHeight)
	end
end

-- Function to shift frames up
local function shiftFramesUp_OUTPUTZONES()
	if currentFrameIndex_OUTPUTZONES > 1 then
		currentFrameIndex_OUTPUTZONES = currentFrameIndex_OUTPUTZONES - 1
		local frameHeight = LCD.OutputDevices.List.Template.Size.Y.Offset

		for i, frame in ipairs(frames_OUTPUTZONES) do
			if i == currentFrameIndex_OUTPUTZONES then
				frame.BackgroundTransparency = 0
				frame.Location.TextColor3 = Color3.new(0.627, 0.702, 0.976)
				frame.Mode.TextColor3 = Color3.new(0.627, 0.702, 0.976)
				frame.Zone.TextColor3 = Color3.new(0.627, 0.702, 0.976)
			else
				frame.BackgroundTransparency = 1
				frame.Location.TextColor3 = Color3.new(0, 0, 0)
				frame.Mode.TextColor3 = Color3.new(0, 0, 0)
				frame.Zone.TextColor3 = Color3.new(0, 0, 0)
			end
		end

		LCD.OutputDevices.List.Position = LCD.OutputDevices.List.Position + UDim2.new(0, 0, 0, frameHeight)
	end
end

-- Main Execution
addZoneToListOUTPUT()
initializeFrames8()

-- OUTPUT CERTAIN ZONES

local currentFrameIndex_OUTPUTZONES_CERTAIN = 1
local totalFrames_OUTPUTZONES_CERTAIN = 0
local frames_OUTPUTZONES_CERTAIN = {}
local zonesTable_OUTPUT_CERTAIN = {}
local ZoneDisablementTable_OUTPUT_CERTAIN = {}

if not DevicesFolder or not LCD then
	error("DevicesFolder or LCD is not defined.")
end

local function initializeFrames9()
	for i, frame in ipairs(frames_OUTPUTZONES_CERTAIN) do
		if i == currentFrameIndex_OUTPUTZONES_CERTAIN then
			frame.BackgroundTransparency = 0
			frame.Location.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			frame.Mode.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			frame.Address.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
		else
			frame.BackgroundTransparency = 1
			frame.Location.TextColor3 = Color3.new(0, 0, 0)
			frame.Mode.TextColor3 = Color3.new(0, 0, 0)
			frame.Address.TextColor3 = Color3.new(0, 0, 0)
		end
	end
end

for a, device in pairs(DevicesFolder:GetChildren()) do
	if device:IsA("Model") then

		local deviceVal = device:FindFirstChild("Script") 
			and device:FindFirstChild("Script"):FindFirstChildOfClass("StringValue")

		if deviceVal.Name == "ZMU" then

			table.insert(OutputsDisabled, {
				Address = device:GetAttribute("DeviceAddress"),
				Zone = device:GetAttribute("DeviceZone"),
				Disabled = false,
				Device = "ZMU"
			})

		elseif deviceVal.Name == "SOUNDER" then

			table.insert(OutputsDisabled, {
				Address = device:GetAttribute("DeviceAddress"),
				Zone = device:GetAttribute("DeviceZone"),
				Disabled = false,
				Device = "SOUNDER"
			})

		elseif deviceVal.Name == "BEACON" then

			table.insert(OutputsDisabled, {
				Address = device:GetAttribute("DeviceAddress"),
				Zone = device:GetAttribute("DeviceZone"),
				Disabled = false,
				Device = "BEACON"
			})

		end

	end
end

local function addZoneToListOUTPUT_CERTAIN(zone)
	-- Clear existing frames
	for _, v in pairs(LCD.SpecificOutputDevices.List:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "Template" then
			v:Destroy()
		end
	end

	currentFrameIndex_OUTPUTZONES_CERTAIN = 1
	frames_OUTPUTZONES_CERTAIN = {}
	totalFrames_OUTPUTZONES_CERTAIN = 0

	LCD.SpecificOutputDevices.List.Position = SpecOutputDevices_List_OrigPos

	-- Add frames based on devices
	for _, device in pairs(DevicesFolder:GetChildren()) do
		if device:IsA("Model") and device:GetAttribute("DeviceZone") == zone then
			local deviceVal = device:FindFirstChild("Script") 
				and device:FindFirstChild("Script"):FindFirstChildOfClass("StringValue")

			if not deviceVal then
				warn("Missing Script or StringValue for device: " .. device.Name)
				continue
			end

			if deviceVal.Name == "ZMU" or deviceVal.Name == "SOUNDER" or deviceVal.Name == "BEACON" then
				totalFrames_OUTPUTZONES_CERTAIN += 1
				local clone = LCD.SpecificOutputDevices.List.Template:Clone()
				clone.Name = "Device"
				clone.Location.Text = device:GetAttribute("Location") or "Unknown"
				clone.Address.Text = device:GetAttribute("DeviceAddress") or "N/A"
				clone.Parent = LCD.SpecificOutputDevices.List
				clone.Visible = true



				-- Add attributes
				local zoneVal = Instance.new("StringValue")
				zoneVal.Name = "ZONE"
				zoneVal.Value = device:GetAttribute("DeviceZone")
				zoneVal.Parent = clone

				local addressVal = Instance.new("StringValue")
				addressVal.Name = "ADDRESS"
				addressVal.Value = device:GetAttribute("DeviceAddress")
				addressVal.Parent = clone

				for a, devicea in ipairs(OutputsDisabled) do
					if devicea.Address == device:GetAttribute("DeviceAddress") then

						if devicea.Disabled == true then
							clone.Mode.Text = "Disabled"
						else
							clone.Mode.Text = "Enabled"
						end

					end
				end

				table.insert(frames_OUTPUTZONES_CERTAIN, clone)
			end
		end

		initializeFrames9()

	end

	-- Update zone state



end

-- Function to shift frames down
local function shiftFramesDown_OUTPUTZONES_CERTAIN()
	if currentFrameIndex_OUTPUTZONES_CERTAIN < totalFrames_OUTPUTZONES_CERTAIN then
		currentFrameIndex_OUTPUTZONES_CERTAIN = currentFrameIndex_OUTPUTZONES_CERTAIN + 1
		local frameHeight = LCD.SpecificOutputDevices.List.Template.Size.Y.Offset

		for i, frame in ipairs(frames_OUTPUTZONES_CERTAIN) do
			if i == currentFrameIndex_OUTPUTZONES_CERTAIN then
				frame.BackgroundTransparency = 0
				frame.Location.TextColor3 = Color3.new(0.627, 0.702, 0.976)
				frame.Mode.TextColor3 = Color3.new(0.627, 0.702, 0.976)
				frame.Address.TextColor3 = Color3.new(0.627, 0.702, 0.976)
			else
				frame.BackgroundTransparency = 1
				frame.Location.TextColor3 = Color3.new(0, 0, 0)
				frame.Mode.TextColor3 = Color3.new(0, 0, 0)
				frame.Address.TextColor3 = Color3.new(0, 0, 0)
			end
		end

		LCD.SpecificOutputDevices.List.Position = LCD.SpecificOutputDevices.List.Position + UDim2.new(0, 0, 0, -frameHeight)
	end
end

-- Function to shift frames up
local function shiftFramesUp_OUTPUTZONES_CERTAIN()
	if currentFrameIndex_OUTPUTZONES_CERTAIN > 1 then
		currentFrameIndex_OUTPUTZONES_CERTAIN = currentFrameIndex_OUTPUTZONES_CERTAIN - 1
		local frameHeight = LCD.SpecificOutputDevices.List.Template.Size.Y.Offset

		for i, frame in ipairs(frames_OUTPUTZONES_CERTAIN) do
			if i == currentFrameIndex_OUTPUTZONES_CERTAIN then
				frame.BackgroundTransparency = 0
				frame.Location.TextColor3 = Color3.new(0.627, 0.702, 0.976)
				frame.Mode.TextColor3 = Color3.new(0.627, 0.702, 0.976)
				frame.Address.TextColor3 = Color3.new(0.627, 0.702, 0.976)
			else
				frame.BackgroundTransparency = 1
				frame.Location.TextColor3 = Color3.new(0, 0, 0)
				frame.Mode.TextColor3 = Color3.new(0, 0, 0)
				frame.Address.TextColor3 = Color3.new(0, 0, 0)
			end
		end

		LCD.SpecificOutputDevices.List.Position = LCD.SpecificOutputDevices.List.Position + UDim2.new(0, 0, 0, frameHeight)
	end
end

-- Main Execution
addZoneToListOUTPUT_CERTAIN()
initializeFrames9()

-- CONVERT TO STRING

local function convertStringToNumbers(inputString)
	if #inputString > 4 then
		inputString = string.sub(inputString, 1, 4)
	end

	inputString = string.rep("0", 4 - #inputString) .. inputString

	return inputString
end
-- CHECK DISABLEMENTS



local function updateTotalDisabled()
	local TotalDisabled = 0

	for _, zone in ipairs(ZoneDisablementTable) do
		local isDisabled = zone.Callpoints or zone.Detectors or zone.allInputs

		if isDisabled then
			TotalDisabled = TotalDisabled + 1
		end
	end

	if AllOutputsDisabled or AllBeaconsDisabled or AllSoundersDisabled or AllOtherRelaysDisabled then
		TotalDisabled = totalFrames_ZONES
	end

	local disabledOutputTable = {}

	for a, device in ipairs(OutputsDisabled) do

		if device.Disabled == true then

			if not table.find(disabledOutputTable, device.Zone) then
				table.insert(disabledOutputTable, device.Zone)
			end

		end
	end

	TotalDisabled = TotalDisabled + tonumber(#disabledOutputTable)

	LCD.ZoneInput.Header.ZoneController.Text = "[  " .. tostring(TotalDisabled) .. " ZONE(s) with INPUTS DISABLED  ]"
	LCD.Home.Info.Disablements.Text = adjustString("   " .. tostring(TotalDisabled) .. " Zone(s) With Disablements         More>")
end
-- LCD.ZoneInput.Header.ZoneController.Text = "[  " .. TotalDisabled .." ZONE(s) with INPUTS DISABLED  ]"

updateTotalDisabled()


local function AutoLearn(LoopVal)

	LCD.AutoLearn.DataHeaders.Visible = false
	LCD.AutoLearn.Data.Visible = false
	LCD.AutoLearn.ControlHeader.Text = "[ Auto Learn Loop ".. LoopVal .."  ]"
	LCD.AutoLearn.Data.Text = "   0    0    0    0    0    0    0    0    0"
	LCD.AutoLearn.Address.Text = "Address 000"
	LCD.AutoLearn.DevicesFound.Text = "Devices found   =   0"

	local deviceCount = 0 

	local MCP_Loop = 0
	local Sounders_Loop = 0
	local Opt_Loop = 0
	local Heat_Loop = 0
	local Multi_Loop = 0
	local ION_Loop = 0
	local Other_Loop = 0
	local IO_Loop = 0
	local ZoneMonitorUnit_Loop = 0

	local function formatDeviceID(deviceID)
		return string.format("%03d", tonumber(deviceID))
	end


	for _, model in pairs(DevicesFolder:GetChildren()) do
		if model:IsA("Model") then

			local modelLoop = model:GetAttribute("Loop")
			if modelLoop == LoopVal then

				local vents = model:FindFirstChild("Vents")



				deviceCount = deviceCount + 1
				LCD.AutoLearn.DevicesFound.Text = "Devices Found = " .. deviceCount

				local deviceID = model:GetAttribute("DeviceID")
				if deviceID then
					LCD.AutoLearn.Address.Text = "Address " .. formatDeviceID(deviceID)
				end

				local ModelScript = model:FindFirstChildOfClass("Script")
				if ModelScript:FindFirstChildOfClass("StringValue") then




					local stringVal = ModelScript:FindFirstChildOfClass("StringValue")

					if stringVal.Name == "MCP" then
						MCP_Loop = MCP_Loop + 1
					elseif stringVal.Name == "SOUNDER" then
						Sounders_Loop = Sounders_Loop + 1
					elseif stringVal.Name == "MULTISENSOR" then

						if vents and vents.Transparency == 0 then
							Multi_Loop = Multi_Loop + 1
						end

					elseif stringVal.Name == "OPTICALDETECTOR" then

						if vents and vents.Transparency == 0 then
							Opt_Loop = Opt_Loop + 1
						end

					elseif stringVal.Name == "HEATDETECTOR" then

						if vents and vents.Transparency == 0 then
							Heat_Loop = Heat_Loop + 1
						end

					elseif stringVal.Name == "IO" then
						IO_Loop = IO_Loop + 1
					elseif stringVal.Name == "ZMU" then
						ZoneMonitorUnit_Loop = ZoneMonitorUnit_Loop + 1
					elseif stringVal.Name == "ION" then

						if vents and vents.Transparency == 0 then
							ION_Loop = ION_Loop + 1
						end

					end

				end

				wait(math.random(0.2, 5))


			end
		end
	end

	for i, v in ipairs(FaultTable) do
		if v.Loop == LoopVal then

			NetAPI:Fire("RemoveFault", LoopVal, "Device Missing")

			if v.Fault == "Device Missing" then

				table.remove(FaultTable, i)

				if #FaultTable == 0 then

					InFault = false
					script.Flash_Fault.Value = false
					FlashOrange_Fault()
					Fault:Stop()

					LCD.Fault.Visible = false
					LCD.Home.Info.Fault.Visible = false
					LCD.Home.Logo.Visible = true
					LCD.Home.FaultContact.Visible = false

					LEDs.Fault.Color = Color3.new(0.192157, 0.192157, 0.196078)

					if LCD.Home.Info.Disablements.Visible == false then
						LCD.Home.Instructions.Visible = true
					end

				end

			end

		end
	end

	LCD.AutoLearn.DataHeaders.Visible = true
	LCD.AutoLearn.Data.Visible = true
	LCD.AutoLearn.Data.Text = "   " .. Opt_Loop .."    " .. ION_Loop .."    " .. Multi_Loop .."    " .. Heat_Loop .."    " .. MCP_Loop .."    " .. Sounders_Loop .."    " .. IO_Loop .."    " .. ZoneMonitorUnit_Loop .."    " .. Other_Loop ..""

end

function checkDisablements()
	if AllSoundersDisabled then
		LEDs.SounderDisabled.Color = Color3.new(1, 0.52549, 0.184314)
	else
		LEDs.SounderDisabled.Color = Color3.new(0.192157, 0.192157, 0.196078)
	end

	updateTotalDisabled()

	local isAnyZoneDisabled = false



	LEDs.Disablement.Color = Color3.new(1, 0.52549, 0.184314)

	if AllOutputsDisabled == false and AllSoundersDisabled == false and AllBeaconsDisabled == false and AllOtherRelaysDisabled == false and FaultRoutingDisabled == false and FireRoutingDisabled == false and FireProtectionDisabled == false then
		LEDs.Disablement.Color = Color3.new(0.192157, 0.192157, 0.196078)
	end

	if not script.Parent.Backing:FindFirstChild("Routing") then
		if FireRoutingDisabled == false or FaultRoutingDisabled == false then
			
			LEDs.FireRouting_Fault.Color = Color3.new(1, 0.52549, 0.184314)
			
			
		elseif FireRoutingDisabled and FaultRoutingDisabled == true then
			
			LEDs.FireRouting_Fault.Color = Color3.new(0.192157, 0.192157, 0.196078)
			
		end
		
		
	else
		
		LEDs.FireRouting_Fault.Color = Color3.new(0.192157, 0.192157, 0.196078)
		
	end

	if FireRoutingDisabled == true then
		LEDs.FireRouting_Disabled.Color = Color3.new(1, 0.52549, 0.184314)
	else
		LEDs.FireRouting_Disabled.Color = Color3.new(0.192157, 0.192157, 0.196078)
	end

	for _, zone in ipairs(ZoneDisablementTable) do
		if zone.Callpoints or zone.Detectors or zone.allInputs or AllBeaconsDisabled or AllOutputsDisabled or AllSoundersDisabled or AllOtherRelaysDisabled then
			isAnyZoneDisabled = true
			LEDs.Disablement.Color = Color3.new(1, 0.52549, 0.184314)
			break
		end
	end

	for _, output in ipairs(OutputsDisabled) do
		if output.Disabled == true then
			LEDs.SounderDisabled.Color = Color3.new(1, 0.52549, 0.184314) -- "Disabled" color
			LEDs.Disablement.Color = Color3.new(1, 0.52549, 0.184314)
			isAnyZoneDisabled = true
			break
		end
	end

	if isAnyZoneDisabled then
		LEDs.Disablement.Color = Color3.new(1, 0.52549, 0.184314)
		LEDs.Disablement.Material = Enum.Material.Neon
		LCD.Home.Instructions.Visible = false
		LCD.Home.Info.Disablements.Visible = true
	else
		LEDs.Disablement.Color = Color3.new(0.192157, 0.192157, 0.196078)
		LCD.Home.Info.Disablements.Visible = false

		if InFault then
			LCD.Home.Instructions.Visible = false
			LCD.Home.Info.Fault.Visible = true
		else
			LCD.Home.Instructions.Visible = true
		end
	end
	
	if AllOutputsDisabled == true or AllSoundersDisabled == true or AllBeaconsDisabled == true or AllOtherRelaysDisabled == true or FaultRoutingDisabled == true or FireRoutingDisabled == true or FireProtectionDisabled == true then
		LEDs.Disablement.Color = Color3.new(1, 0.52549, 0.184314)
	end
	
end

checkDisablements()


-- FUNCTION BUTTONS

Buttons.Silence.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()

	if LoggedIn == true then

	if InAlarm == true or InEvac == true or InTrouble == true and LoggedIn == true then

		if Whitelist == true then
			if plr:GetRankInGroup(GID) >= GR then
				script.Flash.Value = false
				wait(0.1)

				if InEvac == true then
					LEDs.Fire.Color = Color3.new(1, 0, 0)	
				end

				LEDs.SounderSilence.Color = Color3.new(1, 0.52549, 0.184314)
				wait(DelayTime)
				NetAPI:Fire("Silence")
			end
		else

			script.Flash.Value = false
			wait(0.1)
			if InEvac == true then
				LEDs.Fire.Color = Color3.new(1, 0, 0)	
			end
			LEDs.SounderSilence.Color = Color3.new(1, 0.52549, 0.184314)
			wait(DelayTime)
			NetAPI:Fire("Silence")

		end

		if InFault == true and LoggedIn == true then
			Fault:Stop()
			script.Flash_Fault.Value = false
			wait(0.01)
			LEDs.Fault.Color = Color3.new(1, 0.52549, 0.184314)
		end
	
	end

	elseif LoggedIn == false then

		MakeFramesVisible(false)

		FunctionToComplete = "Silence"

		LCD.Password.Visible = true
	end
end)

Buttons.Evacuate.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()

	if LoggedIn == true then

		if Whitelist == true then

			if plr:GetRankInGroup(GID) >= GR then
				wait(DelayTime)
				NetAPI:Fire("Evacuate", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))
			end
		else

			wait(DelayTime)
			NetAPI:Fire("Evacuate", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))
		end

	elseif LoggedIn == false then

		MakeFramesVisible(false)

		FunctionToComplete = "Evacuate"

		LCD.Password.Visible = true


	end
end)

Buttons.Mute.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if InAlarm == true then
		if Whitelist == true then
			if plr:GetRankInGroup(GID) >= GR then
				Buzzer:Stop()
				script.Flash.Value = false
				wait(1)

				if InEvac then
					LEDs.Fire.Color = Color3.new(1, 0, 0)	
				end


			end
		else
			Buzzer:Stop()
			script.Flash.Value = false
			wait(1)

			if InEvac then
				LEDs.Fire.Color = Color3.new(1, 0, 0)	
			end

		end

	elseif InFault == true then
		if Whitelist == true then
			if plr:GetRankInGroup(GID) >= GR then

				if LCD.Fault.Visible == true then
					LCD.Fault.Visible = false

					if InAlarm == true then

						LCD.Alarm.Visible = true

					else

						LCD.Home.Visible = true

					end

				end

				Fault:Stop()
				script.Flash_Fault.Value = false
				wait(1)
				LEDs.Fault.Color = Color3.new(1, 0.52549, 0.184314)
			end
		else

			if LCD.Fault.Visible == true then
				LCD.Fault.Visible = false

				if InAlarm == true then

					LCD.Alarm.Visible = true

				else

					LCD.Home.Visible = true

				end

			end

			Fault:Stop()
			script.Flash_Fault.Value = false
			wait(1)
			LEDs.Fault.Color = Color3.new(1, 0.52549, 0.184314)
		end

	end
end)

Buttons.Reset.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	wait(1)

	if LoggedIn == true then

		if Whitelist == true then
			if plr:GetRankInGroup(GID) >= GR then



				if LCD.Alarm.OutputDelay.Visible == true and LCD.Alarm.Visible == true then


					NetAPI:Fire("Reset")


				end

				LEDs.Fire.Color = Color3.new(0.192157, 0.192157, 0.196078)
				LEDs.SounderSilence.Color = Color3.new(0.192157, 0.192157, 0.196078)
				InAlarm = false
				for i, v in ipairs(LEDs:GetDescendants()) do
					if v:IsA("BasePart") and v.Name:sub(1, 1) == "Z" then
						v.Color = Color3.new(0.192157, 0.192157, 0.196078)
					end
				end
				wait(DelayTime)
				NetAPI:Fire("Reset")
				LCD.Alarm.Visible = false
				LCD.Home.Visible = true
			end
		else



			if LCD.Alarm.OutputDelay.Visible == true and LCD.Alarm.Visible == true then

				NetAPI:Fire("Reset")


			end

			LEDs.Fire.Color = Color3.new(0.192157, 0.192157, 0.196078)
			LEDs.SounderSilence.Color = Color3.new(0.192157, 0.192157, 0.196078)

			for i, v in ipairs(LEDs:GetDescendants()) do
				if v:IsA("BasePart") and v.Name:sub(1, 1) == "Z" then
					v.Color = Color3.new(0.192157, 0.192157, 0.196078)
				end
			end
			wait(DelayTime)
			NetAPI:Fire("Reset")
			InAlarm = false
			LCD.Alarm.Visible = false
			LCD.Home.Visible = true
		end

	elseif LoggedIn == false then
		MakeFramesVisible(false)

		FunctionToComplete = "Reset"

		wait(0.01)
		LCD.Password.Visible = true
	end
end)



local SoftwareUi_TimedEvents = script.Parent.Backing.PC_Connection.TimedEvent

-- KEY (PANEL OPEN)
local Locked = true
local PanelLockDB = false
Panel.Panel.Lock.Touched:Connect(function(part)
	if part.Parent:FindFirstChild("NX:PanelKey") then


		if PanelLockDB == false then
			PanelLockDB = true

			if Locked == true then
				Locked = false
				Hinge.TargetAngle = 105

				if script.Parent.Backing.PC_Connection then
					script.Parent.Backing.PC_Connection.ProximityPrompt.Enabled = true


				end

			else
				Locked = true
				Hinge.TargetAngle = 0

				if script.Parent.Backing.PC_Connection then
					script.Parent.Backing.PC_Connection.ProximityPrompt.Enabled = false

					SoftwareUi_TimedEvents.Parent = script.Parent.Backing.PC_Connection


				end

			end
			wait(1)
			PanelLockDB = false
		end
	end
end)

-- PROX
local prox = script.Parent.Backing.PC_Connection.ProximityPrompt

prox.Triggered:Connect(function(plr)
	if Whitelist == true then

		if plr:GetRankInGroup(GID) >= GR then


			local character = plr.Character



			if character:FindFirstChildOfClass("Tool") then	
				local tool = character:FindFirstChildOfClass("Tool")
				if tool:FindFirstChild("NX:LaptopTimedEvents") then

					tool.Ui.Value = SoftwareUi_TimedEvents
					tool.Panel.Value = script.Parent.Backing.PC_Connection

					local playerui = plr.PlayerGui

					SoftwareUi_TimedEvents.Parent = playerui




				end

			end
		end

	else

		local character = plr.Character



		if character:FindFirstChildOfClass("Tool") then	
			local tool = character:FindFirstChildOfClass("Tool")
			if tool:FindFirstChild("NX:LaptopTimedEvents") then

				tool.Ui.Value = SoftwareUi_TimedEvents
				tool.Panel.Value = script.Parent.Backing.PC_Connection

				local playerui = plr.PlayerGui

				SoftwareUi_TimedEvents.Parent = playerui




			end

		end


	end

end)

local function isAlarmInTable(alarmTable, name, loc, id)
	for _, alarm in ipairs(alarmTable) do
		if alarm.Name == name and alarm.Loc == loc and alarm.ID == id then
			return true
		end
	end
	return false
end



-- BINDABLE EVENT

local ZonesInFire = {}
local AZonesInFire = 0
local FireStarted = false
-- API:Fire("Evacuate", DeviceName, DeviceID, DeviceZone, "Callpoint", "Fire OR LOCATION")

local function updateLCDActivationType(type)
	local activationText = {
		Callpoint = "<CALL POINT >",
		Detector = "<DETECTOR >",
		Panel = "<PANEL >",
		Test = "<TEST >",
		Keyswitch = "<KEYSWITCH >"
	}
	LCD.Alarm.Activation.Text = activationText[type] or "<UNKNOWN >"
end

function addZoneAndDevice(zoneId, deviceName, deviceId, deviceLoc)
	if not table.find(ZonesInAlarm, zoneId) then
		table.insert(ZonesInAlarm, zoneId)
		addZoneToList_MoreAlarms()
	end

	if not isAlarmInTable(DeviceTextInAlarm, zoneId, deviceLoc, deviceId) then
		table.insert(DeviceTextInAlarm, { Name = zoneId, Loc = deviceLoc, ID = deviceId })
	end
end

function updateZoneLED(zoneId)
	if LEDs:FindFirstChild("Z" .. zoneId) then
		LEDs:WaitForChild("Z" .. zoneId).Color = Color3.new(1, 0, 0)
	end
end

function updateZoneFireList(zoneId)
	local alreadyAdded = false
	for _, v in ipairs(ZonesInFire) do
		if v == zoneId then
			alreadyAdded = true
			break
		end
	end
	if not alreadyAdded then
		AZonesInFire += 1
		table.insert(ZonesInFire, zoneId)
	end
end

NetAPI.Event:Connect(function(data, data1, data2, data3, data4, data5, data6, data7, data8)

	if script.PoweredOn.Value == true then

		if data == "Evacuate" and CheckPriority("Evac") then
			addZoneAndDevice(data3, data1, data2, data5)
			if not InEvac then
				InEvac, InAlarm, InTrouble = true, false, false
				Buzzer:Play()
				MakeFramesVisible(false)
				LCD.Alarm.Visible = true
				LEDs.PreAlarm.Color = Color3.new(0.192157, 0.192157, 0.196078)
				
				if FireRoutingDisabled == false then
				LEDs.FireRouting_Activated.Color = Color3.new(1, 0, 0)
				end
				
				if FireProtectionDisabled == false then
					LEDs.FireProtection.Color = Color3.new(1, 0, 0)
				end
				
				LCD.Alarm.OutputDelay.Visible = false
				LCD.Alarm.DeviceName.Text = data1
				updateZoneFireList(data3)
				LCD.Alarm.Zone.Text = "[      ".. AZonesInFire .."    Zones in Fire.             Zone ".. data3 .."]"
				if not FireStarted then
					FireStarted = true
					LCD.Alarm.Header.Zone.Text = " FIRE STARTED IN ZONE " .. data3
				end
				LCD.Alarm.DeviceID.Text = data2
				updateLCDActivationType(data4)
				updateZoneLED(data3)
				if not script.Flash.Value then
					script.Flash.Value = true
					task.delay(0.1, FlashRed_Fire)
				end
			end

		elseif data == "MainsPower" then
			if data1 == "Disconnect" then
				script.Flash_Power.Value = true
				FlashGreen_Power()


			elseif data1 == "Connect" then
				script.Flash_Power.Value = false
				wait(0.1)
				FlashGreen_Power()
				LEDs.Power.Color = Color3.new(0.411765, 0.886275, 0.0980392)
				wait(1)		
				LEDs.Power.Color = Color3.new(0.411765, 0.886275, 0.0980392)


			end

		elseif data == "PreAlarm" and CheckPriority("Custom") then
			PreAlarmCount += 1
			addZoneAndDevice(data3, data1, data2, data5)

			if Config.PreAlarmOverride and PreAlarmCount >= 2 then
				NetAPI:Fire("Evacuate", data1, data2, data3, "Detector", data5)
				return
			end
			MakeFramesVisible(false)
			LCD.PreAlarm.Visible = true
			LCD.PreAlarm.Zone.Text = "ZONE " .. convert0000Format(data3)
			LCD.PreAlarm.ZoneLocation.Text = string.upper(ZoneLocations[data3] or "UNKNOWN")
			LCD.PreAlarm.Location.Text = string.upper(data5)
			updateLCDActivationType(data4)
			LEDs.PreAlarm.Color = Color3.new(1, 0.52549, 0.184314)

		elseif data == "InvestigationFIRE" and CheckPriority("Evac") then
			addZoneAndDevice(data3, data1, data2, data5)
			InEvac, InTrouble = true, false
			Buzzer:Play()
			MakeFramesVisible(false)
			LCD.Alarm.Visible = true
			LCD.Alarm.OutputDelay.Visible = true
			LCD.Alarm.OutputDelay.Text = "OUTPUT DELAY   " .. InvestigationDelay .. " s"
			LCD.Alarm.DeviceName.Text = data1
			LCD.Alarm.DeviceID.Text = data2
			updateZoneFireList(data3)
			LCD.Alarm.Zone.Text = "[      ".. AZonesInFire .."    Zones in Fire.             Zone ".. data3 .."]"
			updateLCDActivationType(data4)
			updateZoneLED(data3)
			if FireStarted == false then
				FireStarted = true
				LCD.Alarm.Header.Zone.Text = " FIRE STARTED IN ZONE " .. data3
			end
			if InvestDelayONCE then
				NetAPI:Fire("InvestigationDelay", false)
			end
			NetAPI:Fire("COUNTOWN", InvestigationDelay)
			task.spawn(function()
				for i = InvestigationDelay, 1, -1 do
					LCD.Alarm.OutputDelay.Text = "OUTPUT DELAY   " .. i .. " s"
					wait(1)
				end
				NetAPI:Fire("Evacuate", data1, data2, data3, data4, data5)
			end)

		elseif data == "Silence" then
			script.Flash.Value = false
			wait(0.1)

			if InEvac == true then
				LEDs.Fire.Color = Color3.new(1, 0, 0)	
			end

			LEDs.SounderSilence.Color = Color3.new(1, 0.52549, 0.184314)

		elseif data == "RemoveFault" then

			-- Iterate through the FaultTable
			for i, v in ipairs(FaultTable) do
				-- Check if the current loop and fault match the provided data
				if v.Loop == data1 and v.Fault == data2 then
					-- Remove the fault entry from the FaultTable
					table.remove(FaultTable, i)

					-- Check if the FaultTable is now empty
					if #FaultTable == 0 then
						-- Reset fault-related states
						InFault = false
						script.Flash_Fault.Value = false

						-- Stop flashing and reset LEDs
						FlashOrange_Fault()
						Fault:Stop()
						LEDs.Fault.Color = Color3.new(0.192157, 0.192157, 0.196078)

						-- Update the LCD display
						LCD.Fault.Visible = false
						LCD.Home.Info.Fault.Visible = false
						LCD.Home.Logo.Visible = true
						LCD.Home.FaultContact.Visible = false

						-- Check if Disablements section is hidden and show Instructions
						if not LCD.Home.Info.Disablements.Visible then
							LCD.Home.Instructions.Visible = true
						end
					end

					-- Exit the loop as the fault has been handled
					-- break
				end
			end


		elseif data == "COUNTDOWN" then

			Countdown = data1



		elseif data == "Update" then
			if Config.InvestigationDelay.Active == true then
				LEDs.Delay.Color = Color3.new(1, 0.52549, 0.184314)
				LCD.Delay.Function.NoInvestigationDelay.Text = "   NO INVESTIGATION DELAY"
			else
				LEDs.Delay.Color = Color3.new(0.192157, 0.192157, 0.196078)
				LCD.Delay.Function.NoInvestigationDelay.Text = "   INVESTIGATION DELAY"
			end



		elseif data == "Trouble" and CheckPriority("Trouble") then
			if not InAlarm or not InTrouble then
				InTrouble, InAlarm = true, true
				addZoneAndDevice(data3, data1, data2, data5)
				Buzzer:Play()
				MakeFramesVisible(false)
				LCD.AlarmCondition.Visible = true
				LCD.AlarmCondition.Zone.Text = "ZONE " .. convert0000Format(data3)
				LCD.AlarmCondition.ZoneLocation.Text = string.upper(ZoneLocations[data3] or "UNKNOWN")
				LCD.AlarmCondition.Location.Text = string.upper(data5)
				LCD.AlarmCondition.AlarmType.Text = string.upper(data6 or "TROUBLE")
				updateLCDActivationType(data4)
				LCD.AlarmCondition.AlarmCount.Zone.Text = "   ".. #ZonesInAlarm .." Zone In Alarm                      More>"
				updateZoneLED(data3)
			end

		elseif data == "Fault" then

			local found = false
			local indexToRemove = nil

			if data5 == "ALL" then
				-- Check if "ALL" fault is already present
				for i, v in ipairs(FaultTable) do
					if v.Zone == "ALL" then
						found = true
						indexToRemove = i
						break
					end
				end

				if found then
					-- Remove the existing "ALL" fault
					table.remove(FaultTable, indexToRemove)
					MainsFault = false
					previousAmountOfFaults = math.max(0, previousAmountOfFaults - 1)
				else
					-- Set MainsFault to true since "ALL" is not in the table
					MainsFault = true
					local previousFaults = FaultTable
					FaultTable = {}
					previousAmountOfFaults = 0
					InFault = false
					script.Flash_Fault.Value = false
					FlashOrange_Fault()
					Fault:Stop()
					LCD.Home.Info.Fault.Visible = false
					LCD.Home.Logo.Visible = true
					LCD.Home.FaultContact.Visible = false
					LEDs.Fault.Color = Color3.new(0.192157, 0.192157, 0.196078)

					if not LCD.Home.Info.Disablements.Visible then
						LCD.Home.Instructions.Visible = true
					end

					if LCD.Fault.Visible then
						LCD.Fault.Visible = false
						LCD.Home.Visible = true
					end

					-- Restore previous faults except for "ALL"
					for _, v in ipairs(previousFaults) do
						if v.Zone ~= "ALL" then
							table.insert(FaultTable, v)
							previousAmountOfFaults = previousAmountOfFaults + 1
						end
					end
				end
			else
				-- Find and remove the existing fault if it already exists
				for i = #FaultTable, 1, -1 do
					if FaultTable[i].Zone == data5 and FaultTable[i].Add == data3 then
						table.remove(FaultTable, i)
						previousAmountOfFaults = math.max(0, previousAmountOfFaults - 1)
						addZoneToList_FaultView()
						found = true
					end
				end
			end

			if not found then
				-- First time detecting this fault
				previousAmountOfFaults = previousAmountOfFaults + 1
				table.insert(FaultTable, {Fault = data1, Add = data3, Loop = data4, Zone = data5})
				addZoneToList_FaultView()
				LCD.Fault.Visible = true
				Fault:Play()
				LCD.Home.Info.Fault.Visible = true
				LCD.Home.Logo.Visible = false
				LCD.Home.FaultContact.Visible = true
				LCD.Home.Instructions.Visible = false
				InFault = true
			else
				-- Fault detected again, remove it and check if others exist
				if #FaultTable == 0 then
					InFault = false
					script.Flash_Fault.Value = false
					FlashOrange_Fault()
					Fault:Stop()
					LCD.Home.Info.Fault.Visible = false
					LCD.Home.Logo.Visible = true
					LCD.Home.FaultContact.Visible = false
					LEDs.Fault.Color = Color3.new(0.192157, 0.192157, 0.196078)

					if not LCD.Home.Info.Disablements.Visible then
						LCD.Home.Instructions.Visible = true
					end

					if LCD.Fault.Visible then
						LCD.Fault.Visible = false
						LCD.Home.Visible = true
					end
				end
			end

			LCD.Fault.Zone.Text = "ZONE " .. convert0000Format(data2)
			LCD.Fault.Fault.Text = string.upper(data1)
			LCD.Fault.ZoneLocation.Text = ZoneLocations[data2] or "CANNOT FIND"
			LCD.Fault.Device.Text = string.upper(data6)
			LCD.Fault.Location.Text = string.upper(data7)

			local faultCountText = 0

			if MainsFault == true then
				faultCountText = totalFrames_ZONES
			else
				faultCountText = previousAmountOfFaults
			end

			LCD.Home.Info.Fault.Text = adjustString("   " .. faultCountText .. " Zone(s) In Fault                  More>")
			LCD.Fault.Header.Zone.Text = adjustString("   " .. faultCountText .. " Zone(s) In Fault                  More>")

			if #FaultTable ~= 0 then
				script.Flash_Fault.Value = true
				FlashOrange_Fault()
			else
				script.Flash_Fault.Value = false
				FlashOrange_Fault()
			end









		elseif data == "ClassChange" and CheckPriority("ClassChange") then
			if not InAlarm then
				InAlarm, InClassChange = true, true
				addZoneAndDevice(data3, data1, data2, data5)
				Buzzer:Play()
				MakeFramesVisible(false)
				LCD.AlarmCondition.Visible = true
				LCD.AlarmCondition.Zone.Text = "ZONE " .. convert0000Format(data3)
				LCD.AlarmCondition.ZoneLocation.Text = string.upper(ZoneLocations[data3] or "UNKNOWN")
				LCD.AlarmCondition.Location.Text = string.upper(data5)
				LCD.AlarmCondition.AlarmType.Text = "CLASSCHANGE"
				updateLCDActivationType(data4)
				LCD.AlarmCondition.AlarmCount.Zone.Text = "   ".. #ZonesInAlarm .." Zone In Alarm                      More>"
				updateZoneLED(data3)
				wait(Config.ClassChangeTime)
				NetAPI:Fire("Reset")
			end

		elseif (data == "Alarm" or data == "CauseEffect") and CheckPriority("Custom") then
			if not InAlarm then
				InAlarm = true
				addZoneAndDevice(data3, data1, data2, data5)
				Buzzer:Play()
				MakeFramesVisible(false)
				LCD.AlarmCondition.Visible = true
				LCD.AlarmCondition.Zone.Text = "ZONE " .. convert0000Format(data3)
				LCD.AlarmCondition.ZoneLocation.Text = string.upper(ZoneLocations[data3] or "UNKNOWN")
				LCD.AlarmCondition.Location.Text = string.upper(data5)
				LCD.AlarmCondition.AlarmType.Text = string.upper(data6 or data)
				updateLCDActivationType(data4)
				LCD.AlarmCondition.AlarmCount.Zone.Text = "   ".. #ZonesInAlarm .." Zone In Alarm                      More>"
				updateZoneLED(data3)
				
			end





		elseif data == "TestMode" then







			local found = false

			local frame = LCD.ZoneInput_Test.List:FindFirstChild("ZoneFrame_" .. data2	)	

			local ZoneNumber = data2

			for a, zone in ipairs(ZonesInTest) do

				if data1 == "CLEAR_ALL" then
					ClearTestTables()
					LEDs.Test.Color = Color3.new(0.192157, 0.192157, 0.196078)
				end

				if zone == frame then
					found = true
					table.remove(ZonesInTest, a)
					frame.Mode.Text = "   -"

					AmountOfZonesINTEST = AmountOfZonesINTEST - 1



					if #ZonesInTest == 0 then
						LEDs.Test.Color = Color3.new(0.192157, 0.192157, 0.196078)
					end



					break
				end
			end


			if not found then
				table.insert(ZonesInTest, frame)
				frame.Mode.Text = "IN TEST"

				AmountOfZonesINTEST = AmountOfZonesINTEST + 1
				LEDs.Test.Color = Color3.new(1, 0.52549, 0.184314)


			end



			LCD.ZoneInput_Test.Header.ZoneController.Text = "[  " .. AmountOfZonesINTEST .. " ZONE(s) in Test ]"



		elseif data == "Delay" then
			DelayTime = data1
		elseif data == "InvestigationDelay" then
			if data1 == true then
				LEDs.Delay.Color = Color3.new(1, 0.52549, 0.184314)
			else
				LEDs.Delay.Color = Color3.new(0.192157, 0.192157, 0.196078)
			end

		elseif data == "Reset" then
			AZonesInFire = 0
			InTrouble = false
			InEvac = false
			InAlarm = false
			InClassChange = false
			for i, v in ipairs(LEDs:GetDescendants()) do
				if v:IsA("BasePart") and v.Name:sub(1, 1) == "Z" then
					v.Color = Color3.new(0.192157, 0.192157, 0.196078)
				end
			end

			ZonesInAlarm = {}
			DeviceTextInAlarm = {}

			addZoneToList_MoreAlarms()

			for i, v in ipairs(LEDs:GetDescendants()) do
				if v:IsA("BasePart") and v.Name:sub(1, 1) == "F" then
					if v.Name ~= "Fault" then
						v.Color = Color3.new(0.192157, 0.192157, 0.196078)
					end
				end
			end
			Countdown = 90000000000
			script.Flash.Value = false
			wait(1)

			ZonesInFire = {}

			LEDs.PreAlarm.Color = Color3.new(0.192157, 0.192157, 0.196078)

			LEDs.Fire.Color = Color3.new(0.192157, 0.192157, 0.196078)
			LEDs.SounderSilence.Color = Color3.new(0.192157, 0.192157, 0.196078)
			Buzzer:Stop()

			MakeFramesVisible(false)

			LCD.Alarm.Visible = false
			LCD.Home.Visible = true

			LEDs.Power.Color = Color3.new(0.411765, 0.886275, 0.0980392)

			if Config.InvestigationDelay.Active == true then
				LEDs.Delay.Color = Color3.new(1, 0.52549, 0.184314)
			end

			LEDs.FireProtection.Color = Color3.new(0.192157, 0.192157, 0.196078)

			LEDs.MoreAlarms.Color = Color3.new(0.192157, 0.192157, 0.196078)
			LEDs.FireRouting_Activated.Color = Color3.new(0.192157, 0.192157, 0.196078)

			checkDisablements()

		elseif data == "Disable" then

			if data1 == "SO" then
				for i, device in ipairs(OutputsDisabled) do
					if device.Address == data2 then
						local DeviceZone = device.Zone
						device.Disabled = true

						-- Update SpecificOutputDevices UI
						for _, spDevice in ipairs(LCD.SpecificOutputDevices:GetChildren()) do
							if spDevice:IsA("Frame") and spDevice:FindFirstChild("ZONE") and spDevice.ZONE.Value == DeviceZone then
								spDevice.Mode.Text = "Disabled"
							end
						end

						-- Update Main Frame UI
						updateZoneUI(DeviceZone, OutputsDisabled)
					end
				end


			else
				local z0Ne = data2
				local z0NeDisablement = ZoneDisablementTable[z0Ne]
				local z0NeFrame = frames_ZONES[z0Ne]



				if data1 == "AllInputs" and z0NeDisablement then
					z0NeDisablement.allInputs = true
					z0NeDisablement.Detectors = true
					z0NeDisablement.Callpoints = true
					z0NeFrame.Mode.Text = "Disabled"
				elseif data1 == "Detectors" and z0NeDisablement then
					z0NeDisablement.Detectors = true
					z0NeFrame.Mode.Text = z0NeDisablement.Callpoints and "Disabled" or "Part-Disabled"
				elseif data1 == "Callpoints" and z0NeDisablement then
					z0NeDisablement.Callpoints = true
					z0NeFrame.Mode.Text = z0NeDisablement.Detectors and "Disabled" or "Part-Disabled"
				elseif data1 == "AllOutputs" then
					AllBeaconsDisabled = true
					AllOtherRelaysDisabled = true
					AllSoundersDisabled = true
					AllOutputsDisabled = true

					for i, device in ipairs(OutputsDisabled) do
						device.Disabled = true
					end

					LCD.OutputDisablement.Scroll1.AllSounders.Text = "   ALL SOUNDERS (D)"
					LCD.OutputDisablement.Scroll1.AllBeacons.Text = "   ALL BEACONS (D)"
					LCD.OutputDisablement.Scroll1.AllOtherRelay.Text = "   ALL OTHER RELAY OUTPUTS (D)"

					LCD.OutputDisablement.Scroll1.AllOutputs.Text = "   ALL OUTPUTS (D)"
				elseif data1 == "AllSounders" then
					AllSoundersDisabled = true
					LCD.OutputDisablement.Scroll1.AllSounders.Text = "   ALL SOUNDERS (D)"

					for i, device in ipairs(OutputsDisabled) do
						if device.Device == "SOUNDER" then
							device.Disabled = true
						end
					end

				elseif data1 == "AllBeacons" then
					AllBeaconsDisabled = true
					LCD.OutputDisablement.Scroll1.AllBeacons.Text = "   ALL BEACONS (D)"

					for i, device in ipairs(OutputsDisabled) do
						if device.Device == "BEACON" then
							device.Disabled = true
						end
					end

				elseif data1 == "AllOtherRelay" then
					AllOtherRelaysDisabled = true
					LCD.OutputDisablement.Scroll1.AllOtherRelay.Text = "   ALL OTHER RELAY OUTPUTS (D)"

					for i, device in ipairs(OutputsDisabled) do
						if device.Device == "RELAYS" then
							device.Disabled = true
						end
					end

				elseif data1 == "FaultRouting" then
					FaultRoutingDisabled = true
					LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.Text = "   FIRE ROUTING OUTPUTS (D)"
					
				elseif data1 == "FireProtection" then
					FireProtectionDisabled = true
					LCD.OutputDisablement.Scroll2.FireProtectionOutputs.Text = "  FIRE PROTECTION OUTPUTS (D)"

				elseif data1 == "FireRouting" then
					FireRoutingDisabled = true
					LCD.OutputDisablement.Scroll2.FireRoutingOutputs.Text = "   FIRE ROUTING OUTPUTS (D)"

				end

			end

			checkDisablements()



		elseif data == "Enable" then

			if data1 == "SO" then
				for i, device in ipairs(OutputsDisabled) do
					if device.Address == data2 then
						local DeviceZone = device.Zone
						device.Disabled = false

						-- Update SpecificOutputDevices UI
						for _, spDevice in ipairs(LCD.SpecificOutputDevices:GetChildren()) do
							if spDevice:IsA("Frame") and spDevice:FindFirstChild("ZONE") and spDevice.ZONE.Value == DeviceZone then
								spDevice.Mode.Text = "Enabled"
							end
						end

						-- Update Main Frame UI
						updateZoneUI(DeviceZone, OutputsDisabled)
					end
				end

			else

				local z0Ne = data2
				local z0NeDisablement = ZoneDisablementTable[z0Ne]
				local z0NeFrame = frames_ZONES[z0Ne]

				if data1 == "AllInputs" and z0NeDisablement then
					z0NeDisablement.allInputs = false
					z0NeDisablement.Detectors = false
					z0NeDisablement.Callpoints = false
					z0NeFrame.Mode.Text = "Enabled"
				elseif data1 == "Detectors" and z0NeDisablement then
					z0NeDisablement.Detectors = false
					z0NeFrame.Mode.Text = z0NeDisablement.Callpoints and "Part-Disabled" or "Enabled"
				elseif data1 == "Callpoints" and z0NeDisablement then
					z0NeDisablement.Callpoints = false
					z0NeFrame.Mode.Text = z0NeDisablement.Detectors and "Part-Disabled" or "Enabled"
				elseif data1 == "AllOutputs" then
					AllBeaconsDisabled = false
					AllOtherRelaysDisabled = false
					AllSoundersDisabled = false
					AllOutputsDisabled = false

					for i, device in ipairs(OutputsDisabled) do

						device.Disabled = false

					end

					LCD.OutputDisablement.Scroll1.AllSounders.Text = "   ALL SOUNDERS"
					LCD.OutputDisablement.Scroll1.AllBeacons.Text = "   ALL BEACONS"
					LCD.OutputDisablement.Scroll1.AllOtherRelay.Text = "   ALL OTHER RELAY OUTPUTS"

					LCD.OutputDisablement.Scroll1.AllOutputs.Text = "   ALL OUTPUTS"
				elseif data1 == "AllSounders" then
					AllSoundersDisabled = false

					for i, device in ipairs(OutputsDisabled) do
						if device.Device == "SOUNDER" then
							device.Disabled = false
						end
					end

					LCD.OutputDisablement.Scroll1.AllSounders.Text = "   ALL SOUNDERS"
					
				elseif data1 == "FireRouting" then
					FireRoutingDisabled = false
					LCD.OutputDisablement.Scroll2.FireRoutingOutputs.Text = "   FIRE ROUTING OUTPUTS"
					
				elseif data1 == "FaultRouting" then
					FaultRoutingDisabled = false
					LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.Text = "   FAULT ROUTING OUTPUTS"

				elseif data1 == "FireProtection" then
					FireProtectionDisabled = false
					LCD.OutputDisablement.Scroll2.FireProtectionOutputs.Text = "  FIRE PROTECTION OUTPUTS"
					
				elseif data1 == "AllBeacons" then
					AllBeaconsDisabled = false

					for i, device in ipairs(OutputsDisabled) do
						if device.Device == "BEACON" then
							device.Disabled = false
						end
					end

					LCD.OutputDisablement.Scroll1.AllBeacons.Text = "   ALL BEACONS"
				elseif data1 == "AllOtherRelay" then
					AllOtherRelaysDisabled = false

					for i, device in ipairs(OutputsDisabled) do
						if device.Device == "RELAYS" then
							device.Disabled = false
						end
					end

					LCD.OutputDisablement.Scroll1.AllOtherRelay.Text = "   ALL OTHER RELAY OUTPUTS"
				end

			end

			checkDisablements()
		end






	end
end)


function updateZoneUI(zone, devices)
	local hasDis = false
	local hasEn = false

	for _, device in ipairs(devices) do
		if device.Zone == zone then
			if device.Disabled then
				hasDis = true
			else
				hasEn = true
			end
		end
	end

	local MainFrame = nil
	for _, frame in ipairs(LCD.OutputDevices.List:GetChildren()) do
		if frame:IsA("Frame") and frame:FindFirstChild("ZONE") and frame.ZONE.Value == tostring(zone) then
			MainFrame = frame
			print("mainframe: " .. MainFrame.Name)
			break
		end
	end

	if MainFrame and MainFrame:FindFirstChild("Mode") and MainFrame.Mode:IsA("TextLabel") then
		if hasDis and hasEn then
			MainFrame.Mode.Text = "Part-Disabled"
		elseif hasDis then
			MainFrame.Mode.Text = "Disabled"
		else
			MainFrame.Mode.Text = "Enabled"
		end
	else
		warn("MainFrame or Mode not found for zone: " .. tostring(zone))
	end
end
-- BUTTONS



function ChangeLEDToBlack(LED)
	LED.Color = Color3.new(0.192157, 0.192157, 0.196078)
end

Buttons.MoreAlarms.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if InAlarm == true and LoggedIn == true then

		if Whitelist == true then

			if plr:GetRankInGroup(GID) >= GR then

				MakeFramesVisible(false)
				LCD.MoreAlarms.Visible = true

			end

		else

			MakeFramesVisible(false)
			LCD.MoreAlarms.Visible = true

		end

	end
end)

Buttons.F1.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if InAlarm == false and LoggedIn == true then
		if Whitelist == true then

			if plr:GetRankInGroup(GID) >= GR then

				LEDs.F1.Color = Color3.new(1, 0.52549, 0.184314)

				wait(DelayTime)
				if Functions.F1() then
					ChangeLEDToBlack(LEDs.F1)

				end

			end
		else

			LEDs.F1.Color = Color3.new(1, 0.52549, 0.184314)

			wait(DelayTime)
			if Functions.F1() then
				ChangeLEDToBlack(LEDs.F1)

			end
		end
	end
end)

Buttons.F2.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if InAlarm == false and LoggedIn == true then
		if Whitelist == true then
			if plr:GetRankInGroup(GID) >= GR then
				LEDs.F2_Press.Color = Color3.new(1, 0.52549, 0.184314)
				LEDs.F2.Color = Color3.new(1, 0.52549, 0.184314)

				wait(DelayTime)
				if Functions.F2() then
					ChangeLEDToBlack(LEDs.F2)
					ChangeLEDToBlack(LEDs.F2_Press)
				end

			end
		else
			LEDs.F2_Press.Color = Color3.new(1, 0.52549, 0.184314)
			LEDs.F2.Color = Color3.new(1, 0.52549, 0.184314)

			wait(DelayTime)
			if Functions.F2() then
				ChangeLEDToBlack(LEDs.F2)
				ChangeLEDToBlack(LEDs.F2_Press)
			end
		end
	end
end)

Buttons.F3.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if InAlarm == false and LoggedIn == true then
		if Whitelist == true then
			if plr:GetRankInGroup(GID) >= GR then
				LEDs.F3_Press.Color = Color3.new(1, 0.52549, 0.184314)
				LEDs.F3.Color = Color3.new(1, 0.52549, 0.184314)

				wait(DelayTime)
				if Functions.F3() then
					ChangeLEDToBlack(LEDs.F3)
					ChangeLEDToBlack(LEDs.F3_Press)
				end

			end
		else
			LEDs.F3_Press.Color = Color3.new(1, 0.52549, 0.184314)
			LEDs.F3.Color = Color3.new(1, 0.52549, 0.184314)

			wait(DelayTime)
			if Functions.F3() then
				ChangeLEDToBlack(LEDs.F3)
				ChangeLEDToBlack(LEDs.F3_Press)
			end
		end
	end
end)

Buttons.F4.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if InAlarm == false and LoggedIn == true then
		if Whitelist == true then
			if plr:GetRankInGroup(GID) >= GR then
				LEDs.F4_Press.Color = Color3.new(1, 0.52549, 0.184314)
				LEDs.F4.Color = Color3.new(1, 0.52549, 0.184314)

				wait(DelayTime)
				if Functions.F4() then
					ChangeLEDToBlack(LEDs.F4)
					ChangeLEDToBlack(LEDs.F4_Press)
				end

			end
		else
			LEDs.F4.Color = Color3.new(1, 0.52549, 0.184314)
			LEDs.F4_Press.Color = Color3.new(1, 0.52549, 0.184314)

			wait(DelayTime)
			if Functions.F4() then
				ChangeLEDToBlack(LEDs.F4)
				ChangeLEDToBlack(LEDs.F4_Press)
			end
		end
	end
end)

-- NUMBER BUTTON FUNCTION FOR LOOPS

function onNumberButtonClicked(number)
	if newZoneInput == "" then
		for a, framea in ipairs(frames_LOOPS) do
			if a == currentFrameIndex_LOOPS then
				previousZone = framea.Zone.Text
			end
		end
	end

	if #newZoneInput < 3 then  
		newZoneInput = newZoneInput .. tostring(number)  

		for i, frame in ipairs(frames_LOOPS) do
			if i == currentFrameIndex_LOOPS then
				frame.Zone.Text = convert000Format(newZoneInput)
			end
		end
	end
end

-- STILL BUTTONS: NUMBERS
Buttons.N1.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Password.Visible == true then
				L2_Input = L2_Input .. "1"

				if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
					LCD.Password.Frame.Frame.Password.Text = "*"
				else
					LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
				end


			elseif LCD.LoopDevices.Visible == true then



				onNumberButtonClicked("1")

			end


		end
	else
		if LCD.Password.Visible == true then
			L2_Input = L2_Input .. "1"

			if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
				LCD.Password.Frame.Frame.Password.Text = "*"
			else
				LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
			end

		elseif LCD.LoopDevices.Visible == true then

			onNumberButtonClicked("1")

		end
	end
end)

Buttons.N2.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Password.Visible == true then
				L2_Input = L2_Input .. "2"

				if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
					LCD.Password.Frame.Frame.Password.Text = "*"
				else
					LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
				end

			elseif LCD.LoopDevices.Visible == true then

				onNumberButtonClicked("2")

			end


		end
	else
		if LCD.Password.Visible == true then
			L2_Input = L2_Input .. "2"

			if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
				LCD.Password.Frame.Frame.Password.Text = "*"
			else
				LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
			end

		elseif LCD.LoopDevices.Visible == true then

			onNumberButtonClicked("2")

		end
	end
end)

Buttons.N3.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Password.Visible == true then
				L2_Input = L2_Input .. "3"

				if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
					LCD.Password.Frame.Frame.Password.Text = "*"
				else
					LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
				end

			elseif LCD.LoopDevices.Visible == true then

				onNumberButtonClicked("3")


			end


		end
	else
		if LCD.Password.Visible == true then
			L2_Input = L2_Input .. "3"

			if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
				LCD.Password.Frame.Frame.Password.Text = "*"
			else
				LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
			end

		elseif LCD.LoopDevices.Visible == true then

			onNumberButtonClicked("3")

		end
	end
end)

Buttons.N4.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Password.Visible == true then
				L2_Input = L2_Input .. "4"

				if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
					LCD.Password.Frame.Frame.Password.Text = "*"
				else
					LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
				end

			elseif LCD.LoopDevices.Visible == true then

				onNumberButtonClicked("4")

			end


		end
	else
		if LCD.Password.Visible == true then
			L2_Input = L2_Input .. "4"

			if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
				LCD.Password.Frame.Frame.Password.Text = "*"
			else
				LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
			end

		elseif LCD.LoopDevices.Visible == true then

			onNumberButtonClicked("4")

		end
	end
end)

Buttons.N5.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Password.Visible == true then
				L2_Input = L2_Input .. "5"

				if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
					LCD.Password.Frame.Frame.Password.Text = "*"
				else
					LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
				end

			elseif LCD.LoopDevices.Visible == true then

				onNumberButtonClicked("5")

			end


		end
	else
		if LCD.Password.Visible == true then
			L2_Input = L2_Input .. "5"

			if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
				LCD.Password.Frame.Frame.Password.Text = "*"
			else
				LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
			end

		elseif LCD.LoopDevices.Visible == true then

			onNumberButtonClicked("5")

		end
	end
end)

Buttons.N6.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Password.Visible == true then
				L2_Input = L2_Input .. "6"

				if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
					LCD.Password.Frame.Frame.Password.Text = "*"
				else
					LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
				end

			elseif LCD.LoopDevices.Visible == true then

				onNumberButtonClicked("1")

			end


		end
	else
		if LCD.Password.Visible == true then
			L2_Input = L2_Input .. "6"

			if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
				LCD.Password.Frame.Frame.Password.Text = "*"
			else
				LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
			end

		elseif LCD.LoopDevices.Visible == true then

			onNumberButtonClicked("1")

		end
	end
end)

Buttons.N7.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Password.Visible == true then
				L2_Input = L2_Input .. "7"

				if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
					LCD.Password.Frame.Frame.Password.Text = "*"
				else
					LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
				end

			elseif LCD.LoopDevices.Visible == true then

				onNumberButtonClicked("1")

			end


		end
	else
		if LCD.Password.Visible == true then
			L2_Input = L2_Input .. "7"

			if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
				LCD.Password.Frame.Frame.Password.Text = "*"
			else
				LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
			end

		elseif LCD.LoopDevices.Visible == true then

			onNumberButtonClicked("1")

		end
	end
end)

Buttons.N8.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Password.Visible == true then
				L2_Input = L2_Input .. "8"

				if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
					LCD.Password.Frame.Frame.Password.Text = "*"
				else
					LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
				end

			elseif LCD.LoopDevices.Visible == true then

				onNumberButtonClicked("1")

			end


		end
	else
		if LCD.Password.Visible == true then
			L2_Input = L2_Input .. "8"

			if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
				LCD.Password.Frame.Frame.Password.Text = "*"
			else
				LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
			end

		elseif LCD.LoopDevices.Visible == true then

			onNumberButtonClicked("8")

		end
	end
end)

Buttons.N9.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Password.Visible == true then
				L2_Input = L2_Input .. "9"

				if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
					LCD.Password.Frame.Frame.Password.Text = "*"
				else
					LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
				end

			elseif LCD.LoopDevices.Visible == true then

				onNumberButtonClicked("9")

			end


		end
	else
		if LCD.Password.Visible == true then
			L2_Input = L2_Input .. "9"

			if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
				LCD.Password.Frame.Frame.Password.Text = "*"
			else
				LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
			end

		elseif LCD.LoopDevices.Visible == true then

			onNumberButtonClicked("9")

		end
	end
end)

Buttons.N0.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Password.Visible == true then
				L2_Input = L2_Input .. "0"

				if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
					LCD.Password.Frame.Frame.Password.Text = "*"
				else
					LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
				end

			elseif LCD.Alarm.Visible == true then

				if Investigation == true then
					Countdown = Countdown + 20
					NetAPI:Fire("COUNTDOWN", Countdown)
					wait(1)
				end

			elseif LCD.LoopDevices.Visible == true then

				onNumberButtonClicked("0")

			end


		end
	else
		if LCD.Password.Visible == true then
			L2_Input = L2_Input .. "0"

			if LCD.Password.Frame.Frame.Password.Text == "Please Enter Your Password" then
				LCD.Password.Frame.Frame.Password.Text = "*"
			else
				LCD.Password.Frame.Frame.Password.Text = LCD.Password.Frame.Frame.Password.Text .. "*"
			end

		elseif LCD.Alarm.Visible == true then

			if inInvest == true then
				Countdown = Countdown + 20
				NetAPI:Fire("COUNTDOWN", Countdown)
				wait(1)
			end

		elseif LCD.LoopDevices.Visible == true then

			onNumberButtonClicked("0")


		end
	end
end)

-- ENTER



-- MENU


Buttons.Menu.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LoggedIn == true then

				checkDisablements()

				LoopInfoInput = "View"

				for i, v in pairs(LCD.LoopInfo:GetChildren()) do
					if v:IsA("TextLabel") then
						v.TextColor3 = Color3.new(0, 0, 0)
						v.BackgroundTransparency = 1
					end
				end

				LCD.LoopInfo.ViewEdit.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.ViewEdit.BackgroundTransparency = 0

				if LCD.ZoneInput_Test.Visible == true then

					LCD.ZoneInput_Test.Visible = false
					LCD.TestSelection.Visible = false
					LCD.TestSelection.Sounders.Visible = false

					LCD.TestSelection.InTest.Visible = true


				end



				MakeFramesVisible(false)
				LCD.Level2Menu.Visible = true




			else

				MakeFramesVisible(false)
				LCD.Menu.Visible = true

			end


		end
	else
		if LoggedIn == true then

			checkDisablements()

			LCD.LoopInfo.Visible = false

			LoopInfoInput = "View"

			for i, v in pairs(LCD.LoopInfo:GetChildren()) do
				if v:IsA("TextLabel") then
					v.TextColor3 = Color3.new(0, 0, 0)
					v.BackgroundTransparency = 1
				end
			end

			LCD.LoopInfo.ViewEdit.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			LCD.LoopInfo.ViewEdit.BackgroundTransparency = 0

			if LCD.TestMenu.Visible == true then

				LCD.TestMenu.Visible = false
				LCD.TestSelection.Visible = false
				LCD.TestSelection.Sounders.Visible = false

				LCD.TestSelection.InTest.Visible = true

				if LCD.Home.Visible == true then

					LCD.Home.Visible = false
					LCD.Level2Menu.Visible = true

				end

			else


				MakeFramesVisible(false)
				LCD.Level2Menu.Visible = true


			end


		else

			MakeFramesVisible(false)
			LCD.Menu.Visible = true

		end



	end
end)

-- BUTTONS: ARROWS

Buttons.Tick.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Menu.Visible == true then

				if MenuInput == "Enable_Controls" then



					if LCD.Menu.EnableControls.Text == "DISABLE-CONTROLS" then

						LoggedIn = false
						LCD.Menu.EnableControls.Text = "ENABLE-CONTROLS"
						script.Access.Value = false

					else

						LCD.Menu.Visible = false

						if Config.AlwaysLoggedIn == true then
							LCD.Level2Menu.Visible = true
						else
							LCD.Password.Visible = true
							L2_Input = ""
						end

					end


				elseif MenuInput == "View" then
					LCD.Menu.Visible = false
					LCD.View.Visible = true
					LCD.View.View2.Visible = false
					LCD.View.Visible = true
					LCD.View.View2.Visible = false
					LCD.View.View1.Visible = true

				elseif MenuInput == "Status" then
					LCD.Menu.Visible = false

					LCD.Home.Visible = true

					if InAlarm == true or InTrouble == true then
						LCD.Home.Visible = false
						LCD.AlarmCondition.Visible = true

					elseif InEvac == true then

						LCD.Home.Visible = false
						LCD.Alarm.Visible = true





					end



				elseif MenuInput == "LEDTest" then

					if InAlarm == false then
						Buzzer:Play()
						for i, v in ipairs(LEDs:GetDescendants()) do
							if v:IsA("BasePart") and v.Name:sub(1, 1) == "Z" then
								v.Color = Color3.new(1, 0, 0)
							end
						end

						for i, v in ipairs(LEDs:GetDescendants()) do
							if v:IsA("BasePart") and v.Name:sub(1, 1) == "F" then
								v.Color = Color3.new(1, 0.52549, 0.184314)
							end
						end


						for i, v in ipairs(LEDs:GetDescendants()) do
							if v:IsA("BasePart") and v.Name:sub(1, 1) == "S" then
								v.Color = Color3.new(1, 0.52549, 0.184314)
							end
						end

						for i, v in ipairs(LEDs:GetDescendants()) do
							if v:IsA("BasePart") and v.Name:sub(1, 1) == "T" then
								v.Color = Color3.new(1, 0.52549, 0.184314)
							end
						end

						for i, v in ipairs(LEDs:GetDescendants()) do
							if v:IsA("BasePart") and v.Name:sub(1, 1) == "D" then
								v.Color = Color3.new(1, 0.52549, 0.184314)
							end
						end

						LEDs.Fire.Color = Color3.new(1, 0, 0)
						LEDs.MoreAlarms.Color = Color3.new(1, 0, 0)
						LEDs.PreAlarm.Color = Color3.new(1, 0.52549, 0.184314)

						LEDs.FireProtection.Color = Color3.new(1, 0, 0)

						wait(5)
						Buzzer:Stop()
						for i, v in pairs(LEDs:GetChildren()) do
							if v:IsA("BasePart") then
								v.Color = Color3.new(0.192157, 0.192157, 0.196078)

								if v.Name == "Power" then
									v.Color = Color3.new(0.411765, 0.886275, 0.0980392)
								elseif v.Name == "Delay" and Config.InvestigationDelay.Active == true then
									LEDs.Delay.Color = Color3.new(1, 0.52549, 0.184314)
								elseif v.Name == "FireRouting_Activated" then
									LEDs.FireRouting_Activated.Color = Color3.new(0.192157, 0.192157, 0.196078)
								end

							end
						end

						if DisabledDevice_Amount > 0 then
							LEDs.Disablement.Color = Color3.new(1, 0.52549, 0.184314)
						end

						if SoundersDisableList > 0 then
							LEDs.SounderDisabled.Color = Color3.new(1, 0.52549, 0.184314)
						end

						if InFault then
							LEDs.Fault.Color = Color3.new(1, 0.52549, 0.184314)
						end




					end

				end

			elseif LCD.SpecificOutputDevices.Visible == true then
				for i, frame in ipairs(frames_OUTPUTZONES_CERTAIN) do
					if i == currentFrameIndex_OUTPUTZONES_CERTAIN then
						local deviceAddress = frame.Address.Text

						for _, device in ipairs(OutputsDisabled) do
							if device.Address == deviceAddress then
								if device.Disabled then
									NetAPI:Fire("Enable", "SO", deviceAddress)
									frame.Mode.Text = "Enabled"
								else
									NetAPI:Fire("Disable", "SO", deviceAddress)
									frame.Mode.Text = "Disabled"
								end
							end
						end
					end
				end




			elseif LCD.TestMenu.LCDTest.Visible == true then
				LCD.TestMenu.LCDTest.ButtonInput.Text = "?"

			elseif LCD.ZoneInput_Test.Visible == true then
				ChangeTestStatus()

			elseif LCD.LoopDevices.Visible == true then
				if newZoneInput ~= "" then
					for i, frame in ipairs(frames_LOOPS) do
						if i == currentFrameIndex_LOOPS then
							frame.Zone.Text = convert000Format(newZoneInput)
							previousZone = newZoneInput  


							for a, model in ipairs(Loopdevices_models) do
								if a == currentFrameIndex_LOOPS and model:IsA("Model") then
									model:SetAttribute("DeviceZone", newZoneInput)
								end
							end
						end
					end

					newZoneInput = ""
				end

			elseif LCD.LoopInfo.Visible == true then
				if LoopInfoInput == "AutoLearn" then
					LCD.LoopInfo.Visible = false
					LCD.AutoLearn.Visible = true
					AutoLearn(removeLFromString(LoopSelectInput))
				elseif LoopInfoInput == "Calibrate" then
					LCD.LoopInfo.Visible = false
					LCD.Calibrate.Visible = true
					wait(math.random(2, 5))
					LCD.Calibrate.Visible = false
					LCD.LoopInfo.Visible = true
				elseif LoopInfoInput == "View" then
					LCD.LoopInfo.Visible = false
					LCD.LoopDevices.Visible = true
					getLoopDevices(removeLFromString(LoopSelectInput))
				end

			elseif LCD.Password.Visible == true then

				for userName, user in pairs(UsersConfig) do
					-- Debugging: Print the user details to ensure the loop is iterating correctly
					print("Checking user:", userName, "with code:", user.Code)

					if L2_Input == user.Code then
						print("Match found for user:", userName) -- Debugging: Log when a match is found

						LCD.Level2Menu.UserNode.Text = userName .. "  Node " .. script.Parent:GetAttribute("Node")
						InLevel = user.Level



						if FunctionToComplete == "" then

							if tonumber(InLevel) >= 3 then
								script.Level3.Value = true
							elseif tonumber(InLevel) >= 2 then
								script.Access.Value = true	
							end


							LoggedIn = true

							LCD.Level2Menu.Visible = true
							LCD.Password.Visible = false
							L2_Input = ""
							LCD.Password.Frame.Frame.Password.Text = ""
							LCD.Menu.EnableControls.Text = "DISABLE-CONTROLS"

							if MenuToOpen == "Disable" then

								if tonumber(InLevel) >= tonumber(UserMenus_Levels.Disable) then

									LCD.Level2Menu.Visible = false
									LCD.DisablementMenu.Visible = true
									MenuToOpen = ""

								end

							elseif MenuToOpen == "Enable" then

								if tonumber(InLevel) >= tonumber(UserMenus_Levels.Disable) then

									LCD.Level2Menu.Visible = false
									LCD.DisablementMenu.Visible = true
									MenuToOpen = ""

								end


							elseif MenuToOpen == "Test" then

								if tonumber(InLevel) >= tonumber(UserMenus_Levels.Test) then

									LCD.Level2Menu.Visible = false
									LCD.TestMenu.Visible = true
									MenuToOpen = ""

								end

							elseif MenuToOpen == "Delay" then

								if tonumber(InLevel) >= tonumber(UserMenus_Levels.Delay) then

									LCD.Level2Menu.Visible = false
									LCD.Delay.Visible = true
									MenuToOpen = ""

								end


							elseif MenuToOpen == "Commission" then

								if tonumber(InLevel) >= tonumber(UserMenus_Levels.Commission) then

									LCD.Level2Menu.Visible = false
									LCD.Commission.Visible = true
									LCD.Commission.Menu1.Visible = true
									LCD.Commission.Menu2.Visible = false
									MenuToOpen = ""

								end


							end

						else
							LCD.Password.Visible = false




							if FunctionToComplete == "Evacuate" then
								FunctionToComplete = ""
								NetAPI:Fire("Evacuate", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))

								L2_Input = ""
								LCD.Password.Frame.Frame.Password.Text = ""

								MakeFramesVisible(false)

								if InAlarm or InTrouble then
									LCD.AlarmCondition.Visible = true
								else
									LCD.AlarmCondition.Visible = true
								end

								if InEvac == true then
									LCD.Alarm.Visible = true
								end

							elseif FunctionToComplete == "Silence" then
								FunctionToComplete = ""
								NetAPI:Fire("Silence")

								L2_Input = ""
								LCD.Password.Frame.Frame.Password.Text = ""

								MakeFramesVisible(false)

								if InAlarm or InTrouble then
									LCD.AlarmCondition.Visible = true
								else
									LCD.AlarmCondition.Visible = true
								end

								if InEvac == true then
									LCD.Alarm.Visible = true
								end

							elseif FunctionToComplete == "Reset" then
								FunctionToComplete = ""
								NetAPI:Fire("Reset")

								L2_Input = ""
								LCD.Password.Frame.Frame.Password.Text = ""

								MakeFramesVisible(false)

								if InAlarm or InTrouble then
									LCD.AlarmCondition.Visible = true
								else
									LCD.AlarmCondition.Visible = true
								end

								if InEvac == true then
									LCD.Alarm.Visible = true
								end

							elseif FunctionToComplete == "Resound" then
								FunctionToComplete = ""

								if InTrouble then
									NetAPI:Fire("Trouble", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))
								else
									NetAPI:Fire("Evacuate", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))
								end

								L2_Input = ""
								LCD.Password.Frame.Frame.Password.Text = ""

								MakeFramesVisible(false)

								if InAlarm or InTrouble then
									LCD.AlarmCondition.Visible = true
								else
									LCD.AlarmCondition.Visible = true
								end

								if InEvac == true then
									LCD.Alarm.Visible = true
								end
							end
						end
					else
						print("No match for user:", userName) -- Debugging: Log when no match is found
						LoggedIn = false
						LCD.Password.Frame.Frame.Password.Text = " Password Not Recognised !"
						LCD.Password.Frame.Frame.Password.TextXAlignment = Enum.TextXAlignment.Left
						wait(1)
						L2_Input = ""
						LCD.Password.Frame.Frame.Password.Text = ""
						LCD.Password.Frame.Frame.Password.TextXAlignment = Enum.TextXAlignment.Center
					end
				end

			elseif LCD.Alarm.Visible == true then
				Countdown = 999999999999999
				wait(0.1)
				NetAPI:Fire("COUNTOWN", Countdown)
				if InTrouble == true then
					NetAPI:Fire("Trouble", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))
				else
					NetAPI:Fire("Evacuate", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))
				end



			elseif LCD.Tools.Visible == true and LCD.TestMenu.LCDTest.Visible == false then
				if tools_Input == "Commission" then

					if tonumber(InLevel) >= tonumber(UserMenus_Levels.Commission) then

						LCD.Tools.Visible = false
						LCD.Commission.Visible = true
						LCD.Commission.Menu1.Visible = true
						LCD.Commission.Menu2.Visible = false 

					else

						LCD.Tools.Visible = false
						LCD.Password.Visible = true
						MenuToOpen = "Commission"

					end

				end			

			elseif LCD.Commission.Menu1.Visible == true then
				if Commission_Input1 == "View" then
					LCD.Commission.Menu1.Visible = false
					LCD.Commission.Visible = false

				elseif Commission_Input1 == "Disable" then
					LCD.Commission.Menu1.Visible = false
					LCD.Commission.Visible = false
					LCD.DisablementMenu.Visible = true
					addZoneToList()
				elseif Commission_Input1 == "Enable" then
					LCD.Commission.Menu1.Visible = false
					LCD.Commission.Visible = false
					LCD.DisablementMenu.Visible = true
					addZoneToList()
				elseif Commission_Input1 == "NextMenu" then
					LCD.Commission.Menu1.Visible = false
					LCD.Commission.Menu2.Visible = true
				elseif Commission_Input1 == "Exit" then
					LCD.Commission.Menu1.Visible = false
					LCD.Commission.Visible = false
					LCD.Tools.Visible = true
				elseif Commission_Input1 == "Loops" then

					if LCD.LoopSelect.AmountOfLoops.Value == "1" then
						LCD.Commission.Visible = false
						LCD.Commission.Menu1.Visible = false
						LCD.LoopInfo.Visible = true
					else
						LCD.Commission.Visible = false
						LCD.Commission.Menu1.Visible = false
						LCD.LoopSelect.Visible = true
					end

				end

			elseif LCD.LoopSelect.Visible == true then
				if LoopSelectInput == "L1" then
					LCD.LoopSelect.Visible = false
					LCD.LoopInfo.Visible = true

					LCD.LoopInfo.ControlHeader.Text = "[ Loop 1 ]"

				elseif LoopSelectInput == "L2" then
					LCD.LoopSelect.Visible = false
					LCD.LoopInfo.Visible = true

					LCD.LoopInfo.ControlHeader.Text = "[ Loop 2 ]"

				elseif LoopSelectInput == "L3" then
					LCD.LoopSelect.Visible = false
					LCD.LoopInfo.Visible = true

					LCD.LoopInfo.ControlHeader.Text = "[ Loop 3 ]"

				elseif LoopSelectInput == "L4" then
					LCD.LoopSelect.Visible = false
					LCD.LoopInfo.Visible = true

					LCD.LoopInfo.ControlHeader.Text = "[ Loop 4 ]"

				elseif LoopSelectInput == "L5" then
					LCD.LoopSelect.Visible = false
					LCD.LoopInfo.Visible = true

					LCD.LoopInfo.ControlHeader.Text = "[ Loop 5 ]"

				elseif LoopSelectInput == "L6" then
					LCD.LoopSelect.Visible = false
					LCD.LoopInfo.Visible = true

					LCD.LoopInfo.ControlHeader.Text = "[ Loop 6 ]"

				elseif LoopSelectInput == "L7" then
					LCD.LoopSelect.Visible = false
					LCD.LoopInfo.Visible = true

					LCD.LoopInfo.ControlHeader.Text = "[ Loop 7 ]"

				elseif LoopSelectInput == "L8" then
					LCD.LoopSelect.Visible = false
					LCD.LoopInfo.Visible = true

					LCD.LoopInfo.ControlHeader.Text = "[ Loop 8 ]"

				end

			elseif LCD.Level2Menu.Visible == true then
				if Level2MenuInput == "Status" then

					LCD.Level2Menu.Visible = false

					if InAlarm == true or InTrouble == true then
						LCD.Menu.Visible = false
						LCD.AlarmCondition.Visible = true
					elseif InEvac == true then

						LCD.Menu.Visible = false
						LCD.Alarm.Visible = true

					else

						LCD.Menu.Visible = false
						LCD.Home.Visible = true

					end	
				elseif Level2MenuInput == "Test" then

					if tonumber(InLevel) >= tonumber(UserMenus_Levels.Test) then

						LCD.Level2Menu.Visible = false
						LCD.TestMenu.Visible = true

					else

						LCD.Level2Menu.Visible = false
						LCD.Password.Visible = true
						MenuToOpen = "Test"

					end

				elseif Level2MenuInput == "Delay" then

					if tonumber(InLevel) >= tonumber(UserMenus_Levels.Delay) then

						LCD.Level2Menu.Visible = false
						LCD.Delay.Visible = true

					else

						LCD.Level2Menu.Visible = false
						LCD.Password.Visible = true
						MenuToOpen = "Delay"

					end

				elseif Level2MenuInput == "Disable" then

					if tonumber(InLevel) >= tonumber(UserMenus_Levels.Disable) then

						LCD.Level2Menu.Visible = false
						LCD.DisablementMenu.Visible = true
						addZoneToList()

					else

						LCD.Level2Menu.Visible = false
						LCD.Password.Visible = true
						MenuToOpen = "Disable"

					end

				elseif Level2MenuInput == "Enable" then

					if tonumber(InLevel) >= tonumber(UserMenus_Levels.Disable) then

						LCD.Level2Menu.Visible = false
						LCD.DisablementMenu.Visible = true
						addZoneToList()

					else

						LCD.Level2Menu.Visible = false
						LCD.Password.Visible = true
						MenuToOpen = "Enable"

					end

				elseif Level2MenuInput == "Tools" then
					LCD.Level2Menu.Visible = false
					LCD.Tools.Visible = true
				elseif Level2MenuInput == "View" then
					LCD.Level2Menu.Visible = false
					LCD.View.Visible = true
					LCD.View.View2.Visible = false
					LCD.View.View1.Visible = true
				end

			elseif LCD.TestSelection.InTest.Visible == true then
				if testSelect_InTest == "Finish" then

					LCD.TestSelection.Visible = false
					LCD.TestSelection.InTest.Visible = false
					LCD.TestSelection.Sounders.Visible = false


					ClearTestTables()

					if InAlarm and not InTrouble then
						LCD.Alarm.Visible = true
					elseif InTrouble then
						LCD.AlarmCondition.Visible = true
					elseif not InAlarm and not InTrouble then
						LCD.Level2Menu.Visible = true
					end

				elseif testSelect_InTest == "KeepIn" then

					LCD.TestSelection.Visible = false
					LCD.TestSelection.InTest.Visible = false
					LCD.TestSelection.Sounders.Visible = false


					LCD.TestMenu.Visible = true

				end

			elseif LCD.TestMenu.Visible == true then
				if Test_Input == "Printer" then
					NetAPI:Fire("TestPrint")


				elseif Test_Input == "Zones" then

					LCD.TestMenu.Visible = false
					LCD.TestSelection.Visible = true
					LCD.TestSelection.InTest.Visible = false
					LCD.TestSelection.Sounders.Visible = true

				elseif Test_Input == "Buzzer" then

					Buzzer:Play()
					wait(5)
					Buzzer:Stop()

				elseif Test_Input == "Display" then

					LCD.TestMenu.LCDTest.Visible = true


				end

			elseif LCD.TestSelection.Sounders.Visible == true then
				if testSelect_SoundersInput == "With" then
					LCD.TestSelection.Visible = false
					LCD.TestSelection.Sounders.Visible = false


					LCD.ZoneInput_Test.Visible = true

				elseif testSelect_SoundersInput == "Without" then
					LCD.TestSelection.Visible = false
					LCD.TestSelection.Sounders.Visible = false


					LCD.ZoneInput_Test.Visible = true

				end

			elseif LCD.OutputDisablement.Scroll1.Visible == true and LCD.OutputDisablement.Visible == true then
				if OutputDisablement_Input == "AllOutputs" then

					if AllOutputsDisabled == true then
						AllOutputsDisabled = false
						NetAPI:Fire("Enable", "AllOutputs")
						LCD.OutputDisablement.Visible = false
					else
						AllOutputsDisabled = true
						NetAPI:Fire("Disable", "AllOutputs")
						LCD.OutputDisablement.Visible = false
					end

				elseif OutputDisablement_Input == "AllSounders" then

					if AllOutputsDisabled == true then
						AllOutputsDisabled = false
						NetAPI:Fire("Enable", "AllSounders")
						LCD.OutputDisablement.Visible = false
					else
						AllOutputsDisabled = true
						NetAPI:Fire("Disable", "AllSounders")
						LCD.OutputDisablement.Visible = false
					end

				elseif OutputDisablement_Input == "AllBeacons" then

					if AllOutputsDisabled == true then
						AllOutputsDisabled = false
						NetAPI:Fire("Enable", "AllBeacons")
						LCD.OutputDisablement.Visible = false
					else
						AllOutputsDisabled = true
						NetAPI:Fire("Disable", "AllBeacons")
						LCD.OutputDisablement.Visible = false
					end

				elseif OutputDisablement_Input == "AllOtherRelay" then

					if AllOutputsDisabled == true then
						AllOutputsDisabled = false
						NetAPI:Fire("Enable", "AllOtherRelay")
						LCD.OutputDisablement.Visible = false
					else
						AllOutputsDisabled = true
						NetAPI:Fire("Disable", "AllOtherRelay")
						LCD.OutputDisablement.Visible = false
					end

				end

			elseif LCD.OutputDisablement.Scroll2.Visible == true and LCD.OutputDisablement.Visible == true then
				if OutputDisablement2_Input == "FaultRouting" then

					if FaultRoutingDisabled == true then
						FaultRoutingDisabled = false
						NetAPI:Fire("Enable", "FaultRouting")
						LCD.OutputDisablement.Visible = false
					else
						FaultRoutingDisabled = true
						NetAPI:Fire("Disable", "FaultRouting")
						LCD.OutputDisablement.Visible = false

					end

				elseif OutputDisablement2_Input == "FireProtection" then

					if FireProtectionDisabled == true then
						FireProtectionDisabled = false
						NetAPI:Fire("Enable", "FireProtection")
						LCD.OutputDisablement.Visible = false
					else
						FireProtectionDisabled = true
						NetAPI:Fire("Disable", "FireProtection")
						LCD.OutputDisablement.Visible = false

					end

				elseif OutputDisablement2_Input == "FireRouting" then

					if FireRoutingDisabled == true then
						FireRoutingDisabled = false
						NetAPI:Fire("Enable", "FireRouting")
						LCD.OutputDisablement.Visible = false
					else
						FireRoutingDisabled = true
						NetAPI:Fire("Disable", "FireRouting")
						LCD.OutputDisablement.Visible = false

					end

				elseif OutputDisablement2_Input == "OnlySelected" then

					LCD.OutputDisablement.Visible = false
					LCD.OutputDevices.Visible = true

				end

			elseif LCD.Delay.Visible == true then
				if DelayInput == "NoInvestigation" then
					if inInvest == true then
						LCD.Delay.Function.NoInvestigationDelay.Text = "   INVESTIGATION DELAY"
						NetAPI:Fire("InvestigationDelay", false)
						inInvest = false
					else
						inInvest = true
						NetAPI:Fire("InvestigationDelay", true)
						LCD.Delay.Function.NoInvestigationDelay.Text = "   NO INVESTIGATION DELAY"
					end





				elseif DelayInput == "OnceOnly" then
					InvestDelayONCE = true
					NetAPI:Fire("InvestigationDelay", true)


				elseif DelayInput == "Automatic" then
					Config.Delay = CurrentDelay
					NetAPI:Fire("Delay", CurrentDelay)

				elseif DelayInput == "Extended" then
					NetAPI:Fire("Delay", Config.ExtendedDelay)

				end

			elseif LCD.DisablementMenu.Visible == true then
				if DisablementMenu_Input == "ZoneInputs" then
					LCD.DisablementMenu.Visible = false
					LCD.ZoneInput.Visible = true
				elseif DisablementMenu_Input == "Outputs" then

					LCD.OutputDisablement.Visible = true
				end

			elseif LCD.View.Visible == true then
				if viewMenu_Input == "NextMenu" then

					LCD.View.View1.Visible = false
					LCD.View.View2.Visible = true

				end

			elseif LCD.ZoneInput.List.Visible == true and LCD.ZoneInput.Visible == true then

				if LCD.ZoneInput.Function.Visible == false then

					if currentFrameIndex_ZONES >= 1 then

						LCD.ZoneInput.Function.Visible = true

						local zOneq = zonesTable[currentFrameIndex_ZONES]
						local z0neDisablementtaBle = ZoneDisablementTable[zOneq]

						print(zOneq)

						if z0neDisablementtaBle then

							if LCD and LCD.ZoneInput and LCD.ZoneInput.Function then
								if LCD.ZoneInput.Function.AllInputs then
									if z0neDisablementtaBle["allInputs"] == true then
										LCD.ZoneInput.Function.AllInputs.Text = "   ALL INPUTS (D)"

									else
										LCD.ZoneInput.Function.AllInputs.Text = "   ALL INPUTS"

									end

								end

								if LCD.ZoneInput.Function.OnlyAutomaticDetectors then
									if z0neDisablementtaBle["Detectors"] == true then
										LCD.ZoneInput.Function.OnlyAutomaticDetectors.Text = "   ONLY AUTOMATIC DETECTORS (D)"

									else
										LCD.ZoneInput.Function.OnlyAutomaticDetectors.Text = "   ONLY AUTOMATIC DETECTORS"

									end

								end

								if LCD.ZoneInput.Function.OnlyManualDevices then
									if z0neDisablementtaBle["Callpoints"] == true then
										LCD.ZoneInput.Function.OnlyManualDevices.Text = "   ONLY MANUAL DEVICES (D)"

									else
										LCD.ZoneInput.Function.OnlyManualDevices.Text = "   ONLY MANUAL DEVICES"

									end

								end

							end
						end

					else





					end

				elseif LCD.ZoneInput.Function.Visible == true and LCD.ZoneInput.Visible == true then
					if ZoneFunction_Input == "AllInputs" then

						local CurrentZoneq = zonesTable[currentFrameIndex_ZONES]


						for _, zone in ipairs(ZoneDisablementTable) do
							if zone.Zone == CurrentZoneq then

								if zone["allInputs"] == true then
									zone["allInputs"] = false
									NetAPI:Fire("Enable", "AllInputs", CurrentZoneq)
									local CurrentFrame = frames_ZONES[currentFrameIndex_ZONES]
									CurrentFrame.Mode.Text = "Enabled"
									LCD.ZoneInput.Function.Visible = false
									checkDisablements()

									zone.Detectors = false
									zone.Callpoints = false

								else
									zone["allInputs"] = true
									NetAPI:Fire("Disable", "AllInputs", CurrentZoneq)
									local CurrentFrame = frames_ZONES[currentFrameIndex_ZONES]
									CurrentFrame.Mode.Text = "Disabled"
									LCD.ZoneInput.Function.Visible = false
									checkDisablements()

									zone.Detectors = true
									zone.Callpoints = true

								end

							end
						end


					elseif ZoneFunction_Input == "AutomaticDetectors" then

						local CurrentZoneq = zonesTable[currentFrameIndex_ZONES]


						for _, zone in ipairs(ZoneDisablementTable) do
							if zone.Zone == CurrentZoneq then

								if zone["Detectors"] == true then
									zone["Detectors"] = false
									NetAPI:Fire("Enable", "Detectors", CurrentZoneq)
									local CurrentFrame = frames_ZONES[currentFrameIndex_ZONES]

									LCD.ZoneInput.Function.Visible = false

									if zone.Callpoints == false then
										zone["Callpoints"] = false
										CurrentFrame.Mode.Text = "Enabled"
									else
										zone["Callpoints"] = true
										CurrentFrame.Mode.Text = "Part-Disabled"
									end

									checkDisablements()
								else
									zone["Detectors"] = true
									NetAPI:Fire("Disable", "Detectors", CurrentZoneq)
									local CurrentFrame = frames_ZONES[currentFrameIndex_ZONES]

									LCD.ZoneInput.Function.Visible = false

									if zone.Callpoints == false then
										zone["Callpoints"] = false
										CurrentFrame.Mode.Text = "Part-Disabled"
									else
										zone["Callpoints"] = true
										CurrentFrame.Mode.Text = "Disabled"
									end

									checkDisablements()

								end

							end
						end

					elseif ZoneFunction_Input == "ManualDevices" then

						local CurrentZoneq = zonesTable[currentFrameIndex_ZONES]


						for _, zone in ipairs(ZoneDisablementTable) do
							if zone.Zone == CurrentZoneq then

								if zone["Callpoints"] == true then
									zone["Callpoints"] = false
									NetAPI:Fire("Enable", "Callpoints", CurrentZoneq)
									local CurrentFrame = frames_ZONES[currentFrameIndex_ZONES]

									LCD.ZoneInput.Function.Visible = false

									if zone.Detectors == false then
										zone["Detectors"] = false
										CurrentFrame.Mode.Text = "Enabled"
									else
										zone["Detectors"] = true
										CurrentFrame.Mode.Text = "Part-Disabled"
									end

									checkDisablements()
								else
									zone["Callpoints"] = true
									NetAPI:Fire("Disable", "Callpoints", CurrentZoneq)
									local CurrentFrame = frames_ZONES[currentFrameIndex_ZONES]

									LCD.ZoneInput.Function.Visible = false

									if zone.Detectors == false then
										zone["Detectors"] = false
										CurrentFrame.Mode.Text = "Part-Disabled"
									else
										zone["Detectors"] = true
										CurrentFrame.Mode.Text = "Disabled"
									end

									checkDisablements()

								end

							end
						end

					end

					checkDisablements()





				end





			end

		end


	else


		if LCD.Menu.Visible == true then

			if MenuInput == "Enable_Controls" then



				if LCD.Menu.EnableControls.Text == "DISABLE-CONTROLS" then

					LoggedIn = false
					LCD.Menu.EnableControls.Text = "ENABLE-CONTROLS"
					script.Access.Value = false

				else

					LCD.Menu.Visible = false

					if Config.AlwaysLoggedIn == true then
						LCD.Level2Menu.Visible = true
					else
						LCD.Password.Visible = true
						L2_Input = ""
					end

				end

			elseif MenuInput == "View" then
				LCD.Menu.Visible = false
				LCD.View.Visible = true
				LCD.View.View2.Visible = false
				LCD.View.Visible = true
				LCD.View.View2.Visible = false
				LCD.View.View1.Visible = true

			elseif MenuInput == "Status" then
				LCD.Menu.Visible = false

				LCD.Home.Visible = true

				if InAlarm == true or InTrouble == true then
					LCD.Home.Visible = false
					LCD.AlarmCondition.Visible = true

				elseif InEvac == true then

					LCD.Home.Visible = false
					LCD.Alarm.Visible = true





				end



			elseif MenuInput == "LEDTest" then

				if InAlarm == false then
					Buzzer:Play()
					for i, v in ipairs(LEDs:GetDescendants()) do
						if v:IsA("BasePart") and v.Name:sub(1, 1) == "Z" then
							v.Color = Color3.new(1, 0, 0)
						end
					end

					for i, v in ipairs(LEDs:GetDescendants()) do
						if v:IsA("BasePart") and v.Name:sub(1, 1) == "F" then
							v.Color = Color3.new(1, 0.52549, 0.184314)
						end
					end


					for i, v in ipairs(LEDs:GetDescendants()) do
						if v:IsA("BasePart") and v.Name:sub(1, 1) == "S" then
							v.Color = Color3.new(1, 0.52549, 0.184314)
						end
					end

					for i, v in ipairs(LEDs:GetDescendants()) do
						if v:IsA("BasePart") and v.Name:sub(1, 1) == "T" then
							v.Color = Color3.new(1, 0.52549, 0.184314)
						end
					end

					for i, v in ipairs(LEDs:GetDescendants()) do
						if v:IsA("BasePart") and v.Name:sub(1, 1) == "D" then
							v.Color = Color3.new(1, 0.52549, 0.184314)
						end
					end

					LEDs.Fire.Color = Color3.new(1, 0, 0)
					LEDs.MoreAlarms.Color = Color3.new(1, 0, 0)
					LEDs.PreAlarm.Color = Color3.new(1, 0.52549, 0.184314)

					LEDs.FireProtection.Color = Color3.new(1, 0, 0)

					wait(5)
					Buzzer:Stop()
					for i, v in pairs(LEDs:GetChildren()) do
						if v:IsA("BasePart") then
							v.Color = Color3.new(0.192157, 0.192157, 0.196078)

							if v.Name == "Power" then
								v.Color = Color3.new(0.411765, 0.886275, 0.0980392)
							elseif v.Name == "Delay" and Config.InvestigationDelay.Active == true then
								LEDs.Delay.Color = Color3.new(1, 0.52549, 0.184314)
							elseif v.Name == "FireRouting_Activated" then
								LEDs.FireRouting_Activated.Color = Color3.new(0.192157, 0.192157, 0.196078)
							end

						end
					end

					if DisabledDevice_Amount > 0 then
						LEDs.Disablement.Color = Color3.new(1, 0.52549, 0.184314)
					end

					if SoundersDisableList > 0 then
						LEDs.SounderDisabled.Color = Color3.new(1, 0.52549, 0.184314)
					end

					if InFault then
						LEDs.Fault.Color = Color3.new(1, 0.52549, 0.184314)
					end




				end

			end

		elseif LCD.SpecificOutputDevices.Visible == true then
			for i, frame in ipairs(frames_OUTPUTZONES_CERTAIN) do
				if i == currentFrameIndex_OUTPUTZONES_CERTAIN then
					local deviceAddress = frame.Address.Text

					for _, device in ipairs(OutputsDisabled) do
						if device.Address == deviceAddress then
							if device.Disabled then
								NetAPI:Fire("Enable", "SO", deviceAddress)
								frame.Mode.Text = "Enabled"
							else
								NetAPI:Fire("Disable", "SO", deviceAddress)
								frame.Mode.Text = "Disabled"
							end
						end
					end
				end
			end

		elseif LCD.TestMenu.LCDTest.Visible == true then
			LCD.TestMenu.LCDTest.ButtonInput.Text = "?"

		elseif LCD.ZoneInput_Test.Visible == true then
			ChangeTestStatus()

		elseif LCD.LoopDevices.Visible == true then
			if newZoneInput ~= "" then
				for i, frame in ipairs(frames_LOOPS) do
					if i == currentFrameIndex_LOOPS then
						frame.Zone.Text = convert000Format(newZoneInput)
						previousZone = newZoneInput  


						for a, model in ipairs(Loopdevices_models) do
							if a == currentFrameIndex_LOOPS and model:IsA("Model") then
								model:SetAttribute("DeviceZone", newZoneInput)
							end
						end
					end
				end

				newZoneInput = ""
			end

		elseif LCD.LoopInfo.Visible == true then
			if LoopInfoInput == "AutoLearn" then
				LCD.LoopInfo.Visible = false
				LCD.AutoLearn.Visible = true
				AutoLearn(removeLFromString(LoopSelectInput))
			elseif LoopInfoInput == "Calibrate" then
				LCD.LoopInfo.Visible = false
				LCD.Calibrate.Visible = true
				wait(math.random(2, 5))
				LCD.Calibrate.Visible = false
				LCD.LoopInfo.Visible = true
			elseif LoopInfoInput == "View" then
				LCD.LoopInfo.Visible = false
				LCD.LoopDevices.Visible = true
				getLoopDevices(removeLFromString(LoopSelectInput))
			end

		elseif LCD.Password.Visible == true then

			local found = false

			for userName, user in pairs(UsersConfig) do
				-- Debugging: Print the user details to ensure the loop is iterating correctly
				print("Checking user:", userName, "with code:", user.Code)
				print(L2_Input)
				if L2_Input == user.Code then

					found = true

					print("Match found for user:", userName) -- Debugging: Log when a match is found

					LCD.Level2Menu.UserNode.Text = userName .. "  Node " .. script.Parent:GetAttribute("Node")
					InLevel = user.Level

					if FunctionToComplete == "" then

						if tonumber(InLevel) >= 3 then
							script.Level3.Value = true
						elseif tonumber(InLevel) >= 2 then
							script.Access.Value = true	
						end

						LoggedIn = true

						LCD.Level2Menu.Visible = true
						LCD.Password.Visible = false
						L2_Input = ""
						LCD.Password.Frame.Frame.Password.Text = ""
						LCD.Menu.EnableControls.Text = "DISABLE-CONTROLS"

						if MenuToOpen == "Disable" then

							if tonumber(InLevel) >= tonumber(UserMenus_Levels.Disable) then

								LCD.Level2Menu.Visible = false
								LCD.DisablementMenu.Visible = true
								MenuToOpen = ""

							end

						elseif MenuToOpen == "Enable" then

							if tonumber(InLevel) >= tonumber(UserMenus_Levels.Disable) then

								LCD.Level2Menu.Visible = false
								LCD.DisablementMenu.Visible = true
								MenuToOpen = ""

							end


						elseif MenuToOpen == "Test" then

							if tonumber(InLevel) >= tonumber(UserMenus_Levels.Test) then

								LCD.Level2Menu.Visible = false
								LCD.TestMenu.Visible = true
								MenuToOpen = ""

							end

						elseif MenuToOpen == "Delay" then

							if tonumber(InLevel) >= tonumber(UserMenus_Levels.Delay) then

								LCD.Level2Menu.Visible = false
								LCD.Delay.Visible = true
								MenuToOpen = ""

							end


						elseif MenuToOpen == "Commission" then

							if tonumber(InLevel) >= tonumber(UserMenus_Levels.Commission) then

								LCD.Level2Menu.Visible = false
								LCD.Commission.Menu1.Visible = true
								LCD.Commission.Menu2.Visible = false
								LCD.Commission.Visible = true
								MenuToOpen = ""

							end


						end

					else
						LCD.Password.Visible = false




						if FunctionToComplete == "Evacuate" then
							FunctionToComplete = ""
							NetAPI:Fire("Evacuate", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))

							L2_Input = ""
							LCD.Password.Frame.Frame.Password.Text = ""

							MakeFramesVisible(false)

							if InAlarm or InTrouble then
								LCD.AlarmCondition.Visible = true
							else
								LCD.AlarmCondition.Visible = true
							end

							if InEvac == true then
								LCD.Alarm.Visible = true
							end

						elseif FunctionToComplete == "Silence" then
							FunctionToComplete = ""
							NetAPI:Fire("Silence")

							L2_Input = ""
							LCD.Password.Frame.Frame.Password.Text = ""

							MakeFramesVisible(false)

							if InAlarm or InTrouble then
								LCD.AlarmCondition.Visible = true
							else
								LCD.AlarmCondition.Visible = true
							end

							if InEvac == true then
								LCD.Alarm.Visible = true
							end

						elseif FunctionToComplete == "Reset" then
							FunctionToComplete = ""
							NetAPI:Fire("Reset")

							L2_Input = ""
							LCD.Password.Frame.Frame.Password.Text = ""

							MakeFramesVisible(false)

							if InAlarm or InTrouble then
								LCD.AlarmCondition.Visible = true
							else
								LCD.AlarmCondition.Visible = true
							end

							if InEvac == true then
								LCD.Alarm.Visible = true
							end

						elseif FunctionToComplete == "Resound" then
							FunctionToComplete = ""

							if InTrouble then
								NetAPI:Fire("Trouble", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))
							else
								NetAPI:Fire("Evacuate", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))
							end

							L2_Input = ""
							LCD.Password.Frame.Frame.Password.Text = ""

							MakeFramesVisible(false)

							if InAlarm or InTrouble then
								LCD.AlarmCondition.Visible = true
							else
								LCD.AlarmCondition.Visible = true
							end

							if InEvac == true then
								LCD.Alarm.Visible = true
							end
						end
					end
				else
					print("No match for user:", userName) -- Debugging: Log when no match is found

				end
			end

			if not found then

				LoggedIn = false
				LCD.Password.Frame.Frame.Password.Text = " Password Not Recognised !"
				LCD.Password.Frame.Frame.Password.TextXAlignment = Enum.TextXAlignment.Left
				wait(1)
				L2_Input = ""
				LCD.Password.Frame.Frame.Password.Text = ""
				LCD.Password.Frame.Frame.Password.TextXAlignment = Enum.TextXAlignment.Center

			end


		elseif LCD.Alarm.Visible == true then
			Countdown = 999999999999999
			wait(0.1)
			NetAPI:Fire("COUNTOWN", Countdown)
			if InTrouble == true then
				NetAPI:Fire("Trouble", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))
			else
				NetAPI:Fire("Evacuate", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))
			end

		elseif LCD.View.Visible == true then
			if viewMenu_Input == "NextMenu" then

				LCD.View.View1.Visible = false
				LCD.View.View2.Visible = true

			end

		elseif LCD.Delay.Visible == true then
			if DelayInput == "NoInvestigation" then
				if inInvest == true then
					LCD.Delay.Function.NoInvestigationDelay.Text = "   INVESTIGATION DELAY"
					NetAPI:Fire("InvestigationDelay", false)
					inInvest = false
				else
					inInvest = true
					NetAPI:Fire("InvestigationDelay", true)
					LCD.Delay.Function.NoInvestigationDelay.Text = "   NO INVESTIGATION DELAY"
				end





			elseif DelayInput == "OnceOnly" then
				InvestDelayONCE = true
				NetAPI:Fire("InvestigationDelay", true)


			elseif DelayInput == "Automatic" then
				Config.Delay = CurrentDelay
				NetAPI:Fire("Delay", CurrentDelay)

			elseif DelayInput == "Extended" then
				NetAPI:Fire("Delay", Config.ExtendedDelay)

			end

		elseif LCD.LoopSelect.Visible == true then
			if LoopSelectInput == "L1" then
				LCD.LoopSelect.Visible = false
				LCD.LoopInfo.Visible = true

				LCD.LoopInfo.ControlHeader.Text = "[ Loop 1 ]"

			elseif LoopSelectInput == "L2" then
				LCD.LoopSelect.Visible = false
				LCD.LoopInfo.Visible = true

				LCD.LoopInfo.ControlHeader.Text = "[ Loop 2 ]"

			elseif LoopSelectInput == "L3" then
				LCD.LoopSelect.Visible = false
				LCD.LoopInfo.Visible = true

				LCD.LoopInfo.ControlHeader.Text = "[ Loop 3 ]"

			elseif LoopSelectInput == "L4" then
				LCD.LoopSelect.Visible = false
				LCD.LoopInfo.Visible = true

				LCD.LoopInfo.ControlHeader.Text = "[ Loop 4 ]"

			elseif LoopSelectInput == "L5" then
				LCD.LoopSelect.Visible = false
				LCD.LoopInfo.Visible = true

				LCD.LoopInfo.ControlHeader.Text = "[ Loop 5 ]"

			elseif LoopSelectInput == "L6" then
				LCD.LoopSelect.Visible = false
				LCD.LoopInfo.Visible = true

				LCD.LoopInfo.ControlHeader.Text = "[ Loop 6 ]"

			elseif LoopSelectInput == "L7" then
				LCD.LoopSelect.Visible = false
				LCD.LoopInfo.Visible = true

				LCD.LoopInfo.ControlHeader.Text = "[ Loop 7 ]"

			elseif LoopSelectInput == "L8" then
				LCD.LoopSelect.Visible = false
				LCD.LoopInfo.Visible = true

				LCD.LoopInfo.ControlHeader.Text = "[ Loop 8 ]"

			end


		elseif LCD.Tools.Visible == true and LCD.TestMenu.LCDTest.Visible == false then
			if tools_Input == "Commission" then

				if tonumber(InLevel) >= tonumber(UserMenus_Levels.Commission) then

					LCD.Tools.Visible = false
					LCD.Commission.Visible = true
					LCD.Commission.Menu1.Visible = true
					LCD.Commission.Menu2.Visible = false

				else

					LCD.Tools.Visible = false
					LCD.Password.Visible = true
					MenuToOpen = "Commission"

				end

			end			

		elseif LCD.Commission.Menu1.Visible == true then
			if Commission_Input1 == "View" then
				LCD.Commission.Menu1.Visible = false
				LCD.Commission.Visible = false

			elseif Commission_Input1 == "Disable" then
				LCD.Commission.Menu1.Visible = false
				LCD.Commission.Visible = false
				LCD.DisablementMenu.Visible = true
				addZoneToList()
			elseif Commission_Input1 == "Enable" then
				LCD.Commission.Menu1.Visible = false
				LCD.Commission.Visible = false
				LCD.DisablementMenu.Visible = true
				addZoneToList()
			elseif Commission_Input1 == "NextMenu" then
				LCD.Commission.Menu1.Visible = false
				LCD.Commission.Menu2.Visible = true
			elseif Commission_Input1 == "Exit" then
				LCD.Commission.Menu1.Visible = false
				LCD.Commission.Visible = false
				LCD.Tools.Visible = true

			elseif Commission_Input1 == "Loops" then

				if LCD.LoopSelect.AmountOfLoops.Value == "1" then
					LCD.Commission.Visible = false
					LCD.LoopInfo.Visible = true
				else
					LCD.Commission.Visible = false
					LCD.LoopSelect.Visible = true
				end

			end




		elseif LCD.Level2Menu.Visible == true then
			if Level2MenuInput == "Status" then

				LCD.Level2Menu.Visible = false



				if InAlarm == true or InTrouble == true then
					LCD.Menu.Visible = false
					LCD.AlarmCondition.Visible = true
				elseif InEvac == true then

					LCD.Menu.Visible = false
					LCD.Alarm.Visible = true

				else

					LCD.Menu.Visible = false
					LCD.Home.Visible = true

				end	

			elseif Level2MenuInput == "Test" then

				if tonumber(InLevel) >= tonumber(UserMenus_Levels.Test) then

					LCD.Level2Menu.Visible = false
					LCD.TestMenu.Visible = true

				else

					LCD.Level2Menu.Visible = false
					LCD.Password.Visible = true
					MenuToOpen = "Test"

				end

			elseif Level2MenuInput == "Delay" then

				if tonumber(InLevel) >= tonumber(UserMenus_Levels.Delay) then

					LCD.Level2Menu.Visible = false
					LCD.Delay.Visible = true

				else

					LCD.Level2Menu.Visible = false
					LCD.Password.Visible = true
					MenuToOpen = "Delay"

				end

			elseif Level2MenuInput == "Disable" then

				if tonumber(InLevel) >= tonumber(UserMenus_Levels.Disable) then

					LCD.Level2Menu.Visible = false
					LCD.DisablementMenu.Visible = true
					addZoneToList()

				else

					LCD.Level2Menu.Visible = false
					LCD.Password.Visible = true
					MenuToOpen = "Disable"

				end

			elseif Level2MenuInput == "Enable" then

				if tonumber(InLevel) >= tonumber(UserMenus_Levels.Disable) then

					LCD.Level2Menu.Visible = false
					LCD.DisablementMenu.Visible = true
					addZoneToList()

				else

					LCD.Level2Menu.Visible = false
					LCD.Password.Visible = true
					MenuToOpen = "Enable"

				end

			elseif Level2MenuInput == "Tools" then
				LCD.Level2Menu.Visible = false
				LCD.Tools.Visible = true
			elseif Level2MenuInput == "View" then
				LCD.Level2Menu.Visible = false
				LCD.View.Visible = true
				LCD.View.View2.Visible = false
				LCD.View.View1.Visible = true
			end

		elseif LCD.TestSelection.InTest.Visible == true then
			if testSelect_InTest == "Finish" then

				LCD.TestSelection.Visible = false
				LCD.TestSelection.InTest.Visible = false
				LCD.TestSelection.Sounders.Visible = false


				ClearTestTables()

				if InAlarm and not InTrouble then
					LCD.Alarm.Visible = true
				elseif InTrouble then
					LCD.AlarmCondition.Visible = true
				elseif not InAlarm and not InTrouble then
					LCD.Level2Menu.Visible = true
				end

			elseif testSelect_InTest == "KeepIn" then

				LCD.TestSelection.Visible = false
				LCD.TestSelection.InTest.Visible = false
				LCD.TestSelection.Sounders.Visible = false

				LCD.Level2Menu.Visible = true
			end

		elseif LCD.TestMenu.Visible == true then
			if Test_Input == "Printer" then



			elseif Test_Input == "Zones" then

				LCD.TestMenu.Visible = false
				LCD.TestSelection.Visible = true
				LCD.TestSelection.InTest.Visible = false
				LCD.TestSelection.Sounders.Visible = true

			elseif Test_Input == "Buzzer" then

				Buzzer:Play()
				wait(5)
				Buzzer:Stop()

			elseif Test_Input == "Display" then

				LCD.TestMenu.LCDTest.Visible = true


			end

		elseif LCD.TestSelection.Sounders.Visible == true then
			if testSelect_SoundersInput == "With" then
				LCD.TestSelection.Visible = false
				LCD.TestSelection.Sounders.Visible = false


				LCD.ZoneInput_Test.Visible = true

			elseif testSelect_SoundersInput == "Without" then
				LCD.TestSelection.Visible = false
				LCD.TestSelection.Sounders.Visible = false


				LCD.ZoneInput_Test.Visible = true

			end

		elseif LCD.OutputDisablement.Scroll1.Visible == true and LCD.OutputDisablement.Visible == true then
			if OutputDisablement_Input == "AllOutputs" then

				if AllOutputsDisabled == true then
					AllOutputsDisabled = false
					NetAPI:Fire("Enable", "AllOutputs")
					LCD.OutputDisablement.Visible = false
				else
					AllOutputsDisabled = true
					NetAPI:Fire("Disable", "AllOutputs")
					LCD.OutputDisablement.Visible = false
				end

			elseif OutputDisablement_Input == "AllSounders" then

				if AllOutputsDisabled == true then
					AllOutputsDisabled = false
					NetAPI:Fire("Enable", "AllSounders")
					LCD.OutputDisablement.Visible = false
				else
					AllOutputsDisabled = true
					NetAPI:Fire("Disable", "AllSounders")
					LCD.OutputDisablement.Visible = false
				end

			elseif OutputDisablement_Input == "AllBeacons" then

				if AllOutputsDisabled == true then
					AllOutputsDisabled = false
					NetAPI:Fire("Enable", "AllBeacons")
					LCD.OutputDisablement.Visible = false
				else
					AllOutputsDisabled = true
					NetAPI:Fire("Disable", "AllBeacons")
					LCD.OutputDisablement.Visible = false
				end

			elseif OutputDisablement_Input == "AllOtherRelay" then

				if AllOutputsDisabled == true then
					AllOutputsDisabled = false
					NetAPI:Fire("Enable", "AllOtherRelay")
					LCD.OutputDisablement.Visible = false
				else
					AllOutputsDisabled = true
					NetAPI:Fire("Disable", "AllOtherRelay")
					LCD.OutputDisablement.Visible = false
				end

			end

		elseif LCD.OutputDisablement.Scroll2.Visible == true and LCD.OutputDisablement.Visible == true then
			if OutputDisablement2_Input == "FaultRouting" then

				if FaultRoutingDisabled == true then
					FaultRoutingDisabled = false
					NetAPI:Fire("Enable", "FaultRouting")
					LCD.OutputDisablement.Visible = false
				else
					FaultRoutingDisabled = true
					NetAPI:Fire("Disable", "FaultRouting")
					LCD.OutputDisablement.Visible = false

				end

			elseif OutputDisablement2_Input == "FireProtection" then

				if FireProtectionDisabled == true then
					FireProtectionDisabled = false
					NetAPI:Fire("Enable", "FireProtection")
					LCD.OutputDisablement.Visible = false
				else
					FireProtectionDisabled = true
					NetAPI:Fire("Disable", "FireProtection")
					LCD.OutputDisablement.Visible = false

				end

			elseif OutputDisablement2_Input == "FireRouting" then

				if FireRoutingDisabled == true then
					FireRoutingDisabled = false
					NetAPI:Fire("Enable", "FireRouting")
					LCD.OutputDisablement.Visible = false
				else
					FireRoutingDisabled = true
					NetAPI:Fire("Disable", "FireRouting")
					LCD.OutputDisablement.Visible = false

				end

			elseif OutputDisablement2_Input == "OnlySelected" then

				LCD.OutputDisablement.Visible = false
				LCD.OutputDevices.Visible = true

			end

		elseif LCD.DisablementMenu.Visible == true then
			if DisablementMenu_Input == "ZoneInputs" then
				LCD.DisablementMenu.Visible = false
				LCD.ZoneInput.Visible = true
			elseif DisablementMenu_Input == "Outputs" then

				LCD.OutputDisablement.Visible = true
			end




		elseif LCD.ZoneInput.List.Visible == true and LCD.ZoneInput.Visible == true then

			if LCD.ZoneInput.Function.Visible == false then

				if currentFrameIndex_ZONES >= 1 then

					LCD.ZoneInput.Function.Visible = true

					local zOneq = zonesTable[currentFrameIndex_ZONES]
					local z0neDisablementtaBle = ZoneDisablementTable[zOneq]

					print(zOneq)

					if z0neDisablementtaBle then

						if LCD and LCD.ZoneInput and LCD.ZoneInput.Function then
							if LCD.ZoneInput.Function.AllInputs then
								if z0neDisablementtaBle["allInputs"] == true then
									LCD.ZoneInput.Function.AllInputs.Text = "   ALL INPUTS (D)"

								else
									LCD.ZoneInput.Function.AllInputs.Text = "   ALL INPUTS"

								end

							end

							if LCD.ZoneInput.Function.OnlyAutomaticDetectors then
								if z0neDisablementtaBle["Detectors"] == true then
									LCD.ZoneInput.Function.OnlyAutomaticDetectors.Text = "   ONLY AUTOMATIC DETECTORS (D)"

								else
									LCD.ZoneInput.Function.OnlyAutomaticDetectors.Text = "   ONLY AUTOMATIC DETECTORS"

								end

							end

							if LCD.ZoneInput.Function.OnlyManualDevices then
								if z0neDisablementtaBle["Callpoints"] == true then
									LCD.ZoneInput.Function.OnlyManualDevices.Text = "   ONLY MANUAL DEVICES (D)"

								else
									LCD.ZoneInput.Function.OnlyManualDevices.Text = "   ONLY MANUAL DEVICES"

								end

							end

						end
					end

				else





				end

			elseif LCD.ZoneInput.Function.Visible == true and LCD.ZoneInput.Visible == true then
				if ZoneFunction_Input == "AllInputs" then

					local CurrentZoneq = zonesTable[currentFrameIndex_ZONES]


					for _, zone in ipairs(ZoneDisablementTable) do
						if zone.Zone == CurrentZoneq then

							if zone["allInputs"] == true then
								zone["allInputs"] = false
								NetAPI:Fire("Enable", "AllInputs", CurrentZoneq)
								local CurrentFrame = frames_ZONES[currentFrameIndex_ZONES]
								CurrentFrame.Mode.Text = "Enabled"
								LCD.ZoneInput.Function.Visible = false
								checkDisablements()

								zone.Detectors = false
								zone.Callpoints = false

							else
								zone["allInputs"] = true
								NetAPI:Fire("Disable", "AllInputs", CurrentZoneq)
								local CurrentFrame = frames_ZONES[currentFrameIndex_ZONES]
								CurrentFrame.Mode.Text = "Disabled"
								LCD.ZoneInput.Function.Visible = false
								checkDisablements()

								zone.Detectors = true
								zone.Callpoints = true

							end

						end
					end


				elseif ZoneFunction_Input == "AutomaticDetectors" then

					local CurrentZoneq = zonesTable[currentFrameIndex_ZONES]


					for _, zone in ipairs(ZoneDisablementTable) do
						if zone.Zone == CurrentZoneq then

							if zone["Detectors"] == true then
								zone["Detectors"] = false
								NetAPI:Fire("Enable", "Detectors", CurrentZoneq)
								local CurrentFrame = frames_ZONES[currentFrameIndex_ZONES]

								LCD.ZoneInput.Function.Visible = false

								if zone.Callpoints == false then
									zone["Callpoints"] = false
									CurrentFrame.Mode.Text = "Enabled"
								else
									zone["Callpoints"] = true
									CurrentFrame.Mode.Text = "Part-Disabled"
								end

								checkDisablements()
							else
								zone["Detectors"] = true
								NetAPI:Fire("Disable", "Detectors", CurrentZoneq)
								local CurrentFrame = frames_ZONES[currentFrameIndex_ZONES]

								LCD.ZoneInput.Function.Visible = false

								if zone.Callpoints == false then
									zone["Callpoints"] = false
									CurrentFrame.Mode.Text = "Part-Disabled"
								else
									zone["Callpoints"] = true
									CurrentFrame.Mode.Text = "Disabled"
								end

								checkDisablements()

							end

						end
					end

				elseif ZoneFunction_Input == "ManualDevices" then

					local CurrentZoneq = zonesTable[currentFrameIndex_ZONES]


					for _, zone in ipairs(ZoneDisablementTable) do
						if zone.Zone == CurrentZoneq then

							if zone["Callpoints"] == true then
								zone["Callpoints"] = false
								NetAPI:Fire("Enable", "Callpoints", CurrentZoneq)
								local CurrentFrame = frames_ZONES[currentFrameIndex_ZONES]

								LCD.ZoneInput.Function.Visible = false

								if zone.Detectors == false then
									zone["Detectors"] = false
									CurrentFrame.Mode.Text = "Enabled"
								else
									zone["Detectors"] = true
									CurrentFrame.Mode.Text = "Part-Disabled"
								end

								checkDisablements()
							else
								zone["Callpoints"] = true
								NetAPI:Fire("Disable", "Callpoints", CurrentZoneq)
								local CurrentFrame = frames_ZONES[currentFrameIndex_ZONES]

								LCD.ZoneInput.Function.Visible = false

								if zone.Detectors == false then
									zone["Detectors"] = false
									CurrentFrame.Mode.Text = "Part-Disabled"
								else
									zone["Detectors"] = true
									CurrentFrame.Mode.Text = "Disabled"
								end

								checkDisablements()

							end

						end
					end

				end

				checkDisablements()







			end







		end












	end
end)

Buttons.DownArrow.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Menu.Visible == true then



				if MenuInput == "Enable_Controls" then
					MenuInput = "LEDTest"
					LCD.Menu.EnableControls.TextColor3 = Color3.new(0, 0, 0)
					LCD.Menu.EnableControls.BackgroundTransparency = 1

					LCD.Menu.LEDTest.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Menu.LEDTest.BackgroundTransparency = 0
				elseif MenuInput == "View" then
					MenuInput = "Status"
					LCD.Menu.View.TextColor3 = Color3.new(0, 0, 0)
					LCD.Menu.View.BackgroundTransparency = 1

					LCD.Menu.Status.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Menu.Status.BackgroundTransparency = 0
				end

				--

			elseif LCD.SpecificOutputDevices.Visible == true then
				shiftFramesDown_OUTPUTZONES_CERTAIN()

			elseif LCD.OutputDevices.Visible == true then
				shiftFramesDown_OUTPUTZONES()

			elseif LCD.MoreAlarms_Zone.Visible == true then
				shiftFramesDown_MOREALARMSZONES()

			elseif LCD.TestMenu.LCDTest.Visible == true then
				LCD.TestMenu.LCDTest.ButtonInput.Text = "?"

			elseif LCD.LoopInfo.Visible == true then
				if LoopInfoInput == "View" then
					LoopInfoInput = "History"
					LCD.LoopInfo.ViewEdit.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.ViewEdit.BackgroundTransparency = 1
					LCD.LoopInfo.History.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.History.BackgroundTransparency = 0

				elseif LoopInfoInput == "AutoLearn" then
					LoopInfoInput = "Meter"
					LCD.LoopInfo.AutoLearn.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.AutoLearn.BackgroundTransparency = 1
					LCD.LoopInfo.Meter.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.Meter.BackgroundTransparency = 0

				elseif LoopInfoInput == "Meter" then
					LoopInfoInput = "SelfTest"
					LCD.LoopInfo.Meter.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.Meter.BackgroundTransparency = 1
					LCD.LoopInfo.SelfTest.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.SelfTest.BackgroundTransparency = 0


				elseif LoopInfoInput == "Calibrate" then
					LoopInfoInput = "Scope"
					LCD.LoopInfo.Calibrate.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.Calibrate.BackgroundTransparency = 1
					LCD.LoopInfo.Scope.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.Scope.BackgroundTransparency = 0


				end




				---

			elseif LCD.MoreAlarms.Visible == true then
				shiftFramesDown_MOREALARMS()


			elseif LCD.LoopSelect.Visible == true then
				if LCD.LoopSelect.AmountOfLoops.Value == "2" then

					if LoopSelectInput == "L1" then
						LoopSelectInput = "L4"
						LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 0


					end

				elseif LCD.LoopSelect.AmountOfLoops.Value == "4" then

					if LoopSelectInput == "L1" then
						LoopSelectInput = "L4"
						LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 0


					end

				elseif LCD.LoopSelect.AmountOfLoops.Value == "8" then

					if LoopSelectInput == "L1" then
						LoopSelectInput = "L4"
						LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 0
					elseif LoopSelectInput == "L4" then
						LoopSelectInput = "L7"
						LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop7.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop7.BackgroundTransparency = 0

					elseif LoopSelectInput == "L2" then
						LoopSelectInput = "L5"
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 0
					elseif LoopSelectInput == "L5" then
						LoopSelectInput = "L8"
						LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop8.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop8.BackgroundTransparency = 0

					elseif LoopSelectInput == "L3" then
						LoopSelectInput = "L6"
						LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop6.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop6.BackgroundTransparency = 0

					end

				end


				---

			elseif LCD.Delay.Visible == true then
				if DelayInput == "NoInvestigation" then
					DelayInput = "OnceOnly"
					LCD.Delay.Function.NoInvestigationDelay.TextColor3 = Color3.new(0, 0, 0)
					LCD.Delay.Function.NoInvestigationDelay.BackgroundTransparency = 1

					LCD.Delay.Function.OnceOnly.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Delay.Function.OnceOnly.BackgroundTransparency = 0
				elseif DelayInput == "OnceOnly" then
					DelayInput = "Automatic"
					LCD.Delay.Function.OnceOnly.TextColor3 = Color3.new(0, 0, 0)
					LCD.Delay.Function.OnceOnly.BackgroundTransparency = 1

					LCD.Delay.Function.Automatic.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Delay.Function.Automatic.BackgroundTransparency = 0
				elseif DelayInput == "Automatic" then
					DelayInput = "Extended"
					LCD.Delay.Function.Automatic.TextColor3 = Color3.new(0, 0, 0)
					LCD.Delay.Function.Automatic.BackgroundTransparency = 1

					LCD.Delay.Function.Extended.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Delay.Function.Extended.BackgroundTransparency = 0
				end

			elseif LCD.ZoneInput_Test.Visible == true then
				shiftFramesDown_ZONESTEST()

			elseif LCD.LoopDevices.Visible == true then

				for a, framea in ipairs(frames_LOOPS) do
					if a == currentFrameIndex_LOOPS then
						previousZone = framea.Zone.Text
					end
				end

				for i, frame in ipairs(frames_LOOPS) do
					if i == currentFrameIndex_LOOPS then
						frame.Zone.Text = convert000Format(previousZone)
					end
				end

				newZoneInput = ""
				shiftFramesDown_LOOPS()



			elseif LCD.Commission.Menu1.Visible == true then

				if Commission_Input1 == "Loops" then
					Commission_Input1 = "View"
					LCD.Commission.Menu1.Loops.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Loops.BackgroundTransparency = 1

					LCD.Commission.Menu1.View.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.View.BackgroundTransparency = 0

				elseif Commission_Input1 == "Zones" then
					Commission_Input1 = "Disable"
					LCD.Commission.Menu1.Zones.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Zones.BackgroundTransparency = 1

					LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Disable.BackgroundTransparency = 0

				elseif Commission_Input1 == "Disable" then
					Commission_Input1 = "NextMenu"
					LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Disable.BackgroundTransparency = 1

					LCD.Commission.Menu1.NextMenu.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.NextMenu.BackgroundTransparency = 0

				elseif Commission_Input1 == "Exit" then
					Commission_Input1 = "Enable"
					LCD.Commission.Menu1.Exit.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Exit.BackgroundTransparency = 1

					LCD.Commission.Menu1.Enable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Enable.BackgroundTransparency = 0

				end

			elseif LCD.Level2Menu.Visible == true then
				if Level2MenuInput == "View" then
					Level2MenuInput = "Test"

					LCD.Level2Menu.View.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.View.BackgroundTransparency = 1

					LCD.Level2Menu.Test.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Test.BackgroundTransparency = 0
				elseif Level2MenuInput == "Disable" then
					Level2MenuInput = "Delay"
					LCD.Level2Menu.Disable.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Disable.BackgroundTransparency = 1

					LCD.Level2Menu.Delay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Delay.BackgroundTransparency = 0

				elseif Level2MenuInput == "Delay" then
					Level2MenuInput = "Status"
					LCD.Level2Menu.Delay.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Delay.BackgroundTransparency = 1

					LCD.Level2Menu.Status.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Status.BackgroundTransparency = 0
				elseif Level2MenuInput == "Enable" then
					Level2MenuInput = "Tools"
					LCD.Level2Menu.Enable.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Enable.BackgroundTransparency = 1

					LCD.Level2Menu.Tools.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Tools.BackgroundTransparency = 0
				end

			elseif LCD.Commission.Menu2.Visible == true then

				if Commission_Input2 == "Passwords" then
					Commission_Input2 = "EN"
					LCD.Commission.Menu2.Passwords.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.Passwords.BackgroundTransparency = 1

					LCD.Commission.Menu2.EN.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.EN.BackgroundTransparency = 0
				elseif Commission_Input2 == "TimeDate" then
					Commission_Input2 = "Setup"
					LCD.Commission.Menu2.TimeDate.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.TimeDate.BackgroundTransparency = 1

					LCD.Commission.Menu2.Setup.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.Setup.BackgroundTransparency = 0
				elseif Commission_Input2 == "PCConfig" then
					Commission_Input2 = "Display"
					LCD.Commission.Menu2.PCConfig.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.PCConfig.BackgroundTransparency = 1

					LCD.Commission.Menu2.Display.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.Display.BackgroundTransparency = 0


				end
				--

			elseif LCD.View.View2.Visible == true and LCD.View.Visible == true then
				if viewMenu2_Input == "Network" then
					viewMenu2_Input = "Log"

					LCD.View.View2.Network.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View2.Network.BackgroundTransparency = 1

					LCD.View.View2.Log.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View2.Log.BackgroundTransparency = 0

				elseif viewMenu2_Input == "Panel" then
					viewMenu2_Input = "Supervisory"
					LCD.View.View2.Panel.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View2.Panel.BackgroundTransparency = 1

					LCD.View.View2.Supervisory.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View2.Supervisory.BackgroundTransparency = 0




				end

			elseif LCD.View.View1.Visible == true then
				if viewMenu_Input == "Alarms" then
					viewMenu_Input = "Outputs"

					LCD.View.View1.Alarms.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Alarms.BackgroundTransparency = 1

					LCD.View.View1.Outputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Outputs.BackgroundTransparency = 0

				elseif viewMenu_Input == "Faults" then
					viewMenu_Input = "Inputs"

					LCD.View.View1.Faults.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Faults.BackgroundTransparency = 1

					LCD.View.View1.Inputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Inputs.BackgroundTransparency = 0

				elseif viewMenu_Input == "Inputs" then
					viewMenu_Input = "NextMenu"

					LCD.View.View1.Inputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Inputs.BackgroundTransparency = 1

					LCD.View.View1.NextMenu.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.NextMenu.BackgroundTransparency = 0

				elseif viewMenu_Input == "Fires" then
					viewMenu_Input = "Disabled"

					LCD.View.View1.Fires.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Fires.BackgroundTransparency = 1

					LCD.View.View1.Disabled.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Disabled.BackgroundTransparency = 0



				end

			elseif LCD.TestSelection.InTest.Visible == true then
				if testSelect_InTest == "Finish" then
					testSelect_InTest = "KeepIn"

					LCD.TestSelection.InTest.Finished.TextColor3 = Color3.new(0, 0, 0)
					LCD.TestSelection.InTest.Finished.BackgroundTransparency = 1

					LCD.TestSelection.InTest.KeepIn.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.TestSelection.InTest.KeepIn.BackgroundTransparency = 0
				end

			elseif LCD.TestSelection.Sounders.Visible == true then
				if testSelect_SoundersInput == "Without" then
					testSelect_SoundersInput = "With"

					LCD.TestSelection.Sounders.WithoutSounders.TextColor3 = Color3.new(0, 0, 0)
					LCD.TestSelection.Sounders.WithoutSounders.BackgroundTransparency = 1

					LCD.TestSelection.Sounders.WithSounders.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.TestSelection.Sounders.WithSounders.BackgroundTransparency = 0
				end




			elseif LCD.TestMenu.Visible == true then
				if Test_Input == "Zones" then

					Test_Input = "Outputs"

					LCD.TestMenu.Zones.TextColor3 = Color3.new(0, 0, 0)
					LCD.TestMenu.Zones.BackgroundTransparency = 1

					LCD.TestMenu.Outputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.TestMenu.Outputs.BackgroundTransparency = 0


				end

			elseif LCD.OutputDisablement.Scroll1.Visible == true and LCD.OutputDisablement.Visible == true then
				if OutputDisablement_Input == "AllOutputs" then
					OutputDisablement_Input = "AllSounders"

					LCD.OutputDisablement.Scroll1.AllOutputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.OutputDisablement.Scroll1.AllOutputs.BackgroundTransparency = 1

					LCD.OutputDisablement.Scroll1.AllSounders.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.OutputDisablement.Scroll1.AllSounders.BackgroundTransparency = 0

				elseif OutputDisablement_Input == "AllSounders" then
					OutputDisablement_Input = "AllBeacons"

					LCD.OutputDisablement.Scroll1.AllSounders.TextColor3 = Color3.new(0, 0, 0)
					LCD.OutputDisablement.Scroll1.AllSounders.BackgroundTransparency = 1

					LCD.OutputDisablement.Scroll1.AllBeacons.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.OutputDisablement.Scroll1.AllBeacons.BackgroundTransparency = 0

				elseif OutputDisablement_Input == "AllBeacons" then
					OutputDisablement_Input = "AllOtherRelay"

					LCD.OutputDisablement.Scroll1.AllBeacons.TextColor3 = Color3.new(0, 0, 0)
					LCD.OutputDisablement.Scroll1.AllBeacons.BackgroundTransparency = 1

					LCD.OutputDisablement.Scroll1.AllOtherRelay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.OutputDisablement.Scroll1.AllOtherRelay.BackgroundTransparency = 0
				elseif OutputDisablement_Input == "AllOtherRelay" then

					LCD.OutputDisablement.Scroll1.Visible = false
					LCD.OutputDisablement.Scroll2.Visible = true

				end

			elseif LCD.OutputDisablement.Scroll2.Visible == true and LCD.OutputDisablement.Visible == true then

				if OutputDisablement2_Input == "FireProtection" then

					OutputDisablement2_Input = "FaultRouting"

					LCD.OutputDisablement.Scroll2.FireProtectionOutputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.OutputDisablement.Scroll2.FireProtectionOutputs.BackgroundTransparency = 1

					LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.BackgroundTransparency = 0

				elseif OutputDisablement2_Input == "FaultRouting" then

					OutputDisablement2_Input = "FireRouting"

					LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.BackgroundTransparency = 1

					LCD.OutputDisablement.Scroll2.FireRoutingOutputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.OutputDisablement.Scroll2.FireRoutingOutputs.BackgroundTransparency = 0

				elseif OutputDisablement2_Input == "FireRouting" then

					OutputDisablement2_Input = "OnlySelected"

					LCD.OutputDisablement.Scroll2.FireRoutingOutputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.OutputDisablement.Scroll2.FireRoutingOutputs.BackgroundTransparency = 1

					LCD.OutputDisablement.Scroll2.OnlySelected.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.OutputDisablement.Scroll2.OnlySelected.BackgroundTransparency = 0


				end

			elseif LCD.DisablementMenu.Visible == true then
				if DisablementMenu_Input == "ZoneInputs" then
					DisablementMenu_Input = "Controls"

					LCD.DisablementMenu.ZonesInputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.DisablementMenu.ZonesInputs.BackgroundTransparency = 1

					LCD.DisablementMenu.Controls.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.DisablementMenu.Controls.BackgroundTransparency = 0
				elseif DisablementMenu_Input == "Outputs" then
					DisablementMenu_Input = "UserID"

					LCD.DisablementMenu.Outputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.DisablementMenu.Outputs.BackgroundTransparency = 1

					LCD.DisablementMenu.UserID.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.DisablementMenu.UserID.BackgroundTransparency = 0

				end

			elseif LCD.ZoneInput.Function.Visible == true then
				if ZoneFunction_Input == "AllInputs" then
					ZoneFunction_Input = "SelectedInputs"

					LCD.ZoneInput.Function.AllInputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.ZoneInput.Function.AllInputs.BackgroundTransparency = 1

					LCD.ZoneInput.Function.SelectedInputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.ZoneInput.Function.SelectedInputs.BackgroundTransparency = 0

				elseif ZoneFunction_Input == "SelectedInputs" then
					ZoneFunction_Input = "AutomaticDetectors"

					LCD.ZoneInput.Function.SelectedInputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.ZoneInput.Function.SelectedInputs.BackgroundTransparency = 1

					LCD.ZoneInput.Function.OnlyAutomaticDetectors.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.ZoneInput.Function.OnlyAutomaticDetectors.BackgroundTransparency = 0

				elseif ZoneFunction_Input == "AutomaticDetectors" then
					ZoneFunction_Input = "ManualDevices"

					LCD.ZoneInput.Function.OnlyAutomaticDetectors.TextColor3 = Color3.new(0, 0, 0)
					LCD.ZoneInput.Function.OnlyAutomaticDetectors.BackgroundTransparency = 1

					LCD.ZoneInput.Function.OnlyManualDevices.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.ZoneInput.Function.OnlyManualDevices.BackgroundTransparency = 0

				end



			elseif LCD.ZoneInput.List.Visible == true then
				if LCD.ZoneInput.Function.Visible == false then

					shiftFramesDown_ZONES()

				end




			end
		end
	else

		if LCD.Menu.Visible == true then



			if MenuInput == "Enable_Controls" then
				MenuInput = "LEDTest"
				LCD.Menu.EnableControls.TextColor3 = Color3.new(0, 0, 0)
				LCD.Menu.EnableControls.BackgroundTransparency = 1

				LCD.Menu.LEDTest.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Menu.LEDTest.BackgroundTransparency = 0
			elseif MenuInput == "View" then
				MenuInput = "Status"
				LCD.Menu.View.TextColor3 = Color3.new(0, 0, 0)
				LCD.Menu.View.BackgroundTransparency = 1

				LCD.Menu.Status.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Menu.Status.BackgroundTransparency = 0
			end

			--

		elseif LCD.SpecificOutputDevices.Visible == true then
			shiftFramesDown_OUTPUTZONES_CERTAIN()

		elseif LCD.OutputDevices.Visible == true then
			shiftFramesDown_OUTPUTZONES()

		elseif LCD.MoreAlarms_Zone.Visible == true then
			shiftFramesDown_MOREALARMSZONES()

		elseif LCD.TestMenu.LCDTest.Visible == true then
			LCD.TestMenu.LCDTest.ButtonInput.Text = "?"

		elseif LCD.LoopInfo.Visible == true then
			if LoopInfoInput == "View" then
				LoopInfoInput = "History"
				LCD.LoopInfo.ViewEdit.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.ViewEdit.BackgroundTransparency = 1
				LCD.LoopInfo.History.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.History.BackgroundTransparency = 0

			elseif LoopInfoInput == "AutoLearn" then
				LoopInfoInput = "Meter"
				LCD.LoopInfo.AutoLearn.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.AutoLearn.BackgroundTransparency = 1
				LCD.LoopInfo.Meter.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.Meter.BackgroundTransparency = 0

			elseif LoopInfoInput == "Meter" then
				LoopInfoInput = "SelfTest"
				LCD.LoopInfo.Meter.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.Meter.BackgroundTransparency = 1
				LCD.LoopInfo.SelfTest.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.SelfTest.BackgroundTransparency = 0


			elseif LoopInfoInput == "Calibrate" then
				LoopInfoInput = "Scope"
				LCD.LoopInfo.Calibrate.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.Calibrate.BackgroundTransparency = 1
				LCD.LoopInfo.Scope.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.Scope.BackgroundTransparency = 0


			end

			---

		elseif LCD.MoreAlarms.Visible == true then
			shiftFramesDown_MOREALARMS()

		elseif LCD.ZoneInput_Test.Visible == true then
			shiftFramesDown_ZONESTEST()

		elseif LCD.LoopDevices.Visible == true then

			for a, framea in ipairs(frames_LOOPS) do
				if a == currentFrameIndex_LOOPS then
					previousZone = framea.Zone.Text
				end
			end

			for i, frame in ipairs(frames_LOOPS) do
				if i == currentFrameIndex_LOOPS then
					frame.Zone.Text = convert000Format(previousZone)
				end
			end

			newZoneInput = ""
			shiftFramesDown_LOOPS()

		elseif LCD.LoopSelect.Visible == true then
			if LCD.LoopSelect.AmountOfLoops.Value == "2" then

				if LoopSelectInput == "L1" then
					LoopSelectInput = "L4"
					LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 0


				end

			elseif LCD.LoopSelect.AmountOfLoops.Value == "4" then

				if LoopSelectInput == "L1" then
					LoopSelectInput = "L4"
					LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 0


				end

			elseif LCD.LoopSelect.AmountOfLoops.Value == "8" then

				if LoopSelectInput == "L1" then
					LoopSelectInput = "L4"
					LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 0
				elseif LoopSelectInput == "L4" then
					LoopSelectInput = "L7"
					LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop7.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop7.BackgroundTransparency = 0

				elseif LoopSelectInput == "L2" then
					LoopSelectInput = "L5"
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 0
				elseif LoopSelectInput == "L5" then
					LoopSelectInput = "L8"
					LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop8.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop8.BackgroundTransparency = 0

				elseif LoopSelectInput == "L3" then
					LoopSelectInput = "L6"
					LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop6.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop6.BackgroundTransparency = 0

				end

			end


			---

		elseif LCD.Delay.Visible == true then
			if DelayInput == "NoInvestigation" then
				DelayInput = "OnceOnly"
				LCD.Delay.Function.NoInvestigationDelay.TextColor3 = Color3.new(0, 0, 0)
				LCD.Delay.Function.NoInvestigationDelay.BackgroundTransparency = 1

				LCD.Delay.Function.OnceOnly.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Delay.Function.OnceOnly.BackgroundTransparency = 0
			elseif DelayInput == "OnceOnly" then
				DelayInput = "Automatic"
				LCD.Delay.Function.OnceOnly.TextColor3 = Color3.new(0, 0, 0)
				LCD.Delay.Function.OnceOnly.BackgroundTransparency = 1

				LCD.Delay.Function.Automatic.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Delay.Function.Automatic.BackgroundTransparency = 0
			elseif DelayInput == "Automatic" then
				DelayInput = "Extended"
				LCD.Delay.Function.Automatic.TextColor3 = Color3.new(0, 0, 0)
				LCD.Delay.Function.Automatic.BackgroundTransparency = 1

				LCD.Delay.Function.Extended.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Delay.Function.Extended.BackgroundTransparency = 0
			end


		elseif LCD.Commission.Menu1.Visible == true then

			if Commission_Input1 == "Loops" then
				Commission_Input1 = "View"
				LCD.Commission.Menu1.Loops.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Loops.BackgroundTransparency = 1

				LCD.Commission.Menu1.View.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.View.BackgroundTransparency = 0

			elseif Commission_Input1 == "Zones" then
				Commission_Input1 = "Disable"
				LCD.Commission.Menu1.Zones.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Zones.BackgroundTransparency = 1

				LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Disable.BackgroundTransparency = 0

			elseif Commission_Input1 == "Disable" then
				Commission_Input1 = "NextMenu"
				LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Disable.BackgroundTransparency = 1

				LCD.Commission.Menu1.NextMenu.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.NextMenu.BackgroundTransparency = 0

			elseif Commission_Input1 == "Exit" then
				Commission_Input1 = "Enable"
				LCD.Commission.Menu1.Exit.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Exit.BackgroundTransparency = 1

				LCD.Commission.Menu1.Enable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Enable.BackgroundTransparency = 0

			end

		elseif LCD.Level2Menu.Visible == true then
			if Level2MenuInput == "View" then
				Level2MenuInput = "Test"

				LCD.Level2Menu.View.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.View.BackgroundTransparency = 1

				LCD.Level2Menu.Test.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Test.BackgroundTransparency = 0
			elseif Level2MenuInput == "Disable" then
				Level2MenuInput = "Delay"
				LCD.Level2Menu.Disable.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Disable.BackgroundTransparency = 1

				LCD.Level2Menu.Delay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Delay.BackgroundTransparency = 0

			elseif Level2MenuInput == "Delay" then
				Level2MenuInput = "Status"
				LCD.Level2Menu.Delay.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Delay.BackgroundTransparency = 1

				LCD.Level2Menu.Status.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Status.BackgroundTransparency = 0
			elseif Level2MenuInput == "Enable" then
				Level2MenuInput = "Tools"
				LCD.Level2Menu.Enable.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Enable.BackgroundTransparency = 1

				LCD.Level2Menu.Tools.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Tools.BackgroundTransparency = 0
			end

		elseif LCD.Commission.Menu2.Visible == true then

			if Commission_Input2 == "Passwords" then
				Commission_Input2 = "EN"
				LCD.Commission.Menu2.Passwords.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.Passwords.BackgroundTransparency = 1

				LCD.Commission.Menu2.EN.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.EN.BackgroundTransparency = 0
			elseif Commission_Input2 == "TimeDate" then
				Commission_Input2 = "Setup"
				LCD.Commission.Menu2.TimeDate.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.TimeDate.BackgroundTransparency = 1

				LCD.Commission.Menu2.Setup.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.Setup.BackgroundTransparency = 0
			elseif Commission_Input2 == "PCConfig" then
				Commission_Input2 = "Display"
				LCD.Commission.Menu2.PCConfig.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.PCConfig.BackgroundTransparency = 1

				LCD.Commission.Menu2.Display.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.Display.BackgroundTransparency = 0


			end
			--

		elseif LCD.View.View2.Visible == true and LCD.View.Visible == true then
			if viewMenu2_Input == "Network" then
				viewMenu2_Input = "Log"

				LCD.View.View2.Network.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View2.Network.BackgroundTransparency = 1

				LCD.View.View2.Log.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View2.Log.BackgroundTransparency = 0

			elseif viewMenu2_Input == "Panel" then
				viewMenu2_Input = "Supervisory"
				LCD.View.View2.Panel.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View2.Panel.BackgroundTransparency = 1

				LCD.View.View2.Supervisory.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View2.Supervisory.BackgroundTransparency = 0




			end

		elseif LCD.View.View1.Visible == true then
			if viewMenu_Input == "Alarms" then
				viewMenu_Input = "Outputs"

				LCD.View.View1.Alarms.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Alarms.BackgroundTransparency = 1

				LCD.View.View1.Outputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Outputs.BackgroundTransparency = 0

			elseif viewMenu_Input == "Faults" then
				viewMenu_Input = "Inputs"

				LCD.View.View1.Faults.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Faults.BackgroundTransparency = 1

				LCD.View.View1.Inputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Inputs.BackgroundTransparency = 0

			elseif viewMenu_Input == "Inputs" then
				viewMenu_Input = "NextMenu"

				LCD.View.View1.Inputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Inputs.BackgroundTransparency = 1

				LCD.View.View1.NextMenu.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.NextMenu.BackgroundTransparency = 0

			elseif viewMenu_Input == "Fires" then
				viewMenu_Input = "Disabled"

				LCD.View.View1.Fires.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Fires.BackgroundTransparency = 1

				LCD.View.View1.Disabled.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Disabled.BackgroundTransparency = 0



			end

		elseif LCD.TestSelection.InTest.Visible == true then
			if testSelect_InTest == "Finish" then
				testSelect_InTest = "KeepIn"

				LCD.TestSelection.InTest.Finished.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestSelection.InTest.Finished.BackgroundTransparency = 1

				LCD.TestSelection.InTest.KeepIn.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestSelection.InTest.KeepIn.BackgroundTransparency = 0
			end

		elseif LCD.TestSelection.Sounders.Visible == true then
			if testSelect_SoundersInput == "Without" then
				testSelect_SoundersInput = "With"

				LCD.TestSelection.Sounders.WithoutSounders.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestSelection.Sounders.WithoutSounders.BackgroundTransparency = 1

				LCD.TestSelection.Sounders.WithSounders.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestSelection.Sounders.WithSounders.BackgroundTransparency = 0
			end




		elseif LCD.TestMenu.Visible == true then
			if Test_Input == "Zones" then

				Test_Input = "Outputs"

				LCD.TestMenu.Zones.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestMenu.Zones.BackgroundTransparency = 1

				LCD.TestMenu.Outputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestMenu.Outputs.BackgroundTransparency = 0


			end

		elseif LCD.OutputDisablement.Scroll1.Visible == true and LCD.OutputDisablement.Visible == true then
			if OutputDisablement_Input == "AllOutputs" then
				OutputDisablement_Input = "AllSounders"

				LCD.OutputDisablement.Scroll1.AllOutputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.OutputDisablement.Scroll1.AllOutputs.BackgroundTransparency = 1

				LCD.OutputDisablement.Scroll1.AllSounders.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.OutputDisablement.Scroll1.AllSounders.BackgroundTransparency = 0

			elseif OutputDisablement_Input == "AllSounders" then
				OutputDisablement_Input = "AllBeacons"

				LCD.OutputDisablement.Scroll1.AllSounders.TextColor3 = Color3.new(0, 0, 0)
				LCD.OutputDisablement.Scroll1.AllSounders.BackgroundTransparency = 1

				LCD.OutputDisablement.Scroll1.AllBeacons.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.OutputDisablement.Scroll1.AllBeacons.BackgroundTransparency = 0

			elseif OutputDisablement_Input == "AllBeacons" then
				OutputDisablement_Input = "AllOtherRelay"

				LCD.OutputDisablement.Scroll1.AllBeacons.TextColor3 = Color3.new(0, 0, 0)
				LCD.OutputDisablement.Scroll1.AllBeacons.BackgroundTransparency = 1

				LCD.OutputDisablement.Scroll1.AllOtherRelay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.OutputDisablement.Scroll1.AllOtherRelay.BackgroundTransparency = 0
			elseif OutputDisablement_Input == "AllOtherRelay" then

				LCD.OutputDisablement.Scroll1.Visible = false
				LCD.OutputDisablement.Scroll2.Visible = true

			end

		elseif LCD.OutputDisablement.Scroll2.Visible == true and LCD.OutputDisablement.Visible == true then

			if OutputDisablement2_Input == "FireProtection" then

				OutputDisablement2_Input = "FaultRouting"

				LCD.OutputDisablement.Scroll2.FireProtectionOutputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.OutputDisablement.Scroll2.FireProtectionOutputs.BackgroundTransparency = 1

				LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.BackgroundTransparency = 0

			elseif OutputDisablement2_Input == "FaultRouting" then

				OutputDisablement2_Input = "FireRouting"

				LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.BackgroundTransparency = 1

				LCD.OutputDisablement.Scroll2.FireRoutingOutputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.OutputDisablement.Scroll2.FireRoutingOutputs.BackgroundTransparency = 0

			elseif OutputDisablement2_Input == "FireRouting" then

				OutputDisablement2_Input = "OnlySelected"

				LCD.OutputDisablement.Scroll2.FireRoutingOutputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.OutputDisablement.Scroll2.FireRoutingOutputs.BackgroundTransparency = 1

				LCD.OutputDisablement.Scroll2.OnlySelected.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.OutputDisablement.Scroll2.OnlySelected.BackgroundTransparency = 0


			end

		elseif LCD.DisablementMenu.Visible == true then
			if DisablementMenu_Input == "ZoneInputs" then
				DisablementMenu_Input = "Controls"

				LCD.DisablementMenu.ZonesInputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.DisablementMenu.ZonesInputs.BackgroundTransparency = 1

				LCD.DisablementMenu.Controls.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.DisablementMenu.Controls.BackgroundTransparency = 0
			elseif DisablementMenu_Input == "Outputs" then
				DisablementMenu_Input = "UserID"

				LCD.DisablementMenu.Outputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.DisablementMenu.Outputs.BackgroundTransparency = 1

				LCD.DisablementMenu.UserID.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.DisablementMenu.UserID.BackgroundTransparency = 0

			end

		elseif LCD.ZoneInput.Function.Visible == true then
			if ZoneFunction_Input == "AllInputs" then
				ZoneFunction_Input = "SelectedInputs"

				LCD.ZoneInput.Function.AllInputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.ZoneInput.Function.AllInputs.BackgroundTransparency = 1

				LCD.ZoneInput.Function.SelectedInputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.ZoneInput.Function.SelectedInputs.BackgroundTransparency = 0

			elseif ZoneFunction_Input == "SelectedInputs" then
				ZoneFunction_Input = "AutomaticDetectors"

				LCD.ZoneInput.Function.SelectedInputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.ZoneInput.Function.SelectedInputs.BackgroundTransparency = 1

				LCD.ZoneInput.Function.OnlyAutomaticDetectors.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.ZoneInput.Function.OnlyAutomaticDetectors.BackgroundTransparency = 0

			elseif ZoneFunction_Input == "AutomaticDetectors" then
				ZoneFunction_Input = "ManualDevices"

				LCD.ZoneInput.Function.OnlyAutomaticDetectors.TextColor3 = Color3.new(0, 0, 0)
				LCD.ZoneInput.Function.OnlyAutomaticDetectors.BackgroundTransparency = 1

				LCD.ZoneInput.Function.OnlyManualDevices.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.ZoneInput.Function.OnlyManualDevices.BackgroundTransparency = 0

			end



		elseif LCD.ZoneInput.List.Visible == true then
			if LCD.ZoneInput.Function.Visible == false then

				shiftFramesDown_ZONES()

			end



		end

	end

end)

Buttons.UpArrow.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Menu.Visible == true then



				if MenuInput == "LEDTest" then
					MenuInput = "Enable_Controls"
					LCD.Menu.LEDTest.TextColor3 = Color3.new(0, 0, 0)
					LCD.Menu.LEDTest.BackgroundTransparency = 1

					LCD.Menu.EnableControls.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Menu.EnableControls.BackgroundTransparency = 0
				elseif MenuInput == "Status" then
					MenuInput = "View"
					LCD.Menu.Status.TextColor3 = Color3.new(0, 0, 0)
					LCD.Menu.Status.BackgroundTransparency = 1

					LCD.Menu.View.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Menu.View.BackgroundTransparency = 0
				end

				--

			elseif LCD.SpecificOutputDevices.Visible == true then
				shiftFramesUp_OUTPUTZONES_CERTAIN()

			elseif LCD.OutputDevices.Visible == true then
				shiftFramesUp_OUTPUTZONES()

			elseif LCD.MoreAlarms_Zone.Visible == true then
				shiftFramesUp_MOREALARMSZONES()

			elseif LCD.TestMenu.LCDTest.Visible == true then
				LCD.TestMenu.LCDTest.ButtonInput.Text = "?"

			elseif LCD.MoreAlarms.Visible == true then
				shiftFramesUp_MOREALARMS()

			elseif LCD.ZoneInput_Test.Visible == true then
				shiftFramesUp_ZONESTEST()

			elseif LCD.LoopDevices.Visible == true then

				for a, framea in ipairs(frames_LOOPS) do
					if a == currentFrameIndex_LOOPS then
						previousZone = framea.Zone.Text
					end
				end

				for i, frame in ipairs(frames_LOOPS) do
					if i == currentFrameIndex_LOOPS then
						frame.Zone.Text = convert000Format(previousZone) 
					end
				end

				newZoneInput = ""
				shiftFramesUp_LOOPS()

				---

			elseif LCD.LoopInfo.Visible == true then
				if LoopInfoInput == "History" then
					LoopInfoInput = "View"
					LCD.LoopInfo.History.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.History.BackgroundTransparency = 1
					LCD.LoopInfo.ViewEdit.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.ViewEdit.BackgroundTransparency = 0

				elseif LoopInfoInput == "SelfTest" then
					LoopInfoInput = "Meter"
					LCD.LoopInfo.SelfTest.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.SelfTest.BackgroundTransparency = 1
					LCD.LoopInfo.Meter.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.Meter.BackgroundTransparency = 0

				elseif LoopInfoInput == "Meter" then
					LoopInfoInput = "AutoLearn"
					LCD.LoopInfo.Meter.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.Meter.BackgroundTransparency = 1
					LCD.LoopInfo.AutoLearn.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.AutoLearn.BackgroundTransparency = 0


				elseif LoopInfoInput == "Scope" then
					LoopInfoInput = "Calibrate"
					LCD.LoopInfo.Scope.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.Scope.BackgroundTransparency = 1
					LCD.LoopInfo.Calibrate.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.Calibrate.BackgroundTransparency = 0


				end


			elseif LCD.LoopSelect.Visible == true then
				if LCD.LoopSelect.AmountOfLoops.Value == "2" then

					if LoopSelectInput == "L4" then
						LoopSelectInput = "L1"
						LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 0



					end

				elseif LCD.LoopSelect.AmountOfLoops.Value == "4" then


					if LoopSelectInput == "L4" then
						LoopSelectInput = "L1"
						LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 0



					end

				elseif LCD.LoopSelect.AmountOfLoops.Value == "8" then

					if LoopSelectInput == "L7" then
						LoopSelectInput = "L4"
						LCD.LoopSelect.LoopSelect.Loop7.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop7.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 0
					elseif LoopSelectInput == "L4" then
						LoopSelectInput = "L1"
						LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 0

					elseif LoopSelectInput == "L8" then
						LoopSelectInput = "L5"
						LCD.LoopSelect.LoopSelect.Loop8.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop8.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 0
					elseif LoopSelectInput == "L5" then
						LoopSelectInput = "L2"
						LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0

					elseif LoopSelectInput == "L6" then
						LoopSelectInput = "L3"
						LCD.LoopSelect.LoopSelect.Loop6.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop6.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 0

					end

				end


				---

			elseif LCD.Delay.Visible == true then
				if DelayInput == "Extended" then
					DelayInput = "Automatic"
					LCD.Delay.Function.Extended.TextColor3 = Color3.new(0, 0, 0)
					LCD.Delay.Function.Extended.BackgroundTransparency = 1

					LCD.Delay.Function.Automatic.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Delay.Function.Automatic.BackgroundTransparency = 0
				elseif DelayInput == "Automatic" then
					DelayInput = "OnceOnly"
					LCD.Delay.Function.Automatic.TextColor3 = Color3.new(0, 0, 0)
					LCD.Delay.Function.Automatic.BackgroundTransparency = 1

					LCD.Delay.Function.OnceOnly.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Delay.Function.OnceOnly.BackgroundTransparency = 0
				elseif DelayInput == "OnceOnly" then
					DelayInput = "NoInvestigation"
					LCD.Delay.Function.OnceOnly.TextColor3 = Color3.new(0, 0, 0)
					LCD.Delay.Function.OnceOnly.BackgroundTransparency = 1

					LCD.Delay.Function.NoInvestigationDelay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Delay.Function.NoInvestigationDelay.BackgroundTransparency = 0
				end

			elseif LCD.Commission.Menu1.Visible == true then

				if Commission_Input1 == "Enable" then
					Commission_Input1 = "Exit"
					LCD.Commission.Menu1.Enable.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Enable.BackgroundTransparency = 1

					LCD.Commission.Menu1.Exit.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Exit.BackgroundTransparency = 0

				elseif Commission_Input1 == "Disable" then
					Commission_Input1 = "Zones"
					LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Disable.BackgroundTransparency = 1

					LCD.Commission.Menu1.Zones.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Zones.BackgroundTransparency = 0

				elseif Commission_Input1 == "NextMenu" then
					Commission_Input1 = "Disable"
					LCD.Commission.Menu1.NextMenu.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.NextMenu.BackgroundTransparency = 1

					LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Disable.BackgroundTransparency = 0

				elseif Commission_Input1 == "View" then
					Commission_Input1 = "Loops"
					LCD.Commission.Menu1.View.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.View.BackgroundTransparency = 1

					LCD.Commission.Menu1.Loops.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Loops.BackgroundTransparency = 0

				end

			elseif LCD.Commission.Menu2.Visible == true then

				if Commission_Input2 == "EN" then
					Commission_Input2 = "Passwords"
					LCD.Commission.Menu2.EN.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.EN.BackgroundTransparency = 1

					LCD.Commission.Menu2.Passwords.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.Passwords.BackgroundTransparency = 0
				elseif Commission_Input2 == "Setup" then
					Commission_Input2 = "TimeDate"
					LCD.Commission.Menu2.Setup.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.Setup.BackgroundTransparency = 1

					LCD.Commission.Menu2.TimeDate.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.TimeDate.BackgroundTransparency = 0
				elseif Commission_Input2 == "Display" then
					Commission_Input2 = "PCConfig"
					LCD.Commission.Menu2.Display.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.Display.BackgroundTransparency = 1

					LCD.Commission.Menu2.PCConfig.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.PCConfig.BackgroundTransparency = 0


				end

			elseif LCD.View.View2.Visible == true and LCD.View.Visible == true then
				if viewMenu2_Input == "Log" then
					viewMenu2_Input = "Network"

					LCD.View.View2.Log.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View2.Log.BackgroundTransparency = 1

					LCD.View.View2.Network.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View2.Network.BackgroundTransparency = 0

				elseif viewMenu2_Input == "Supervisory" then
					viewMenu2_Input = "Panel"
					LCD.View.View2.Supervisory.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View2.Supervisory.BackgroundTransparency = 1

					LCD.View.View2.Panel.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View2.Panel.BackgroundTransparency = 0




				end

			elseif LCD.View.View1.Visible == true then
				if viewMenu_Input == "Outputs" then
					viewMenu_Input = "Alarms"

					LCD.View.View1.Outputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Outputs.BackgroundTransparency = 1

					LCD.View.View1.Alarms.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Alarms.BackgroundTransparency = 0

				elseif viewMenu_Input == "Inputs" then
					viewMenu_Input = "Faults"

					LCD.View.View1.Inputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Inputs.BackgroundTransparency = 1

					LCD.View.View1.Faults.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Faults.BackgroundTransparency = 0

				elseif viewMenu_Input == "NextMenu" then
					viewMenu_Input = "Inputs"

					LCD.View.View1.NextMenu.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.NextMenu.BackgroundTransparency = 1

					LCD.View.View1.Inputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Inputs.BackgroundTransparency = 0




				elseif viewMenu_Input == "Disabled" then
					viewMenu_Input = "Fires"

					LCD.View.View1.Disabled.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Disabled.BackgroundTransparency = 1

					LCD.View.View1.Fires.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Fires.BackgroundTransparency = 0



				end

			elseif LCD.Level2Menu.Visible == true then
				if Level2MenuInput == "Test" then
					Level2MenuInput = "View"

					LCD.Level2Menu.Test.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Test.BackgroundTransparency = 1

					LCD.Level2Menu.View.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.View.BackgroundTransparency = 0
				elseif Level2MenuInput == "Status" then
					Level2MenuInput = "Delay"
					LCD.Level2Menu.Status.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Status.BackgroundTransparency = 1

					LCD.Level2Menu.Delay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Delay.BackgroundTransparency = 0

				elseif Level2MenuInput == "Delay" then
					Level2MenuInput = "Disable"
					LCD.Level2Menu.Delay.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Delay.BackgroundTransparency = 1

					LCD.Level2Menu.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Disable.BackgroundTransparency = 0
				elseif Level2MenuInput == "Tools" then
					Level2MenuInput = "Enable"
					LCD.Level2Menu.Tools.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Tools.BackgroundTransparency = 1

					LCD.Level2Menu.Enable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Enable.BackgroundTransparency = 0
				end



				--

			elseif LCD.TestSelection.Sounders.Visible == true then
				if testSelect_SoundersInput == "With" then
					testSelect_SoundersInput = "Without"

					LCD.TestSelection.Sounders.WithSounders.TextColor3 = Color3.new(0, 0, 0)
					LCD.TestSelection.Sounders.WithSounders.BackgroundTransparency = 1

					LCD.TestSelection.Sounders.WithoutSounders.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.TestSelection.Sounders.WithoutSounders.BackgroundTransparency = 0
				end

			elseif LCD.TestMenu.Visible == true then
				if Test_Input == "Outputs" then

					Test_Input = "Zones"

					LCD.TestMenu.Outputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.TestMenu.Outputs.BackgroundTransparency = 1

					LCD.TestMenu.Zones.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.TestMenu.Zones.BackgroundTransparency = 0


				end

			elseif LCD.TestSelection.InTest.Visible == true then
				if testSelect_InTest == "KeepIn" then

					testSelect_InTest = "Finish"

					LCD.TestSelection.InTest.KeepIn.TextColor3 = Color3.new(0, 0, 0)
					LCD.TestSelection.InTest.KeepIn.BackgroundTransparency = 1

					LCD.TestSelection.InTest.Finished.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.TestSelection.InTest.Finished.BackgroundTransparency = 0
				end

			elseif LCD.OutputDisablement.Scroll1.Visible == true and LCD.OutputDisablement.Visible == true then
				if OutputDisablement_Input == "AllOtherRelay" then
					OutputDisablement_Input = "AllBeacons"

					LCD.OutputDisablement.Scroll1.AllOtherRelay.TextColor3 = Color3.new(0, 0, 0)
					LCD.OutputDisablement.Scroll1.AllOtherRelay.BackgroundTransparency = 1

					LCD.OutputDisablement.Scroll1.AllBeacons.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.OutputDisablement.Scroll1.AllBeacons.BackgroundTransparency = 0

				elseif OutputDisablement_Input == "AllBeacons" then
					OutputDisablement_Input = "AllSounders"

					LCD.OutputDisablement.Scroll1.AllBeacons.TextColor3 = Color3.new(0, 0, 0)
					LCD.OutputDisablement.Scroll1.AllBeacons.BackgroundTransparency = 1

					LCD.OutputDisablement.Scroll1.AllSounders.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.OutputDisablement.Scroll1.AllSounders.BackgroundTransparency = 0

				elseif OutputDisablement_Input == "AllSounders" then
					OutputDisablement_Input = "AllOutputs"

					LCD.OutputDisablement.Scroll1.AllSounders.TextColor3 = Color3.new(0, 0, 0)
					LCD.OutputDisablement.Scroll1.AllSounders.BackgroundTransparency = 1

					LCD.OutputDisablement.Scroll1.AllOutputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.OutputDisablement.Scroll1.AllOutputs.BackgroundTransparency = 0
				end

			elseif LCD.OutputDisablement.Scroll2.Visible == true and LCD.OutputDisablement.Visible == true then

				if OutputDisablement2_Input == "OnlySelected" then

					OutputDisablement2_Input = "FireRouting"

					LCD.OutputDisablement.Scroll2.OnlySelected.TextColor3 = Color3.new(0, 0, 0)
					LCD.OutputDisablement.Scroll2.OnlySelected.BackgroundTransparency = 1

					LCD.OutputDisablement.Scroll2.FireRoutingOutputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.OutputDisablement.Scroll2.FireRoutingOutputs.BackgroundTransparency = 0

				elseif OutputDisablement2_Input == "FireRouting" then

					OutputDisablement2_Input = "FaultRouting"

					LCD.OutputDisablement.Scroll2.FireRoutingOutputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.OutputDisablement.Scroll2.FireRoutingOutputs.BackgroundTransparency = 1

					LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.BackgroundTransparency = 0

				elseif OutputDisablement2_Input == "FaultRouting" then

					OutputDisablement2_Input = "FireProtection"

					LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.BackgroundTransparency = 1

					LCD.OutputDisablement.Scroll2.FireProtectionOutputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.OutputDisablement.Scroll2.FireProtectionOutputs.BackgroundTransparency = 0

				elseif OutputDisablement2_Input == "FireProtection" then

					LCD.OutputDisablement.Scroll1.Visible = true
					LCD.OutputDisablement.Scroll2.Visible = false

				end

			elseif LCD.ZoneInput.Function.Visible == true then
				if ZoneFunction_Input == "ManualDevices" then
					ZoneFunction_Input = "AutomaticDetectors"

					LCD.ZoneInput.Function.OnlyManualDevices.TextColor3 = Color3.new(0, 0, 0)
					LCD.ZoneInput.Function.OnlyManualDevices.BackgroundTransparency = 1

					LCD.ZoneInput.Function.OnlyAutomaticDetectors.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.ZoneInput.Function.OnlyAutomaticDetectors.BackgroundTransparency = 0

				elseif ZoneFunction_Input == "AutomaticDetectors" then
					ZoneFunction_Input = "SelectedInputs"

					LCD.ZoneInput.Function.OnlyAutomaticDetectors.TextColor3 = Color3.new(0, 0, 0)
					LCD.ZoneInput.Function.OnlyAutomaticDetectors.BackgroundTransparency = 1

					LCD.ZoneInput.Function.SelectedInputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.ZoneInput.Function.SelectedInputs.BackgroundTransparency = 0

				elseif ZoneFunction_Input == "SelectedInputs" then
					ZoneFunction_Input = "AllInputs"

					LCD.ZoneInput.Function.SelectedInputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.ZoneInput.Function.SelectedInputs.BackgroundTransparency = 1

					LCD.ZoneInput.Function.AllInputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.ZoneInput.Function.AllInputs.BackgroundTransparency = 0

				end

			elseif LCD.DisablementMenu.Visible == true then
				if DisablementMenu_Input == "Controls" then
					DisablementMenu_Input = "ZoneInputs"

					LCD.DisablementMenu.Controls.TextColor3 = Color3.new(0, 0, 0)
					LCD.DisablementMenu.Controls.BackgroundTransparency = 1

					LCD.DisablementMenu.ZonesInputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.DisablementMenu.ZonesInputs.BackgroundTransparency = 0
				elseif DisablementMenu_Input == "UserID" then
					DisablementMenu_Input = "Outputs"

					LCD.DisablementMenu.UserID.TextColor3 = Color3.new(0, 0, 0)
					LCD.DisablementMenu.UserID.BackgroundTransparency = 1

					LCD.DisablementMenu.Outputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.DisablementMenu.Outputs.BackgroundTransparency = 0

				end



			elseif LCD.ZoneInput.List.Visible == true then
				if LCD.ZoneInput.Function.Visible == false then

					shiftFramesUp_ZONES()

				end



			end

		end
	else
		if LCD.Menu.Visible == true then



			if MenuInput == "LEDTest" then
				MenuInput = "Enable_Controls"
				LCD.Menu.LEDTest.TextColor3 = Color3.new(0, 0, 0)
				LCD.Menu.LEDTest.BackgroundTransparency = 1

				LCD.Menu.EnableControls.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Menu.EnableControls.BackgroundTransparency = 0
			elseif MenuInput == "Status" then
				MenuInput = "View"
				LCD.Menu.Status.TextColor3 = Color3.new(0, 0, 0)
				LCD.Menu.Status.BackgroundTransparency = 1

				LCD.Menu.View.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Menu.View.BackgroundTransparency = 0
			end

			--

		elseif LCD.SpecificOutputDevices.Visible == true then
			shiftFramesUp_OUTPUTZONES_CERTAIN()

		elseif LCD.OutputDevices.Visible == true then
			shiftFramesUp_OUTPUTZONES()

		elseif LCD.MoreAlarms_Zone.Visible == true then
			shiftFramesUp_MOREALARMSZONES()

		elseif LCD.TestMenu.LCDTest.Visible == true then
			LCD.TestMenu.LCDTest.ButtonInput.Text = "?"

		elseif LCD.LoopInfo.Visible == true then
			if LoopInfoInput == "History" then
				LoopInfoInput = "View"
				LCD.LoopInfo.History.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.History.BackgroundTransparency = 1
				LCD.LoopInfo.ViewEdit.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.ViewEdit.BackgroundTransparency = 0

			elseif LoopInfoInput == "SelfTest" then
				LoopInfoInput = "Meter"
				LCD.LoopInfo.SelfTest.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.SelfTest.BackgroundTransparency = 1
				LCD.LoopInfo.Meter.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.Meter.BackgroundTransparency = 0

			elseif LoopInfoInput == "Meter" then
				LoopInfoInput = "AutoLearn"
				LCD.LoopInfo.Meter.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.Meter.BackgroundTransparency = 1
				LCD.LoopInfo.AutoLearn.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.AutoLearn.BackgroundTransparency = 0


			elseif LoopInfoInput == "Scope" then
				LoopInfoInput = "Calibrate"
				LCD.LoopInfo.Scope.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.Scope.BackgroundTransparency = 1
				LCD.LoopInfo.Calibrate.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.Calibrate.BackgroundTransparency = 0


			end

		elseif LCD.MoreAlarms.Visible == true then
			shiftFramesUp_MOREALARMS()

		elseif LCD.ZoneInput_Test.Visible == true then
			shiftFramesUp_ZONESTEST()

			---


		elseif LCD.LoopDevices.Visible == true then

			for a, framea in ipairs(frames_LOOPS) do
				if a == currentFrameIndex_LOOPS then
					previousZone = framea.Zone.Text
				end
			end

			for i, frame in ipairs(frames_LOOPS) do
				if i == currentFrameIndex_LOOPS then
					frame.Zone.Text = convert000Format(previousZone) 
				end
			end

			newZoneInput = ""
			shiftFramesUp_LOOPS()

		elseif LCD.LoopSelect.Visible == true then
			if LCD.LoopSelect.AmountOfLoops.Value == "2" then

				if LoopSelectInput == "L4" then
					LoopSelectInput = "L1"
					LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 0



				end

			elseif LCD.LoopSelect.AmountOfLoops.Value == "4" then


				if LoopSelectInput == "L4" then
					LoopSelectInput = "L1"
					LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 0



				end

			elseif LCD.LoopSelect.AmountOfLoops.Value == "8" then

				if LoopSelectInput == "L7" then
					LoopSelectInput = "L4"
					LCD.LoopSelect.LoopSelect.Loop7.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop7.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 0
				elseif LoopSelectInput == "L4" then
					LoopSelectInput = "L1"
					LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 0

				elseif LoopSelectInput == "L8" then
					LoopSelectInput = "L5"
					LCD.LoopSelect.LoopSelect.Loop8.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop8.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 0
				elseif LoopSelectInput == "L5" then
					LoopSelectInput = "L2"
					LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0

				elseif LoopSelectInput == "L6" then
					LoopSelectInput = "L3"
					LCD.LoopSelect.LoopSelect.Loop6.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop6.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 0

				end

			end


			---


		elseif LCD.Delay.Visible == true then
			if DelayInput == "Extended" then
				DelayInput = "Automatic"
				LCD.Delay.Function.Extended.TextColor3 = Color3.new(0, 0, 0)
				LCD.Delay.Function.Extended.BackgroundTransparency = 1

				LCD.Delay.Function.Automatic.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Delay.Function.Automatic.BackgroundTransparency = 0
			elseif DelayInput == "Automatic" then
				DelayInput = "OnceOnly"
				LCD.Delay.Function.Automatic.TextColor3 = Color3.new(0, 0, 0)
				LCD.Delay.Function.Automatic.BackgroundTransparency = 1

				LCD.Delay.Function.OnceOnly.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Delay.Function.OnceOnly.BackgroundTransparency = 0
			elseif DelayInput == "OnceOnly" then
				DelayInput = "NoInvestigation"
				LCD.Delay.Function.OnceOnly.TextColor3 = Color3.new(0, 0, 0)
				LCD.Delay.Function.OnceOnly.BackgroundTransparency = 1

				LCD.Delay.Function.NoInvestigationDelay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Delay.Function.NoInvestigationDelay.BackgroundTransparency = 0
			end


		elseif LCD.Commission.Menu1.Visible == true then

			if Commission_Input1 == "Enable" then
				Commission_Input1 = "Exit"
				LCD.Commission.Menu1.Enable.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Enable.BackgroundTransparency = 1

				LCD.Commission.Menu1.Exit.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Exit.BackgroundTransparency = 0

			elseif Commission_Input1 == "Disable" then
				Commission_Input1 = "Zones"
				LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Disable.BackgroundTransparency = 1

				LCD.Commission.Menu1.Zones.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Zones.BackgroundTransparency = 0

			elseif Commission_Input1 == "NextMenu" then
				Commission_Input1 = "Disable"
				LCD.Commission.Menu1.NextMenu.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.NextMenu.BackgroundTransparency = 1

				LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Disable.BackgroundTransparency = 0

			elseif Commission_Input1 == "View" then
				Commission_Input1 = "Loops"
				LCD.Commission.Menu1.View.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.View.BackgroundTransparency = 1

				LCD.Commission.Menu1.Loops.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Loops.BackgroundTransparency = 0

			end

		elseif LCD.Commission.Menu2.Visible == true then

			if Commission_Input2 == "EN" then
				Commission_Input2 = "Passwords"
				LCD.Commission.Menu2.EN.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.EN.BackgroundTransparency = 1

				LCD.Commission.Menu2.Passwords.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.Passwords.BackgroundTransparency = 0
			elseif Commission_Input2 == "Setup" then
				Commission_Input2 = "TimeDate"
				LCD.Commission.Menu2.Setup.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.Setup.BackgroundTransparency = 1

				LCD.Commission.Menu2.TimeDate.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.TimeDate.BackgroundTransparency = 0
			elseif Commission_Input2 == "Display" then
				Commission_Input2 = "PCConfig"
				LCD.Commission.Menu2.Display.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.Display.BackgroundTransparency = 1

				LCD.Commission.Menu2.PCConfig.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.PCConfig.BackgroundTransparency = 0


			end

		elseif LCD.View.View2.Visible == true and LCD.View.Visible == true then
			if viewMenu2_Input == "Log" then
				viewMenu2_Input = "Network"

				LCD.View.View2.Log.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View2.Log.BackgroundTransparency = 1

				LCD.View.View2.Network.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View2.Network.BackgroundTransparency = 0

			elseif viewMenu2_Input == "Supervisory" then
				viewMenu2_Input = "Panel"
				LCD.View.View2.Supervisory.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View2.Supervisory.BackgroundTransparency = 1

				LCD.View.View2.Panel.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View2.Panel.BackgroundTransparency = 0




			end

		elseif LCD.View.View1.Visible == true then
			if viewMenu_Input == "Outputs" then
				viewMenu_Input = "Alarms"

				LCD.View.View1.Outputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Outputs.BackgroundTransparency = 1

				LCD.View.View1.Alarms.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Alarms.BackgroundTransparency = 0

			elseif viewMenu_Input == "Inputs" then
				viewMenu_Input = "Faults"

				LCD.View.View1.Inputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Inputs.BackgroundTransparency = 1

				LCD.View.View1.Faults.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Faults.BackgroundTransparency = 0

			elseif viewMenu_Input == "NextMenu" then
				viewMenu_Input = "Inputs"

				LCD.View.View1.NextMenu.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.NextMenu.BackgroundTransparency = 1

				LCD.View.View1.Inputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Inputs.BackgroundTransparency = 0

			elseif viewMenu_Input == "Disabled" then
				viewMenu_Input = "Fires"

				LCD.View.View1.Disabled.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Disabled.BackgroundTransparency = 1

				LCD.View.View1.Fires.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Fires.BackgroundTransparency = 0



			end

		elseif LCD.Level2Menu.Visible == true then
			if Level2MenuInput == "Test" then
				Level2MenuInput = "View"

				LCD.Level2Menu.Test.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Test.BackgroundTransparency = 1

				LCD.Level2Menu.View.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.View.BackgroundTransparency = 0
			elseif Level2MenuInput == "Status" then
				Level2MenuInput = "Delay"
				LCD.Level2Menu.Status.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Status.BackgroundTransparency = 1

				LCD.Level2Menu.Delay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Delay.BackgroundTransparency = 0

			elseif Level2MenuInput == "Delay" then
				Level2MenuInput = "Disable"
				LCD.Level2Menu.Delay.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Delay.BackgroundTransparency = 1

				LCD.Level2Menu.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Disable.BackgroundTransparency = 0
			elseif Level2MenuInput == "Tools" then
				Level2MenuInput = "Enable"
				LCD.Level2Menu.Tools.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Tools.BackgroundTransparency = 1

				LCD.Level2Menu.Enable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Enable.BackgroundTransparency = 0
			end

			--



		elseif LCD.TestSelection.Sounders.Visible == true then
			if testSelect_SoundersInput == "With" then
				testSelect_SoundersInput = "Without"

				LCD.TestSelection.Sounders.WithSounders.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestSelection.Sounders.WithSounders.BackgroundTransparency = 1

				LCD.TestSelection.Sounders.WithoutSounders.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestSelection.Sounders.WithoutSounders.BackgroundTransparency = 0
			end

		elseif LCD.TestMenu.Visible == true then
			if Test_Input == "Outputs" then

				Test_Input = "Zones"

				LCD.TestMenu.Outputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestMenu.Outputs.BackgroundTransparency = 1

				LCD.TestMenu.Zones.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestMenu.Zones.BackgroundTransparency = 0


			end

		elseif LCD.TestSelection.InTest.Visible == true then
			if testSelect_InTest == "KeepIn" then

				testSelect_InTest = "Finish"

				LCD.TestSelection.InTest.KeepIn.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestSelection.InTest.KeepIn.BackgroundTransparency = 1

				LCD.TestSelection.InTest.Finished.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestSelection.InTest.Finished.BackgroundTransparency = 0
			end

		elseif LCD.OutputDisablement.Scroll1.Visible == true and LCD.OutputDisablement.Visible == true then
			if OutputDisablement_Input == "AllOtherRelay" then
				OutputDisablement_Input = "AllBeacons"

				LCD.OutputDisablement.Scroll1.AllOtherRelay.TextColor3 = Color3.new(0, 0, 0)
				LCD.OutputDisablement.Scroll1.AllOtherRelay.BackgroundTransparency = 1

				LCD.OutputDisablement.Scroll1.AllBeacons.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.OutputDisablement.Scroll1.AllBeacons.BackgroundTransparency = 0

			elseif OutputDisablement_Input == "AllBeacons" then
				OutputDisablement_Input = "AllSounders"

				LCD.OutputDisablement.Scroll1.AllBeacons.TextColor3 = Color3.new(0, 0, 0)
				LCD.OutputDisablement.Scroll1.AllBeacons.BackgroundTransparency = 1

				LCD.OutputDisablement.Scroll1.AllSounders.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.OutputDisablement.Scroll1.AllSounders.BackgroundTransparency = 0

			elseif OutputDisablement_Input == "AllSounders" then
				OutputDisablement_Input = "AllOutputs"

				LCD.OutputDisablement.Scroll1.AllSounders.TextColor3 = Color3.new(0, 0, 0)
				LCD.OutputDisablement.Scroll1.AllSounders.BackgroundTransparency = 1

				LCD.OutputDisablement.Scroll1.AllOutputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.OutputDisablement.Scroll1.AllOutputs.BackgroundTransparency = 0
			end

		elseif LCD.OutputDisablement.Scroll2.Visible == true and LCD.OutputDisablement.Visible == true then

			if OutputDisablement2_Input == "OnlySelected" then

				OutputDisablement2_Input = "FireRouting"

				LCD.OutputDisablement.Scroll2.OnlySelected.TextColor3 = Color3.new(0, 0, 0)
				LCD.OutputDisablement.Scroll2.OnlySelected.BackgroundTransparency = 1

				LCD.OutputDisablement.Scroll2.FireRoutingOutputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.OutputDisablement.Scroll2.FireRoutingOutputs.BackgroundTransparency = 0

			elseif OutputDisablement2_Input == "FireRouting" then

				OutputDisablement2_Input = "FaultRouting"

				LCD.OutputDisablement.Scroll2.FireRoutingOutputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.OutputDisablement.Scroll2.FireRoutingOutputs.BackgroundTransparency = 1

				LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.BackgroundTransparency = 0

			elseif OutputDisablement2_Input == "FaultRouting" then

				OutputDisablement2_Input = "FireProtection"

				LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.OutputDisablement.Scroll2.FaultRoutingOutputs.BackgroundTransparency = 1

				LCD.OutputDisablement.Scroll2.FireProtectionOutputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.OutputDisablement.Scroll2.FireProtectionOutputs.BackgroundTransparency = 0

			elseif OutputDisablement2_Input == "FireProtection" then

				LCD.OutputDisablement.Scroll1.Visible = true
				LCD.OutputDisablement.Scroll2.Visible = false

			end

		elseif LCD.ZoneInput.Function.Visible == true then
			if ZoneFunction_Input == "ManualDevices" then
				ZoneFunction_Input = "AutomaticDetectors"

				LCD.ZoneInput.Function.OnlyManualDevices.TextColor3 = Color3.new(0, 0, 0)
				LCD.ZoneInput.Function.OnlyManualDevices.BackgroundTransparency = 1

				LCD.ZoneInput.Function.OnlyAutomaticDetectors.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.ZoneInput.Function.OnlyAutomaticDetectors.BackgroundTransparency = 0

			elseif ZoneFunction_Input == "AutomaticDetectors" then
				ZoneFunction_Input = "SelectedInputs"

				LCD.ZoneInput.Function.OnlyAutomaticDetectors.TextColor3 = Color3.new(0, 0, 0)
				LCD.ZoneInput.Function.OnlyAutomaticDetectors.BackgroundTransparency = 1

				LCD.ZoneInput.Function.SelectedInputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.ZoneInput.Function.SelectedInputs.BackgroundTransparency = 0

			elseif ZoneFunction_Input == "SelectedInputs" then
				ZoneFunction_Input = "AllInputs"

				LCD.ZoneInput.Function.SelectedInputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.ZoneInput.Function.SelectedInputs.BackgroundTransparency = 1

				LCD.ZoneInput.Function.AllInputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.ZoneInput.Function.AllInputs.BackgroundTransparency = 0

			end

		elseif LCD.DisablementMenu.Visible == true then
			if DisablementMenu_Input == "Controls" then
				DisablementMenu_Input = "ZoneInputs"

				LCD.DisablementMenu.Controls.TextColor3 = Color3.new(0, 0, 0)
				LCD.DisablementMenu.Controls.BackgroundTransparency = 1

				LCD.DisablementMenu.ZonesInputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.DisablementMenu.ZonesInputs.BackgroundTransparency = 0
			elseif DisablementMenu_Input == "UserID" then
				DisablementMenu_Input = "Outputs"

				LCD.DisablementMenu.UserID.TextColor3 = Color3.new(0, 0, 0)
				LCD.DisablementMenu.UserID.BackgroundTransparency = 1

				LCD.DisablementMenu.Outputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.DisablementMenu.Outputs.BackgroundTransparency = 0

			end



		elseif LCD.ZoneInput.List.Visible == true then
			if LCD.ZoneInput.Function.Visible == false then

				shiftFramesUp_ZONES()

			end



		end

	end
end)


Buttons.RightArrow.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Menu.Visible == true then

				if MenuInput == "Enable_Controls" then
					MenuInput = "View"
					LCD.Menu.EnableControls.TextColor3 = Color3.new(0, 0, 0)
					LCD.Menu.EnableControls.BackgroundTransparency = 1

					LCD.Menu.View.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Menu.View.BackgroundTransparency = 0
				elseif MenuInput == "LEDTest" then
					MenuInput = "Status"
					LCD.Menu.LEDTest.TextColor3 = Color3.new(0, 0, 0)
					LCD.Menu.LEDTest.BackgroundTransparency = 1

					LCD.Menu.Status.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Menu.Status.BackgroundTransparency = 0
				end

			elseif LCD.AlarmCondition.Visible == true then
				LCD.AlarmCondition.Visible = false
				LCD.MoreAlarms.Visible = true

			elseif LCD.MoreAlarms_Zone.Visible == true then
				LCD.MoreAlarms_Zone.Visible = false
				LCD.MoreAlarms.Visible = true

			elseif LCD.MoreAlarms.Visible == true then
				LCD.MoreAlarms.Visible = false
				LCD.MoreAlarms_Zone.Visible = true

				for a, frame in ipairs(frames_MOREALARM) do
					if a == currentFrameIndex_MOREALARMS then
						local zoneValueObject = frame:FindFirstChild("ZONE")
						if zoneValueObject and zoneValueObject:IsA("StringValue") then
							local Val = zoneValueObject.Value
							print(Val)
							addZoneToList_MoreAlarms_Zone(Val)
						else
							warn("ZONE value object not found or invalid in frame: " .. frame.Name)
						end
					end
				end

			elseif LCD.OutputDevices.Visible == true then
				LCD.OutputDevices.Visible = false
				LCD.SpecificOutputDevices.Visible = true

				for a, frame in ipairs(frames_OUTPUTZONES) do
					if a == currentFrameIndex_OUTPUTZONES then
						local zoneValueObject = frame:FindFirstChild("ZONE")
						if zoneValueObject and zoneValueObject:IsA("StringValue") then
							local Val = zoneValueObject.Value
							print(Val)
							addZoneToListOUTPUT_CERTAIN(Val)
						else
							warn("ZONE value object not found or invalid in frame: " .. frame.Name)
						end
					end
				end

			elseif LCD.FaultView.Visible == true then
				LCD.FaultView.Visible = false
				LCD.FaultView_Zone.Visible = true

				for a, frame in ipairs(frames_FAULTSVIEW) do
					if a == currentFrameIndex_FAULTSVIEW then
						-- Find the "ZONE" StringValue object in the current frame
						local zoneValueObject = frame:FindFirstChild("ZONE")
						if zoneValueObject and zoneValueObject:IsA("StringValue") then
							local Val = zoneValueObject.Value
							print("Detected ZONE value:", Val)
							addZoneToList_FaultView_ZONE(Val)
						else
							-- Log a warning if the ZONE object is missing or of the wrong type
							if not zoneValueObject then
								warn("ZONE value object not found in frame: " .. frame.Name)
							elseif not zoneValueObject:IsA("StringValue") then
								warn("ZONE object in frame: " .. frame.Name .. " is not a StringValue.")
							end
						end
					end
				end

			elseif LCD.TestMenu.LCDTest.Visible == true then
				LCD.TestMenu.LCDTest.ButtonInput.Text = "?"

			elseif LCD.Home.Info.Fault.Visible == true and LCD.Home.Visible == true and LoggedIn then

				LCD.Home.Visible = false
				LCD.FaultView.Visible = true

			elseif LCD.Fault.Visible == true and LoggedIn then
				LCD.Fault.Visible = false
				LCD.FaultView.Visible = true



			elseif LCD.Level2Menu.Visible == true then

				if Level2MenuInput == "View" then
					Level2MenuInput = "Disable"
					LCD.Level2Menu.View.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.View.BackgroundTransparency = 1

					LCD.Level2Menu.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Disable.BackgroundTransparency = 0
				elseif Level2MenuInput == "Disable" then
					Level2MenuInput = "Enable"
					LCD.Level2Menu.Disable.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Disable.BackgroundTransparency = 1

					LCD.Level2Menu.Enable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Enable.BackgroundTransparency = 0
				elseif Level2MenuInput == "Test" then
					Level2MenuInput = "Delay"
					LCD.Level2Menu.Test.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Test.BackgroundTransparency = 1

					LCD.Level2Menu.Delay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Delay.BackgroundTransparency = 0
				elseif Level2MenuInput == "Delay" then
					Level2MenuInput = "Tools"
					LCD.Level2Menu.Delay.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Delay.BackgroundTransparency = 1

					LCD.Level2Menu.Tools.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Tools.BackgroundTransparency = 0
				end

			elseif LCD.Delay.Visible == true then
				if DelayInput == "NoDelay" then
					DelayInput = "Delay"
					LCD.Delay.NoDelay.BackgroundTransparency = 1
					LCD.Delay.NoDelay.TextColor3 = Color3.new(0, 0, 0)
					LCD.Delay.Delay.BackgroundTransparency = 0
					LCD.Delay.Delay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				end


			elseif LCD.LoopInfo.Visible == true then
				if LoopInfoInput == "View" then
					LoopInfoInput = "AutoLearn"
					LCD.LoopInfo.ViewEdit.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.ViewEdit.BackgroundTransparency = 1
					LCD.LoopInfo.AutoLearn.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.AutoLearn.BackgroundTransparency = 0

				elseif LoopInfoInput == "AutoLearn" then
					LoopInfoInput = "Calibrate"
					LCD.LoopInfo.AutoLearn.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.AutoLearn.BackgroundTransparency = 1
					LCD.LoopInfo.Calibrate.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.Calibrate.BackgroundTransparency = 0

				elseif LoopInfoInput == "History" then
					LoopInfoInput = "Meter"
					LCD.LoopInfo.History.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.History.BackgroundTransparency = 1
					LCD.LoopInfo.Meter.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.Meter.BackgroundTransparency = 0


				elseif LoopInfoInput == "Meter" then
					LoopInfoInput = "Scope"
					LCD.LoopInfo.Meter.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.Meter.BackgroundTransparency = 1
					LCD.LoopInfo.Scope.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.Scope.BackgroundTransparency = 0


				end


			elseif LCD.DisablementMenu.Visible == true then
				if DisablementMenu_Input == "ZoneInputs" then
					DisablementMenu_Input = "Outputs"

					LCD.DisablementMenu.ZonesInputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.DisablementMenu.ZonesInputs.BackgroundTransparency = 1

					LCD.DisablementMenu.Outputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.DisablementMenu.Outputs.BackgroundTransparency = 0
				elseif DisablementMenu_Input == "Outputs" then
					DisablementMenu_Input = "Groups"

					LCD.DisablementMenu.Outputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.DisablementMenu.Outputs.BackgroundTransparency = 1

					LCD.DisablementMenu.Groups.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.DisablementMenu.Groups.BackgroundTransparency = 0
				elseif DisablementMenu_Input == "Controls" then
					DisablementMenu_Input = "UserID"

					LCD.DisablementMenu.Controls.TextColor3 = Color3.new(0, 0, 0)
					LCD.DisablementMenu.Controls.BackgroundTransparency = 1

					LCD.DisablementMenu.UserID.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.DisablementMenu.UserID.BackgroundTransparency = 0
				end

			elseif LCD.View.View2.Visible == true and LCD.View.Visible == true then
				if viewMenu2_Input == "Panel" then
					viewMenu2_Input = "Network"

					LCD.View.View2.Panel.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View2.Panel.BackgroundTransparency = 1

					LCD.View.View2.Network.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View2.Network.BackgroundTransparency = 0

				elseif viewMenu2_Input == "Network" then
					viewMenu2_Input = "Warnings"
					LCD.View.View2.Network.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View2.Network.BackgroundTransparency = 1

					LCD.View.View2.Warnings.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View2.Warnings.BackgroundTransparency = 0

				elseif viewMenu2_Input == "Supervisory" then
					viewMenu2_Input = "Log"

					LCD.View.View2.Supervisory.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View2.Supervisory.BackgroundTransparency = 1

					LCD.View.View2.Log.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View2.Log.BackgroundTransparency = 0


				end

			elseif LCD.View.View1.Visible == true and LCD.View.Visible == true then
				if viewMenu_Input == "Fires" then
					viewMenu_Input = "Faults"

					LCD.View.View1.Fires.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Fires.BackgroundTransparency = 1

					LCD.View.View1.Faults.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Faults.BackgroundTransparency = 0

				elseif viewMenu_Input == "Faults" then
					viewMenu_Input = "Alarms"

					LCD.View.View1.Faults.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Faults.BackgroundTransparency = 1

					LCD.View.View1.Alarms.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Alarms.BackgroundTransparency = 0

				elseif viewMenu_Input == "Disabled" then
					viewMenu_Input = "Inputs"

					LCD.View.View1.Disabled.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Disabled.BackgroundTransparency = 1

					LCD.View.View1.Inputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Inputs.BackgroundTransparency = 0

				elseif viewMenu_Input == "Inputs" then
					viewMenu_Input = "Outputs"

					LCD.View.View1.Inputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Inputs.BackgroundTransparency = 1

					LCD.View.View1.Outputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Outputs.BackgroundTransparency = 0

				end

				---


			elseif LCD.LoopSelect.Visible == true then
				if LCD.LoopSelect.AmountOfLoops.Value == "2" then

					if LoopSelectInput == "L1" then
						LoopSelectInput = "L2"
						LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0
					elseif LoopSelectInput == "L2" then
						LoopSelectInput = "L3"
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 0



					end

				elseif LCD.LoopSelect.AmountOfLoops.Value == "4" then

					if LoopSelectInput == "L1" then
						LoopSelectInput = "L2"
						LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0
					elseif LoopSelectInput == "L2" then
						LoopSelectInput = "L3"
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 0



					end

				elseif LCD.LoopSelect.AmountOfLoops.Value == "8" then

					if LoopSelectInput == "L1" then
						LoopSelectInput = "L2"
						LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0
					elseif LoopSelectInput == "L2" then
						LoopSelectInput = "L3"
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 0

					elseif LoopSelectInput == "L4" then
						LoopSelectInput = "L5"
						LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 0
					elseif LoopSelectInput == "L5" then
						LoopSelectInput = "L6"
						LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop6.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop6.BackgroundTransparency = 0

					elseif LoopSelectInput == "L7" then
						LoopSelectInput = "L8"
						LCD.LoopSelect.LoopSelect.Loop7.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop7.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop8.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop8.BackgroundTransparency = 0

					end

				end


				---

			elseif LCD.Tools.Visible == true and LCD.TestMenu.LCDTest.Visible == false then
				if tools_Input == "Commission" then
					tools_Input = "Print"

					LCD.Tools.Commission.TextColor3 = Color3.new(0, 0, 0)
					LCD.Tools.Commission.BackgroundTransparency = 1

					LCD.Tools.Print.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Tools.Print.BackgroundTransparency = 0

				elseif tools_Input == "Print" then
					tools_Input = "ChangeTime"

					LCD.Tools.Print.TextColor3 = Color3.new(0, 0, 0)
					LCD.Tools.Print.BackgroundTransparency = 1

					LCD.Tools.ChangeTime.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Tools.ChangeTime.BackgroundTransparency = 0

				end



			elseif LCD.Commission.Menu1.Visible == true then

				if Commission_Input1 == "Loops" then
					Commission_Input1 = "Zones"
					LCD.Commission.Menu1.Loops.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Loops.BackgroundTransparency = 1

					LCD.Commission.Menu1.Zones.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Zones.BackgroundTransparency = 0

				elseif Commission_Input1 == "Zones" then
					Commission_Input1 = "Exit"
					LCD.Commission.Menu1.Zones.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Zones.BackgroundTransparency = 1

					LCD.Commission.Menu1.Exit.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Exit.BackgroundTransparency = 0

				elseif Commission_Input1 == "View" then
					Commission_Input1 = "Disable"
					LCD.Commission.Menu1.View.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.View.BackgroundTransparency = 1

					LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Disable.BackgroundTransparency = 0

				elseif Commission_Input1 == "Disable" then
					Commission_Input1 = "Enable"
					LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Disable.BackgroundTransparency = 1

					LCD.Commission.Menu1.Enable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Enable.BackgroundTransparency = 0

				end

			elseif LCD.Commission.Menu2.Visible == true then

				if Commission_Input2 == "Passwords" then
					Commission_Input2 = "TimeDate"
					LCD.Commission.Menu2.Passwords.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.Passwords.BackgroundTransparency = 1

					LCD.Commission.Menu2.TimeDate.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.TimeDate.BackgroundTransparency = 0
				elseif Commission_Input2 == "TimeDate" then
					Commission_Input2 = "PCConfig"
					LCD.Commission.Menu2.TimeDate.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.TimeDate.BackgroundTransparency = 1

					LCD.Commission.Menu2.PCConfig.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.PCConfig.BackgroundTransparency = 0
				elseif Commission_Input2 == "EN" then
					Commission_Input2 = "Setup"
					LCD.Commission.Menu2.EN.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.EN.BackgroundTransparency = 1

					LCD.Commission.Menu2.Setup.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.Setup.BackgroundTransparency = 0

				elseif Commission_Input2 == "Setup" then
					Commission_Input2 = "Display"
					LCD.Commission.Menu2.Setup.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.Setup.BackgroundTransparency = 1

					LCD.Commission.Menu2.Display.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.Display.BackgroundTransparency = 0
				end




			end

		elseif LCD.TestMenu.Visible == true then
			if Test_Input == "Zones" then
				Test_Input = "Display"

				LCD.TestMenu.Zones.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestMenu.Zones.BackgroundTransparency = 1

				LCD.TestMenu.Display.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestMenu.Display.BackgroundTransparency = 0

			elseif Test_Input == "Display" then
				Test_Input = "Buzzer"

				LCD.TestMenu.Display.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestMenu.Display.BackgroundTransparency = 1

				LCD.TestMenu.Buzzer.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestMenu.Buzzer.BackgroundTransparency = 0
			elseif Test_Input == "Buzzer" then
				Test_Input = "Printer"

				LCD.TestMenu.Buzzer.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestMenu.Buzzer.BackgroundTransparency = 1

				LCD.TestMenu.Printer.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestMenu.Printer.BackgroundTransparency = 0
			end


		end
	else
		if LCD.Menu.Visible == true then

			if MenuInput == "Enable_Controls" then
				MenuInput = "View"
				LCD.Menu.EnableControls.TextColor3 = Color3.new(0, 0, 0)
				LCD.Menu.EnableControls.BackgroundTransparency = 1

				LCD.Menu.View.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Menu.View.BackgroundTransparency = 0
			elseif MenuInput == "LEDTest" then
				MenuInput = "Status"
				LCD.Menu.LEDTest.TextColor3 = Color3.new(0, 0, 0)
				LCD.Menu.LEDTest.BackgroundTransparency = 1

				LCD.Menu.Status.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Menu.Status.BackgroundTransparency = 0
			end

		elseif LCD.TestMenu.LCDTest.Visible == true then
			LCD.TestMenu.LCDTest.ButtonInput.Text = "?"

		elseif LCD.Home.Info.Fault.Visible == true and LCD.Home.Visible == true and LoggedIn then

			LCD.Home.Visible = false
			LCD.FaultView.Visible = true

		elseif LCD.Fault.Visible == true and LoggedIn then
			LCD.Fault.Visible = false
			LCD.FaultView.Visible = true

		elseif LCD.MoreAlarms.Visible == true then
			LCD.MoreAlarms.Visible = false
			LCD.MoreAlarms_Zone.Visible = true

			for a, frame in ipairs(frames_MOREALARM) do
				if a == currentFrameIndex_MOREALARMS then
					local zoneValueObject = frame:FindFirstChild("ZONE")
					if zoneValueObject and zoneValueObject:IsA("StringValue") then
						local Val = zoneValueObject.Value
						print(Val)
						addZoneToList_MoreAlarms_Zone(Val)
					else
						warn("ZONE value object not found or invalid in frame: " .. frame.Name)
					end
				end
			end

		elseif LCD.OutputDevices.Visible == true then
			LCD.OutputDevices.Visible = false
			LCD.SpecificOutputDevices.Visible = true

			for a, frame in ipairs(frames_OUTPUTZONES) do
				if a == currentFrameIndex_OUTPUTZONES then
					local zoneValueObject = frame:FindFirstChild("ZONE")
					if zoneValueObject and zoneValueObject:IsA("StringValue") then
						local Val = zoneValueObject.Value
						print(Val)
						addZoneToListOUTPUT_CERTAIN(Val)
					else
						warn("ZONE value object not found or invalid in frame: " .. frame.Name)
					end
				end
			end

		elseif LCD.FaultView.Visible == true then
			LCD.FaultView.Visible = false
			LCD.FaultView_Zone.Visible = true

			for a, frame in ipairs(frames_FAULTSVIEW) do
				if a == currentFrameIndex_FAULTSVIEW then
					-- Find the "ZONE" StringValue object in the current frame
					local zoneValueObject = frame:FindFirstChild("ZONE")
					if zoneValueObject and zoneValueObject:IsA("StringValue") then
						local Val = zoneValueObject.Value
						print("Detected ZONE value:", Val)
						addZoneToList_FaultView_ZONE(Val)
					else
						-- Log a warning if the ZONE object is missing or of the wrong type
						if not zoneValueObject then
							warn("ZONE value object not found in frame: " .. frame.Name)
						elseif not zoneValueObject:IsA("StringValue") then
							warn("ZONE object in frame: " .. frame.Name .. " is not a StringValue.")
						end
					end
				end
			end

		elseif LCD.DisablementMenu.Visible == true then
			if DisablementMenu_Input == "ZoneInputs" then
				DisablementMenu_Input = "Outputs"

				LCD.DisablementMenu.ZonesInputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.DisablementMenu.ZonesInputs.BackgroundTransparency = 1

				LCD.DisablementMenu.Outputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.DisablementMenu.Outputs.BackgroundTransparency = 0
			elseif DisablementMenu_Input == "Outputs" then
				DisablementMenu_Input = "Groups"

				LCD.DisablementMenu.Outputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.DisablementMenu.Outputs.BackgroundTransparency = 1

				LCD.DisablementMenu.Groups.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.DisablementMenu.Groups.BackgroundTransparency = 0
			elseif DisablementMenu_Input == "Controls" then
				DisablementMenu_Input = "UserID"

				LCD.DisablementMenu.Controls.TextColor3 = Color3.new(0, 0, 0)
				LCD.DisablementMenu.Controls.BackgroundTransparency = 1

				LCD.DisablementMenu.UserID.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.DisablementMenu.UserID.BackgroundTransparency = 0
			end

		elseif LCD.LoopInfo.Visible == true then
			if LoopInfoInput == "View" then
				LoopInfoInput = "AutoLearn"
				LCD.LoopInfo.ViewEdit.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.ViewEdit.BackgroundTransparency = 1
				LCD.LoopInfo.AutoLearn.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.AutoLearn.BackgroundTransparency = 0

			elseif LoopInfoInput == "AutoLearn" then
				LoopInfoInput = "Calibrate"
				LCD.LoopInfo.AutoLearn.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.AutoLearn.BackgroundTransparency = 1
				LCD.LoopInfo.Calibrate.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.Calibrate.BackgroundTransparency = 0

			elseif LoopInfoInput == "History" then
				LoopInfoInput = "Meter"
				LCD.LoopInfo.History.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.History.BackgroundTransparency = 1
				LCD.LoopInfo.Meter.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.Meter.BackgroundTransparency = 0


			elseif LoopInfoInput == "Meter" then
				LoopInfoInput = "Scope"
				LCD.LoopInfo.Meter.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.Meter.BackgroundTransparency = 1
				LCD.LoopInfo.Scope.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.Scope.BackgroundTransparency = 0


			end

		elseif LCD.View.View2.Visible == true and LCD.View.Visible == true then
			if viewMenu2_Input == "Panel" then
				viewMenu2_Input = "Network"

				LCD.View.View2.Panel.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View2.Panel.BackgroundTransparency = 1

				LCD.View.View2.Network.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View2.Network.BackgroundTransparency = 0

			elseif viewMenu2_Input == "Network" then
				viewMenu2_Input = "Warnings"
				LCD.View.View2.Network.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View2.Network.BackgroundTransparency = 1

				LCD.View.View2.Warnings.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View2.Warnings.BackgroundTransparency = 0

			elseif viewMenu2_Input == "Supervisory" then
				viewMenu2_Input = "Log"

				LCD.View.View2.Supervisory.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View2.Supervisory.BackgroundTransparency = 1

				LCD.View.View2.Log.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View2.Log.BackgroundTransparency = 0


			end

		elseif LCD.View.View1.Visible == true then
			if viewMenu_Input == "Fires" then
				viewMenu_Input = "Faults"

				LCD.View.View1.Fires.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Fires.BackgroundTransparency = 1

				LCD.View.View1.Faults.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Faults.BackgroundTransparency = 0

			elseif viewMenu_Input == "Faults" then
				viewMenu_Input = "Alarms"

				LCD.View.View1.Faults.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Faults.BackgroundTransparency = 1

				LCD.View.View1.Alarms.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Alarms.BackgroundTransparency = 0

			elseif viewMenu_Input == "Disabled" then
				viewMenu_Input = "Inputs"

				LCD.View.View1.Disabled.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Disabled.BackgroundTransparency = 1

				LCD.View.View1.Inputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Inputs.BackgroundTransparency = 0

			elseif viewMenu_Input == "Inputs" then
				viewMenu_Input = "Outputs"

				LCD.View.View1.Inputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Inputs.BackgroundTransparency = 1

				LCD.View.View1.Outputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Outputs.BackgroundTransparency = 0

			end

			---


		elseif LCD.LoopSelect.Visible == true then
			if LCD.LoopSelect.AmountOfLoops.Value == "2" then

				if LoopSelectInput == "L1" then
					LoopSelectInput = "L2"
					LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0
				elseif LoopSelectInput == "L2" then
					LoopSelectInput = "L3"
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 0



				end

			elseif LCD.LoopSelect.AmountOfLoops.Value == "4" then

				if LoopSelectInput == "L1" then
					LoopSelectInput = "L2"
					LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0
				elseif LoopSelectInput == "L2" then
					LoopSelectInput = "L3"
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 0



				end

			elseif LCD.LoopSelect.AmountOfLoops.Value == "8" then

				if LoopSelectInput == "L1" then
					LoopSelectInput = "L2"
					LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0
				elseif LoopSelectInput == "L2" then
					LoopSelectInput = "L3"
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 0

				elseif LoopSelectInput == "L4" then
					LoopSelectInput = "L5"
					LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 0
				elseif LoopSelectInput == "L5" then
					LoopSelectInput = "L6"
					LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop6.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop6.BackgroundTransparency = 0

				elseif LoopSelectInput == "L7" then
					LoopSelectInput = "L8"
					LCD.LoopSelect.LoopSelect.Loop7.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop7.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop8.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop8.BackgroundTransparency = 0

				end

			end


			---

		elseif LCD.Tools.Visible == true and LCD.TestMenu.LCDTest.Visible == false then
			if tools_Input == "Commission" then
				tools_Input = "Print"

				LCD.Tools.Commission.TextColor3 = Color3.new(0, 0, 0)
				LCD.Tools.Commission.BackgroundTransparency = 1

				LCD.Tools.Print.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Tools.Print.BackgroundTransparency = 0

			elseif tools_Input == "Print" then
				tools_Input = "ChangeTime"

				LCD.Tools.Print.TextColor3 = Color3.new(0, 0, 0)
				LCD.Tools.Print.BackgroundTransparency = 1

				LCD.Tools.ChangeTime.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Tools.ChangeTime.BackgroundTransparency = 0

			end

		elseif LCD.Level2Menu.Visible == true then

			if Level2MenuInput == "View" then
				Level2MenuInput = "Disable"
				LCD.Level2Menu.View.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.View.BackgroundTransparency = 1

				LCD.Level2Menu.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Disable.BackgroundTransparency = 0
			elseif Level2MenuInput == "Disable" then
				Level2MenuInput = "Enable"
				LCD.Level2Menu.Disable.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Disable.BackgroundTransparency = 1

				LCD.Level2Menu.Enable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Enable.BackgroundTransparency = 0
			elseif Level2MenuInput == "Test" then
				Level2MenuInput = "Delay"
				LCD.Level2Menu.Test.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Test.BackgroundTransparency = 1

				LCD.Level2Menu.Delay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Delay.BackgroundTransparency = 0
			elseif Level2MenuInput == "Delay" then
				Level2MenuInput = "Tools"
				LCD.Level2Menu.Delay.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Delay.BackgroundTransparency = 1

				LCD.Level2Menu.Tools.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Tools.BackgroundTransparency = 0
			end		

		elseif LCD.Commission.Menu1.Visible == true then

			if Commission_Input1 == "Loops" then
				Commission_Input1 = "Zones"
				LCD.Commission.Menu1.Loops.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Loops.BackgroundTransparency = 1

				LCD.Commission.Menu1.Zones.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Zones.BackgroundTransparency = 0

			elseif Commission_Input1 == "Zones" then
				Commission_Input1 = "Exit"
				LCD.Commission.Menu1.Zones.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Zones.BackgroundTransparency = 1

				LCD.Commission.Menu1.Exit.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Exit.BackgroundTransparency = 0

			elseif Commission_Input1 == "View" then
				Commission_Input1 = "Disable"
				LCD.Commission.Menu1.View.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.View.BackgroundTransparency = 1

				LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Disable.BackgroundTransparency = 0

			elseif Commission_Input1 == "Disable" then
				Commission_Input1 = "Enable"
				LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Disable.BackgroundTransparency = 1

				LCD.Commission.Menu1.Enable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Enable.BackgroundTransparency = 0

			end

		elseif LCD.Commission.Menu2.Visible == true then

			if Commission_Input2 == "Passwords" then
				Commission_Input2 = "TimeDate"
				LCD.Commission.Menu2.Passwords.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.Passwords.BackgroundTransparency = 1

				LCD.Commission.Menu2.TimeDate.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.TimeDate.BackgroundTransparency = 0
			elseif Commission_Input2 == "TimeDate" then
				Commission_Input2 = "PCConfig"
				LCD.Commission.Menu2.TimeDate.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.TimeDate.BackgroundTransparency = 1

				LCD.Commission.Menu2.PCConfig.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.PCConfig.BackgroundTransparency = 0
			elseif Commission_Input2 == "EN" then
				Commission_Input2 = "Setup"
				LCD.Commission.Menu2.EN.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.EN.BackgroundTransparency = 1

				LCD.Commission.Menu2.Setup.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.Setup.BackgroundTransparency = 0

			elseif Commission_Input2 == "Setup" then
				Commission_Input2 = "Display"
				LCD.Commission.Menu2.Setup.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.Setup.BackgroundTransparency = 1

				LCD.Commission.Menu2.Display.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.Display.BackgroundTransparency = 0
			end

		elseif LCD.Delay.Visible == true then
			if DelayInput == "NoDelay" then
				DelayInput = "Delay"
				LCD.Delay.NoDelay.BackgroundTransparency = 1
				LCD.Delay.NoDelay.TextColor3 = Color3.new(0, 0, 0)
				LCD.Delay.Delay.BackgroundTransparency = 0
				LCD.Delay.Delay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			end



		elseif LCD.TestMenu.Visible == true then
			if Test_Input == "Zones" then
				Test_Input = "Display"

				LCD.TestMenu.Zones.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestMenu.Zones.BackgroundTransparency = 1

				LCD.TestMenu.Display.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestMenu.Display.BackgroundTransparency = 0

			elseif Test_Input == "Display" then
				Test_Input = "Buzzer"

				LCD.TestMenu.Display.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestMenu.Display.BackgroundTransparency = 1

				LCD.TestMenu.Buzzer.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestMenu.Buzzer.BackgroundTransparency = 0
			elseif Test_Input == "Buzzer" then
				Test_Input = "Printer"

				LCD.TestMenu.Buzzer.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestMenu.Buzzer.BackgroundTransparency = 1

				LCD.TestMenu.Printer.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestMenu.Printer.BackgroundTransparency = 0
			end
		end
	end
end)



Buttons.LeftArrow.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then

			if LCD.Menu.Visible == true then

				if MenuInput == "View" then
					MenuInput = "Enable_Controls"
					LCD.Menu.View.TextColor3 = Color3.new(0, 0, 0)
					LCD.Menu.View.BackgroundTransparency = 1

					LCD.Menu.EnableControls.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Menu.EnableControls.BackgroundTransparency = 0
				elseif MenuInput == "Status" then
					MenuInput = "LEDTest"
					LCD.Menu.Status.TextColor3 = Color3.new(0, 0, 0)
					LCD.Menu.Status.BackgroundTransparency = 1

					LCD.Menu.LEDTest.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Menu.LEDTest.BackgroundTransparency = 0
				end

				-----

			elseif LCD.SpecificOutputDevices.Visible == true then
				LCD.SpecificOutputDevices.Visible = false
				LCD.OutputDevices.Visible = true

			elseif LCD.FaultView_Zone.Visible == true then
				LCD.FaultView_Zone.Visible = false
				LCD.FaultView.Visible = true

			elseif LCD.MoreAlarms_Zone.Visible == true then
				LCD.MoreAlarms_Zone.Visible = false
				LCD.MoreAlarms.Visible = true

			elseif LCD.TestMenu.LCDTest.Visible == true then
				LCD.TestMenu.LCDTest.ButtonInput.Text = "?"

			elseif LCD.LoopInfo.Visible == true then
				if LoopInfoInput == "Calibrate" then
					LoopInfoInput = "AutoLearn"
					LCD.LoopInfo.Calibrate.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.Calibrate.BackgroundTransparency = 1
					LCD.LoopInfo.AutoLearn.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.AutoLearn.BackgroundTransparency = 0

				elseif LoopInfoInput == "AutoLearn" then
					LoopInfoInput = "View"
					LCD.LoopInfo.AutoLearn.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.AutoLearn.BackgroundTransparency = 1
					LCD.LoopInfo.ViewEdit.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.ViewEdit.BackgroundTransparency = 0

				elseif LoopInfoInput == "Scope" then
					LoopInfoInput = "Meter"
					LCD.LoopInfo.Scope.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.Scope.BackgroundTransparency = 1
					LCD.LoopInfo.Meter.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.Meter.BackgroundTransparency = 0


				elseif LoopInfoInput == "Meter" then
					LoopInfoInput = "History"
					LCD.LoopInfo.Meter.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopInfo.Meter.BackgroundTransparency = 1
					LCD.LoopInfo.History.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopInfo.History.BackgroundTransparency = 0


				end

			elseif LCD.Commission.Menu1.Visible == true then

				if Commission_Input1 == "Exit" then
					Commission_Input1 = "Zones"
					LCD.Commission.Menu1.Exit.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Exit.BackgroundTransparency = 1

					LCD.Commission.Menu1.Zones.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Zones.BackgroundTransparency = 0

				elseif Commission_Input1 == "Zones" then
					Commission_Input1 = "Loops"
					LCD.Commission.Menu1.Zones.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Zones.BackgroundTransparency = 1

					LCD.Commission.Menu1.Loops.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Loops.BackgroundTransparency = 0

				elseif Commission_Input1 == "Enable" then
					Commission_Input1 = "Disable"
					LCD.Commission.Menu1.Enable.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Enable.BackgroundTransparency = 1

					LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.Disable.BackgroundTransparency = 0

				elseif Commission_Input1 == "Disable" then
					Commission_Input1 = "View"
					LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu1.Disable.BackgroundTransparency = 1

					LCD.Commission.Menu1.View.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu1.View.BackgroundTransparency = 0

				end

			elseif LCD.Commission.Menu2.Visible == true then

				if Commission_Input2 == "PCConfig" then
					Commission_Input2 = "TimeDate"
					LCD.Commission.Menu2.PCConfig.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.PCConfig.BackgroundTransparency = 1

					LCD.Commission.Menu2.TimeDate.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.TimeDate.BackgroundTransparency = 0
				elseif Commission_Input2 == "TimeDate" then
					Commission_Input2 = "Passwords"
					LCD.Commission.Menu2.TimeDate.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.TimeDate.BackgroundTransparency = 1

					LCD.Commission.Menu2.Passwords.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.Passwords.BackgroundTransparency = 0
				elseif Commission_Input2 == "Display" then
					Commission_Input2 = "Setup"
					LCD.Commission.Menu2.Display.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.Display.BackgroundTransparency = 1

					LCD.Commission.Menu2.Setup.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.Setup.BackgroundTransparency = 0

				elseif Commission_Input2 == "Setup" then
					Commission_Input2 = "EN"
					LCD.Commission.Menu2.Setup.TextColor3 = Color3.new(0, 0, 0)
					LCD.Commission.Menu2.Setup.BackgroundTransparency = 1

					LCD.Commission.Menu2.EN.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Commission.Menu2.EN.BackgroundTransparency = 0
				end

			elseif LCD.LoopSelect.Visible == true then
				if LCD.LoopSelect.AmountOfLoops.Value == "2" then

					if LoopSelectInput == "L3" then
						LoopSelectInput = "L2"
						LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0
					elseif LoopSelectInput == "L2" then
						LoopSelectInput = "L1"
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 0


					end

				elseif LCD.LoopSelect.AmountOfLoops.Value == "4" then

					if LoopSelectInput == "L3" then
						LoopSelectInput = "L2"
						LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0
					elseif LoopSelectInput == "L2" then
						LoopSelectInput = "L1"
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 0


					end

				elseif LCD.LoopSelect.AmountOfLoops.Value == "8" then

					if LoopSelectInput == "L3" then
						LoopSelectInput = "L2"
						LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0
					elseif LoopSelectInput == "L2" then
						LoopSelectInput = "L1"
						LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 0

					elseif LoopSelectInput == "L6" then
						LoopSelectInput = "L5"
						LCD.LoopSelect.LoopSelect.Loop6.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop6.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 0
					elseif LoopSelectInput == "L5" then
						LoopSelectInput = "L4"
						LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 0

					elseif LoopSelectInput == "L8" then
						LoopSelectInput = "L7"
						LCD.LoopSelect.LoopSelect.Loop8.TextColor3 = Color3.new(0, 0, 0)
						LCD.LoopSelect.LoopSelect.Loop8.BackgroundTransparency = 1
						LCD.LoopSelect.LoopSelect.Loop7.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
						LCD.LoopSelect.LoopSelect.Loop7.BackgroundTransparency = 0

					end

				end

				---

			elseif LCD.View.View2.Visible == true and LCD.View.Visible == true then
				if viewMenu2_Input == "Warnings" then
					viewMenu2_Input = "Network"

					LCD.View.View2.Warnings.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View2.Warnings.BackgroundTransparency = 1

					LCD.View.View2.Network.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View2.Network.BackgroundTransparency = 0

				elseif viewMenu2_Input == "Network" then
					viewMenu2_Input = "Panel"
					LCD.View.View2.Network.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View2.Network.BackgroundTransparency = 1

					LCD.View.View2.Panel.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View2.Panel.BackgroundTransparency = 0

				elseif viewMenu2_Input == "Log" then
					viewMenu2_Input = "Supervisory"

					LCD.View.View2.Log.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View2.Log.BackgroundTransparency = 1

					LCD.View.View2.Supervisory.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View2.Supervisory.BackgroundTransparency = 0


				end

			elseif LCD.View.View1.Visible == true then
				if viewMenu_Input == "Alarms" then
					viewMenu_Input = "Faults"

					LCD.View.View1.Alarms.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Alarms.BackgroundTransparency = 1

					LCD.View.View1.Faults.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Faults.BackgroundTransparency = 0

				elseif viewMenu_Input == "Faults" then
					viewMenu_Input = "Fires"

					LCD.View.View1.Faults.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Faults.BackgroundTransparency = 1

					LCD.View.View1.Fires.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Fires.BackgroundTransparency = 0

				elseif viewMenu_Input == "Outputs" then
					viewMenu_Input = "Inputs"

					LCD.View.View1.Outputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Outputs.BackgroundTransparency = 1

					LCD.View.View1.Inputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Inputs.BackgroundTransparency = 0

				elseif viewMenu_Input == "Inputs" then
					viewMenu_Input = "Disabled"

					LCD.View.View1.Inputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.View.View1.Inputs.BackgroundTransparency = 1

					LCD.View.View1.Disabled.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.View.View1.Disabled.BackgroundTransparency = 0

				end

			elseif LCD.Tools.Visible == true and LCD.TestMenu.LCDTest.Visible == false then
				if tools_Input == "ChangeTime" then
					tools_Input = "Print"

					LCD.Tools.ChangeTime.TextColor3 = Color3.new(0, 0, 0)
					LCD.Tools.ChangeTime.BackgroundTransparency = 1

					LCD.Tools.Print.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Tools.Print.BackgroundTransparency = 0

				elseif tools_Input == "Print" then
					tools_Input = "Commission"

					LCD.Tools.Print.TextColor3 = Color3.new(0, 0, 0)
					LCD.Tools.Print.BackgroundTransparency = 1

					LCD.Tools.Commission.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Tools.Commission.BackgroundTransparency = 0

				end

			elseif LCD.DisablementMenu.Visible == true then
				if DisablementMenu_Input == "Groups" then
					DisablementMenu_Input = "Outputs"

					LCD.DisablementMenu.Groups.TextColor3 = Color3.new(0, 0, 0)
					LCD.DisablementMenu.Groups.BackgroundTransparency = 1

					LCD.DisablementMenu.Outputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.DisablementMenu.Outputs.BackgroundTransparency = 0
				elseif DisablementMenu_Input == "Outputs" then
					DisablementMenu_Input = "ZoneInputs"

					LCD.DisablementMenu.Outputs.TextColor3 = Color3.new(0, 0, 0)
					LCD.DisablementMenu.Outputs.BackgroundTransparency = 1

					LCD.DisablementMenu.ZonesInputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.DisablementMenu.ZonesInputs.BackgroundTransparency = 0
				elseif DisablementMenu_Input == "UserID" then
					DisablementMenu_Input = "Controls"

					LCD.DisablementMenu.UserID.TextColor3 = Color3.new(0, 0, 0)
					LCD.DisablementMenu.UserID.BackgroundTransparency = 1

					LCD.DisablementMenu.Controls.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.DisablementMenu.Controls.BackgroundTransparency = 0
				end

			elseif LCD.Level2Menu.Visible == true then


				if Level2MenuInput == "Enable" then
					Level2MenuInput = "Disable"
					LCD.Level2Menu.Enable.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Enable.BackgroundTransparency = 1

					LCD.Level2Menu.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Disable.BackgroundTransparency = 0
				elseif Level2MenuInput == "Disable" then
					Level2MenuInput = "View"
					LCD.Level2Menu.Disable.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Disable.BackgroundTransparency = 1

					LCD.Level2Menu.View.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.View.BackgroundTransparency = 0

				elseif Level2MenuInput == "Tools" then
					Level2MenuInput = "Delay"
					LCD.Level2Menu.Tools.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Tools.BackgroundTransparency = 1

					LCD.Level2Menu.Delay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Delay.BackgroundTransparency = 0
				elseif Level2MenuInput == "Delay" then
					Level2MenuInput = "Test"
					LCD.Level2Menu.Delay.TextColor3 = Color3.new(0, 0, 0)
					LCD.Level2Menu.Delay.BackgroundTransparency = 1

					LCD.Level2Menu.Test.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.Level2Menu.Test.BackgroundTransparency = 0


				end



			elseif LCD.TestMenu.Visible == true then

				if Test_Input == "Printer" then
					Test_Input = "Buzzer"

					LCD.TestMenu.Printer.TextColor3 = Color3.new(0, 0, 0)
					LCD.TestMenu.Printer.BackgroundTransparency = 1

					LCD.TestMenu.Buzzer.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.TestMenu.Buzzer.BackgroundTransparency = 0
				elseif Test_Input == "Buzzer" then
					Test_Input = "Display"
					LCD.TestMenu.Buzzer.TextColor3 = Color3.new(0, 0, 0)
					LCD.TestMenu.Buzzer.BackgroundTransparency = 1

					LCD.TestMenu.Display.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.TestMenu.Display.BackgroundTransparency = 0
				elseif Test_Input == "Display" then
					Test_Input = "Zones"
					LCD.TestMenu.Display.TextColor3 = Color3.new(0, 0, 0)
					LCD.TestMenu.Display.BackgroundTransparency = 1

					LCD.TestMenu.Zones.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.TestMenu.Zones.BackgroundTransparency = 0
				end

			end




		end
	else
		if LCD.Menu.Visible == true then

			if MenuInput == "View" then
				MenuInput = "Enable_Controls"
				LCD.Menu.View.TextColor3 = Color3.new(0, 0, 0)
				LCD.Menu.View.BackgroundTransparency = 1

				LCD.Menu.EnableControls.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Menu.EnableControls.BackgroundTransparency = 0
			elseif MenuInput == "Status" then
				MenuInput = "LEDTest"
				LCD.Menu.Status.TextColor3 = Color3.new(0, 0, 0)
				LCD.Menu.Status.BackgroundTransparency = 1

				LCD.Menu.LEDTest.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Menu.LEDTest.BackgroundTransparency = 0
			end

			-----

		elseif LCD.SpecificOutputDevices.Visible == true then
			LCD.SpecificOutputDevices.Visible = false
			LCD.OutputDevices.Visible = true

		elseif LCD.FaultView_Zone.Visible == true then
			LCD.FaultView_Zone.Visible = false
			LCD.FaultView.Visible = true

		elseif LCD.TestMenu.LCDTest.Visible == true then
			LCD.TestMenu.LCDTest.ButtonInput.Text = "?"

		elseif LCD.LoopInfo.Visible == true then
			if LoopInfoInput == "Calibrate" then
				LoopInfoInput = "AutoLearn"
				LCD.LoopInfo.Calibrate.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.Calibrate.BackgroundTransparency = 1
				LCD.LoopInfo.AutoLearn.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.AutoLearn.BackgroundTransparency = 0

			elseif LoopInfoInput == "AutoLearn" then
				LoopInfoInput = "View"
				LCD.LoopInfo.AutoLearn.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.AutoLearn.BackgroundTransparency = 1
				LCD.LoopInfo.ViewEdit.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.ViewEdit.BackgroundTransparency = 0

			elseif LoopInfoInput == "Scope" then
				LoopInfoInput = "Meter"
				LCD.LoopInfo.Scope.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.Scope.BackgroundTransparency = 1
				LCD.LoopInfo.Meter.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.Meter.BackgroundTransparency = 0


			elseif LoopInfoInput == "Meter" then
				LoopInfoInput = "History"
				LCD.LoopInfo.Meter.TextColor3 = Color3.new(0, 0, 0)
				LCD.LoopInfo.Meter.BackgroundTransparency = 1
				LCD.LoopInfo.History.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.History.BackgroundTransparency = 0


			end

		elseif LCD.LoopSelect.Visible == true then
			if LCD.LoopSelect.AmountOfLoops.Value == "2" then

				if LoopSelectInput == "L3" then
					LoopSelectInput = "L2"
					LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0
				elseif LoopSelectInput == "L2" then
					LoopSelectInput = "L1"
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 0


				end

			elseif LCD.LoopSelect.AmountOfLoops.Value == "4" then

				if LoopSelectInput == "L3" then
					LoopSelectInput = "L2"
					LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0
				elseif LoopSelectInput == "L2" then
					LoopSelectInput = "L1"
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 0


				end

			elseif LCD.LoopSelect.AmountOfLoops.Value == "8" then

				if LoopSelectInput == "L3" then
					LoopSelectInput = "L2"
					LCD.LoopSelect.LoopSelect.Loop3.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop3.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 0
				elseif LoopSelectInput == "L2" then
					LoopSelectInput = "L1"
					LCD.LoopSelect.LoopSelect.Loop2.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop2.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop1.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop1.BackgroundTransparency = 0

				elseif LoopSelectInput == "L6" then
					LoopSelectInput = "L5"
					LCD.LoopSelect.LoopSelect.Loop6.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop6.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 0
				elseif LoopSelectInput == "L5" then
					LoopSelectInput = "L4"
					LCD.LoopSelect.LoopSelect.Loop5.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop5.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop4.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop4.BackgroundTransparency = 0

				elseif LoopSelectInput == "L8" then
					LoopSelectInput = "L7"
					LCD.LoopSelect.LoopSelect.Loop8.TextColor3 = Color3.new(0, 0, 0)
					LCD.LoopSelect.LoopSelect.Loop8.BackgroundTransparency = 1
					LCD.LoopSelect.LoopSelect.Loop7.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
					LCD.LoopSelect.LoopSelect.Loop7.BackgroundTransparency = 0

				end

			end

		elseif LCD.Commission.Menu1.Visible == true then

			if Commission_Input1 == "Exit" then
				Commission_Input1 = "Zones"
				LCD.Commission.Menu1.Exit.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Exit.BackgroundTransparency = 1

				LCD.Commission.Menu1.Zones.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Zones.BackgroundTransparency = 0

			elseif Commission_Input1 == "Zones" then
				Commission_Input1 = "Loops"
				LCD.Commission.Menu1.Zones.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Zones.BackgroundTransparency = 1

				LCD.Commission.Menu1.Loops.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Loops.BackgroundTransparency = 0

			elseif Commission_Input1 == "Enable" then
				Commission_Input1 = "Disable"
				LCD.Commission.Menu1.Enable.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Enable.BackgroundTransparency = 1

				LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.Disable.BackgroundTransparency = 0

			elseif Commission_Input1 == "Disable" then
				Commission_Input1 = "View"
				LCD.Commission.Menu1.Disable.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu1.Disable.BackgroundTransparency = 1

				LCD.Commission.Menu1.View.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu1.View.BackgroundTransparency = 0

			end

		elseif LCD.Commission.Menu2.Visible == true then

			if Commission_Input2 == "PCConfig" then
				Commission_Input2 = "TimeDate"
				LCD.Commission.Menu2.PCConfig.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.PCConfig.BackgroundTransparency = 1

				LCD.Commission.Menu2.TimeDate.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.TimeDate.BackgroundTransparency = 0
			elseif Commission_Input2 == "TimeDate" then
				Commission_Input2 = "Passwords"
				LCD.Commission.Menu2.TimeDate.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.TimeDate.BackgroundTransparency = 1

				LCD.Commission.Menu2.Passwords.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.Passwords.BackgroundTransparency = 0
			elseif Commission_Input2 == "Display" then
				Commission_Input2 = "Setup"
				LCD.Commission.Menu2.Display.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.Display.BackgroundTransparency = 1

				LCD.Commission.Menu2.Setup.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.Setup.BackgroundTransparency = 0

			elseif Commission_Input2 == "Setup" then
				Commission_Input2 = "EN"
				LCD.Commission.Menu2.Setup.TextColor3 = Color3.new(0, 0, 0)
				LCD.Commission.Menu2.Setup.BackgroundTransparency = 1

				LCD.Commission.Menu2.EN.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Commission.Menu2.EN.BackgroundTransparency = 0
			end

			---

		elseif LCD.View.View2.Visible == true and LCD.View.Visible == true then
			if viewMenu2_Input == "Warnings" then
				viewMenu2_Input = "Network"

				LCD.View.View2.Warnings.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View2.Warnings.BackgroundTransparency = 1

				LCD.View.View2.Network.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View2.Network.BackgroundTransparency = 0

			elseif viewMenu2_Input == "Network" then
				viewMenu2_Input = "Panel"
				LCD.View.View2.Network.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View2.Network.BackgroundTransparency = 1

				LCD.View.View2.Panel.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View2.Panel.BackgroundTransparency = 0

			elseif viewMenu2_Input == "Log" then
				viewMenu2_Input = "Supervisory"

				LCD.View.View2.Log.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View2.Log.BackgroundTransparency = 1

				LCD.View.View2.Supervisory.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View2.Supervisory.BackgroundTransparency = 0


			end

		elseif LCD.View.View1.Visible == true then
			if viewMenu_Input == "Alarms" then
				viewMenu_Input = "Faults"

				LCD.View.View1.Alarms.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Alarms.BackgroundTransparency = 1

				LCD.View.View1.Faults.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Faults.BackgroundTransparency = 0

			elseif viewMenu_Input == "Faults" then
				viewMenu_Input = "Fires"

				LCD.View.View1.Faults.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Faults.BackgroundTransparency = 1

				LCD.View.View1.Fires.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Fires.BackgroundTransparency = 0

			elseif viewMenu_Input == "Outputs" then
				viewMenu_Input = "Inputs"

				LCD.View.View1.Outputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Outputs.BackgroundTransparency = 1

				LCD.View.View1.Inputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Inputs.BackgroundTransparency = 0

			elseif viewMenu_Input == "Inputs" then
				viewMenu_Input = "Disabled"

				LCD.View.View1.Inputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.View.View1.Inputs.BackgroundTransparency = 1

				LCD.View.View1.Disabled.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.View.View1.Disabled.BackgroundTransparency = 0

			end

		elseif LCD.Tools.Visible == true and LCD.TestMenu.LCDTest.Visible == false then
			if tools_Input == "ChangeTime" then
				tools_Input = "Print"

				LCD.Tools.ChangeTime.TextColor3 = Color3.new(0, 0, 0)
				LCD.Tools.ChangeTime.BackgroundTransparency = 1

				LCD.Tools.Print.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Tools.Print.BackgroundTransparency = 0

			elseif tools_Input == "Print" then
				tools_Input = "Commission"

				LCD.Tools.Print.TextColor3 = Color3.new(0, 0, 0)
				LCD.Tools.Print.BackgroundTransparency = 1

				LCD.Tools.Commission.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Tools.Commission.BackgroundTransparency = 0

			end

		elseif LCD.DisablementMenu.Visible == true then
			if DisablementMenu_Input == "Groups" then
				DisablementMenu_Input = "Outputs"

				LCD.DisablementMenu.Groups.TextColor3 = Color3.new(0, 0, 0)
				LCD.DisablementMenu.Groups.BackgroundTransparency = 1

				LCD.DisablementMenu.Outputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.DisablementMenu.Outputs.BackgroundTransparency = 0
			elseif DisablementMenu_Input == "Outputs" then
				DisablementMenu_Input = "ZoneInputs"

				LCD.DisablementMenu.Outputs.TextColor3 = Color3.new(0, 0, 0)
				LCD.DisablementMenu.Outputs.BackgroundTransparency = 1

				LCD.DisablementMenu.ZonesInputs.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.DisablementMenu.ZonesInputs.BackgroundTransparency = 0
			elseif DisablementMenu_Input == "UserID" then
				DisablementMenu_Input = "Controls"

				LCD.DisablementMenu.UserID.TextColor3 = Color3.new(0, 0, 0)
				LCD.DisablementMenu.UserID.BackgroundTransparency = 1

				LCD.DisablementMenu.Controls.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.DisablementMenu.Controls.BackgroundTransparency = 0
			end

		elseif LCD.TestMenu.Visible == true then

			if Test_Input == "Printer" then
				Test_Input = "Buzzer"

				LCD.TestMenu.Printer.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestMenu.Printer.BackgroundTransparency = 1

				LCD.TestMenu.Buzzer.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestMenu.Buzzer.BackgroundTransparency = 0
			elseif Test_Input == "Buzzer" then
				Test_Input = "Display"
				LCD.TestMenu.Buzzer.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestMenu.Buzzer.BackgroundTransparency = 1

				LCD.TestMenu.Display.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestMenu.Display.BackgroundTransparency = 0
			elseif Test_Input == "Display" then
				Test_Input = "Zones"
				LCD.TestMenu.Display.TextColor3 = Color3.new(0, 0, 0)
				LCD.TestMenu.Display.BackgroundTransparency = 1

				LCD.TestMenu.Zones.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.TestMenu.Zones.BackgroundTransparency = 0
			end

		elseif LCD.Level2Menu.Visible == true then


			if Level2MenuInput == "Enable" then
				Level2MenuInput = "Disable"
				LCD.Level2Menu.Enable.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Enable.BackgroundTransparency = 1

				LCD.Level2Menu.Disable.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Disable.BackgroundTransparency = 0
			elseif Level2MenuInput == "Disable" then
				Level2MenuInput = "View"
				LCD.Level2Menu.Disable.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Disable.BackgroundTransparency = 1

				LCD.Level2Menu.View.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.View.BackgroundTransparency = 0

			elseif Level2MenuInput == "Tools" then
				Level2MenuInput = "Delay"
				LCD.Level2Menu.Tools.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Tools.BackgroundTransparency = 1

				LCD.Level2Menu.Delay.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Delay.BackgroundTransparency = 0
			elseif Level2MenuInput == "Delay" then
				Level2MenuInput = "Test"
				LCD.Level2Menu.Delay.TextColor3 = Color3.new(0, 0, 0)
				LCD.Level2Menu.Delay.BackgroundTransparency = 1

				LCD.Level2Menu.Test.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.Level2Menu.Test.BackgroundTransparency = 0


			end



		end


	end
end)

Buttons.LEDTest.ClickDetector.MouseClick:Connect(function(plr)
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then
			if InAlarm == false then
				Buzzer:Play()
				for i, v in ipairs(LEDs:GetDescendants()) do
					if v:IsA("BasePart") and v.Name:sub(1, 1) == "Z" then
						v.Color = Color3.new(1, 0, 0)
					end
				end

				for i, v in ipairs(LEDs:GetDescendants()) do
					if v:IsA("BasePart") and v.Name:sub(1, 1) == "F" then
						v.Color = Color3.new(1, 0.52549, 0.184314)
					end
				end

				for i, v in ipairs(LEDs:GetDescendants()) do
					if v:IsA("BasePart") and v.Name:sub(1, 1) == "S" then
						v.Color = Color3.new(1, 0.52549, 0.184314)
					end
				end

				for i, v in ipairs(LEDs:GetDescendants()) do
					if v:IsA("BasePart") and v.Name:sub(1, 1) == "T" then
						v.Color = Color3.new(1, 0.52549, 0.184314)
					end
				end

				for i, v in ipairs(LEDs:GetDescendants()) do
					if v:IsA("BasePart") and v.Name:sub(1, 1) == "D" then
						v.Color = Color3.new(1, 0.52549, 0.184314)
					end
				end

				LEDs.Fire.Color = Color3.new(1, 0, 0)
				LEDs.MoreAlarms.Color = Color3.new(1, 0, 0)
				LEDs.PreAlarm.Color = Color3.new(1, 0.52549, 0.184314)
				LEDs.FireRouting_Activated.Color = Color3.new(1, 0, 0)
				LEDs.FireProtection.Color = Color3.new(1, 0, 0)

				wait(5)
				Buzzer:Stop()
				for i, v in pairs(LEDs:GetChildren()) do
					if v:IsA("BasePart") then
						v.Color = Color3.new(0, 0, 0)

						if v.Name == "Power" then
							v.Color = Color3.new(0.411765, 0.886275, 0.0980392)
						elseif v.Name == "Delay" and Config.InvestigationDelay.Active == true then
							LEDs.Delay.Color = Color3.new(1, 0.52549, 0.184314)
						elseif v.Name == "FireRouting_Activated" then
							LEDs.FireRouting_Activated.Color = Color3.new(0, 0, 0)
						end

					end
				end

				if DisabledDevice_Amount > 0 then
					LEDs.Disablement.Color = Color3.new(1, 0.52549, 0.184314)
				end

				if SoundersDisableList > 0 then
					LEDs.SounderDisabled.Color = Color3.new(1, 0.52549, 0.184314)
				end

				if InFault then
					LEDs.Fault.Color = Color3.new(1, 0.52549, 0.184314)
				end

			end
		end
	else
		if InAlarm == false then
			Buzzer:Play()
			for i, v in ipairs(LEDs:GetDescendants()) do
				if v:IsA("BasePart") and v.Name:sub(1, 1) == "Z" then
					v.Color = Color3.new(1, 0, 0)
				end
			end

			for i, v in ipairs(LEDs:GetDescendants()) do
				if v:IsA("BasePart") and v.Name:sub(1, 1) == "F" then
					v.Color = Color3.new(1, 0.52549, 0.184314)
				end
			end

			for i, v in ipairs(LEDs:GetDescendants()) do
				if v:IsA("BasePart") and v.Name:sub(1, 1) == "S" then
					v.Color = Color3.new(1, 0.52549, 0.184314)
				end
			end

			for i, v in ipairs(LEDs:GetDescendants()) do
				if v:IsA("BasePart") and v.Name:sub(1, 1) == "T" then
					v.Color = Color3.new(1, 0.52549, 0.184314)
				end
			end

			for i, v in ipairs(LEDs:GetDescendants()) do
				if v:IsA("BasePart") and v.Name:sub(1, 1) == "D" then
					v.Color = Color3.new(1, 0.52549, 0.184314)
				end
			end

			LEDs.Fire.Color = Color3.new(1, 0, 0)
			LEDs.MoreAlarms.Color = Color3.new(1, 0, 0)
			LEDs.PreAlarm.Color = Color3.new(1, 0.52549, 0.184314)
			LEDs.FireRouting_Activated.Color = Color3.new(1, 0, 0)
			LEDs.FireProtection.Color = Color3.new(1, 0, 0)

			wait(5)
			Buzzer:Stop()
			for i, v in pairs(LEDs:GetChildren()) do
				if v:IsA("BasePart") then
					v.Color = Color3.new(0, 0, 0)

					if v.Name == "Power" then
						v.Color = Color3.new(0.411765, 0.886275, 0.0980392)
					elseif v.Name == "Delay" and Config.InvestigationDelay.Active == true then
						LEDs.Delay.Color = Color3.new(1, 0.52549, 0.184314)
					elseif v.Name == "FireRouting_Activated" then
						LEDs.FireRouting_Activated.Color = Color3.new(0, 0, 0)
					end

				end
			end


			if DisabledDevice_Amount > 0 then
				LEDs.Disablement.Color = Color3.new(1, 0.52549, 0.184314)
			end

			if SoundersDisableList > 0 then
				LEDs.SounderDisabled.Color = Color3.new(1, 0.52549, 0.184314)
			end


		end
	end
end)

Buttons.Esc.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()
	if Whitelist == true then
		if plr:GetRankInGroup(GID) >= GR then



			if LCD.Level2Menu.Visible == true then
				LCD.Level2Menu.Visible = false
				LCD.Menu.Visible = true

				if LoggedIn == true then
					LCD.Menu.EnableControls.Text = "DISABLE-CONTROLS"
					LCD.Menu.ControlHeader.Text = "[ CONTROLS ENABLED  ]"
				else
					LCD.Menu.EnableControls.Text = "ENABLE-CONTROLS"
					LCD.Menu.ControlHeader.Text = "[ CONTROLS DISABLED  ]"
				end

			elseif LCD.OutputDevices.Visible == true then
				LCD.OutputDevices.Visible = false
				LCD.DisablementMenu.Visible = true

			elseif LCD.TestMenu.LCDTest.Visible == true then
				LCD.TestMenu.LCDTest.Visible = false

			elseif LCD.MoreAlarms_Zone.Visible == true then
				LCD.MoreAlarms_Zone.Visible = false
				LCD.MoreAlarms.Visible = true

			elseif LCD.AlarmCondition.Visible == true then

				if LoggedIn then
					LCD.AlarmCondition.Visible = false
					LCD.Level2Menu.Visible = true
				else
					LCD.AlarmCondition.Visible = false
					LCD.Menu.Visible = true
				end

			elseif LCD.MoreAlarms.Visible == true then
				LCD.MoreAlarms.Visible = false

				if InAlarm then
					LCD.Alarm.Visible = true
				else
					LCD.Level2Menu.Visible = true
				end

			elseif LCD.AutoLearn.Visible == true then
				LCD.AutoLearn.Visible = false
				LCD.LoopInfo.Visible = true

			elseif LCD.LoopDevices.Visible == true then
				LCD.LoopDevices.Visible = false
				LCD.LoopInfo.Visible = true

			elseif LCD.LoopInfo.Visible == true then
				LCD.LoopSelect.Visible = true
				LCD.LoopInfo.Visible = false

				LoopInfoInput = "View"

				for i, v in pairs(LCD.LoopInfo:GetChildren()) do
					if v:IsA("TextLabel") then
						v.TextColor3 = Color3.new(0, 0, 0)
						v.BackgroundTransparency = 1
					end
				end

				LCD.LoopInfo.ViewEdit.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
				LCD.LoopInfo.ViewEdit.BackgroundTransparency = 0

			elseif LCD.LoopSelect.Visible == true then
				LCD.LoopSelect.Visible = false
				LCD.Commission.Visible = true
				LCD.Commission.Menu1.Visible = true

			elseif LCD.ZoneInput_Test.Visible == true then
				LCD.ZoneInput_Test.Visible = false
				LCD.TestSelection.Visible = true
				LCD.TestSelection.InTest.Visible = true
				LCD.TestSelection.Sounders.Visible = false

			elseif LCD.Password.Visible == true then
				LCD.Password.Visible = false

				if not InAlarm then
					LCD.Menu.Visible = true
				elseif InAlarm and not InEvac then
					LCD.AlarmCondition.Visible = true
				elseif InTrouble and not InEvac then
					LCD.AlarmCondition.Visible = true
				elseif InEvac then
					LCD.Alarm.Visible = true
				end

			elseif LCD.OutputDisablement.Visible == true then
				LCD.OutputDisablement.Visible = false



			elseif LCD.DisablementMenu.Visible == true then
				LCD.DisablementMenu.Visible = false
				LCD.Level2Menu.Visible = true
				LCD.Menu.Visible = false


			elseif LCD.Commission.Menu2.Visible == true then
				LCD.Commission.Menu1.Visible = true
				LCD.Commission.Menu2.Visible = false
			elseif LCD.Commission.Menu1.Visible == true then
				LCD.Commission.Menu1.Visible = false
				LCD.Commission.Menu2.Visible = false
				LCD.Commission.Visible = false
				LCD.Tools.Visible = true
			elseif LCD.Tools.Visible == true and LCD.TestMenu.LCDTest.Visible == false then
				LCD.Tools.Visible = false
				LCD.Level2Menu.Visible = true

			elseif LCD.ZoneInput.Function.Visible == true then
				LCD.ZoneInput.Function.Visible = false

			elseif LCD.ZoneInput.List.Visible == true and LCD.ZoneInput.Visible == true then

				if LCD.ZoneInput.Function.Visible == false then
					LCD.ZoneInput.Visible = false
					LCD.DisablementMenu.Visible = true
				end


			elseif LCD.View.Visible == true and LCD.View.View2.Visible == true then
				LCD.View.View2.Visible = false
				LCD.View.View1.Visible = true

			elseif LCD.View.Visible == true and LCD.View.View1.Visible == true then
				if LoggedIn == true then

					LCD.Level2Menu.Visible = true
					LCD.View.Visible = false
					LCD.View.View2.Visible = false
					LCD.View.View1.Visible = false
					LCD.Level2Menu.Visible = true
				else

					LCD.Menu.Visible = true
					LCD.View.Visible = false
					LCD.View.View2.Visible = false
					LCD.View.View1.Visible = false

				end

			elseif LCD.TestMenu.Visible == true then



				LCD.TestMenu.Visible = false
				LCD.TestSelection.Visible = true
				LCD.TestSelection.Sounders.Visible = false

				LCD.TestSelection.InTest.Visible = true



			elseif LCD.TestSelection.Visible == true then
				LCD.TestSelection.Visible = false
				LCD.TestSelection.Sounders.Visible = false

				LCD.TestSelection.InTest.Visible = false
				LCD.TestMenu.Visible = true
				testSelect_InTest = "Finished"
				testSelect_SoundersInput = "Without"

			elseif LCD.Delay.Visible == true then
				LCD.Delay.Visible = false
				LCD.Level2Menu.Visible = true
			elseif LCD.Password.Visible == true then
				LCD.Password.Visible = false
				LCD.Home.Visible = true
				L2_Input = ""
				LCD.Password.Frame.Frame.Password.Text = ""
			end


		end
	else



		if LCD.Level2Menu.Visible == true then
			LCD.Level2Menu.Visible = false
			LCD.Menu.Visible = true

			if LoggedIn == true then
				LCD.Menu.EnableControls.Text = "DISABLE-CONTROLS"
				LCD.Menu.ControlHeader.Text = "[ CONTROLS ENABLED  ]"
			else
				LCD.Menu.EnableControls.Text = "ENABLE-CONTROLS"
				LCD.Menu.ControlHeader.Text = "[ CONTROLS DISABLED  ]"
			end

		elseif LCD.OutputDevices.Visible == true then
			LCD.OutputDevices.Visible = false
			LCD.DisablementMenu.Visible = true

		elseif LCD.TestMenu.LCDTest.Visible == true then
			LCD.TestMenu.LCDTest.Visible = false

		elseif LCD.MoreAlarms_Zone.Visible == true then
			LCD.MoreAlarms_Zone.Visible = false
			LCD.MoreAlarms.Visible = true

		elseif LCD.LoopDevices.Visible == true then
			LCD.LoopDevices.Visible = false
			LCD.LoopInfo.Visible = true

		elseif LCD.ZoneInput_Test.Visible == true then
			LCD.ZoneInput_Test.Visible = false
			LCD.TestSelection.Visible = true
			LCD.TestSelection.InTest.Visible = true
			LCD.TestSelection.Sounders.Visible = false

		elseif LCD.Password.Visible == true then
			LCD.Password.Visible = false

			if not InAlarm then
				LCD.Menu.Visible = true
			elseif InAlarm and not InEvac then
				LCD.AlarmCondition.Visible = true
			elseif InTrouble and not InEvac then
				LCD.AlarmCondition.Visible = true
			elseif InEvac then
				LCD.Alarm.Visible = true
			end

		elseif LCD.MoreAlarms.Visible == true then
			LCD.MoreAlarms.Visible = false

			if InAlarm then
				LCD.Alarm.Visible = true
			else
				LCD.Level2Menu.Visible = true
			end

		elseif LCD.AutoLearn.Visible == true then
			LCD.AutoLearn.Visible = false
			LCD.LoopInfo.Visible = true

		elseif LCD.LoopInfo.Visible == true then
			LCD.LoopSelect.Visible = true
			LCD.LoopInfo.Visible = false

			LoopInfoInput = "View"

			for i, v in pairs(LCD.LoopInfo:GetChildren()) do
				if v:IsA("TextLabel") then
					v.TextColor3 = Color3.new(0, 0, 0)
					v.BackgroundTransparency = 1
				end
			end

			LCD.LoopInfo.ViewEdit.TextColor3 = Color3.new(0.627451, 0.701961, 0.976471)
			LCD.LoopInfo.ViewEdit.BackgroundTransparency = 0

		elseif LCD.LoopSelect.Visible == true then
			LCD.LoopSelect.Visible = false
			LCD.Commission.Visible = true

		elseif LCD.OutputDisablement.Visible == true then
			LCD.OutputDisablement.Visible = false

		elseif LCD.DisablementMenu.Visible == true then
			LCD.DisablementMenu.Visible = false
			LCD.Level2Menu.Visible = true
			LCD.Menu.Visible = false

		elseif LCD.Commission.Menu2.Visible == true then
			LCD.Commission.Menu1.Visible = true
			LCD.Commission.Menu2.Visible = false
		elseif LCD.Commission.Menu1.Visible == true then
			LCD.Commission.Menu1.Visible = false
			LCD.Commission.Menu2.Visible = false
			LCD.Commission.Visible = false
			LCD.Tools.Visible = true
		elseif LCD.Tools.Visible == true and LCD.TestMenu.LCDTest.Visible == false then
			LCD.Tools.Visible = false
			LCD.Level2Menu.Visible = true

		elseif LCD.ZoneInput.Function.Visible == true then
			LCD.ZoneInput.Function.Visible = false

		elseif LCD.ZoneInput.List.Visible == true and LCD.ZoneInput.Visible == true then

			if LCD.ZoneInput.Function.Visible == false then
				LCD.ZoneInput.Visible = false
				LCD.DisablementMenu.Visible = true
			end


		elseif LCD.View.Visible == true and LCD.View.View2.Visible == true then
			LCD.View.View2.Visible = false
			LCD.View.View1.Visible = true

		elseif LCD.View.Visible == true and LCD.View.View1.Visible == true then
			if LoggedIn == true then

				LCD.Level2Menu.Visible = true
				LCD.View.Visible = false
				LCD.View.View2.Visible = false
				LCD.View.View1.Visible = false
				LCD.Level2Menu.Visible = true
			else

				LCD.Menu.Visible = true
				LCD.View.Visible = false
				LCD.View.View2.Visible = false
				LCD.View.View1.Visible = false

			end

		elseif LCD.TestMenu.Visible == true then



			LCD.TestMenu.Visible = false
			LCD.TestSelection.Visible = true
			LCD.TestSelection.Sounders.Visible = false

			LCD.TestSelection.InTest.Visible = true



		elseif LCD.TestSelection.Visible == true then
			LCD.TestSelection.Visible = false
			LCD.TestSelection.Sounders.Visible = false

			LCD.TestSelection.InTest.Visible = false
			LCD.TestMenu.Visible = true
			testSelect_InTest = "Finished"
			testSelect_SoundersInput = "Without"

		elseif LCD.Delay.Visible == true then
			LCD.Delay.Visible = false
			LCD.Level2Menu.Visible = true
		elseif LCD.Password.Visible == true then
			LCD.Password.Visible = false
			LCD.Home.Visible = true
			L2_Input = ""
			LCD.Password.Frame.Frame.Password.Text = ""
		end



	end
end)

Buttons.Resound.ClickDetector.MouseClick:Connect(function(plr)
	Press:Play()

	if LoggedIn == true then

		if Whitelist == true then
			if plr:GetRankInGroup(GID) >= GR then

				if InAlarm == true and InTrouble == false then
					NetAPI:Fire("Evacuate", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))

				elseif InAlarm == true and InTrouble == true then

					NetAPI:Fire("Trouble", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))

				end

			end
		else
			if InAlarm == true and InTrouble == false then
				NetAPI:Fire("Evacuate", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))
			elseif InAlarm == true and InTrouble == true then

				NetAPI:Fire("Trouble", DeviceName, DeviceID, DeviceZone, "Panel", script.Parent:GetAttribute("DeviceLocation"))

			end
		end

	elseif LoggedIn == false then

		MakeFramesVisible(false)

		FunctionToComplete = "Resound"

		LCD.Password.Visible = true


	end

end)

--[[
Buttons.Silence.ClickDetector.MouseClick:Connect(function(plr)
	if Whitelist == true then
	if plr:GetRankInGroup(GID) >= GR then
		
	end
	else
		
	end
end)
]]



-- KEEP AT BOTTOM!!!!!!

-- FLASH EVAC


-- Format Time

--[[local function getFormattedDate()

	local currentDate = os.date("*t")


	local months = {
		"JAN", "FEB", "MAR", "APR", "MAY", "JUN",
		"JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
	}


	local day = string.format("%02d", currentDate.day)
	local month = months[currentDate.month]            
	local year = currentDate.year                     


	return day .. " " .. month .. " " .. year
end

local function formatTime(hour, minute)
	return string.format("%02d:%02d", hour, minute)
end

local function getBritishTime()
	local currentTime = os.time()
	local utcOffset = Config.TimeOffset
	local localTime = currentTime + utcOffset * 3600


	local hour = tonumber(os.date("!%H", localTime))
	local minute = tonumber(os.date("!%M", localTime))

	-- Print formatted time

	LCD.Home.Time.Text = formatTime(hour, minute) .. "<br />" .. getFormattedDate()

end ]]

function FlashGreen_Power()
	if script.Flash_Power.Value == true then
		while script.Flash_Power.Value do
			LEDs.Power.Color = Color3.new(0.411765, 0.886275, 0.0980392)
			wait(1)
			LEDs.Power.Color = Color3.new(0, 0, 0)
			wait(1)
		end
	end
end

function FlashOrange_Fault()
	if script.Flash_Fault.Value == true then
		while script.Flash_Fault.Value do
			LEDs.Fault.Color = Color3.new(1, 0.52549, 0.184314)
			wait(1)
			LEDs.Fault.Color = Color3.new(0, 0, 0)
			wait(1)
		end
	end
end

function FlashRed_Fire()
	while script.Flash.Value do
		LEDs.Fire.Color = Color3.new(1, 0, 0)
		wait(1)
		LEDs.Fire.Color = Color3.new(0, 0, 0)
		wait(1)
	end
end

