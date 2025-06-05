local surfaceGui = script.Parent
local questionLabel = surfaceGui:WaitForChild("QuestionLabel")
local statsGui = workspace:WaitForChild("StatsBoard"):WaitForChild("SurfaceGui")
local statsLabel = statsGui:WaitForChild("StatsLabel")

local function appendStats(text)
	statsLabel.Text = statsLabel.Text .. text .. "\n"
end

local buttons = {
	surfaceGui:WaitForChild("Option1"),
	surfaceGui:WaitForChild("Option2"),
	surfaceGui:WaitForChild("Option3"),
	surfaceGui:WaitForChild("Option4"),
	surfaceGui:WaitForChild("Option5")
}

local buttonConns = {}
local userInput = {x = {}, y = {}}
local inputIndex = 1
local currentCoord = "x"
local numPoints = 0
local inputStage = 0
local inputMode = "manual"

local graphFolder = Instance.new("Folder")
graphFolder.Name = "Graphs"
graphFolder.Parent = surfaceGui


local function drawFunction(func, color)
	local width = surfaceGui.AbsoluteSize.X
	local height = surfaceGui.AbsoluteSize.Y

	if width == 0 or height == 0 then
		surfaceGui:GetPropertyChangedSignal("AbsoluteSize"):Wait()
		width = surfaceGui.AbsoluteSize.X
		height = surfaceGui.AbsoluteSize.Y
	end

	local xMin, xMax = math.huge, -math.huge
	local yMin, yMax = math.huge, -math.huge
	for i = 1, #userInput.x do
		local x, y = userInput.x[i], userInput.y[i]
		if x < xMin then xMin = x end
		if x > xMax then xMax = x end
		if y < yMin then yMin = y end
		if y > yMax then yMax = y end
	end

	local xPadding = (xMax - xMin) * 0.1
	local yPadding = (yMax - yMin) * 0.1
	xMin -= xPadding
	xMax += xPadding
	yMin -= yPadding
	yMax += yPadding

	if xMax - xMin == 0 then xMax += 1 end
	if yMax - yMin == 0 then yMax += 1 end

	local size = 10
	for xi = xMin, xMax, (xMax - xMin) / 300 do
		local success, yi = pcall(func, xi)
		if success and typeof(yi) == "number" and math.abs(yi) < 1e5 then
			local px = (xi - xMin) / (xMax - xMin) * width
			local py = (1 - (yi - yMin) / (yMax - yMin)) * height

			local point = Instance.new("Frame")
			point.Size = UDim2.new(0, size, 0, size)
			point.Position = UDim2.new(0, px - size / 2, 0, py - size / 2)
			point.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
			point.BorderSizePixel = 0
			point.ZIndex = 2
			point.Parent = graphFolder
		end
	end
end
local function computeMSE(x, y, f)
	local n = #x
	local sum = 0
	for i = 1, n do
		local ok, diff = pcall(function() return f(x[i]) - y[i] end)
		if ok then
			sum += diff * diff
		end
	end
	return math.sqrt(sum / n)
end

local function computeS(x, y, f)
	local sum = 0
	for i = 1, #x do
		local ok, diff = pcall(function() return f(x[i]) - y[i] end)
		if ok then
			sum += diff * diff
		end
	end
	return sum
end

local function computeR2(x, y, f)
	local n = #x
	local avg_y = 0
	for i = 1, n do avg_y += y[i] end
	avg_y = avg_y / n

	local ss_tot, ss_res = 0, 0
	for i = 1, n do
		local ok, y_pred = pcall(function() return f(x[i]) end)
		if ok then
			ss_tot += (y[i] - avg_y)^2
			ss_res += (y[i] - y_pred)^2
		end
	end

	if ss_tot == 0 then return 0 end
	return 1 - (ss_res / ss_tot)
end

local function computePearson(x, y)
	local n = #x
	local sum_x, sum_y = 0, 0
	for i = 1, n do
		sum_x += x[i]
		sum_y += y[i]
	end
	local avg_x, avg_y = sum_x / n, sum_y / n

	local num, denom_x, denom_y = 0, 0, 0
	for i = 1, n do
		local dx = x[i] - avg_x
		local dy = y[i] - avg_y
		num += dx * dy
		denom_x += dx^2
		denom_y += dy^2
	end

	if denom_x == 0 or denom_y == 0 then return 0 end
	return num / math.sqrt(denom_x * denom_y)
