Scriptname UD_CustomDevice_NPCSlot  extends ReferenceAlias

import UnforgivingDevicesMain
import UD_NPCInteligence

UDCustomDeviceMain Property UDCDmain auto
UnforgivingDevicesMain Property UDmain 
    UnforgivingDevicesMain Function get()
        return UDCDmain.UDmain
    EndFunction    
EndProperty
UD_CustomDevices_NPCSlotsmanager Property UDNPCM hidden
    UD_CustomDevices_NPCSlotsmanager Function get()
        return GetOwningQuest() as UD_CustomDevices_NPCSlotsmanager
    EndFunction
EndProperty
zadlibs_UDPatch Property libs hidden
    zadlibs_UDPatch Function get()
        return UDmain.libsp
    EndFunction
EndProperty
UD_OrgasmManager Property UDOM Hidden
    UD_OrgasmManager Function get()
        return UDmain.UDOM
    EndFunction
EndProperty
UD_ExpressionManager Property UDEM Hidden
    UD_ExpressionManager Function get()
        return UDmain.UDEM
    EndFunction
EndProperty
UD_CustomDevice_RenderScript[] Property UD_equipedCustomDevices auto hidden
Form[] Property UD_BodySlots auto hidden

UD_CustomDevice_RenderScript _handRestrain = none
UD_CustomDevice_RenderScript Property UD_HandRestrain Hidden
    UD_CustomDevice_RenderScript Function get()
        if _handRestrain
            if _handRestrain.IsUnlocked
                _handRestrain = none
            endif
        endif
        if GetActor().wornhaskeyword(libs.zad_deviousHeavyBondage)
            if !_handRestrain
                _handRestrain = getHeavyBondageDevice()
            endif
        else
            _handRestrain = none
        endif
        return _handRestrain
    EndFunction
    
    Function set(UD_CustomDevice_RenderScript akDevice)
        _handRestrain = akDevice
    EndFunction
EndProperty

int _iUsedSlots = 0
int _iScriptState = 0
bool Property Ready = False auto hidden
bool    _isplayer = false

;Weapon Property BestWeapon = none auto hidden
Weapon _BestWeapon
Weapon Property UD_BestWeapon Hidden
    Weapon Function get()
        if !_BestWeapon || GetActor().getItemCount(_BestWeapon) == 0
            _BestWeapon = GetBestWeapon()
        endif
        return _BestWeapon
    EndFunction
    Function set(Weapon akWeapon)
        _BestWeapon = akWeapon
    EndFunction
EndProperty
float Property AgilitySkill         = 0.0 auto hidden
float Property StrengthSkill        = 0.0 auto hidden
float Property MagickSkill          = 0.0 auto hidden
float Property CuttingSkill         = 0.0 auto hidden
float Property SmithingSkill        = 0.0 auto hidden

float Property ArousalSkillMult     = 1.0 auto hidden

;prevent slot update
State UpdatePaused
    Function update(float fTimePassed)
    EndFunction
    Function updateDeviceHour(float fMult)
    EndFunction
    Function UpdateSlot(Bool abUpdateSkill = true)
    EndFunction
    Function DeviceUpdate(UD_CustomDevice_RenderScript akDevice,Float afTimePassed)
    EndFunction
    Function UpdateSkills()
    EndFunction
EndState

;update other variables
Function UpdateSlot(Bool abUpdateSkill = true)
    ArousalSkillMult = UDCDmain.getArousalSkillMult(getActor())
    if abUpdateSkill
        UpdateSkills()
    endif
    if !GetActor().wornhaskeyword(libs.zad_deviousHeavyBondage)
        _handRestrain = none ;unreference device
    endif
EndFunction

Function UpdateBodySlots()
    ;if !UD_BodySlots
    ;    UD_BodySlots = new Form[32]
    ;    GInfo("UD_BodySlots not init for " + getSlotedNPCName() + ", creating array")
    ;endif
    
    int loc_i = 0
    Actor loc_actor = GetActor()
    while loc_i < 32
        UD_BodySlots[loc_i] = loc_actor.GetWornForm(Math.LeftShift(0x1,loc_i))
        loc_i += 1
    endwhile
EndFunction

Form Function getSlotForm(int aiSlot)
    if UD_BodySlots
        return UD_BodySlots[aiSlot]
    else
        return none
    endif
EndFunction

bool _DeviceManipMutex = false
Function startDeviceManipulation()
    float loc_time = 0.0
    while _DeviceManipMutex && loc_time <= 60.0
        Utility.waitMenuMode(0.1)
        loc_time += 0.1
    endwhile
    _DeviceManipMutex = true
    
    if loc_time >= 60.0
        UDCDmain.Error("startDeviceManipulation timeout!!!")
    endif
EndFunction

Function endDeviceManipulation()
    _DeviceManipMutex = false
EndFunction

Event OnInit()
    Utility.wait(1.0)
    UD_equipedCustomDevices = UDCDMain.MakeNewDeviceSlots()
    Ready = True
EndEvent

Event OnPlayerLoadGame()
EndEvent

UD_CustomDevice_RenderScript Function GetUserSelectedDevice()
    String[] loc_devicesString = getSlotsStringA()
    loc_devicesString = PapyrusUtil.PushString(loc_devicesString,"--BACK--")
    int loc_deviceIndx = UDCDmain.GetUserListInput(loc_devicesString)
    
    if loc_deviceIndx != (loc_devicesString.length - 1) && loc_deviceIndx >= 0
        UD_CustomDevice_RenderScript loc_device = UD_equipedCustomDevices[loc_deviceIndx]
        ReorderSlots(loc_device)
        return loc_device
    else
        return none
    endif
EndFunction

String[] Function getSlotsStringA()
    String[] loc_res
    int i = 0
    while UD_equipedCustomDevices[i]
        loc_res = PapyrusUtil.PushString(loc_res,UD_equipedCustomDevices[i].getDeviceName())
        i+=1
    endwhile
    return loc_res
EndFunction

Function ReorderSlots(UD_CustomDevice_RenderScript firstDevice)
    startDeviceManipulation()
    int loc_reorderIndx = GetDeviceSlotIndx(firstDevice)
    int i = loc_reorderIndx 
    while i < UD_equipedCustomDevices.length
        if UD_equipedCustomDevices[i] && ((i + 1) != UD_equipedCustomDevices.length)
            UD_equipedCustomDevices[i] = UD_equipedCustomDevices[i + 1]
        endif
        i+=1
    endwhile
    
    ;push back
    i = UD_equipedCustomDevices.length - 1
    while i
        if !UD_equipedCustomDevices[i] && UD_equipedCustomDevices[i - 1]
            UD_equipedCustomDevices[i] = UD_equipedCustomDevices[i - 1]
            UD_equipedCustomDevices[i - 1] = none
        endif
        i-=1
    endwhile
    
    UD_equipedCustomDevices[0] = firstDevice
    endDeviceManipulation()
EndFunction

int Function GetDeviceSlotIndx(UD_CustomDevice_RenderScript device)
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i] == device
            return i
        endif
        i+=1
    endwhile
    return -1
EndFunction

Function SetSlotTo(Actor akActor)
    if UDmain.TraceAllowed()
        UDCDmain.Log("SetSlotTo("+getActorName(akActor)+") for " + self)
    endif

    if !IsPlayer()
        ForceRefTo(akActor)
    endif

    akActor.addToFaction(UDCDmain.RegisteredNPCFaction)

    if IsPlayer()
        UDOM.CheckOrgasmCheck(akActor)
        UDOM.CheckArousalCheck(akActor)
    else
        akActor.AddToFaction(UDOM.ArousalCheckLoopFaction)
        akActor.AddToFaction(UDOM.OrgasmCheckLoopFaction)
    endif

    UpdateSlot(false)

    if !IsPlayer()
        regainDevices()
    endif
EndFunction

Function Init()
EndFunction

bool Function isInPlayerCell()
    if UDmain.Player.getParentCell() == getActor().getParentCell()
        return true
    else
        return false
    endif
EndFunction

bool Function isScriptRunning()
    if _iUsedSlots > 0
        return True
    else
        return False
    endif
EndFunction

bool Function canUpdate()
    return !IsDead() && !getActor().getCurrentScene()
EndFunction

bool Function IsDead()
    if isUsed()
        return getActor().isDead() && !isPlayer()
    else
        return false
    endif
EndFunction

int Function getNumberOfRegisteredDevices()
    return _iUsedSlots
EndFunction

Function unregisterSlot()
    ;UDmain.Info("Unregistered NPC " + GetSlotedNPCName())
    if UDmain.TraceAllowed()
        UDCDmain.Log("NPC " + getSlotedNPCName() + " unregistered",2)
    endif
    if _iUsedSlots
        unregisterAllDevices()
    endif
    StorageUtil.UnSetIntValue(getActor(), "UD_ManualRegister")
    _iScriptState = 0
    if IsPlayer()
        UDOM.RemoveAbilities(getActor())
    else
        CleanArousalUpdate()
        CleanOrgasmUpdate()
    endif
    self.Clear()
EndFunction

