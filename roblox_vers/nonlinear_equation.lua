local surfaceGui = script.Parent
local questionLabel = surfaceGui:WaitForChild("QuestionLabel")

local buttons = {
	surfaceGui:WaitForChild("Option1"),
	surfaceGui:WaitForChild("Option2"),
	surfaceGui:WaitForChild("Option3"),
	surfaceGui:WaitForChild("Option4"),
	surfaceGui:WaitForChild("Option5")
}

local logValue = surfaceGui:FindFirstChild("TerminalLog")
if not logValue then
	logValue = Instance.new("StringValue")
	logValue.Name  = "TerminalLog"
	logValue.Value = ""          
	logValue.Parent = surfaceGui
end

local nativePrint = print


local function guiPrint(...)
    
    local out = {}
    for i = 1, select("#", ...) do
        out[#out + 1] = tostring(select(i, ...))
    end
    local line = table.concat(out, "\t")

    
    nativePrint(line)

    
    if #logValue.Value > 20000 then
        
        logValue.Value = logValue.Value:sub(-10000)
    end
    logValue.Value ..= line .. "\n"
end


print = guiPrint


local repeatButton = nil

local function chooseInitial(f, a, b)
	return math.abs(f(a)) < math.abs(f(b)) and a or b
end


local DOT_SIZE   = 5    

local graphFolder = Instance.new("Folder", surfaceGui)
graphFolder.Name = "Graphs"

local chordXs, secantXs, iterXs = {}, {}, {}
local buttonConns, selectedEquation = {}, nil



local mathFuncs = {
	[1] = function(x) return x^3 - x - 2 end,
	[2] = function(x) return math.cos(x) - x end,
	[3] = function(x) return math.exp(-x) - x end,
	[4] = function(x) return math.log(x) + x^2 end,
	[5] = function(x) return x^3 + 4*x^2 - 10 end
}

local derivatives = {
	[1] = function(x) return 3*x^2 - 1 end,
	[2] = function(x) return -math.sin(x) - 1 end,
	[3] = function(x) return -math.exp(-x) - 1 end,
	[4] = function(x) return 1/x + 2*x end,
	[5] = function(x) return 3*x^2 + 8*x end
}

local function chordMethod(f, a, b, eps)
	table.clear(chordXs)
	if math.abs(b - a) < eps then
		print("⚠️ Интервал слишком мал или a == b")
		table.insert(chordXs, b)
		return
	end
	local iter = 0
	while math.abs(b - a) > eps do
		local fa, fb = f(a), f(b)
		local next = b - fb * (b - a) / (fb - fa)
		a, b = b, next
		iter += 1
	end
	table.insert(chordXs, b) 
	print(string.format("  ▸ Хорд: %.6f, y = %.6f, итераций: %d", b, f(b), iter))

end


local function secantMethod(f, a, b, eps)
	table.clear(secantXs)
	if math.abs(b - a) < eps then
		print("⚠️ Интервал слишком мал или a == b")
		table.insert(secantXs, b)
		return
	end
	local iter = 0
	while math.abs(b - a) > eps do
		local fa, fb = f(a), f(b)
		local next = b - fb * (b - a) / (fb - fa)
		a, b = b, next
		iter += 1
	end
	table.insert(secantXs, b) 
	print(string.format("  ▸ Секущих: %.6f, y = %.6f, итераций: %d", b, f(b), iter))

end


local function simpleIteration(f, df, a, b, eps)
	table.clear(iterXs)
	local x0 = chooseInitial(f, a, b)

	local dfval = df(x0)
	if math.abs(dfval) < 1e-8 then
		print("❌ Производная ≈ 0")
		questionLabel.Text = "❌ Производная ≈ 0. Метод не применим."
		repeatButton.Visible = true
		table.insert(iterXs, x0)
		return
	end

	local lambda = -1 / dfval
	local maxPhi = -math.huge
	for x = a, b, (b - a) / 50 do
		local val = math.abs(1 + lambda * df(x))
		if val > maxPhi then maxPhi = val end
	end
	if maxPhi >= 1 then
		print(string.format("❌ Метод не сходится: max|φ'(x)| = %.3f", maxPhi))
		questionLabel.Text = "❌ Метод простой итерации расходится. Попробуйте другой интервал."
		repeatButton.Visible = true
		table.insert(iterXs, x0)
		return
	end

	local phi = function(x) return x + lambda * f(x) end

	local x, iter = x0, 0
	local max_iter = 100
	local converged = false
	repeat
		local next = phi(x)
		if math.abs(next - x) < eps then
			x = next
			converged = true
			break
		end
		x = next
		iter += 1
	until iter >= max_iter

	table.insert(iterXs, x)

	if converged then
		print(string.format("  ▸ Простая итерация: x = %.6f, f(x) = %.6f, итераций: %d", x, f(x), iter))
	else
		print(string.format("  ❌ Итерации не сошлись за %d шагов. Последнее приближение: x = %.6f, f(x) = %.6f", iter, x, f(x)))
	end
end





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
		btn.Size = UDim2.new(0.9, 0, 0.1, 0)
		btn.Position = UDim2.new(0.05, 0, 0.25 + 0.115 * (i - 1), 0)
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
	local keys = {"0","1","2","3","4","5","6","7","8","9",".","-","←","Сохранить"}
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

local function askIntervalAndEpsilon(callback)
	local interval = {}
	local function askEpsilon()
		showDigitInput("Введите ε:", function(eps)
			if eps > 0 then interval.epsilon = eps callback(interval) else askEpsilon() end
		end)
	end
	local function askB()
		showDigitInput("Введите b:", function(b)
			if b > interval.a then interval.b = b askEpsilon() else askB() end
		end)
	end
	showDigitInput("Введите a:", function(a)
		interval.a = a askB()
	end)
end

local function drawAxes(x0, x1, y0, y1)
	local w, h = surfaceGui.AbsoluteSize.X, surfaceGui.AbsoluteSize.Y
	local px   = function(x) return (x - x0) / (x1 - x0) * w end
	local py   = function(y) return (1 - (y - y0) / (y1 - y0)) * h end
	local px0  = math.clamp(px(0), 100, w - 100)
	local py0  = math.clamp(py(0), 100, h - 100)

	local ax = Instance.new("Frame", surfaceGui) 
	ax.Name              = "Axis"
	ax.Size              = UDim2.new(1, 0, 0, 2)
	ax.Position          = UDim2.new(0, 0, 0, py0)
	ax.BackgroundColor3  = Color3.new(0, 0, 0)

	local ay = Instance.new("Frame", surfaceGui)
	ay.Name              = "Axis"
	ay.Size              = UDim2.new(0, 2, 1, 0)
	ay.Position          = UDim2.new(0, px0, 0, 0)
	ay.BackgroundColor3  = Color3.new(0, 0, 0)

	local function ticks(isX)
		local a, b = (isX and x0 or y0), (isX and x1 or y1)
		for i = 0, 10 do
			local v   = a + i * (b - a) / 10
			local pxv = px(isX and v or 0)
			local pyv = py(isX and 0 or v)

			local t = Instance.new("Frame", surfaceGui)
			t.Name             = "Tick"
			t.Size             = isX and UDim2.new(0, 1, 0, 8)
				or UDim2.new(0, 8, 0, 1)
			t.Position         = isX and UDim2.new(0, pxv, 0, py0 - 4)
				or UDim2.new(0, px0 - 4, 0, pyv)
			t.BackgroundColor3 = Color3.new(0, 0, 0)

			local lbl = Instance.new("TextLabel", surfaceGui)
			lbl.Name                 = "Label"
			lbl.Size                 = UDim2.new(0, 50, 0, 22)
			lbl.BackgroundTransparency= 1
			lbl.TextScaled           = true
			lbl.TextColor3           = Color3.new(0, 0, 0)
			lbl.Text                 = string.format("%.1f", v)
			lbl.Position             = isX
				and UDim2.new(0, pxv - 25, 0, py0 + 10)
				or  UDim2.new(0, px0 - 55, 0, pyv - 11)
		end
	end
	ticks(true)
	ticks(false)
end


local function drawCurve(xs, ys, col, size)
	size = size or DOT_SIZE
	local w, h = surfaceGui.AbsoluteSize.X, surfaceGui.AbsoluteSize.Y

	local xmin, xmax = math.huge, -math.huge
	local ymin, ymax = math.huge, -math.huge
	for _, x in ipairs(xs) do
		xmin = math.min(xmin, x)
		xmax = math.max(xmax, x)
	end
	for _, y in ipairs(ys) do
		ymin = math.min(ymin, y)
		ymax = math.max(ymax, y)
	end

	local px = function(x) return (x - xmin) / (xmax - xmin) * w end
	local py = function(y) return (1 - (y - ymin) / (ymax - ymin)) * h end

	for i = 1, #xs do
		local p = Instance.new("Frame", graphFolder)
		p.Size              = UDim2.new(0, size, 0, size)
		p.Position          = UDim2.new(0, px(xs[i]) - size / 2, 0, py(ys[i]) - size / 2)
		p.BackgroundColor3  = col
		p.BorderSizePixel   = 0
		p.ZIndex            = 2
	end
	return xmin, xmax, ymin, ymax
end



local function legend(text, col, idx, total)
	local rowH = 22
	local l    = Instance.new("TextLabel", surfaceGui)
	l.Name                   = "LegendItem"
	l.Size                   = UDim2.new(0, 200, 0, rowH)
	l.Position               = UDim2.new(1, -210, 1, -(rowH * total + 10) + rowH * (idx - 1))
	l.BackgroundColor3       = col
	l.BackgroundTransparency = 0.3
	l.TextColor3             = Color3.new(0, 0, 0)
	l.TextScaled             = true
	l.Text                   = text
end

local function drawApproximationTrack(x_list, f, a, b, color, label, index)
	local w, h = surfaceGui.AbsoluteSize.X, surfaceGui.AbsoluteSize.Y
	local yMin, yMax = math.huge, -math.huge
	for _, x in ipairs(x_list) do
		local ok, y = pcall(f, x)
		if ok then
			yMin = math.min(yMin, y)
			yMax = math.max(yMax, y)
		end
	end
	if yMin == yMax then yMin -= 1 yMax += 1 end
	for _, x in ipairs(x_list) do
		local ok, y = pcall(f, x)
		if ok then
			local px = (x - a) / (b - a) * w
			local py = (1 - (y - yMin) / (yMax - yMin)) * h
			local pt = Instance.new("Frame")
			pt.Name = "TrackPoint"
			pt.Size = UDim2.new(0, 6, 0, 6)
			pt.Position = UDim2.new(0, px - 3, 0, py - 3)
			pt.BackgroundColor3 = color
			pt.BorderSizePixel = 0
			pt.ZIndex = 3
			pt.Parent = surfaceGui
		end
	end
	local legend = Instance.new("TextLabel")
	legend.Name = "Legend" .. tostring(index)
	legend.Size = UDim2.new(0, 100, 0, 20)
	legend.Position = UDim2.new(1, -110, 0, 10 + 25 * (index - 1))
	legend.BackgroundTransparency = 1
	legend.Text = label
	legend.TextColor3 = color
	legend.TextScaled = true
	legend.Parent = surfaceGui
end

local function drawAllPlots(f, a, b, xs_chord, xs_secant, xs_iter)
	
	for _, c in ipairs(surfaceGui:GetChildren()) do
		if c.Name == "Axis" or c.Name == "Tick" or c.Name == "Label" or c.Name == "LegendItem" or c.Name == "FuncPoint" or c.Name == "RootPoint" then
			c:Destroy()
		end
	end

	
	local N = 300
	local xs, ys = {}, {}
	for i = 0, N do
		local x = a + (b - a) * i / N
		local ok, y = pcall(f, x)
		if ok then
			table.insert(xs, x)
			table.insert(ys, y)
		end
	end

	local xmin, xmax, ymin, ymax = drawCurve(xs, ys, Color3.new(0, 0, 0), 2)
	drawAxes(xmin, xmax, ymin, ymax)

	
	local function plotPoints(xlist, color)
		local ys = {}
		for _, x in ipairs(xlist) do
			local ok, y = pcall(f, x)
			table.insert(ys, ok and y or 0)
		end
		drawCurve(xlist, ys, color, 20)
	end

	
	plotPoints(xs_chord,  Color3.fromRGB(255, 0, 0))   
	plotPoints(xs_secant, Color3.fromRGB(0, 255, 0))   
	plotPoints(xs_iter,   Color3.fromRGB(0, 0, 255))   

	
	legend("Метод хорд",    Color3.fromRGB(255, 0, 0), 1, 3)
	legend("Метод секущих", Color3.fromRGB(0, 255, 0), 2, 3)
	legend("Итерации",      Color3.fromRGB(0, 0, 255), 3, 3)

	
	local w, h = surfaceGui.AbsoluteSize.X, surfaceGui.AbsoluteSize.Y
	local function plotDot(x, color)
		local ok, y = pcall(f, x)
		if not ok then return end
		local px = (x - a) / (b - a) * w
		local py = (1 - (y - ymin) / (ymax - ymin)) * h
		local dot = Instance.new("Frame")
		dot.Name = "RootPoint"
		dot.Size = UDim2.new(0, 20, 0, 20)
		dot.Position = UDim2.new(0, px - 4, 0, py - 4)
		dot.BackgroundColor3 = color
		dot.BorderSizePixel = 0
		dot.ZIndex = 4
		dot.Parent = surfaceGui
	end

	if #xs_chord  > 0 then plotDot(xs_chord[#xs_chord],  Color3.fromRGB(255, 0, 0)) end
	if #xs_secant > 0 then plotDot(xs_secant[#xs_secant], Color3.fromRGB(0, 255, 0)) end
	if #xs_iter   > 0 then plotDot(xs_iter[#xs_iter],     Color3.fromRGB(0, 0, 255)) end
end



local function drawFunction(f, a, b)
	
	for _, obj in ipairs(surfaceGui:GetChildren()) do
		if obj.Name == "FuncPoint" or obj.Name:match("^Legend") or obj.Name == "TrackPoint" or obj.Name == "Axis" or obj.Name == "RootPoint" then
			obj:Destroy()
		end
	end

	local w, h = surfaceGui.AbsoluteSize.X, surfaceGui.AbsoluteSize.Y
	local step = (b - a) / 300
	local yMin, yMax = math.huge, -math.huge

	
	for x = a, b, step do
		local ok, y = pcall(f, x)
		if ok then
			yMin = math.min(yMin, y)
			yMax = math.max(yMax, y)
		end
	end
	if yMin == yMax then yMin -= 1 yMax += 1 end

	
	for x = a, b, step do
		local ok, y = pcall(f, x)
		if ok then
			local px = (x - a) / (b - a) * w
			local py = (1 - (y - yMin) / (yMax - yMin)) * h
			local pt = Instance.new("Frame")
			pt.Name = "FuncPoint"
			pt.Size = UDim2.new(0, 2, 0, 2)
			pt.Position = UDim2.new(0, px, 0, py)
			pt.BackgroundColor3 = Color3.new(0, 0, 0)
			pt.BorderSizePixel = 0
			pt.ZIndex = 2
			pt.Parent = surfaceGui
		end
	end

	
	local x0 = 0
	if a <= 0 and b >= 0 then
		x0 = (0 - a) / (b - a) * w
	else
		x0 = -1
	end

	local y0 = 0
	if yMin <= 0 and yMax >= 0 then
		y0 = (1 - (0 - yMin) / (yMax - yMin)) * h
	else
		y0 = -1
	end

	if x0 >= 0 then
		local yAxis = Instance.new("Frame")
		yAxis.Name = "Axis"
		yAxis.Size = UDim2.new(0, 2, 1, 0)
		yAxis.Position = UDim2.new(0, x0, 0, 0)
		yAxis.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		yAxis.BorderSizePixel = 0
		yAxis.ZIndex = 1
		yAxis.Parent = surfaceGui
	end

	if y0 >= 0 then
		local xAxis = Instance.new("Frame")
		xAxis.Name = "Axis"
		xAxis.Size = UDim2.new(1, 0, 0, 2)
		xAxis.Position = UDim2.new(0, 0, 0, y0)
		xAxis.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		xAxis.BorderSizePixel = 0
		xAxis.ZIndex = 1
		xAxis.Parent = surfaceGui
	end

	
	local function plotDot(x, color)
		local ok, y = pcall(f, x)
		if not ok then return end
		local px = (x - a) / (b - a) * w
		local py = (1 - (y - yMin) / (yMax - yMin)) * h
		local dot = Instance.new("Frame")
		dot.Name = "RootPoint"
		dot.Size = UDim2.new(0, 8, 0, 8)
		dot.Position = UDim2.new(0, px - 4, 0, py - 4)
		dot.BackgroundColor3 = color
		dot.BorderSizePixel = 0
		dot.ZIndex = 4
		dot.Parent = surfaceGui
	end

	if #chordXs > 0 then plotDot(chordXs[#chordXs], Color3.fromRGB(255, 0, 0)) end
	if #secantXs > 0 then plotDot(secantXs[#secantXs], Color3.fromRGB(0, 255, 0)) end
	if #iterXs > 0 then plotDot(iterXs[#iterXs], Color3.fromRGB(0, 0, 255)) end
end


local function startProgram()
	selectedEquation = nil
	questionLabel.Text = "Выберите способ ввода:"

	showOptions({
		{text = "Ввести вручную", value = "manual"},
		{text = "Считать из файла", value = "file"}
	}, function(mode)
		if mode == "manual" then
			
			questionLabel.Text = "Выберите уравнение:"
			showOptions({
				{text = "f(x) = x^3 - x - 2", value = 1},
				{text = "f(x) = cos(x) - x", value = 2},
				{text = "f(x) = e^(-x) - x", value = 3},
				{text = "f(x) = ln(x) + x^2", value = 4},
				{text = "f(x) = x^3 + 4x^2 - 10", value = 5}
			}, function(eq)
				selectedEquation = eq
				askIntervalAndEpsilon(function(interval)
					local f    = mathFuncs[selectedEquation]
					local df   = derivatives[selectedEquation]
					local a, b = interval.a, interval.b
					local eps  = interval.epsilon

					local fa, fb = f(a), f(b)
					if fa * fb > 0 then
						questionLabel.Text = "❌ На интервале нет одного корня. Попробуйте снова."
						repeatButton.Visible = true
						return
					end

					chordMethod(f, a, b, eps)
					secantMethod(f, a, b, eps)
					simpleIteration(f, df, a, b, eps)

					drawAllPlots(f, a, b, chordXs, secantXs, iterXs)
				end)
			end)

		elseif mode == "file" then
			
			questionLabel.Text = "" 
			repeatButton.Visible = true 

			local autoInput = surfaceGui:FindFirstChild("AutoInput")
			if autoInput and autoInput:IsA("StringValue") and autoInput.Value ~= "" then
				local input = autoInput.Value
				local f, a, b, eps = input:match("f%s*=%s*(%d+)%s*;%s*a%s*=%s*([%d%.%-]+)%s*;%s*b%s*=%s*([%d%.%-]+)%s*;%s*eps%s*=%s*([%d%.%-]+)")
				if f and a and b and eps then
					f = tonumber(f)
					a = tonumber(a)
					b = tonumber(b)
					eps = tonumber(eps)

					selectedEquation = f
					local func = mathFuncs[f]
					local df   = derivatives[f]

					if not func or not df then
						questionLabel.Text = "⚠️ Некорректный номер функции."
						return
					end

					local fa, fb = func(a), func(b)
					if fa * fb > 0 then
						questionLabel.Text = "❌ f(a) * f(b) > 0 — корней нет или их чётное число."
						return
					end

					chordMethod(func, a, b, eps)
					secantMethod(func, a, b, eps)
					simpleIteration(func, df, a, b, eps)

					drawAllPlots(func, a, b, chordXs, secantXs, iterXs)
				else
					questionLabel.Text = "⚠️ Неверный формат строки в AutoInput"
				end
			else
				questionLabel.Text = "⚠️ Не найден AutoInput (StringValue) или он пуст."
			end
		end

	end)
end



questionLabel.TextScaled = true
questionLabel.TextWrapped = true
questionLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
questionLabel.Position = UDim2.new(0.05, 0, 0.05, 0)



repeatButton = Instance.new("TextButton", surfaceGui)
repeatButton.Size             = UDim2.new(0, 140, 0, 40)
repeatButton.Position         = UDim2.new(0, 10, 0, 10)
repeatButton.Text             = "Начать заново"
repeatButton.TextScaled       = true
repeatButton.Visible          = false

repeatButton.MouseButton1Click:Connect(function()
	repeatButton.Visible = false

	
	for _, dot in ipairs(graphFolder:GetChildren()) do
		dot:Destroy()
	end

	
	for _, child in ipairs(surfaceGui:GetChildren()) do
		if child.Name ~= "Graphs" and (
			child.Name == "FuncPoint" or child.Name == "RootPoint" or
				child.Name == "Axis"      or child.Name == "Tick"      or
				child.Name == "Label"     or child.Name == "LegendItem"or
				child.Name:match("^Legend") or child.Name == "TrackPoint" or
				child.Name == "InputFrame") then
			child:Destroy()
		end
	end

	startProgram()
end)


startProgram()

