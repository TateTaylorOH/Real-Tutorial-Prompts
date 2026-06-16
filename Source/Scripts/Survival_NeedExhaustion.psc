scriptName Survival_NeedExhaustion extends Survival_NeedBase

globalvariable property Survival_AfflictionExhaustionChance auto
keyword property LocTypeInn auto
spell property VampireVampirism auto
formlist property Survival_ExhaustionResistRacesMinor auto
Bool property playerSleeping = false auto hidden
keyword property LocTypePlayerHouse auto
message property RestedMessage auto
quest property PlayerSleepQuest auto
spell property pDoomLoverAbility auto
referencealias property PlayerAlias auto
quest property RelationshipMarriageFIN auto
message property BeastBloodMessage auto
spell property WerewolfImmunity auto
message property MarriageRestedMessage auto
message property Survival_AfflictionAddledMsg auto
spell property Survival_DiseaseBrownRot auto
quest property BYOHRelationshipAdoption auto
spell[] property needSpellsNoDisease auto
spell property BYOHAdoptionSleepAbilityFemale auto
globalvariable property Survival_RacialBonusMinor auto
globalvariable property Survival_HelpShown_Exhaustion auto
locationalias property CurrentHomeLocation auto
formlist property Survival_ExhaustionResistRacesMajor auto
spell property Rested auto
spell property BYOHAdoptionSleepAbilityMale auto
globalvariable property Survival_RacialBonusMajor auto
spell property WellRested auto
companionshousekeepingscript property CHScript auto
spell property Survival_DiseaseBrownRot2 auto
referencealias property LoveInterest auto
message property BYOHAdoptionRestedMessageFemale auto
message property BYOHAdoptionRestedMessageMale auto
spell property Survival_AfflictionAddled auto
message property WellRestedMessage auto
spell property Survival_DiseaseBrownRot3 auto
message property Survival_HelpExhaustionHigh auto
spell property MarriageSleepAbility auto

function NeedUpdateGameTime()
	Float racialBonus
	survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}} Update Start")
	Bool wasSleeping = detectedSleepEvent
	if conditions.isInPlaneOfOblivion
		survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}} In Oblivion, skipping NeedUpdateGameTime.")
		lastTimeInGameHours = utility.GetCurrentGameTime() * 24 as Float
		return 
	endIf
	if playerSleeping
		survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}} Player was sleeping, cancelling this update.")
		playerSleeping = false
		lastTimeInGameHours = utility.GetCurrentGameTime() * 24 as Float
		return 
	endIf
	race playerRace = PlayerRef.GetActorBase().GetRace()
	if Survival_ExhaustionResistRacesMajor.HasForm(playerRace as form)
		racialBonus = Survival_RacialBonusMajor.GetValue()
	elseIf Survival_ExhaustionResistRacesMinor.HasForm(playerRace as form)
		racialBonus = Survival_RacialBonusMinor.GetValue()
	endIf
	Float newExhaustionValue = IncrementNeedByTick(racialBonus)
	ApplyExhaustionStage(newExhaustionValue, lastValue, CanGetRestedBonus(false))
	if !wasSleeping && newExhaustionValue >= needStage5Value && !PlayerRef.HasSpell(Survival_AfflictionAddled as form)
		survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}} Player eligible for Addled. Rolling...")
		Float result = utility.RandomFloat(0.000000, 1.00000)
		survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}}     Result: " + result as String)
		if result <= Survival_AfflictionExhaustionChance.GetValue()
			survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}}     Player is now Addled!")
			Survival_AfflictionAddledMsg.Show()
			PlayerRef.AddSpell(Survival_AfflictionAddled, false)
		endIf
	endIf
	lastValue = newExhaustionValue
endFunction

function DecreaseExhaustion(Float amount, Bool qualitySleep)
	Float newExhaustionValue
	if conditions.isInPlaneOfOblivion
		survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}} In Oblivion, skipping DecreaseExhaustion.")
		return 
	endIf
	survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}} DecreaseExhaustion Start, amount " + amount as String + " qualitySleep " + qualitySleep as String)
	ApplyAdoptionBonus()
	Float currentNeedValue = NeedValue.GetValue()
	amount *= GetBrownRotEffectMult()
	if qualitySleep
		survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}} Player got quality sleep.")
		newExhaustionValue = DecrementNeed(currentNeedValue, amount, -1.00000, -1.00000)
	else
		survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}} Player got poor quality sleep outdoors.")
		if currentNeedValue >= needStage2Value
			newExhaustionValue = DecrementNeed(currentNeedValue, amount, needStage2Value, -1.00000)
		else
			survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}} Sleeping here would make the player worse off; don't apply this change.")
			return 
		endIf
	endIf
	ApplyExhaustionStage(newExhaustionValue, lastValue, CanGetRestedBonus(true))
	lastValue = newExhaustionValue
endFunction

