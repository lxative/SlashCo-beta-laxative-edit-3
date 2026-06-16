AddCSLuaFile()

DEFINE_BASECLASS("player_default")

local PLAYER = {}
--local SlashCo = SlashCo

--
-- See gamemodes/base/player_class/player_default.lua for all overridable variables
--
PLAYER.DisplayName = "Survivor"

PLAYER.SlowWalkSpeed = 100
PLAYER.WalkSpeed = 200
PLAYER.RunSpeed = 300
PLAYER.StartHealth = 100
PLAYER.MaxHealth = 100
PLAYER.Achievements = {}
PLAYER.Inventory = {}

function PLAYER:GetInventory()
	return PLAYER.Inventory
end

function PLAYER:Loadout()
	self.Player:RemoveAllAmmo()
	self.Player:Give("sc_survivorhands")
	self.Player:SetCanWalk(true)
end

SlashCo.SurvivorModels = file.Find("models/slashco/survivor/male_*.mdl", "GAME")
for idx, fileName in ipairs(SlashCo.SurvivorModels) do
	SlashCo.SurvivorModels[idx] = "models/slashco/survivor/" .. fileName
	SlashCo.SurvivorModels[SlashCo.SurvivorModels[idx]] = idx
end

hook.Add("SlashCo:Precache", "SlashCo:PrecacheSurvivorModels", function()
	for _, modelName in ipairs(SlashCo.SurvivorModels) do
		SlashCo.PrecacheModel(modelName)
	end
end)

