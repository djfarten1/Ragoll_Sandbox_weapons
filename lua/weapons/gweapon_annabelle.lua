AddCSLuaFile()
SWEP.Base = "rs_weapon_base"
SWEP.PrintName = "Annabelle"
SWEP.Instructions = "My advice to you is... aim for the head!"

SWEP.Slot = 3
SWEP.SlotPos = 2

SWEP.Initialize = function(self)
	self:AutoHooksCreate()
end

SWEP.WeaponModel = "models/weapons/w_annabelle.mdl"

SWEP.Category = "Guns"

SWEP.Damage = 8

SWEP.ShootDamage = 40
SWEP.ShootForce = 10

SWEP.TerminalSpeed = 110
SWEP.AttackCD = 0.3
SWEP.AttackCDStab = 0.4

SWEP.ShootCD = 0.40

SWEP.PostAnimDamageTime = 0.1

SWEP.Primary.ClipSize		= 2		-- Size of a clip
SWEP.Primary.DefaultClip	= 2			-- Default number of bullets in a clip
SWEP.Primary.Automatic		= true		-- Automatic/Semi Auto
SWEP.Primary.Ammo			= "357"

--AutoHook Table
--METHOD: Will add hooks to weapons copies and call similar function (WITH PREFIX "AutoHook_") in that copy then time comes
SWEP.AutoHooks = {
	"RS_RAGDOLLCONTROL(PostBodyAnimation)",	--Will add this hook and run self.AutoHook_RS_RAGDOLLCONTROL(PostBodyAnimation) then needed
	"RS_PHYSCONTROL(PhysicsCollide)",
	"RS_CalcWeaponViewOffsetAngles",
}



SWEP["AutoHook_RS_CalcWeaponViewOffsetAngles"] = function(self,pos,angles,fov)
	if(!IsValid(self))then return nil end
	
	local ply = self.Owner
	--print(self.Reloading)
	if(IsValid(ply) and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass()==self:GetClass())then
		if(ply:KeyDown(IN_ATTACK2) and !self.Reloading and ply:KeyDown(IN_SPEED))then
			local wep = self:GetWeaponEnt()
			if(IsValid(wep))then
				local rag = RS_RAGDOLLCONTROL:GetRagdoll()
				local bone = rag:LookupBone("ValveBiped.Bip01_Head1")
				local bonepos = rag:GetBonePosition(bone)
				
				local wepangs = wep:GetAngles()
				local weppos = wep:GetPos() - wepangs:Forward()*-16 + wepangs:Up()*7.5 - wepangs:Right()*-1.5
				
				
				--local angs = LerpAngle(RS_RAGDOLLCONTROL:GetWVAChangeFraction(self),angles,(weppos-bonepos):Angle())
				--print(angles,"gay",angs)
				return (weppos-bonepos):Angle(),weppos:Distance(bonepos),RS_RAGDOLLCONTROL:GetWVAChangeFraction(self)
				
				--[[
				local angs = wep:GetAngles()
				local pos = wep:GetPos() + angs:Forward()*-14 + angs:Up()*9.9
				
				return RS_RAGDOLLCONTROL:CalcWeaponView(wep,view,pos,angs,8,20)
				]]
			end
		end
	end
end

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
	if !IsValid(DrawModel) then
		DrawModel = ClientsideModel(self.WeaponModel, RENDER_GROUP_OPAQUE_ENTITY)
		DrawModel:SetNoDraw(true)
	else
		DrawModel:SetModel(self.WeaponModel)

		local vec = Vector(55, 55, 60)
		local ang = Vector(-48, -48, -48):Angle()

		cam.Start3D(vec, ang, 20, x, y + 35, wide, tall, 5, 4096)
		cam.IgnoreZ(true)
		render.SuppressEngineLighting(true)

		render.SetLightingOrigin(self:GetPos())
		render.ResetModelLighting(50 / 255, 50 / 255, 50 / 255)
		render.SetColorModulation(1, 1, 1)
		render.SetBlend(255)

		render.SetModelLighting(4, 1, 1, 1)

		DrawModel:SetRenderAngles(Angle(0, RealTime() * 30 % 360, 0))
		DrawModel:DrawModel()
		DrawModel:SetRenderAngles()

		render.SetColorModulation(1, 1, 1)
		render.SetBlend(1)
		render.SuppressEngineLighting(false)
		cam.IgnoreZ(false)
		cam.End3D()
	end

	self:PrintWeaponInfo(x + wide + 20, y + tall * 0.95, alpha)
