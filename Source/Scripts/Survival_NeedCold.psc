scriptName Survival_NeedCold extends Survival_NeedBase

message property Survival_ColdWarmingUpMessage auto
message property Survival_ColdConditionStage1 auto
Int property coldLevelBlizzardMod = 10 auto hidden
Int property coldLevelWarmAreaNightMod = 1 auto hidden
formlist property Survival_AshWeather auto
Int property coldStage4ColdLevelMin = 10 auto hidden
Int property coldStage1ColdLevelMin = 1 auto hidden
globalvariable property Survival_LastWarmingUpMsgTime auto
Float property cachedColdResistMaxValue auto hidden
survival_heatcheck property heatcheck auto
globalvariable property Survival_ColdResistMaxValue auto
message property Survival_ColdConditionStage4 auto
Int property coldStage3ColdLevelMin = 7 auto hidden
globalvariable property Survival_ColdLevelInFreezingWater auto
Float property cachedNeedUpdateGameTimeInterval auto hidden
Int property coldStage5ColdLevelMin = 13 auto hidden
message property Survival_ColdConditionStage3 auto
Int property coldLevelWarmArea = 0 auto hidden
Float property cachedColdTargetGameHoursToNumb auto hidden
Float property cachedColdLevelMult auto hidden
Float property cachedTimescale auto hidden
message property Survival_ColdConditionStage2 auto
Int property coldLevelSnowMod = 6 auto hidden
formlist property Survival_ColdWeakRacesMajor auto
Int property currentColdLevel = 0 auto hidden
Int property coldLevelFreezingArea = 6 auto hidden
globalvariable property GameHour auto
Int property coldStage2ColdLevelMin = 4 auto hidden
Bool property isBeastRace = false auto hidden
referencealias property PlayerInfoAlias auto
Int property lastColdLevel = 20 auto hidden
Int property coldLevelRainMod = 3 auto hidden
globalvariable property TimeScale auto
Int property coldLevelCoolAreaNightMod = 2 auto hidden
quest property Survival_PlayerInfoQuest auto
Int property coldLevelCoolArea = 3 auto hidden
globalvariable property Survival_ColdTargetGameHoursToNumb auto
globalvariable property Survival_AfflictionColdChance auto
referencealias property PlayerAlias auto
formlist property Survival_InteriorAreas auto
message property Survival_ColdConditionStage5 auto
spell property Survival_AfflictionFrostbitten auto
globalvariable property Survival_HelpShown_Cold auto
globalvariable property Survival_RacialBonusMajor auto
formlist property Survival_BlizzardWeather auto
Int property coldLevelFreezingAreaNightMod = 4 auto hidden
message property Survival_HelpColdHigh auto
message property Survival_AfflictionFrostbittenMsg auto
globalvariable property Survival_ColdLevelMult auto
globalvariable property Survival_TemperatureLevel auto
message property Survival_ColdConditionStage0 auto

Int temperatureLevelNeutral = 0
Int temperatureLevelFreezingArea = 4
Float warmthMaxBonusPercent = 0.850000
Int areaTypeCool = 2
Int temperatureLevelNearHeat = 1
Int temperatureLevelColdArea = 3
Int weatherClassRain = 2
Int temperatureLevelWarmArea = 2
Int areaTypeFreezing = 3
Int lastTemperatureLevel = 0
Bool wasInOblivion = false
Int areaTypeChillyInterior = -1
Int coldToRestoreInWarmArea = 40
Int weatherClassSnow = 3
Int areaTypeInterior = 0
Int areaTypeWarm = 1

