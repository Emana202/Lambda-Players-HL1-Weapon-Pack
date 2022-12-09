if ( CLIENT ) then return end

local IsValid = IsValid
local GetConVar = GetConVar
local EffectData = EffectData
local random = math.random
local Rand = math.Rand
local util_Effect = util.Effect
local util_BlastDamage = util.BlastDamage

hook.Add( "EntityEmitSound", "LambdaPlayers_HL1Pack_ReplaceSounds", function( data )
    local ent = data.Entity
    if !IsValid( ent ) then return end

    local sndName = data.OriginalSoundName

    if ent.l_IsLambdaBolt then 
        if sndName == "Weapon_Crossbow.BoltHitWorld" then
            data.SoundName = "lambdaplayers/weapons/hl1/crossbow/xbow_hit1.wav"
            data.Pitch = random( 98, 105 )
            data.Volume = Rand( 0.95, 1.0 )
            data.Channel = CHAN_BODY

            ent:SetMoveType( MOVETYPE_NONE )
            ent:SetRenderMode( RENDERMODE_NONE )
            ent:RemoveCallOnRemove( ent.l_RemoveCall )

            if GetConVar( "lambdaplayers_weapons_hl1crossbow_explosivebolts" ):GetBool() then
                local effectData = EffectData()
                effectData:SetOrigin( ent:GetPos() )
                effectData:SetFlags( 128 )
                util_Effect( "Explosion", effectData )
                
                ent:EmitSound( "lambdaplayers/weapons/hl1/explode" .. random( 3, 5 ) .. ".wav", 140, 100, 1, CHAN_STATIC )

                local owner = ent:GetOwner()
                local validOwner = IsValid( owner )
                util_BlastDamage( ( validOwner and owner:GetWeaponENT() or ent ), ( validOwner and owner or ent ), ent:GetPos(), 128, 40 )
            end

            ent:Remove()
            return true
        end

        if sndName == "Weapon_Crossbow.BoltHitBody" or sndName == "Weapon_Crossbow.BoltSkewer" then
            data.SoundName = "lambdaplayers/weapons/hl1/crossbow/xbow_hitbod" .. random( 1, 2 ) .. ".wav"
            return true
        end
    end

    if ent.l_IsLambdaRocket then 
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
end )