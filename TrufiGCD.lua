-- TrufiGCD stevemyz@gmail.com
ChatFrame1:AddMessage("载入成功")--JANY
--sizeicon = 30 
--speed = sizeicon /1.6 --回放速度
local TimeGcd = 1.6
--width = sizeicon * 3 -- длина очереди
local SpMod = 3 -- 快速回放修改器
local f=CreateFrame("Frame","Eventframe1",UIParent)--JANY
TrGCDBufferIcon = {} --图标距离计数器
local TimeDelay = 0.03 -- 更新之间的延迟
local TimeReset = GetTime() -- 最后一个On更新时间
local DurTimeImprove = 0.0 --快速回放持续时间
TrGCDCastSp = {} -- 0 - каст идет, 1 - каст прошел и не идет   0是种姓，1是种姓，不是。
TrGCDCastSpBanTime = {} --种姓停止时间
TrGCDBL = {} -- 专家黑名单
local BLSpSel = nil --高亮显示的刀片中的Spell
local InnerBL = { --关闭的黑名单，按ID
	61391, -- Тайфун x2
	5374, -- Расправа х3
	27576, -- Расправа (левая рука) х3
	88263, -- Молот Праведника х3
	98057, -- Великий воин Света
	32175, -- Удар бури
	32176, -- Удар бури (левая рука)
	96103, -- Яростный выпад
	85384, -- Яростный выпад (левая рука)
	57794, -- Героический прыжок
	52174, -- Героический прыжок
	135299, -- Ледяная ловушка
	121473, -- Теневой клинок
	121474, -- Второй теневой клинок
	114093, -- Хлещущий ветер (левая рука)
	114089, -- Хлещущий ветер
	115357, -- Свирепость бури
	115360, -- Свирепость бури (левая рука)
	127797, -- Вихрь урсола
	102794, -- Вихрь урсола
	50622, -- Вихрь клинков
	122128, -- Божественная звезда (шп)
	110745, -- Божественная звезда (не шп)
	120696, -- Сияние (шп)
	120692, -- Сияние (не шп)
	115464, -- Целительная сфера
	126526, -- Целительная сфера
	132951, -- Осветительная ракета
	107270, -- Танцующий журавль
	137584, -- Бросок сюрикена
	137585, -- Бросок сюрикена левой рукой
	117993, -- Ци-полет (дамаг)
	124040, -- Ци-полет (хил)
	
}
local cross = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7"
local skull = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"
local trinket = "Interface\\Icons\\inv_jewelry_trinketpvp_01"
TrGCDInsSp = {}
TrGCDInsSp["spell"] = {}
TrGCDInsSp["time"] = {}
TrGCDSpStop = {} -- 斯佩拉种姓的图标编号
TrGCDSpStopTime = {} -- 斯佩拉种姓的图标编号
TrGCDSpStopName = {}
local TrGCDEnable = true
local PlayerDislocation = 0 -- 球员的位置：1-世界，2-PVE，3-体育场，4-Bg。
TrGCDIconOnEnter = {} -- false - курсор на иконке
TrGCDTimeuseSpamSpell = {} -- 使用N->；SpellID->；Time队列中的垃圾邮件的时间

--мод движения иконок
local ModTimeVanish = 2; -- время, за которое иконки будут исчезать图标消失的时间。
local ModTimeIndent = 3; -- время, через которое иконки будут исчезать图标消失的时间

--假面娱乐剧
local Masque = LibStub("Masque", true)
if Masque then
	TrGCDMasqueIcons = Masque:Group("TrufiGCD", "All Icons")
end

SLASH_TRUFI1, SLASH_TRUFI2 = '/tgcd', '/trufigcd' --唾液
function SlashCmdList.TRUFI(msg, editbox) --命令函数
	InterfaceOptionsFrame_OpenToCategory(TrGCDGUI)
end
local function AddButton(parent,position,x,y,height,width,text,font,texttop,template) --添加按钮
	local temp = nil
	if (template == nil) then temp = "UIPanelButtonTemplate" end
	local button = CreateFrame ("Button", nil, parent, temp)
	button:SetHeight(height)
	button:SetWidth(width)
	button:SetPoint(position, parent, position,x, y)
	button:SetText(text)
	if ((font ~= nil) and (texttop ~= nil)) then
		button.Text = button:CreateFontString(nil, "BACKGROUND")
		button.Text:SetFont("Fonts\\FRIZQT__.TTF", font)
		button.Text:SetText(texttop)
		button.Text:SetPoint("TOP", button, "TOP",0, 10)
	end
	return button
end
local function AddCheckButton (parent, position,x,y,text,name,fromenable) --复选框模板
	local button = CreateFrame("CheckButton", name, parent, "ChatConfigCheckButtonTemplate")
	button:SetPoint(position, parent, position,x,y)
	button:SetChecked(fromenable)
	getglobal(name .. 'Text'):SetText(text)
	button:SetScript("OnEnter", function(self)
		if self.tooltipText then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, 1)
		end
		if self.tooltipRequirement then
			GameTooltip:AddLine(self.tooltipRequirement, "", 1.0, 1.0, 1.0)
			GameTooltip:Show()
		end
	end )
	button:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	return button
end
local function ValueReverse(value) -- 单击CheckButton后，将更改保存的值，falsee->；true，true->；false
	local t = value
	if (t) then t = false else t = true end
	return t