function ApplyColdStage(Float newColdValue, Float oldColdValue)
	Int newStage
	Bool increasing = newColdValue > oldColdValue
	if wasInOblivion
		increasing = true
	endIf
	survival_globalfunctions.SurvivalLogMessage("{{COLD}}     Applying Cold stage. New value: " + newColdValue as String + ", Old value: " + oldColdValue as String + ", increasing: " + increasing as String)
	if hasBonus
		newStage = 0
	elseIf survival_globalfunctions.Between(newColdValue, needStage2Value, NeedMinValue, false)
		newStage = 1
	elseIf survival_globalfunctions.Between(newColdValue, needStage3Value, needStage2Value, false)
		newStage = 2
	elseIf survival_globalfunctions.Between(newColdValue, needStage4Value, needStage3Value, false)
		newStage = 3
	elseIf survival_globalfunctions.Between(newColdValue, needStage5Value, needStage4Value, false)
		newStage = 4
	elseIf survival_globalfunctions.Between(newColdValue, NeedMaxValue.GetValue(), needStage5Value, true)
		newStage = 5
	endIf
	if newStage != oldStage
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}     Applying Stage " + newStage as String)
		ApplyNeedStagePlayerEffects(increasing, needSpells[newStage], needMessagesWhenIncreasing[newStage], needMessagesWhenDecreasing[newStage])
		ApplyNeedSFX(increasing, needSoundFXs[newStage], needSoundFXsFemale[newStage], needPlaySoundFXsOnImprove[newStage])
		ApplyNeedRumble(increasing, needRumbleSmallMotorStrengths[newStage], needRumbleBigMotorStrengths[newStage], needRumbleDurations[newStage], needPlayRumblesOnImprove[newStage])
	endIf
	oldStage = newStage
	if newStage >= 2 && Survival_HelpShown_Cold.GetValueInt() == 0 && !PlayerRef.IsInCombat()
		ShowTutorialMessage(Survival_HelpColdHigh)
		Survival_HelpShown_Cold.SetValueInt(1)
	endIf
endFunction

function NeedUpdateGameTime()
	survival_globalfunctions.SurvivalLogMessage("{{COLD}} Update Start")
	Bool wasSleeping = detectedSleepEvent
	if cachedTimescale == 0.000000
		PrecacheValues()
	endIf
	if conditions.isInPlaneOfOblivion
		survival_globalfunctions.SurvivalLogMessage("{{COLD}} In Oblivion, skipping NeedUpdateGameTime.")
		lastTimeInGameHours = utility.GetCurrentGameTime() * 24 as Float
		wasInOblivion = true
		return 
	endIf
	currentColdLevel = UpdateColdLevel()
	Bool nearHeat = heatcheck.IsPlayerNearHeatAndStanding()
	DisplayColdLevelTransitionMessage(currentColdLevel)
	if nearHeat
		survival_globalfunctions.SurvivalLogMessage("{{COLD}} Player is near heat, skipping update.")
		lastTimeInGameHours = utility.GetCurrentGameTime() * 24 as Float
		wasInOblivion = false
		lastColdLevel = currentColdLevel
		return 
	endIf
	Int newMaxStage = GetColdStageMaximum(currentColdLevel)
	Float newMaxValue = GetMaxStageValue(newMaxStage)
	Float warmthRating = PlayerRef.GetWarmthRating()
	Float totalBonus = survival_globalfunctions.ClampFloatTo(warmthRating, 0.000000, cachedColdResistMaxValue)
	Float bonusReductionPercent = warmthMaxBonusPercent * totalBonus / cachedColdResistMaxValue
	survival_globalfunctions.SurvivalLogMessage("{{COLD}} Player's current Warmth Rating: " + totalBonus as String + " (reduction of " + bonusReductionPercent as String + "%)")
	Float newColdValue = IncrementNeedByTick(newMaxValue, bonusReductionPercent)
	ApplyColdStage(newColdValue, lastValue)
	if !wasSleeping && newColdValue >= needStage5Value && !PlayerRef.HasSpell(Survival_AfflictionFrostbitten as form)
		survival_globalfunctions.SurvivalLogMessage("{{COLD}} Player eligible for Frostbitten. Rolling...")
		Float result = utility.RandomFloat(0.000000, 1.00000)
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}     Result: " + result as String)
		if result <= Survival_AfflictionColdChance.GetValue()
			survival_globalfunctions.SurvivalLogMessage("{{COLD}}     Player is now Frostbitten!")
			Survival_AfflictionFrostbittenMsg.Show()
			PlayerRef.AddSpell(Survival_AfflictionFrostbitten, false)
		endIf
	endIf
	UpdateTemperatureUI(currentColdLevel, lastValue, newColdValue)
	CheckIfMaxCold(newColdValue)
	wasInOblivion = false
	lastValue = newColdValue
	lastColdLevel = currentColdLevel
