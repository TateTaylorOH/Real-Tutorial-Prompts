scriptName Survival_NeedHunger extends Survival_NeedBase

globalvariable property Survival_HelpShown_Hunger auto
spell property Survival_AfflictionWeakened auto
spell property Survival_DiseaseGutworm auto
Bool property eating = false auto hidden
referencealias property PlayerAlias auto
globalvariable property Survival_HungerRestoreLargeAmount auto
globalvariable property Survival_RacialBonusMinor auto
spell property Survival_DiseaseFoodPoisoning auto
spell property Survival_DiseaseGutworm2 auto
Float[] property EatingQueue auto
globalvariable property Survival_AfflictionHungerChance auto
globalvariable property Survival_HungerRestoreMediumAmount auto
message property Survival_AfflictionWeakenedMsg auto
formlist property Survival_HungerResistRacesMinor auto
spell property Survival_DiseaseGutworm3 auto
globalvariable property Survival_HungerRestoreSmallAmount auto
message property Survival_HelpHungerHigh auto
globalvariable property Survival_HungerRestoreVerySmallAmount auto

Int currentEatingIndex = 0

function DecreaseHungerVerySmall()
	DecreaseHungerBuffered(Survival_HungerRestoreVerySmallAmount.GetValue())
endFunction

function IncreaseHunger(Float amount)
	if conditions.isInPlaneOfOblivion
		survival_globalfunctions.SurvivalLogMessage("{{HUNGER}} In Oblivion, skipping IncreaseHunger.")
		return 
	endIf
	survival_globalfunctions.SurvivalLogMessage("{{HUNGER}} IncreaseHunger Start")
	Float currentNeedValue = NeedValue.GetValue()
	Float newHungerValue = IncrementNeed(currentNeedValue, amount, -1.00000)
	ApplyHungerStage(newHungerValue, lastValue)
	lastValue = newHungerValue
endFunction

function DecreaseHungerLarge()
	DecreaseHungerBuffered(Survival_HungerRestoreLargeAmount.GetValue())
endFunction

function AddToEatingBuffer(Float amount)
	Bool checkedEveryIndex = false
	Int nextIndex = currentEatingIndex
	while !checkedEveryIndex
		if EatingQueue[nextIndex] == 0.000000
			EatingQueue[nextIndex] = amount
			return 
		else
			survival_globalfunctions.SurvivalLogMessage("{{EATING}}   Index " + nextIndex as String + " is populated, checking next index.")
			nextIndex = GetNextIndex(nextIndex, EatingQueue)
		endIf
		if nextIndex == currentEatingIndex
			checkedEveryIndex = true
		endIf
	endWhile
	survival_globalfunctions.SurvivalLogMessage("{{EATING}}   Could not find empty entry from current starting point, overwriting " + nextIndex as String)
	EatingQueue[nextIndex] = amount
endFunction

function DecreaseHungerBuffered(Float amount)
	if conditions.isInPlaneOfOblivion
		return 
	endIf
	AddToEatingBuffer(amount)
	if !eating
		eating = true
		ProcessEatingBuffer()
		eating = false
	endIf
endFunction

Float function GetGutwormEffectMult()
	if PlayerRef.HasSpell(Survival_DiseaseGutworm as form)
		return 0.750000
	elseIf PlayerRef.HasSpell(Survival_DiseaseGutworm2 as form)
		return 0.500000
	elseIf PlayerRef.HasSpell(Survival_DiseaseGutworm3 as form)
		return 0.250000
	else
		return 1.00000
	endIf
endFunction

function UpdateAttributePenalty(Float afNeedValue, String asAttributeAV, String asPenaltyAV)
	parent.UpdateAttributePenalty(afNeedValue, "Stamina", survival_globalfunctions.HungerStaminaPenaltyAV())
endFunction

function StopNeed()
	WaitForUnlock()
	parent.StopNeed()
	PlayerAlias.Clear()
endFunction

function NeedUpdateGameTime()
	Float racialBonus
	survival_globalfunctions.SurvivalLogMessage("{{HUNGER}} Update Start")
	Bool wasSleeping = detectedSleepEvent
	if conditions.isInPlaneOfOblivion
		survival_globalfunctions.SurvivalLogMessage("{{HUNGER}} In Oblivion, skipping NeedUpdateGameTime.")
		lastTimeInGameHours = utility.GetCurrentGameTime() * 24 as Float
		return 
	endIf
	race playerRace = PlayerRef.GetActorBase().GetRace()
	if Survival_HungerResistRacesMinor.HasForm(playerRace as form)
		racialBonus = Survival_RacialBonusMinor.GetValue()
	endIf
	Float totalBonus = racialBonus
	Float newHungerValue = IncrementNeedByTick(totalBonus)
	ApplyHungerStage(newHungerValue, lastValue)
	if !wasSleeping && newHungerValue >= needStage5Value && !PlayerRef.HasSpell(Survival_AfflictionWeakened as form)
		survival_globalfunctions.SurvivalLogMessage("{{HUNGER}} Player eligible for Weakened. Rolling...")
		Float result = utility.RandomFloat(0.000000, 1.00000)
		survival_globalfunctions.SurvivalLogMessage("{{HUNGER}}     Result: " + result as String)
		if result <= Survival_AfflictionHungerChance.GetValue()
			survival_globalfunctions.SurvivalLogMessage("{{HUNGER}}     Player is now Weakened!")
			Survival_AfflictionWeakenedMsg.Show()
			PlayerRef.AddSpell(Survival_AfflictionWeakened, false)
		endIf
	endIf
	lastValue = newHungerValue
endFunction