function PLAYER:SetModel()
	local modelname
	local cl_modelname = self.Player:GetInfo("slashco_cl_playermodel")
	if SlashCo.SurvivorModels[cl_modelname] then
		modelname = cl_modelname
	else
		modelname = SlashCo.SurvivorModels[math.random(1, #SlashCo.SurvivorModels)]
	end

	self.Player:SetModel(modelname)
end

function PLAYER:Init()
	self.Player:AddEffects(EF_NOFLASHLIGHT)
end

player_manager.RegisterClass("player_survivor", PLAYER, "player_default")

hook.Add("CalcMainActivity", "SurvivorAnimator", function(ply, _)
	if ply:Team() ~= TEAM_SURVIVOR then
		return
	end

	if ply:GetNWBool("SurvivorTackled") then
		ply.CalcIdeal = ACT_DIESIMPLE
		ply.CalcSeqOverride = ply:LookupSequence("zombie_slump_idle_01")

		return ply.CalcIdeal, ply.CalcSeqOverride
	end

	if ply:GetNWBool("SurvivorGrabbed") then
		ply.CalcIdeal = ACT_DIESIMPLE
		ply.CalcSeqOverride = ply:LookupSequence("idle_all_cower")

		return ply.CalcIdeal, ply.CalcSeqOverride
	end

	if not ply:GetNWBool("SurvivorSidExecution") and not ply:GetNWBool("Taunt_MNR") then
		ply.surv_anim_antispam = false
	end

	if ply:GetNWBool("SurvivorSidExecution") then
		ply.CalcIdeal = ACT_DIESIMPLE
		ply.CalcSeqOverride = ply:LookupSequence("sid_execution")
		if ply.surv_anim_antispam == nil or ply.surv_anim_antispam == false then
			ply:SetCycle(0)
			ply.surv_anim_antispam = true
		end

		return ply.CalcIdeal, ply.CalcSeqOverride
	elseif ply:GetNWBool("Taunt_Cali") then
		ply.CalcIdeal = ACT_DIESIMPLE
		ply.CalcSeqOverride = ply:LookupSequence("taunt_cali")

		return ply.CalcIdeal, ply.CalcSeqOverride
	elseif ply:GetNWBool("Taunt_MNR") then
		ply.CalcIdeal = ACT_DIESIMPLE
		ply.CalcSeqOverride = ply:LookupSequence("taunt_mnr")
		if ply.surv_anim_antispam == nil or ply.surv_anim_antispam == false then
			ply:SetCycle(0)
			ply.surv_anim_antispam = true
		end

		return ply.CalcIdeal, ply.CalcSeqOverride
	elseif ply:GetNWBool("Taunt_Griddy") then
		ply.CalcIdeal = ACT_DIESIMPLE
		ply.CalcSeqOverride = ply:LookupSequence("taunt_griddy")

		return ply.CalcIdeal, ply.CalcSeqOverride
	else
		return
	end
end)

hook.Add("PlayerFootstep", "SurvivorFootstep", function(ply)
	--pos, foot, sound, volume, rf
	if ply:Team() == TEAM_SURVIVOR and ply:ItemFunction("OnFootstep") then
		return true
	end
end)

-- everything below this line is just a copy paste from prior version
-- 2026-06-10

local staminaDepletion = 0.008

local plyMeta = FindMetaTable( "Player" )
function plyMeta:GetStamina()
    return self:GetNWFloat( "ST2Stamina", self:GetStaminaCap() )
end

function plyMeta:SetStamina( ST )
    self:SetNWFloat( "ST2Stamina", ST )
end

function plyMeta:AddStamina( ST )
    self:SetNWFloat( "ST2Stamina", math.Clamp( self:GetNWFloat( "ST2Stamina", self:GetStaminaCap() ) + ST, 0, self:GetStaminaCap() ) )
end

function plyMeta:CapStamina( cap )
    self:SetNWFloat( "ST2MaxStam", cap )
end

function plyMeta:GetStaminaCap()
    return self:GetNWFloat( "ST2MaxStam", 100 )
end

hook.Add( "PlayerSpawn", "SetupST2StaminaValues", function( ply )

    ply:SetStamina( ply:GetStaminaCap() )

end )

local CMoveData = FindMetaTable( "CMoveData" )

function CMoveData:RemoveKeys( keys )
	local newbuttons = bit.band( self:GetButtons(), bit.bnot( keys ) )
	self:SetButtons( newbuttons )
end

hook.Add( "PlayerTick", "STStamina2ModifyStamina", function( ply, mv )

	if IsFirstTimePredicted() then -- is this even a good idea? i am not very experienced with using prediction... i just wanted the stamina bar to look smoother on ping :( laxative
	
    -- refill stamina if noclipping
    if ply:GetMoveType() == MOVETYPE_NOCLIP then
        ply:SetStamina( ply:GetStaminaCap() )
    end

    -- disallow jumping when our stamina is too low
    if ply:Team() == TEAM_SURVIVOR and ply:GetStamina() < 15 then
        mv:RemoveKeys( IN_JUMP )
    end


    if ply:Alive() and CurTime() >= ply:GetNWFloat( "ZeroStam", 0 ) + 3 then
    
        ply:SetNWFloat( "ZeroStam", 0 )

        -- stamina regen
        if mv:GetVelocity():LengthSqr() <= ( ply:GetRunSpeed() * 1.2 * ply:GetRunSpeed() * 1.2 ) then
            if ply:OnGround() then
				if mv:GetVelocity():LengthSqr() == 0 then
					ply:AddStamina( 0.004 )
                elseif mv:GetVelocity():LengthSqr() <= 4900 then
                    ply:AddStamina( 0.003 )
                else
                    ply:AddStamina( 0.001 )
                end
            else
                ply:AddStamina( 0.0 )
            end
        end

        -- handle stamina draining
        if ply:IsSprinting() and mv:GetVelocity():LengthSqr() >= ply:GetWalkSpeed() * ply:GetWalkSpeed() * ( ply:GetStamina() <= 25 and 0.6 or 1 ) and ply:OnGround() then
            ply:AddStamina( -1 * staminaDepletion )
        elseif ply:WaterLevel() >= 2 then
            if ply:IsSprinting() then
                ply:AddStamina( -0.3 * staminaDepletion )
            else
                ply:AddStamina( -0.2 * staminaDepletion )
            end
        end

        -- take a chunk of stamina when jumping
        if ply:OnGround() and mv:KeyPressed( IN_JUMP ) and ply:GetStamina() > 15 and IsFirstTimePredicted() then
            ply:AddStamina( -120 * staminaDepletion )
        end

    end
	end
end )

hook.Add( "SetupMove", "ApplyStaminaModifications", function( ply, mv, cmd )
    if ply:Team() == TEAM_SURVIVOR and ply:Alive() and ply:GetStamina() < 15 then
        mv:RemoveKeys( IN_JUMP )
        mv:SetMaxClientSpeed( mv:GetMaxClientSpeed() * 0.625 )
        mv:SetMaxSpeed( mv:GetMaxClientSpeed() * 0.625 )
        cmd:SetForwardMove( cmd:GetForwardMove() * 0.625 )
        cmd:SetSideMove( cmd:GetSideMove() * 0.625 )
        if ply:GetStamina() == 0 and ply:GetNWFloat( "ZeroStam", 0 ) == 0 then
            ply:SetNWFloat( "ZeroStam", CurTime() )
        end
    end
end )