Function sortSlots(bool mutex = true)
    if mutex
        startDeviceManipulation()
    endif
    int i = 0
    while i < UD_equipedCustomDevices.length - 1
        if UD_equipedCustomDevices[i] == none && UD_equipedCustomDevices[i + 1]
            UD_equipedCustomDevices[i] = UD_equipedCustomDevices[i + 1]
            UD_equipedCustomDevices[i + 1] = none
        endif
        
        ;sorted
        if UD_equipedCustomDevices[i] == none && UD_equipedCustomDevices[i + 1] == none
            endDeviceManipulation()
            return
        endif
        
        i+=1
    endwhile
    if mutex
        endDeviceManipulation()
    endif
EndFunction

;removes bullshit
Function QuickFix()
    removeCopies()
    removeUnusedDevices()
EndFunction

;fix bunch of problems
Function fix()
    Int loc_res = UDCDmain.UDCD_NPCM.UD_FixMenu_MSG.show()
    if loc_res == 0 ;general fix
        UDCDmain.Print("[UD] Starting general fixes")
        UDCDMain.ResetFetchFunction()
        removeCopies()
        removeUnusedDevices()
        removeLostRenderDevices()

        UDCDmain.EnableActor(getActor())

        getActor().removeFromFaction(UDCDmain.MinigameFaction)
        getActor().removeFromFaction(UDCDmain.BlockExpressionFaction)
        
        if IsPlayer()
            Game.EnablePlayerControls()
            Game.SetPlayerAiDriven(False)
        else
            getActor().SetDontMove(False)
        endif
        
        getActor().RemoveFromFaction(libs.zadAnimatingFaction)
        getActor().RemoveFromFaction(libs.Sexlab.AnimatingFaction)
        
        UDCDmain.libs.StartBoundEffects(getActor())
        
        _DeviceManipMutex = false
        
        if IsPlayer()
            UDOM.CheckArousalCheck(getActor())
            UDOM.CheckOrgasmCheck(getActor())
        endif
        UDCDmain.Print("[UD] loops checked!")
        
        UDCDmain.Print("[UD] General fixes done!")
    elseif loc_res == 1 ;reset orgasm var
        StorageUtil.UnsetFloatValue(getActor(), "UD_OrgasmRate")
        StorageUtil.UnsetFloatValue(getActor(), "UD_OrgasmForcing")
        StorageUtil.UnsetFloatValue(getActor(), "UD_OrgasmResistMultiplier")
        StorageUtil.UnsetFloatValue(getActor(), "UD_OrgasmRateMultiplier")
        StorageUtil.UnsetFloatValue(getActor(), "UD_ArousalRate")
        StorageUtil.UnsetFloatValue(getActor(), "UD_ArousalRateM")
        StorageUtil.UnsetIntValue(getActor(), "UD_OrgasmRate")
        StorageUtil.UnsetIntValue(getActor(), "UD_OrgasmForcing")
        StorageUtil.UnsetIntValue(getActor(), "UD_OrgasmResistMultiplier")
        StorageUtil.UnsetIntValue(getActor(), "UD_OrgasmRateMultiplier")
        StorageUtil.UnsetIntValue(getActor(), "UD_ArousalRate")
        StorageUtil.UnsetIntValue(getActor(), "UD_ArousalRateM")
        StorageUtil.UnsetIntValue(getActor(), "UD_OrgasmExhaustion")
        StorageUtil.UnsetIntValue(getActor(), "UD_ActiveVib_Strength")
        StorageUtil.UnsetIntValue(getActor(), "UD_ActiveVib")
        
        GetActor().DispelSpell(UDmain.UDlibs.ArousalCheckSpell)
        GetActor().AddSpell(UDmain.UDlibs.ArousalCheckAbilitySpell,true)
        
        GetActor().DispelSpell(UDmain.UDlibs.OrgasmCheckSpell)
        GetActor().AddSpell(UDmain.UDlibs.OrgasmCheckSpell,true)
        UDCDmain.Print("[UD] Orgasm variables reseted!")
    elseif loc_res == 2 ;reset expression
        UDCDMain.UDEM.ResetExpressionRaw(getActor(),100)
    elseif loc_res == 3 ;unequip slot
        UDCDmain.Print("[UD] Loading slots...")
        UpdateBodySlots()
        UDCDmain.Print("[UD] Slots loaded")
        if UD_BodySlots
            int loc_i = 0
            string[] loc_list
            while loc_i < 32
                String loc_string = "[" +(30 + loc_i) + "] "
                if UD_BodySlots[loc_i].getName()
                    loc_string += UD_BodySlots[loc_i].getName() ;armor have name, use it
                else
                    loc_string += UD_BodySlots[loc_i] ;armor doesn't have name, show editor ID
                    if UD_BodySlots[loc_i].HasKeyWord(UDmain.UDlibs.UnforgivingDevice)
                        loc_string += " (UD)"
                    elseif UD_BodySlots[loc_i].HasKeyWord(libs.zad_Lockable)
                        loc_string += " (DD)"
                    elseif UD_BodySlots[loc_i] == libs.DevicesUnderneath.zad_DeviceHider
                        loc_string += " (HIDER)" 
                    endif
                endif
                
                
                loc_list = PapyrusUtil.PushString(loc_list,loc_string)
                loc_i += 1
            endwhile
            loc_list = PapyrusUtil.PushString(loc_list,"-BACK-")
            int loc_slot = UDCDMain.GetUserListInput(loc_list)
            if loc_slot >= 0 && loc_slot < 32
                getActor().unequipItem(UD_BodySlots[loc_slot])
            endif
        endif
    endif
EndFunction

Function removeLostRenderDevices()
    ;if !isPlayer()
    ;    UDCDmain.Print("removeLostRenderDevices doesn't work for NPCs. Skipping!",1)
    ;endif
    
    startDeviceManipulation()
    if UDmain.TraceAllowed()    
        UDCDmain.Log("removeLostRenderDevices("+getSlotedNPCName()+")")
    endif
    Actor _currentSlotedActor = getActor()
    int iItem = _currentSlotedActor.GetNumItems()
    Form[] loc_toRemove
    while iItem
        iItem -= 1
        if UDmain.TraceAllowed()        
            UDCDmain.Log("removeLostRenderDevices("+getSlotedNPCName()+"): Proccesing form " + _currentSlotedActor.GetNthForm(iItem))
        endif
        Armor ArmorDevice = _currentSlotedActor.GetNthForm(iItem) as Armor
        
        if ArmorDevice ;is armor (optimalization)
            if UDmain.TraceAllowed()            
                UDCDmain.Log("removeLostRenderDevices("+getSlotedNPCName()+"): Proccesing armor " + ArmorDevice)
            endif
            if ArmorDevice.haskeyword(UDCDmain.UDlibs.UnforgivingDevice) ;is render device
                ;get script and check if player have inventory device
                Armor loc_RenDevice = ArmorDevice
                Armor loc_InvDevice = UDCDmain.getStoredInventoryDevice(loc_RenDevice)
                if UDmain.TraceAllowed()                
                    UDCDmain.Log("removeLostRenderDevices("+getSlotedNPCName()+"): Proccesing device " + loc_InvDevice.getName())
                endif
                bool loc_cond = !UDCDmain.CheckRenderDeviceEquipped(_currentSlotedActor,loc_RenDevice)
                if UDmain.TraceAllowed()                
                    UDCDmain.Log("removeLostRenderDevices("+getSlotedNPCName()+"): " + loc_InvDevice.getName() + ", cond: " + loc_cond)
                endif
                if  loc_cond
                    loc_toRemove = PapyrusUtil.PushForm(loc_toRemove, ArmorDevice)
                    UDCDmain.Print("Lost device found: " + loc_InvDevice.getName() + " removed!")
                else
                    if !getDeviceByRender(loc_RenDevice)
                        UDCDmain.Print("Found unregistred device "+loc_InvDevice.getName()+" , registering")
                        UD_CustomDevice_RenderScript loc_device = UDCDmain.getDeviceScriptByRender(GetActor(),loc_RenDevice)
                        if loc_device
                            RegisterDevice(loc_device,false)
                            UDCDmain.Print(loc_device.getDeviceHeader() + " registered")
                        else
                            UDCDmain.Print("Can't get device. Aborting.")
                        endif
                    endif
                endif
            endif
        endif
    endwhile
    
    int loc_toRemoveNum = loc_toRemove.length
    
    while loc_toRemoveNum
        loc_toRemoveNum -= 1
        if deviceAlreadyRegisteredRender(loc_toRemove[loc_toRemoveNum] as Armor)
            unregisterDeviceByRend(loc_toRemove[loc_toRemoveNum] as Armor,0,true,false) ;no mutex
        endif
        _currentSlotedActor.removeItem(loc_toRemove[loc_toRemoveNum],1,true)
    endwhile
    endDeviceManipulation()
EndFunction

