if !IsMounted( "hl1" ) then return end

local CurTime = CurTime
local DamageInfo = DamageInfo

local physBoxMins = Vector( 19, 8, 2.25 )
local physBoxMaxs = Vector( -25, -2, -0.25 )

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_crowbar = {
        model = "models/weapons/w_crowbar_hls.mdl",
        origin = "Half-Life 1",
        prettyname = "Crowbar",
        holdtype = "melee",
        killicon = "lambdaplayers/killicons/icon_hl1_crowbar",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 60,

        OnDrop = function( cs_prop )
            cs_prop:PhysicsInitBox( physBoxMins, physBoxMaxs )
            cs_prop:PhysWake()
            cs_prop:GetPhysicsObject():SetMaterial( "crowbar" )
        end,

        callback = function( self, wepent, target )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )

            local dmg = ( ( CurTime() <= self.l_WeaponUseCooldown + 1.0 ) and 5 or 10 )
            local dmginfo = DamageInfo() 
            dmginfo:SetDamage( dmg )
            dmginfo:SetAttacker( self )
            dmginfo:SetInflictor( wepent )
            dmginfo:SetDamageType( DMG_CLUB )
            dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )

            target:TakeDamageInfo( dmginfo )
            wepent:EmitSound( "HL1Weapon_Crowbar.Melee_Hit", 70 )

            self.l_WeaponUseCooldown = CurTime() + 0.25
            return true
        end,

        islethal = true
    }

} )