endFunction

function ForceTemperatureLevelUI(Int level)
	SetUITemperatureLevel(level)
endFunction

function ForceTemperatureUINeutral()
	SetUITemperatureLevel(temperatureLevelNeutral)
endFunction

function UpdateTemperatureUI(Int aiColdLevel, Float afOldColdValue, Float afNewColdValue)
	Int temperatureLevel
	if afOldColdValue == afNewColdValue
		temperatureLevel = temperatureLevelNeutral
	elseIf afOldColdValue > afNewColdValue
		temperatureLevel = temperatureLevelWarmArea
	elseIf afOldColdValue < afNewColdValue
		if aiColdLevel >= coldStage5ColdLevelMin
			temperatureLevel = temperatureLevelFreezingArea
		else
			temperatureLevel = temperatureLevelColdArea
		endIf
	endIf
	SetUITemperatureLevel(temperatureLevel)
endFunction

function UpdateAttributePenalty(Float afNeedValue, String asAttributeAV, String asPenaltyAV)
	parent.UpdateAttributePenalty(afNeedValue, "Health", survival_globalfunctions.ColdHealthPenaltyAV())
endFunction

function DecreaseCold(Float amount, Float customMinValue, Bool suppressWarmUpMessage)
	if conditions.isInPlaneOfOblivion
		survival_globalfunctions.SurvivalLogMessage("{{COLD}} In Oblivion, skipping DecreaseCold.")
		return 
	endIf
	survival_globalfunctions.SurvivalLogMessage("{{COLD}} DecreaseCold Start")
	Float currentNeedValue = NeedValue.GetValue()
	Bool previouslyIncreasing = wasIncreasing
	if previouslyIncreasing && currentNeedValue > 50.0000 && !suppressWarmUpMessage
		Float currentTime = utility.GetCurrentRealTime()
		if currentTime - Survival_LastWarmingUpMsgTime.GetValue() >= 10.0000
			Survival_ColdWarmingUpMessage.Show()
			Survival_LastWarmingUpMsgTime.SetValue(currentTime)
		endIf
	endIf
	Float newColdValue = DecrementNeed(currentNeedValue, amount, customMinValue, -1.00000)
	ApplyColdStage(newColdValue, lastValue)
	lastValue = newColdValue
endFunction

function ClearAttributePenalty(String asPenaltyAV)
	parent.ClearAttributePenalty(survival_globalfunctions.ColdHealthPenaltyAV())
endFunction

Float function GetMaxStageValue(Int maxStageId)
	if conditions.isBeastRace == 1 as Bool
		return survival_globalfunctions.ClampFloatTo(parent.GetMaxStageValue(maxStageId), 0.000000, needStage5Value - 1 as Float)
	else
		return parent.GetMaxStageValue(maxStageId)
	endIf
endFunction

function SetNeedStageValues()
	needStage1Value = 50.0000
	needStage2Value = 120.000
	needStage3Value = 300.000
	needStage4Value = 500.000
	needStage5Value = 800.000
endFunction

function RemoveAllNeedSpells()
	Int i = 0
	while i < needSpells.length
		PlayerRef.RemoveSpell(needSpells[i])
		i += 1
	endWhile
endFunction

function StartNeed()
	oldStage = 99
	parent.StartNeed()
	RegisterForSleep()
	PlayerAlias.ForceRefIfEmpty(PlayerRef as objectreference)
endFunction

