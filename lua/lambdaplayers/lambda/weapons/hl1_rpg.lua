local IsValid = IsValid
local CurTime = CurTime
local Rand = math.Rand
local random = math.random
local ents_Create = ents.Create
local svGravity = GetConVar( "sv_gravity" )
local TraceLine = util.TraceLine
local trTbl = { filter = {} }
local laserMat = Material( "lambdaplayers/sprites/hl1_laserdot" )

local SetMaterial, DrawSprite
if ( CLIENT ) then
    SetMaterial = render.SetMaterial
    DrawSprite = render.DrawSprite
end

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
            trTbl.filter[ 1 ] = self
            trTbl.filter[ 2 ] = wepent
            trTbl.filter[ 3 ] = wepent:GetNW2Entity( "lambdahl1_rpgrocket", NULL )

            local trDot = TraceLine( trTbl )
            if trDot.HitSky then return end

            SetMaterial( laserMat )
            DrawSprite( ( trDot.HitPos + trDot.HitNormal * 3 - EyeVector() * 4 ), 16, 16, color_white ) 
        end,

        OnDeploy = function( self, wepent )
            wepent:SetNW2Entity( "lambdahl1_rpgrocket", NULL )
            wepent.RocketTargetTime = 0
            wepent.RocketIgniteTime = 0
        end,

        OnHolster = function( self, wepent )
            wepent.RocketTargetTime = nil
            wepent.RocketIgniteTime = nil
        end,

        OnThink = function( self, wepent, isdead )
            if isdead then return end

            local rocket = wepent:GetNW2Entity( "lambdahl1_rpgrocket", NULL )
            if !IsValid( rocket ) then return end
            
            local curTime = CurTime()
            if ( self.l_WeaponUseCooldown - curTime ) <= 2.0 then
                self.l_WeaponUseCooldown = ( curTime + 2.0 )
            end
            if curTime < wepent.RocketTargetTime or !laserEnabled:GetBool() then return end

            local attachData = wepent:GetAttachment( 1 )
            trTbl.start = attachData.Pos
            trTbl.filter[ 1 ] = self
            trTbl.filter[ 2 ] = wepent
            trTbl.filter[ 3 ] = rocket

            local ene = self:GetEnemy()
            if LambdaIsValid( ene ) and self:CanSee( ene ) then
                trTbl.endpos = ( attachData.Pos + ( ene:GetPos() - attachData.Pos ):GetNormalized() * 32756 )
            else
                trTbl.endpos = ( attachData.Pos + attachData.Ang:Forward() * 32756 )
            end

            vecTarget = ( TraceLine( trTbl ).HitPos - trTbl.start ):GetNormalized()
            rocket:SetAngles( vecTarget:Angle() )

            local speed = rocket:GetVelocity():Length()
            if curTime < wepent.RocketIgniteTime then
                rocket:SetLocalVelocity( rocket:GetVelocity() * 0.2 + vecTarget * speed * 0.798 )
            else
                rocket:SetLocalVelocity( rocket:GetVelocity() * 0.2 + vecTarget * ( speed * 0.8 + 400 ) )
                local speedLimit = ( rocket:WaterLevel() == 3 and 300 or 2000 )
                if rocket:GetVelocity():Length() > speedLimit then rocket:SetLocalVelocity( rocket:GetVelocity():GetNormalized() * speedLimit ) end
            end

            wepent.RocketTargetTime = ( curTime + 0.1 )
        end,

        OnAttack = function( self, wepent, target )
            trTbl.start = wepent:GetAttachment( 1 ).Pos
            trTbl.endpos = target:GetPos()
            trTbl.filter = target
            if self:GetForward():Dot( ( trTbl.endpos - trTbl.start ):GetNormalized() ) < 0.66 then return true end

            local tr = TraceLine( trTbl )
            if tr.Entity == self then self.l_WeaponUseCooldown = CurTime() + 0.25 return true end

            if tr.Fraction != 1.0 then 
                trTbl.endpos = target:WorldSpaceCenter()
                if TraceLine( trTbl ).Fraction != 1.0 then self.l_WeaponUseCooldown = CurTime() + 0.25 return true end
            end

            local rocket = ents_Create( "rpg_rocket" )
            if !IsValid( rocket ) then return true end

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

            wepent:SetNW2Entity( "lambdahl1_rpgrocket", rocket )
            wepent.RocketTargetTime = ( CurTime() + 0.4 )
            wepent.RocketIgniteTime = ( CurTime() + 1.4 )

            return true
        end,

        islethal = true
    }

})