local CurTime = CurTime
local random = math.random
local Rand = math.Rand

local bulletData = {
    Damage = 40,
    Spread = Vector( 0.1, 0.1, 0 ),
    Force = 10,
    HullSize = 5,
    TracerName = "Tracer"
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_revolver = {
        model = "models/lambdaplayers/weapons/hl1/w_357.mdl",
        origin = "Half-Life 1",
        prettyname = ".357 Magnum",
        holdtype = "pistol",
        killicon = "lambdaplayers/killicons/icon_hl1_revolver",
        bonemerge = true,
        keepdistance = 750,
        attackrange = 2000,

        clip = 6,
        OnAttack = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end

            self.l_WeaponUseCooldown = CurTime() + Rand( 0.8, 1.2 )
            wepent:EmitSound( "lambdaplayers/weapons/hl1/357/357_shot" .. random( 1, 2 ) .. ".wav", 90, random( 95, 105 ), 1, CHAN_WEAPON )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )

            self:HandleMuzzleFlash( 1 )

            bulletData.Attacker = self
            bulletData.IgnoreEntity = self
            bulletData.Src = wepent:GetPos()
            bulletData.Dir = ( target:WorldSpaceCenter() - bulletData.Src ):GetNormalized()
            wepent:FireBullets( bulletData )

            self.l_Clip = self.l_Clip - 1

            return true
        end,

        reloadtime = 3.05,
        reloadsounds = { { 2, "lambdaplayers/weapons/hl1/357/357_reload1.wav" } },

        OnReload = function( self, wepent )
            local animLayer
            local animID = self:LookupSequence( "reload_revolver_base_layer" )
            if animID != -1 then
                animLayer = self:AddGestureSequence( animID )
                self:SetLayerBlendIn( animLayer, 0.2 )
                self:SetLayerBlendOut( animLayer, 0.2 )
            else
                animLayer = self:AddGesture( ACT_HL2MP_GESTURE_RELOAD_REVOLVER )
            end
            self:SetLayerPlaybackRate( animLayer, 1.25 )
        end,

        islethal = true
    }

} )