bool Function registerDevice(UD_CustomDevice_RenderScript oref,bool mutex = true)
    if UDmain.TraceAllowed()    
        UDCDmain.Log("Starting slot device register for " + oref.getDeviceHeader() )
    endif
    if GetDeviceSlotIndx(oref) > 0
        UDmain.Error("registerDevice("+oref.getDeviceHeader()+") is already registered")
        return false
    endif
    if mutex
    startDeviceManipulation()
    endif
    int size = UD_equipedCustomDevices.length
    int i = 0
    while i < size
        if !UD_equipedCustomDevices[i]
            UD_equipedCustomDevices[i] = oref
            _iUsedSlots+=1
            if mutex
                endDeviceManipulation()
            endif
            return true
        endif
        i+=1
    endwhile
    if mutex
        endDeviceManipulation()
    endif
    return false
EndFunction

int Function unregisterDevice(UD_CustomDevice_RenderScript oref,int i = 0,bool sort = True,bool mutex = true)
    if mutex
        startDeviceManipulation()
    endif
    int res = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i] == oref
            UD_equipedCustomDevices[i] = none
            _iUsedSlots-=1
            res += 1
        endif
        i+=1
    endwhile
    if mutex
        endDeviceManipulation()
    endif
    ;if isScriptRunning() && _iUsedSlots == 0
        ;resetScriptState()
    ;    return res
    ;endif    
    
    if isScriptRunning() && sort
        sortSlots(mutex)
    endif
    
    return res
EndFunction

int Function unregisterDeviceByInv(Armor invDevice,int i = 0,bool sort = True,bool mutex = true)

    int res = 0
    UD_CustomDevice_RenderScript loc_device = getDeviceByInventory(invDevice)
    
    if !loc_device
        UDCDmain.Error("unregisterDeviceByInv("+getSlotedNPCName()+","+invDevice.getName()+") failed!! No registered device found")
        return res
    endif
    
    return unregisterDevice(loc_device,i,sort,mutex)
EndFunction

int Function unregisterDeviceByRend(Armor rendDevice,int i = 0,bool sort = True,bool mutex = true)

    int res = 0
    UD_CustomDevice_RenderScript loc_device = getDeviceByRender(rendDevice)
    
    if !loc_device
        UDCDmain.Error("unregisterDeviceByRend("+getSlotedNPCName()+","+rendDevice+") failed!! No registered device found")
        return res
    endif
    
    return unregisterDevice(loc_device,i,sort,mutex)
EndFunction

int Function unregisterAllDevices(int i = 0,bool mutex = true)
    if mutex
        startDeviceManipulation()
    endif
    int res = 0
    while UD_equipedCustomDevices[i]
        UD_equipedCustomDevices[i] = none
        _iUsedSlots-=1
        res += 1
        i += 1
    endwhile
    if mutex
        endDeviceManipulation()
    endif
    return res
EndFunction

bool Function deviceAlreadyRegistered(Armor deviceInventory)
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].deviceInventory == deviceInventory
            return true
        endif
        i+=1
    endwhile
    return false
EndFunction

bool Function deviceAlreadyRegisteredKw(Keyword kw,Bool abCheckAllKw = false)
    int i = 0
    while UD_equipedCustomDevices[i]
        if (UD_equipedCustomDevices[i].UD_DeviceKeyword == kw) || (abCheckAllKw && UD_equipedCustomDevices[i].DeviceRendered.haskeyword(kw))
            return true
        endif
        i+=1
    endwhile
    return false
EndFunction

bool FUnction deviceAlreadyRegisteredRender(Armor deviceRendered)
    int i = 0
    while UD_equipedCustomDevices[i];UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].deviceRendered == deviceRendered
            return true
        endif
        i+=1
    endwhile
    return false
    
EndFunction

Function removeAllDevices()
    ;startDeviceManipulation()
    StorageUtil.SetIntValue(getActor(), "UD_blockSlotUpdate",1)
    while UD_equipedCustomDevices[0]
        UD_equipedCustomDevices[0].unlockRestrain()
    endwhile
    ;regainDevices()
    StorageUtil.UnSetIntValue(getActor(), "UD_blockSlotUpdate")
    ;endDeviceManipulation()
EndFunction

Function removeUnusedDevices()
    startDeviceManipulation()
    int i = 0
    while UD_equipedCustomDevices[i]
        UD_CustomDevice_RenderScript loc_device = UD_equipedCustomDevices[i]
        bool loc_condInv  =  loc_device.getWearer().getItemCount(loc_device.deviceInventory) == 0
        bool loc_condRend =  loc_device.getWearer().getItemCount(loc_device.deviceRendered)  == 0
        
        if loc_condInv || loc_condRend
            if !loc_condRend && loc_condInv ;remove render device if it for some reason doesn't removed it before
                loc_device.removeDevice(loc_device.getWearer())
                loc_device.getWearer().removeItem(loc_device.deviceRendered)
            endif
            UD_equipedCustomDevices[i] = none
            if UDmain.TraceAllowed()            
                UDCDmain.Log(loc_device.getDeviceName() + " is unused, removing from " + getSlotedNPCName(),2)
            endif
            _iUsedSlots -= 1
        endif
        i+=1
    endwhile
    endDeviceManipulation()
    
    sortSlots()
EndFunction

int Function numberOfUnusedDevices()
    int res = 0
    int i = 0
    while UD_equipedCustomDevices[i]
        if !UD_equipedCustomDevices[i].getWearer().IsEquipped(UD_equipedCustomDevices[i].deviceInventory) && isPlayer()
            res += 1
        endif
        i+=1
    endwhile
    return res
EndFunction

;replece slot with new device
Function replaceSlot(UD_CustomDevice_RenderScript oref, Armor inventoryDevice)
    startDeviceManipulation()
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].deviceInventory == inventoryDevice
            UD_equipedCustomDevices[i] = oref
        endif
        i+=1
    endwhile
    endDeviceManipulation()
EndFunction

int Function getCopiesOfDevice(UD_CustomDevice_RenderScript oref)
    int res = 0
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].deviceInventory == oref.deviceInventory
            res += 1
        endif
        i+=1
    endwhile
    
    return res
EndFunction

Function removeCopies()
    ;startDeviceManipulation()
    int i = 0
    while UD_equipedCustomDevices[i]
        if i < _iUsedSlots - 1
            unregisterDevice(UD_equipedCustomDevices[i],i + 1)
        endif
        i+=1
    endwhile
    ;endDeviceManipulation()
EndFunction

int Function numberOfCopies()
    int res = 0
    int i = 0
    while UD_equipedCustomDevices[i]
        if i < _iUsedSlots - 1
            res += getCopiesOfDevice(UD_equipedCustomDevices[i])
        endif
        i+=1
    endwhile
    return res
EndFunction

int Function debugSize()
    int i = 0
    while UD_equipedCustomDevices[i]
        i+=1
    endwhile
    return i
EndFunction

Function orgasm()
    if UDmain.UD_OrgasmExhaustion
        UDmain.addOrgasmExhaustion(getActor())
    endif
    int size = UD_equipedCustomDevices.length
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].isReady()
            UD_equipedCustomDevices[i].orgasm()
            UDmain.UDMOM.Procces_UpdateModifiers_Orgasm(UD_equipedCustomDevices[i])
        else
            GError("Device " + UD_equipedCustomDevices[i].GetDeviceName() + " is not ready -> aborting orgasm call")
        endif
        i+=1
    endwhile
EndFunction

Event OnActivateDevice(string sDeviceName)
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].deviceInventory.getName() == sDeviceName && UD_equipedCustomDevices[i].isReady()
            UD_equipedCustomDevices[i].activateDevice()
            return
        endif
        i+=1
    endwhile
EndEvent

;call devices function orgasm() when player have sexlab orgasm
Event SexlabOrgasmStart(bool HasPlayer)               
    int size = UD_equipedCustomDevices.length
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].isReady()
            UD_equipedCustomDevices[i].orgasm(True)
        endif
        i+=1
    endwhile
EndEvent 

;call devices function edge() when player get edged
Function edge()
    int size = UD_equipedCustomDevices.length
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].isReady()
            UD_equipedCustomDevices[i].edge()
        endif
        i+=1
    endwhile
EndFunction

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
    if isScriptRunning()
        if UDmain.TraceAllowed()
            UDCDmain.Log("OnHit("+akAggressor+","+akSource+","+akProjectile+") on " + getSlotedNPCName())
        endif
        if akSource
            if akSource as Weapon
                OnWeaponHit(akSource as Weapon)
            elseif akSource as Spell
                OnSpellHit(akSource as Spell)
            endif
        endif
    endif
EndEvent

Function OnWeaponHit(Weapon source)
    int i = 0
    while UD_equipedCustomDevices[i]
        UD_equipedCustomDevices[i].weaponHit(source)
        i+=1
    endwhile
EndFunction

Function OnSpellHit(Spell source)
    int i = 0
    while UD_equipedCustomDevices[i]
        UD_equipedCustomDevices[i].spellHit(source)
        i+=1
    endwhile    
EndFunction

