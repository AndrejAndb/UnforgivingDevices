Scriptname zadlibs_UDPatch extends zadlibs

import MfgConsoleFunc
import sslBaseExpression
import UnforgivingDevicesMain

UDCustomDeviceMain Property UDCDmain auto
UnforgivingDevicesMain Property UDmain
    UnforgivingDevicesMain Function get()
        return UDCDMain.UDmain
    EndFunction
EndProperty
UD_MutexManagerScript Property UDMM
    UD_MutexManagerScript Function get()
        return UDmain.UDMM
    EndFunction
EndProperty
UD_Libs Property UDlibs
    UD_Libs Function get()
        return UDmain.UDlibs
    EndFunction
EndProperty
UD_OrgasmManager Property UDOM
    UD_OrgasmManager Function get()
        return UDmain.UDOM
    EndFunction
EndProperty

bool Property UD_StartThirdPersonAnimation_Switch = true auto

Function LockDevice_Paralel(actor akActor, armor deviceInventory, bool force = false)
    UDCDmain.LockDeviceParalel(akActor,deviceInventory,force)
EndFunction

Bool Function LockDevice(actor akActor, armor deviceInventory, bool force = false)
    if UDmain.TraceAllowed()    
        UDmain.Log("LockDevice("+MakeDeviceHeader(akActor,deviceInventory)+")",3)
    endif
    if UDCDmain.UDmain.UD_zadlibs_ParalelProccesing
        LockDevice_Paralel(akActor, deviceInventory, force)
        return true
    else
        return LockDevicePatched(akActor, deviceInventory, force)
    endif
EndFunction

bool Function isMutexed(Actor akActor,Armor invDevice)
    return UDMM.IsDeviceMutexed(akActor,invDevice)
EndFunction

bool Property DD_LockDeviceBlocking = true auto
UD_CustomDevice_NPCSlot _lastLockSlot  = none
UD_MutexScript          _lastLockMutex = none
Bool Function LockDevicePatched(actor akActor, armor deviceInventory, bool force = false)
    if !deviceInventory
        UDmain.Warning("LockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - none passed as deviceInventory")
        return false
    endif
    if !akActor
        UDmain.Warning("LockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - none passed as akActor")
        return false
    endif
    if !deviceInventory.haskeyword(zad_inventoryDevice)
        UDmain.Warning("LockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - passed armor is not devious device. Aborting!")
        return false
    endif
    if !UDmain.ActorIsValidForUD(akActor)
        UDmain.Warning("LockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") is not valid actor or dead! Aborting")
        return false
    endif
    
    if !UDmain.ActorIsPlayer(akActor)
        StorageUtil.AdjustIntValue(akActor,"UDLockOperations",1) ;increase number of lock operations for NPC. Is used by NPC manager before NPC is register with auto scan
    endif
    
    bool loc_res = false
    if deviceInventory.hasKeyword(UDlibs.PatchedInventoryDevice)
        UDmain.UDNPCM.GotoState("UpdatePaused")
        
        UD_CustomDevice_NPCSlot loc_slot = none
        ;if _lastLockSlot && (_lastLockSlot.GetActor() == akActor)
        ;    loc_slot = _lastLockSlot
        ;else
            loc_slot = UDCDmain.getNPCSlot(akActor)
        ;endif
        UD_MutexScript          loc_mutex = none
        
        if loc_slot
            loc_slot.StartLockMutex()
        else
            ;if _lastLockMutex && (_lastLockMutex.GetActor() == akActor) && !_lastLockMutex.IsLockMutexed()
            ;    loc_mutex = _lastLockMutex
            ;else
                loc_mutex = UDMM.WaitForFreeAndSet_Lock(akActor,deviceInventory)
            ;endif
        endif
        
        ;_lastLockSlot  = loc_slot
        ;_lastLockMutex = loc_mutex
        
        if UDmain.TraceAllowed()
            if loc_slot
                UDmain.Log("LockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - operation started - NPC slot: " + loc_slot,1)
            elseif loc_mutex
                UDmain.Log("LockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - operation started - mutex: " + loc_mutex,1)
            else
                UDmain.Log("LockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - operation started - no mutex",1)
            endif
        endif
        
        if loc_slot
            loc_slot.ResetMutex_Lock(deviceInventory)
        elseif loc_mutex
            ;ResetLockMutex(akActor,deviceInventory)
        endif

        zad_AlwaysSilent.addForm(akActor)
        
        ;taken from zadlibs, only removed Log function call
        If force
            Keyword kw = GetDeviceKeyword(deviceInventory)
            if kw
                loc_res = SwapDevicesPatched(akActor, deviceInventory, zad_DeviousDevice = kw,abUseLockFunction = false) ;don't use lock function, as that would block whole system
            else
                loc_res = false
            endif
        else
            if !akActor.GetItemCount(deviceInventory)
                akActor.AddItem(deviceInventory, 1, true)
            EndIf

            akActor.EquipItemEx(deviceInventory, 0, false, true)
            loc_res = true
        endif
        
        if loc_slot
            loc_slot.ProccesLockMutex()
        elseif loc_mutex
            loc_mutex.EvaluateLockMutex()
        endif
        
        zad_AlwaysSilent.RemoveAddedForm(akActor)
        
        if UDmain.TraceAllowed()
            if loc_slot
                UDmain.Log("LockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - operation completed - NPC slot: " + loc_slot,1)
            elseif loc_mutex
                UDmain.Log("LockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - operation completed - mutex: " + loc_mutex,1)
            else
                UDmain.Log("LockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - operation completed - no mutex",1)
            endif
        endif
        
        if loc_slot
            loc_slot.EndLockMutex()
        elseif loc_mutex
            loc_mutex.ResetLockMutex()
        endif
    else
        if UDmain.TraceAllowed()
            UDmain.Log("LockDevicePatched("+getActorName(akActor)+","+deviceInventory.getName()+") (patched) called, device is NOT UD -> skipping mutex")
        endif
        
        loc_res = parent.LockDevice(akActor,deviceInventory,force)
        
        ;make function blocking
        ;pretty much added just so DCL can work properly when equipping more device at once
        if DD_LockDeviceBlocking
            Armor deviceRendered = GetRenderedDevice(deviceInventory)
            float loc_time = 0.0
            while loc_time <= 1.5 && !UDCDmain.CheckRenderDeviceEquipped(akActor, deviceRendered)
                Utility.waitMenuMode(0.1)
                loc_time += 0.1
            endwhile
            if loc_time >= 1.5
                ;render device lock failed, abort
                UDmain.Error("LockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") DD mutex failed. Render device is not equipped - timeout")
            endif
        endif
    endif
    
    if UDmain.TraceAllowed()
        UDmain.Log("LockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - ended",3)
    endif
    
    UDmain.UDNPCM.GotoState("")
    if !UDmain.ActorIsPlayer(akActor)
        StorageUtil.AdjustIntValue(akActor,"UDLockOperations",-1) ;decrease number of lock operations for NPC. Is used by NPC manager before NPC is register with auto scan
    endif
    return loc_res
