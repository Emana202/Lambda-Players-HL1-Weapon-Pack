local IsValid = IsValid
local CurTime = CurTime
local Rand = math.Rand
local random = math.random
local ents_Create = ents.Create
local svGravity = GetConVar( "sv_gravity" )
local TraceLine = util.TraceLine
local trTbl = {}
local laserMat = Material( "lambdaplayers/sprites/hl1_laserdot" )

local laserEnabled = CreateLambdaConvar( "lambdaplayers_weapons_hl1rpg_enablelaserguidance", 1, true, false, true, "Enables HL1 RPG's laser guidance system.", 0, 1, { type = "Bool", name = "HL1 RPG - Enable Laser Guidance", category = "Weapon Utilities" } )

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

        OnDraw = function( self, wepent )
            if !laserEnabled:GetBool() then return end

            local attachData = wepent:GetAttachment( 1 )
            trTbl.start = attachData.Pos
            trTbl.endpos = ( attachData.Pos + attachData.Ang:Forward() * 32756 )
            trTbl.filter = { self, wepent, wepent.CurrentRocket }

            local trDot = TraceLine( trTbl )
            if trDot.HitSky then return end

            render.SetMaterial( laserMat )
            render.DrawSprite( ( trDot.HitPos + trDot.HitNormal * 3 - EyeVector() * 4 ), 16, 16, color_white ) 
        end,

        OnDeploy = function( self, wepent )
            wepent.CurrentRocket = NULL
        end,

        OnHolster = function( self, wepent )
            wepent.CurrentRocket = nil
        end,

        OnThink = function( self, wepent, isdead )
            if !isdead and ( self.l_WeaponUseCooldown - CurTime() ) <= 2.0 and IsValid( wepent.CurrentRocket ) then
                self.l_WeaponUseCooldown = CurTime() + 2.0
            end
            return 0.1
        end,

        OnAttack = function( self, wepent, target )            
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

            self.l_WeaponUseCooldown = CurTime() + 2.0
            wepent:EmitSound( "lambdaplayers/weapons/hl1/rpg/rocketfire1.wav", 80, 100, 0.9, CHAN_WEAPON )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )

            local spawnAng = ( trTbl.endpos - trTbl.start ):Angle()

            rocket:SetPos( trTbl.start )
            rocket:SetAngles( spawnAng )
            rocket:SetOwner( self )
            rocket:Spawn()

            local gravity = svGravity:GetInt()
            if gravity != 0 then rocket:SetGravity( 400 / gravity ) end

            rocket.l_IsLambdaRocket = true
            rocket:SetModel( "models/lambdaplayers/weapons/hl1/props/rocket.mdl" )

            spawnAng.x = ( spawnAng.x - 30 )          
            rocket:SetLocalVelocity( spawnAng:Forward() * 250 + selfFwd * self.loco:GetVelocity():Dot( selfFwd ) )

            if laserEnabled:GetBool() then
                wepent.CurrentRocket = rocket
                self.l_WeaponUseCooldown = self.l_WeaponUseCooldown + 2.0

                local nextTargetTime = CurTime() + 0.4
                local fullIgnitionTime = CurTime() + 1.4

                rocket:LambdaHookTick( "Lambda_HL1Rocket_LaserGuidance", function()
                    if !LambdaIsValid( self ) or !IsValid( wepent ) or self:GetWeaponName() != "hl1_rpg" or !laserEnabled:GetBool() then 
                        if IsValid( wepent ) then wepent.CurrentRocket = NULL end
                        return true 
                    end
                    if CurTime() <= nextTargetTime then return end

                    local attachData = wepent:GetAttachment( 1 )
                    trTbl.start = attachData.Pos
                    trTbl.filter = { self, wepent, rocket }

                    local ene = self:GetEnemy()
                    if LambdaIsValid( ene ) then
                        trTbl.endpos = attachData.Pos + ( ene:GetPos() - attachData.Pos ):GetNormalized() * 32756
                    else
                        trTbl.endpos = attachData.Pos + attachData.Ang:Forward() * 32756
                    end
                    vecTarget = ( TraceLine( trTbl ).HitPos - trTbl.start ):GetNormalized()

                    rocket:SetAngles( vecTarget:Angle() )

                    local speed = rocket:GetVelocity():Length()
                    if CurTime() < fullIgnitionTime then
                        rocket:SetLocalVelocity( rocket:GetVelocity() * 0.2 + vecTarget * speed * 0.798 )
                    else
                        rocket:SetLocalVelocity( rocket:GetVelocity() * 0.2 + vecTarget * ( speed * 0.8 + 400 ) )
                        local speedLimit = ( rocket:WaterLevel() == 3 and 300 or 2000 )
                        if rocket:GetVelocity():Length() > speedLimit then rocket:SetLocalVelocity( rocket:GetVelocity():GetNormalized() * speedLimit ) end
                    end

                    nextTargetTime = CurTime() + 0.1
                end )
            end

            return true
        end,

        islethal = true
    }

})