Function showDebugMenu(int slot_id)
    if slot_id >= 0 && slot_id < 20 && slot_id < _iUsedSlots
    UD_CustomDevice_RenderScript selectedDevice = UD_equipedCustomDevices[slot_id]
        while UD_equipedCustomDevices[slot_id] == selectedDevice && UD_equipedCustomDevices[slot_id]
            int res = UDCDmain.DebugMessage.show(UD_equipedCustomDevices[slot_id].getDurability(),UD_equipedCustomDevices[slot_id].getMaxDurability(),100.0 - UD_equipedCustomDevices[slot_id].getCondition())
            if res == 0 ;dmg dur
                UD_equipedCustomDevices[slot_id].decreaseDurabilityAndCheckUnlock(10.0)
                if UD_equipedCustomDevices[slot_id].isUnlocked
                    return
                endif
            elseif res == 1 ;repair dur
                UD_equipedCustomDevices[slot_id].decreaseDurabilityAndCheckUnlock(-10.0)
            elseif res == 2 ;repatch
                UD_equipedCustomDevices[slot_id].patchDevice()
                ;UDCDmain.UDPatcher.safecheckAnimations(UD_equipedCustomDevices[slot_id],True)
                ;UD_equipedCustomDevices[slot_id].safeCheckAnimations()
                return
            elseif res == 3 ;unlock
                UD_equipedCustomDevices[slot_id].unlockRestrain()
                return
            elseif res == 4 ;unregister
                unregisterDevice(UD_equipedCustomDevices[slot_id])
                return
            elseif res == 5 ;activate
                UD_equipedCustomDevices[slot_id].activateDevice()
                return
            elseif res == 6 ;Add modifier
                string[] loc_ModifierList = new String[9]
                loc_ModifierList[0] = "Regen"
                loc_ModifierList[1] = "Sentient"
                loc_ModifierList[2] = "Loose"
                loc_ModifierList[3] = "MAO"
                loc_ModifierList[4] = "MAH"
                loc_ModifierList[5] = "_HEAL"
                loc_ModifierList[6] = "LootGold"
                loc_ModifierList[7] = "DOR"
                loc_ModifierList[8] = "_L_CHEAP"
                int loc_res1 = UDCDMain.GetUserListInput(loc_ModifierList)
                if loc_res1 >= 0
                    String loc_modName = loc_ModifierList[loc_res1]
                    String loc_param = UDCDMain.GetUserTextInput()
                    
                    if !UD_equipedCustomDevices[slot_id].addModifier(loc_modName,loc_param)
                        UDCDmain.Print("Error! Can't add " + loc_modName)
                    endif
                endif
                ;UD_equipedCustomDevices[slot_id].addModifier()
                ;debug.messagebox(UD_equipedCustomDevices[slot_id].getInfoString())
            elseif res == 7 ;Remove modifier
                if UD_equipedCustomDevices[slot_id].UD_Modifiers.length > 0
                    int loc_res = UDCDMain.GetUserListInput(UD_equipedCustomDevices[slot_id].UD_Modifiers)
                    if loc_res >= 0
                        string loc_modRaw = UD_equipedCustomDevices[slot_id].UD_Modifiers[loc_res]
                        string loc_modHead = UD_equipedCustomDevices[slot_id].GetModifierHeader(loc_modRaw)
                        if !UD_equipedCustomDevices[slot_id].removeModifier(loc_modHead)
                            UDCDmain.Print("Error! Can't remove " + loc_modRaw)
                        endif
                    endif
                endif
                ;debug.messagebox(UD_equipedCustomDevices[slot_id].getDebugString())
            else
                return
            endif
        endwhile
    endif
EndFunction

Function update(float fTimePassed)
    int i = 0
    while UD_equipedCustomDevices[i]
        DeviceUpdate(UD_equipedCustomDevices[i],fTimePassed)
        i+=1
    endwhile
EndFunction

Function DeviceUpdate(UD_CustomDevice_RenderScript akDevice,Float afTimePassed)
    if akDevice.isReady()
        akDevice.update(afTimePassed)
    endif
EndFunction

Function updateDeviceHour(float fMult)
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].isReady()
            UD_equipedCustomDevices[i].updateHour(fMult)
        endif
        i+=1
    endwhile
EndFunction

Function updateHour(float fMult)
    UpdateMotivationToDef(GetActor(),10) ;decrease/increase motivation so it will finally reach default 100
EndFunction

;returns first device which have connected corresponding Inventory Device
UD_CustomDevice_RenderScript Function getDeviceByInventory(Armor deviceInventory)
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].deviceInventory == deviceInventory
            return UD_equipedCustomDevices[i]
        endif
        i+=1
    endwhile
    return none
EndFunction

;returns first device which have connected corresponding Render Device
UD_CustomDevice_RenderScript Function getDeviceByRender(Armor deviceRendered)
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].deviceRendered == deviceRendered
            return UD_equipedCustomDevices[i]
        endif
        i+=1
    endwhile
    return none
EndFunction

;returns heavy bondage (hand restrain) device
UD_CustomDevice_RenderScript Function getHeavyBondageDevice()
    int size = UD_equipedCustomDevices.length
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].isHeavyBondage()
            return UD_equipedCustomDevices[i]
        endif
        i+=1
    endwhile
    
    return none
EndFunction

;returs first device by keywords
;mod = 0 => AND     (device need all provided keyword)
;mod = 1 => OR     (device need one provided keyword)
UD_CustomDevice_RenderScript Function getFirstDeviceByKeyword(keyword kw1,keyword kw2 = none,keyword kw3 = none, int mod = 0)
    if !kw2
        kw2 = kw1
    endif
    
    if !kw3
        kw3 = kw1
    endif
    
    int i = 0
    while UD_equipedCustomDevices[i]
        if mod == 0
            if UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw1) && UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw2) && UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw3)
                return UD_equipedCustomDevices[i]
            endif
        elseif mod == 1
            if UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw1) || UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw2) || UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw3)
                return UD_equipedCustomDevices[i]
            endif
        endif
        i+=1
    endwhile
    return none
EndFunction

;returns last device containing keyword
UD_CustomDevice_RenderScript Function getLastDeviceByKeyword(keyword kw1,keyword kw2 = none,keyword kw3 = none, int mod = 0)
    if !kw2
        kw2 = kw1
    endif
    
    if !kw3
        kw3 = kw1
    endif
    
    int i = _iUsedSlots
    while i
        i-=1
        if mod == 0
            if UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw1) && UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw2) && UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw3)
                return UD_equipedCustomDevices[i]
            endif
        elseif mod == 1
            if UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw1) || UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw2) || UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw3)
                return UD_equipedCustomDevices[i]
            endif
        endif
    endwhile
    return none
EndFunction

;returs first device by keywords
;mod = 0 => AND     (device need all provided keyword)
;mod = 1 => OR     (device need one provided keyword)
UD_CustomDevice_RenderScript Function getDeviceByKeyword(keyword akKeyword)
    if !akKeyword
        UDCDmain.Error(getSlotedNPCName() + " slot - getDeviceByKeyword - keyword = none")
        return none
    endif
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].UD_DeviceKeyword == (akKeyword)
            return UD_equipedCustomDevices[i]
        endif
        i+=1
    endwhile
    return none
EndFunction

;returns array of all device containing keyword in their render device
;mod = 0 => AND     (device need all provided keyword)
;mod = 1 => OR         (device need one provided keyword)
UD_CustomDevice_RenderScript[] Function getAllDevicesByKeyword(keyword kw1,keyword kw2 = none,keyword kw3 = none, int mod = 0)
    if !kw2
        kw2 = kw1
    endif
    
    if !kw3
        kw3 = kw1
    endif
    
    UD_CustomDevice_RenderScript[] res = UDCDMain.MakeNewDeviceSlots()
    int found_devices = 0
    int size = UD_equipedCustomDevices.length
    int i = 0
    while UD_equipedCustomDevices[i]
        if mod == 0
            if UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw1) && UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw2) && UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw3)
                res[found_devices] = UD_equipedCustomDevices[i]
                found_devices += 1
            endif
        elseif mod == 1
            if UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw1) || UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw2) || UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw3)
                res[found_devices] = UD_equipedCustomDevices[i]
                found_devices += 1
            endif
        endif
        i+=1
    endwhile
    return res
EndFunction

;returns array of all device containing keyword in their render device
;mod = 0 => AND     (device need all provided keyword)
;mod = 1 => OR         (device need one provided keyword)
UD_CustomDevice_RenderScript[] Function getAllActivableDevicesByKeyword(bool bCheckCondition, keyword kw1,keyword kw2 = none,keyword kw3 = none, int mod = 0)
    if !kw2
        kw2 = kw1
    endif
    
    if !kw3
        kw3 = kw1
    endif
    
    UD_CustomDevice_RenderScript[] res = UDCDMain.MakeNewDeviceSlots()
    int found_devices = 0
    int size = UD_equipedCustomDevices.length
    int i = 0
    while UD_equipedCustomDevices[i]
        if mod == 0
            if UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw1) && UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw2) && UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw3)
                if (UD_equipedCustomDevices[i].canBeActivated() || !bCheckCondition)  && UD_equipedCustomDevices[i].isNotShareActive()
                    res[found_devices] = UD_equipedCustomDevices[i]
                    found_devices += 1
                endif
            endif
        elseif mod == 1
            if UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw1) || UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw2) || UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw3)
                if (UD_equipedCustomDevices[i].canBeActivated() || !bCheckCondition) && UD_equipedCustomDevices[i].isNotShareActive()
                    res[found_devices] = UD_equipedCustomDevices[i]
                    found_devices += 1
                endif
            endif
        endif
        i+=1
    endwhile
    return res