EndFunction

Bool Function SwapDevices(actor akActor, armor deviceInventory, keyword zad_DeviousDevice = none, bool destroyDevice = false, bool genericonly = true)
    return SwapDevicesPatched(akActor, deviceInventory, zad_DeviousDevice, destroyDevice, genericonly)
EndFunction

Bool Function SwapDevicesPatched(actor akActor, armor deviceInventory, keyword zad_DeviousDevice = none, bool destroyDevice = false, bool genericonly = true,bool abUseLockFunction = true)
    Keyword loc_keyword
    if !zad_DeviousDevice
        loc_keyword = GetDeviceKeyword(deviceInventory)
    else
        loc_keyword = zad_DeviousDevice
    EndIf
    Armor WornDevice = GetWornRenderedDeviceByKeyword(akActor, loc_keyword)
    if WornDevice
        Armor idevice = GetWornDevice(akActor, loc_keyword)
        if !UnlockDevice(akActor, idevice, WornDevice, zad_DeviousDevice = loc_keyword, destroyDevice = destroyDevice, genericonly = genericonly)
            GError("UnlockDevice() failed for "+ deviceInventory.getName() +". Aborting.")
            return false
        EndIf
    Else
        log("No confilicting device worn. Proceeding.")
    EndIf
    if abUseLockFunction
        LockDevicePatched(akActor,deviceInventory)
    else
        if akActor.GetItemCount(deviceInventory) <= 0
            akActor.AddItem(deviceInventory, 1, true)
        EndIf
        akActor.EquipItemEx(deviceInventory, 0, false, true)
    endif

    return true
EndFunction