end
local TrGCDLoadFrame = CreateFrame("Frame", nil, UIParent)
TrGCDLoadFrame:RegisterEvent("ADDON_LOADED")
TrGCDLoadFrame:SetScript("OnEvent", TrufiGCDAddonLoaded)
function TrufiGCDAddonLoaded(self, event, ...)
	local arg1 = ...;
	if (arg1 == "TrufiGCD" and event == "ADDON_LOADED") then 
		--Load options
		TrGCDQueueOpt = {}
		local TrGCDNullOptions = false -- настройки пустые?
		if (TrufiGCDChSave == nil) then
			TrGCDNullOptions = true
		else
			if (TrufiGCDChSave["TrGCDQueueFr"] == nil) then
				TrGCDNullOptions = true
			else
				for i=1,12 do
					if (TrufiGCDChSave["TrGCDQueueFr"][i] == nil) then
						TrGCDNullOptions = true
					else
						if ((TrufiGCDChSave["TrGCDQueueFr"][i]["point"] == nil) or (TrufiGCDChSave["TrGCDQueueFr"][i]["enable"] == nil) or (TrufiGCDChSave["TrGCDQueueFr"][i]["text"] == nil)) then
							TrGCDNullOptions = true
						elseif ((TrufiGCDChSave["TrGCDQueueFr"][i]["fade"] == nil) or (TrufiGCDChSave["TrGCDQueueFr"][i]["size"] == nil) or (TrufiGCDChSave["TrGCDQueueFr"][i]["width"] == nil)) then
							TrGCDNullOptions = true					
						elseif ((TrufiGCDChSave["TrGCDQueueFr"][i]["speed"] == nil) or (TrufiGCDChSave["TrGCDQueueFr"][i]["x"] == nil) or (TrufiGCDChSave["TrGCDQueueFr"][i]["y"] == nil)) then	
							TrGCDNullOptions = true
						end
					end
				end
			end
			if (TrufiGCDChSave["TooltipEnable"] == nil) then
				TrGCDNullOptions = true
			end
		end
		if (TrGCDNullOptions) then TrGCDRestoreDefaultSettings()
		else
			for i=1,12 do
				TrGCDQueueOpt[i] = {}
				TrGCDQueueOpt[i].x = TrufiGCDChSave["TrGCDQueueFr"][i]["x"]
				TrGCDQueueOpt[i].y = TrufiGCDChSave["TrGCDQueueFr"][i]["y"]
				TrGCDQueueOpt[i].point = TrufiGCDChSave["TrGCDQueueFr"][i]["point"]
				TrGCDQueueOpt[i].enable = TrufiGCDChSave["TrGCDQueueFr"][i]["enable"]				
				TrGCDQueueOpt[i].text = TrufiGCDChSave["TrGCDQueueFr"][i]["text"]
				TrGCDQueueOpt[i].fade = TrufiGCDChSave["TrGCDQueueFr"][i]["fade"]
				TrGCDQueueOpt[i].size = TrufiGCDChSave["TrGCDQueueFr"][i]["size"]
				TrGCDQueueOpt[i].width = TrufiGCDChSave["TrGCDQueueFr"][i]["width"]
				TrGCDQueueOpt[i].speed = TrufiGCDChSave["TrGCDQueueFr"][i]["speed"]
			end				
		end
		--检查空黑色列表
		if (TrufiGCDChSave["TrGCDBL"] == nil) then TrGCDBLDefaultSetting()
		else TrGCDBL = TrufiGCDChSave["TrGCDBL"]
		end
		-- 空白EnableIn检查
		-- NEW MODE, TrufiGCDChSave["EnableIn"] - ["PvE"], ["Arena"], ["Bg"], ["World"] = true or false
		TrGCDNullOptions = false
		if (TrufiGCDChSave["EnableIn"] == nil) then
			TrGCDNullOptions = true
		else
			if (TrufiGCDChSave["EnableIn"]["PvE"] == nil) then TrGCDNullOptions = true
			elseif (TrufiGCDChSave["EnableIn"]["Arena"] == nil) then TrGCDNullOptions = true
			elseif (TrufiGCDChSave["EnableIn"]["Bg"] == nil) then TrGCDNullOptions = true
			elseif (TrufiGCDChSave["EnableIn"]["World"] == nil) then TrGCDNullOptions = true
			elseif (TrufiGCDChSave["EnableIn"]["Enable"] == nil) then TrGCDNullOptions = true
			end
		end
		if (TrGCDNullOptions) then 
			TrufiGCDChSave["EnableIn"] = {}
			TrufiGCDChSave["EnableIn"]["PvE"] = true
			TrufiGCDChSave["EnableIn"]["Arena"] = true
			TrufiGCDChSave["EnableIn"]["Bg"] = true
			TrufiGCDChSave["EnableIn"]["World"] = true
			TrufiGCDChSave["EnableIn"]["Enable"] = true
		end
		-- проверка на пустой ModScroll VERSION 1.5
		if (TrufiGCDChSave["ModScroll"] == nil) then TrufiGCDChSave["ModScroll"] = true end
		-- проверка на пустой EnableIn - Raid VERSION 1.6
		if (TrufiGCDChSave["EnableIn"]["Raid"] == nil) then TrufiGCDChSave["EnableIn"]["Raid"] = true end
		if (TrufiGCDChSave["TooltipStopMove"] == nil) then TrufiGCDChSave["TooltipStopMove"] = true end
		if (TrufiGCDChSave["TooltipSpellID"] == nil) then TrufiGCDChSave["TooltipSpellID"] = false end
		
		TrGCDCheckToEnableAddon()
		-- Options Panel Frame
		TrGCDGUI = CreateFrame ("Frame", nil, UIParent, "OptionsBoxTemplate")
		TrGCDGUI:Hide()
		TrGCDGUI.name = "TrufiGCD"
		--кнопка show/hide
		TrGCDGUI.buttonfix = AddButton(TrGCDGUI,"TOPLEFT",10,-30,22,100,"Show",10,"显示/隐藏锚点")
		TrGCDGUI.buttonfix:SetScript("OnClick", TrGCDGUIButtonFixClick)
		--кнопка загрузки настроек сохраненных в кэше
		TrGCDGUI.ButtonLoad = AddButton(TrGCDGUI,"TOPRIGHT",-145,-30,22,100,"Load",10,"加载保存设置")
		TrGCDGUI.ButtonLoad:SetScript("OnClick", TrGCDLoadSettings) 
		--кнопки сохранения настроек в кэш
		TrGCDGUI.ButtonSave = AddButton(TrGCDGUI,"TOPRIGHT",-260,-30,22,100,"Save",10,"将设置保存到缓存")
		TrGCDGUI.ButtonSave:SetScript("OnClick", TrGCDSaveSettings) 
		--кнопка восстановления стандартных настроек
		TrGCDGUI.ButtonRes = AddButton(TrGCDGUI,"TOPRIGHT",-30,-30,22,100,"Default",10,"恢复默认设置")
		TrGCDGUI.ButtonRes:SetScript("OnClick", function () TrGCDRestoreDefaultSettings() TrGCDUploadViewSetting() end) 
		--чек на Тултип
		TrGCDGUI.CheckTooltipText = TrGCDGUI:CreateFontString(nil, "BACKGROUND")
		TrGCDGUI.CheckTooltipText:SetFont("Fonts\\FRIZQT__.TTF", 12)
		TrGCDGUI.CheckTooltipText:SetText("工具提示:")
		TrGCDGUI.CheckTooltipText:SetPoint("TOPRIGHT", TrGCDGUI, "TOPRIGHT",-70, -360)
		TrGCDGUI.CheckTooltip = AddCheckButton(TrGCDGUI,"TOPRIGHT",-90,-380,"激活","TrGCDCheckTooltip",TrufiGCDChSave["TooltipEnable"])
		TrGCDGUI.CheckTooltip:SetScript("OnClick", function () TrufiGCDChSave["TooltipEnable"] = ValueReverse(TrufiGCDChSave["TooltipEnable"]) end)
		TrGCDGUI.CheckTooltip.tooltipText = ('悬停图标时显示工具提示')
		TrGCDGUI.CheckTooltipMove = AddCheckButton(TrGCDGUI,"TOPRIGHT",-90,-410,"停止图标","TrGCDCheckTooltipMove",TrufiGCDChSave["TooltipStopMove"])
		TrGCDGUI.CheckTooltipMove:SetScript("OnClick", function () TrufiGCDChSave["TooltipStopMove"] = ValueReverse(TrufiGCDChSave["TooltipStopMove"]) end)
		TrGCDGUI.CheckTooltipMove.tooltipText = ('将图标悬停时停止移动图标')
		TrGCDGUI.CheckTooltipID = AddCheckButton(TrGCDGUI,"TOPRIGHT",-90,-440,"拼写 ID","TrGCDCheckTooltipSpellID",TrufiGCDChSave["TooltipSpellID"])
		TrGCDGUI.CheckTooltipID:SetScript("OnClick", function () TrufiGCDChSave["TooltipSpellID"] = ValueReverse(TrufiGCDChSave["TooltipSpellID"]) end)
		TrGCDGUI.CheckTooltipID.tooltipText = ('悬停图标时将拼写ID写入聊天')
		-- чек на скролл иконок
		TrGCDGUI.CheckModScroll = AddCheckButton(TrGCDGUI,"TOPRIGHT",-90,-80,"滚动图标","TrGCDCheckModScroll",TrufiGCDChSave["ModScroll"])
		TrGCDGUI.CheckModScroll:SetScript("OnClick", function () TrufiGCDChSave["ModScroll"] = ValueReverse(TrufiGCDChSave["ModScroll"]) end)
		TrGCDGUI.CheckModScroll.tooltipText = ('图标就会消失')
		-- Галочки EnableIn: Enable, World, PvE, Arena, Bg
		TrGCDGUI.CheckEnableIn = {}
		TrGCDGUI.CheckEnableIn.Text = TrGCDGUI:CreateFontString(nil, "BACKGROUND")
		TrGCDGUI.CheckEnableIn.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
		TrGCDGUI.CheckEnableIn.Text:SetText("启用:")
		TrGCDGUI.CheckEnableIn.Text:SetPoint("TOPRIGHT", TrGCDGUI, "TOPRIGHT",-53, -175)
		TrGCDGUI.CheckEnableIn[0] = AddCheckButton(TrGCDGUI, "TOPRIGHT",-90,-140,"启用插件","trgcdcheckenablein0",TrufiGCDChSave["EnableIn"]["Enable"])
		TrGCDGUI.CheckEnableIn[0]:SetScript("OnClick", function ()
			TrufiGCDChSave["EnableIn"]["Enable"] = ValueReverse(TrufiGCDChSave["EnableIn"]["Enable"])
			TrGCDCheckToEnableAddon(0)
		end)
		TrGCDGUI.CheckEnableIn[1] = AddCheckButton(TrGCDGUI, "TOPRIGHT",-90,-200,"世界","trgcdcheckenablein1",TrufiGCDChSave["EnableIn"]["World"])
		TrGCDGUI.CheckEnableIn[1]:SetScript("OnClick", function ()
			TrufiGCDChSave["EnableIn"]["World"] = ValueReverse(TrufiGCDChSave["EnableIn"]["World"])
			TrGCDCheckToEnableAddon(1)
		end)
		TrGCDGUI.CheckEnableIn[2] = AddCheckButton(TrGCDGUI, "TOPRIGHT",-90,-230,"群","trgcdcheckenablein2",TrufiGCDChSave["EnableIn"]["PvE"])
		TrGCDGUI.CheckEnableIn[2]:SetScript("OnClick", function ()
			TrufiGCDChSave["EnableIn"]["PvE"] = ValueReverse(TrufiGCDChSave["EnableIn"]["PvE"])
			TrGCDCheckToEnableAddon(2)
		end)		
		TrGCDGUI.CheckEnableIn[5] = AddCheckButton(TrGCDGUI, "TOPRIGHT",-90,-260,"袭击","trgcdcheckenablein5",TrufiGCDChSave["EnableIn"]["Raid"])
		TrGCDGUI.CheckEnableIn[5]:SetScript("OnClick", function ()
			TrufiGCDChSave["EnableIn"]["Raid"] = ValueReverse(TrufiGCDChSave["EnableIn"]["Raid"])
			TrGCDCheckToEnableAddon(5)
		end)
		TrGCDGUI.CheckEnableIn[3] = AddCheckButton(TrGCDGUI, "TOPRIGHT",-90,-290,"竞技场","trgcdcheckenablein3",TrufiGCDChSave["EnableIn"]["Arena"])
		TrGCDGUI.CheckEnableIn[3]:SetScript("OnClick", function ()
			TrufiGCDChSave["EnableIn"]["Arena"] = ValueReverse(TrufiGCDChSave["EnableIn"]["Arena"])
			TrGCDCheckToEnableAddon(3)
		end)	
		TrGCDGUI.CheckEnableIn[4] = AddCheckButton(TrGCDGUI, "TOPRIGHT",-90,-320,"战场","trgcdcheckenablein4",TrufiGCDChSave["EnableIn"]["Bg"])
		TrGCDGUI.CheckEnableIn[4]:SetScript("OnClick", function ()
			TrufiGCDChSave["EnableIn"]["Bg"] = ValueReverse(TrufiGCDChSave["EnableIn"]["Bg"])
			TrGCDCheckToEnableAddon(4)
		end)
		--复选标记、幻灯片和菜单签名
		for i=1,4 do
			_G["TrGCDGUI.Text" .. i] = TrGCDGUI:CreateFontString(nil, "BACKGROUND")
			_G["TrGCDGUI.Text" .. i]:SetFont("Fonts\\FRIZQT__.TTF", 12)
		end
		_G["TrGCDGUI.Text1"]:SetText("激活")
		_G["TrGCDGUI.Text1"]:SetPoint("TOPLEFT", TrGCDGUI, "TOPLEFT",20, -65)		
		_G["TrGCDGUI.Text2"]:SetText("渐弱")
		_G["TrGCDGUI.Text2"]:SetPoint("TOPLEFT", TrGCDGUI, "TOPLEFT",105, -65)	
		_G["TrGCDGUI.Text3"]:SetText("图标大小")
		_G["TrGCDGUI.Text3"]:SetPoint("TOPLEFT", TrGCDGUI, "TOPLEFT",245, -65)	
		_G["TrGCDGUI.Text4"]:SetText("图标数量")
		_G["TrGCDGUI.Text4"]:SetPoint("TOPLEFT", TrGCDGUI, "TOPLEFT",390, -65)	
		-- 按show/hide键后的框架
		TrGCDFixEnable = CreateFrame ("Frame", nil, UIParent)
		TrGCDFixEnable:SetHeight(50)
		TrGCDFixEnable:SetWidth(160)
		TrGCDFixEnable:SetPoint("TOP", UIParent, "TOP",0, -150)		
		TrGCDFixEnable:Hide()	
		TrGCDFixEnable:RegisterForDrag("LeftButton")
		TrGCDFixEnable:SetScript("OnDragStart", TrGCDFixEnable.StartMoving)
		TrGCDFixEnable:SetScript("OnDragStop", TrGCDFixEnable.StopMovingOrSizing)	
		TrGCDFixEnable:SetMovable(true)
		TrGCDFixEnable:EnableMouse(true)
		TrGCDFixEnable.Texture = TrGCDFixEnable:CreateTexture(nil, "BACKGROUND")
		TrGCDFixEnable.Texture:SetAllPoints(TrGCDFixEnable)
		TrGCDFixEnable.Texture:SetColorTexture(0, 0, 0)
		TrGCDFixEnable.Texture:SetAlpha(0.5)
		TrGCDFixEnable.Button = AddButton(TrGCDFixEnable,"BOTTOM",0,5,22,150,"Return to options",12,"TrufiGCD")
		TrGCDFixEnable.Button:SetScript("OnClick", function () InterfaceOptionsFrame_OpenToCategory(TrGCDGUI) end)		
		TrGCDFixEnable.Button.Text:SetPoint("TOP", TrGCDFixEnable, "TOP",0, -5)
		--checkbutton enable/disable
		TrGCDGUI.checkenable = {}
		TrGCDGUI.checkenablename = {}
		TrGCDGUI.menu = {}
		TrGCDGUI.sizeslider = {}
		TrGCDGUI.widthslider = {}
		for i=1,12 do
			TrGCDGUI.checkenable[i] = AddCheckButton(TrGCDGUI, "TOPLEFT",10,-50-i*40,TrGCDQueueOpt[i].text,("checkenable"..i),TrGCDQueueOpt[i].enable)
			TrGCDGUI.checkenable[i]:SetScript("OnClick", function () TrGCDCheckEnableClick(i) end)
			--dropdown menues
			TrGCDGUI.menu[i] = CreateFrame("FRAME", ("TrGCDGUImenu"..i), TrGCDGUI, "UIDropDownMenuTemplate")
			TrGCDGUI.menu[i]:SetPoint("TOPLEFT", TrGCDGUI, "TOPLEFT",70, -50-i*40)
			UIDropDownMenu_SetWidth(TrGCDGUI.menu[i], 55)
			UIDropDownMenu_SetText(TrGCDGUI.menu[i], TrGCDQueueOpt[i].fade)
			UIDropDownMenu_Initialize(TrGCDGUI.menu[i], function(self, level, menuList)
				local info = UIDropDownMenu_CreateInfo()
				info.text = "Left"
				info.menuList = 1
				info.notCheckable = true
				info.func = function() TrGCDFadeMenuWasCheck(i, "Left") end
				UIDropDownMenu_AddButton(info)		
				info.text = "Right"
				info.menuList = 2
				info.func = function() TrGCDFadeMenuWasCheck(i, "Right") end
				UIDropDownMenu_AddButton(info)	
				info.text = "Up"
				info.menuList = 3
				info.func = function() TrGCDFadeMenuWasCheck(i, "Up") end
				UIDropDownMenu_AddButton(info)	
				info.text = "Down"
				info.menuList = 4
				info.func = function() TrGCDFadeMenuWasCheck(i, "Down") end			
				UIDropDownMenu_AddButton(info)
			end)
			--Size Slider
			TrGCDGUI.sizeslider[i] = CreateFrame("Slider", ("TrGCDGUIsizeslider" .. i), TrGCDGUI, "OptionsSliderTemplate")
			TrGCDGUI.sizeslider[i]:SetWidth(170)
			TrGCDGUI.sizeslider[i]:SetPoint("TOPLEFT", TrGCDGUI, "TOPLEFT",190, -55-i*40)
			TrGCDGUI.sizeslider[i].tooltipText = ('Size icons ' .. TrGCDQueueOpt[i].text)
			getglobal(TrGCDGUI.sizeslider[i]:GetName() .. 'Low'):SetText('10')
			getglobal(TrGCDGUI.sizeslider[i]:GetName() .. 'High'):SetText('100')
			getglobal(TrGCDGUI.sizeslider[i]:GetName() .. 'Text'):SetText(TrGCDQueueOpt[i].size)
			TrGCDGUI.sizeslider[i]:SetMinMaxValues(10,100)
			TrGCDGUI.sizeslider[i]:SetValueStep(1)
			TrGCDGUI.sizeslider[i]:SetValue(TrGCDQueueOpt[i].size)
			TrGCDGUI.sizeslider[i]:SetScript("OnValueChanged", function (self,value) TrGCDSpSizeChanged(i,value) end)
			TrGCDGUI.sizeslider[i]:Show()
			--Width Slider
			TrGCDGUI.widthslider[i] = CreateFrame("Slider", ("TrGCDGUIwidthslider" .. i), TrGCDGUI, "OptionsSliderTemplate")
			TrGCDGUI.widthslider[i]:SetWidth(100)
			TrGCDGUI.widthslider[i]:SetPoint("TOPLEFT", TrGCDGUI, "TOPLEFT",390, -55-i*40)
			TrGCDGUI.widthslider[i].tooltipText = ('Spell icons in queue ' .. TrGCDQueueOpt[i].text)
			getglobal(TrGCDGUI.widthslider[i]:GetName() .. 'Low'):SetText('1')
			getglobal(TrGCDGUI.widthslider[i]:GetName() .. 'High'):SetText('8')
			getglobal(TrGCDGUI.widthslider[i]:GetName() .. 'Text'):SetText(TrGCDQueueOpt[i].width)
			TrGCDGUI.widthslider[i]:SetMinMaxValues(1,8)
			TrGCDGUI.widthslider[i]:SetValueStep(1)
			TrGCDGUI.widthslider[i]:SetValue(TrGCDQueueOpt[i].width)
			TrGCDGUI.widthslider[i]:SetScript("OnValueChanged", function (self,value) TrGCDSpWidthChanged(i,value) end)
			TrGCDGUI.widthslider[i]:Show()
		end
		InterfaceOptions_AddCategory(TrGCDGUI)
		--添加Spell Black List选项卡
		TrGCDGUI.BL = CreateFrame ("Frame", nil, UIParent, "OptionsBoxTemplate")
		TrGCDGUI.BL:Hide()
		TrGCDGUI.BL.name = "黑名单"
		TrGCDGUI.BL.parent = "TrufiGCD"
		TrGCDGUI.BL.ScrollBD = CreateFrame ("Frame", nil, TrGCDGUI.BL)
		TrGCDGUI.BL.ScrollBD:SetPoint("TOPLEFT", TrGCDGUI.BL, "TOPLEFT",10, -25)
		TrGCDGUI.BL.ScrollBD:SetWidth(200)
		TrGCDGUI.BL.ScrollBD:SetHeight(501)		
		TrGCDGUI.BL.ScrollBD:SetBackdrop({bgFile = nil,
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
			tile = true, tileSize = 16, edgeSize = 16, 
			insets = {left = 0, right = 0, top = 0, bottom = 0}})		
		TrGCDGUI.BL.Scroll = CreateFrame ("ScrollFrame", nil, TrGCDGUI.BL)
		TrGCDGUI.BL.Scroll:SetPoint("TOPLEFT", TrGCDGUI.BL, "TOPLEFT",10, -30)
		TrGCDGUI.BL.Scroll:SetWidth(200)
		TrGCDGUI.BL.Scroll:SetHeight(488)
		TrGCDGUI.BL.Scroll.ScrollBar = CreateFrame("Slider", "TrGCDBLScroll", TrGCDGUI.BL.Scroll, "UIPanelScrollBarTemplate") 
		TrGCDGUI.BL.Scroll.ScrollBar:SetPoint("TOPLEFT", TrGCDGUI.BL.Scroll, "TOPRIGHT", 1, -16) 
		TrGCDGUI.BL.Scroll.ScrollBar:SetPoint("BOTTOMLEFT", TrGCDGUI.BL.Scroll, "BOTTOMRIGHT", 1, 16) 
		TrGCDGUI.BL.Scroll.ScrollBar:SetMinMaxValues(1, 470) 
		TrGCDGUI.BL.Scroll.ScrollBar:SetValueStep(1) 
		TrGCDGUI.BL.Scroll.ScrollBar.Bg = TrGCDGUI.BL.Scroll.ScrollBar:CreateTexture(nil, "BACKGROUND") 
		TrGCDGUI.BL.Scroll.ScrollBar.Bg:SetAllPoints(TrGCDGUI.BL.Scroll.ScrollBar) 
		TrGCDGUI.BL.Scroll.ScrollBar.Bg:SetColorTexture(0, 0, 0, 0.4)
		TrGCDGUI.BL.Scroll.ScrollBar:SetValue(0) 
		TrGCDGUI.BL.Scroll.ScrollBar:SetScript("OnValueChanged", function (self, value) 
			self:GetParent():SetVerticalScroll(value) 
		end) 
		TrGCDGUI.BL.List = CreateFrame ("Frame", nil, TrGCDGUI.BL.Scroll)
		--TrGCDGUI.BL.List:SetPoint("TOPLEFT", TrGCDGUI.BL.Scroll, "TOPLEFT",10, -35)
		TrGCDGUI.BL.List:SetWidth(200)
		TrGCDGUI.BL.List:SetHeight(958)
		TrGCDGUI.BL.List.Text = TrGCDGUI.BL.List:CreateFontString(nil, "BACKGROUND")
		TrGCDGUI.BL.List.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
		TrGCDGUI.BL.List.Text:SetText("黑名单")
		TrGCDGUI.BL.List.Text:SetPoint("TOPLEFT", TrGCDGUI.BL.List, "TOPLEFT", 15, 15)
		TrGCDGUI.BL.Spell = {}
		TrGCDGUI.BL.TextSpell = TrGCDGUI.BL:CreateFontString(nil, "BACKGROUND")
		TrGCDGUI.BL.TextSpell:SetFont("Fonts\\FRIZQT__.TTF", 12)
		TrGCDGUI.BL.TextSpell:SetText("选择技能")
		TrGCDGUI.BL.Delete = AddButton(TrGCDGUI.BL,"TOPLEFT",260,-130,22,100,"Delete")
		TrGCDGUI.BL.TextSpell:SetPoint("TOPLEFT", TrGCDGUI.BL.Delete, "TOPLEFT", 5, 15)
		for i=1,60 do
			TrGCDGUI.BL.Spell[i] = AddButton(TrGCDGUI.BL.List,"TOP",0,(-(i-1)*16),15,192,_,11," ",true)
			TrGCDGUI.BL.Spell[i]:Disable()
			TrGCDGUI.BL.Spell[i].Number = i
			TrGCDGUI.BL.Spell[i].Text:SetAllPoints(TrGCDGUI.BL.Spell[i])
			TrGCDGUI.BL.Spell[i].Texture = TrGCDGUI.BL.Spell[i]:CreateTexture(nil, "BACKGROUND")
			TrGCDGUI.BL.Spell[i].Texture:SetAllPoints(TrGCDGUI.BL.Spell[i])
			TrGCDGUI.BL.Spell[i].Texture:SetColorTexture(255, 210, 0)
			TrGCDGUI.BL.Spell[i].Texture:SetAlpha(0)
			TrGCDGUI.BL.Spell[i]:SetScript("OnEnter", function (self) if (BLSpSel ~= self) then self.Texture:SetAlpha(0.3) end end)
			TrGCDGUI.BL.Spell[i]:SetScript("OnLeave", function (self) if (BLSpSel ~= self) then self.Texture:SetAlpha(0) end end)			
			TrGCDGUI.BL.Spell[i]:SetScript("OnClick", function (self) 
				if (BLSpSel ~= nil) then BLSpSel.Texture:SetAlpha(0) end
				BLSpSel = self 
				self.Texture:SetAlpha(0.6) 
				TrGCDGUI.BL.TextSpell:SetText(self.Text:GetText())
			end)	
		end	
		TrGCDLoadBlackList()		
		TrGCDGUI.BL.Delete:SetScript("OnClick", function () 
			if (BLSpSel ~= nil) then
				table.remove(TrGCDBL, BLSpSel.Number)
				TrGCDGUI.BL.TextSpell:SetText("选择技能")
				TrGCDLoadBlackList()
			end
		end) 
		TrGCDGUI.BL.Scroll:SetScrollChild(TrGCDGUI.BL.List)
		TrGCDGUI.BL.AddEdit = CreateFrame("EditBox", nil, TrGCDGUI.BL, "InputBoxTemplate")
		TrGCDGUI.BL.AddEdit:SetWidth(200)
		TrGCDGUI.BL.AddEdit:SetHeight(20)
		TrGCDGUI.BL.AddEdit:SetPoint("TOPLEFT", TrGCDGUI.BL, "TOPLEFT", 265, -200)
		TrGCDGUI.BL.AddEdit:SetAutoFocus(false)
		TrGCDGUI.BL.AddButt = AddButton(TrGCDGUI.BL,"TOPLEFT",260,-225,22,100,"Add",12,"输入技能名称或技能ID")
		TrGCDGUI.BL.AddButt.Text:SetPoint("TOPLEFT",TrGCDGUI.BL.AddButt,"TOPLEFT", 5, 40)
		TrGCDGUI.BL.AddButt:SetScript("OnClick", function (self) TrGCDBLAddSpell(self) end)
		TrGCDGUI.BL.AddEdit:SetScript("OnEnterPressed", function (self) TrGCDBLAddSpell(self) end)
		TrGCDGUI.BL.AddEdit:SetScript("OnEscapePressed", function (self) self:ClearFocus() end)	
		TrGCDGUI.BL.AddButt.Text2 = TrGCDGUI.BL.List:CreateFontString(nil, "BACKGROUND")
		TrGCDGUI.BL.AddButt.Text2:SetFont("Fonts\\FRIZQT__.TTF", 11)
		--TrGCDGUI.BL.AddButt.Text2:SetText("Blacklist can be loaded from the saved settings,\nbut does not restore the default.")
		TrGCDGUI.BL.AddButt.Text2:SetPoint("BOTTOMLEFT", TrGCDGUI.BL.AddButt, "BOTTOMLEFT", 0, -35)
		--кнопка загрузки настроек сохраненных в кэше
		TrGCDGUI.BL.ButtonLoad = AddButton(TrGCDGUI.BL,"TOPRIGHT",-145,-30,22,100,"Load",10,"载入缓存黑名单")
		TrGCDGUI.BL.ButtonLoad:SetScript("OnClick", TrGCDBLLoadSetting) 
		--кнопки сохранения настроек в кэш
		TrGCDGUI.BL.ButtonSave = AddButton(TrGCDGUI.BL,"TOPRIGHT",-260,-30,22,100,"Save",10,"将黑名单保存到缓存")
		TrGCDGUI.BL.ButtonSave:SetScript("OnClick", TrGCDBLSaveSetting) 
		--кнопка восстановления стандартных настроек
		TrGCDGUI.BL.ButtonRes = AddButton(TrGCDGUI.BL,"TOPRIGHT",-30,-30,22,100,"Default",10,"恢复默认黑名单")
		TrGCDGUI.BL.ButtonRes:SetScript("OnClick", function () TrGCDBLDefaultSetting() TrGCDLoadBlackList() end) 		
		InterfaceOptions_AddCategory(TrGCDGUI.BL)
		-- Creating event enter arena/bg event frame
		TrGCDEnterEventFrame = CreateFrame("Frame", nil, UIParent)
		TrGCDEnterEventFrame:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
		TrGCDEnterEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		TrGCDEnterEventFrame:SetScript("OnEvent", TrGCDEnterEventHandler)
		-- Creating event spell frame
		TrGCDEventFrame = CreateFrame("Frame", nil, UIParent)
		TrGCDEventFrame:RegisterEvent("UNIT_SPELLCAST_START")
		TrGCDEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		TrGCDEventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
		TrGCDEventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		TrGCDEventFrame:SetScript("OnEvent", TrGCDEventHandler)
		TrGCDEventFrame:SetScript("OnUpdate", TrGCDUpdate)
		TrGCDEventBuffFrame = CreateFrame("Frame", nil, UIParent)
		TrGCDEventBuffFrame:RegisterEvent("UNIT_AURA")
		TrGCDEventBuffFrame:SetScript("OnEvent", TrGCDEventBuffHandler)		
		--Creating TrGCDQueueFr i =
		--1 - player, 2 - party1, 3 - party2
		--5 - arena1, 6 - arena2, 7 - arena3
		--11 - target, 12 - focus
		TrGCDQueueFr = {}
		TrGCDIcon = {}
		TrGCDi = {} --TrGCDIcons计数器
		TrGCDQueueFirst = {} -- 排在第一位
		TrGCDQueueFirstI = {} --开始排队，然后移动，就像Spell在TrGCDQueuFr中所做的那样。
		for i=1,12 do
			--if (TrGCDQueueOpt[i].enable) then
				TrGCDQueueFr[i] = CreateFrame("Frame", nil, UIParent)
				TrGCDResizeQFr(i)
				TrGCDQueueFr[i].texture = TrGCDQueueFr[i]:CreateTexture(nil, "BACKGROUND")
				TrGCDQueueFr[i].texture:SetAllPoints(TrGCDQueueFr[i])
				TrGCDQueueFr[i].texture:SetColorTexture(0, 0, 0)
				TrGCDQueueFr[i].texture:SetAlpha(0)
				TrGCDQueueFr[i].text = TrGCDQueueFr[i]:CreateFontString(nil, "BACKGROUND")
				TrGCDQueueFr[i].text:SetFont("Fonts\\FRIZQT__.TTF", 9)
				TrGCDQueueFr[i].text:SetText(TrGCDQueueOpt[i].text)
				TrGCDQueueFr[i].text:SetAllPoints(TrGCDQueueFr[i])
				TrGCDQueueFr[i].text:SetAlpha(0)
				TrGCDQueueFr[i]:RegisterForDrag("LeftButton")
				TrGCDQueueFr[i]:SetScript("OnDragStart", TrGCDQueueFr[i].StartMoving)
				TrGCDQueueFr[i]:SetScript("OnDragStop", TrGCDQueueFr[i].StopMovingOrSizing)
				TrGCDQueueFr[i]:SetPoint(TrGCDQueueOpt[i].point, UIParent, TrGCDQueueOpt[i].point, TrGCDQueueOpt[i].x, TrGCDQueueOpt[i].y)
				--TrGCDIcon[i]
				TrGCDIcon[i] = {}
				TrGCDi[i] = 1
				TrGCDSpStop[i] = 0
				TrGCDSpStopTime[i] = GetTime()
				TrGCDCastSpBanTime[i] = GetTime()
				TrGCDInsSp["time"][i] = GetTime()
				TrGCDIconOnEnter[i] = true
				TrGCDTimeuseSpamSpell[i] = {}
				for k = 1,10 do
					TrGCDIcon[i][k] = CreateFrame("Button", nil, TrGCDQueueFr[i])
					TrGCDIcon[i][k]:SetHeight(TrGCDQueueOpt[i].size)
					TrGCDIcon[i][k]:SetWidth(TrGCDQueueOpt[i].size)
					TrGCDIcon[i][k].texture = TrGCDIcon[i][k]:CreateTexture(nil, "BACKGROUND")
					TrGCDIcon[i][k].texture:SetAllPoints(TrGCDIcon[i][k])
					TrGCDIcon[i][k].texture2 = TrGCDIcon[i][k]:CreateTexture(nil, "BORDER")
					TrGCDIcon[i][k].texture2:SetAllPoints(TrGCDIcon[i][k].texture)
					TrGCDIcon[i][k].texture2:SetTexture(cross)
					TrGCDIcon[i][k].texture2:SetAlpha(1)
					TrGCDIcon[i][k].texture2:Hide()
					TrGCDIcon[i][k].texture2.show = false
					TrGCDIcon[i][k]:Hide()
					TrGCDIcon[i][k].show = false
					TrGCDIcon[i][k].x = 0
					TrGCDIcon[i][k].TimeStart = 0
					TrGCDIcon[i][k].spellID = 0			
					TrGCDIcon[i][k]:SetScript("OnEnter", function (self)
						if (TrufiGCDChSave["TooltipEnable"] == true) then
							GameTooltip_SetDefaultAnchor(GameTooltip, self)
							GameTooltip:SetSpellByID(self.spellID, false, false, true)
							GameTooltip:Show()
							if (TrufiGCDChSave["TooltipStopMove"] == true) then
								TrGCDIconOnEnter[i] = false
							end							
							if (TrufiGCDChSave["TooltipSpellID"] == true) then
								if (self.spellID ~= nil) then 
									--print(GetSpellLink(self.spellID) .. ' ID: ' .. self.spellID,"GetSpellLink(self.spellID)") 

								end
							end
						end
					end)
					TrGCDIcon[i][k]:SetScript("OnLeave", function () GameTooltip_Hide() TrGCDIconOnEnter[i] = true end)
					if Masque then TrGCDMasqueIcons:AddButton(TrGCDIcon[i][k], {Icon = TrGCDIcon[i][k].texture}) end
				end
				TrGCDQueueFirst[i] = {}
				TrGCDQueueFirstI[i] = 1 --начало очереди, потом сдвигается, как спелл проходит в TrGCDQueueFr
				TrGCDBufferIcon[i] = 0.0
				TrGCDCastSp[i] = 1 -- 0 - каст идет, 1 - каст прошел и не идет
			--end
		end

		TrGCDQueueFr[11]:RegisterEvent("PLAYER_TARGET_CHANGED")
		TrGCDQueueFr[11]:SetScript("OnEvent", function() 
			TrGCDClear(11)
			if (TrGCDQueueOpt[11].enable) then TrGCDPlayerTarFocDetect(11) end
		end)		
		TrGCDQueueFr[12]:RegisterEvent("PLAYER_FOCUS_CHANGED")
		TrGCDQueueFr[12]:SetScript("OnEvent", function()
			TrGCDClear(12) 
			if (TrGCDQueueOpt[12].enable) then TrGCDPlayerTarFocDetect(12) end
		end)
	end