function DisplayColdLevelTransitionMessage(Int aiColdLevel)
	Bool inOblivion = (Survival_PlayerInfoQuest as survival_playerinfo).CheckIsInPlaneOfOblivion(none, true, false)
	if !inOblivion
		if lastColdLevel < coldStage5ColdLevelMin && aiColdLevel >= coldStage5ColdLevelMin
			Survival_ColdConditionStage5.Show()
		elseIf lastColdLevel < coldStage4ColdLevelMin && aiColdLevel >= coldStage4ColdLevelMin
			Survival_ColdConditionStage4.Show()
		elseIf lastColdLevel < coldStage3ColdLevelMin && aiColdLevel >= coldStage3ColdLevelMin
			Survival_ColdConditionStage3.Show()
		elseIf lastColdLevel < coldStage2ColdLevelMin && aiColdLevel >= coldStage2ColdLevelMin
			Survival_ColdConditionStage2.Show()
		elseIf lastColdLevel < coldStage1ColdLevelMin && aiColdLevel >= coldStage1ColdLevelMin
			Survival_ColdConditionStage1.Show()
		elseIf lastColdLevel > coldLevelWarmArea && aiColdLevel == coldLevelWarmArea
			Survival_ColdConditionStage0.Show()
		endIf
	endIf
endFunction

function CheckIfMaxCold(Float afColdValue)
	if afColdValue >= NeedMaxValue.GetValue()
		survival_globalfunctions.SurvivalLogMessage("{{COLD}} Player at max cold, killing.")
		PlayerRef.Kill(none)
	endIf
endFunction

function PrecacheValues()
	cachedTimescale = TimeScale.GetValue()
	cachedColdLevelMult = Survival_ColdLevelMult.GetValue()
	cachedColdTargetGameHoursToNumb = Survival_ColdTargetGameHoursToNumb.GetValue()
	cachedNeedUpdateGameTimeInterval = NeedUpdateGameTimeInterval.GetValue()
	cachedColdResistMaxValue = Survival_ColdResistMaxValue.GetValue()
endFunction

Float function GetNeedRatePerTick()
	survival_globalfunctions.SurvivalLogMessage("{{COLD}} CalculateColdIncreasePerTick calculating...")
	Float c = cachedColdLevelMult * currentColdLevel as Float
	survival_globalfunctions.SurvivalLogMessage("{{COLD}}     coldLevelMult * currentColdLevel = " + c as String)
	Float targetRealTimeSecondsToNumb = cachedColdTargetGameHoursToNumb * 3600 as Float / cachedTimescale
	survival_globalfunctions.SurvivalLogMessage("{{COLD}}     targetRealTimeSecondsToNumb = " + targetRealTimeSecondsToNumb as String)
	Float coldPerSecond = c / targetRealTimeSecondsToNumb
	survival_globalfunctions.SurvivalLogMessage("{{COLD}}     coldPerSecond = " + coldPerSecond as String)
	Float updateGameTimeDeltaInRealSeconds = cachedNeedUpdateGameTimeInterval * 3600.00 / cachedTimescale
	survival_globalfunctions.SurvivalLogMessage("{{COLD}}     updateGameTimeDeltaInRealSeconds = " + updateGameTimeDeltaInRealSeconds as String)
	Float result = coldPerSecond * updateGameTimeDeltaInRealSeconds
	survival_globalfunctions.SurvivalLogMessage("{{COLD}}     result = " + result as String)
	return result
endFunction

Float function GetAmountToIncrementBy(Int ticks, Float rateReductionMultiplier)
	Float result = parent.GetAmountToIncrementBy(ticks, rateReductionMultiplier)
	race playerRace = PlayerRef.GetActorBase().GetRace()
	if Survival_ColdWeakRacesMajor.HasForm(playerRace as form)
		result *= 1 as Float + Survival_RacialBonusMajor.GetValue()
	endIf
	return result
endFunction

function ForceTemperatureUILastKnown()
	SetUITemperatureLevel(lastTemperatureLevel)
endFunction