end

//AutoHooks
SWEP["AutoHook_RS_RAGDOLLCONTROL(PostBodyAnimation)"] = function(self,comrag,eyeangs,footbase,additiveeyeangs)
	local ply = self.Owner
	if(!IsValid(ply) or !IsValid(ply:GetActiveWeapon()))then return nil end
	local rag = ply.RS_Ragdoll
	if(comrag == rag and ply:GetActiveWeapon():GetClass()==self:GetClass())then --We want to animate only after our ragdoll body anim not any other
		local ply = self.Owner
		local rag = ply.RS_Ragdoll
		
		if(ply:KeyDown(IN_ATTACK2) and !RS_RAGDOLLCONTROL_ANIMATION:IsAnimating(rag,"arg_weapon_shotgun(reload)") and !self.Reloading)then
			ARG_Ent = self.WeaponEnt
			ARG_Ent = ARG_Ent:GetPhysicsObject()
			
			self:SetConstraintState("aim")
			RS_RAGDOLLCONTROL_ANIMATION:AnimateRag(rag,"arg_weapon_shotgun(aim)",1)
			RS_RAGDOLLCONTROL_ANIMATION:AnimateRag(rag,"arg_weapon_shotgun(aim-hands)",1)
			--ARG_Tilt = 50
			--RS_RAGDOLLCONTROL_ANIMATION:AnimateRag(rag,"arg-weapon_knife(corrective_atkdir)",1)
			--self:Animate(1)
			--print(CurTime())
			
		else
			if(!RS_RAGDOLLCONTROL_ANIMATION:IsAnimating(rag,"arg_weapon_shotgun(reload)"))then
				RS_RAGDOLLCONTROL_ANIMATION:AnimateRag(rag,"arg_weapon_shotgun(idle)",1)
			end
		end
		if(IsChanged(ply:KeyDown(IN_ATTACK2),"KeyDown_IN_ATTACK2",self) and !ply:KeyDown(IN_ATTACK2))then
			if(!self.Reloading)then
				self:SetConstraintState("normal")
			end
		end
		
		if(self.NextShoot and self.NextShoot<=CurTime())then
			self.NextShoot = nil
		end
		
		if(!self.Reloading)then
			if(ply:KeyDown(IN_ATTACK))then
				if(ply:KeyDown(IN_ATTACK2) and !self.NextShoot and ply:KeyPressed(IN_ATTACK))then
					self.NextShoot = CurTime() + self.ShootCD
					self:TryShoot()
				elseif(!ply:KeyDown(IN_ATTACK2) and !self.NextAttack and RS_RAGDOLLCONTROL:GetKeyDown(ply,IN_ATTACK))then
					self:Animate("weapon_ak(stab)")
				end
			end
		end

		self:AnimThink()	--Everything better postbodyanims
	end
end

SWEP["AutoHook_RS_PHYSCONTROL(PhysicsCollide)"] = function(self,ent,data)
	local ply = self.Owner
	local rag = ply.RS_Ragdoll
	local b_handR = rag.PhysBones["ValveBiped.Bip01_R_Hand"]
	-- or (ent == rag and data.PhysObject==b_handR)
	if( ((ent==self.WeaponEnt and data.HitEntity!=rag) or (ent == rag and data.PhysObject==b_handR) ))then	--Making sure we can't harm ourselves(We can't possibly actually> Why? Because Garry's)
		if((self:IsAttackingAny()) and !self.DealtDamage)then
			speed = data.HitSpeed:Length()
			if(speed)then
				local frac = math.min(speed/self.TerminalSpeed,1)
				--data.HitEntity:TakeDamage(math.Round(self.Damage*frac))
				
				local dmg = DamageInfo()
				dmg:SetDamage(math.Round(self.Damage*frac))
				dmg:SetDamageType(DMG_CLUB)
				dmg:SetDamagePosition(data.HitPos)
				dmg:SetInflictor(ent)
				dmg:SetAttacker(self.Owner)
				---data.HitEntity:TakeDamageInfo(dmg)
				RS_RAGDOLLCONTROL:ApplyDamage(data.HitEntity,dmg,data.HitObject)
				
				rag:EmitSound("physics/body/body_medium_impact_hard1.wav",math.max(frac*80,50))
				self.DealtDamage = true
			end
			self.DealtDamage = true
		end
	end
