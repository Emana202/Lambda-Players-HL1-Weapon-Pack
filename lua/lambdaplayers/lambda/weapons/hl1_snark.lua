local CurTime = CurTime
local ipairs = ipairs
local IsValid = IsValid
local random = math.random
local Rand = math.Rand
local TraceHull = util.TraceHull
local ents_Create = ents.Create
local table_remove = table.remove
local throwTr = {
    mins = Vector( -4, -4, 0 ),
    maxs = Vector( 4, 4, 8 )
}

local snarkLimit = CreateLambdaConvar( "lambdaplayers_weapons_snarks_snarklimit", 8, true, false, true, "The amount of snarks Lambda Players can deploy. Set to zero to disable", 0, 30, { type = "Slider", decimals = 0, name = "HL1 Snarks - Snark Limit", category = "Weapon Utilities" } )
local crouchedOffset = Vector( -32, -32, -42 )

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    hl1_snark = {
        model = "models/weapons/w_squeak_hls.mdl",
        origin = "Half-Life 1",
        prettyname = "Snarks",
        holdtype = "slam",
        bonemerge = true,
        
        keepdistance = 600,
        attackrange = 750,
        islethal = true,

        OnEquip = function( self, wepent )
            wepent.l_HL1Snarks = ( wepent.l_HL1Snarks or {} )
        end,

        OnAttack = function( self, wepent, target )
            if target.l_IsLambdaSnark then
                local owner = target:GetOwner()
                if !IsValid( owner ) or owner == self then
                    self:RetreatFrom( target, 5 )
                    return true
                else
                    target = owner
                end
            end

            local snarkCount = #wepent.l_HL1Snarks
            local totalLimit = snarkLimit:GetInt()
            if snarkCount >= totalLimit then
                for index, snark in ipairs( wepent.l_HL1Snarks ) do
                    if !IsValid( snark ) then
                        table_remove( wepent.l_HL1Snarks, index )
                        snarkCount = ( snarkCount - 1 )
                    end
                end
            end
            if snarkCount >= totalLimit then return true end

            local trace_origin = self:WorldSpaceCenter()
            if self:Crouching() then trace_origin = ( trace_origin - crouchedOffset ) end

            local throwAng = ( target:WorldSpaceCenter() - trace_origin ):Angle()
            local throwDir = throwAng:Forward()

            throwTr.start = ( trace_origin + throwDir * 20 )
            throwTr.endpos = ( trace_origin + throwDir * 64 )
            throwTr.filter = self
            
            local tr = TraceHull( throwTr )
            if tr.AllSolid or tr.StartSolid or tr.Fraction <= 0.25 then return end

            local snark = ents_Create( "monster_snark" )
            if !IsValid( snark ) then return end

            snark:SetPos( tr.HitPos )
            snark:SetAngles( throwAng )
            snark:SetOwner( self )
            snark:SetVelocity( throwDir * 200 + self.loco:GetVelocity() )
            snark:Spawn()

            snark:SetEnemy( target )
            snark:SetModel( "models/lambdaplayers/weapons/hl1/props/squeak.mdl" )
            snark.l_IsLambdaSnark = true
            snark.l_UseLambdaDmgModifier = true
            wepent.l_HL1Snarks[ #wepent.l_HL1Snarks + 1 ] = snark

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )

            self.l_WeaponUseCooldown = ( CurTime() + Rand( 0.3, 0.75 ) )
            wepent:EmitSound( "lambdaplayers/weapons/hl1/squeek/sqk_hunt" .. random( 2, 3 ) .. ".wav", 105 )

            return true
        end
    }
} )