EndFunction

;returns number of all device containing keyword in their render device
;mod = 0 => AND     (device need all provided keyword)
;mod = 1 => OR     (device need one provided keyword)
int Function getNumberOfDevicesWithKeyword(keyword kw1,keyword kw2 = none,keyword kw3 = none, int mod = 0)
    if !kw2
        kw2 = kw1
    endif
    
    if !kw3
        kw3 = kw1
    endif

    int found_devices = 0
    int size = UD_equipedCustomDevices.length
    int i = 0
    while UD_equipedCustomDevices[i]
        if mod == 0
            if UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw1) && UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw2) && UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw3)
                found_devices += 1
            endif
        elseif mod == 1
            if UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw1) || UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw2) || UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw3)
                found_devices += 1
            endif
        endif
        i+=1
    endwhile
    return found_devices
EndFunction

;returns number of all device containing keyword in their render device
;mod = 0 => AND     (device need all provided keyword)
;mod = 1 => OR     (device need one provided keyword)
int Function getNumberOfActivableDevicesWithKeyword(bool bCheckCondition, keyword kw1,keyword kw2 = none,keyword kw3 = none, int mod = 0)
    if !kw2
        kw2 = kw1
    endif
    
    if !kw3
        kw3 = kw1
    endif

    int found_devices = 0
    int size = UD_equipedCustomDevices.length
    int i = 0
    while UD_equipedCustomDevices[i]
        if mod == 0
            if UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw1) && UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw2) && UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw3)
                if (UD_equipedCustomDevices[i].canBeActivated() || !bCheckCondition) && UD_equipedCustomDevices[i].isNotShareActive()
                    found_devices += 1
                endif
            endif
        elseif mod == 1
            if UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw1) || UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw2) || UD_equipedCustomDevices[i].deviceRendered.hasKeyword(kw3)
                if (UD_equipedCustomDevices[i].canBeActivated() || !bCheckCondition) && UD_equipedCustomDevices[i].isNotShareActive()
                    found_devices += 1
                endif
            endif
        endif
        i+=1
    endwhile
    return found_devices
EndFunction

;returns number of devices that can be activated
int Function getActiveDevicesNum()
    int found_devices = 0
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].canBeActivated() && UD_equipedCustomDevices[i].isNotShareActive()
            found_devices += 1
        endif
        i+=1
    endwhile
    return found_devices
EndFunction

;returns all device that can be activated
UD_CustomDevice_RenderScript[] Function getActiveDevices()
    UD_CustomDevice_RenderScript[] res = UDCDMain.MakeNewDeviceSlots()
    int found_devices = 0
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].canBeActivated() && UD_equipedCustomDevices[i].isNotShareActive()
            res[found_devices] = UD_equipedCustomDevices[i]
            found_devices += 1
        endif
        i+=1
    endwhile
    return res
EndFunction


Function TurnOffAllVibrators()
    if UDmain.TraceAllowed()    
        UDCDmain.Log("TurnOffAllVibrators() called for " + getSlotedNPCName(),1)
    endif
    int i = 0
    while UD_equipedCustomDevices[i]
        UD_CustomVibratorBase_RenderScript loc_vib = (UD_equipedCustomDevices[i] as UD_CustomVibratorBase_RenderScript)
        if loc_vib && !(loc_vib as UD_ControlablePlug_RenderScript)
            if loc_vib.isVibrating() && loc_vib.getRemainingVibrationDuration() > 0
                if UDmain.TraceAllowed()                
                    UDCDmain.Log("Stoping " + UD_equipedCustomDevices[i].getDeviceName() + " on " + getSlotedNPCName())
                endif
                (UD_equipedCustomDevices[i] as UD_CustomVibratorBase_RenderScript).stopVibrating()
            endif
        endif
        i+=1
    endwhile
EndFunction

;returns number of vibrators
int Function getVibratorNum()
    if UDmain.TraceAllowed()    
        UDCDmain.Log("getVibratorNum() called for " + getSlotedNPCName(),3)
    endif
    int found_devices = 0
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i] as UD_CustomVibratorBase_RenderScript
            found_devices += 1
        endif
        i+=1
    endwhile
    if UDmain.TraceAllowed()    
        UDCDmain.Log("getOffVibratorNum() - return value: " + found_devices,3)
    endif
    return found_devices
EndFunction

;returns number of vibrators
int Function getActivableVibratorNum()
    int found_devices = 0
    int i = 0
    while UD_equipedCustomDevices[i]
        UD_CustomVibratorBase_RenderScript loc_vib = UD_equipedCustomDevices[i] as UD_CustomVibratorBase_RenderScript
        if loc_vib
            if loc_vib.canVibrate()
                found_devices += 1
            endif
        endif
        i+=1
    endwhile
    return found_devices
EndFunction

;returns number of turned off vibrators (and the ones which can be turned on)
int Function getOffVibratorNum()
    if UDmain.TraceAllowed()    
        UDCDmain.Log("getOffVibratorNum() called for " + getSlotedNPCName(),3)
    endif
    int found_devices = 0
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i] as UD_CustomVibratorBase_RenderScript
            UD_CustomVibratorBase_RenderScript loc_vibrator = (UD_equipedCustomDevices[i] as UD_CustomVibratorBase_RenderScript)
            if loc_vibrator.CanVibrate() && !loc_vibrator.isVibrating()
                found_devices += 1
            endif
        endif
        i+=1
    endwhile
    if UDmain.TraceAllowed()    
        UDCDmain.Log("getOffVibratorNum() - return value: " + found_devices,3)
    endif
    return found_devices
EndFunction

;returns all vibrators
UD_CustomDevice_RenderScript[] Function getVibrators()
    if UDmain.TraceAllowed()    
        UDCDmain.Log("getVibrators() called for " + getSlotedNPCName(),3)
    endif
    UD_CustomDevice_RenderScript[] res = UDCDmain.MakeNewDeviceSlots()
    int found_devices = 0
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i] as UD_CustomVibratorBase_RenderScript
            UD_CustomVibratorBase_RenderScript loc_vibrator = (UD_equipedCustomDevices[i] as UD_CustomVibratorBase_RenderScript)
            ;if loc_vibrator.CanVibrate()
                if UDmain.TraceAllowed()                
                    UDCDmain.Log("getVibrators() - usable vibrator found: " + loc_vibrator.getDeviceName(),3)
                endif
                res[found_devices] = loc_vibrator
                found_devices += 1
            ;endif
        endif
        i+=1
    endwhile
    if UDmain.TraceAllowed()    
        UDCDmain.Log("getVibrators() - return array: " + res,3)
    endif
    return res
EndFunction

;returns all turned off vibrators
UD_CustomDevice_RenderScript[] Function getOffVibrators()
    if UDmain.TraceAllowed()    
        UDCDmain.Log("getOffVibrators() called for " + getSlotedNPCName(),3)
    endif
    UD_CustomDevice_RenderScript[] res = UDCDmain.MakeNewDeviceSlots()
    int found_devices = 0
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i] as UD_CustomVibratorBase_RenderScript
            if UDmain.TraceAllowed()            
                UDCDmain.Log("getOffVibrators() - vibrator found: " + UD_equipedCustomDevices[i].getDeviceName(),3)
            endif
            UD_CustomVibratorBase_RenderScript loc_vibrator = (UD_equipedCustomDevices[i] as UD_CustomVibratorBase_RenderScript)
            if loc_vibrator.CanVibrate() && !loc_vibrator.isVibrating()
                if UDmain.TraceAllowed()                
                    UDCDmain.Log("getOffVibrators() - non used vibrator found: " + UD_equipedCustomDevices[i].getDeviceName(),3)
                endif
                res[found_devices] = loc_vibrator
                found_devices += 1
            endif
        endif
        i+=1
    endwhile
    if UDmain.TraceAllowed()    
        UDCDmain.Log("getOffVibrators() - return array: " + res,3)
    endif
    return res
EndFunction

;returns all turned activable vibrators
UD_CustomDevice_RenderScript[] Function getActivableVibrators()
    UD_CustomDevice_RenderScript[] res = UDCDmain.MakeNewDeviceSlots()
    int found_devices = 0
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i] as UD_CustomVibratorBase_RenderScript
            UD_CustomVibratorBase_RenderScript loc_vibrator = (UD_equipedCustomDevices[i] as UD_CustomVibratorBase_RenderScript)
            if loc_vibrator.CanVibrate()
                res[found_devices] = loc_vibrator
                found_devices += 1
            endif
        endif
        i+=1
    endwhile
    return res
EndFunction

;???
Function deleteLastUsedSlot()
    startDeviceManipulation()
    int i = 0
    while i <  UD_equipedCustomDevices.length
        if !UD_equipedCustomDevices[i]
            UD_equipedCustomDevices[i - 1].delete()
            UD_equipedCustomDevices[i - 1] = none
            _iUsedSlots-=1
            endDeviceManipulation()
            return
        endif
        i+=1
    endwhile
    endDeviceManipulation()
EndFunction

