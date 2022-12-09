local CurTime = CurTime
local Rand = math.Rand
local random = math.random

local shellPos = Vector( 1, 4, 0 )
local shellAng = Angle( 0, 90, 0 )

local bulletData = {
    Damage = 8,
    Force = 8,
    HullSize = 5,
    TracerName = "Tracer"
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_pistol = {
        model = "models/lambdaplayers/weapons/hl1/w_9mmhandgun.mdl",
        origin = "Half-Life 1",
        prettyname = "9mm Pistol",
        holdtype = "revolver",
        killicon = "lambdaplayers/killicons/icon_hl1_glock",
        bonemerge = true,
        keepdistance = 650,
        attackrange = 1500,

        clip = 17,
        callback = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end

            local inQuickFireRange = self:IsInRange( target, 300 )

            self.l_WeaponUseCooldown = CurTime() + ( inQuickFireRange and 0.2 or Rand( 0.3, 0.4 ) )
            wepent:EmitSound( "lambdaplayers/weapons/hl1/9mmhandgun/pl_gun3.wav", 85, random( 95, 105 ), 1, CHAN_WEAPON )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )

            self:HandleMuzzleFlash( 1 )
            self:HandleShellEject( "ShellEject", shellPos, shellAng )

            local spread = ( inQuickFireRange and 0.25 or 0.1 )
            bulletData.Spread = Vector( spread, spread, 0 )
            bulletData.Attacker = self
            bulletData.IgnoreEntity = self
            bulletData.Src = wepent:GetPos()
            bulletData.Dir = ( target:WorldSpaceCenter() - bulletData.Src ):GetNormalized()
            wepent:FireBullets( bulletData )

            self.l_Clip = self.l_Clip - 1

            return true
        end,

        reloadtime = 2.28,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimspeed = 0.66,
        reloadsounds = { 
            { 0.22, "lambdaplayers/weapons/hl1/9mmhandgun/9mmclip2.wav" },
            { 1.28, "lambdaplayers/weapons/hl1/9mmhandgun/9mmclip1.wav" }
        },

        islethal = true
    }

} )