end
//AutoHooks

SWEP.WeaponConstraintStates = {
	["normal"] = function(self)
		self:CreateWeaponEnt()
		
		self:UnWeldWeaponEnt()
		self:PositionWeaponEnt()
		self:WeldWeaponEnt()
		
		self:UnWeldWeaponLHandEnt()
		self:PositionHand()
		self:WeldWeaponLHandEnt()
	end,
	["reload"] = function(self)
		self:CreateWeaponEnt()
	
		self:UnWeldWeaponEnt()
		self:PositionWeaponEnt()
		self:WeldWeaponEnt()
	end,
	["aim"] = function(self)
		self:UnWeldWeaponEnt()
		self:UnWeldWeaponLHandEnt()
	end,
}

table.Merge(SWEP,{
	GetLeftHandPos = function(self)
		return self.WeaponEnt:GetPos()+self.WeaponEnt:GetAngles():Right()*-2+self.WeaponEnt:GetAngles():Up()*-4.5+self.WeaponEnt:GetAngles():Forward()*-8
	end,

	GetLeftHandAng = function(self)
		local angs = self.WeaponEnt:GetAngles()
		angs:RotateAroundAxis(angs:Forward(),-90)
		--angs:RotateAroundAxis(angs:Up(),-90)
		return angs
	end,
	
	PositionHand = function(self,up)
		if(CLIENT)then return end
		local ply = self.Owner
		local rag = ply.RS_Ragdoll
		up = up or 0
		local b_handL = rag.PhysBones["ValveBiped.Bip01_L_Hand"]
		b_handL:SetPos(self:GetLeftHandPos()+self.WeaponEnt:GetAngles():Right()*up)
		b_handL:SetAngles(self:GetLeftHandAng())
	end,
	
	RemoveWeaponEnt = function(self)
		if(CLIENT)then return end
		local wep = self.WeaponEnt
		if(IsValid(wep))then
			wep:Remove()
		end
	end,
	
	PositionWeaponEnt = function(self)
		if(CLIENT)then return end
		local ply = self.Owner
		local rag = ply.RS_Ragdoll
		local wep = self.WeaponEnt
		local b_hand = rag.PhysBones["ValveBiped.Bip01_R_Hand"]
		local handangs = b_hand:GetAngles()
		local handangs = b_hand:GetAngles()
		handangs:RotateAroundAxis(handangs:Forward(),0)
		handangs:RotateAroundAxis(handangs:Right(),180)
		--handangs:RotateAroundAxis(handangs:Up(),180)
		wep:SetPos(b_hand:GetPos()+b_hand:GetAngles():Forward()*17+b_hand:GetAngles():Right()*0.3+b_hand:GetAngles():Up()*-0.1)
		wep:SetAngles(handangs)
	end,
	
	WeldWeaponLHandEnt = function(self)
		if(CLIENT)then return end
		local ply = self.Owner
		local rag = ply.RS_Ragdoll
		local wep = self.WeaponEnt
		local b_handL = rag.PhysBones["ValveBiped.Bip01_L_Hand"]
		local locvec = self:GetLeftHandPos()
		locvec = locvec + b_handL:GetAngles():Forward()*4 + b_handL:GetAngles():Up()*-1 + b_handL:GetAngles():Right()*1
		--locvec = b_handL:WorldToLocal(locvec)
		self.WeaponLHANDWeld = constraint.Ballsocket(wep,rag,0,rag._PhysToBonesNum[b_handL],b_handL:WorldToLocal(locvec),0,0)--constraint.Weld(wep,rag,0,rag._PhysToBonesNum[b_handL],0,false,false)
	end,

	UnWeldWeaponLHandEnt = function(self)
		if(CLIENT)then return end
		local wep = self.WeaponEnt
		if(IsValid(self.WeaponLHANDWeld))then
			self.WeaponLHANDWeld:Remove()
		end
	end,

	UnWeldWeaponEnt = function(self)
		if(CLIENT)then return end
		local wep = self.WeaponEnt
		constraint.RemoveConstraints(wep,"Weld")
		--constraint.RemoveConstraints(wep,"Weld")
	end,
	
	WeldWeaponEnt = function(self)
		if(CLIENT)then return end
		local ply = self.Owner
		local rag = ply.RS_Ragdoll
		local wep = self.WeaponEnt
		local b_hand = rag.PhysBones["ValveBiped.Bip01_R_Hand"]
		constraint.Weld(wep,rag,0,rag._PhysToBonesNum[b_hand],0,false,false)
	end,
	
	CreateWeaponEnt = function(self)
		--if(1)then return end
		if(CLIENT)then return end
		if(IsValid(self.WeaponEnt))then self.WeaponEnt:Remove() end
		local ply = self.Owner
		local rag = ply.RS_Ragdoll
		if(!IsValid(rag))then return end
		
		local b_hand = rag.PhysBones["ValveBiped.Bip01_R_Hand"]
		local b_handL = rag.PhysBones["ValveBiped.Bip01_L_Hand"]
		
		self.WeaponEnt = ents.Create("prop_physics")
		local wep = self.WeaponEnt
		wep.RS_PreventUse = true
		self:SetWeaponEnt(wep)
		
		--wep:SetModel("models/weapons/w_rif_famas.mdl")
		wep:SetModel(self.WeaponModel)
		--self:PositionWeaponEnt(wep)
		RS_PHYSCONTROL:AddPhysCollideCallBack(wep)
		wep:Spawn()
		wep:Activate()
		
		wep:GetPhysicsObject():SetMass(1)
		wep:GetPhysicsObject():SetDragCoefficient(0)
		constraint.NoCollide(wep,rag,0,rag._PhysToBonesNum[b_hand])
		constraint.NoCollide(wep,rag,0,rag._PhysToBonesNum[b_handL])
		--[[
		self:WeldWeaponEnt()
		
		self:PositionHand(0)
		self:WeldWeaponLHandEnt()
		]]
	end,
	
	StopAttacks = function(self)
		self.AttackingTable = {}
	end,
	StopOneTimeAnims = function(self)
		local ply = self:GetOwner()
		if(SERVER and IsValid(ply) and IsValid(ply.RS_Ragdoll))then
			RS_RAGDOLLCONTROL_ANIMATION:AnimateRag_Reset(ply.RS_Ragdoll,"arg_weapon_shotgun(reload)")
		end
	end,
	
	Deploy = function(self)
		self:CreateWeaponEnt()
		self:UnWeldWeaponEnt()
		self:PositionWeaponEnt()
		self:WeldWeaponEnt()
		
		self:UnWeldWeaponLHandEnt()
		self:PositionHand()
		self:WeldWeaponLHandEnt()
	end,
	
	Holster = function(self,swtichto)
		self:StopAttacks()
		self:RemoveWeaponEnt()
		self:StopReload()
		self:StopOneTimeAnims()
		return true
	end,
	
	OnRemove = function(self)
		self:StopAttacks()
		self:RemoveWeaponEnt()
		self:StopReload()
		self:StopOneTimeAnims()
	end,
	
	Think = function(self)
		if(SERVER)then	--Only execute on server
			local ply = self.Owner
			local rag = ply.RS_Ragdoll
			
			if(self.NextAttack and self.NextAttack<=CurTime())then
				self.NextAttack = nil
			end
			
			self:AddRecoilMul(engine.TickInterval()*self.RecoilAddPerSecond)
			--print(self:GetRecoilMul())
			--Nothing to see here, everything proccessed post body animation
			
		end
		self:ReloadThink()
	end,
	
	RecoilAddPerSecond = 2,
	MaxRecoil = 4,
	AddRecoilMul = function(self,amt)
		self.RecoilMul = math.Clamp((self.RecoilMul or 1)+amt,1,self.MaxRecoil)
	end,
	GetRecoilMul = function(self)
		self.RecoilMul = self.RecoilMul or 1
		return self.RecoilMul
	end,
	
	ShootEffects = function(self)
		local ply = self.Owner
		local rag = ply.RS_Ragdoll
		local angs = self.WeaponEnt:GetAngles()
		local phys = self.WeaponEnt:GetPhysicsObject()
		local recoilmul = 5.3*self:GetRecoilMul()
		phys:ApplyForceCenter(angs:Up()*1-angs:Forward()*40)
		phys:ApplyTorqueCenter(angs:Up()*math.Rand(-0.3,0.3)*4*recoilmul)
		phys:ApplyTorqueCenter(-angs:Right()*math.Rand(-0.5,-0.3)*7*recoilmul)
		
		self:Recoil(Angle(-recoilmul*math.Rand(0.3,0.5)/1.8,-recoilmul/1.5*math.Rand(-0.3,0.4),0),Angle(-recoilmul/1.8*math.Rand(0.3,0.5),-recoilmul/1.5*math.Rand(-0.1,0.2),0))
		
		self.WeaponEnt:EmitSound("weapons/shotgun/shotgun_fire6.wav",75,100,1,CHAN_WEAPON)
		
		--self:AddRecoilMul(-0.1)
		self:AddRecoilMul(-2*self.ShootCD)
	end,
	
	PostReload = function(self)
		self:SetConstraintState("normal")
	end,
	
	ReloadTime = 4,
	Reload = function(self)
		--if(SERVER)then
		local ply = self.Owner
		local rag = ply.RS_Ragdoll
		if(self:Clip1()<self:GetMaxClip1() and ply:GetAmmoCount( self:GetPrimaryAmmoType() )>0 and !self.Reloading)then
			self.Reloading = CurTime()+self.ReloadTime
			--self:Animate("weapon_ak(reload)",true,true)
			if(SERVER)then
				RS_RAGDOLLCONTROL_ANIMATION:ResetAnimation(rag,"arg_weapon_shotgun(reload)")
				self:SetConstraintState("reload")
				self.WeaponEnt:EmitSound("weapons/shotgun/shotgun_reload1.wav",55,100,1,CHAN_AUTO)
				timer.Simple(2, function()
				self.WeaponEnt:EmitSound("weapons/shotgun/shotgun_reload2.wav",55,100,1,CHAN_AUTO)
				end)
			end
		end
		--end
	end,
	
	ReloadThink = function(self)
		if(self.Reloading and self.Reloading<=CurTime())then
			self:EndReload()
			self:StopReload()
		end
	end,
	
	EndReload = function(self)
		local ply = self.Owner
		local delta = math.min(ply:GetAmmoCount( self:GetPrimaryAmmoType() ),math.max(self:GetMaxClip1()-self:Clip1(),0))
		self:SetClip1(self:Clip1()+delta)
		ply:RemoveAmmo(delta,self:GetPrimaryAmmoType())
		self:PostReload()
	end,

	StopReload = function(self)
		self.Reloading = nil
	end,

	TryShoot = function(self)
		if(self:Clip1()<1 or self.Reloading)then
			return
		end
		self:SetClip1(self:Clip1()-1)
		
		self:Shoot()
	end,
	
	Shoot = function(self)
		local angs = self.WeaponEnt:GetAngles()
		local numBullets = 2 
		local spread = 0.1
		for i = 1, numBullets do
			local bullet = {}
			bullet.Attacker = self.Owner
			bullet.Damage = self.ShootDamage
			bullet.Force = self.ShootForce
			bullet.Dir = (-angs:Forward() + angs:Up() * math.tan(math.rad(-10)))
			bullet.Dir:Normalize()
			bullet.Src = self.WeaponEnt:GetPos() + angs:Up() * 1 - angs:Forward() * 15 + angs:Right() * -5
			local spread = 0.07
			bullet.Spread = Vector(spread, spread, 0)
			bullet.TracerName = "Tracer"
			bullet.IgnoreEntity = self.WeaponEnt

			self.WeaponEnt:FireBullets(bullet)
		end

		self:ShootEffects()
	end,

	
})
--}
--RS_RAGDOLLCONTROL_WEAPONS:ReloadAllWeaponScripts(self.Class)