;returns current device that have minigame on (return none if no minigame is on)
UD_CustomDevice_RenderScript Function getMinigameDevice()
    int size = UD_equipedCustomDevices.length
    int i = 0
    while UD_equipedCustomDevices[i]
        if UD_equipedCustomDevices[i].isMinigameOn()
            return UD_equipedCustomDevices[i]
        endif
        i+=1
    endwhile
    
    return none
EndFunction

bool Function hasFreeHands(bool checkGrasp = false)
    bool res = !getActor().wornhaskeyword(UDCDmain.libs.zad_deviousHeavyBondage) 
        
    if checkGrasp
        if getActor().wornhaskeyword(UDCDmain.libs.zad_DeviousBondageMittens)
            res = false
        endif
    endif
    return res
EndFunction

bool Function isPlayer()
    return False
EndFunction

bool Function isUsed()
    if getActor()
        return true
    else
        return false
    endif
EndFunction

Bool Function IsInMinigame()
    Actor loc_actor = getActor()
    if loc_actor
        return loc_actor.IsInFaction(UDCDmain.MinigameFaction)
    else
        return false
    endif
EndFunction

Bool Function HaveLockingOperations()
    Actor loc_actor = getActor()
    if loc_actor
        return StorageUtil.GetIntValue(loc_actor,"UDLockOperations",0)
    else
        return 0
    endif
EndFunction

String Function getSlotedNPCName()
    if isUsed()
        return (getActorReference()).getLeveledActorBase().getName()
    else
        return "Empty"
    endif
EndFunction

Actor Function getActor()
    return self.getActorReference()
EndFunction

int Function removeWrongWearerDevices()
    ;startDeviceManipulation()
    int res = 0
    int i = 0
    Actor _currentSlotedActor = getActor()
    while UD_equipedCustomDevices[i]
        if (UD_equipedCustomDevices[i].getWearer() != _currentSlotedActor) || UD_equipedCustomDevices[i].isUnlocked
            res += unregisterDevice(UD_equipedCustomDevices[i],i,False)
        endif
        i+=1
    endwhile
    ;endDeviceManipulation()
    if res > 0
        sortSlots()
    endif
    return res
EndFunction

Function resetValues()
    _iScriptState = 1
EndFunction

bool _regainMutex = false
Function regainDevices()
    Actor _currentSlotedActor = getActor()
    if _currentSlotedActor.GetItemCount(UDCDmain.UDlibs.PatchedInventoryDevice) == 0 || _currentSlotedActor.GetItemCount(UDCDmain.UDlibs.UnforgivingDevice) == 0
        return
    endif
    
    while _regainMutex
        Utility.waitMenuMode(0.1)
    endwhile
    _regainMutex = True
    
    ;super complex shit
    int removedDevices = removeWrongWearerDevices()
    int loc_slotmask = 0x80000000;_currentSlotedActor.GetNumItems()
    while loc_slotmask
        loc_slotmask = Math.RightShift(loc_slotmask,1)
        Armor ArmorDevice = _currentSlotedActor.GetWornForm(loc_slotmask) as Armor;GetNthForm(iItem) as Armor
        if ArmorDevice
            if ArmorDevice.hasKeyword(UDCDmain.UDlibs.UnforgivingDevice)
                ;render device with custom script -> register
                if !deviceAlreadyRegisteredRender(ArmorDevice)
                    UD_CustomDevice_RenderScript script = UDCDmain.getDeviceScriptByRender(_currentSlotedActor,ArmorDevice)
                    if _currentSlotedActor.getItemCount(script.DeviceInventory) && _currentSlotedActor.getItemCount(script.DeviceRendered)
                        if registerDevice(script)
                            if UDmain.TraceAllowed()
                                UDmain.Log("UD_CustomDevice_NPCSlot,"+ self +"/ Device "+ script.getDeviceName() + " succesfully registered!",2)
                            endif
                        endif
                    endif
                endif
            endif
        endif
    endwhile
    _regainMutex = False
EndFunction


Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    if akBaseItem as Weapon
        Weapon loc_weapon = akBaseItem as Weapon
        if UDCDmain.isSharp(loc_weapon)
            if _BestWeapon.getBaseDamage() < loc_weapon.GetBaseDamage()
                _BestWeapon = loc_weapon
            endif
        endif
    endIf
endEvent

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    if akBaseItem as Weapon
        Weapon loc_weapon = akBaseItem as Weapon
        if loc_weapon == _BestWeapon
            if getActor().getItemCount(loc_weapon) == 0
                _BestWeapon = GetBestWeapon() ;find the next best weapon
            endif
        endif
    endIf
endEvent

Weapon Function GetBestWeapon()
    int loc_i = getActor().GetNumItems()
    Weapon loc_res = none
    if getActor().GetItemCount(_BestWeapon)
        loc_res = _BestWeapon
    endif
    while loc_i
        loc_i -= 1
        Weapon loc_weapon = getActor().GetNthForm(loc_i) as Weapon
        if loc_weapon
            if UDCDmain.isSharp(loc_weapon)
                if !loc_res
                    loc_res = loc_weapon
                elseif (loc_weapon.getBaseDamage() > loc_res.GetBaseDamage())
                    loc_res = loc_weapon
                endif
            endif
        endif
    endwhile
    return loc_res
EndFunction

Function UpdateSkills()
    AgilitySkill    = UDmain.UDSKILL.getActorAgilitySkills(getActor())
    StrengthSkill   = UDmain.UDSKILL.getActorStrengthSkills(getActor())
    MagickSkill     = UDmain.UDSKILL.getActorMagickSkills(getActor())
    CuttingSkill    = UDmain.UDSKILL.getActorCuttingSkills(getActor())
    SmithingSkill   = UDmain.UDSKILL.getActorSmithingSkills(getActor())
EndFunction


;===============================================================================
;===============================================================================
;                                    MUTEX
;===============================================================================
;===============================================================================

;LOCK MUTEX
bool        Property UD_GlobalDeviceMutex_InventoryScript                   = false     auto hidden
bool        Property UD_GlobalDeviceMutex_InventoryScript_Failed            = false     auto hidden
Armor       Property UD_GlobalDeviceMutex_Device                            = none      auto hidden

;UNLOCK MUTEX
bool        Property UD_GlobalDeviceUnlockMutex_InventoryScript             = false     auto hidden
bool        Property UD_GlobalDeviceUnlockMutex_InventoryScript_Failed      = false     auto hidden
Armor       Property UD_GlobalDeviceUnlockMutex_Device                      = none      auto hidden

Keyword     Property UD_UnlockToken                                         = none      auto hidden    

Function ResetMutex_Lock(Armor invDevice)
    UD_GlobalDeviceMutex_inventoryScript                 = false
    UD_GlobalDeviceMutex_InventoryScript_Failed         = false
    UD_GlobalDeviceMutex_Device                         = invDevice
EndFunction

Function ResetMutex_Unlock(Armor invDevice)
    UD_GlobalDeviceUnlockMutex_InventoryScript             = false
    UD_GlobalDeviceUnlockMutex_InventoryScript_Failed     = false
    UD_UnlockToken                                        = none
    UD_GlobalDeviceUnlockMutex_Device                     = invDevice
EndFunction

Bool Function IsMutexOn()
    return _LOCKDEVICE_MUTEX || _UNLOCKDEVICE_MUTEX
EndFunction

;function made as replacemant for akActor.isEquipped, because that function doesn't work for NPCs
bool Function CheckRenderDeviceEquipped(Armor rendDevice)
    if !isUsed()
        return false
    endif
    
    int loc_mask = 0x00000001
    while loc_mask != 0x80000000
        Form loc_armor = getActor().GetWornForm(loc_mask)
        if loc_armor ;check if there is anything in slot
            if (loc_armor as Armor) == rendDevice
                return true ;render device is equipped
            endif
        endif
        loc_mask = Math.LeftShift(loc_mask,1)
    endwhile
    return false ;device is not equipped
EndFunction

Bool _LOCKDEVICE_MUTEX = false
Function StartLockMutex()
    while _LOCKDEVICE_MUTEX
        Utility.waitMenuMode(0.1)
    endwhile
    _LOCKDEVICE_MUTEX = true
    GoToState("UpdatePaused")
EndFunction

Function EndLockMutex()
    GoToState("")
    _LOCKDEVICE_MUTEX = false
EndFunction

Bool Function IsLockMutexed(Armor invDevice)
    return UD_GlobalDeviceMutex_Device == invDevice
EndFunction

Bool _UNLOCKDEVICE_MUTEX = false
Function StartUnLockMutex()
    while _UNLOCKDEVICE_MUTEX
        Utility.waitMenuMode(0.1)
    endwhile
    _UNLOCKDEVICE_MUTEX = true
    GoToState("UpdatePaused")
EndFunction

Function EndUnLockMutex()
    GoToState("")
    _UNLOCKDEVICE_MUTEX = false
EndFunction

Bool Function IsUnlockMutexed(Armor invDevice)
    return UD_GlobalDeviceUnlockMutex_Device == invDevice
EndFunction