end
function TrGCDCheckToEnableAddon(t) -- 检查EnableIn机床是否已启用
	if (TrufiGCDChSave["EnableIn"]["Enable"] == false) then TrGCDEnable = false
	elseif (PlayerDislocation == 1) then TrGCDEnable = TrufiGCDChSave["EnableIn"]["World"]
	elseif (PlayerDislocation == 2) then TrGCDEnable = TrufiGCDChSave["EnableIn"]["PvE"]
	elseif (PlayerDislocation == 3) then TrGCDEnable = TrufiGCDChSave["EnableIn"]["Arena"]
	elseif (PlayerDislocation == 4) then TrGCDEnable = TrufiGCDChSave["EnableIn"]["Bg"]
	elseif (PlayerDislocation == 5) then TrGCDEnable = TrufiGCDChSave["EnableIn"]["Raid"]
	end
	if (t ~= nil) then
		if ((PlayerDislocation == t) or (t == 0)) then
			for i=1,12 do TrGCDClear(i) end
		end
	end
end
function TrGCDEnterEventHandler(self, event, ...) -- 伊文特，当球员走上赛场，竞技场，进场的时候，或者相反的情况下，他走了出来。
	local _, PlayerLocation = IsInInstance()
	if (event == "PLAYER_ENTERING_BATTLEGROUND") then
		if (PlayerLocation == "arena") then
			PlayerDislocation = 3
			if (TrufiGCDChSave["EnableIn"]["Arena"]) then TrGCDEnable = true
			else TrGCDEnable = false end
		elseif (PlayerLocation == "pvp") then
			PlayerDislocation = 4
			if (TrufiGCDChSave["EnableIn"]["Bg"]) then TrGCDEnable = true
			else TrGCDEnable = false end
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
		if (PlayerLocation == "party") then
			PlayerDislocation = 2
			if (TrufiGCDChSave["EnableIn"]["PvE"]) then TrGCDEnable = true
			else TrGCDEnable = false end
		elseif (PlayerLocation == "raid") then
			PlayerDislocation = 5
			if (TrufiGCDChSave["EnableIn"]["Raid"]) then TrGCDEnable = true
			else TrGCDEnable = false end
		elseif ((PlayerLocation ~= "arena") or (PlayerLocation ~= "pvp")) then
			PlayerDislocation = 1
			if (TrufiGCDChSave["EnableIn"]["World"]) then TrGCDEnable = true
			else TrGCDEnable = false end
		end
	end