function ClearAttributePenalty(String asPenaltyAV)
	parent.ClearAttributePenalty(survival_globalfunctions.HungerStaminaPenaltyAV())
endFunction

function SetNeedStageValues()
	needStage1Value = 80 as Float
	needStage2Value = 160 as Float
	needStage3Value = 340 as Float
	needStage4Value = 520 as Float
	needStage5Value = 770 as Float
endFunction

function StartNeed()
	oldStage = 99
	parent.StartNeed()
	RegisterForSleep()
	PlayerAlias.ForceRefIfEmpty(PlayerRef as objectreference)
endFunction

function ProcessEatingBuffer()
	Bool foodToEat = true
	while foodToEat
		Float eatingValue = EatingQueue[currentEatingIndex]
		EatingQueue[currentEatingIndex] = 0.000000
		if eatingValue != 0.000000
			DecreaseHungerImpl(eatingValue)
			survival_globalfunctions.SurvivalLogMessage("{{EATING}}   Ate food at index " + currentEatingIndex as String)
			currentEatingIndex = GetNextIndex(currentEatingIndex, EatingQueue)
		else
			foodToEat = false
		endIf
	endWhile
endFunction

function DecreaseHungerMedium()
	DecreaseHungerBuffered(Survival_HungerRestoreMediumAmount.GetValue())
endFunction

function RemoveAllNeedSpells()
	Int i = 0
	while i < needSpells.length
		PlayerRef.RemoveSpell(needSpells[i])
		i += 1
	endWhile
endFunction

function DecreaseHungerImpl(Float amount)
	survival_globalfunctions.SurvivalLogMessage("{{HUNGER}} DecreaseHunger Start")
	amount *= GetGutwormEffectMult()
	Float currentNeedValue = NeedValue.GetValue()
	Float newHungerValue = DecrementNeed(currentNeedValue, amount, -1.00000, -1.00000)
	ApplyHungerStage(newHungerValue, lastValue)
	lastValue = newHungerValue
endFunction

Float function IncrementNeedByTick(Float rateReductionMultiplier)
	utility.Wait(1 as Float)
	survival_globalfunctions.SurvivalLogMessage("{{HUNGER}}     IncrementNeedByTick with rateReductionMultiplier = " + rateReductionMultiplier as String)
	Float currentNeedValue = NeedValue.GetValue()
	Float currentTimeInGameHours = utility.GetCurrentGameTime() * 24 as Float
	Float currentTimeInRealSeconds = utility.GetCurrentRealTime()
	if firstUpdate
		survival_globalfunctions.SurvivalLogMessage("{{HUNGER}}     Ignoring the first update and storing update time.")
		lastTimeInGameHours = currentTimeInGameHours
		return currentNeedValue + 1 as Float
	endIf
	Int ticks = GetTicks(currentTimeInGameHours, lastTimeInGameHours)
	Float amountToIncrementBy = GetAmountToIncrementBy(ticks, rateReductionMultiplier)
	Float newNeedValue = IncrementNeed(currentNeedValue, amountToIncrementBy, -1.00000)
	survival_globalfunctions.SurvivalLogMessage("{{HUNGER}}     Incrementing need by " + amountToIncrementBy as String)
	lastTimeInGameHours = currentTimeInGameHours
	survival_globalfunctions.SurvivalLogMessage("{{HUNGER}}     New value is " + newNeedValue as String)
	return newNeedValue
endFunction

function ApplyHungerStage(Float newHungerValue, Float oldHungerValue)
	Int newStage
	Bool increasing = newHungerValue > oldHungerValue
	survival_globalfunctions.SurvivalLogMessage("{{HUNGER}}     Applying Hunger stage. New value: " + newHungerValue as String + ", Old value: " + oldHungerValue as String + ", increasing: " + increasing as String)
	if hasBonus
		newStage = 0
	elseIf survival_globalfunctions.Between(newHungerValue, needStage2Value, NeedMinValue, false)
		newStage = 1
	elseIf survival_globalfunctions.Between(newHungerValue, needStage3Value, needStage2Value, false)
		newStage = 2
	elseIf survival_globalfunctions.Between(newHungerValue, needStage4Value, needStage3Value, false)
		newStage = 3
	elseIf survival_globalfunctions.Between(newHungerValue, needStage5Value, needStage4Value, false)
		newStage = 4
	elseIf survival_globalfunctions.Between(newHungerValue, NeedMaxValue.GetValue(), needStage5Value, true)
		newStage = 5
	endIf
	if newStage != oldStage
		survival_globalfunctions.SurvivalLogMessage("{{HUNGER}}     Applying Stage " + newStage as String)
		ApplyNeedStagePlayerEffects(increasing, needSpells[newStage], needMessagesWhenIncreasing[newStage], needMessagesWhenDecreasing[newStage])
		ApplyNeedSFX(increasing, needSoundFXs[newStage], needSoundFXsFemale[newStage], needPlaySoundFXsOnImprove[newStage])
		ApplyNeedRumble(increasing, needRumbleSmallMotorStrengths[newStage], needRumbleBigMotorStrengths[newStage], needRumbleDurations[newStage], needPlayRumblesOnImprove[newStage])
	endIf
	oldStage = newStage
	if newStage >= 2 && Survival_HelpShown_Hunger.GetValueInt() == 0 && !PlayerRef.IsInCombat()
		ShowTutorialMessage(Survival_HelpHungerHigh)
		Survival_HelpShown_Hunger.SetValueInt(1)
	endIf
endFunction

Int function GetNextIndex(Int idx, Float[] array)
	return (idx + 1) % array.length
endFunction

function DecreaseHungerSmall()
	DecreaseHungerBuffered(Survival_HungerRestoreSmallAmount.GetValue())
endFunction
