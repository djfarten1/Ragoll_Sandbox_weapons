--This is a first two-handed weapon of this gamemode
--This is the first weapon to utilize default gmod SWEP system
AddCSLuaFile()
SWEP.Base = "rs_weapon_base"
SWEP.PrintName = "Deagle"
SWEP.Instructions = "pew pew"

SWEP.Slot = 1
SWEP.SlotPos = 3

SWEP.Initialize = function(self)
	self:AutoHooksCreate()
end

SWEP.Damage = 20

SWEP.ShootDamage = 50
SWEP.ShootForce = 10

SWEP.TerminalSpeed = 150
SWEP.AttackCD = 0.3
SWEP.AttackCDStab = 0.4

SWEP.ShootCD = 0.30

SWEP.PostAnimDamageTime = 0.1

SWEP.Primary.ClipSize		= 7		-- Size of a clip
SWEP.Primary.DefaultClip	= 7			-- Default number of bullets in a clip
SWEP.Primary.Automatic		= true		-- Automatic/Semi Auto
SWEP.Primary.Ammo			= "357"

SWEP.WeaponModel = "models/weapons/w_pist_deagle.mdl"
SWEP.Category = "Guns"
--AutoHook Table
--METHOD: Will add hooks to weapons copies and call similar function (WITH PREFIX "AutoHook_") in that copy then time comes
SWEP.AutoHooks = {
	"RS_RAGDOLLCONTROL(PostBodyAnimation)",	--Will add this hook and run self.AutoHook_RS_RAGDOLLCONTROL(PostBodyAnimation) then needed
	"RS_PHYSCONTROL(PhysicsCollide)",
}

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
		
		self.AnimationTable = self.AnimationTable or {}
		
		if(ply:KeyDown(IN_ATTACK2) and !self:IsAnimating("weapon_pistol(reload)") and !self.Reloading)then
			ARG_Ent = self.WeaponEnt
			ARG_Ent = ARG_Ent:GetPhysicsObject()
			--self:UnWeldWeaponEnt()
			--if(!self.Reloading)then
				self:SetConstraintState("aim")
				RS_RAGDOLLCONTROL_ANIMATION:AnimateRag(rag,"arg_weapon_pistol(aim)",1)
				RS_RAGDOLLCONTROL_ANIMATION:AnimateRag(rag,"arg_357(aim-hands)",1)

		else
			--ply:ChatPrint(CurTime())
			if(!self:IsAnimating("weapon_pistol(reload)"))then
				RS_RAGDOLLCONTROL_ANIMATION:AnimateRag(rag,"weapon_knife(idle)",1)
			end
		end
		if(IsChanged(ply:KeyDown(IN_ATTACK2),"KeyDown_IN_ATTACK2",self) and !ply:KeyDown(IN_ATTACK2))then
			if(!self.Reloading)then
				self:SetConstraintState("normal")
			end
			--[[
			self:UnWeldWeaponEnt()
			self:PositionWeaponEnt()
			self:WeldWeaponEnt()
			]]
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
					self:Animate("weapon_knife(stab)")
				end
			end
		end

		self:AnimThink()	--Everything better postbodyanims
		
		local atkdir = nil
		if(self:IsAnimating("weapon_knife(stab)"))then
			atkdir = (atkdir or 0) + 40
		end
		
		if(atkdir)then
			ARG_Tilt = atkdir	--Needed animation argument
			RS_RAGDOLLCONTROL_ANIMATION:AnimateRag(rag,"arg-weapon_knife(corrective_atkdir)",1)
		end
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
table.Merge(SWEP,{
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
		handangs:RotateAroundAxis(handangs:Forward(),180)
		handangs:RotateAroundAxis(handangs:Right(),0)
		wep:SetPos(b_hand:GetPos()+b_hand:GetAngles():Forward()*5+b_hand:GetAngles():Right()*1.5+b_hand:GetAngles():Up()*3)
		wep:SetAngles(handangs)
	end,
	
	WeldWeaponEnt = function(self)
		if(CLIENT)then return end
		local ply = self.Owner
		local rag = ply.RS_Ragdoll
		local wep = self.WeaponEnt
		local b_hand = rag.PhysBones["ValveBiped.Bip01_R_Hand"]
		constraint.Weld(wep,rag,0,rag._PhysToBonesNum[b_hand],0,false,false)
	end,
	
	UnWeldWeaponEnt = function(self)
		if(CLIENT)then return end
		local wep = self.WeaponEnt
		constraint.RemoveConstraints(wep,"Weld")
	end,
	
	CreateWeaponEnt = function(self)
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
		wep:SetModel(self.WeaponModel)

		wep:Spawn()
		wep:Activate()
		
		--self:PositionWeaponEnt(wep)
		RS_PHYSCONTROL:AddPhysCollideCallBack(wep)
		constraint.NoCollide(wep,rag,0,rag._PhysToBonesNum[b_hand])
		constraint.NoCollide(wep,rag,0,rag._PhysToBonesNum[b_handL])
		--self:WeldWeaponEnt()
		return wep
	end,
	


	WeaponConstraintStates = {
		["normal"] = function(self)
			self:CreateWeaponEnt()
			self:PositionWeaponEnt()
			self:WeldWeaponEnt()
		end,
		["aim"] = function(self)
			self:UnWeldWeaponEnt()
		end,
	},
	
	StopAnims = function(self)
		self.AnimationTable = {}
	end,
	
	Deploy = function(self)
		self:CreateWeaponEnt()
		self:PositionWeaponEnt()
		self:WeldWeaponEnt()
	end,
	
	Holster = function(self,swtichto)
		self:StopAnims()
		self:RemoveWeaponEnt()
		self:StopReload()
		return true
	end,
	
	OnRemove = function(self)
		self:StopAnims()
		self:RemoveWeaponEnt()
		self:StopReload()
	end,
	
	Think = function(self)
		if(SERVER)then	--Only execute on server
			local ply = self.Owner
			local rag = ply.RS_Ragdoll
			
			if(self.NextAttack and self.NextAttack<=CurTime())then
				self.NextAttack = nil
			end
			
			self:ReloadThink()
			--Nothing to see here, everything proccessed post body animation
		end
	end,
	
	MaxRecoil = 15,
	AddRecoilMul = function(self,amt)
		self.RecoilMul = math.Clamp((self.RecoilMul or 1)+amt,1,self.MaxRecoil)
	end,
	GetRecoilMul = function(self)
		self.RecoilMul = self.RecoilMul or 1
		return self.RecoilMul
	end,
	
	ShootEffects = function(self)
		local angs = self.WeaponEnt:GetAngles()
		local ply = self.Owner
		local phys = self.WeaponEnt:GetPhysicsObject()
		local recoilmul = 3*self:GetRecoilMul()
		phys:ApplyForceCenter(angs:Up()*40+angs:Forward()*-40)
		phys:ApplyTorqueCenter(angs:Up()*math.Rand(-0.5,0.5)*recoilmul)
		phys:ApplyTorqueCenter(angs:Right()*4*recoilmul)
		
		local punch = Angle(-recoilmul/0.9*math.Rand(0.3,0.5),-recoilmul/0.6*math.Rand(-0.1,0.2),0)
		
		self:Recoil(punch*1.1,punch)
		self.WeaponEnt:EmitSound("weapons/deagle/deagle-1.wav",75,100,1,CHAN_WEAPON)
		
	end,
	
	ReloadTime = 1.6,
	Reload = function(self)
		if(SERVER)then
			local ply = self.Owner
			if(self:Clip1()<self:GetMaxClip1() and ply:GetAmmoCount( self:GetPrimaryAmmoType() )>0 and !self.Reloading)then
				self.Reloading = CurTime()+self.ReloadTime
				self:SetConstraintState("normal")
				self:Animate("weapon_pistol(reload)",true,true)
				self.WeaponEnt:EmitSound("weapons/deagle/de_clipout.wav",55,100,1,CHAN_AUTO)
				timer.Simple(1, function()
					self.WeaponEnt:EmitSound("weapons/deagle/de_clipin.wav",55,100,1,CHAN_AUTO)
				end)
				timer.Simple(2, function()
					self.WeaponEnt:EmitSound("weapons/deagle/de_slideback.wav",55,100,1,CHAN_AUTO)
				end)
			end
		end
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
		local bul = {}
		bul.Attacker = self
		bul.Damage = self.ShootDamage
		bul.Force = self.ShootForce
		bul.Dir = (angs:Forward() + angs:Up() * math.tan(math.rad(3)))
		bul.Src = self.WeaponEnt:GetPos()+angs:Up()*4.7+angs:Forward()*6
		local spread = 0.005 * self:GetRecoilMul()
		bul.Spread = Vector(spread,spread,0)
		bul.IgnoreEntity = self.WeaponEnt
		
		bul.Attacker = self.Owner
		
		self.WeaponEnt:FireBullets(bul)
		
		self:ShootEffects()
	end,
	
	AnimThink = function(self)
		local ply = self.Owner
		local rag = ply.RS_Ragdoll
		
		self.AnimationTable = self.AnimationTable or {}
		
		for id,info in pairs(self.AnimationTable)do
			if(info.EndTime<=CurTime())then
				self.AnimationTable[id] = nil
				self.DealtDamage = nil
			elseif(info.AnimEndTime>CurTime())then
				RS_RAGDOLLCONTROL_ANIMATION:AnimateRag(rag,info.Anim,info.Rate)
			end
		end
	end,

	IsAttacking = function(self,atkid)
		self.AnimationTable = self.AnimationTable or {}
		return self.AnimationTable[atkid]~=nil and !self.AnimationTable[atkid].NoAttack
	end,
	
	IsAnimating = function(self,atkid)
		self.AnimationTable = self.AnimationTable or {}
		return (self.AnimationTable[atkid] and self.AnimationTable[atkid].AnimEndTime>CurTime())
	end,

	IsAttackingAny = function(self)
		self.AnimationTable = self.AnimationTable or {}
		return (next(self.AnimationTable) ~= nil and !next(self.AnimationTable).NoAttack)
	end,
	
	Animate = function(self,mode,noattackcd,noattack)
		local ply = self.Owner
		local rag = ply.RS_Ragdoll
		
		self.AnimationTable = self.AnimationTable or {}
		self.AnimationTable[mode] = {}
		local atk = self.AnimationTable[mode]
		atk.Anim = mode
		atk.Rate = 1
		atk.AnimEndTime = CurTime()+RS_RAGDOLLCONTROL_ANIMATION:GetAnimTime(rag,mode)
		atk.EndTime = CurTime()+RS_RAGDOLLCONTROL_ANIMATION:GetAnimTime(rag,mode)+self.PostAnimDamageTime
		atk.NoAttack = noattack
		if(!noattackcd)then
			if(mode=="weapon_knife(stab)")then
				self.NextAttack = atk.EndTime+self.AttackCDStab
			else
				self.NextAttack = atk.EndTime+self.AttackCD
			end
		end
		
		self.DealtDamage = nil
		
		return atk.AnimEndTime
	end,
})
--}
--RS_RAGDOLLCONTROL_WEAPONS:ReloadAllWeaponScripts(self.Class)
