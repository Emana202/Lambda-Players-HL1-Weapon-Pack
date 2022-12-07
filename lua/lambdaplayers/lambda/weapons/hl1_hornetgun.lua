if !IsMounted( "hl1" ) then return end

local IsValid = IsValid
local CurTime = CurTime
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local Rand = math.Rand
local random = math.random
local min = math.min
local SpriteTrail = util.SpriteTrail
local ents_Create = ents.Create
local timer_Simple = timer.Simple

local hornetMins, hornetMaxs = Vector( -4, -4, -4 ), Vector( 4, 4, 4 )
local hornetClrRed, hornetClrOrange = Color(179, 39, 14, 128), Color(255, 128, 0, 128)

local physBoxMins = Vector( -22, -7, -1.5 )
local physBoxMaxs = Vector( 15, 3, 8 )

local function OnDieTouch( self, ent )
    if self.l_DealtDamage or !ent or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end

    local owner = self:GetOwner()
    if IsValid( owner ) and ent:Health() > 0 and ent:GetClass() != "nihilanth_energy_ball" then
        self:EmitSound( "Hornet.Die" )
        local dmginfo = DamageInfo()
        dmginfo:SetAttacker( owner )
        dmginfo:SetInflictor( owner:GetWeaponENT() )
        dmginfo:SetDamage( 7 )
        dmginfo:SetDamageType( DMG_NEVERGIB )
        dmginfo:SetDamageForce( self:GetForward() * 2000 )
        dmginfo:SetDamagePosition( self:GetPos() )
        ent:TakeDamageInfo( dmginfo )
    end

    self.l_DealtDamage = true
    self:SetLocalVelocity( Vector() )
    self:SetMoveType( MOVETYPE_NONE )
    self:AddEffects( EF_NODRAW )
    self:AddSolidFlags( FSOLID_NOT_SOLID )
    SafeRemoveEntityDelayed( self, 1 )
end

local function OnTrackThink( self )
    if CurTime() > self.l_StopAttackTime then
        self:NextThink( CurTime() + 0.1 )
        SafeRemoveEntityDelayed( self, 0.1 )
        return true
    end

    self:FrameAdvance()
    
    local myPos = self:GetPos()
    local myVel = self:GetVelocity()

    local foundEnemy = false
    local owner = self:GetOwner()
    if IsValid( owner ) then
        local enemy = owner:GetEnemy()
        if IsValid( enemy ) then 
            local enePos = enemy:WorldSpaceCenter()
            if myPos:DistToSqr( enePos ) <= ( 512 * 512 ) and self:Visible( enemy ) then 
                foundEnemy = true
                self.l_EnemyLKP = enePos
            end
        end
    end
    if !foundEnemy then self.l_EnemyLKP = ( self.l_EnemyLKP + myVel * self.l_FlySpeed * 0.1 ) end

    local dirToEnemy = ( self.l_EnemyLKP - myPos ):GetNormalized()
    local flightDir = ( ( myVel:Length() < 0.1 ) and dirToEnemy or myVel:GetNormalized() )

    local delta = flightDir:Dot( dirToEnemy )
    if delta < 0.5 then self:EmitSound( "Hornet.Buzz" ) end

    local velDir = ( flightDir + dirToEnemy ):GetNormalized()
    if self.l_IsRed then
        if delta <= 0 then delta = 0.25 end
        self:SetLocalVelocity( velDir * ( self.l_FlySpeed * delta ) )
        self:NextThink( CurTime() + Rand( 0.1, 0.3 ) )
    else
        self:SetLocalVelocity( velDir * self.l_FlySpeed )
        self:NextThink( CurTime() + 0.1 )
    end

    self:SetAngles( self:GetVelocity():Angle() )
    self:SetSolid( SOLID_BBOX )

    return true
end

local function OnTrackTouch( self, ent )
    if ent.l_IsLambdaHornet or ent == self:GetOwner() then return end

    if !ent:IsNPC() and !ent:IsPlayer() and !ent:IsNextBot() then
        local vel = self:GetVelocity():GetNormalized()
        vel.x = vel.x * -1; vel.y = vel.y * -1

        self:SetPos( self:GetPos() + vel * 4 )
        self:SetLocalVelocity( vel * self.l_FlySpeed )

        return
    end

    OnDieTouch( self, ent )
end