Bool Function UnlockDevice(actor akActor, armor deviceInventory, armor deviceRendered = none, keyword zad_DeviousDevice = none, bool destroyDevice = false, bool genericonly = false)
    if !akActor
        UDmain.Warning("UnlockDevice called for none actor!")
        return false
    endif
    if !deviceInventory
        UDmain.Warning("None passed to UnlockDevice as deviceInventory. Aborting!")
        return false
    endif
    if !deviceInventory.haskeyword(zad_inventoryDevice)
        UDmain.Warning("UnlockDevice("+MakeDeviceHeader(akActor,deviceInventory)+") - passed deviceInventory is not devious device. Aborting!")
        return false
    endif
    if deviceRendered
        if !deviceRendered.haskeyword(zad_lockable) && !deviceRendered.haskeyword(zad_DeviousPlug)
            UDmain.Warning("UnlockDevice("+MakeDeviceHeader(akActor,deviceInventory)+") - passed deviceRendered("+deviceRendered+") is not devious device. Aborting!")
            deviceRendered = none
        endif
    endif
    
    if !UDmain.ActorIsPlayer(akActor)
        StorageUtil.AdjustIntValue(akActor,"UDLockOperations",1) ;increase number of lock operations for NPC. Is used by NPC manager before NPC is register with auto scan
    endif
    
    bool                    loc_res     = False ;return value
    
    if UDmain.TraceAllowed()
        UDmain.Log("UnlockDevice("+akActor+","+deviceInventory+","+deviceRendered+","+zad_DeviousDevice+","+destroyDevice+","+genericonly+")",1)
    endif
    
    if deviceInventory.hasKeyword(UDCDmain.UDlibs.PatchedInventoryDevice)
        UDmain.UDNPCM.GotoState("UpdatePaused")
        UD_CustomDevice_NPCSlot loc_slot    = none ;NPC slot for registered NPC
        UD_MutexScript          loc_mutex   = none ;mutex used for non registered NPC
        ;start mutex if actor is not dead
        bool loc_actordead = akActor.isDead()
        if !loc_actordead
            loc_slot = UDCDmain.getNPCSlot(akActor)
            if loc_slot
                loc_slot.StartUnlockMutex()
            else
                loc_mutex = UDMM.WaitForFreeAndSet_Unlock(akActor,deviceInventory)
            endif
        endif
        
        if UDmain.TraceAllowed()
            UDmain.Log("UnlockDevice("+MakeDeviceHeader(akActor,deviceInventory)+") called",2)
        endif
        If (genericonly && deviceInventory.HasKeyWord(zad_BlockGeneric)) || deviceInventory.HasKeyWord(zad_QuestItem)
            UDmain.Error("UnlockDevice("+MakeDeviceHeader(akActor,deviceInventory)+") aborted because device is not a generic item.")
            loc_res = false
        else
            Armor loc_renDevice = none
            
            ;get render device, this is important as function will not work without RD
            if deviceRendered
                loc_renDevice = deviceRendered
            else
                loc_renDevice = UDCDmain.getStoredRenderDevice(deviceInventory)
                if loc_renDevice
                    loc_renDevice = GetRenderedDevice(deviceInventory)
                endif
            endif
            
            ;check if actor actually have render device. Without RD, unlock function will not work
            if akActor.getItemCount(loc_renDevice)
                if loc_slot
                    loc_slot.ResetMutex_UnLock(deviceInventory) ;init slot mutex
                elseif loc_mutex
                    ;is already set by WaitForFreeAndSet_Unlock
                endif
                
                if UDmain.TraceAllowed()    
                    if loc_slot
                        UDmain.Log("UnlockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - operation started - NPC slot: " + loc_slot,1)
                    elseif loc_mutex    
                        UDmain.Log("UnlockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - operation started - mutex: " + loc_mutex,1)
                    else
                        UDmain.Log("UnlockDevicePatched("+MakeDeviceHeader(akActor,deviceInventory)+") - operation started - no mutex",1)
                    endif
                endif
                
                ;ignore ID events to prevent unwanted behavier
                StorageUtil.SetIntValue(akActor, "UD_ignoreEvent" + deviceInventory, 0x110)
                
                Int loc_idcount = akActor.getItemCount(deviceInventory)
                
                ;send and receive device from event container, so inside unlock function can be called
                akActor.removeItem(deviceInventory,loc_idcount,True,UDCDmain.EventContainer_ObjRef)
                UDCDmain.EventContainer_ObjRef.removeItem(deviceInventory,loc_idcount,True,akActor)

                ;procces mutex untill device is unlocked
                if loc_slot
                    loc_slot.ProccesUnLockMutex()
                elseif loc_mutex
                    loc_mutex.EvaluateUnLockMutex()
                endif
                
                ;remove inventory device if its detroy on remove
                if destroyDevice
                    akActor.RemoveItem(deviceInventory, 1, true)
                EndIf
                
                loc_res = true          ;succes
            else
                loc_res = false         ;failure
            endif
        endif
        
        ;end mutex
        if loc_slot
            loc_slot.EndUnLockMutex()
        elseif loc_mutex
            loc_mutex.ResetUnLockMutex()
        endif
    else
        ;use default DD unlock function
        loc_res = parent.UnlockDevice(akActor, deviceInventory, deviceRendered, zad_DeviousDevice, destroyDevice, genericonly) ;actor not registered
    endif
    if UDmain.TraceAllowed()        
        UDmain.Log("UnlockDevice("+deviceInventory.getName()+") (patched) finished: "+loc_res,1)
    endif
    UDmain.UDNPCM.GotoState("")
    if !UDmain.ActorIsPlayer(akActor)
        StorageUtil.AdjustIntValue(akActor,"UDLockOperations",-1) ;decrease number of lock operations for NPC. Is used by NPC manager before NPC is register with auto scan
    endif
    return loc_res
EndFunction

