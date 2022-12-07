-- if !IsMounted( "hl1" ) then return end

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

local physBoxMins = Vector( -34, -3, 0 )
local physBoxMaxs = Vector( 10, 4, 10 )

local function FireBeam( lambda, wepent, pos, damage, rof )
    lambda.l_WeaponUseCooldown = CurTime() + ( rof or Rand( 0.2, 0.4 ) )
    lambda:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
    lambda:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )

    wepent:EmitSound( "Weapon_Gauss.Fire" )
    wepent.AfterShockSound = CurTime() + Rand( 0.3, 0.8 )

    trTbl.start = wepent:GetPos()
    trTbl.endpos = ( trTbl.start + ( pos - trTbl.start ):GetNormalized() * 8192 + VectorRand( -200, 200 ) )
    trTbl.filter = { lambda, wepent }
    local tr = TraceLine( trTbl )

    local beameffect = EffectData()
    beameffect:SetFlags( 1 )
    beameffect:SetStart( tr.StartPos )
    beameffect:SetOrigin( tr.HitPos )
    util_Effect( "HL1GaussBeamReflect", beameffect )

    util_Decal( "FadingScorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal )

    local hitEnt = tr.Entity
    if !IsValid( hitEnt ) then return end
    
    if hitEnt:Health() > 0 then
        local dmginfo = DamageInfo()
        dmginfo:SetAttacker( lambda )
        dmginfo:SetInflictor( wepent )
        dmginfo:SetDamage( damage or 20 )
        dmginfo:SetDamageType( DMG_ENERGYBEAM )
        dmginfo:SetDamageForce( lambda:GetForward() * 16000 )
        hitEnt:DispatchTraceAttack( dmginfo, tr )
    end

    if !hitEnt:IsPlayer() then
        local phys = hitEnt:GetPhysicsObject()
        if IsValid( phys ) then phys:ApplyForceOffset( lambda:GetForward() * 4000, tr.HitPos ) end
    end
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_gauss = {
        model = "models/weapons/w_gauss_hls.mdl",
        origin = "Half-Life 1",
        prettyname = "Tau Cannon",
        holdtype = "shotgun",
        killicon = "lambdaplayers/killicons/icon_hl1_gauss",
        bonemerge = true,
        keepdistance = 750,
        attackrange = 2000,

        OnDrop = function( cs_prop )
            cs_prop:PhysicsInitBox( physBoxMins, physBoxMaxs )
            cs_prop:PhysWake()
            cs_prop:GetPhysicsObject():SetMaterial( "weapon" )
        end,

        OnEquip = function( self, wepent )
            wepent.AfterShockSound = 0
            wepent:CallOnRemove( "Lambda_HL1Gauss_StopChargeSound" .. wepent:EntIndex(), function()
                if wepent.ChargeSound then wepent.ChargeSound:Stop(); wepent.ChargeSound = nil end
            end )
        end,

        OnUnequip = function( self, wepent )
            wepent.AfterShockSound = nil
            wepent:RemoveCallOnRemove( "Lambda_HL1Gauss_StopChargeSound" .. wepent:EntIndex() )
        end,

        OnThink = function( self, wepent )
            local shockSnd = wepent.AfterShockSound
            if shockSnd > 0 and CurTime() > shockSnd then
                local rndSnd = random( 3, 6 )
                if rndSnd > 3 then wepent:EmitSound( "weapons/electro" .. rndSnd .. ".wav", 100, 100, Rand( 0.7, 0.8 ), CHAN_AUTO ) end
                wepent.AfterShockSound = 0
            end
        end,

        clip = 100,
        callback = function( self, wepent, target )
            if random( 1, 20 ) == 1 then
                self.l_WeaponUseCooldown = CurTime() + 0.5

                if !wepent.ChargeSound then wepent.ChargeSound = CreateSound( wepent, "Weapon_Gauss.Spin" ) end
                wepent.ChargeSound:PlayEx( 0.7, 110 )
                wepent.ChargeSound:ChangePitch( 250, 4 )

                local startTime = CurTime()
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
                    local holdTime = ( CurTime() - startTime )

                    if holdTime >= ( chargeTime * ( self:CanSee( fireTarget ) and 1 or Rand( 1.75, 2.5 ) ) ) or !LambdaIsValid( fireTarget ) or self:Health() < ( startHealth * 0.5 ) then
                        wepent.ChargeSound:Stop()
                        wepent.ChargeSound = nil

                        local firePos = ( LambdaIsValid( fireTarget ) and fireTarget:WorldSpaceCenter() or ( self:WorldSpaceCenter() + self:GetForward() * 8192 ) )
                        FireBeam( self, wepent, firePos, min( 200, 200 * ( holdTime * 0.25 ) ), Rand( 0.66, 1.0 ) )

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