local function OnTakeDamage( self, dmg )
    self:Remove()
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_hornetgun = {
        model = "models/weapons/w_hgun_hls.mdl",
        origin = "Half-Life 1",
        prettyname = "Hivehand",
        holdtype = "pistol",
        killicon = "lambdaplayers/killicons/icon_hl1_hornetgun",
        bonemerge = true,
        keepdistance = 750,
        attackrange = 1500,

        OnDrop = function( cs_prop )
            cs_prop:PhysicsInitBox( physBoxMins, physBoxMaxs )
            cs_prop:PhysWake()
            cs_prop:GetPhysicsObject():SetMaterial( "weapon" )
        end,

        OnEquip = function( self, wepent )
            wepent.UsingSecondaryFire = false
            wepent.HornetsLeft = 8
            wepent.FirePhase = 1
            wepent.RechargeTime = CurTime() + 0.5
        end,

        OnUnequip = function( self, wepent )
            wepent.UsingSecondaryFire = true
            wepent.HornetsLeft = nil
            wepent.FirePhase = nil
            wepent.RechargeTime = nil
        end,

        OnThink = function( self, wepent )
            if CurTime() <= wepent.RechargeTime then return end
            wepent.HornetsLeft = min( wepent.HornetsLeft + 1, 8 )
            wepent.RechargeTime = CurTime() + 0.5
        end,

        clip = 8,
        callback = function( self, wepent, target )
            if wepent.HornetsLeft > 0 then
                local spawnAng = ( target:WorldSpaceCenter() - wepent:GetPos() ):Angle()
                if self:GetForward():Dot( spawnAng:Forward() ) < 0.33 then return true end

                local hornet = ents_Create( "base_anim" )
                if IsValid( hornet ) then
                    hornet.l_IsLambdaHornet = true
                    hornet.l_IsRed = ( random( 1, 5 ) <= 2 )

                    local inRange = self:IsInRange( target, 300 )
                    if !wepent.UsingSecondaryFire then
                        if wepent.HornetsLeft > 4 then
                            wepent.UsingSecondaryFire = inRange
                        end
                    elseif !inRange then
                        wepent.UsingSecondaryFire = false
                    end

                    local spawnPos = ( wepent:GetPos() + spawnAng:Forward() * 24 + spawnAng:Right() * 8 + spawnAng:Up() * -12 )
                    if wepent.UsingSecondaryFire then
                        local curPhase = wepent.FirePhase
                        wepent.FirePhase = ( curPhase + 1 )

                        if curPhase == 1 then
                            spawnPos = ( spawnPos + spawnAng:Up() * 8 )
                        elseif curPhase == 2 then
                            spawnPos = ( spawnPos + spawnAng:Up() * 8 )
                            spawnPos = ( spawnPos + spawnAng:Right() * 8 )
                        elseif curPhase == 3 then
                            spawnPos = ( spawnPos + spawnAng:Right() * 8 )
                        elseif curPhase == 4 then
                            spawnPos = ( spawnPos + spawnAng:Up() * -8 )
                            spawnPos = ( spawnPos + spawnAng:Right() * 8 )
                        elseif curPhase == 5 then
                            spawnPos = ( spawnPos + spawnAng:Up() * -8 )
                        elseif curPhase == 6 then
                            spawnPos = ( spawnPos + spawnAng:Up() * -8 )
                            spawnPos = ( spawnPos + spawnAng:Right() * -8 )
                        elseif curPhase == 7 then
                            spawnPos = ( spawnPos + spawnAng:Right() * -8 )
                        elseif curPhase == 8 then
                            spawnPos = ( spawnPos + spawnAng:Up() * 8 )
                            spawnPos = ( spawnPos + spawnAng:Right() * -8 )
                            wepent.FirePhase = 1
                        end

                        hornet.Touch = OnDieTouch
                        timer_Simple( 4, function() if IsValid( hornet ) then hornet:Remove() end end )

                        self.l_WeaponUseCooldown = CurTime() + 0.1
                    else
                        hornet.Think = OnTrackThink
                        hornet.Touch = OnTrackTouch

                        hornet.l_FlySpeed = ( hornet.l_IsRed and 600 or 800 )
                        hornet.l_StopAttackTime = CurTime() + 3.5
                        hornet.l_EnemyLKP = target:WorldSpaceCenter()

                        self.l_WeaponUseCooldown = CurTime() + Rand( 0.25, 0.55 )
                    end

                    hornet:SetPos( spawnPos )
                    hornet:SetAngles( spawnAng )
                    hornet:SetOwner( self )
                    hornet:SetVelocity( spawnAng:Forward() * ( wepent.UsingSecondaryFire and 1200 or 300 ) )
                    hornet:Spawn()

                    hornet:SetMoveType( MOVETYPE_FLY )
                    hornet:SetSolid( SOLID_BBOX )
                    hornet:SetHealth( 1 )
                    hornet:SetModel( "models/hornet.mdl" )
                    hornet:SetCollisionBounds( hornetMins, hornetMaxs )
                    hornet:ResetSequenceInfo()
                    hornet.OnTakeDamage = OnTakeDamage

                    local trailColor = ( hornet.l_IsRed and hornetClrRed or hornetClrOrange )
                    SpriteTrail( hornet, 0, trailColor, true, 4, 2, 1, 0.05, "sprites/laserbeam.vmt" )

                    wepent:EmitSound( "Weapon_Hornetgun.Single", 70, 100, 1, CHAN_WEAPON )

                    self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )
                    self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )

                    wepent.HornetsLeft = ( wepent.HornetsLeft - 1 )
                    wepent.RechargeTime = CurTime() + 0.5
                end
            else
                wepent.UsingSecondaryFire = false
                self.l_WeaponUseCooldown = CurTime() + ( random( 1, 4 ) == 1 and Rand( 1.5, 3.0 ) or 0.25 )
            end

            return true
        end,

        islethal = true
    }

} )