end
function TrGCDLoadBlackList() -- 下载黑名单
	for i=1,60 do
		if (TrGCDBL[i] ~= nil) then
			local spellname = GetSpellInfo(TrGCDBL[i])
			if (spellname == nil) then spellname = TrGCDBL[i] end
			TrGCDGUI.BL.Spell[i]:Enable()
			TrGCDGUI.BL.Spell[i].Text:SetText(spellname)
		else
			TrGCDGUI.BL.Spell[i]:Disable()
			TrGCDGUI.BL.Spell[i].Text:SetText(nil)
			TrGCDGUI.BL.Spell[i].Texture:SetAlpha(0)
		end
	end
end
function TrGCDBLAddSpell(self)
	if (TrGCDGUI.BL.AddEdit:GetText() ~= nil) then
		local spellname = TrGCDGUI.BL.AddEdit:GetText()
		if (#TrGCDBL < 60) then
		--local spellicon = select(3, GetSpellInfo(TrGCDGUI.BL.AddEdit:GetText()))
		--if (spellicon ~= nil) then
			table.insert(TrGCDBL, spellname)
			TrGCDLoadBlackList()
			--TrGCDGUI.BL.AddEdit:SetText("")
			TrGCDGUI.BL.AddEdit:ClearFocus()
			--TrGCDGUI.BL.AddButt.Text2:SetText()
		--else TrGCDGUI.BL.AddButt.Text2:SetText('Spell not find, please try again.') end
		end
	end
end
function TrGCDBLSaveSetting()
	if (TrufiGCDGlSave == nil) then TrufiGCDGlSave = {} end
	TrufiGCDGlSave["TrGCDBL"] = {}
	for i=1,#TrGCDBL do	TrufiGCDGlSave["TrGCDBL"][i] = TrufiGCDChSave["TrGCDBL"][i]	end
end
function TrGCDBLLoadSetting()
	if ((TrufiGCDChSave ~= nil) and (TrufiGCDGlSave["TrGCDQueueFr"] ~= nil)) then
		for i=1,#TrufiGCDGlSave["TrGCDBL"] do TrufiGCDChSave["TrGCDBL"][i] = TrufiGCDGlSave["TrGCDBL"][i] end
		if (#TrufiGCDGlSave["TrGCDBL"] < #TrufiGCDChSave["TrGCDBL"]) then 
			for i=(#TrufiGCDGlSave["TrGCDBL"]+1),#TrufiGCDChSave["TrGCDBL"] do TrufiGCDChSave["TrGCDBL"][i] = nil end 
		end
		TrGCDLoadBlackList()
	end
end
function TrGCDBLDefaultSetting()
	if (TrufiGCDChSave == nil) then TrufiGCDChSave = {} end
	TrufiGCDChSave["TrGCDBL"] = {}
	TrGCDBL = TrufiGCDChSave["TrGCDBL"]
	TrGCDBL[1] = 6603 --автоатака
	TrGCDBL[2] = 75 --автовыстрел
	TrGCDBL[3] = 7384 --превосходствo
end
function TrGCDSaveSettings()
	if (TrufiGCDGlSave == nil) then TrufiGCDGlSave = {} end
	TrufiGCDGlSave["TrGCDQueueFr"] = {}
	for i=1,12 do
		TrufiGCDGlSave["TrGCDQueueFr"][i] = {}
		TrufiGCDGlSave["TrGCDQueueFr"][i]["x"] = TrGCDQueueOpt[i].x
		TrufiGCDGlSave["TrGCDQueueFr"][i]["y"] = TrGCDQueueOpt[i].y	
		TrufiGCDGlSave["TrGCDQueueFr"][i]["point"] = TrGCDQueueOpt[i].point
		TrufiGCDGlSave["TrGCDQueueFr"][i]["enable"] = TrGCDQueueOpt[i].enable
		TrufiGCDGlSave["TrGCDQueueFr"][i]["text"] = TrGCDQueueOpt[i].text
		TrufiGCDGlSave["TrGCDQueueFr"][i]["fade"] = TrGCDQueueOpt[i].fade
		TrufiGCDGlSave["TrGCDQueueFr"][i]["size"] = TrGCDQueueOpt[i].size
		TrufiGCDGlSave["TrGCDQueueFr"][i]["width"] = TrGCDQueueOpt[i].width
		TrufiGCDGlSave["TrGCDQueueFr"][i]["speed"] = TrGCDQueueOpt[i].speed	
	end
	TrufiGCDGlSave["TooltipEnable"] = TrufiGCDChSave["TooltipEnable"]
	TrufiGCDGlSave["TooltipStopMove"] = TrufiGCDChSave["TooltipStopMove"]
	TrufiGCDGlSave["TooltipSpellID"] = TrufiGCDChSave["TooltipSpellID"]
	TrufiGCDGlSave["EnableIn"] = {}
	TrufiGCDGlSave["EnableIn"]["PvE"] = TrufiGCDChSave["EnableIn"]["PvE"]
	TrufiGCDGlSave["EnableIn"]["Raid"] = TrufiGCDChSave["EnableIn"]["Raid"]
	TrufiGCDGlSave["EnableIn"]["Arena"] = TrufiGCDChSave["EnableIn"]["Arena"]
	TrufiGCDGlSave["EnableIn"]["Bg"] = TrufiGCDChSave["EnableIn"]["Bg"]
	TrufiGCDGlSave["EnableIn"]["World"] = TrufiGCDChSave["EnableIn"]["World"]
	TrufiGCDGlSave["EnableIn"]["Enable"] = TrufiGCDChSave["EnableIn"]["Enable"]
	TrufiGCDGlSave["ModScroll"] = TrufiGCDChSave["ModScroll"]
end
function TrGCDLoadSettings()
	if ((TrufiGCDGlSave ~= nil) and (TrufiGCDGlSave["TrGCDQueueFr"] ~= nil)) then
		for i=1,12 do
			TrGCDQueueOpt[i].x = TrufiGCDGlSave["TrGCDQueueFr"][i]["x"]
			TrGCDQueueOpt[i].y = TrufiGCDGlSave["TrGCDQueueFr"][i]["y"]
			TrGCDQueueOpt[i].point = TrufiGCDGlSave["TrGCDQueueFr"][i]["point"]
			TrGCDQueueOpt[i].enable = TrufiGCDGlSave["TrGCDQueueFr"][i]["enable"]
			TrGCDQueueOpt[i].text = TrufiGCDGlSave["TrGCDQueueFr"][i]["text"]
			TrGCDQueueOpt[i].fade = TrufiGCDGlSave["TrGCDQueueFr"][i]["fade"]
			TrGCDQueueOpt[i].size = TrufiGCDGlSave["TrGCDQueueFr"][i]["size"]
			TrGCDQueueOpt[i].width = TrufiGCDGlSave["TrGCDQueueFr"][i]["width"]
			TrGCDQueueOpt[i].speed = TrufiGCDGlSave["TrGCDQueueFr"][i]["speed"]
			TrufiGCDChSave["TrGCDQueueFr"] = TrGCDQueueOpt
		end
		if (TrufiGCDGlSave["EnableIn"] ~= nil) then
			TrufiGCDChSave["TooltipEnable"] = TrufiGCDGlSave["TooltipEnable"]
			TrufiGCDChSave["EnableIn"] = {}
			TrufiGCDChSave["EnableIn"]["PvE"] = TrufiGCDGlSave["EnableIn"]["PvE"]
			TrufiGCDChSave["EnableIn"]["Arena"] = TrufiGCDGlSave["EnableIn"]["Arena"]
			TrufiGCDChSave["EnableIn"]["Bg"] = TrufiGCDGlSave["EnableIn"]["Bg"]
			TrufiGCDChSave["EnableIn"]["World"] = TrufiGCDGlSave["EnableIn"]["World"]
			TrufiGCDChSave["EnableIn"]["Enable"] = TrufiGCDGlSave["EnableIn"]["Enable"]
			if (TrufiGCDGlSave["EnableIn"]["Raid"] ~= nil) then
				TrufiGCDChSave["EnableIn"]["Raid"] = TrufiGCDGlSave["EnableIn"]["Raid"]		
				TrufiGCDChSave["TooltipStopMove"] = TrufiGCDGlSave["TooltipStopMove"]
				TrufiGCDChSave["TooltipSpellID"] = TrufiGCDGlSave["TooltipSpellID"]
			end
		end
		if (TrufiGCDGlSave["ModScroll"] ~= nil) then
			TrufiGCDChSave["ModScroll"] = TrufiGCDGlSave["ModScroll"]
		end
		TrGCDUploadViewSetting()
	end
end
function TrGCDRestoreDefaultSettings() -- восстановление стандартных настроек
	if (TrufiGCDChSave == nil) then TrufiGCDChSave = {} end
	TrufiGCDChSave["TrGCDQueueFr"] = {}
	TrufiGCDChSave["TooltipEnable"] = true
	TrufiGCDChSave["TooltipStopMove"] = true
	TrufiGCDChSave["TooltipSpellID"] = false
	for i=1,12 do
		TrufiGCDChSave["TrGCDQueueFr"][i] = {}
		TrGCDQueueOpt[i] = {}
		TrGCDQueueOpt[i].x = 0
		TrGCDQueueOpt[i].y = 0
		TrGCDQueueOpt[i].point = "CENTER"	
		TrGCDQueueOpt[i].enable = true
		if (i==1) then TrGCDQueueOpt[i].text = "Player" end
		if (i>1 and i<=5) then TrGCDQueueOpt[i].text = "Party " .. i-1 end
		if (i>5 and i<=10) then TrGCDQueueOpt[i].text = "Arena " .. i-5 end
		if (i==11) then TrGCDQueueOpt[i].text = "Target" end
		if (i==12) then TrGCDQueueOpt[i].text = "Focus" end
		TrGCDQueueOpt[i].fade = "Left"
		TrGCDQueueOpt[i].size = 30
		TrGCDQueueOpt[i].width = 3
		TrGCDQueueOpt[i].speed = TrGCDQueueOpt[i].size / TimeGcd
		TrufiGCDChSave["TrGCDQueueFr"][i]["x"] = TrGCDQueueOpt[i].x
		TrufiGCDChSave["TrGCDQueueFr"][i]["y"] = TrGCDQueueOpt[i].y	
		TrufiGCDChSave["TrGCDQueueFr"][i]["point"] = TrGCDQueueOpt[i].point
		TrufiGCDChSave["TrGCDQueueFr"][i]["enable"] = TrGCDQueueOpt[i].enable
		TrufiGCDChSave["TrGCDQueueFr"][i]["text"] = TrGCDQueueOpt[i].text
		TrufiGCDChSave["TrGCDQueueFr"][i]["fade"] = TrGCDQueueOpt[i].fade
		TrufiGCDChSave["TrGCDQueueFr"][i]["size"] = TrGCDQueueOpt[i].size
		TrufiGCDChSave["TrGCDQueueFr"][i]["width"] = TrGCDQueueOpt[i].width
		TrufiGCDChSave["TrGCDQueueFr"][i]["speed"] = TrGCDQueueOpt[i].speed
	end
	TrufiGCDChSave["EnableIn"] = {}
	TrufiGCDChSave["EnableIn"]["PvE"] = true
	TrufiGCDChSave["EnableIn"]["Raid"] = true
	TrufiGCDChSave["EnableIn"]["Arena"] = true
	TrufiGCDChSave["EnableIn"]["Bg"] = true
	TrufiGCDChSave["EnableIn"]["World"] = true
	TrufiGCDChSave["EnableIn"]["Enable"] = true	
	TrufiGCDChSave["ModScroll"] = true
end
function TrGCDUploadViewSetting()
	TrGCDGUI.CheckTooltip:SetChecked(TrufiGCDChSave["TooltipEnable"])
	TrGCDGUI.CheckTooltipMove:SetChecked(TrufiGCDChSave["TooltipStopMove"])
	TrGCDGUI.CheckTooltipID:SetChecked(TrufiGCDChSave["TooltipSpellID"])
	for i=1,12 do
		getglobal(TrGCDGUI.sizeslider[i]:GetName() .. 'Text'):SetText(TrGCDQueueOpt[i].size)
		TrGCDGUI.sizeslider[i]:SetValue(TrGCDQueueOpt[i].size)
		getglobal(TrGCDGUI.widthslider[i]:GetName() .. 'Text'):SetText(TrGCDQueueOpt[i].width)
		TrGCDGUI.widthslider[i]:SetValue(TrGCDQueueOpt[i].width)
		UIDropDownMenu_SetText(TrGCDGUI.menu[i], TrGCDQueueOpt[i].fade)
		TrGCDGUI.checkenable[i]:SetChecked(TrGCDQueueOpt[i].enable)
		TrGCDCheckEnableClick(i)
		TrGCDCheckEnableClick(i)
		TrGCDResizeQFr(i)
		TrGCDClear(i)
		TrGCDQueueFr[i]:ClearAllPoints()
		TrGCDQueueFr[i]:SetPoint(TrGCDQueueOpt[i].point, UIParent, TrGCDQueueOpt[i].point, TrGCDQueueOpt[i].x, TrGCDQueueOpt[i].y)
	end
	TrGCDGUI.CheckEnableIn[0]:SetChecked(TrufiGCDChSave["EnableIn"]["Enable"])	
	TrGCDGUI.CheckEnableIn[1]:SetChecked(TrufiGCDChSave["EnableIn"]["World"])	
	TrGCDGUI.CheckEnableIn[2]:SetChecked(TrufiGCDChSave["EnableIn"]["PvE"])	
	TrGCDGUI.CheckEnableIn[3]:SetChecked(TrufiGCDChSave["EnableIn"]["Arena"])	
	TrGCDGUI.CheckEnableIn[4]:SetChecked(TrufiGCDChSave["EnableIn"]["Bg"])	
	TrGCDGUI.CheckEnableIn[5]:SetChecked(TrufiGCDChSave["EnableIn"]["Raid"])	
	TrGCDGUI.CheckModScroll:SetChecked(TrufiGCDChSave["ModScroll"])
end
function TrGCDResizeQFr(i) -- TrGCDQueueFr队列大小调整后的解析
	if ((TrGCDQueueOpt[i].fade == "Left") or (TrGCDQueueOpt[i].fade == "Right")) then
		TrGCDQueueFr[i]:SetHeight(TrGCDQueueOpt[i].size)
		TrGCDQueueFr[i]:SetWidth(TrGCDQueueOpt[i].width*TrGCDQueueOpt[i].size)
	elseif ((TrGCDQueueOpt[i].fade == "Up") or (TrGCDQueueOpt[i].fade == "Down")) then
		TrGCDQueueFr[i]:SetHeight(TrGCDQueueOpt[i].width*TrGCDQueueOpt[i].size)
		TrGCDQueueFr[i]:SetWidth(TrGCDQueueOpt[i].size)
	end
	if Masque then TrGCDMasqueIcons:ReSkin() end
end
function TrGCDSpSizeChanged(i,value) --изменен размер иконок спеллов
	value = math.ceil(value);
	getglobal(TrGCDGUI.sizeslider[i]:GetName() .. 'Text'):SetText(value)
	TrGCDQueueOpt[i].size = value
	TrufiGCDChSave["TrGCDQueueFr"][i]["size"] = value
	TrGCDQueueOpt[i].speed = TrGCDQueueOpt[i].size / TimeGcd
	TrufiGCDChSave["TrGCDQueueFr"][i]["speed"] = TrGCDQueueOpt[i].speed
	TrGCDResizeQFr(i)
	TrGCDClear(i)
end
function TrGCDSpWidthChanged(i,value) --更改队列长度
	value = math.ceil(value);
	getglobal(TrGCDGUI.widthslider[i]:GetName() .. 'Text'):SetText(value)
	TrGCDQueueOpt[i].width = value
	TrufiGCDChSave["TrGCDQueueFr"][i]["width"] = value
	TrGCDResizeQFr(i)	
	TrGCDClear(i)
end
function TrGCDFadeMenuWasCheck(i, str) --выбрана строчка в меню направления фейда абилок
	TrGCDClear(i)
	UIDropDownMenu_SetText(TrGCDGUI.menu[i], str)
	TrGCDQueueOpt[i].fade = str
	TrufiGCDChSave["TrGCDQueueFr"][i]["fade"] = str
	TrGCDResizeQFr(i)
end
function TrGCDCheckEnableClick(i) --出现“打开/关闭框架”复选框
	if (TrGCDQueueOpt[i].enable) then
		if (TrGCDGUI.buttonfix:GetText() == "Hide") then
			TrGCDQueueFr[i]:SetMovable(false)
			TrGCDQueueFr[i]:EnableMouse(false)
			TrGCDQueueFr[i].texture:SetAlpha(0)
			TrGCDQueueFr[i].text:SetAlpha(0)
		end
		TrGCDQueueOpt[i].enable = false
		TrufiGCDChSave["TrGCDQueueFr"][i]["enable"] = TrGCDQueueOpt[i].enable
	else 
		if (TrGCDGUI.buttonfix:GetText() == "Hide") then
			TrGCDQueueFr[i]:SetMovable(true)
			TrGCDQueueFr[i]:EnableMouse(true)
			TrGCDQueueFr[i].texture:SetAlpha(0.5)
			TrGCDQueueFr[i].text:SetAlpha(0.5)
		end
		TrGCDQueueOpt[i].enable = true
		TrufiGCDChSave["TrGCDQueueFr"][i]["enable"] = TrGCDQueueOpt[i].enable
	end
	TrGCDClear(i)
end
function TrGCDGUIButtonFixClick() --show/hide按钮在选项中的功能
	if 	(TrGCDGUI.buttonfix:GetText() == "Show") then
		TrGCDGUI.buttonfix:SetText("Hide")
		TrGCDFixEnable:Show()
		for i=1,12 do
			if (TrGCDQueueOpt[i].enable) then
				TrGCDQueueFr[i]:SetMovable(true)
				TrGCDQueueFr[i]:EnableMouse(true)
				TrGCDQueueFr[i].texture:SetAlpha(0.5)
				TrGCDQueueFr[i].text:SetAlpha(0.5)
			end
		end
	else
		TrGCDGUI.buttonfix:SetText("Show")
		TrGCDFixEnable:Hide()
		for i=1,12 do
			if (TrGCDQueueOpt[i].enable) then
				TrGCDQueueFr[i]:SetMovable(false)
				TrGCDQueueFr[i]:EnableMouse(false)
				TrGCDQueueFr[i].texture:SetAlpha(0)	
				TrGCDQueueFr[i].text:SetAlpha(0)
				TrGCDQueueOpt[i].point, _, _, TrGCDQueueOpt[i].x, TrGCDQueueOpt[i].y = TrGCDQueueFr[i]:GetPoint()
				TrufiGCDChSave["TrGCDQueueFr"][i]["x"] = TrGCDQueueOpt[i].x
				TrufiGCDChSave["TrGCDQueueFr"][i]["y"] = TrGCDQueueOpt[i].y
				TrufiGCDChSave["TrGCDQueueFr"][i]["point"] = TrGCDQueueOpt[i].point
				TrufiGCDChSave["TrGCDQueueFr"][i]["enable"] = TrGCDQueueOpt[i].enable
			end
		end
	end
end
function TrGCDClear(i)
	TrGCDCastSp[i] = 1
	for k=1,10 do
		TrGCDIcon[i][k].show = false 
		TrGCDIcon[i][k]:SetAlpha(0)
		TrGCDIcon[i][k].x = 0
		TrGCDIcon[i][k]:SetHeight(TrGCDQueueOpt[i].size)
		TrGCDIcon[i][k]:SetWidth(TrGCDQueueOpt[i].size)
		TrGCDIcon[i][k]:ClearAllPoints()
		TrGCDIcon[i][k]:Hide()
		TrGCDi[i] = 1
		TrGCDQueueFirst[i] = {}
		TrGCDQueueFirstI[i] = 1
		TrGCDIcon[i][k].texture:SetTexture(nil)
		TrGCDIcon[i][k].texture2:Hide()
		--TrGCDIcon[i][k]:SetPoint("LEFT", TrGCDQueueFr[i], "LEFT",0,0)
	end
end
local function TrGCDCheckForEual(a,b) -- проверка эквивалентности юнитов - имя, хп
	local t = false
	if ((UnitName(a) == UnitName(b)) and (UnitName(a)~= nil) and (UnitName(b) ~= nil)) then
		if (UnitHealth(a) == UnitHealth(b)) then t = true end
	end
	return t
end
function TrGCDPlayerTarFocDetect(k) -- 支票是否已经在框架中有目标或焦点(帕蒂或竞技场)
	--k = 11 - target, 12 - focus
	local t = "null"
	local i = 0
	if (k == 11) then t = "target" end
	if (k == 12) then t = "focus" end
	if (TrGCDCheckForEual(t,"player")) then i = 1 end
	for j=2,5 do if (TrGCDCheckForEual(t,("party"..j-1))) then i = j end end
	for j=6,10 do if (TrGCDCheckForEual(t,("arena"..j-5))) then i = j end end
	if ((k ~= 11) and TrGCDCheckForEual(t,"target")) then i = 11 end
	if ((k~= 12) and TrGCDCheckForEual(t,"focus")) then i = 12 end
	if (i ~= 0) then -- если есть то копипаст всей очереди
		local width = TrGCDQueueOpt[i].width*TrGCDQueueOpt[i].size
		for j=1,10 do
			TrGCDIcon[k][j].x = TrGCDIcon[i][j].x
			if (TrGCDQueueOpt[k].fade == "Left") then TrGCDIcon[k][j]:SetPoint("RIGHT", TrGCDQueueFr[k], "RIGHT",TrGCDIcon[k][j].x,0)
			elseif (TrGCDQueueOpt[k].fade == "Right") then TrGCDIcon[k][j]:SetPoint("LEFT", TrGCDQueueFr[k], "LEFT",-TrGCDIcon[k][j].x,0)
			elseif (TrGCDQueueOpt[k].fade == "Up") then TrGCDIcon[k][j]:SetPoint("BOTTOM", TrGCDQueueFr[k], "BOTTOM",0,-TrGCDIcon[k][j].x)
			elseif (TrGCDQueueOpt[k].fade == "Down") then TrGCDIcon[k][j]:SetPoint("TOP", TrGCDQueueFr[k], "TOP",0,TrGCDIcon[k][j].x) end		
			TrGCDIcon[k][j].texture:SetTexture(TrGCDIcon[i][j].texture:GetTexture())
			TrGCDIcon[k][j].show = TrGCDIcon[i][j].show
			TrGCDIcon[k][j]:SetAlpha(TrGCDIcon[i][j]:GetAlpha())
			TrGCDIcon[k][j].TimeStart = TrGCDIcon[i][j].TimeStart
			if (TrGCDIcon[k][j].show) then 
				TrGCDIcon[k][j]:SetAlpha((1-(abs(TrGCDIcon[k][j].x) - width)/10))  --МИГАЕТ ПРИ РАЗНОМ РАЗМЕРЕ ОЧЕРЕДИ
				TrGCDIcon[k][j]:Show() 
			else TrGCDIcon[k][j]:Hide() end
			TrGCDIcon[k][j].texture2.show = TrGCDIcon[i][j].texture2.show
			if (TrGCDIcon[k][j].texture2.show) then 
				TrGCDIcon[k][j].texture2:Show() 
			else TrGCDIcon[k][j].texture2:Hide() end
		end
		TrGCDCastSp[k] = TrGCDCastSp[i]
		TrGCDBufferIcon[k] = TrGCDBufferIcon[i]
		TrGCDCastSpBanTime[k] = TrGCDCastSpBanTime[i]	
		TrGCDi[k] = TrGCDi[i]
		TrGCDQueueFirstI[k] = 1
		if (TrGCDSizeQueue(i) > 0) then -- копипаст очереди спеллов на первое место
			for j=1,TrGCDSizeQueue(i) do
				TrGCDQueueFirst[k][j] = TrGCDQueueFirst[i][TrGCDQueueFirstI[i]+j-1]
			end
		end
	end
end
--TrGCDQueueFirst-到新位置的Spail队列
function TrGCDAddSpQueue(TrGCDit, i) -- 将新Spell添加到新位置
	local k = TrGCDQueueFirstI[i]
	while (TrGCDQueueFirst[i][k] ~= nil) do k = k + 1 end
	TrGCDQueueFirst[i][k] = TrGCDit
end
function TrGCDSizeQueue(i) -- 了解新位置的队列长度
	local k = TrGCDQueueFirstI[i]
	while (TrGCDQueueFirst[i][k] ~= nil) do k = k + 1 end
	return (k - TrGCDQueueFirstI[i])
end
function TrGCDPlayerDetect(who) --让我们找出发送者
	local t = false --true-如果伊文特是在酒吧或竞技场上启动的
	local i = 0
	if (who == "player") then i = 1 t = true return i,t end
	for j=2,5 do if (who == ("party"..j-1)) then i = j t = true return i,t end end
	for j=6,10 do if (who == ("arena"..j-5)) then i = j t = true return i,t end end
	if (who == "target") then i = 11 t = true return i,t end
	if (who == "focus") then i = 12 t = true end
	return i, t
end
--48108 - Огненная глыба!
--34936 - Ответный удар
--93400 - Падающие звезды
--69369 - Стремительность хищника
--81292 - Cимвол пронзания разума
--87160 - Наступление тьмы
--114255 - Пробуждение света
--124430 - Божественная мудрость
function TrGCDEventBuffHandler(self,event, ...) --запущена эвентом изменения баффов/дебаффов персонажа
	if (TrGCDEnable) then
		local who = ... ;
		local i,t = TrGCDPlayerDetect(who)
		local tt = true
		if (t) then
			for k=1,16 do
				local k = select(11,UnitBuff(who, k))
				if (k == 48108) then TrGCDInsSp["spell"][i] = 48108 tt = false
				elseif (k == 34936) then TrGCDInsSp["spell"][i] = 34936 tt = false
				elseif (k == 93400) then TrGCDInsSp["spell"][i] = 93400 tt = false
				elseif (k == 69369) then TrGCDInsSp["spell"][i] = 69369 tt = false 
				elseif (k == 81292) then TrGCDInsSp["spell"][i] = 81292 tt = false
				elseif (k == 87160) then TrGCDInsSp["spell"][i] = 87160 tt = false
				elseif (k == 114255) then TrGCDInsSp["spell"][i] = 114255 tt = false
				elseif (k == 124430) then TrGCDInsSp["spell"][i] = 124430 tt = false end
			end
			if (((GetTime()-TrGCDInsSp["time"][i]) <0.1) and (tt)) then TrGCDInsSp["spell"][i] = 0 end
		end
	end
end
local function TrGCDAddGcdSpell(texture, i, spellid) -- добавление нового спелла в очередь
	if (TrGCDi[i] == 10) then TrGCDi[i] = 1 end
	TrGCDAddSpQueue(TrGCDi[i], i)
	TrGCDIcon[i][TrGCDi[i]].x = 0;
	TrGCDIcon[i][TrGCDi[i]].texture:SetTexture(texture)	
	TrGCDIcon[i][TrGCDi[i]].show = false
	TrGCDIcon[i][TrGCDi[i]]:SetAlpha(0)
	TrGCDIcon[i][TrGCDi[i]]:Hide()
	TrGCDIcon[i][TrGCDi[i]].spellID = spellid
	TrGCDi[i] = TrGCDi[i] + 1
end
function TrGCDEventHandler(self, event, ...)
	local arg1, _, arg5 = ...; -- arg1 - who,  arg5 - spellID
	local spellicon = select(3, GetSpellInfo(arg5))
	local casttime = select(4, GetSpellInfo(arg5))/1000
	local spellname = GetSpellInfo(arg5)
	local i,t = TrGCDPlayerDetect(arg1) -- I-用户编号，t=true-如果有人在酒吧或竞技场上
	if (TrGCDEnable and t and TrGCDQueueOpt[i].enable) then --所有的技能
		--print(arg5 .. " - " .. spellname,"我正在施放技能")
		if (TrGCDQueueOpt[i].text == "Target") then
			SendBossNotes(spellname)
		end
		local blt = true -- TGCDCD队列
		local sblt = true -- 对于关闭的黑名单(按ID在内部)
		TrGCDInsSp["time"][i] = GetTime()	
		for l=1, #TrGCDBL do if ((TrGCDBL[l] == spellname) or (GetSpellInfo(TrGCDBL[l]) == spellname)) then blt = false end end -- проверка на черный список
		for l=1, #InnerBL do if (InnerBL[l] == arg5) then sblt = false end end -- проверка на закрытый черный список
		if ((spellicon ~= nil) and t and blt and sblt and (GetSpellLink(arg5) ~= nil)) then
			if (arg5 == 42292) then spellicon = trinket end --替换填充图案纹理
				local IsChannel = UnitChannelInfo(arg1)--ченнелинг ли спелл
			if (event == "UNIT_SPELLCAST_START") then
				--print("目标正在施放技能 " .. spellname,arg5,GetSpellLink(arg5),UnitName("target"))
				

				TrGCDAddGcdSpell(spellicon, i, arg5)
				TrGCDCastSp[i] = 0-- 0 - каст идет, 1 - каст прошел и не идет
				TrGCDCastSpBanTime[i] = GetTime()

			elseif (event == "UNIT_SPELLCAST_SUCCEEDED") then
				if (TrGCDCastSp[i] == 0) then
					--print("目标成功施放技能 " .. spellname,arg5,GetSpellLink(arg5))
					if (IsChannel == nil) then TrGCDCastSp[i] = 1 end
				else
					local b = false --висит ли багнутый бафф инстант каста
					if ((TrGCDInsSp["spell"][i] == 48108) and (arg5 == 11366)) then b = true
					elseif ((TrGCDInsSp["spell"][i] == 34936) and (arg5 == 29722)) then b = true
					elseif ((TrGCDInsSp["spell"][i] == 93400) and (arg5 == 78674)) then b = true
					elseif ((TrGCDInsSp["spell"][i] == 69369) and ((arg5 == 339) or (arg5 == 33786) or (arg5 == 5185) or (arg5 == 2637) or (arg5 == 20484)))then b = true 
					elseif ((TrGCDInsSp["spell"][i] == 81292) and (arg5 == 8092)) then b = true
					elseif ((TrGCDInsSp["spell"][i] == 87160) and (arg5 == 73510)) then b = true
					elseif ((TrGCDInsSp["spell"][i] == 114255) and (arg5 == 2061)) then b = true
					elseif ((TrGCDInsSp["spell"][i] == 124430) and (arg5 == 8092)) then b = true end
					TrGCDCastSpBanTime[i] = GetTime()
					if (IsChannel ~= nil) then TrGCDCastSp[i] = 0 end
					if (((GetTime()-TrGCDSpStopTime[i]) < 1) and (TrGCDSpStopName[i] == spellname) and (b == false)) then
						TrGCDIcon[i][TrGCDSpStop[i]].texture2:Hide()
						TrGCDIcon[i][TrGCDSpStop[i]].texture2.show = false
					end
					if ((casttime <= 0) or b) then TrGCDAddGcdSpell(spellicon, i, arg5) end
					--print("succeeded " .. spellname .. " - " ..TrGCDCastSp[i],"成功施放技能")
				end
			elseif ((event == "UNIT_SPELLCAST_STOP") and (TrGCDCastSp[i] == 0)) then
				--print("目标施放技能失败 " .. spellname,arg5,GetSpellLink(arg5))
				TrGCDCastSp[i] = 1
				TrGCDIcon[i][TrGCDi[i]-1].texture2:Show()
				TrGCDIcon[i][TrGCDi[i]-1].texture2.show = true
				TrGCDSpStop[i] = TrGCDi[i]-1
				TrGCDSpStopName[i] = spellname
				TrGCDSpStopTime[i] = GetTime()
			elseif (event == "UNIT_SPELLCAST_CHANNEL_STOP") then
				TrGCDCastSp[i] = 1
				--print("channel stop " .. spellname .. " - " .. TrGCDCastSp[i],"技能4")
			end
		end
	end
end
function TrGCDUpdate(self)
	if ((GetTime() - TimeReset)> TimeDelay) then
		for i=1,12 do
			if (TrGCDQueueOpt[i].enable and TrGCDIconOnEnter[i]) then
				if (TrGCDSizeQueue(i) > 0) then
					if ((TrGCDQueueOpt[i].size - TrGCDBufferIcon[i]) <= 0) then
						local k = TrGCDQueueFirst[i][TrGCDQueueFirstI[i]]
						TrGCDIcon[i][k].show = true
						TrGCDIcon[i][k]:Show()
						TrGCDIcon[i][k]:SetAlpha(1)
						TrGCDQueueFirstI[i] = TrGCDQueueFirstI[i] + 1
						TrGCDBufferIcon[i] = 0
						TrGCDIcon[i][k].TimeStart = GetTime()
					end
				end
				if ((GetTime() - TrGCDCastSpBanTime[i]) > 10) then TrGCDCastSp[i] = 1 end				
				local fastspeed = TrGCDQueueOpt[i].speed*SpMod*(TrGCDSizeQueue(i)+1)
				if (TrGCDSizeQueue(i) > 0) then DurTimeImprove = (TrGCDQueueOpt[i].size - TrGCDBufferIcon[i])/fastspeed
				else DurTimeImprove = 0.0 end
				if (DurTimeImprove > (GetTime()-TimeReset)) then DurTimeImprove = GetTime()-TimeReset end
				for k = 1,10 do
					if (TrGCDIcon[i][k].show) then
						local width = TrGCDQueueOpt[i].width * TrGCDQueueOpt[i].size
						if (TrufiGCDChSave["ModScroll"] == false) then
							if (DurTimeImprove ~= 0) then
								TrGCDIcon[i][k].x = TrGCDIcon[i][k].x - (GetTime()-TimeReset-DurTimeImprove)*TrGCDQueueOpt[i].speed*TrGCDCastSp[i] - DurTimeImprove*fastspeed end
						else
							TrGCDIcon[i][k].x = TrGCDIcon[i][k].x - (GetTime()-TimeReset-DurTimeImprove)*TrGCDQueueOpt[i].speed*TrGCDCastSp[i] - DurTimeImprove*fastspeed
						end
						if (TrGCDQueueOpt[i].fade == "Left") then TrGCDIcon[i][k]:SetPoint("RIGHT", TrGCDQueueFr[i], "RIGHT",TrGCDIcon[i][k].x,0)
						elseif (TrGCDQueueOpt[i].fade == "Right") then TrGCDIcon[i][k]:SetPoint("LEFT", TrGCDQueueFr[i], "LEFT",-TrGCDIcon[i][k].x,0)
						elseif (TrGCDQueueOpt[i].fade == "Up") then TrGCDIcon[i][k]:SetPoint("BOTTOM", TrGCDQueueFr[i], "BOTTOM",0,-TrGCDIcon[i][k].x)
						elseif (TrGCDQueueOpt[i].fade == "Down") then TrGCDIcon[i][k]:SetPoint("TOP", TrGCDQueueFr[i], "TOP",0,TrGCDIcon[i][k].x) end						
						if (TrufiGCDChSave["ModScroll"] == false) then
							if ((GetTime() - TrGCDIcon[i][k].TimeStart) > (ModTimeVanish + ModTimeIndent)) then
								TrGCDIcon[i][k].show = false 
								TrGCDIcon[i][k]:Hide() 
								TrGCDIcon[i][k]:SetAlpha(0)
								TrGCDIcon[i][k].x = 0
								TrGCDIcon[i][k].texture2:Hide()
								TrGCDIcon[i][k].texture2.show = false
							elseif ((GetTime() - TrGCDIcon[i][k].TimeStart) > ModTimeIndent) then TrGCDIcon[i][k]:SetAlpha((1-(GetTime() - TrGCDIcon[i][k].TimeStart - ModTimeIndent)/ModTimeVanish)) end
						end
						if (abs(TrGCDIcon[i][k].x) > width) then
							if ((1-(abs(TrGCDIcon[i][k].x) - width)/10) < 0) then 
								TrGCDIcon[i][k].show = false 
								TrGCDIcon[i][k]:Hide() 
								TrGCDIcon[i][k]:SetAlpha(0)
								TrGCDIcon[i][k].x = 0
								TrGCDIcon[i][k].texture2:Hide()
								TrGCDIcon[i][k].texture2.show = false
							elseif (TrufiGCDChSave["ModScroll"] == true) then TrGCDIcon[i][k]:SetAlpha((1-(abs(TrGCDIcon[i][k].x) - width)/10)) end
						end
					end
				end
				if (TrufiGCDChSave["ModScroll"] == false) then
					if (DurTimeImprove ~= 0) then
						TrGCDBufferIcon[i] = TrGCDBufferIcon[i] + (GetTime()-TimeReset-DurTimeImprove)*TrGCDQueueOpt[i].speed*TrGCDCastSp[i] + DurTimeImprove *fastspeed
					end
				else 
					TrGCDBufferIcon[i] = TrGCDBufferIcon[i] + (GetTime()-TimeReset-DurTimeImprove)*TrGCDQueueOpt[i].speed*TrGCDCastSp[i] + DurTimeImprove *fastspeed
				end
			end
		end
		TimeReset = GetTime()
	end
end



if GetLocale() == "zhCN" then
	Raiders_List = {
			["技能"] = {
				{name = "火球术", raiders = "敌人正在施放火球术，快打断"},
				{name = "回城", raiders = "3个图腾必须一起死，图腾死了再打Boss。"},
			},
			["阿塔达萨"] = {
				{name = "邪灵劣魔", raiders = "为了部落。你的敌人很弱小，快碾碎它"},
				{name = "沃卡尔", raiders = "3个图腾必须一起死，图腾死了再打Boss。"},
				{name = "莱赞", raiders = "卡视角躲恐惧，被点名跑河道，别踩土堆。"},
				{name = "女祭司阿伦扎", raiders = "秒ADD，Boss吸血前，血水一人一滩。"},
				{name = "亚兹玛", raiders = "除坦克其他人出分身前集中。"},
			},
			["地渊孢林"] = {
				{name = "长者莉娅克萨", raiders = "打断、Boss冲锋位置远离。"},
				{name = "被感染的岩喉", raiders = "8秒内踩掉小虫子，躲喷吐和冲锋。"},
				{name = "孢子召唤者赞查", raiders = "利用顺劈和点名清蘑菇，躲球。"},
				{name = "不羁畸变怪", raiders = "集体移动，利用清理光圈消debuff，全力输出Boss，输出越高能量越快小怪出得越快Boss死得越快。"},
			},
			["自由镇"]	= {
				{name = "尤朵拉船长", raiders = "音量开大听着夏一可小姐姐的声音嗨起来。"},
				{name = "乔里船长", raiders = "音量开大听着夏一可小姐姐的声音嗨起来。"},
				{name = "拉乌尔船长", raiders = "音量开大听着夏一可小姐姐的声音嗨起来。"},
				{name = "天空上尉库拉格", raiders = "冲锋前有旋涡，看到就躲开，分散点站，中了绿水，跑出范围。"},
				{name = "托萨克", raiders = "远程治疗看到血池就先站到边上去，一般鲨鱼刚扔出来都是点远程，确认丢自己了跑进血池去等鲨鱼追过来。"},
				{name = "哈兰·斯威提", raiders = "出小怪控一下，远程能点就点掉，点不掉或者是进战队，就看清楚只要不是点自己，就冲过去先干掉，省得自爆。"},
			},
			["诸王之眠"]	= {
				{name = "征服者阿卡阿里", raiders = "最早被打死的那个Boss会时不时出现，智者(毒性新星)一定要打断，征服者的翻滚记得直线分担。"},
				{name = "智者扎纳扎尔", raiders = "最早被打死的那个Boss会时不时出现，智者(毒性新星)一定要打断，征服者的翻滚记得直线分担。"},
				{name = "屠夫库拉", raiders = "最早被打死的那个Boss会时不时出现，智者(毒性新星)一定要打断，征服者的翻滚记得直线分担。"},
				{name = "黄金风蛇", raiders = "吐金是直线方向AOE，旋风斩躲开就好，出小怪能打掉就打能控就控。"},
				{name = "殓尸者姆沁巴", raiders = "重点是不要开错棺材，有队友的那个会抖动。"},
				{name = "达萨大王", raiders = "提前和队伍商量好是一起顺时针跑还是用技能往回传送。"},
			},
			["风暴神殿"]	= {
				{name = "阿库希尔", raiders = "点名出人群，驱散或到时间后所有人躲海浪、躲冲锋。"},
				{name = "铁舟修士", raiders = "先女人，急速圈第一时间吃。"},
				{name = "唤风者菲伊", raiders = "先女人，急速圈第一时间吃。"},
				{name = "斯托颂勋爵", raiders = "被点名的抓紧时间撞球，其他人攻击救人。"},
				{name = "低语者沃尔兹斯", raiders = "躲拍地面的触须，打断，转阶段先集火打一边。"},
			},
			["围攻伯拉勒斯"]	= {
				{name = "拜恩比吉中士", raiders = "点名带着风筝，把Boss风筝到炸弹和轰炸区里去。"},
				{name = "恐怖船长洛克伍德", raiders = "躲AOE，秒ADD，捡道具把Boss打下船。"},
				{name = "哈达尔·黑渊", raiders = "躲正面，雕像附近别放白圈。"},
				{name = "维克戈斯", raiders = "t拉住攻城触须dps救人开炮，躲地面技能。"},
			},
			["塞塔里斯神庙"]	= {
				{name = "阿德里斯", raiders = "打身上没电的那个，躲正面，近战范围分散。"},
				{name = "阿斯匹克斯", raiders = "打身上没电的那个，躲正面，近战范围分散。"},
				{name = "米利克萨", raiders = "定身/控制技能救队友，路径躲开。"},
				{name = "加瓦兹特", raiders = "挡好电，挡1个塔等buff消掉了再去挡。"},
				{name = "萨塔里斯的化身", raiders = "驱散、在没有层数的时候治疗Boss/用球，蛤蟆第一时间打掉不然别怪奶不动。"},
			},
			["托尔达戈"]	= {
				{name = "泥沙女王", raiders = "躲陷阱，小虫治疗OT杀。"},
				{name = "杰斯·豪里斯", raiders = "提前开牢房清怪，打断恐惧，飞刀卡视野，P2集火Boss。"},
				{name = "骑士队长瓦莱莉", raiders = "留一个安全角落就行。"},
				{name = "科古斯狱长", raiders = "靠墙分散，用最少的移动躲技能，1层点名自己吃，2层开始坦克/其他职业帮挡。"},
			},
			["维克雷斯庄园"]	= {
				{name = "贪食的拉尔", raiders = "躲正面技能，躲地上绿水，杀ADD。"},
				{name = "魂缚巨像", raiders = "层数过高时把boss带到野火上烤一下，其他人躲灵魂。"},
				{name = "女巫布里亚", raiders = "输出变大的Boss，打断，队友被控制晕着打。"},
				{name = "女巫马拉迪", raiders = "输出变大的Boss，打断，队友被控制晕着打。"},
				{name = "女巫索林娜", raiders = "输出变大的Boss，打断，队友被控制晕着打。"},
				{name = "维克雷斯勋爵和夫人", raiders = "中毒出人群，躲漩涡。"},
				{name = "维克雷斯夫人", raiders = "中毒出人群，躲漩涡。"},
				{name = "高莱克·图尔", raiders = "先杀奴隶主，捡瓶子烧尸体。"},
			},
			["暴富矿区！！"]	= {
				{name = "投币式群体打击者", raiders = "躲正面、把球踢还给Boss。"},
				{name = "艾泽洛克", raiders = "躲正面、先杀小怪。"},
				{name = "瑞克莎·流火", raiders = "保证身后没有黄水和即将喷发的管子。"},
				{name = "商业大亨拉兹敦克", raiders = "P1留心直升机轰炸，点名出人群，P2被点名跑到钻头下面。"},
			},
		}
else
	Raiders_List = {}
end
--JANY核对信息
local function getRaidersByEncounterName(name)
for i,k in pairs(Raiders_List) do
	for i,v in pairs(k) do
		if v.name == name then
			return v.raiders
		end
	end
end
end


--JANY-- 发信息
function SendBossNotes(bossname)
	local raidersText
	local encounterName
	if EncounterJournal and EncounterJournal.encounterID then
		encounterName = EJ_GetEncounterInfo(EncounterJournal.encounterID)
	end
	if bossname then
		raidersText = getRaidersByEncounterName(bossname) or "无此BOSS数据"
	elseif encounterName then
		raidersText = getRaidersByEncounterName(encounterName) or "无此BOSS数据"
		bossname = encounterName
	end
	if raidersText and bossname and raidersText~="无此BOSS数据" then
		bossname = '目标:' .. bossname
		if IsInRaid() then
			--SendChatMessage(bossname, (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT") or "raid");
			--SendChatMessage(raidersText, (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT") or "raid");
			DEFAULT_CHAT_FRAME:AddMessage(bossname, "say");
			DEFAULT_CHAT_FRAME:AddMessage(raidersText, "say");

		elseif IsInGroup() then
			--SendChatMessage(bossname, (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT") or "party");
			--SendChatMessage(raidersText, (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT") or "party");
			DEFAULT_CHAT_FRAME:AddMessage(bossname, "say");
			DEFAULT_CHAT_FRAME:AddMessage(raidersText, "say");
		else
			--SendChatMessage(bossname, "say");
			--SendChatMessage(raidersText, "say");
			DEFAULT_CHAT_FRAME:AddMessage(bossname, "say");
			DEFAULT_CHAT_FRAME:AddMessage(raidersText, "say");
		end
	--else
		--DEFAULT_CHAT_FRAME:AddMessage("数据库无此数据",1,0,0)
	end
end
--JANY进入战斗离开战斗
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")   
f:SetScript("OnEvent", function (self,event)
	if event == "PLAYER_REGEN_ENABLED" then
		DEFAULT_CHAT_FRAME:AddMessage("离开战斗状态",1,0,0)
	elseif event == "PLAYER_REGEN_DISABLED" then
		if UnitName("target") == nil then
			DEFAULT_CHAT_FRAME:AddMessage("没有目标1",1,0,0)
			return
		end
		SendBossNotes(UnitName("target"));
	end	
end);
