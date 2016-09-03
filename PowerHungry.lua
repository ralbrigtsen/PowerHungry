do
	local addon, namespace = ...
	setfenv(1, setmetatable(namespace, { __index = _G }))
end

--config
local TEXT_FMT = "|TInterface/LevelUp/LevelUpTex:0:0:0:0:512:512:370:400:20:50|t%d"
local SIZE = 40
local FALLBACK_ICON = "Interface/Icons/INV_Misc_QuestionMark"


local btn = CreateFrame("Button", "PowerHungryButton", UIParent, "SecureActionButtonTemplate")
btn:SetPoint("CENTER")
btn:SetHeight(SIZE)
btn:SetWidth(SIZE)
btn:SetAttribute("type", "item")

local tex = btn:CreateTexture()
tex:SetAllPoints()
local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
cd:SetAllPoints()
local fs = btn:CreateFontString()
fs:SetPoint("TOP", btn, "BOTTOM")
fs:SetFontObject("GameFontGreen")

btn:EnableMouse(true)
btn:SetMovable(true)
btn:RegisterForDrag("LeftButton")
btn:SetScript("OnDragStart", function(self) if IsAltKeyDown() then self:StartMoving() end end)
btn:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

btn:RegisterEvent("BAG_UPDATE_COOLDOWN")
btn:RegisterEvent("SPELL_UPDATE_COOLDOWN") --because BAG_UPDATE_COOLDOWN doesn't fire for GCDs from item use
btn:RegisterEvent("BAG_UPDATE_DELAYED")
btn:RegisterEvent("PLAYER_REGEN_ENABLED")

local dirty
btn:SetScript("OnEvent", function(_, event)
	if event == "BAG_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_COOLDOWN" then
		if btn.itemID then
			CooldownFrame_Set(cd, GetItemCooldown(btn.itemID))
		end
	else
		if event == "BAG_UPDATE_DELAYED" and InCombatLockdown() then
			dirty = true
		elseif event == "BAG_UPDATE_DELAYED" or dirty then --update button info
			dirty = false

			local id, p
			for bag = 0, 4 do --scan for artifact power items
				for slot = 1, GetContainerNumSlots(bag) do
					id = GetContainerItemID(bag, slot)
					p = power[id]
					if p then break	end
				end
				if p then break end
			end

			if p then --item found
				btn:SetShown(true)
				btn.itemID = id
				btn:SetAttribute("item", "item:"..id)
				tex:SetTexture(GetItemIcon(id))
				fs:SetText(TEXT_FMT:format(p))
			else --fallback
				btn:SetShown(false)
				btn.itemID = nil
				btn:SetAttribute("item", nil)
				tex:SetTexture(FALLBACK_ICON)
				fs:SetText("")
			end
		end

		if GameTooltip:IsShown() and GameTooltip:GetOwner() == btn then
			btn:GetScript("OnEnter")(btn) --update tooltip
		end
	end
end)

btn:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	if self.itemID then
		GameTooltip:SetItemByID(self.itemID)
	else
		GameTooltip:ClearLines()
		GameTooltip:AddLine("PowerHungry")
		GameTooltip:AddLine("|cffffffffNo artifact power found.|r")
		GameTooltip:AddLine("Alt+drag to move")
	end
	if dirty then
		GameTooltip:AddLine("|cffff0000(Waiting until out of combat to update...)|r")
	end
	GameTooltip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
