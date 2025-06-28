local surfaceGui    = script.Parent
local questionLabel = surfaceGui:WaitForChild("QuestionLabel")
local statsLabel    = workspace:WaitForChild("StatsBoard")
	:WaitForChild("SurfaceGui"):WaitForChild("StatsLabel")

if surfaceGui.AbsoluteSize.X == 0 then
	surfaceGui:GetPropertyChangedSignal("AbsoluteSize"):Wait()
end


local buttons = {
	surfaceGui.Option1, surfaceGui.Option2, surfaceGui.Option3,
	surfaceGui.Option4, surfaceGui.Option5
}
local buttonConns = {}

local repeatButton = Instance.new("TextButton", surfaceGui)
repeatButton.Size             = UDim2.new(0, 140, 0, 40)
repeatButton.Position         = UDim2.new(0, 10, 0, 10)
repeatButton.Text             = "Начать заново"
repeatButton.TextScaled       = true
repeatButton.Visible          = false

local graphFolder = Instance.new("Folder", surfaceGui)
graphFolder.Name = "Graphs"


local ODEs = {
	{ name = "y' = x + y", f = function(x, y) return x + y end,
	exact = function(x, x0, y0) 
		local C = (y0 + x0 + 1) / math.exp(x0)
		return C * math.exp(x) - x - 1
	end },

	{ name = "y' = y·cos(x)", f = function(x, y) return y * math.cos(x) end,
	exact = function(x, x0, y0)  
		return y0 * math.exp(math.sin(x) - math.sin(x0))
	end },

	{ name = "y' = x² − y", f = function(x, y) return x^2 - y end,
	exact = nil  
	},
}



local MAX_STEPS  = 5000      
local DOT_SIZE   = 5         
local DEC_PLACES = 10         


local function clearButtons()
	for i, b in ipairs(buttons) do
		b.Visible = false
		b.Text    = ""
		if buttonConns[i] then
			buttonConns[i]:Disconnect()
			buttonConns[i] = nil
		end
	end
end

local function appendStats(t)
	statsLabel.Text ..= t .. "\n"
end


local BH, SPC, STARTY = 0.10, 0.015, 0.25

local function showOptions(list, cb)
	clearButtons()
	for i, opt in ipairs(list) do
		local b = buttons[i]
		b.Visible      = true
		b.Text         = opt.text
		b.TextScaled   = true
		b.Size         = UDim2.new(0.9, 0, BH, 0)
		b.Position     = UDim2.new(0.05, 0, STARTY + (BH + SPC) * (i - 1), 0)
		buttonConns[i] = b.MouseButton1Click:Connect(function()
			clearButtons()
			cb(opt.value)
		end)
	end
end


local function showDigitInput(prompt, onSuccess, validator)
	clearButtons()
	for _, c in ipairs(surfaceGui:GetChildren()) do
		if c.Name == "InputFrame" then c:Destroy() end
	end
	questionLabel.Text = prompt

	local fr = Instance.new("Frame", surfaceGui)
	fr.Name                   = "InputFrame"
	fr.Size                   = UDim2.new(0.9, 0, 0.6, 0)
	fr.Position               = UDim2.new(0.05, 0, 0.3, 0)
	fr.BackgroundTransparency = 1

	local disp = Instance.new("TextLabel", fr)
	disp.Size                  = UDim2.new(1, 0, 0.15, 0)
	disp.TextScaled            = true
	disp.TextWrapped           = true
	disp.BackgroundColor3      = Color3.fromRGB(230, 230, 230)
	disp.TextColor3            = Color3.new(0, 0, 0)
	disp.Text                  = prompt

	local cur  = ""
	local keys = { "0","1","2","3","4","5","6","7","8","9",".","-" }
	for i = #keys, 2, -1 do
		local j = math.random(1, i)
		keys[i], keys[j] = keys[j], keys[i]
	end
	table.insert(keys, "←")
	table.insert(keys, "OK")

	for idx, k in ipairs(keys) do
		local b = Instance.new("TextButton", fr)
		b.Size       = UDim2.new(0.3, 0, 0.15, 0)
		local row    = math.floor((idx - 1) / 3)
		local col    = (idx - 1) % 3
		b.Position   = UDim2.new(0.01 + 0.33 * col, 0, 0.2 + 0.17 * row, 0)
		b.Text       = k
		b.TextScaled = true
		b.MouseButton1Click:Connect(function()
			if k == "←" then
				cur = cur:sub(1, -2)
			elseif k == "OK" then
				local num = tonumber(cur)
				if num and (not validator or validator(num)) then
					fr:Destroy()
					onSuccess(num)
				else
					disp.Text = prompt .. "\nНеверное значение!"
				end
			else
				cur = cur .. k
			end
			disp.Text = prompt .. "\n" .. cur
		end)
	end