function StartNeed()
	RemoveAllNeedSpells()
	oldStage = 99
	parent.StartNeed()
	PlayerSleepQuest.UnregisterForSleep()
	PlayerAlias.ForceRefIfEmpty(PlayerRef as objectreference)
endFunction

function SwitchToNoDiseaseEffects()
	survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}}     Switching to no disease effects.")
	Int i = 3
	while i < needSpells.length
		if PlayerRef.HasSpell(needSpells[i] as form)
			PlayerRef.RemoveSpell(needSpells[i])
			PlayerRef.AddSpell(needSpellsNoDisease[i], false)
		endIf
		i += 1
	endWhile
endFunction

function UpdateAttributePenalty(Float afNeedValue, String asAttributeAV, String asPenaltyAV)
	parent.UpdateAttributePenalty(afNeedValue, "Magicka", survival_globalfunctions.ExhaustionMagickaPenaltyAV())
endFunction

Float function IncrementNeedByTick(Float rateReductionMultiplier)
	utility.Wait(1 as Float)
	survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}}     IncrementNeedByTick with rateReductionMultiplier = " + rateReductionMultiplier as String)
	Float currentNeedValue = NeedValue.GetValue()
	Float currentTimeInGameHours = utility.GetCurrentGameTime() * 24 as Float
	Float currentTimeInRealSeconds = utility.GetCurrentRealTime()
	if firstUpdate
		survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}}     Ignoring the first update and storing update time.")
		lastTimeInGameHours = currentTimeInGameHours
		return currentNeedValue + 1 as Float
	endIf
	Int ticks = GetTicks(currentTimeInGameHours, lastTimeInGameHours)
	Float amountToIncrementBy = GetAmountToIncrementBy(ticks, rateReductionMultiplier)
	if PlayerRef.IsOverEncumbered()
		amountToIncrementBy *= Survival_ExhaustionOverEncumberedMult.GetValue()
	endIf
	Float newNeedValue = IncrementNeed(currentNeedValue, amountToIncrementBy, -1.00000)
	survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}}     Incrementing need by " + amountToIncrementBy as String)
	lastTimeInGameHours = currentTimeInGameHours
	survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}}     New value is " + newNeedValue as String)
	return newNeedValue
endFunction

function ApplyAdoptionBonus()
	if BYOHRelationshipAdoption.IsRunning() && PlayerRef.GetCurrentLocation() == CurrentHomeLocation.GetLocation()
		RemoveAdoptionRested()
		if PlayerRef.GetActorBase().GetSex() == 0
			BYOHAdoptionRestedMessageMale.Show()
			PlayerRef.AddSpell(BYOHAdoptionSleepAbilityMale, false)
		else
			BYOHAdoptionRestedMessageFemale.Show()
			PlayerRef.AddSpell(BYOHAdoptionSleepAbilityFemale, false)
		endIf
	endIf
endFunction

Bool function PlayerIsVampireOrWerewolf()
	if PlayerRef.HasSpell(VampireVampirism as form) || PlayerRef.HasSpell(WerewolfImmunity as form)
		return true
	else
		return false
	endIf
endFunction

function ClearAttributePenalty(String asPenaltyAV)
	parent.ClearAttributePenalty(survival_globalfunctions.ExhaustionMagickaPenaltyAV())
endFunction

function RemoveAllNeedSpells()
	PlayerRef.RemoveSpell(Rested)
	PlayerRef.RemoveSpell(WellRested)
	PlayerRef.RemoveSpell(MarriageSleepAbility)
	Int i = 0
	while i < needSpells.length
		PlayerRef.RemoveSpell(needSpells[i])
		i += 1
	endWhile
	i = 0
	while i < needSpellsNoDisease.length
		PlayerRef.RemoveSpell(needSpellsNoDisease[i])
		i += 1
	endWhile
endFunction

function RemoveAdoptionRested()
	PlayerRef.RemoveSpell(BYOHAdoptionSleepAbilityMale)
	PlayerRef.RemoveSpell(BYOHAdoptionSleepAbilityFemale)
endFunction

function SwitchToDiseaseEffects()
	survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}}     Switching to disease effects.")
	Int i = 3
	while i < needSpells.length
		if PlayerRef.HasSpell(needSpellsNoDisease[i] as form)
			PlayerRef.RemoveSpell(needSpellsNoDisease[i])
			PlayerRef.AddSpell(needSpells[i], false)
		endIf
		i += 1
	endWhile
endFunction

function SetNeedStageValues()
	needStage1Value = 80 as Float
	needStage2Value = 160 as Float
	needStage3Value = 340 as Float
	needStage4Value = 560 as Float
	needStage5Value = 800 as Float
endFunction

Float function GetBrownRotEffectMult()
	if PlayerRef.HasSpell(Survival_DiseaseBrownRot as form)
		return 0.750000
	elseIf PlayerRef.HasSpell(Survival_DiseaseBrownRot2 as form)
		return 0.500000
	elseIf PlayerRef.HasSpell(Survival_DiseaseBrownRot3 as form)
		return 0.250000
	else
		return 1.00000
	endIf
