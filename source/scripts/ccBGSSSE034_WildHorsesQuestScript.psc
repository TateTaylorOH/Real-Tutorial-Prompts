scriptName ccBGSSSE034_WildHorsesQuestScript extends Quest
{Main script that handles quest, tutorial, horse renaming}

globalvariable property TamedHorseCounter auto
referencealias[] property ArrayHorseNames auto
keyword property SpecialHorseKeyword auto
Quest property ccBGSSSE034_Misc_Horse01_Chestnut auto
Quest property ccBGSSSE034_Misc_Horse02_Black auto
referencealias property WildHorseNotes auto
message property MessageHorseNamed auto
message property ccBGSSSE034_MessageMustBeTamedRename auto
referencealias property NewHorseName auto
Quest property ccBGSSSE034_Misc_Horse06_WhiteSpotted auto
faction property PlayerFaction auto
Quest property ccBGSSSE034_Misc_Horse04_Pale auto
Quest property ccBGSSSE034_Misc_Horse03_GreyBlack auto
faction property PlayerHorseFaction auto
message property HelpWildHorseTutorial auto
Quest property ccBGSSSE034_Misc_Horse05_RedBrown auto
Quest property ccBGSSSE034_Misc_Horse07_BrownSpotted auto
referencealias property WildHorseMap auto
referencealias property StablesPlayersHorse auto
referencealias[] property WildHorseAliases auto

Bool HasTutorialDisplayed = false

ccbgssse034_wildhorserefaliasscript function GetHorseRefAlias(actor HorseActorRef)
{Loops over the horse ref aliases to match the supplied actor ref}
	ccbgssse034_wildhorserefaliasscript thisHorseAlias
	Int i = 0
	while i <= WildHorseAliases.length - 1
		if HorseActorRef == WildHorseAliases[i].GetActorReference()
			thisHorseAlias = WildHorseAliases[i] as ccbgssse034_wildhorserefaliasscript
		endIf
		i += 1
	endWhile
	return thisHorseAlias
endFunction

function ShowTutorial()
	if !HasTutorialDisplayed
		HasTutorialDisplayed = true
		HelpWildHorseTutorial.Show()
	endIf
endFunction

function RenameLastRiddenHorse()
{Forces the horse into a random unused RefAlias containing name data}
	actor HorseToRename = game.GetPlayersLastRiddenHorse()
	if HorseToRename != none && HorseToRename.HasKeyword(SpecialHorseKeyword) && HorseToRename.IsInFaction(PlayerHorseFaction)
		ccbgssse034_wildhorserefaliasscript HorseRefAlias = GetHorseRefAlias(HorseToRename)
		if HorseRefAlias
			Int i
			Bool bFoundAvailableName = false
			Int MaxTries = 50
			Int NameAttempCounter = 0
			while bFoundAvailableName == false && NameAttempCounter < MaxTries
				i = utility.RandomInt(0, ArrayHorseNames.length - 1)
				if ArrayHorseNames[i].GetActorReference()
					NameAttempCounter += 1
				else
					bFoundAvailableName = true
				endIf
			endWhile
			if bFoundAvailableName
				if HorseRefAlias.CurrentName
					HorseRefAlias.CurrentName.Clear()
				endIf
				ArrayHorseNames[i].ForceRefTo(HorseToRename as objectreference)
				HorseRefAlias.CurrentName = ArrayHorseNames[i]
				MessageHorseNamed.Show()
			endIf
		endIf
	else
		ccBGSSSE034_MessageMustBeTamedRename.Show()
	endIf
endFunction

function UpdateTamedHorseCount()
{increments global value displayed in quest objective}
	ModObjectiveGlobal(1 as Float, TamedHorseCounter, 10, -1.00000, true, true, true)
	if TamedHorseCounter.GetValueInt() == 7
		SetStage(20)
	endIf
endFunction

function CheckAndClearQuestItems()
{Since each horse has a separate misc quest, we have to check as each completes to ensure all are finished before we clear the map and journal as quest items.}
	if ccBGSSSE034_Misc_Horse01_Chestnut.IsStageDone(0) && ccBGSSSE034_Misc_Horse02_Black.IsStageDone(0) && ccBGSSSE034_Misc_Horse03_GreyBlack.IsStageDone(0) && ccBGSSSE034_Misc_Horse04_Pale.IsStageDone(0) && ccBGSSSE034_Misc_Horse05_RedBrown.IsStageDone(0) && ccBGSSSE034_Misc_Horse06_WhiteSpotted.IsStageDone(0) && ccBGSSSE034_Misc_Horse07_BrownSpotted.IsStageDone(0)
		WildHorseMap.Clear()
		WildHorseNotes.Clear()
	endIf
endFunction