end


local function doLinearRegression(x, y)
	local n = #x
	local sx, sy, sxy, sxx = 0, 0, 0, 0
	for i = 1, n do
		sx += x[i]
		sy += y[i]
		sxy += x[i] * y[i]
		sxx += x[i] * x[i]
	end
	local b = (n * sxy - sx * sy) / (n * sxx - sx * sx)
	local a = (sy - b * sx) / n
	return {a, b}
end

local function doExponentialRegression(x, y)
	local n = #x
	local ln_y = {}
	for i = 1, n do
		if y[i] <= 0 then return nil end
		ln_y[i] = math.log(y[i])
	end
	local coeffs = doLinearRegression(x, ln_y)
	if not coeffs then return nil end
	local a = math.exp(coeffs[1])
	local b = coeffs[2]
	return {a, b}
end

local function doLogarithmicRegression(x, y)
	local n = #x
	local ln_x = {}
	for i = 1, n do
		if x[i] <= 0 then return nil end
		ln_x[i] = math.log(x[i])
	end
	local coeffs = doLinearRegression(ln_x, y)
	if not coeffs then return nil end
	return coeffs
end

local function doPoly3Regression(x, y)
	local n = #x
	local sx = {0, 0, 0, 0, 0, 0, 0}  
	local sy = {0, 0, 0, 0}           

	for i = 1, n do
		local xi, yi = x[i], y[i]
		local xi_pow = 1
		for k = 1, 7 do
			xi_pow *= xi
			sx[k] += xi_pow
		end
		local xi_y = yi
		for k = 1, 4 do
			sy[k] += xi_y
			xi_y *= xi
		end
	end

	local A = {
		{n,      sx[1], sx[2], sx[3]},
		{sx[1],  sx[2], sx[3], sx[4]},
		{sx[2],  sx[3], sx[4], sx[5]},
		{sx[3],  sx[4], sx[5], sx[6]}
	}

	local function det4(m)
		local function det3(m3)
			return m3[1][1]*(m3[2][2]*m3[3][3] - m3[2][3]*m3[3][2])
			- m3[1][2]*(m3[2][1]*m3[3][3] - m3[2][3]*m3[3][1])
				+ m3[1][3]*(m3[2][1]*m3[3][2] - m3[2][2]*m3[3][1])
		end

		local det = 0
		for j = 1, 4 do
			local sub = {}
			for i = 2, 4 do
				local row = {}
				for k = 1, 4 do
					if k ~= j then
						table.insert(row, m[i][k])
					end
				end
				table.insert(sub, row)
			end
			local sign = ((j % 2) == 1) and 1 or -1
			det += sign * m[1][j] * det3(sub)
		end
		return det
	end

	local function replaceColumn(matrix, colIndex, newColumn)
		local copy = {}
		for i = 1, 4 do
			copy[i] = {table.unpack(matrix[i])}
			copy[i][colIndex] = newColumn[i]
		end
		return copy
	end

	local D = det4(A)
	if D == 0 then return nil end

	local a = det4(replaceColumn(A, 1, sy)) / D
	local b = det4(replaceColumn(A, 2, sy)) / D
	local c = det4(replaceColumn(A, 3, sy)) / D
	local d = det4(replaceColumn(A, 4, sy)) / D

	return {a, b, c, d}
