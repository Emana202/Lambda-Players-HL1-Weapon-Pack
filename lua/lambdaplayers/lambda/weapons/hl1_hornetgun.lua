local IsValid = IsValid
local CurTime = CurTime
local ipairs = ipairs
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local Rand = math.Rand
local random = math.random
local min = math.min
local SpriteTrail = util.SpriteTrail
local ents_Create = ents.Create
local timer_Simple = timer.Simple
local FindInSphere = ents.FindInSphere
local ignorePlys = GetConVar( "ai_ignoreplayers" )

local hornetMins, hornetMaxs = Vector( -4, -4, -4 ), Vector( 4, 4, 4 )
local hornetClrRed, hornetClrOrange = Color(179, 39, 14, 128), Color(255, 128, 0, 128)

local function IsValidEnemy( self, ent )
    if !LambdaIsValid( ent ) or ent:Health() <= 0 then return false end
    local owner = self:GetOwner()
    if IsValid( owner ) then return owner:CanTarget( ent ) end
    return ( ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer() and ent:Alive() and !ignorePlys:GetBool() )
end

local function OnDieTouch( self, ent )
    if self.l_DealtDamage or !ent or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end

    local owner = self:GetOwner()
    if IsValid( owner ) and ent:Health() > 0 and ent:GetClass() != "nihilanth_energy_ball" then
        self:EmitSound( "lambdaplayers/weapons/hl1/hornetgun/ag_hornethit" .. random( 1, 3 ) .. ".wav", 75, 100, 1, CHAN_VOICE )
        local dmginfo = DamageInfo()
        dmginfo:SetAttacker( owner )
        dmginfo:SetInflictor( self )
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

    local enemy = self.l_Enemy
    if !IsValidEnemy( self, enemy ) then
        local myOwner = self:GetOwner()
        local myFwd = self:GetForward()

        local lastDist = nil
        for _, v in ipairs( FindInSphere( myPos, 512 ) ) do
            if v == myOwner or !IsValidEnemy( self, v ) or !self:Visible( v ) then continue end

            local targPos = v:WorldSpaceCenter()
            local targDot = myFwd:Dot( ( targPos - myPos ):GetNormalized() )
            if targDot <= 0.9 then continue end

            local curDist = myPos:DistToSqr( targPos )
            if lastDist and curDist >= lastDist then continue end

            enemy = v
            lastDist = curDist
        end
        
        self.l_Enemy = enemy
    end

    if LambdaIsValid( enemy ) and self:Visible( enemy ) then
        self.l_EnemyLKP = enemy:WorldSpaceCenter()
    else
        self.l_EnemyLKP = ( self.l_EnemyLKP + myVel * self.l_FlySpeed * 0.1 ) 
    end

    local dirToEnemy = ( self.l_EnemyLKP - myPos ):GetNormalized()
    local flightDir = ( ( myVel:Length() < 0.1 ) and dirToEnemy or myVel:GetNormalized() )

    local delta = flightDir:Dot( dirToEnemy )
    if delta < 0.5 then self:EmitSound( "lambdaplayers/weapons/hl1/hornetgun/ag_buzz" .. random( 1, 3 ) .. ".wav", 70, 100, 0.8, CHAN_VOICE ) end

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
    if ent.l_IsLambdaHornet then return end

    local owner = self:GetOwner()
    if ent == owner then return end

    if !ent:IsNPC() and !ent:IsPlayer() and !ent:IsNextBot() or IsValid( owner ) and !owner:CanTarget( ent ) then
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
        model = "models/lambdaplayers/weapons/hl1/w_hornetgun.mdl",
        origin = "Half-Life 1",
        prettyname = "Hivehand",
        holdtype = "pistol",
        killicon = "lambdaplayers/killicons/icon_hl1_hornetgun",
        bonemerge = true,
        keepdistance = 750,
        attackrange = 1500,

        OnDeploy = function( self, wepent )
            wepent.UsingSecondaryFire = false
            wepent.FirePhase = 1
            wepent.RechargeTime = CurTime() + 0.5
        end,

        OnHolster = function( self, wepent )
            wepent.UsingSecondaryFire = true
            wepent.FirePhase = nil
            wepent.RechargeTime = nil
        end,

        OnThink = function( self, wepent, isdead )
            if !isdead and CurTime() <= wepent.RechargeTime then return end
            wepent.RechargeTime = CurTime() + 0.5
            
            local hornetCount = self.l_Clip
            if hornetCount == -1 then hornetCount = 0 end
            self.l_Clip = min( hornetCount + 1, 8 )
        end,

        clip = 8,
        OnAttack = function( self, wepent, target )
            if self.l_Clip > 0 then
                local spawnPos = wepent:GetAttachment( 1 ).Pos
                local spawnAng = ( target:WorldSpaceCenter() - spawnPos ):Angle()
                if self:GetForward():Dot( spawnAng:Forward() ) < 0.33 then return true end

                local hornet = ents_Create( "base_anim" )
                if IsValid( hornet ) then
                    hornet.l_IsLambdaHornet = true
                    hornet.l_IsRed = ( random( 1, 5 ) <= 2 )

                    local inRange = self:IsInRange( target, 350 )
                    if !wepent.UsingSecondaryFire then
                        if self.l_Clip > 4 then
                            wepent.UsingSecondaryFire = inRange
                        end
                    elseif !inRange then
                        wepent.UsingSecondaryFire = false
                    end

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
                        hornet.l_Enemy = NULL
                        hornet.l_EnemyLKP = target:WorldSpaceCenter()

                        self.l_WeaponUseCooldown = CurTime() + 0.25
                    end

                    hornet:SetPos( spawnPos )
                    hornet:SetAngles( spawnAng )
                    hornet:SetOwner( self )
                    hornet:SetVelocity( spawnAng:Forward() * ( wepent.UsingSecondaryFire and 1200 or 300 ) )
                    hornet:Spawn()

                    hornet:SetMoveType( MOVETYPE_FLY )
                    hornet:SetSolid( SOLID_BBOX )
                    hornet:SetHealth( 1 )
                    hornet:SetModel( "models/lambdaplayers/weapons/hl1/props/hornet.mdl" )
                    hornet:SetCollisionBounds( hornetMins, hornetMaxs )
                    hornet:ResetSequenceInfo()
                    
                    hornet.OnTakeDamage = OnTakeDamage
                    hornet.l_UseLambdaDmgModifier = true
                    hornet.l_killiconname = wepent.l_killiconname

                    local trailColor = ( hornet.l_IsRed and hornetClrRed or hornetClrOrange )
                    SpriteTrail( hornet, 0, trailColor, true, 4, 2, 1, 0.05, "sprites/laserbeam.vmt" )

                    wepent:EmitSound( "lambdaplayers/weapons/hl1/hornetgun/ag_fire" .. random( 1, 3 ) .. ".wav", 75, 100, 1, CHAN_WEAPON )

                    self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )
                    self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )

                    local hornetLeft = ( self.l_Clip - 1 )
                    if hornetLeft == 0 then hornetLeft = -1 end
                    self.l_Clip = hornetLeft

                    wepent.RechargeTime = CurTime() + 0.5
                end
            else
                wepent.UsingSecondaryFire = false
                self.l_WeaponUseCooldown = CurTime() + ( random( 1, 6 ) == 1 and Rand( 1.0, 3.0 ) or 0.25 )
            end

            return true
        end,

        islethal = true
    }

} )