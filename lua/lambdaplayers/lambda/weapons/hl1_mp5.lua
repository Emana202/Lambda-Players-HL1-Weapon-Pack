local IsValid = IsValid
local CurTime = CurTime
local util_Effect = util.Effect
local EffectData = EffectData
local random = math.random
local Rand = math.Rand
local ents_Create = ents.Create

if ( CLIENT ) then
    killicon.AddAlias( "grenade_mp5", "grenade_ar2" )
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_mp5 = {
        model = "models/lambdaplayers/weapons/hl1/w_9mmar.mdl",
        origin = "Half-Life 1",
        prettyname = "MP5",
        holdtype = "ar2",
        killicon = "lambdaplayers/killicons/icon_hl1_mp5",
        bonemerge = true,
        keepdistance = 500,
        attackrange = 1000,

        clip = 50,
        tracername = "Tracer",
        damage = 5,
        spread = 0.133,
        rateoffire = 0.1,
        muzzleflash = 1,
        shelleject = "ShellEject",
        shelloffpos = Vector( -2, -1, 0 ),
        shelloffang = Angle( 90, -90, 0 ),
        attackanim = ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1,
        attacksnd = "lambdaplayers/weapons/hl1/9mmar/hks*3*.wav",

        OnAttack = function( self, wepent, target )
            if random( 50 ) != 1 or !self:IsInRange( target, 1000 ) then return end

            local grenade = ents_Create( "grenade_mp5" )
            if !IsValid( grenade ) then return end

            self.l_WeaponUseCooldown = CurTime() + 1.0

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )

            local gLaunchSnd = "lambdaplayers/weapons/hl1/9mmar/glauncher" .. ( random( 1, 2 ) == 2 and 2 or "" ) .. ".wav"
            wepent:EmitSound( gLaunchSnd, 75, random( 94, 110 ), 1, CHAN_WEAPON )

            local offsetZ = ( self:GetRangeTo( target ) / random( 6, 7 ) )
            local vecThrow = ( ( target:GetPos() + target:GetUp() * offsetZ ) - wepent:GetPos() ):Angle()
            
            grenade:SetPos( wepent:GetPos() + vecThrow:Forward() * 24 + vecThrow:Up() * 24 )
            grenade:SetAngles( vecThrow )
            grenade:SetOwner( self )
            grenade:Spawn()
            grenade:Activate()

            grenade:SetModel( "models/lambdaplayers/weapons/hl1/props/9mmar_grenade.mdl" )
            grenade:SetMoveType(MOVETYPE_FLYGRAVITY)
            grenade:SetVelocity( vecThrow:Forward() * 800 )
            grenade:SetLocalAngularVelocity( Angle( -Rand( -100, -500 ), 0, 0 ) )
            grenade.l_IsLambdaMP5Grenade = true

            return true
        end,

        reloadtime = 1.53,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        reloadanimspeed = 1.33,
        reloadsounds = { 
            { 0.17, "lambdaplayers/weapons/hl1/9mmar/cliprelease1.wav" },
            { 0.80, "lambdaplayers/weapons/hl1/9mmar/clipinsert1.wav" }
        },

        islethal = true
    }

} )