end
local function doPoly2Regression(x, y)
	local n = #x
	local Sx, Sx2, Sx3, Sx4 = 0, 0, 0, 0
	local Sy, Sxy, Sx2y = 0, 0, 0

	for i = 1, n do
		local xi, yi = x[i], y[i]
		local xi2 = xi^2
		local xi3 = xi^3
		local xi4 = xi^4

		Sx += xi
		Sx2 += xi2
		Sx3 += xi3
		Sx4 += xi4

		Sy += yi
		Sxy += xi * yi
		Sx2y += xi2 * yi
	end

	local A = {
		{n,    Sx,   Sx2},
		{Sx,   Sx2,  Sx3},
		{Sx2,  Sx3,  Sx4}
	}
	local B = {Sy, Sxy, Sx2y}


	local function det3(m)
		return m[1][1]*(m[2][2]*m[3][3] - m[2][3]*m[3][2])
		- m[1][2]*(m[2][1]*m[3][3] - m[2][3]*m[3][1])
			+ m[1][3]*(m[2][1]*m[3][2] - m[2][2]*m[3][1])
	end

	local function replaceColumn(matrix, columnIndex, newColumn)
		local copy = {}
		for i = 1, 3 do
			copy[i] = {table.unpack(matrix[i])}
			copy[i][columnIndex] = newColumn[i]
		end
		return copy
	end

	local D = det3(A)
	if D == 0 then return nil end

	local a = det3(replaceColumn(A, 1, B)) / D
	local b = det3(replaceColumn(A, 2, B)) / D
	local c = det3(replaceColumn(A, 3, B)) / D

	return {a, b, c}
end

local function doPowerRegression(x, y)
	local n = #x
	local ln_x, ln_y = {}, {}
	for i = 1, n do
		if x[i] <= 0 or y[i] <= 0 then return nil end
		ln_x[i] = math.log(x[i])
		ln_y[i] = math.log(y[i])
	end
	local coeffs = doLinearRegression(ln_x, ln_y)
	if not coeffs then return nil end
	local a = math.exp(coeffs[1])
	local b = coeffs[2]
	return {a, b}
end
local function drawInputPoints(xMin, xMax, yMin, yMax)
	local width = surfaceGui.AbsoluteSize.X
	local height = surfaceGui.AbsoluteSize.Y

	local function toScreen(x, y)
		local px = (x - xMin) / (xMax - xMin) * width
		local py = (1 - (y - yMin) / (yMax - yMin)) * height
		return px, py
	end

	for i = 1, #userInput.x do
		local x, y = userInput.x[i], userInput.y[i]
		local px, py = toScreen(x, y)

		local point = Instance.new("Frame")
		point.Size = UDim2.new(0, 14, 0, 14) 
		point.Position = UDim2.new(0, px - 7, 0, py - 7)
		point.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		point.BorderSizePixel = 2
		point.BorderColor3 = Color3.fromRGB(255, 255, 255) 
		point.ZIndex = 4
		point.Name = "DataPoint"
		point.Parent = graphFolder
	end
end


local function drawAxes(xMin, xMax, yMin, yMax)
	for _, child in ipairs(surfaceGui:GetChildren()) do
		if child.Name == "Axis" or child.Name == "Tick" or child.Name == "Label" then
			child:Destroy()
		end
	end

	local width = surfaceGui.AbsoluteSize.X
	local height = surfaceGui.AbsoluteSize.Y

	local function toScreen(x, y)
		local px = (x - xMin) / (xMax - xMin) * width
		local py = (1 - (y - yMin) / (yMax - yMin)) * height
		return px, py
	end

	local px0, py0 = toScreen(0, 0)
	px0 = math.clamp(px0, 100, width - 100)    
	py0 = math.clamp(py0, 100, height - 100)  


	local xAxis = Instance.new("Frame")
	xAxis.Name = "Axis"
	xAxis.Size = UDim2.new(1, 0, 0, 2)
	xAxis.Position = UDim2.new(0, 0, 0, py0)
	xAxis.BackgroundColor3 = Color3.new(0, 0, 0)
	xAxis.BorderSizePixel = 0
	xAxis.ZIndex = 1
	xAxis.Parent = surfaceGui


	local yAxis = Instance.new("Frame")
	yAxis.Name = "Axis"
	yAxis.Size = UDim2.new(0, 2, 1, 0)
	yAxis.Position = UDim2.new(0, px0, 0, 0)
	yAxis.BackgroundColor3 = Color3.new(0, 0, 0)
	yAxis.BorderSizePixel = 0
	yAxis.ZIndex = 1
	yAxis.Parent = surfaceGui

	local function drawTicks(isX)
		local rangeMin = isX and xMin or yMin
		local rangeMax = isX and xMax or yMax
		local step = (rangeMax - rangeMin) / 10

		for i = 0, 10 do
			local val = rangeMin + i * step
			local px, py = toScreen(isX and val or 0, isX and 0 or val)

			local tick = Instance.new("Frame")
			tick.Name = "Tick"
			tick.Size = isX and UDim2.new(0, 1, 0, 8) or UDim2.new(0, 8, 0, 1)
			tick.Position = isX
				and UDim2.new(0, px, 0, py0 - 4)
				or UDim2.new(0, px0 - 4, 0, py)
			tick.BackgroundColor3 = Color3.new(0, 0, 0)
			tick.BorderSizePixel = 0
			tick.ZIndex = 1
			tick.Parent = surfaceGui

			local label = Instance.new("TextLabel")
			label.Name = "Label"
			label.Size = UDim2.new(0, 50, 0, 22)
			label.Text = string.format("%.1f", val)
			label.TextScaled = true
			label.BackgroundTransparency = 1
			label.TextColor3 = Color3.new(0, 0, 0)
			label.Position = isX
				and UDim2.new(0, px - 25, 0, py0 + 10)
				or UDim2.new(0, px0 - 55, 0, py - 11)
			label.ZIndex = 2
			label.Parent = surfaceGui
		end
	end

	drawTicks(true)
	drawTicks(false)
