Scriptname UD_Native hidden

;===Minigame Effect===
        Function StartMinigameEffect        (Actor akActor,Float afMult, Float afStamina, Float afHealth, Float afMagicka, Bool abToggle) global native
        Function EndMinigameEffect          (Actor akActor)                     global native
bool    Function IsMinigameEffectOn         (Actor akActor)                     global native
        Function UpdateMinigameEffectMult   (Actor akActor, float afNewMult)    global native
        Function ToggleMinigameEffect       (Actor akActor, bool abToggle)      global native ;abToggle = true -> enabled, abToggle = false -> disabled
bool    Function MinigameStatsCheck         (Actor akActor, bool abStamina, bool abHealth, bool abMagicka)                      global native
        Function MinigameEffectSetHealth    (Actor akActor, float afNewHealth)  global native
        Function MinigameEffectSetStamina   (Actor akActor, float afNewStamina) global native
        Function MinigameEffectSetMagicka   (Actor akActor, float afNewMagicka) global native
        Function MinigameEffectUpdateHealth (Actor akActor, float afHealth)     global native
        Function MinigameEffectUpdateStamina(Actor akActor, float afStamina)    global native
        Function MinigameEffectUpdateMagicka(Actor akActor, float afMagicka)    global native

;===UTILITY===
Int     Function CodeBit                    (int aiCodedMap,int aiValue,int aiSize,int aiIndex) global native
Int     Function DecodeBit                  (int aiCodedMap,int aiSize,int aiIndex)             global native

;===UI===
int     Function RemoveAllMeterEntries()                                        global native
        Function ToggleAllMeters            (bool abToggle)                     global native

;iWantWidget meters
        Function AddMeterEntryIWW           (string asPath, int aiId, string asName, float afBase, float afRate, bool abShow)   global native
        Function RemoveMeterEntryIWW        (int aiId)                          global native
        Function ToggleMeterIWW             (int aiId, bool abToggle)           global native
        Function SetMeterRateIWW            (int aiId, float afNewRate)         global native
        Function SetMeterMultIWW            (int aiId, float afNewMult)         global native
        Function SetMeterValueIWW           (int aiId, float afNewValue)        global native
Float   Function UpdateMeterValueIWW        (int aiId, float afDiffValue)       global native
Float   Function GetMeterValueIWW           (int aiId)                          global native

;SkyUi meters
        Function AddMeterEntrySkyUi         (string asPath, string asName, float afBase, float afRate, bool abShow)             global native
        Function RemoveMeterEntrySkyUi      (string asPath)                     global native
        Function ToggleMeterSkyUi           (string asPath, bool abToggle)      global native
        Function SetMeterRateSkyUi          (string asPath, float afNewRate)    global native
        Function SetMeterMultSkyUi          (string asPath, float afNewMult)    global native
        Function SetMeterValueSkyUi         (string asPath, float afNewValue)   global native
Float   Function UpdateMeterValueSkyUi      (string asPath, float afDiffValue)  global native
Float   Function GetMeterValueSkyUi         (string asPath)                     global native

;===Inventory===
Form[]  Function GetInventoryDevices        (Actor akActor, bool abWorn)        global native
Form[]  Function GetRenderDevices           (Actor akActor, bool abWorn)        global native
Weapon  Function GetSharpestWeapon          (Actor akActor)                     global native

;===Animation===
Int     Function GetActorConstrains         (Actor akActor)                     global native

;===Skill===
Int     Function CalculateSkillFromPerks    (Actor akActor,Formlist akList,Int aiIncrease)      global native

;===Modifiers===
Bool    Function HasModifier                (String[] aaModifiers, String asModName)            global native
Int     Function GetModifierIndex           (String[] aaModifiers, String asModName)            global native
Bool    Function ModifierHaveParams         (String[] aaModifiers, String asModName)            global native
String[] Function getModifierAllParam       (String[] aaModifiers, String asModName)            global native
Int     Function GetModifierParamNum        (String[] aaModifiers, String asModName)            global native