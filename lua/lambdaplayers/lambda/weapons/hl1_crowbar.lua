local CurTime = CurTime
local DamageInfo = DamageInfo
local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    hl1_crowbar = {
        model = "models/lambdaplayers/weapons/hl1/w_crowbar.mdl",
        origin = "Half-Life 1",
        prettyname = "Crowbar",
        holdtype = "melee",
        killicon = "lambdaplayers/killicons/icon_hl1_crowbar",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 60,

        OnAttack = function( self, wepent, target )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )

            local dmg = ( ( CurTime() <= self.l_WeaponUseCooldown + 1.0 ) and 5 or 10 )
            local dmginfo = DamageInfo() 
            dmginfo:SetDamage( dmg )
            dmginfo:SetAttacker( self )
            dmginfo:SetInflictor( wepent )
            dmginfo:SetDamageType( DMG_CLUB )
            dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
            target:TakeDamageInfo( dmginfo )

            if target:IsPlayer() or target:IsNextBot() or target:IsNPC() then
                wepent:EmitSound( "lambdaplayers/weapons/hl1/crowbar/cbar_hitbod" .. random( 3 ) .. ".wav", 85, 100, 1, CHAN_ITEM )
            else
                wepent:EmitSound( "lambdaplayers/weapons/hl1/crowbar/cbar_hit" .. random( 2 ) .. ".wav", 95, ( 98 + random( 0, 3 ) ), 0.6, CHAN_ITEM )
            end

            self.l_WeaponUseCooldown = CurTime() + 0.25
            return true
        end,

        islethal = true
    }

} )