end


local buttonHeight = 0.1
local spacing = 0.015
local startY = 0.25

local function clearButtons()
	for i, btn in ipairs(buttons) do
		btn.Visible = false
		btn.Text = ""
		if buttonConns[i] then
			buttonConns[i]:Disconnect()
			buttonConns[i] = nil
		end
	end
end

local function showOptions(options, callback)
	clearButtons()
	for i, opt in ipairs(options) do
		local btn = buttons[i]
		btn.Text = opt.text
		btn.Visible = true
		btn.TextScaled = true
		btn.Size = UDim2.new(0.9, 0, buttonHeight, 0)
		btn.Position = UDim2.new(0.05, 0, startY + (buttonHeight + spacing) * (i - 1), 0)
		buttonConns[i] = btn.MouseButton1Click:Connect(function()
			clearButtons()
			callback(opt.value)
		end)
	end
end

local function showDigitInput(promptText, onConfirm)
	clearButtons()
	for _, c in ipairs(surfaceGui:GetChildren()) do
		if c.Name == "InputFrame" then c:Destroy() end
	end

	questionLabel.Text = promptText

	local frame = Instance.new("Frame", surfaceGui)
	frame.Name = "InputFrame"
	frame.Size = UDim2.new(0.9, 0, 0.6, 0)
	frame.Position = UDim2.new(0.05, 0, 0.3, 0)
	frame.BackgroundTransparency = 1

	local display = Instance.new("TextLabel", frame)
	display.Size = UDim2.new(1, 0, 0.15, 0)
	display.Position = UDim2.new(0, 0, 0, 0)
	display.TextScaled = true
	display.TextColor3 = Color3.new(0, 0, 0)
	display.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	display.Text = ""

	local current = ""


	local digits = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "-"}
	local special = {"←", "Сохранить"}

	for i = #digits, 2, -1 do
		local j = math.random(1, i)
		digits[i], digits[j] = digits[j], digits[i]
	end


	local keys = {}
	for _, v in ipairs(digits) do table.insert(keys, v) end
	for _, v in ipairs(special) do table.insert(keys, v) end


	for idx, key in ipairs(keys) do
		local btn = Instance.new("TextButton", frame)
		btn.Size = UDim2.new(0.3, 0, 0.15, 0)
		local row = math.floor((idx - 1) / 3)
		local col = (idx - 1) % 3
		btn.Position = UDim2.new(0.01 + 0.33 * col, 0, 0.2 + 0.17 * row, 0)
		btn.Text = key
		btn.TextScaled = true
		btn.BackgroundColor3 = Color3.new(1, 1, 1)
		btn.TextColor3 = Color3.new(0, 0, 0)

		btn.MouseButton1Click:Connect(function()
			if key == "←" then
				current = current:sub(1, -2)
			elseif key == "Сохранить" then
				local num = tonumber(current)
				if num then
					print("Введено число:", num)
					frame:Destroy()
					onConfirm(num)
				else
					display.Text = "Ошибка!"
				end
			else
				current = current .. key
			end
			display.Text = promptText .. "\n" .. current
		end)
	end
