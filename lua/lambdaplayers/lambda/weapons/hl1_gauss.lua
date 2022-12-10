local IsValid = IsValid
local CurTime = CurTime
local EffectData = EffectData
local DamageInfo = DamageInfo
local CreateSound = CreateSound
local VectorRand = VectorRand
local random = math.random
local Rand = math.Rand
local min = math.min
local util_Decal = util.Decal
local util_Effect = util.Effect

local TraceLine = util.TraceLine
local trTbl = {}

local function FireBeam( lambda, wepent, pos, secondaryFire )
    lambda.l_WeaponUseCooldown = CurTime() + ( !secondaryFire and Rand( 0.2, 0.4 ) or Rand( 0.66, 1.0 ) )
    lambda:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )
    lambda:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )

    wepent:EmitSound( "lambdaplayers/weapons/hl1/gauss/gauss2.wav", 90, random( 80, 111 ), 1, CHAN_WEAPON )
    wepent.AfterShockSound = CurTime() + Rand( 0.3, 0.8 )

    local fireStart = wepent:GetAttachment( 1 ).Pos
    local fireDir = ( pos - fireStart ):Angle()
    
    local accuracyDecay = ( 400 * ( lambda:GetRangeSquaredTo( pos ) / ( 1024 * 1024 ) ) )
    if secondaryFire then accuracyDecay = accuracyDecay * 0.5 end
    local fireEnd = ( fireStart + fireDir:Forward() * 8192 + fireDir:Right() * random( -accuracyDecay, accuracyDecay ) + fireDir:Up() * random( -accuracyDecay, accuracyDecay ) )

    trTbl.start = fireStart
    trTbl.endpos = fireEnd
    trTbl.filter = lambda
    local tr = TraceLine( trTbl )

    local beameffect = EffectData()
    beameffect:SetFlags( secondaryFire and 0 or 1 )
    beameffect:SetStart( fireStart )
    beameffect:SetOrigin( tr.HitPos )
    util_Effect( "HL1GaussBeamReflect", beameffect )

    util_Decal( "FadingScorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal )

    local balleffect = EffectData()
    balleffect:SetOrigin( tr.HitPos )
    balleffect:SetNormal( tr.HitNormal )
    util_Effect( "HL1GaussReflect", balleffect )

    local hitEnt = tr.Entity
    if !IsValid( hitEnt ) then return end
    
    local damage = ( secondaryFire and min( 200, 200 * ( ( ( CurTime() - wepent.ChargeStartTime ) ) * 0.25 ) ) or 20 )

    if hitEnt:Health() > 0 then
        local dmginfo = DamageInfo()
        dmginfo:SetAttacker( lambda )
        dmginfo:SetInflictor( wepent )
        dmginfo:SetDamage( damage )
        dmginfo:SetDamageType( DMG_ENERGYBEAM )
        dmginfo:SetDamageForce( fireDir:Forward() * damage * 600 )
        dmginfo:SetDamagePosition( tr.HitPos )
        hitEnt:DispatchTraceAttack( dmginfo, tr )
    end

    if !hitEnt:IsPlayer() then
        local phys = hitEnt:GetPhysicsObject()
        if IsValid( phys ) then phys:ApplyForceOffset( fireDir:Forward() * damage * 200, tr.HitPos ) end
    end
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_gauss = {
        model = "models/lambdaplayers/weapons/hl1/w_gauss.mdl",
        origin = "Half-Life 1",
        prettyname = "Tau Cannon",
        holdtype = "shotgun",
        killicon = "lambdaplayers/killicons/icon_hl1_gauss",
        bonemerge = true,
        keepdistance = 750,
        attackrange = 2000,

        OnEquip = function( self, wepent )
            wepent.AfterShockSound = 0
            wepent.ChargeStartTime = 0
            wepent:CallOnRemove( "Lambda_HL1Gauss_StopChargeSound" .. wepent:EntIndex(), function()
                if wepent.ChargeSound then wepent.ChargeSound:Stop(); wepent.ChargeSound = nil end
            end )
        end,

        OnUnequip = function( self, wepent )
            wepent.AfterShockSound = nil
            wepent.ChargeStartTime = nil
            wepent:RemoveCallOnRemove( "Lambda_HL1Gauss_StopChargeSound" .. wepent:EntIndex() )
        end,

        OnThink = function( self, wepent )
            local shockSnd = wepent.AfterShockSound
            if shockSnd > 0 and CurTime() > shockSnd then
                local rndSnd = random( 3, 6 )
                if rndSnd > 3 then wepent:EmitSound( "lambdaplayers/weapons/hl1/gauss/electro" .. rndSnd .. ".wav", 100, 100, Rand( 0.7, 0.8 ), CHAN_AUTO ) end
                wepent.AfterShockSound = 0
            end
        end,

        clip = 100,
        callback = function( self, wepent, target )
            if random( 1, 10 ) == 1 then
                self.l_WeaponUseCooldown = CurTime() + 0.5

                if !wepent.ChargeSound then wepent.ChargeSound = CreateSound( wepent, "lambdaplayers/weapons/hl1/gauss/pulsemachine.wav" ) end
                wepent.ChargeSound:PlayEx( 0.7, 110 )
                wepent.ChargeSound:ChangePitch( 250, 4 )

                wepent.ChargeStartTime = CurTime()

                local chargeTime = Rand( 1, 4 )
                local startHealth = self:Health()
                self:Hook( "Think", "LambdaPlayer_HL1Gauss_SecondaryFire", function()
                    if ( !LambdaIsValid( self ) or !IsValid( wepent ) or self:GetWeaponName() != "hl1_gauss" ) and wepent.ChargeSound then 
                        wepent.ChargeSound:Stop() 
                        wepent.ChargeSound = nil 
                        return "end" 
                    end

                    self.l_WeaponUseCooldown = CurTime() + 0.5

                    local fireTarget = self:GetEnemy()
                    local holdTime = ( CurTime() - wepent.ChargeStartTime )

                    if holdTime >= ( chargeTime * ( self:CanSee( fireTarget ) and 1 or Rand( 1.75, 2.5 ) ) ) or !LambdaIsValid( fireTarget ) or self:Health() < ( startHealth * 0.5 ) then
                        wepent.ChargeSound:Stop()
                        wepent.ChargeSound = nil

                        local firePos = ( LambdaIsValid( fireTarget ) and fireTarget:WorldSpaceCenter() or ( self:WorldSpaceCenter() + self:GetForward() * 8192 ) )
                        FireBeam( self, wepent, firePos, true )

                        return "end"
                    end
                end, true, 0.1 )
            else
                FireBeam( self, wepent, target:WorldSpaceCenter() )
            end

            return true
        end,

        islethal = true
    }

} )