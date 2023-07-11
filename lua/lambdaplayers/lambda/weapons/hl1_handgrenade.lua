local IsValid = IsValid
local CurTime = CurTime
local EffectData = EffectData
local Rand = math.Rand
local random = math.random
local ents_Create = ents.Create
local timer_Simple = timer.Simple
local svGravity = GetConVar( "sv_gravity" )
local util_Effect = util.Effect
local util_BlastDamage = util.BlastDamage
local util_Decal = util.Decal

local TraceLine = util.TraceLine
local trTbl = {}

local vec3_origin = Vector()
local vec3_angles = Angle()

local function OnGrenadeTouch( self, ent )
    if ent == self:GetOwner() or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end
    if ent:IsPlayer() then self:SetCollisionGroup( COLLISION_GROUP_DEBRIS ) end

    local selfPos = self:GetPos()

    trTbl.start = selfPos
    trTbl.endpos = ( trTbl.start - Vector( 0, 0, 10 ) )
    trTbl.mask = MASK_SOLID_BRUSHONLY
    trTbl.filter = self    
    if TraceLine( trTbl ).Fraction < 1.0 then
        self:SetSequence( self:SelectWeightedSequence( ACT_IDLE ) )
        self:SetAngles( vec3_angles )
    end

    local selfVel = self:GetVelocity()
    if !ent:IsWorld() then
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then phys:ApplyForceOffset( selfVel * 8, selfPos ) end
    end

    local velRate = ( selfVel:Length() / 200 )
    self:SetPlaybackRate( ( velRate > 1 ) and 1 or ( ( velRate < 0.5 ) and 0 or velRate ) )

    self:EmitSound( "lambdaplayers/weapons/hl1/grenade/grenade_hit" .. random( 1, 3 ) .. ".wav", 70, 100, 0.25, CHAN_VOICE )
end

local function ExplodeGrenade( self )
    if !IsValid( self ) then return end
    local selfPos = self:GetPos()

    trTbl.start = ( selfPos + Vector( 0, 0, 8 ) )
    trTbl.endpos = ( trTbl.start + Vector( 0, 0, -40 ) )
    trTbl.mask = MASK_SOLID
    trTbl.filter = self
    
    local tr = TraceLine( trTbl )
    local hitpos, hitnorm = tr.HitPos, tr.HitNormal
    if hitnorm:Length() == 0 then hitpos = ( hitpos + Vector( 0, 0, 60 ) ) end

    if tr.Fraction != 1 and self:WaterLevel() < 2 then
        trTbl.start = selfPos
        trTbl.endpos = ( hitpos + ( hitnorm * 45.6 ) )
        self:SetPos( TraceLine( trTbl ).HitPos )
    end

    local effectData = EffectData()
    effectData:SetOrigin( hitpos )
    util_Effect( "Explosion", effectData )
    self:EmitSound( "lambdaplayers/weapons/hl1/explode" .. random( 3, 5 ) .. ".wav", 140, 100, 1, CHAN_STATIC )

    local owner = self:GetOwner()
    util_BlastDamage( ( IsValid( owner ) and owner:GetWeaponENT() or self ), ( IsValid( owner ) and owner or self ), selfPos, 250, 100 )

    util_Decal( "Scorch", hitpos + hitnorm, hitpos - hitnorm )
    self:Remove()
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_handgrenade = {
        model = "models/lambdaplayers/weapons/hl1/w_grenade.mdl",
        origin = "Half-Life 1",
        prettyname = "Hand Grenade",
        holdtype = "grenade",
        killicon = "lambdaplayers/killicons/icon_hl1_handgrenade",
        bonemerge = true,
        keepdistance = 650,
        attackrange = 1000,

        clip = 10,
        OnAttack = function( self, wepent, target )
            local holdTime = Rand( 0.75, 2.0 )
            local explodeTime = CurTime() + 3.75
            
            self.l_WeaponUseCooldown = CurTime() + holdTime + 1.0

            self:SimpleTimer( ( holdTime - 0.25 ), function()
                if !IsValid( wepent ) or self:GetWeaponName() != "hl1_handgrenade" then return end
                self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
                self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            end )

            self:SimpleTimer( holdTime, function()
                if !IsValid( wepent ) or self:GetWeaponName() != "hl1_handgrenade" then return end

                local grenade = ents_Create( "base_anim" )
                if !IsValid( grenade ) then return end

                local throwPos = ( LambdaIsValid( target ) and ( target:GetPos() + ( target:IsNextBot() and target.loco or target ):GetVelocity() * 0.5 ) or ( self:GetPos() + self:GetForward() * 500 ) )
                local offsetZ = ( self:GetRangeTo( throwPos ) / 3 )
                local spawnPos = self:GetAttachmentPoint( "eyes" ).Pos
                local vecThrow = ( ( throwPos + Vector( 0, 0, offsetZ ) ) - spawnPos ):Angle()

                grenade:SetModel( "models/lambdaplayers/weapons/hl1/props/handgrenade.mdl" )
                grenade:SetPos( spawnPos )
                grenade:SetAngles( Angle( 0, 0, 60 ) ) 
                grenade:SetOwner( self )
                grenade:Spawn()

                grenade:SetMoveType( MOVETYPE_FLYGRAVITY )
                grenade:SetMoveCollide( MOVECOLLIDE_FLY_BOUNCE )
                grenade:SetSolid( SOLID_BBOX )
                grenade:AddSolidFlags( FSOLID_NOT_STANDABLE )
                grenade:SetCollisionBounds( vec3_origin, vec3_origin )
                
                local gravVal = svGravity:GetInt()
                if gravVal != 0 then grenade:SetGravity( 400 / gravVal ) end
                grenade:SetFriction( 0.8 )

                grenade:SetSequence( 0 )
                grenade:SetPlaybackRate( 1 )

                grenade:SetVelocity( vecThrow:Forward() * 500 )
                grenade:SetLocalAngularVelocity( Angle( random( -200, 200 ), random( 400, 500 ), random( -100, 100 ) ) )

                grenade.Touch = OnGrenadeTouch
                timer_Simple( ( explodeTime - CurTime() ), function() ExplodeGrenade( grenade ) end)
            end )

            return true
        end,

        islethal = true
    }

} )