end


local function beginInput()
	clearButtons()
	for _, c in ipairs(surfaceGui:GetChildren()) do
		if c.Name == "InputFrame" then c:Destroy() end
	end

	if inputIndex > numPoints then
		for _, item in ipairs(graphFolder:GetChildren()) do
			item:Destroy()
		end
		questionLabel.Visible = false
		for _, c in ipairs(surfaceGui:GetChildren()) do
			if c.Name == "LegendItem" or c.Name == "Axis" or c.Name == "Tick" or c.Name == "Label" then
				c:Destroy()
			end
		end


		statsLabel.Text = ""  

		local legendIndex = 1
		local dataLegend = Instance.new("TextLabel")
		dataLegend.Name = "LegendItem"
		dataLegend.Size = UDim2.new(0, 200, 0, 20)
		dataLegend.Position = UDim2.new(1, -210, 0, 10)
		dataLegend.BackgroundTransparency = 0.3
		dataLegend.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		dataLegend.TextColor3 = Color3.new(1, 1, 1)
		dataLegend.TextScaled = true
		dataLegend.Text = "Исходные точки"
		dataLegend.ZIndex = 5
		dataLegend.Parent = surfaceGui

	
		local allXPositive, allYPositive = true, true
		for i = 1, #userInput.x do
			if userInput.x[i] <= 0 then allXPositive = false end
			if userInput.y[i] <= 0 then allYPositive = false end
		end

		local models = {
			{ name = "Линейная", coeffs = doLinearRegression(userInput.x, userInput.y), color = Color3.fromRGB(255, 0, 0), eval = function(c, x) return c[1] + c[2] * x end },
			{ name = "Полиномиальная (2 степень)", coeffs = doPoly2Regression(userInput.x, userInput.y), color = Color3.fromRGB(255, 165, 0), eval = function(c, x) return c[1] + c[2]*x + c[3]*x^2 end },
			{ name = "Полиномиальная (3 степень)", coeffs = doPoly3Regression(userInput.x, userInput.y), color = Color3.fromRGB(0, 255, 255), eval = function(c, x) return c[1] + c[2]*x + c[3]*x^2 + c[4]*x^3 end },
		}
		if allYPositive then
			table.insert(models, { name = "Экспоненциальная", coeffs = doExponentialRegression(userInput.x, userInput.y), color = Color3.fromRGB(0, 128, 255), eval = function(c, x) return c[1] * math.exp(c[2] * x) end })
		end
		if allXPositive then
			table.insert(models, { name = "Логарифмическая", coeffs = doLogarithmicRegression(userInput.x, userInput.y), color = Color3.fromRGB(0, 255, 0), eval = function(c, x) return c[1] + c[2] * math.log(x) end })
		end
		if allXPositive and allYPositive then
			table.insert(models, { name = "Степенная", coeffs = doPowerRegression(userInput.x, userInput.y), color = Color3.fromRGB(255, 0, 255), eval = function(c, x) return c[1] * x^c[2] end })
		end

		local bestMSE = math.huge
		local bestModelName = ""

		for _, model in ipairs(models) do
			if model.coeffs then
				local f = function(x)
					local ok, y = pcall(model.eval, model.coeffs, x)
					return ok and y or nil
				end

				local mse = computeMSE(userInput.x, userInput.y, f)
				local r2 = computeR2(userInput.x, userInput.y, f)

				appendStats(model.name .. " MSE: " .. string.format("%.5f", mse))
				appendStats(model.name .. " R²: " .. string.format("%.5f", r2))
				local coeffs = model.coeffs
				local str = ""
				if #coeffs == 2 then
					str = string.format("Коэффициенты (a, b): [%.4f, %.4f]", coeffs[1], coeffs[2])
				elseif #coeffs == 3 then
					str = string.format("Коэффициенты (a, b, c): [%.4f, %.4f, %.4f]", coeffs[1], coeffs[2], coeffs[3])
				elseif #coeffs == 4 then
					str = string.format("Коэффициенты (a, b, c, d): [%.4f, %.4f, %.4f, %.4f]", coeffs[1], coeffs[2], coeffs[3], coeffs[4])
				end
				appendStats("* " .. str)

				if model.name == "Линейная" then
					local pearson = computePearson(userInput.x, userInput.y)
					appendStats("Коэффициент корреляции Пирсона: r = " .. string.format("%.5f", pearson))
				end

				if mse < bestMSE - 1e-8 then
					bestMSE = mse
					bestModelName = model.name
				end


				local xMin, xMax = math.huge, -math.huge
				local yMin, yMax = math.huge, -math.huge
				for i = 1, #userInput.x do
					local x, y = userInput.x[i], userInput.y[i]
					if x < xMin then xMin = x end
					if x > xMax then xMax = x end
					if y < yMin then yMin = y end
					if y > yMax then yMax = y end
				end
				local xRange = xMax - xMin
				local yRange = yMax - yMin

				xMin -= xRange * 0.1
				xMax += xRange * 0.1
				yMin -= yRange * 0.1
				yMax += yRange * 0.1

				
				if xMin > 0 then xMin = 0 end
				if xMax < 0 then xMax = 0 end

				
				if yMin > 0 then yMin = 0 end
				if yMax < 0 then yMax = 0 end

				drawAxes(xMin, xMax, yMin, yMax)
				drawInputPoints(xMin, xMax, yMin, yMax)
				drawFunction(f, model.color)

				legendIndex += 1
				local legend = Instance.new("TextLabel")
				legend.Name = "LegendItem"
				legend.Size = UDim2.new(0, 200, 0, 20)
				legend.Position = UDim2.new(1, -210, 0, 10 + (legendIndex - 1) * 25)
				legend.BackgroundTransparency = 0.3
				legend.BackgroundColor3 = model.color
				legend.TextColor3 = Color3.new(0, 0, 0)
				legend.TextScaled = true
				legend.Text = model.name
				legend.ZIndex = 5
				legend.Parent = surfaceGui
			else
				appendStats(model.name .. " аппроксимация не построена")
			end
		end

		appendStats("Лучшая аппроксимация: " .. bestModelName)
		surfaceGui:FindFirstChild("RepeatButton").Visible = true

		return
	end


	if currentCoord == "x" then
		showDigitInput(string.format("Введите x[%d]", inputIndex), function(val)
			userInput.x[inputIndex] = val
			currentCoord = "y"
			beginInput()
		end)
	else
		showDigitInput(string.format("Введите y[%d]", inputIndex), function(val)
			userInput.y[inputIndex] = val


			for i = 1, inputIndex - 1 do
				if userInput.x[i] == userInput.x[inputIndex] and userInput.y[i] == userInput.y[inputIndex] then
					statsLabel.Text = "❌ Такая точка уже была введена!"
					wait(2)
					statsLabel.Text = ""
					userInput.y[inputIndex] = nil
					return beginInput()
				end
			end

			inputIndex += 1
			currentCoord = "x"
			beginInput()
		end)
	end