Int function UpdateColdLevel()
	survival_globalfunctions.SurvivalLogMessage("{{COLD}} GetCurrentColdLevel calculating")
	Int coldLevel = 0
	if conditions.isSwimmingInFreezingWater
		return Survival_ColdLevelInFreezingWater.GetValueInt()
	endIf
	Int CurrentAreaType = (PlayerInfoAlias as survival_playerlocationinfo).GetCurrentAreaType()
	if CurrentAreaType == areaTypeChillyInterior
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}    In Interior (Cold)...")
		coldLevel += coldLevelFreezingArea
	elseIf CurrentAreaType == areaTypeInterior
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}    In Interior (Warm)...")
		coldLevel += coldLevelWarmArea
	elseIf CurrentAreaType == areaTypeWarm
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}    In Warm Area...")
		coldLevel += coldLevelWarmArea
	elseIf CurrentAreaType == areaTypeCool
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}    In Cool Area...")
		coldLevel += coldLevelCoolArea
	elseIf CurrentAreaType == areaTypeFreezing
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}    In Freezing Area...")
		coldLevel += coldLevelFreezingArea
	endIf
	Float currentHour = GameHour.GetValue()
	if CurrentAreaType > 0 && (currentHour < 7.00000 || currentHour > 19.0000)
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}    At night...")
		if CurrentAreaType == areaTypeWarm
			coldLevel += coldLevelWarmAreaNightMod
		elseIf CurrentAreaType == areaTypeCool
			coldLevel += coldLevelCoolAreaNightMod
		elseIf CurrentAreaType == areaTypeFreezing
			coldLevel += coldLevelFreezingAreaNightMod
		endIf
	else
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}    At day or inside...")
	endIf
	if CurrentAreaType > 0
		Weather theWeather
		if Weather.GetCurrentWeatherTransition() >= 0.500000
			theWeather = Weather.GetCurrentWeather()
		else
			theWeather = Weather.GetOutgoingWeather()
		endIf
		Int theWeatherClass = theWeather.GetClassification()
		if theWeatherClass == weatherClassSnow
			if Survival_AshWeather.HasForm(theWeather as form)
				
			elseIf Survival_BlizzardWeather.HasForm(theWeather as form)
				survival_globalfunctions.SurvivalLogMessage("{{COLD}}    In blizzard...")
				coldLevel += coldLevelBlizzardMod
			else
				survival_globalfunctions.SurvivalLogMessage("{{COLD}}    In snow...")
				coldLevel += coldLevelSnowMod
			endIf
		elseIf theWeatherClass == weatherClassRain
			survival_globalfunctions.SurvivalLogMessage("{{COLD}}    In rain...")
			coldLevel += coldLevelRainMod
		else
			survival_globalfunctions.SurvivalLogMessage("{{COLD}}    In clear weather...")
		endIf
	else
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}    Ignoring weather (inside)...")
	endIf
	survival_globalfunctions.SurvivalLogMessage("{{COLD}}    GetCurrentColdLevel = " + coldLevel as String)
	return coldLevel
endFunction

function ForceTemperatureUINearHeat()
	SetUITemperatureLevel(temperatureLevelNearHeat)
endFunction

function IncreaseCold(Float amount, Float customMaxValue)
	Float newColdValue
	if conditions.isInPlaneOfOblivion
		survival_globalfunctions.SurvivalLogMessage("{{COLD}} In Oblivion, skipping IncreaseCold.")
		return 
	endIf
	survival_globalfunctions.SurvivalLogMessage("{{COLD}} IncreaseCold Start")
	Float currentNeedValue = NeedValue.GetValue()
	Int newMaxStage = GetColdStageMaximum(currentColdLevel)
	if customMaxValue != -1.00000
		newColdValue = IncrementNeed(currentNeedValue, amount, customMaxValue)
	else
		Float newMaxValue = GetMaxStageValue(newMaxStage)
		newColdValue = IncrementNeed(currentNeedValue, amount, newMaxValue)
	endIf
	ApplyColdStage(newColdValue, lastValue)
	CheckIfMaxCold(newColdValue)
	lastValue = newColdValue
endFunction

function SetUITemperatureLevel(Int aiLevel)
	if !conditions.isInPlaneOfOblivion
		Survival_TemperatureLevel.SetValueInt(aiLevel)
	else
		Survival_TemperatureLevel.SetValueInt(temperatureLevelNeutral)
	endIf
endFunction

