--[[-----------------
 WATER FALLING DAMAGE
	  Version 1.1.1
	    09/12/16

by DyaMetR
]]-------------------

if SERVER then

	local enabled = CreateConVar( "wfd_enabled", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_NEVER_AS_STRING}, "Water fall damage toggle" );
	local mul = CreateConVar( "wfd_mul", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_NEVER_AS_STRING}, "Water fall damage multiplier" );
	local airSpeedOnly = CreateConVar( "wfd_speed_only", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_NEVER_AS_STRING}, "Calculate damage only with air speed" );

	local function Spawn(ply)
		ply.WaterFallDamage = {
			TakesDamage = false,
			InWater = false,
			AirSpeed = 0
		}
	end
	hook.Add("PlayerSpawn", "wfd_spawn", Spawn)

	local function Think(ply)

		if enabled:GetInt() <= 0 then return end

		if ply:WaterLevel() > 0 then

			if !ply.WaterFallDamage.InWater then
				if ply.WaterFallDamage.AirSpeed >= 525 and (ply.WaterFallDamage.TakesDamage or airSpeedOnly:GetInt() >= 1) and ply:GetMoveType() != MOVETYPE_NOCLIP then
					local var = math.floor((ply.WaterFallDamage.AirSpeed - 460)/485) -- 420/485
					local damage = math.Clamp(var,0,var)

					-- Take damage
					local dmgInfo = DamageInfo();
					dmgInfo:SetDamage(damage * 20 * mul:GetFloat());
					dmgInfo:SetAttacker(game.GetWorld());
					dmgInfo:SetInflictor(game.GetWorld());
					dmgInfo:SetDamageType(DMG_FALL);
					dmgInfo:SetDamageForce(Vector(0, 0, 0));
					ply:TakeDamageInfo(dmgInfo);

					ply:ViewPunch(Angle(0, 0, 20*math.Clamp(damage,0,2)))
					ply:EmitSound(Sound("physics/body/body_medium_impact_hard"..math.random(1,6)..".wav"))
				end
				ply.WaterFallDamage.InWater = true
				ply.WaterFallDamage.TakesDamage = false
			end

		else

			if ply.WaterFallDamage.InWater then
				ply.WaterFallDamage.InWater = false
			end

			if ply.WaterFallDamage.AirSpeed != ply:GetVelocity():Length() then
				ply.WaterFallDamage.AirSpeed = ply:GetVelocity():Length()
			end

			if ply:OnGround() or ply:GetMoveType() == MOVETYPE_NOCLIP then

				if ply.WaterFallDamage.TakesDamage then
					ply.WaterFallDamage.TakesDamage = false
				end

			else

				if !ply.WaterFallDamage.TakesDamage then

					local trace = util.TraceLine( {
						start = ply:GetPos(),
						endpos = ply:GetPos() + Vector(0,0,-300),
						mask = bit.bor( MASK_WATER, MASK_SOLID ),
						filter = ply
					} )

					if !trace.Hit then
						ply.WaterFallDamage.TakesDamage = true
					end

				end

			end

		end

	end
	hook.Add("PlayerTick", "wfd_think", Think)

end

if CLIENT then

	local function menu( Panel )
		Panel:ClearControls()
		//Do menu things here
		Panel:AddControl( "Label" , { Text = "Water Fall Damage settings", Description = ""} )
		Panel:AddControl( "Checkbox", {
			Label = "Toggle",
			Command = "wfd_enabled",
			}
		)

		Panel:AddControl( "Textbox", {
				Label = "Damage multiplier",
				Command = "wfd_mul",
			}
		)

		Panel:AddControl( "CheckBox", {
				Label = "Calculate damage only with air speed",
				Command = "wfd_speed_only",
			}
		)

	end

	local function createthemenu()
		spawnmenu.AddToolMenuOption( "Utilities", "DyaMetR", "wfd", "Water Fall Damage", "", "", menu )
	end
	hook.Add( "PopulateToolMenu", "wfd_menu", createthemenu )
end
