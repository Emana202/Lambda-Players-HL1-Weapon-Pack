local IsValid = IsValid
local CurTime = CurTime
local Rand = math.Rand
local random = math.random
local ents_Create = ents.Create
local svGravity = GetConVar( "sv_gravity" )

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
            trTbl.start = wepent:GetAttachment( 1 ).Pos
            trTbl.endpos = target:GetPos()
            trTbl.filter = target

            local selfFwd = self:GetForward()
            if selfFwd:Dot( ( trTbl.endpos - trTbl.start ):GetNormalized() ) < 0.66 then return end

            local tr = TraceLine( trTbl )
            if tr.Entity == self then self.l_WeaponUseCooldown = CurTime() + 0.25 return end

            if tr.Fraction != 1.0 then 
                trTbl.endpos = target:WorldSpaceCenter()
                if TraceLine( trTbl ).Fraction != 1.0 then self.l_WeaponUseCooldown = CurTime() + 0.25 return end
            end

            local rocket = ents_Create( "rpg_rocket" )
            if !IsValid( rocket ) then return end

            self.l_WeaponUseCooldown = CurTime() + 1.5
            wepent:EmitSound( "lambdaplayers/weapons/hl1/rpg/rocketfire1.wav", 80, 100, 0.9, CHAN_WEAPON )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )

            local spawnAng = ( trTbl.endpos - trTbl.start ):Angle()

            rocket:SetPos( trTbl.start )
            rocket:SetAngles( spawnAng )
            rocket:SetOwner( self )
            rocket:Spawn()

            local svgravity = svGravity:GetInt()
            if svgravity != 0 then rocket:SetGravity( 400 / svgravity ) end

            rocket.l_IsLambdaRocket = true
            rocket:SetModel( "models/lambdaplayers/weapons/hl1/props/rocket.mdl" )

            spawnAng.x = ( spawnAng.x - 30 )          
            rocket:SetLocalVelocity( spawnAng:Forward() * 250 + selfFwd * self.loco:GetVelocity():Dot( selfFwd ) )

            wepent.CurrentRocket = rocket
            return true
        end,

        islethal = true
    }

})