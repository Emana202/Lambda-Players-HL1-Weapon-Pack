local IsValid = IsValid
local CurTime = CurTime
local Rand = math.Rand
local ents_Create = ents.Create

local TraceLine = util.TraceLine
local trTbl = {}

if ( CLIENT ) then
    killicon.Add( "rpg_rocket", "lambdaplayers/killicons/icon_hl1_rpg", Color( 255, 80, 0, 255 ) )
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_rpg = {
        model = "models/lambdaplayers/weapons/hl1/w_rpg.mdl",
        origin = "Half-Life 1",
        prettyname = "RPG",
        holdtype = "rpg",
        killicon = "rpg_rocket",
        bonemerge = true,
        keepdistance = 800,
        attackrange = 3000,

        OnEquip = function( lambda, wepent )
            wepent.CurrentRocket = NULL
        end,

        OnThink = function( lambda, wepent )
            if IsValid( wepent.CurrentRocket ) then lambda.l_WeaponUseCooldown = CurTime() + 2.0 end
            return 0.1
        end,

        OnUnequip = function( lambda, wepent )
            wepent.CurrentRocket = nil
        end,

        callback = function( self, wepent, target )            
            trTbl.start = self:GetAttachmentPoint( "eyes" ).Pos
            trTbl.endpos = ( target:GetPos() + ( target:IsNextBot() and target.loco or target ):GetVelocity() * Rand( 0.2, 0.8 ) )
            trTbl.filter = target

            local spawnAng = ( trTbl.endpos - trTbl.start ):Angle()
            trTbl.start = ( trTbl.start + spawnAng:Forward() * 32 + spawnAng:Right() * 8 - spawnAng:Up() * 16 )
            spawnAng = ( trTbl.endpos - trTbl.start ):Angle()
            if self:GetForward():Dot( spawnAng:Forward() ) < 0.33 then return end

            if TraceLine( trTbl ).Fraction != 1.0 then 
                trTbl.endpos = target:WorldSpaceCenter()
                if TraceLine( trTbl ).Fraction != 1.0 then return end
            end

            local rocket = ents_Create( "rpg_rocket" )
            if !IsValid( rocket ) then return end

            self.l_WeaponUseCooldown = CurTime() + 1.5
            wepent:EmitSound( "lambdaplayers/weapons/hl1/rpg/rocketfire1.wav", SNDLVL_GUNFIRE, 100, 0.9, CHAN_WEAPON )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )

            rocket:SetPos( trTbl.start )
            rocket:SetAngles( ( trTbl.endpos - trTbl.start ):Angle() )
            rocket:SetOwner( self )
            rocket:Spawn()

            rocket.l_IsLambdaRocket = true
            rocket:SetModel( "models/lambdaplayers/weapons/hl1/props/rocket.mdl" )
            rocket:CallOnRemove( "Lambda_HL1Rocket_StopSound" .. rocket:EntIndex(), function() rocket:StopSound( "lambdaplayers/weapons/hl1/rpg/rocket1.wav" ) end )

            wepent.CurrentRocket = rocket
            return true
        end,

        islethal = true
    }

})