Int function GetColdStageMaximum(Int aiColdLevel)
	if aiColdLevel >= coldStage5ColdLevelMin
		return 5
	elseIf aiColdLevel >= coldStage4ColdLevelMin
		return 4
	elseIf aiColdLevel >= coldStage3ColdLevelMin
		return 3
	elseIf aiColdLevel >= coldStage2ColdLevelMin
		return 2
	elseIf aiColdLevel >= coldStage1ColdLevelMin
		return 1
	else
		return 0
	endIf
endFunction

function StopNeed()
	WaitForUnlock()
	parent.StopNeed()
	PlayerAlias.Clear()
endFunction

Int function GetTemperatureLevelForUI()
	survival_globalfunctions.SurvivalLogMessage("{{COLD}} Re-Evaluate UI Temperature")
	if conditions.isInPlaneOfOblivion
		return temperatureLevelNeutral
	endIf
	Int newMaxStage = GetColdStageMaximum(currentColdLevel)
	Float ceilingValue = GetMaxStageValue(newMaxStage)
	Float currentNeedValue = NeedValue.GetValue()
	if currentNeedValue > ceilingValue
		if PlayerRef.IsInCombat()
			return temperatureLevelNeutral
		else
			return temperatureLevelWarmArea
		endIf
	elseIf currentNeedValue == ceilingValue
		return temperatureLevelNeutral
	elseIf currentColdLevel == 0
		return temperatureLevelNeutral
	elseIf currentColdLevel >= coldStage5ColdLevelMin
		return temperatureLevelFreezingArea
	else
		return temperatureLevelColdArea
	endIf
endFunction

Float function IncrementNeedByTick(Float ceilingValue, Float rateReductionMultiplier)
	Float newNeedValue
	utility.Wait(1 as Float)
	survival_globalfunctions.SurvivalLogMessage("{{COLD}}     IncrementNeedByTick with rateReductionMultiplier = " + rateReductionMultiplier as String)
	Float currentNeedValue = NeedValue.GetValue()
	Float currentTimeInGameHours = utility.GetCurrentGameTime() * 24 as Float
	Float currentTimeInRealSeconds = utility.GetCurrentRealTime()
	if firstUpdate
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}     Ignoring the first update and storing update time.")
		lastTimeInGameHours = currentTimeInGameHours
		return currentNeedValue + 1 as Float
	endIf
	if IsTalkingToNPC()
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}     In a conversation; pausing need advancement and storing update time.")
		lastTimeInGameHours = currentTimeInGameHours
		return currentNeedValue
	endIf
	Int ticks = GetTicks(currentTimeInGameHours, lastTimeInGameHours)
	Float amountToIncrementBy = GetAmountToIncrementBy(ticks, rateReductionMultiplier)
	if currentNeedValue > ceilingValue
		if PlayerRef.IsInCombat()
			survival_globalfunctions.SurvivalLogMessage("{{COLD}}     In combat, don't warm up ambiently.")
			newNeedValue = currentNeedValue
		else
			Float decrementedValue = currentNeedValue - (coldToRestoreInWarmArea * ticks) as Float
			if decrementedValue < ceilingValue
				newNeedValue = DecrementNeed(currentNeedValue, currentNeedValue - ceilingValue, -1.00000, -1.00000)
			else
				newNeedValue = DecrementNeed(currentNeedValue, (coldToRestoreInWarmArea * ticks) as Float, -1.00000, -1.00000)
			endIf
		endIf
	elseIf currentNeedValue + amountToIncrementBy > ceilingValue
		newNeedValue = IncrementNeed(currentNeedValue, ceilingValue - currentNeedValue, -1.00000)
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}     Incrementing need by " + (ceilingValue - currentNeedValue) as String + " (reached cap)")
	else
		newNeedValue = IncrementNeed(currentNeedValue, amountToIncrementBy, -1.00000)
		survival_globalfunctions.SurvivalLogMessage("{{COLD}}     Incrementing need by " + amountToIncrementBy as String)
	endIf
	lastTimeInGameHours = currentTimeInGameHours
	survival_globalfunctions.SurvivalLogMessage("{{COLD}}     New value is " + newNeedValue as String)
	return newNeedValue
endFunction