end


local function clearGraph()
	for _, c in ipairs(graphFolder:GetChildren()) do c:Destroy() end
	for _, c in ipairs(surfaceGui:GetChildren()) do
		if c.Name == "Axis" or c.Name == "Tick"
			or c.Name == "Label" or c.Name == "LegendItem" then
			c:Destroy()
		end
	end
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


local function rungeRule(y1, y2, p, eps)
	return math.abs(y1 - y2) / (2 ^ p - 1) < eps
end


local function heunMethod(f, x0, y0, xn, h, eps)
	if xn < x0 then h = -math.abs(h) end
	local xs, ys = { x0 }, { y0 }
	local stepN  = 0

	while (h > 0 and xs[#xs] < xn) or (h < 0 and xs[#xs] > xn) do
		stepN += 1
		if stepN > MAX_STEPS then error("Heun: слишком много шагов") end

		local x, y = xs[#xs], ys[#ys]

		local y_pred       = y + h  * f(x, y)
		local y_corr       = y + h  * (f(x, y) + f(x + h , y_pred)) / 2

		local h2           = h / 2
		local y_half_pred  = y + h2 * f(x, y)
		local y_half_corr  = y + h2 * (f(x, y) + f(x + h2, y_half_pred)) / 2

		if rungeRule(y_corr, y_half_corr, 2, eps) then
			table.insert(xs, x + h)
			table.insert(ys, y_corr)
		else
			h = h / 2
		end

		if math.abs(h) < 1e-8 then error("Heun h < 1e-8") end
	end
	return xs, ys
end


local function rk4Method(f, x0, y0, xn, h, eps)
	if xn < x0 then h = -math.abs(h) end

	local function step(x, y, hStep)
		local k1 = hStep * f(x        , y          )
		local k2 = hStep * f(x + hStep/2, y + k1/2 )
		local k3 = hStep * f(x + hStep/2, y + k2/2 )
		local k4 = hStep * f(x + hStep  , y + k3   )
		return x + hStep, y + (k1 + 2*k2 + 2*k3 + k4) / 6
	end

	local xs, ys = { x0 }, { y0 }
	local stepN  = 0

	while (h > 0 and xs[#xs] < xn) or (h < 0 and xs[#xs] > xn) do
		stepN += 1
		if stepN > MAX_STEPS then error("RK4: слишком много шагов") end

		local x, y  = xs[#xs], ys[#ys]
		local x1, y1 = step(x, y, h)
		local _, yh  = step(x, y, h / 2)

		if rungeRule(y1, yh, 4, eps) then
			table.insert(xs, x1)
			table.insert(ys, y1)
		else
			h = h / 2
		end

		if math.abs(h) < 1e-8 then error("RK4 h < 1e-8") end
	end
	return xs, ys
end


local function milneMethod(f, x0, y0, xn, h, eps)
	if xn < x0 then h = -math.abs(h) end

	local xs, ys = { x0 }, { y0 }
	local x,  y  = x0, y0
	
	for _ = 1, 3 do
		local k1 = h * f(x          , y          )
		local k2 = h * f(x + h/2    , y + k1/2   )
		local k3 = h * f(x + h/2    , y + k2/2   )
		local k4 = h * f(x + h      , y + k3     )
		y = y + (k1 + 2*k2 + 2*k3 + k4) / 6
		x = x + h
		table.insert(xs, x)
		table.insert(ys, y)
	end

	local stepN = 3
	while (h > 0 and xs[#xs] < xn) or (h < 0 and xs[#xs] > xn) do
		stepN += 1
		if stepN > MAX_STEPS then error("Milne: слишком много шагов") end

		local i          = #ys
		local f0, f1, f2 = f(xs[i-3], ys[i-3]), f(xs[i-2], ys[i-2]), f(xs[i-1], ys[i-1])

		
		local yPred = ys[i-3] + (4*h/3)*(2*f0 - f1 + 2*f2)
		local xNext = xs[i] + h
		local yCorr = yPred

		
		for _ = 1, 50 do
			local yNew = ys[i-2] + (h/3) * (f1 + 4*f2 + f(xNext, yCorr))
			if math.abs(yNew - yCorr) <= eps then break end
			yCorr = yNew
		end

		table.insert(xs, xNext)
		table.insert(ys, yCorr)
	end
	return xs, ys
end


local palette = {
	Heun  = Color3.fromRGB(255,   0, 255),
	RK4   = Color3.fromRGB(  0, 120, 255),
	Milne = Color3.fromRGB(  0, 200,   0),
	Exact = Color3.fromRGB(  0,   0,   0)
}


local function dump(tag, xs, ys)
	print(string.format("[%s] N = %d", tag, #xs))
	local fmt  = "%." .. DEC_PLACES .. "f"
	local step = math.max(1, math.floor(#xs / 100))
	for i = 1, #xs, step do
		print(string.format("  i=%d  x=" .. fmt .. "  y=" .. fmt,
			i - 1, xs[i], ys[i]))
	end
	if step > 1 then
		print(string.format("  ... каждая %d-я точка ...", step))
	end
end


local function solveAll(inp)

	local f      = ODEs[inp.eq].f
	local exactF = ODEs[inp.eq].exact      

	local xh, yh = heunMethod (f, inp.x0, inp.y0, inp.xn, inp.h, inp.eps)
	local xr, yr = rk4Method  (f, inp.x0, inp.y0, inp.xn, inp.h, inp.eps)
	local xm, ym = milneMethod(f, inp.x0, inp.y0, inp.xn, inp.h, inp.eps)


	dump("Heun" , xh, yh)
	dump("RK4"  , xr, yr)
	dump("Milne", xm, ym)


	clearGraph()                         

	local xmin, xmax = math.huge, -math.huge
	local ymin, ymax = math.huge, -math.huge
	local function ext(xs, ys)            
		for i = 1, #xs do
			xmin = math.min(xmin, xs[i]); xmax = math.max(xmax, xs[i])
			ymin = math.min(ymin, ys[i]); ymax = math.max(ymax, ys[i])
		end
	end
	ext(xh, yh);  ext(xr, yr);  ext(xm, ym)


	if exactF then
		local xt, yt = {}, {}
		for i = 1, #xh do
			xt[i] = xh[i]
			yt[i] = exactF(xh[i], inp.x0, inp.y0)
		end
		ext(xt, yt)                      
		drawCurve(xt, yt, palette.Exact, 10)
	end


	local padX, padY = 0.10*(xmax - xmin), 0.10*(ymax - ymin)
	drawAxes(xmin - padX, xmax + padX, ymin - padY, ymax + padY)

	drawCurve(xh, yh, palette.Heun )
	drawCurve(xr, yr, palette.RK4  )
	drawCurve(xm, ym, palette.Milne)

	local total = exactF and 4 or 3
	legend("Heun (уЭ)", palette.Heun , 1, total)
	legend("RK-4"      , palette.RK4  , 2, total)
	legend("Milne"     , palette.Milne, 3, total)
	if exactF then
		legend("Точное", palette.Exact, 4, total)
	end


	local function rungeError(method, p)
		local _, y1 = method(f, inp.x0, inp.y0, inp.xn, inp.h    , inp.eps)
		local _, y2 = method(f, inp.x0, inp.y0, inp.xn, inp.h / 2, inp.eps)
		local i = math.min(#y1, #y2)
		return math.abs(y1[i] - y2[i]) / (2^p - 1)
	end

	print("\n=== Оценка точности (правило Рунге) ===")
	print(string.format("Heun  (p=2): %.2e", rungeError(heunMethod, 2)))
	print(string.format("RK-4  (p=4): %.2e", rungeError(rk4Method , 4)))

	if exactF then
		local yt = {}
		for i = 1, #xh do yt[i] = exactF(xh[i], inp.x0, inp.y0) end
		local function maxError(ya, ye)
			local m = 0
			for i = 1, math.min(#ya, #ye) do
				m = math.max(m, math.abs(ya[i] - ye[i]))
			end
			return m
		end
		print(string.format("ε_Milne   = %.2e", maxError(ym, yt)))
	end


	repeatButton.Visible = true            
end



local input = { eq=nil,x0=nil,y0=nil,xn=nil,h=nil,eps=nil }
local stage = 0

local function nextStep()
	if stage == 0 then
		questionLabel.Visible = true
		questionLabel.Text    = "Выберите одно из ОДУ:"

		local opts = {}
		for i, ode in ipairs(ODEs) do
			opts[#opts+1] = { text = ode.name, value = i }
		end
		showOptions(opts, function(v)
			input.eq = v
			stage    = 1
			nextStep()
		end)

	elseif stage == 1 then
		showDigitInput(
			"x₀:",
			function(v)
				input.x0 = v
				stage = 2
				nextStep()
			end,
			function(_) return true end
		)

	elseif stage == 2 then
		showDigitInput(
			"y₀:",
			function(v)
				input.y0 = v
				stage = 3
				nextStep()
			end,
			function(_) return true end
		)

	elseif stage == 3 then
		showDigitInput(
			"xₙ:",
			function(v)
				if input.h and (v - input.x0) * input.h < 0 then
					questionLabel.Text = "xₙ должен быть по ту же сторону, что и шаг h!"
				else
					input.xn = v
					stage = 4
					nextStep()
				end
			end,
			function(num) return num ~= input.x0 end  
		)

	elseif stage == 4 then
		showDigitInput(
			"h (шаг):",
			function(v)
				if input.xn and (input.xn - input.x0) * v <= 0 then
					
					questionLabel.Text = "Шаг h должен быть в направлении от x₀ к xₙ!"
					nextStep()  
				else
					input.h = v
					stage = 5
					nextStep()
				end
			end,
			function(num) return num ~= 0 end
		)

	elseif stage == 5 then
		showDigitInput(
			"ε (точность):",
			function(v)
				if v <= 0 then
					questionLabel.Text = "Точность ε должна быть положительной!"
					nextStep()  
				else
					input.eps = v
					stage = 6
					nextStep()
				end
			end,
			function(_) return true end  
		)

	else
		questionLabel.Visible = false
		solveAll(input)
	end
end


repeatButton.MouseButton1Click:Connect(function()
	statsLabel.Text      = ""
	clearGraph()
	clearButtons()
	repeatButton.Visible = false
	questionLabel.Visible= true
	input  = { eq=nil,x0=nil,y0=nil,xn=nil,h=nil,eps=nil }
	stage  = 0
	nextStep()
end)

questionLabel.TextScaled  = true
questionLabel.TextWrapped = true
questionLabel.Size        = UDim2.new(0.9, 0, 0.2, 0)
questionLabel.Position    = UDim2.new(0.05, 0, 0.05, 0)


nextStep()