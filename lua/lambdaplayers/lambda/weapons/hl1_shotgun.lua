local IsValid = IsValid
local CurTime = CurTime
local Rand = math.Rand
local random = math.random
local coroutine_wait = coroutine.wait

local shellPos = Vector( -8, -1, 0 )
local shellAng = Angle( 0, 90, 0 )

local bulletData = {
    Damage = 5,
    Force = 5,
    HullSize = 5,
    TracerName = "Tracer",
    Spread = Vector( 0.1, 0.1, 0 )
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_shotgun = {
        model = "models/lambdaplayers/weapons/hl1/w_shotgun.mdl",
        origin = "Half-Life 1",
        prettyname = "SPAS-12",
        holdtype = "shotgun",
        killicon = "lambdaplayers/killicons/icon_hl1_shotgun",
        bonemerge = true,
        keepdistance = 600,
        attackrange = 800,

        clip = 8,
        callback = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )

            local pumpTime = 0.5
            if self.l_Clip >= 2 and random( 5 ) == 1 and self:IsInRange( target, 300 ) then
                pumpTime = 0.9
                self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
                self.l_Clip = self.l_Clip - 2
                wepent:EmitSound( "lambdaplayers/weapons/hl1/shotgun/dbarrel1.wav", 85, random( 85, 115 ), 1, CHAN_WEAPON )
                self.l_WeaponUseCooldown = CurTime() + 1.6
                bulletData.Num = 12
            else
                self.l_Clip = self.l_Clip - 1
                wepent:EmitSound( "lambdaplayers/weapons/hl1/shotgun/sbarrel1.wav", 90, random( 93, 124 ), 1, CHAN_WEAPON )
                self.l_WeaponUseCooldown = CurTime() + 0.85
                bulletData.Num = 6
            end

            self:HandleMuzzleFlash( 1 )

            bulletData.Attacker = self
            bulletData.IgnoreEntity = self
            bulletData.Src = wepent:GetPos()
            bulletData.Dir = ( target:WorldSpaceCenter() - bulletData.Src ):GetNormalized()
            wepent:FireBullets( bulletData )

            self:SimpleTimer( pumpTime, function()
                if !IsValid( wepent ) or self:GetWeaponName() != "hl1_shotgun" then return end
                wepent:EmitSound( "lambdaplayers/weapons/hl1/shotgun/scock1.wav", SNDLVL_NORM, 100, 1, CHAN_ITEM )
                self:HandleShellEject( "ShotgunShellEject", shellPos, shellAng )
            end)

            return true
        end,

        OnReload = function( self, wepent )
            local animID = self:LookupSequence( "reload_shotgun_base_layer" )
            if animID != -1 then 
                self:AddGestureSequence( animID ) 
            else 
                self:AddGesture( ACT_HL2MP_GESTURE_RELOAD_SHOTGUN )
            end

            self:SetIsReloading( true )
            self:Thread( function()

                coroutine_wait( 0.66 )

                while ( self.l_Clip < self.l_MaxClip ) do
                    local ene = self:GetEnemy()
                    if self.l_Clip > 0 and random( 1, 2 ) == 1 and self:InCombat() and self:IsInRange( ene, 512 ) and self:CanSee( ene ) then break end
                    self.l_Clip = self.l_Clip + 1
                    wepent:EmitSound( "lambdaplayers/weapons/hl1/shotgun/reload" .. random( 1, 2 ) .. ".wav", 80, 85 + random( 0, 31 ), 1, CHAN_ITEM )
                    coroutine_wait( 0.5625 )
                end

                wepent:EmitSound( "lambdaplayers/weapons/hl1/shotgun/scock1.wav", SNDLVL_NORM, 100, 1, CHAN_ITEM )
                local ene = self:GetEnemy()
                if self.l_Clip > 0 and random( 1, 2 ) == 1 and self:InCombat() and self:IsInRange( ene, 512 ) and self:CanSee( ene ) then 
                    coroutine_wait( 0.75 )
                end

                self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_SHOTGUN )
                self:SetIsReloading( false )

            end, "HL1_ShotgunReload" )

            return true
        end,

        islethal = true
    }

} )