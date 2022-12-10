local IsValid = IsValid
local CurTime = CurTime
local EffectData = EffectData
local random = math.random
local Rand = math.Rand
local ents_Create = ents.Create
local util_Effect = util.Effect
local util_BlastDamage = util.BlastDamage
local explosiveCvar = CreateLambdaConvar( "lambdaplayers_weapons_hl1crossbow_explosivebolts", 1, true, false, true, "If HL1 Crossbow's bolts should be able to explode on impact.", 0, 1, { type = "Bool", name = "HL1 Crossbow - Enable Explosive Bolts", category = "Weapon Utilities" } )

hook.Add( "EntityTakeDamage", "Lambda_HL1Crossbow_HackKillIcon", function( ent, dmginfo )
    local inflictor = dmginfo:GetInflictor()
    if !IsValid( inflictor ) or !inflictor.l_IsLambdaBolt then return end 

    local owner = inflictor:GetOwner()
    if !IsValid( owner ) or !owner.IsLambdaPlayer then return end
    dmginfo:SetInflictor( owner:GetWeaponENT() )
end )

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_crossbow = {
        model = "models/lambdaplayers/weapons/hl1/w_crossbow.mdl",
        origin = "Half-Life 1",
        prettyname = "Crossbow",
        holdtype = "crossbow",
        killicon = "lambdaplayers/killicons/icon_hl1_crossbow",
        bonemerge = true,
        keepdistance = 750,
        attackrange = 1500,

        clip = 5,
        callback = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end

            local shootPos = ( ( random( 1, 3 ) == 1 and explosiveCvar:GetBool() ) and target:GetPos() or target:WorldSpaceCenter() )
            if random( 1, 4 ) == 1 and !self:IsInRange( shootPos, 256 ) then
                shootPos = shootPos + ( ( target:IsNextBot() and target.loco or target ):GetVelocity() * ( self:GetRangeTo( shootPos ) / 2000 ) )
            end

            local spawnPos = wepent:GetAttachment( 1 ).Pos

            local fireDir = ( shootPos - spawnPos ):Angle()
            if self:GetForward():Dot( fireDir:Forward() ) < 0.66 then return true end

            local bolt = ents_Create( "crossbow_bolt" )
            if !IsValid( bolt ) then return end

            self.l_WeaponUseCooldown = CurTime() + Rand( 0.8, 1.5 )

            wepent:EmitSound( "lambdaplayers/weapons/hl1/crossbow/xbow_fire1.wav", 80, random( 93, 108 ), 1, CHAN_WEAPON )
            wepent:EmitSound( "lambdaplayers/weapons/hl1/crossbow/xbow_reload1.wav", SNDLVL_NORM, random( 93, 108 ), Rand( 0.95, 1.0 ), CHAN_ITEM )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )

            bolt:SetPos( spawnPos + fireDir:Forward() * 32 ) 
            bolt:SetAngles( fireDir )
            bolt:SetOwner( self )
            bolt:Spawn()
            
            bolt.l_IsLambdaBolt = true
            bolt.l_RemoveCall = "Lambda_HL1CrossbowBolt_OnRemoval" .. bolt:EntIndex()

            bolt:SetModel( "models/lambdaplayers/weapons/hl1/props/crossbow_bolt.mdl" )
            bolt:Fire( "SetDamage", ( explosiveCvar:GetBool() and "10" or "50" ) )
            bolt:SetMoveType( MOVETYPE_FLY )
            bolt:SetVelocity( fireDir:Forward() * ( bolt:WaterLevel() == 3 and 1000 or 2000 ) )
            bolt:SetLocalAngularVelocity( Angle( 0, 0, 10 ) )
            bolt:CallOnRemove( bolt.l_RemoveCall, function() 
                if !explosiveCvar:GetBool() then return end

                local effectData = EffectData()
                effectData:SetOrigin( bolt:GetPos() )
                effectData:SetFlags( 128 )
                util_Effect( "Explosion", effectData )

                bolt:EmitSound( "lambdaplayers/weapons/hl1/explode" .. random( 3, 5 ) .. ".wav", SNDLVL_140dB, 100, 1, CHAN_STATIC )
                local validOwner = IsValid( self )
                util_BlastDamage( ( validOwner and self:GetWeaponENT() or bolt ), ( validOwner and self or bolt ), bolt:GetPos(), 128, 40 )
            end )

            self.l_Clip = self.l_Clip - 1
            return true
        end,

        reloadtime = 4.5,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_SMG1,
        reloadanimspeed = 0.4,
        reloadsounds = { { 0, "lambdaplayers/weapons/hl1/crossbow/xbow_reload1.wav" } },

        islethal = true
    }

} )