;modified version of RemoveQuestDevice from zadlibs. This version makes use of registered devices from UD,making unequip procces for NPC safer and faster
Function RemoveQuestDevice(actor akActor, armor deviceInventory, armor deviceRendered, keyword zad_DeviousDevice, keyword RemovalToken, bool destroyDevice=false, bool skipMutex=false)
    If !deviceInventory.HasKeyword(zad_QuestItem) && !deviceRendered.HasKeyword(zad_QuestItem)
        UDmain.Warning("RemoveQuestDevice("+getActorName(akActor)+") aborted for " + deviceInventory.GetName() + " because it's not a quest item.")
        return
    EndIf
    If (!RemovalToken || zadStandardKeywords.HasForm(RemovalToken) || !(deviceInventory.HasKeyword(RemovalToken) || deviceRendered.HasKeyword(RemovalToken)))
        UDmain.Warning("RemoveQuestDevice("+getActorName(akActor)+") called for " + deviceInventory.GetName() + " with invalid removal token. Aborted.")
        return
    EndIf    
    if !deviceInventory.haskeyword(zad_inventoryDevice)
        UDmain.Warning("UnlockDevice("+MakeDeviceHeader(akActor,deviceInventory)+") - passed deviceInventory is not devious device. Aborting!")
        return
    endif
    if deviceRendered
        if !deviceRendered.haskeyword(zad_lockable) && !deviceRendered.haskeyword(zad_DeviousPlug)
            UDmain.Warning("UnlockDevice("+MakeDeviceHeader(akActor,deviceInventory)+") - passed deviceRendered("+deviceRendered+") is not devious device. Aborting!")
            deviceRendered = none
        endif
    endif
    
    if UDmain.TraceAllowed()
        UDmain.Log("RemoveQuestDevice("+getActorName(akActor)+") called for " + deviceInventory.GetName(),1)
    endif
    
    UD_CustomDevice_NPCSlot     loc_slot        = none ;NPC slot for registered NPC
    UD_MutexScript              loc_mutex       = none ;mutex used for non registered NPC
    
    if !UDmain.ActorIsPlayer(akActor)
        StorageUtil.AdjustIntValue(akActor,"UDLockOperations",1) ;increase number of lock operations for NPC. Is used by NPC manager before NPC is register with auto scan
    endif
    
    ;start mutex if actor is not dead
    bool loc_actordead = akActor.isDead()
    if !loc_actordead
        loc_slot = UDCDmain.getNPCSlot(akActor)
        if loc_slot
            loc_slot.StartUnlockMutex()
        else
            loc_mutex = UDMM.WaitForFreeAndSet_Unlock(akActor,deviceInventory)
        endif
    endif
    
    if deviceInventory.hasKeyword(UDCDmain.UDlibs.PatchedInventoryDevice)    
        Armor loc_renDevice = none
        
        ;get render device, this is important as function will not work without RD
        if deviceRendered
            loc_renDevice = deviceRendered
        else
            loc_renDevice = UDCDmain.getStoredRenderDevice(deviceInventory)
            if loc_renDevice
                loc_renDevice = GetRenderedDevice(deviceInventory)
            endif
        endif
    
        if akActor.getItemCount(loc_renDevice)
            ;questItemRemovalAuthorizationToken = RemovalToken
            
            if loc_slot
                loc_slot.ResetMutex_UnLock(deviceInventory) ;init slot mutex
                loc_slot.UD_UnlockToken     = RemovalToken
            elseif loc_mutex
                loc_mutex.UD_UnlockToken     = RemovalToken
                ;is already set by WaitForFreeAndSet_Unlock
            endif
            
            if UDmain.TraceAllowed()    
                if loc_slot
                    UDmain.Log("RemoveQuestDevice("+MakeDeviceHeader(akActor,deviceInventory)+") - operation started - NPC slot: " + loc_slot,1)
                elseif loc_mutex    
                    UDmain.Log("RemoveQuestDevice("+MakeDeviceHeader(akActor,deviceInventory)+") - operation started - mutex: " + loc_mutex,1)
                else
                    UDmain.Log("RemoveQuestDevice("+MakeDeviceHeader(akActor,deviceInventory)+") - operation started - no mutex",1)
                endif
            endif
            
            StorageUtil.SetIntValue(akActor, "UD_ignoreEvent" + deviceInventory, 0x110)
            
            akActor.removeItem(deviceInventory,1,True,UDCDmain.EventContainer_ObjRef)    
            UDCDmain.EventContainer_ObjRef.removeItem(deviceInventory,1,True,akActor)    
            
            ;procces mutex untill device is unlocked
            if loc_slot
                loc_slot.ProccesUnLockMutex()
            elseif loc_mutex
                loc_mutex.EvaluateUnLockMutex()
            endif
            
            if destroyDevice
                akActor.RemoveItem(deviceInventory, 1, true)
            EndIf
        else    
                
        endif        
    else
        parent.RemoveQuestDevice(akActor, deviceInventory, deviceRendered, zad_DeviousDevice, RemovalToken, destroyDevice, skipMutex) ;actor not registered
    endif
    ;end mutex
    if loc_slot
        loc_slot.EndUnLockMutex()
    elseif loc_mutex
        loc_mutex.ResetUnLockMutex()
    endif
    if !UDmain.ActorIsPlayer(akActor)
        StorageUtil.AdjustIntValue(akActor,"UDLockOperations",-1) ;decrease number of lock operations for NPC. Is used by NPC manager before NPC is register with auto scan
    endif
EndFunction

;updated with additional safety
Bool Function UnlockDeviceByKeyword(actor akActor, keyword zad_DeviousDevice, bool destroyDevice = false)
    if !akActor
        UDmain.Error("UnlockDeviceByKeyword - Actor is none")
        return false
    endif
    
    if !zad_DeviousDevice
        UDmain.Error("UnlockDeviceByKeyword("+GetActorName(akActor)+") - keyword is none")
        return false
    endif
    
    if !akActor.wornHasKeyword(zad_DeviousDevice)
        if UDmain.TraceAllowed()
            UDmain.Log("UnlockDeviceByKeyword("+GetActorName(akActor)+")(UDP) - actor have mo keyword equipped= " + zad_DeviousDevice)
        endif
        return false
    endif
    
    if UDmain.TraceAllowed()
        UDmain.Log("UnlockDeviceByKeyword("+GetActorName(akActor)+")(UDP) called for " + zad_DeviousDevice)
    endif    
    
    Armor idevice = GetWornDevice(akActor, zad_DeviousDevice)
    
    if !idevice
        UDmain.Error("UnlockDeviceByKeyword("+GetActorName(akActor)+","+zad_DeviousDevice+") - returned idevice is none")
        return false
    endif
    
    if UnlockDevice(akActor, idevice, zad_DeviousDevice = zad_DeviousDevice, destroyDevice = destroyDevice, genericonly = true)
        return true
    EndIf
    return false
EndFunction

;updated version to make it work for straightjackets
Armor Function GetWornRenderedDeviceByKeyword(Actor akActor, Keyword kw)
    if UDmain.TraceAllowed()
        UDmain.Log("GetWornRenderedDeviceByKeyword("+akActor+","+kw+")",3)
    endif
    Int slotID = GetSlotMaskForDeviceType(kw)
    if slotID == -1
        return None
    EndIf

    if (kw == zad_deviousHeavyBondage) && akActor.wornHasKeyword(zad_DeviousStraitJacket)
        slotID = Armor.GetMaskForSlot(32)
    endif
    
    if UDmain.TraceAllowed()
        UDmain.Log("GetWornRenderedDeviceByKeyword("+akActor+","+kw+") - GetSlotMaskForDeviceType = " + slotID,3)
    endif
    
    Armor renderDevice = akActor.GetWornForm(slotID) As Armor
    
    if UDmain.TraceAllowed()
        UDmain.Log("GetWornRenderedDeviceByKeyword("+akActor+","+kw+") - renderDevice = " + renderDevice,3)
    endif
    
    if renderDevice && renderDevice.HasKeyWord(zad_Lockable)
        return renderDevice
    EndIf
    return none
