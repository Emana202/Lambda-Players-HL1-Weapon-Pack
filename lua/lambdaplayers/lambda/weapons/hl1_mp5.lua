-- if !IsMounted( "hl1" ) then return end

local IsValid = IsValid
local CurTime = CurTime
local random = math.random
local Rand = math.Rand
local ents_Create = ents.Create

local physBoxMins = Vector( 13, 14, 2.25 )
local physBoxMaxs = Vector( -7, -16, -0.25 )

if ( CLIENT ) then
    killicon.AddAlias( "grenade_mp5", "grenade_ar2" )
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_mp5 = {
        model = "models/weapons/w_9mmar.mdl",
        origin = "Half-Life 1",
        prettyname = "MP5",
        holdtype = "ar2",
        killicon = "lambdaplayers/killicons/icon_hl1_mp5",
        bonemerge = true,
        keepdistance = 500,
        attackrange = 1000,

        OnDrop = function( cs_prop )
            cs_prop:PhysicsInitBox( physBoxMins, physBoxMaxs )
            cs_prop:PhysWake()
            cs_prop:GetPhysicsObject():SetMaterial( "weapon" )
        end,

        clip = 50,
        tracername = "Tracer",
        damage = 5,
        spread = 0.15,
        rateoffire = 0.1,
        muzzleflash = 1,
        shelleject = "ShellEject",
        shelloffpos = Vector( -2, -1, 0 ),
        shelloffang = Angle( 90, -90, 0 ),
        attackanim = ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1,
        attacksnd = "HL1Weapon_MP5.Single",

        callback = function( self, wepent, target )
            if random( 50 ) != 1 or !self:IsInRange( target, 1000 ) then return end

            local grenade = ents_Create( "grenade_mp5" )
            if !IsValid( grenade ) then return end

            self.l_WeaponUseCooldown = CurTime() + 1.0

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )

            wepent:EmitSound( "HL1Weapon_MP5.Double", 70, 100, 1, CHAN_WEAPON )

            local offsetZ = ( self:GetRangeTo( target ) / random( 6, 7 ) )
            local vecThrow = ( ( target:GetPos() + target:GetUp() * offsetZ ) - wepent:GetPos() ):Angle()
            
            grenade:SetPos( wepent:GetPos() + vecThrow:Forward() * 24 + vecThrow:Up() * 24 )
            grenade:SetAngles( vecThrow )
            grenade:SetOwner( self )
            grenade:Spawn()
            grenade:Activate()

            grenade:SetMoveType(MOVETYPE_FLYGRAVITY)
            grenade:SetVelocity( vecThrow:Forward() * 800 )
            grenade:SetLocalAngularVelocity( Angle( -Rand( -100, -500 ), 0, 0 ) )

            return true
        end,

        reloadtime = 1.53,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        reloadanimspeed = 1.33,
        reloadsounds = { 
            { 0.17, "Weapon_MP5.Special1" },
            { 0.80, "Weapon_MP5.Special2" }
        },

        islethal = true
    }

} )