Function ProccesLockMutex()
    float loc_time = 0.0
    while loc_time <= 3.0 && (!UD_GlobalDeviceMutex_InventoryScript)
        Utility.waitMenuMode(0.1)
        loc_time += 0.1
    endwhile
    
    if UD_GlobalDeviceMutex_InventoryScript_Failed || loc_time >= 3.0
        UDCDmain.Error("LockDevicePatched("+GetSlotedNPCName()+","+UD_GlobalDeviceMutex_Device.getName()+") failed!!! ID Fail? " + UD_GlobalDeviceMutex_InventoryScript_Failed)
    endif
    
    UD_GlobalDeviceMutex_Device = none
EndFunction

Function ProccesUnlockMutex()
    float loc_time = 0.0
    while loc_time <= 3.0 && (!UD_GlobalDeviceUnlockMutex_InventoryScript)
        Utility.waitMenuMode(0.1)
        loc_time += 0.1
    endwhile
    
    if UD_GlobalDeviceUnlockMutex_InventoryScript_Failed || loc_time >= 3.0
        UDCDmain.Error("UnLockDevicePatched("+GetSlotedNPCName()+","+UD_GlobalDeviceUnlockMutex_Device.getName()+") failed!!! ID Fail? " + UD_GlobalDeviceUnlockMutex_InventoryScript_Failed)
    endif
    
    UD_GlobalDeviceUnlockMutex_Device = none
EndFunction

;===============================================================================
;===============================================================================
;                             AROUSAL/ORGASM UPDATE
;===============================================================================
;===============================================================================

;Arousal update
Function InitArousalUpdate()
    GetActor().AddToFaction(UDOM.ArousalCheckLoopFaction)
EndFunction

Function UpdateArousal(Int aiUpdateTime)
    Actor   loc_actor = GetActor()
    Float   loc_arousalRate = UDOM.getArousalRateM(loc_actor)
    Int     loc_arousal     = Round(loc_arousalRate)*aiUpdateTime
    
    if loc_arousal != 0
        loc_actor.SetFactionRank(UDOM.ArousalCheckLoopFaction,UDOM.UpdateArousal(loc_actor ,loc_arousal))
    else
        loc_actor.SetFactionRank(UDOM.ArousalCheckLoopFaction,UDOM.getActorArousal(loc_actor))
    endif
EndFunction

Function CleanArousalUpdate()
    GetActor().RemoveFromFaction(UDOM.ArousalCheckLoopFaction)
EndFunction

;Orgasm update
float   _currentUpdateTime       = 1.0
bool    _widgetShown             = false
bool    _forceStop               = false
bool    _actorinminigame         = false
float   _forcing                 = 0.0
float   _orgasmRate              = 0.0
float   _orgasmRate2             = 0.0
float   _orgasmRateAnti          = 0.0
float   _orgasmResistMultiplier  = 1.0
float   _orgasmRateMultiplier    = 1.0
int     _arousal                 = 0
int     _tick                    = 1
int     _tickS                   = 0
int     _expressionUpdateTimer   = 0
bool    _orgasmResisting         = false
bool    _orgasmResisting2        = false
bool    _expressionApplied       = false
float   _orgasmCapacity          = 100.0
float   _orgasmResistence        = 2.5
float   _orgasmProgress          = 0.0
float   _orgasmProgress2         = 0.0
float   _orgasmProgress_p        = 0.0
int     _orgasms                 = 0
int     _hornyAnimTimer          = 0
bool[]  _cameraState
int     _msID                    = -1
float   _edgeprogress            = 0.0
int     _edgelevel               = 0

sslBaseExpression expression
float[] _org_expression
float[] _org_expression2
float[] _org_expression3

Function InitOrgasmUpdate()
    Actor loc_actor = GetActor()
    if loc_actor
        loc_actor.AddToFaction(UDOM.OrgasmCheckLoopFaction)
        _org_expression             = UDEM.GetPrebuildExpression_Horny1()
        _org_expression2            = UDEM.GetPrebuildExpression_Happy1()
        _org_expression3            = UDEM.GetPrebuildExpression_Angry1()
        _widgetShown                = false
        _forceStop                  = false
        _orgasmRate                 = 0.0
        _orgasmRate2                = 0.0
        _orgasmRateAnti             = 0.0
        _orgasmResistMultiplier     = UDOM.getActorOrgasmResistMultiplier(loc_actor)
        _orgasmRateMultiplier       = UDOM.getActorOrgasmRateMultiplier(loc_actor)
        _arousal                    = UDOM.getArousal(loc_actor)
        _forcing                    = UDOM.getActorOrgasmForcing(loc_actor)
        _tick                       = 1
        _tickS                      = 0
        _expressionUpdateTimer      = 0
        _orgasmResisting            = loc_actor.isInFaction(UDOM.OrgasmResistFaction)
        _orgasmResisting2           = false
        _expressionApplied          = false
        _orgasmCapacity             = UDOM.getActorOrgasmCapacity(loc_actor)
        _orgasmResistence           = UDOM.getActorOrgasmResist(loc_actor)
        _orgasmProgress             = StorageUtil.GetFloatValue(loc_actor, "UD_OrgasmProgress",0.0)
        _orgasmProgress2            = 0.0
        _orgasmProgress_p           = _orgasmProgress/_orgasmCapacity
        _hornyAnimTimer             = 0
        _msID                       = -1
        _orgasms                    = 0
        _actorinminigame            = UDCDMain.actorInMinigame(loc_actor)
        _edgeprogress               = UDOM.GetHornyProgress(loc_actor)
        _edgelevel                  = UDOM.GetHornyLevel(loc_actor)
    endif
EndFunction

Function UpdateOrgasm(Float afUpdateTime)
    if !UDmain.IsEnabled()
        return
    endif
    Actor akActor = GetActor()
    CalculateOrgasmProgress()
    ;check orgasm
    if _orgasmProgress_p > 0.99
        if UDmain.TraceAllowed()
            UDCDmain.Log("Starting orgasm for " + getActorName(akActor))
        endif
        if _orgasmResisting
            akActor.RemoveFromFaction(UDOM.OrgasmResistFaction)
        endif
        
        if _widgetShown
            _widgetShown = false
            UDmain.UDWC.Toggle_OrgasmWidget(false)
            UDmain.UDWC.UpdatePercent_OrgasmWidget(0.0,true)
        endif
        
        _hornyAnimTimer  = -45 ;cooldown
        
        Int _force = 0
        if _forcing < 0.5
            _force = 0
        elseif _forcing < 1.0
            _force = 1
        else
            _force = 2
        endif
        
        SendOrgasmEvent()
        UDOM.startOrgasm(akActor,UDOM.UD_OrgasmDuration,UDOM.UD_OrgasmArousalReduce,_force,true)
        
        ;Utility.wait(0.25) ;wait, so orgasm variables can be updated
        
        _orgasmProgress = 0.0
        UDOM.SetActorOrgasmProgress(akActor,_orgasmProgress)
    else
        ;check edge
        if _edgeprogress >= 3.0*_orgasmCapacity
            _edgelevel       = UDOM.UpdateHornyLevel(akActor,1) ;increase edge level by 1
            _edgeprogress    = 0.0
            UDOM.SetHornyProgress(akActor,0.0)
            if IsPlayer()
                if _edgelevel == 1
                    UDmain.Print("You feel incredibly horny")
                elseif _edgelevel == 2
                    UDmain.Print("You want to cum")
                elseif _edgelevel == 3
                    UDmain.Print("You want to cum badly")
                elseif _edgelevel == 4
                    UDmain.Print("You would do anything for orgasm")
                elseif _edgelevel > 4
                    UDmain.Print("Unending pleasure is driving you crazy!")
                endif
            endif
            SendEdgeEvent()
        elseif _edgelevel > 0 && _edgeprogress <= _orgasmCapacity/3.0
            _edgelevel       = UDOM.UpdateHornyLevel(akActor,-1) ;decrease edge level by 1
            _edgeprogress    = 0.0
            UDOM.SetHornyProgress(akActor,0.0)
        endif
    endif
    
    if _tick * afUpdateTime >= 1.0
        UpdateOrgasmSecond()
    endif
    _tick += 1
EndFunction

Function CalculateOrgasmProgress()
    Actor akActor = GetActor()
    _orgasmProgress2 = _orgasmProgress
    _orgasmResisting = akActor.isInFaction(UDOM.OrgasmResistFaction)
    if _orgasmResisting
        _orgasmResisting2    = true
        _orgasmProgress      = UDOM.getActorOrgasmProgress(akActor)
    else
        if _orgasmResisting2
            _orgasmResisting2            = false
            _arousal                     = UDOM.getArousal(akActor)
            _orgasmRate                  = UDOM.getActorOrgasmRate(akActor)
            _orgasmRateMultiplier        = UDOM.getActorOrgasmRateMultiplier(akActor)
            _orgasmResistMultiplier      = UDOM.getActorOrgasmResistMultiplier(akActor)
            _orgasms                     = UDOM.getOrgasmingCount(akActor)
            _actorinminigame             = UDCDMain.actorInMinigame(akActor)
            UDOM.SetActorOrgasmProgress(akActor,_orgasmProgress)
        endif
        _orgasmProgress += _orgasmRate*_orgasmRateMultiplier*_currentUpdateTime
    endif
    
    _orgasmRateAnti = UDOM.CulculateAntiOrgasmRateMultiplier(_arousal)*_orgasmResistMultiplier*(_orgasmProgress*(_orgasmResistence/100.0))*_currentUpdateTime  ;edging, orgasm rate needs to be bigger then UD_OrgasmResistence, else actor will not reach orgasm
    
    if !_orgasmResisting
        if _orgasmRate*_orgasmRateMultiplier > 0.0
            _orgasmProgress -= _orgasmRateAnti
        else
            _orgasmProgress -= 3*_orgasmRateAnti
        endif
    endif
    
    ;proccess edge
    _edgeprogress = UDOM.UpdateHornyProgress(akActor, fUnsig((_orgasmRate*_orgasmRateMultiplier - _orgasmRateAnti)*_currentUpdateTime))
    _edgelevel    = UDOM.GetHornyLevel(akActor)
    
    _orgasmProgress_p = fRange(_orgasmProgress/_orgasmCapacity,0.0,1.0) ;update relative orgasm progress
    
    if _widgetShown && !_orgasmResisting
        UDmain.UDWC.UpdatePercent_OrgasmWidget(_orgasmProgress_p)
    endif