EndFunction

Armor Function GetWornDevice(Actor akActor, Keyword kw)
    return GetWornDevicePatched(akActor, kw)
EndFunction

Armor Function GetWornDevicePatched(Actor akActor, Keyword kw)
    if !akActor
        UDmain.Error("GetWornDevice - Actor is none")
        return none
    endif
    if !kw
        UDmain.Error("GetWornDevice("+GetActorName(akActor)+") - keyword is none")
        return none
    endif
    if !akActor.wornHasKeyword(kw)
        UDmain.Warning("GetWornDevice("+GetActorName(akActor)+") - actor have no keyword equipped= " + kw)
        return none
    endif
    if UDmain.TraceAllowed()
        UDmain.Log("GetWornDevice("+GetActorName(akActor)+","+kw+")",3)
    endif
    if UDmain.UDNPCM.isRegistered(akActor)
        UD_CustomDevice_NPCSlot slot = UDmain.UDNPCM.getNPCSlotByActor(akActor)
        if slot.deviceAlreadyRegisteredKw(kw,UDmain.UD_CheckAllKw)
            UD_CustomDevice_RenderScript loc_device = slot.getFirstDeviceByKeyword(kw)
            if loc_device
                Armor loc_id = loc_device.deviceInventory
                return loc_id
            endif
        endif
    endif
    
    Armor loc_result = none
    if UDmain.UD_UseNativeFunctions && akActor == playerRef
        Form[] loc_devices = UD_Native.GetInventoryDevices(akActor,true)
        int loc_i
        while loc_i
            loc_i -= 1
            zadEquipScript loc_tmpZRef = akActor.placeAtMe(loc_devices[loc_i], abInitiallyDisabled = true) as zadEquipScript
            if loc_tmpZRef
                Armor loc_deviceInventory   = loc_tmpZRef.deviceInventory
                Armor loc_deviceRendered    = loc_tmpZRef.deviceRendered
                Keyword loc_DeviceKeyword   = loc_tmpZRef.zad_DeviousDevice
                if akActor.GetItemCount(loc_deviceRendered) && (loc_DeviceKeyword == kw || (UDmain.UD_CheckAllKw && loc_deviceRendered.haskeyword(kw)))
                    loc_tmpZRef.delete()
                    return loc_deviceInventory
                endif
            endif
            if loc_tmpZRef
                loc_tmpZRef.delete()
            endif
        endwhile
    else
        Int loc_FormIndex = akActor.GetNumItems()
        While loc_FormIndex
            loc_FormIndex -= 1
            Form loc_Form = akActor.GetNthForm(loc_FormIndex)
            If loc_Form.HasKeyword(zad_InventoryDevice) && (akActor.IsEquipped(loc_Form) || akActor != playerRef)
                zadEquipScript loc_tmpZRef = akActor.placeAtMe(loc_Form, abInitiallyDisabled = true) as zadEquipScript
                if loc_tmpZRef
                    Armor loc_deviceInventory = loc_tmpZRef.deviceInventory
                    Armor loc_deviceRendered = loc_tmpZRef.deviceRendered
                    Keyword loc_DeviceKeyword = loc_tmpZRef.zad_DeviousDevice
                    if akActor.GetItemCount(loc_deviceRendered) && (loc_DeviceKeyword == kw || (UDmain.UD_CheckAllKw && loc_deviceRendered.haskeyword(kw)))
                        loc_tmpZRef.delete()
                        return loc_deviceInventory
                    endif
                endif
                if loc_tmpZRef
                    loc_tmpZRef.delete()
                endif
            EndIf
        EndWhile
    endif
    return none
EndFunction

;copied and modified libs InflateAnalPlug function to make it show correct msg for npcs
Function InflateAnalPlug(actor akActor, int amount = 1)    
    If !akActor.WornHasKeyword(zad_kw_InflatablePlugAnal)
        ; nothing to do
        return
    EndIf    
    int currentVal = 0
    If akActor == PlayerRef
        currentVal = zadInflatablePlugStateAnal.GetValueInt()
        ; only increase the value up to 5, but make it count as an inflation event even if it's maximum inflated
        if currentVal < 5            
            currentVal += amount
            if currentVal > 5
                currentVal = 5
            EndIf
            if UDmain.TraceAllowed()
                UDmain.Log("Setting anal plug inflation to " + (currentVal),1)
            endif
            zadInflatablePlugStateAnal.SetValueInt(currentVal)
        EndIf    
        LastInflationAdjustmentAnal = Utility.GetCurrentGameTime()
    else
        currentVal = iRange(amount,2,5)
    endif
    UDOM.UpdateBaseOrgasmVals(akActor,5,7.5*currentVal,0.5,3.5*currentVal)
    SendInflationEvent(akActor, False, True, currentval)
EndFunction

;copied and modified libs InflateAnalPlug function to make it show correct msg for npcs
Function InflateVaginalPlug(actor akActor, int amount = 1)    
    If !akActor.WornHasKeyword(zad_kw_InflatablePlugVaginal)
        ; nothing to do
        return
    EndIf
    int currentVal = 0
    If akActor == PlayerRef
        currentVal = zadInflatablePlugStateVaginal.GetValueInt()
        ; only increase the value up to 5, but make it count as an inflation event even if it's maximum inflated
        if currentVal < 5                        
            currentVal += amount
            if currentVal > 5
                currentVal = 5
            EndIf
            if UDmain.TraceAllowed()
                UDmain.Log("Setting vaginal plug inflation to " + (currentVal),1)
            endif
            zadInflatablePlugStateVaginal.SetValueInt(currentVal)
        EndIf    
        LastInflationAdjustmentVaginal = Utility.GetCurrentGameTime()
    else
        currentVal = iRange(amount,2,5)
    endif
    
    UDOM.UpdateBaseOrgasmVals(akActor,5,12.5*currentVal,0.5,5*currentVal)
    SendInflationEvent(akActor, True, True, currentval)
