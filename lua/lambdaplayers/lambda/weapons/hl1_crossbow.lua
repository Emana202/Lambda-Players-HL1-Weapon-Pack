-- if !IsMounted( "hl1" ) then return end

local IsValid = IsValid
local CurTime = CurTime
local EffectData = EffectData
local random = math.random
local Rand = math.Rand
local ents_Create = ents.Create
local util_Effect = util.Effect
local util_BlastDamage = util.BlastDamage

local physBoxMins = Vector( -28, -12, -4.5 )
local physBoxMaxs = Vector( 16, 14, 5 )

local explosiveCvar = CreateLambdaConvar( "lambdaplayers_weapons_hl1crossbow_explosivebolts", 1, true, false, true, "If HL1 Crossbow's bolts should be able to explode on impact.", 0, 1, { type = "Bool", name = "HL1 Crossbow - Enable Explosive Bolts", category = "Weapon Utilities" } )
local function BoltExplode( lambda, pos )
    local effectData = EffectData()
    effectData:SetOrigin( pos )
    util_Effect( "Explosion", effectData )
    util_BlastDamage( lambda:GetWeaponENT(), lambda, pos, 128, 40 )
end

hook.Add( "EntityTakeDamage", "Lambda_HL1Crossbow_HackKillIcon", function( ent, dmginfo )
    local inflictor = dmginfo:GetInflictor()
    if !IsValid( inflictor ) or !inflictor.l_IsLambdaBolt then return end 

    local owner = inflictor:GetOwner()
    if !IsValid( owner ) or !owner.IsLambdaPlayer then return end
    dmginfo:SetInflictor( owner:GetWeaponENT() )
end )

hook.Add( "EntityEmitSound", "Lambda_HL1Crossbow_CheckRicochets", function( data )
    if data.OriginalSoundName != "Weapon_Crossbow.BoltHitWorld" then return end

    local ent = data.Entity
    if !ent or !ent.l_IsLambdaBolt then return end
    
    ent:SetMoveType( MOVETYPE_NONE )
    ent:RemoveCallOnRemove( ent.l_RemoveCall )

    if explosiveCvar:GetBool() then
        local owner = ent:GetOwner()
        BoltExplode( ( IsValid( owner ) and owner or ent ), ent:GetPos() )
    end

    ent:Remove()
end )

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_crossbow = {
        model = "models/weapons/w_crossbow_hls.mdl",
        origin = "Half-Life 1",
        prettyname = "Crossbow",
        holdtype = "crossbow",
        killicon = "lambdaplayers/killicons/icon_hl1_crossbow",
        bonemerge = true,
        keepdistance = 750,
        attackrange = 1500,

        OnDrop = function( cs_prop )
            cs_prop:PhysicsInitBox( physBoxMins, physBoxMaxs )
            cs_prop:PhysWake()
            cs_prop:GetPhysicsObject():SetMaterial( "weapon" )
        end,

        clip = 5,
        callback = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end

            local shootPos = ( ( random( 1, 3 ) == 1 and explosiveCvar:GetBool() ) and target:GetPos() or target:WorldSpaceCenter() )
            if random( 1, 3 ) == 1 and !self:IsInRange( shootPos, 256 ) then
                shootPos = shootPos + ( ( target:IsNextBot() and target.loco or target ):GetVelocity() * ( self:GetRangeTo( shootPos ) / 2000 ) )
            end

            local fireDir = ( shootPos - wepent:GetPos() ):Angle()
            if self:GetForward():Dot( fireDir:Forward() ) < 0.33 then return true end

            local bolt = ents_Create( "crossbow_bolt" )
            if !IsValid( bolt ) then return end

            self.l_WeaponUseCooldown = CurTime() + Rand( 0.75, 1.5 )

            wepent:EmitSound( "HL1Weapon_Crossbow.Single" )
            wepent:EmitSound( "HL1Weapon_Crossbow.Reload" )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )

            bolt:SetPos( wepent:GetPos() + fireDir:Forward() * 32 ) 
            bolt:SetAngles( fireDir )
            bolt:SetOwner( self )
            bolt:Spawn()
            
            bolt.l_IsLambdaBolt = true
            bolt.l_RemoveCall = "Lambda_HL1CrossbowBolt_OnRemoval" .. bolt:EntIndex()

            bolt:SetSkin( 0 )
            bolt:Fire( "SetDamage", ( explosiveCvar:GetBool() and "10" or "50" ) )
            bolt:SetMoveType( MOVETYPE_FLY )
            bolt:SetVelocity( fireDir:Forward() * ( bolt:WaterLevel() == 3 and 1000 or 2000 ) )
            bolt:SetLocalAngularVelocity( Angle( 0, 0, 10 ) )
            bolt:CallOnRemove( bolt.l_RemoveCall, function() 
                if !explosiveCvar:GetBool() then return end
                BoltExplode( ( IsValid( self ) and self or bolt ), bolt:GetPos() )
            end )

            self.l_Clip = self.l_Clip - 1
            return true
        end,

        reloadtime = 4.5,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_SMG1,
        reloadanimspeed = 0.5,
        reloadsounds = { { 0, "HL1Weapon_Crossbow.Reload" } },

        islethal = true
    }

} )