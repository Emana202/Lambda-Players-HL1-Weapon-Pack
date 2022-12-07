-- if !IsMounted( "hl1" ) then return end

local IsValid = IsValid
local CurTime = CurTime
local Rand = math.Rand
local random = math.random

local shellPos = Vector( -8, -1, 0 )
local shellAng = Angle( 0, 90, 0 )
local physBoxMins = Vector( -23, -3, 1 )
local physBoxMaxs = Vector( 6, 6, 3 )

local bulletData = {
    Damage = 5,
    Force = 5,
    HullSize = 5,
    TracerName = "Tracer"
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_shotgun = {
        model = "models/weapons/w_shotgun_hls.mdl",
        origin = "Half-Life 1",
        prettyname = "SPAS-12",
        holdtype = "shotgun",
        killicon = "lambdaplayers/killicons/icon_hl1_shotgun",
        bonemerge = true,
        keepdistance = 400,
        attackrange = 600,

        OnDrop = function( cs_prop )
            cs_prop:PhysicsInitBox( physBoxMins, physBoxMaxs )
            cs_prop:PhysWake()
            cs_prop:GetPhysicsObject():SetMaterial( "weapon" )
        end,

        clip = 8,
        reloadtime = 3,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        reloadanimspeed = 1,

        callback = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )

            local pumpTime = 0.5
            if self.l_Clip >= 2 and random( 8 ) == 1 and self:IsInRange( target, 600 ) then
                pumpTime = 0.9
                self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )

                self.l_Clip = self.l_Clip - 2
                wepent:EmitSound( "HL1Weapon_Shotgun.Double" )
                self.l_WeaponUseCooldown = CurTime() + Rand( 1.5, 1.75 )

                bulletData.Num = 12
                bulletData.Spread = Vector( 0.2, 0.2, 0 )
            else
                self.l_Clip = self.l_Clip - 1
                wepent:EmitSound( "HL1Weapon_Shotgun.Single" )
                self.l_WeaponUseCooldown = CurTime() + Rand( 0.8, 0.95 )
                
                bulletData.Num = 6
                bulletData.Spread = Vector( 0.125, 0.125, 0 )
            end

            self:HandleMuzzleFlash( 1 )

            bulletData.Attacker = self
            bulletData.IgnoreEntity = self
            bulletData.Src = wepent:GetPos()
            bulletData.Dir = ( target:WorldSpaceCenter() - bulletData.Src ):GetNormalized()
            wepent:FireBullets( bulletData )

            self:SimpleTimer( pumpTime, function()
                if !IsValid( wepent ) or self:GetWeaponName() != "hl1_shotgun" then return end
                wepent:EmitSound( "HL1Weapon_Shotgun.Special1" )
                self:HandleShellEject( "ShotgunShellEject", shellPos, shellAng )
            end)

            return true
        end,

        islethal = true
    }

} )