EndFunction

String Function AnimSwitchKeyword(actor akActor, string idleName)
    String[] anims
    If idleName == "Horny01" || idleName == "Horny02" || idleName == "Horny03"
        anims = UDmain.UDAM.GetHornyAnimEvents(akActor, False)
    ElseIf idleName == "Orgasm"
        anims = UDmain.UDAM.GetOrgasmAnimEvents(akActor, False)
    ElseIf idleName == "Edged"
        anims = UDmain.UDAM.GetEdgedAnimEvents(akActor, False)
    EndIf
    
    If anims.Length > 0
        Return anims[Utility.RandomInt(0, anims.Length - 1)]
    Else
        return parent.AnimSwitchKeyword(akActor, idleName)
    EndIf
EndFunction

; Stop vibration event on actor.
Function StopVibrating(actor akActor)
    if akActor.WornHasKeyword(UDlibs.UnforgivingDevice) && UDCDmain.isRegistered(akActor)
        if UDmain.TraceAllowed()
            UDmain.Log("StopVibrating("+GetActorName(akActor)+") - using patched version: " + akActor)
        endif
        UDCDmain.StopAllVibrators(akActor)
        akActor.SetFactionRank(zadVibratorFaction, 0)
        akActor.RemoveFromFaction(zadVibratorFaction)
    else
        if UDmain.TraceAllowed()
            UDmain.Log("StopVibrating("+GetActorName(akActor)+") - using default version: " + akActor)
        endif
        parent.StopVibrating(akActor)
    endif
EndFunction

int Function VibrateEffect(actor akActor, int vibStrength, int duration, bool teaseOnly=false, bool silent = false)
    if UDmain.TraceAllowed()    
        UDmain.Log("VibrateEffect(): " + akActor + ", " + vibStrength + ", " + duration)
    endif
    ;prevent too short vibs. Can cause issue with orgasm system
    if duration >= 0 && duration < 10
        duration = 10
    endif
    
    if akActor.WornHasKeyword(UDlibs.UnforgivingDevice) && UDCDmain.isRegistered(akActor)
        int loc_vibNum = UDCDmain.getActivableVibratorNum(akActor)
        if loc_vibNum > 0
            UD_CustomDevice_RenderScript[] loc_usableVibrators = UDCDmain.getActivableVibrators(akActor)
            UD_CustomVibratorBase_RenderScript loc_selectedVib = loc_usableVibrators[Utility.randomInt(0,loc_vibNum - 1)] as UD_CustomVibratorBase_RenderScript
            if UDmain.TraceAllowed()            
                UDmain.Log("VibrateEffect("+GetActorName(akActor)+") - selected vib:" + loc_selectedVib,1)
            endif
            if !loc_selectedVib.IsVibrating()
                loc_selectedVib.forceStrength(vibStrength*20)
                loc_selectedVib.forceDuration(duration)
                loc_selectedVib.forceEdgingMode(teaseOnly as Int)
                loc_selectedVib.vibrate()
            else
                loc_selectedVib.addVibDuration(duration)
            endif
            return 0
        else
            return parent.VibrateEffect(akActor, vibStrength, duration, teaseOnly, silent)
        endif
    else
        return parent.VibrateEffect(akActor, vibStrength, duration, teaseOnly, silent)
    endif
EndFunction

Function ShockActorPatched(actor akActor,int iArousalUpdate = 25,float fHealth = 0.0, bool bCanKill = false)
    bool loc_loaded = akActor.Is3DLoaded()
    if UDmain.ActorIsPlayer(akActor)
        NotifyPlayer("You squirms uncomfortably as electricity runs through your body!")
    Elseif UDmain.ActorIsFollower(akActor) && loc_loaded
        NotifyNPC(akActor.GetLeveledActorBase().GetName()+" squirms uncomfortably as electricity runs through her.")
    EndIf
    ShockEffect.RemoteCast(akActor, akActor, akActor)
    
    if loc_loaded
        if Utility.randomInt(1,99) < 40
            UDCDmain.ApplyTearsEffect(akActor)
        endif
    endif
    float loc_health = fRange(fHealth,0.0,1000.0)
    
    if loc_health
        if akActor.getAV("Health") > loc_health || bCanKill
            akActor.damageAV("Health", loc_health)
        endif
    endif
    if iArousalUpdate
        int loc_arousalUpdate = iRange(Utility.randomInt(Round(0.75*iArousalUpdate),Round(0.5*iArousalUpdate)),-100,100)
        Aroused.UpdateActorExposure(akActor, loc_arousalUpdate)
    endif
EndFunction

;copied with added trace check and block check
bool[] Function StartThirdPersonAnimation(actor akActor, string animation, bool permitRestrictive=false)
    if UD_StartThirdPersonAnimation_Switch
        UDMain.UDAM.StartSoloAnimation(akActor, animation)
        return new Bool[2]
    else
        return parent.StartThirdPersonAnimation(akActor, animation, permitRestrictive)
    endif
EndFunction

;copied with added trace check and block check
Function EndThirdPersonAnimation(actor akActor, bool[] cameraState, bool permitRestrictive=false)
    if UD_StartThirdPersonAnimation_Switch
        UDMain.UDAM.StopAnimation(akActor)
    else
        parent.EndThirdPersonAnimation(akActor, cameraState, true)
    endif