endFunction

function StopNeed()
	WaitForUnlock()
	parent.StopNeed()
	PlayerAlias.Clear()
	PlayerSleepQuest.RegisterForSleep()
endFunction

function ApplyExhaustionStage(Float newExhaustionValue, Float oldExhaustionValue, Bool CanGetRestedBonus)
	Int newStage
	Bool increasing = newExhaustionValue > oldExhaustionValue
	survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}}     Applying exhaustion stage. New value: " + newExhaustionValue as String + ", Old value: " + oldExhaustionValue as String + ", increasing: " + increasing as String)
	if hasBonus
		newStage = 0
	elseIf survival_globalfunctions.Between(newExhaustionValue, needStage2Value, NeedMinValue, false)
		newStage = 1
	elseIf survival_globalfunctions.Between(newExhaustionValue, needStage3Value, needStage2Value, false)
		newStage = 2
	elseIf survival_globalfunctions.Between(newExhaustionValue, needStage4Value, needStage3Value, false)
		newStage = 3
	elseIf survival_globalfunctions.Between(newExhaustionValue, needStage5Value, needStage4Value, false)
		newStage = 4
	elseIf survival_globalfunctions.Between(newExhaustionValue, NeedMaxValue.GetValue(), needStage5Value, true)
		newStage = 5
	endIf
	if newStage != oldStage || newExhaustionValue == NeedMinValue
		survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}}     Applying Stage " + newStage as String)
		if newStage == 0
			if CanGetRestedBonus
				RemoveAllNeedSpells()
				ApplyNormalRestedBonus()
			else
				ApplyNeedStagePlayerEffects(increasing, needSpells[1], needMessagesWhenIncreasing[1], needMessagesWhenDecreasing[1])
			endIf
		elseIf newStage >= 3 && PlayerIsVampireOrWerewolf()
			ApplyNeedStagePlayerEffects(increasing, needSpellsNoDisease[newStage], needMessagesWhenIncreasing[newStage], needMessagesWhenDecreasing[newStage])
		else
			ApplyNeedStagePlayerEffects(increasing, needSpells[newStage], needMessagesWhenIncreasing[newStage], needMessagesWhenDecreasing[newStage])
		endIf
		ApplyNeedSFX(increasing, needSoundFXs[newStage], needSoundFXsFemale[newStage], needPlaySoundFXsOnImprove[newStage])
		ApplyNeedRumble(increasing, needRumbleSmallMotorStrengths[newStage], needRumbleBigMotorStrengths[newStage], needRumbleDurations[newStage], needPlayRumblesOnImprove[newStage])
	endIf
	oldStage = newStage
	if newStage >= 2 && Survival_HelpShown_Exhaustion.GetValueInt() == 0 && !PlayerRef.IsInCombat()
		ShowTutorialMessage(Survival_HelpExhaustionHigh)
		Survival_HelpShown_Exhaustion.SetValueInt(1)
	endIf
endFunction

function IncreaseExhaustion(Float amount)
	if conditions.isInPlaneOfOblivion
		survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}} In Oblivion, skipping IncreaseExhaustion.")
		return 
	endIf
	survival_globalfunctions.SurvivalLogMessage("{{EXHAUSTION}} IncreaseExhaustion Start, amount " + amount as String)
	Float currentNeedValue = NeedValue.GetValue()
	Float newExhaustionValue = IncrementNeed(currentNeedValue, amount, -1.00000)
	ApplyExhaustionStage(newExhaustionValue, lastValue, CanGetRestedBonus(false))
	lastValue = newExhaustionValue
endFunction

function ApplyNormalRestedBonus()
	location currentLocation = PlayerRef.GetCurrentLocation()
	if RelationshipMarriageFIN.IsRunning() && RelationshipMarriageFIN.GetStage() >= 10 && currentLocation == LoveInterest.GetActorRef().GetCurrentLocation()
		MarriageRestedMessage.Show()
		PlayerRef.AddSpell(MarriageSleepAbility, false)
	elseIf currentLocation.HasKeyword(LocTypeInn) || currentLocation.HasKeyword(LocTypePlayerHouse)
		WellRestedMessage.Show()
		PlayerRef.AddSpell(WellRested, false)
	else
		RestedMessage.Show()
		PlayerRef.AddSpell(Rested, false)
	endIf
endFunction

function SelectCorrectEffects()
	if PlayerIsVampireOrWerewolf()
		SwitchToNoDiseaseEffects()
	else
		SwitchToDiseaseEffects()
	endIf
endFunction

Bool function CanGetRestedBonus(Bool showMessages)
	if CHScript.PlayerHasBeastBlood
		if showMessages
			BeastBloodMessage.Show()
		endIf
		return false
	elseIf PlayerRef.HasSpell(pDoomLoverAbility as form)
		return false
	else
		return true
	endIf
endFunction