EndFunction

Function UpdateOrgasmSecond()
    Actor akActor = GetActor()
    Bool  loc_is3dLoaded = IsPlayer() || akActor.Is3DLoaded()
    
    _orgasmRate2 = _orgasmRate
    _tick = 0
    _tickS += 1
    if _edgelevel > 0
        _edgeprogress = UDOM.UpdateHornyProgress(akActor,-1.0*(100.0 - _arousal)/100.0)
    elseif _edgelevel < 0
        _edgeprogress = UDOM.UpdateHornyProgress(akActor,1.0*(100.0 - _arousal)/100.0)
    endif
    int _switch = (_tickS % 3)
    if _switch == 0
        _orgasmCapacity              = UDOM.getActorOrgasmCapacity(akActor)
    elseif _switch == 1
        _orgasmResistence            = UDOM.getActorOrgasmResist(akActor)
    else
        _forcing                     = UDOM.getActorOrgasmForcing(akActor)
    endif
    
    if !_orgasmResisting
        _arousal                 = UDOM.getArousal(akActor)
        _orgasmRate              = UDOM.getActorOrgasmRate(akActor)
        _orgasmRateMultiplier    = UDOM.getActorOrgasmRateMultiplier(akActor)
        _orgasmResistMultiplier  = UDOM.getActorOrgasmResistMultiplier(akActor)
        _orgasms                 = UDOM.getOrgasmingCount(akActor)
        _actorinminigame         = UDCDMain.actorInMinigame(akActor)
        UDOM.SetActorOrgasmProgress(akActor,_orgasmProgress)
    endif
    
    if loc_is3dLoaded
        UpdateOrgasmExpression()
        
        if (_orgasmRate > 0.5*_orgasmResistMultiplier*_orgasmResistence) 
            ;start moaning sound again. Not play when actor orgasms
            if _msID == -1 && !_orgasms && !_actorinminigame
                _msID = libs.MoanSound.Play(akActor)
                Sound.SetInstanceVolume(_msID, fRange(_orgasmProgress_p*2.0,0.75,1.0)*libs.GetMoanVolume(akActor,_arousal))
            endif
        else
            ;disable moaning sound when orgasm rate is too low
            if _msID != -1
                Sound.StopInstance(_msID)
                _msID = -1
            endif
        endif
        
        ;can play horny animation ?
        UpdateOrgasmHornyAnimation()
        
        if UDOM.UD_UseOrgasmWidget && IsPlayer()
            if (_widgetShown && _orgasmProgress < 2.5) ;|| (loc_widgetShown)
                UDmain.UDWC.Toggle_OrgasmWidget(false)
                _widgetShown = false
            elseif !_widgetShown && _orgasmProgress >= 2.5
                UDmain.UDWC.UpdatePercent_OrgasmWidget(_orgasmProgress_p,true)
                UDmain.UDWC.Toggle_OrgasmWidget(true)
                _widgetShown = true
            endif
        endif
    endif
    
    if _orgasmProgress < 0.0
        _orgasmProgress = 0.0
    endif
    
    if _tickS % 15
        ;Update
    endif
EndFunction

Function UpdateOrgasmExpression()
    Actor akActor = GetActor()
    ;expression
    if _orgasmRate >= _orgasmResistence*0.75 && (!_expressionApplied || _expressionUpdateTimer > 5) 
        ;init expression
        if _edgelevel == 0
            UDEM.ApplyExpressionRaw(akActor, _org_expression, iRange(Round(_orgasmProgress),75,100),false,10)
        elseif _edgelevel > 0 && _edgelevel < 3
            UDEM.ApplyExpressionRaw(akActor, _org_expression2, 75,false,10)
        else
            UDEM.ApplyExpressionRaw(akActor, _org_expression3, 50,false,10)
        endif
        
        _expressionApplied = true
        _expressionUpdateTimer = 0
    elseif _orgasmRate < _orgasmResistence*0.75 && _expressionApplied
        UDEM.ResetExpressionRaw(akActor,10)
        _expressionApplied = false
    endif
    _expressionUpdateTimer += 1
EndFunction

FUnction UpdateOrgasmHornyAnimation()
    Actor akActor = GetActor()
    if !_actorinminigame
        if (_orgasmRate > 0.5*_orgasmResistMultiplier*_orgasmResistence) && !_orgasmResisting && !akActor.IsInCombat() ;orgasm progress is increasing
            if (_hornyAnimTimer == 0) && !libs.IsAnimating(akActor) && UDOM.UD_HornyAnimation ;start horny animation for UD_HornyAnimationDuration
                if Utility.RandomInt() <= (Math.ceiling(100/fRange(_orgasmProgress,15.0,100.0))) 
                    ; Select animation
                    _cameraState = libs.StartThirdPersonAnimation(akActor, libs.AnimSwitchKeyword(akActor, "Horny01"), permitRestrictive=true)
                    _hornyAnimTimer += UDOM.UD_HornyAnimationDuration
                endif
            EndIf
        endif
        
        if !_orgasmResisting
            if _hornyAnimTimer > 0 ;reduce horny animation timer 
                _hornyAnimTimer -= 1
                if (_hornyAnimTimer == 0)
                    libs.EndThirdPersonAnimation(akActor, _cameraState, permitRestrictive=true)
                    _hornyAnimTimer = -20 ;cooldown
                EndIf
            elseif _hornyAnimTimer < 0 ;cooldown
                _hornyAnimTimer += 1
            endif
        endif
    endif
EndFunction

;Event UDOrgasm(Form akActor,Float afOrgasmRate,Int aiArousal,Int aiEdgeLevel,Float afForcing)
Function SendOrgasmEvent()
    int loc_id = ModEvent.Create("UDOrgasmEvent")
    if loc_id
        ModEvent.PushForm(loc_id, GetActor())
        ModEvent.PushFloat(loc_id, _orgasmRate)
        ModEvent.PushInt(loc_id, _arousal)
        ModEvent.PushInt(loc_id, _edgelevel)
        ModEvent.PushFloat(loc_id, _forcing)
        ModEvent.Send(loc_id)
    endif
    Int loc_handle = ModEvent.Create("DeviceActorOrgasmExp")
    if loc_handle
        ModEvent.PushForm(loc_handle, UDOM)         ;Event source (zadlibs), in case that some other mode might call this function from different place
        ModEvent.PushForm(loc_handle, GetActor())      ;Actor
        ModEvent.PushInt(loc_handle, _arousal)   ;Arousal after orgasm
        ModEvent.Send(loc_handle)
    endif
EndFunction

Function SendEdgeEvent()
    int loc_id = ModEvent.Create("UDEdgeEvent")
    if loc_id
        ModEvent.PushForm(loc_id, GetActor())
        ModEvent.PushFloat(loc_id, _orgasmRate)
        ModEvent.PushInt(loc_id,    _arousal)
        ModEvent.PushInt(loc_id, _edgelevel)
        ModEvent.PushFloat(loc_id, _forcing)
        ModEvent.Send(loc_id)
    endif
    Int loc_handle = ModEvent.Create("DeviceActorEdgeExp")
    if loc_handle
        ModEvent.PushForm(loc_handle, UDOM)         ;Event source (zadlibs), in case that some other mode might call this function from different place
        ModEvent.PushForm(loc_handle, GetActor())      ;Actor
        ModEvent.Send(loc_handle)
    endif
EndFunction

Function CleanOrgasmUpdate()
    Actor akActor = GetActor()
    ;stop moan sound
    if _msID != -1
        Sound.StopInstance(_msID)
    endif
    
    ;end animation if it still exist
    if  _hornyAnimTimer > 0
        libs.EndThirdPersonAnimation(akActor, _cameraState, permitRestrictive=true)
        _hornyAnimTimer = 0
    EndIf
    
    ;hide widget
    if _widgetShown
        UDmain.UDWC.Toggle_OrgasmWidget(false)
    endif
    
    ;reset expression
    UDEM.ResetExpressionRaw(akActor, 10)
    
    ;end mutex
    akActor.RemoveFromFaction(UDOM.OrgasmCheckLoopFaction)
EndFunction