EndFunction

Function PlayThirdPersonAnimation(actor akActor, string animation, int duration, bool permitRestrictive=false)
    parent.PlayThirdPersonAnimation(akActor, animation, duration, permitRestrictive=false)
EndFunction

Function ActorOrgasm(actor akActor, int setArousalTo=-1, int vsID=-1)
    int loc_newArousal = 100 - setArousalTo
    if setArousalTo == -1
        loc_newArousal = 75
    endif
    ;ActorOrgasmPatched(akActor,20,loc_newArousal)
    UDmain.GetUDOM(akActor).ActorOrgasm(akActor,20,loc_newArousal)
EndFunction

Function UpdateExposure(actor akRef, float val, bool skipMultiplier=false)
    If (akRef == None)
        Error("UpdateExposure passed none reference.")
        return
    EndIf
    int lastRank = Aroused.GetActorExposure(akRef)
    if skipMultiplier
        ; This function is very slow, and sometimes hangs for multiple seconds (Seen 10+). Directly access internals as a work-around.
        int newVal = lastRank + Round(val) 
        newVal = iRange(newVal,0,100)
        Aroused.SetActorExposure(akRef, newVal)
    Else
        int newRank = Round(lastRank + val * Aroused.GetActorExposureRate(akRef))
        Aroused.SetActorExposure(akRef, newRank)
    EndIf
EndFunction

Function ApplyExpression(Actor akActor, sslBaseExpression expression, int strength, bool openMouth=false)
    if UDmain.ZadExpressionSystemInstalled
        parent.ApplyExpression(akActor, expression, strength, openMouth)
        return
    endif
    
    if akActor.Is3DLoaded() || UDmain.ActorIsPlayer(akActor)
        UDCDmain.UDEM.ApplyExpression(akActor, expression, strength, openMouth,0)
    endif
EndFunction

Function ResetExpression(actor akActor, sslBaseExpression expression)
    if UDmain.ZadExpressionSystemInstalled
        parent.ResetExpression(akActor, expression)
        return
    endif
    UDCDmain.UDEM.ResetExpression(akActor, expression,0)
EndFunction

Function ApplyGagEffect(actor akActor) 
    if UDmain.ZadExpressionSystemInstalled
        parent.ApplyGagEffect(akActor)
        return
    endif   
    UDCDmain.UDEM.ApplyGagEffect(akActor)
EndFunction

Function RemoveGagEffect(actor akActor)
    if UDmain.ZadExpressionSystemInstalled
        parent.RemoveGagEffect(akActor)
        return
    endif   
    UDCDmain.UDEM.RemoveGagEffect(akActor)
EndFunction

Event StartBoundEffects(Actor akTarget)
    UDCDmain.SendStartBoundEffectEvent(akTarget)
EndEvent

Event StartBoundEffectsPatched(Actor akTarget)
    parent.StartBoundEffects(akTarget)
EndEvent

Armor Function GetRenderedDevice(armor device)
    if device.haskeyword(UDCDmain.UDlibs.PatchedInventoryDevice)
        Armor loc_res = StorageUtil.GetFormValue(device, "UD_RenderDevice", none) as Armor
        if loc_res
            if UDmain.TraceAllowed()        
                UDmain.Log("GetRenderedDevice(patched)("+device.getName()+")called, returning " + loc_res,2)
            endif
            return loc_res
        endif
    endif
    return parent.GetRenderedDevice(device)
EndFunction

Function UpdateControls()
    ProcessPlayerControls(true) ;only update when player is not in minigame
EndFunction

Bool _ProcessPlayerControlsMutex = False
Function StartProcessPlayerControlsMutex()
    while _ProcessPlayerControlsMutex
        Utility.waitMenuMode(0.1)
    endwhile
    _ProcessPlayerControlsMutex = True
EndFunction
Function EndProcessPlayerControlsMutex()
    _ProcessPlayerControlsMutex = False
EndFunction
Function ProcessPlayerControls(bool abCheckMinigame = true)
    if UDmain.TraceAllowed()
        UDMain.Log("ProcessPlayerControls",3)
    endif
    if (!abCheckMinigame || !UDCDmain.PlayerInMinigame())
        StartProcessPlayerControlsMutex()
        ; Centralized control management function.
        bool movement   = true
        bool fighting   = true
        bool sneaking   = true
        bool menu       = true

        ;check hardcore mode
        if UDmain.Player.HasSpell(UDlibs.HardcoreDisableSpell)
            menu = false
        else
            menu = true
        endif

        bool activate = true
        int cameraState = Game.GetCameraState()
        if playerRef.WornHasKeyword(zad_DeviousBlindfold) && (config.BlindfoldMode == 1 || config.BlindfoldMode == 0) && (cameraState == 8 || cameraState == 9)
            movement = false
            sneaking = false
        EndIf

        if IsBound(playerRef)
            If playerRef.WornHasKeyword(zad_BoundCombatDisableKick)
                fighting = false
            Else
                fighting = config.UseBoundCombat
            Endif
        EndIf
        if playerRef.WornHasKeyword(zad_DeviousPetSuit)
            sneaking = false
        EndIf
        if playerRef.WornHasKeyword(zad_DeviousPonyGear)
            sneaking = false
        EndIf
        Game.DisablePlayerControls(abMovement = !movement, abFighting = !fighting, abSneaking = !sneaking, abMenu = !menu, abActivate = !activate)    
        Game.EnablePlayerControls(abMovement = movement, abFighting = fighting, abSneaking = sneaking, abMenu = menu, abActivate = activate) 
        EndProcessPlayerControlsMutex()
    endif
