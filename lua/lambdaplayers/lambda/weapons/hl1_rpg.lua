if !IsMounted( "hl1" ) then return end

local IsValid = IsValid
local CurTime = CurTime
local Rand = math.Rand
local ents_Create = ents.Create

local TraceLine = util.TraceLine
local trTbl = {}

local physBoxMins = Vector( -28, -5, 2 )
local physBoxMaxs = Vector( 24, 3, 11 )

if ( CLIENT ) then
    killicon.Add( "rpg_rocket", "lambdaplayers/killicons/icon_hl1_rpg", Color( 255, 80, 0, 255 ) )
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_rpg = {
        model = "models/weapons/w_rpg_hls.mdl",
        origin = "Half-Life 1",
        prettyname = "RPG",
        holdtype = "rpg",
        killicon = "rpg_rocket",
        bonemerge = true,
        keepdistance = 800,
        attackrange = 3000,

        OnDrop = function( cs_prop )
            cs_prop:PhysicsInitBox( physBoxMins, physBoxMaxs )
            cs_prop:PhysWake()
            cs_prop:GetPhysicsObject():SetMaterial( "weapon" )
        end,

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
            trTbl.endpos = target:GetPos()
            trTbl.filter = target

            local spawnAng = ( trTbl.endpos - trTbl.start ):Angle()
            trTbl.start = ( trTbl.start + spawnAng:Forward() * 32 + spawnAng:Right() * 8 - spawnAng:Up() * 8 )
            spawnAng = ( trTbl.endpos - trTbl.start ):Angle()

            local selfFwd = self:GetForward()
            if selfFwd:Dot( spawnAng:Forward() ) < 0.33 then return end

            if TraceLine( trTbl ).Fraction != 1.0 then 
                trTbl.endpos = target:WorldSpaceCenter()
                if TraceLine( trTbl ).Fraction != 1.0 then return end
            end

            local rocket = ents_Create( "rpg_rocket" )
            if !IsValid( rocket ) then return end

            self.l_WeaponUseCooldown = CurTime() + 1.5
            wepent:EmitSound( "HL1Weapon_RPG.Single" )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )

            rocket:SetPos( trTbl.start )
            rocket:SetAngles( spawnAng )
            rocket:SetOwner( self )
            rocket:Spawn()

            wepent.CurrentRocket = rocket
            return true
        end,

        islethal = true
    }

})