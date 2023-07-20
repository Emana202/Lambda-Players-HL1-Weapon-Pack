local IsValid = IsValid
local GetConVar = GetConVar
local EffectData = EffectData
local string_StartWith = string.StartWith
local string_Replace = string.Replace
local random = math.random
local Rand = math.Rand
local IsFirstTimePredicted = IsFirstTimePredicted
local util_Effect = util.Effect
local util_BlastDamage = util.BlastDamage
local explodeBolts

local function OnEntityEmitSound( data )
    local ent = data.Entity
    if IsValid( ent ) then
        local sndName = data.OriginalSoundName
        local sndPath = data.SoundName

        if ent.l_IsLambdaSnark and string_StartWith( sndPath, "squeek/sqk_" ) then
            data.SoundName = string_Replace( sndPath, "squeek/sqk_", "lambdaplayers/weapons/hl1/squeek/sqk_" )
            return true
        elseif ent.l_IsLambdaBolt then 
            if sndName == "Weapon_Crossbow.BoltHitWorld" then
                data.SoundName = "lambdaplayers/weapons/hl1/crossbow/xbow_hit1.wav"
                data.Pitch = random( 98, 105 )
                data.Volume = Rand( 0.95, 1.0 )
                data.Channel = CHAN_BODY

                ent:SetMoveType( MOVETYPE_NONE )
                ent:SetRenderMode( RENDERMODE_NONE )
                ent:RemoveCallOnRemove( ent.l_RemoveCall )

                explodeBolts = ( explodeBolts or GetConVar( "lambdaplayers_weapons_hl1crossbow_explosivebolts" ) )
                if explodeBolts:GetBool() then
                    if IsFirstTimePredicted() then
                        local effectData = EffectData()
                        effectData:SetOrigin( ent:GetPos() )
                        effectData:SetFlags( 128 )
                        util_Effect( "Explosion", effectData )
                    end
                    ent:EmitSound( "lambdaplayers/weapons/hl1/explode" .. random( 3, 5 ) .. ".wav", 140, nil, nil, CHAN_STATIC )

                    local owner = ent:GetOwner()
                    local validOwner = IsValid( owner )
                    util_BlastDamage( ( validOwner and owner:GetWeaponENT() or ent ), ( validOwner and owner or ent ), ent:GetPos(), 128, 50 )
                end

                ent:Remove()
                return true
            end

            if sndName == "Weapon_Crossbow.BoltHitBody" or sndName == "Weapon_Crossbow.BoltSkewer" then
                data.SoundName = "lambdaplayers/weapons/hl1/crossbow/xbow_hitbod" .. random( 2 ) .. ".wav"
                return true
            end
        elseif ent.l_IsLambdaMP5Grenade and sndName == "GrenadeMP5.Detonate" then
            data.SoundName = "lambdaplayers/weapons/hl1/explode" .. random( 3, 5 ) .. ".wav"
            data.SoundLevel = 140
            data.Pitch = 100
            data.Volume = 1.0
            data.Channel = CHAN_STATIC
            
            local effectData = EffectData()
            effectData:SetOrigin( ent:GetPos() )
            util_Effect( "Explosion", effectData )
            
            return true
        elseif ent.l_IsLambdaRocket then 
            if sndName == "HL1Weapon_RPG.RocketIgnite" then
                data.SoundName = "lambdaplayers/weapons/hl1/rpg/rocket1.wav"
                return true
            end

            if sndName == "BaseGrenade.Explode" then
                data.SoundName = "lambdaplayers/weapons/hl1/explode" .. random( 3, 5 ) .. ".wav"
                data.SoundLevel = 140
                data.Pitch = 100
                data.Volume = 1.0
                data.Channel = CHAN_STATIC
                
                ent:StopSound( "lambdaplayers/weapons/hl1/rpg/rocket1.wav" ) 
                ent:Remove()
                return true
            end
        end
    end
end

local function OnLambdaCanTarget( lambda, target )
    if target.l_IsLambdaSnark and ( lambda:GetWeaponName() == "hl1_snark" or target:GetOwner() == lambda and target:GetEnemy() != lambda ) then return true end
end

local function OnLambdaOnOtherKilled( lambda, victim )
    if victim.l_IsLambdaSnark then return true end
end

hook.Add( "EntityEmitSound", "LambdaPlayers_HL1Pack_OnEntityEmitSound", OnEntityEmitSound )
hook.Add( "LambdaCanTarget", "LambdaPlayers_HL1Pack_OnLambdaCanTarget", OnLambdaCanTarget )
hook.Add( "LambdaOnOtherKilled", "LambdaPlayers_HL1Pack_OnLambdaOnOtherKilled", OnLambdaOnOtherKilled )