end


local repeatButton = Instance.new("TextButton")
repeatButton.Name = "RepeatButton"
repeatButton.Size = UDim2.new(0, 140, 0, 40)
repeatButton.Position = UDim2.new(0, 10, 0, 10)
repeatButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
repeatButton.Text = "Повторить"
repeatButton.TextColor3 = Color3.new(0, 0, 0)
repeatButton.TextScaled = true
repeatButton.Visible = false
repeatButton.Parent = surfaceGui

function nextStep()
	clearButtons()
	for _, c in ipairs(surfaceGui:GetChildren()) do
		if c.Name == "InputFrame" then c:Destroy() end
	end

	if inputStage == 0 then
		questionLabel.Text = "Как вы хотите ввести данные?"
		showOptions({
			{text = "Вручную", value = "manual"},
			{text = "Из файла", value = "file"}
		}, function(choice)
			inputMode = choice

			if choice == "file" then
				local fileValue = workspace:FindFirstChild("DataInput")
				if not fileValue or not fileValue:IsA("StringValue") then
					statsLabel.Text = "❌ DataInput (StringValue) не найден в Workspace"
					wait(3)
					statsLabel.Text = ""
					repeatButton.Visible = false
					questionLabel.Visible = true
					nextStep()
					return
				end

				local content = fileValue.Value
				local lines = {}
				for line in string.gmatch(content, "[^\r\n]+") do
					table.insert(lines, line)
				end

				if #lines ~= 2 then
					statsLabel.Text = "❌ Неверный формат: должно быть 2 строки"
					wait(3)
					statsLabel.Text = ""
					repeatButton.Visible = false
					questionLabel.Visible = true
					nextStep()
					return
				end

				local function parseLine(line)
					local result = {}
					for token in string.gmatch(line, "[^%s]+") do
						local num = tonumber(token)
						if not num then return nil end
						table.insert(result, num)
					end
					return result
				end

				local x = parseLine(lines[1])
				local y = parseLine(lines[2])

				if not x or not y or #x < 8 or #x > 12 or #x ~= #y then
					statsLabel.Text = "❌ Данные невалидны: нужно от 8 до 12 чисел в каждой строке"
					wait(3)
					statsLabel.Text = ""
					for _, item in ipairs(graphFolder:GetChildren()) do item:Destroy() end
					for _, c in ipairs(surfaceGui:GetChildren()) do
						if c.Name == "LegendItem" or c.Name == "InputFrame" or c.Name == "Axis" or c.Name == "Tick" or c.Name == "Label" then
							c:Destroy()
						end
					end
					userInput = {x = {}, y = {}}
					inputIndex = 1
					currentCoord = "x"
					numPoints = 0
					inputStage = 0
					repeatButton.Visible = false
					questionLabel.Visible = true
					nextStep()
					return
				end


				local seen = {}
				for i = 1, #x do
					local key = tostring(x[i]) .. "," .. tostring(y[i])
					if seen[key] then
						statsLabel.Text = "❌ В файле есть повторяющиеся точки!"
						wait(3)
						statsLabel.Text = ""
						for _, item in ipairs(graphFolder:GetChildren()) do item:Destroy() end
						for _, c in ipairs(surfaceGui:GetChildren()) do
							if c.Name == "LegendItem" or c.Name == "InputFrame" or c.Name == "Axis" or c.Name == "Tick" or c.Name == "Label" then
								c:Destroy()
							end
						end
						userInput = {x = {}, y = {}}
						inputIndex = 1
						currentCoord = "x"
						numPoints = 0
						inputStage = 0
						repeatButton.Visible = false
						questionLabel.Visible = true
						nextStep()
						return
					end
					seen[key] = true
				end

				userInput.x = x
				userInput.y = y
				numPoints = #x
				inputIndex = numPoints + 1
				currentCoord = "x"
				inputStage = 2
				questionLabel.Visible = false
				beginInput()
			else
				inputStage = 1
				nextStep()
			end
		end)


	elseif inputStage == 1 then
		questionLabel.Text = "Сколько точек хотите ввести?"
		local opts = {}
		for i = 8, 12 do
			table.insert(opts, {text = tostring(i), value = i})
		end
		showOptions(opts, function(n)
			numPoints = n
			inputStage = 2
			beginInput()
		end)
	end
end





repeatButton.MouseButton1Click:Connect(function()
	for _, item in ipairs(graphFolder:GetChildren()) do item:Destroy() end
	for _, c in ipairs(surfaceGui:GetChildren()) do
		if c.Name == "LegendItem" or c.Name == "InputFrame" or c.Name == "Axis" or c.Name == "Tick" or c.Name == "Label" then c:Destroy() end
	end
	statsLabel.Text = ""
	questionLabel.Visible = true
	repeatButton.Visible = false
	userInput = {x = {}, y = {}}
	inputIndex = 1
	currentCoord = "x"
	numPoints = 0
	inputStage = 0
	nextStep()
end)

questionLabel.TextScaled = true
questionLabel.TextWrapped = true
questionLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
questionLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
nextStep()