EndFunction

function stripweapons(actor a, bool unequiponly = true)        
    int i = 2
    Spell spl
    Weapon weap
    Armor sh
    While i > 0
        i -= 1
        if i == 0
            Utility.WaitMenuMode(1.0) ;edited so devices lock also when in menu, to save time
        EndIf
        spl = a.getEquippedSpell(1)
        if spl
            a.unequipSpell(spl, 1)
        endIf
        weap = a.GetEquippedWeapon(true)
        if weap
            a.unequipItem(weap, false, true)
        endIf
        sh = a.GetEquippedShield()
        if sh
            a.unequipItem(sh, false, true)
        endIf
        spl = a.getEquippedSpell(0)
        if spl
            a.unequipSpell(spl, 0)
        endIf
        weap = a.GetEquippedWeapon(false)
        if weap
            a.unequipItem(weap, false, true)
        endIf
    EndWhile
endfunction

Function RepopulateNpcs()
    if repopulateMutex ; Avoid this getting hit too quickly while comparing times
        Log("RepopulateNpcs() is already processing.")
        return
    EndIf
    repopulateMutex=true
    Log("RepopulateNpcs()")
    if Utility.GetCurrentRealTime() - lastRepopulateTime <= 5
        Log("Aborting repopulation of NPC slots: Hit throttle.")
        repopulateMutex=false
        return
    EndIf
    lastRepopulateTime = Utility.GetCurrentRealTime()
    if zadNPCQuest.IsProcessing
        Log("Waiting, since NPC Events is currently processing.")
        int timeout = 0
        while zadNPCQuest.IsProcessing && timeout <= 24
            Utility.WaitMenuMode(5) ;edited so devices lock also when in menu, to save time
            timeout += 1
        EndWhile
        if timeout >= 24
            Warn("RepopulateNpcs() spinlock timed out!!")
            zadNPCQuest.IsProcessing = false
        EndIf
    EndIf
    if !zadNPCSlots.IsStopping() && !zadNPCSlots.IsStarting()
        if zadNPCSlots.IsRunning()
            zadNPCSlots.Stop()
        EndIf
        If config.NumNpcs>0
            ; Feels like a race condition / timing issue?
            ; Perhaps if I call a short wait (Thus suspending execution, giving the quest a chance to fully stop?), it won't occur.
            Utility.WaitMenuMode(2.0) ;edited so devices lock also when in menu, to save time
            zadNPCSlots.Start()
        Else
            Log("Not repopulating NPC slots: Feature is disabled.")
        EndIf
    Else
        Warn("Not repopulating NPC slots: Quest is changing state.")
    EndIf
    repopulateMutex=false
EndFunction

Bool Function JamLock(actor akActor, keyword zad_DeviousDevice)
    If akActor != playerRef || !akActor.WornHasKeyword(zad_DeviousDevice)
        return False
    Endif
    
    Armor loc_renderdevice = GetWornRenderedDeviceByKeyword(akActor,zad_DeviousDevice)
    if loc_renderdevice
        if loc_renderdevice.HasKeyword(UDlibs.UnforgivingDevice)
            UD_CustomDevice_RenderScript loc_device = UDCDmain.getDeviceByRender(akActor, loc_renderdevice)
            loc_device.JammAllLocks(True)
            ;loc_device.UD_JammedLocks = loc_device.UD_CurrentLocks
        endif
        StorageUtil.SetIntValue(akActor, "zad_Equipped" + LookupDeviceType(zad_DeviousDevice) + "_LockJammedStatus", 1)
        return True
    else
        UDmain.Error("JamLock("+GetActorName(akActor)+","+zad_DeviousDevice+") - Error getting device!")
        return false
    endif
EndFunction

Bool Function UnJamLock(actor akActor, keyword zad_DeviousDevice)
    If akActor != playerRef || !akActor.WornHasKeyword(zad_DeviousDevice)
        return False
    Endif
    
    Armor loc_renderdevice = GetWornRenderedDeviceByKeyword(akActor,zad_DeviousDevice)
    if loc_renderdevice
        if loc_renderdevice.HasKeyword(UDlibs.UnforgivingDevice)
            UD_CustomDevice_RenderScript loc_device = UDCDmain.getDeviceByRender(akActor, loc_renderdevice)
            loc_device.JammAllLocks(False)
            ;loc_device.UD_JammedLocks = 0
        endif
        StorageUtil.SetIntValue(akActor, "zad_Equipped" + LookupDeviceType(zad_DeviousDevice) + "_LockJammedStatus", 0)
        return True
    else
        UDmain.Error("UnJamLock("+GetActorName(akActor)+","+zad_DeviousDevice+") - Error getting device!")
        return false
    endif
EndFunction

Function Notify(string out, bool messageBox=false)
    If !messageBox
        UDMain.UDWC.Notification_Push(out)
    Else
        Parent.Notify(out, messageBox)
    EndIf
EndFunction

String Function BuildVibrationString(actor akActor, int vibStrength, bool vPlug, bool aPlug, bool vPiercings, bool nPiercings)
    If UDMain.UDWC.UD_FilterVibNotifications
        Return ""
    Else
        Parent.BuildVibrationString(akActor, vibStrength, vPlug, aPlug, vPiercings, nPiercings)
    EndIf
EndFunction

String Function BuildPostVibrationString(actor akActor, int vibStrength, bool vPlug, bool aPlug, bool vPiercings, bool nPiercings)
    If UDMain.UDWC.UD_FilterVibNotifications
        Return ""
    Else
        Parent.BuildVibrationString(akActor, vibStrength, vPlug, aPlug, vPiercings, nPiercings)
    EndIf
EndFunction
