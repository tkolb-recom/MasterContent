Param
(
    [parameter(Mandatory=$false)]
    [Switch]
    $export,
    [parameter(Mandatory=$false)]
    [Switch]
    $import,
    [parameter(Mandatory=$false)]
    [String]
    $language = 'de',
	[parameter(Mandatory=$false)]
	[Switch]$includeInactiveAndLux
)

$ErrorActionPreference = "Stop"

Import-module -name $PSScriptRoot/memoqextractor.psm1 -force

$toExport = $true;
<#
if($export){
    $toExport = $true;
}elseif ($import){
    $toExport = $false;
}else{
    throw "you need to provide an option (-import or -export)"
}
#>

###############################################


if (-not ([System.Management.Automation.PSTypeName]'UtfStringWriter').Type)
{
    Add-Type -TypeDefinition @"
public sealed class UtfStringWriter : System.IO.StringWriter
{
    public override System.Text.Encoding Encoding { get { return System.Text.Encoding.GetEncoding("UTF-8"); } }
}
"@;
}

# create empty XML
$utfsw = New-Object UtfStringWriter
$xmlWriter = New-Object System.XML.XMLTextWriter($utfsw)
$xmlWriter.Formatting = 'Indented'
$xmlWriter.Indentation = 1
$xmlWriter.IndentChar = "`t"

$xmlWriter.WriteStartDocument()
$xmlWriter.WriteStartElement('TranslationDefinition')
$xmlWriter.WriteAttributeString('version', '1')

$xmlWriter.WriteEndElement() #TranslationDefinition

$xmlWriter.WriteEndDocument()
$xmlWriter.Flush()
$xmlWriter.Close()

$enc = [System.Text.Encoding]::GetEncoding("UTF-8");
[System.IO.File]::WriteAllText("$PSScriptRoot/TranslationDefinition.xml", $utfsw.toString(), $enc)

###############################################

$totalTime=[system.diagnostics.stopwatch]::StartNew();

$themenIds = @(10000, 10051, 10052, 10053, 10054, 10070, 10055, 10057, 10058, 10059, 10060, 10080, 10061, 10062, 10063, 10064, 10056, 10065, 10066, 10067, 10069, 10068, 9998)

$isActive = ' up.aktiv = 1 ';
$isActiveUebThem = 'ut.is_active = 1 ';

<#
if($includeInactiveAndLux){
#>
	$themenIds += 9000
<#	$isActive = ' 1=1 '
	$isActiveUebThem = ' 1=1 '
	
	write-host 'including all for lux relevant items'
}else{
	$themenIds = @(10051, 10052, 10053, 10054, 10070, 10055, 10057, 10058, 10059, 10060, 10080, 10061, 10062, 10063, 10064, 10056, 10065, 10066, 10067, 10069, 10068, 9998)
	write-host 'excluding inactive and lux relevant items'
}
#>

$themenToExport = ($themenIds -join ',')


write-host "* Creating MemoQ import file for table GR_BERUFSGRUPPE"
Invoke-MemoqExtractor -export:$toExport -language $language -file BERUFSGRUPPE  -table BERUFSGRUPPE

write-host "* Creating MemoQ import file for table GR_INTERVENTIONGROUP"
Invoke-MemoqExtractor -export:$toExport -language $language -file INTERVENTIONGROUP  -table INTERVENTIONGROUP

write-host "* Creating MemoQ import file for table GR_MEDISORTINGGROUP"
Invoke-MemoqExtractor -export:$toExport -language $language -file MEDISORTINGGROUP  -table MEDISORTINGGROUP

write-host "* Creating MemoQ import file for table ERSETZE_STRINGS_ERSATZ"
Invoke-MemoqExtractor -export:$toExport -language $language -file ERSETZE_STRINGS_ERSATZ  -table ERSETZE_STRINGS_ERSATZ

write-host "* Creating MemoQ import file for table ERSETZE_STRINGS_ZUERSETZEN"
Invoke-MemoqExtractor -export:$toExport -language $language -file ERSETZE_STRINGS_ZUERSETZEN  -table ERSETZE_STRINGS_ZUERSETZEN

write-host "* Creating MemoQ import file for table MICROSTD"
Invoke-MemoqExtractor -export:$toExport -language $language -file MICROSTD  -table MICROSTD


write-host "* Creating MemoQ import file for table MASSNAHM.TEXT.T"
Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT.All -sql ", prob_mas pm, ueb_prob up, ueb_them u where t.massnahme_id = pm.massnahme_id and pm.problem_id = up.problem_id and $isActive and up.ueberschrift_id = u.ueb_id  and u.thema_id in ($themenToExport)"  -table ACTION

write-host "* Creating MemoQ import file for table PROBLEM.DEF_TEXT.T"
Invoke-MemoqExtractor -export:$toExport -language $language -file DEF_TEXT.All -sql ", ueb_prob up, ueb_them u where t.problem_id = up.problem_id and $isActive and prob_def is not null and up.ueberschrift_id = u.ueb_id  and u.thema_id in ($themenToExport) and t.problem_id < 1000000"  -table PRO_DEF_F

if($import){
    # Die spalte ist identisch mit PRO_DEF_F, nur ohne Formatierung, deshalb wird die selbe datei für den Import verwendet wie PRO_DEF_F
    write-host "* Using MemoQ import file for table PROBLEM.DEF_TEXT.T"
    Invoke-MemoqExtractor -export:$toExport -language $language -file DEF_TEXT.All -sql ", ueb_prob up, ueb_them u where t.problem_id = up.problem_id and $isActive and prob_def is not null and up.ueberschrift_id = u.ueb_id  and u.thema_id in ($themenToExport)"  -table PRO_DEF
}

write-host "* Creating MemoQ import file for table DLGTEIL_KURZ.INHALT.All_EXPL"
Invoke-MemoqExtractor -export:$toExport -language $language -file INHALT.All_EXPL -sql " where t.dlgart_id in (1,2,3,4) and explanation is not null and exists (select 1 from dlg_kurz a where a.dlgteil_id = t.dlgteil_id)"  -table DLG_CONT_EXPL

write-host "* Creating MemoQ import file for table MASSNAHM.TEXT.All_HINT"
Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT.All_HINT -sql ", prob_mas pm, ueb_prob up, ueb_them u where t.hinweise is not null and show_hinweis = 1 and t.massnahme_id = pm.massnahme_id and pm.problem_id = up.problem_id and up.ueberschrift_id = u.ueb_id  and u.thema_id in ($themenToExport)"  -table ACTION_HINT

write-host "* Creating MemoQ import file for table DLGTEIL_KURZ.INHALT.T-I"
Invoke-MemoqExtractor -export:$toExport -language $language -file INHALT.All-I -sql ", dlg_kurz dk, massnahm m, prob_mas pm, ueb_prob up, ueb_them u where t.item_art <> 27 and t.dlgteil_id = dk.dlgteil_id  and  m.dlgbox_id = dk.dlg_id and m.massnahme_id = pm.massnahme_id and pm.problem_id = up.problem_id and $isActive and up.ueberschrift_id = u.ueb_id  and u.thema_id in ($themenToExport)"  -table DLG_CONT_MASSN

write-host "* Creating MemoQ import file for table DLGTEIL_KURZ.INHALT.T-U"
Invoke-MemoqExtractor -export:$toExport -language $language -file INHALT.All-U -sql ", dlg_kurz dk, problem p, ueb_prob up, ueb_them u where t.dlgteil_id = dk.dlgteil_id  and  p.u_dlg_id = dk.dlg_id and p.problem_id = up.problem_id and $isActive and up.ueberschrift_id = u.ueb_id  and u.thema_id in ($themenToExport) and t.DLGTEIL_ID < 1000000 "  -table DLG_CONT_PROB

write-host "* Creating MemoQ import file for table DLGTEIL_KURZ.INHALT.T-K"
Invoke-MemoqExtractor -export:$toExport -language $language -file INHALT.All-K -sql ", dlg_kurz dk, problem p, ueb_prob up, ueb_them u where t.dlgteil_id = dk.dlgteil_id  and  p.k_dlg_id = dk.dlg_id and p.problem_id = up.problem_id and $isActive and up.ueberschrift_id = u.ueb_id  and u.thema_id in ($themenToExport) and t.DLGTEIL_ID < 1000000 "  -table DLG_CONT_PROB

write-host "* Creating MemoQ import file for table DLGTEIL_KURZ.INHALT.T-R"
Invoke-MemoqExtractor -export:$toExport -language $language -file INHALT.All-R -sql ", dlg_kurz dk, problem p, ueb_prob up, ueb_them u where t.dlgteil_id = dk.dlgteil_id  and  p.r_dlg_id = dk.dlg_id and p.problem_id = up.problem_id and $isActive and up.ueberschrift_id = u.ueb_id  and u.thema_id in ($themenToExport) and t.DLGTEIL_ID < 1000000 "  -table DLG_CONT_PROB

write-host "* Creating MemoQ import file for table ZIEL.TEXT.T"
Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT.All -sql ", mas_ziel mz, prob_mas pm, ueb_prob up, ueb_them u where t.ziel_id = mz.ziel_id and mz.massnahme_id = pm.massnahme_id and pm.problem_id = up.problem_id and $isActive and up.ueberschrift_id = u.ueb_id  and u.thema_id in ($themenToExport)"  -table TARGET_TXT_0


write-host "* Creating MemoQ import file for table PROBLEM.TEXT.T"
Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT.All -sql ", ueb_prob up, ueb_them u where t.problem_id = up.problem_id and $isActive and up.ueberschrift_id = u.ueb_id  and u.thema_id in ($themenToExport) and t.problem_id < 1000000"  -table PRO_TEXT

#if($import){
    # Die spalte ist identisch, nur mit anderer Formatierung, deshalb wird die selbe datei für den Import verwendet wie PRO_TEXT
    write-host "* Using MemoQ import file for table PROBLEM.UEBERSCHRIFT.T"
    Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT.All -sql ", ueb_prob up, ueb_them u where t.problem_id = up.problem_id and $isActive and up.ueberschrift_id = u.ueb_id  and u.thema_id in ($themenToExport)"  -table PRO_HEADER
#} 

write-host "* Creating MemoQ import file for table UEBERSCH.UEBERSCHRIFT.T"
Invoke-MemoqExtractor -export:$toExport -language $language -file UEBERSCHRIFT.All -table HEADER

write-host "* Creating MemoQ import file for table THEMEN.THEMA.G7"
Invoke-MemoqExtractor -export:$toExport -language $language -file THEMA.G7 -sql "where gebiet_id = 7 "  -table THEME

write-host "* Creating MemoQ import file for table THEMEN.THEMA.G5"
Invoke-MemoqExtractor -export:$toExport -language $language -file THEMA.G5 -sql "where gebiet_id = 5 and thema_id in ($themenToExport)"  -table THEME

write-host "* Creating MemoQ import file for table THEMEN.THEMA.All"
#if($includeInactiveAndLux){
	Invoke-MemoqExtractor -export:$toExport -language $language -file THEMA.All  -table THEME
#} else {
	Invoke-MemoqExtractor -export:$toExport -language $language -file THEMA.All -sql "where gebiet_id <> 0 and thema_id <> 9000 " -table THEME
#}

write-host "* Creating MemoQ import file for table GR_SYSTEXT.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT -sql "where USEDTYP = 1"  -table GR_SYSTEXT

write-host "* Creating MemoQ import file for table GR_SYSTEXTLONG.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file LONGTEXT -sql "where USEDTYP = 2"  -table GR_SYSTEXTLONG


write-host "* Creating MemoQ import file for table MEDI_FORM.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT  -table MEDI_FORM
write-host "* Creating MemoQ import file for table MEDI_APPLART.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT  -table MEDI_APPL_ART
write-host "* Creating MemoQ import file for table DYNBAUM.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT  -table DYNBAUM
write-host "* Creating MemoQ import file for table STICHWORT.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT  -table STICHWORT
write-host "* Creating MemoQ import file for table PERS_FUNKTIONS.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT  -table PERS_FUNKTIONS
write-host "* Creating MemoQ import file for table PLANINTERVENTION.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT  -table PLANINTERVENTION

write-host "* Creating MemoQ import file for table WUNDART.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file WUNDART.TEXT -sql "where RTS_DN like '#11.#1.#2.#1.%'" -table RTS_KEY

write-host "* Creating MemoQ import file for table WUNDEINSCH.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file WUNDEINSCH.TEXT -sql "where t.RTS_ID in (select rts_id from rts_keys where RTS_DN like '#11.#1.#2.#2.%')"  -table RTS_KEY_VAL

write-host "* Creating MemoQ import file for table WUNDEINSCH.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file WUNDEINSCH.TEXT -sql "where RTS_DN like '#11.#1.#2.#2.%'" -table RTS_KEY

write-host "* Creating MemoQ import file for table WUNDBEH.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file WUNDBEH.TEXT -sql "where t.RTS_ID in (select rts_id from rts_keys where RTS_DN like '#11.#1.#2.#3.%')"  -table RTS_KEY_VAL

write-host "* Creating MemoQ import file for table WUNDBEH.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file WUNDBEH.TEXT -sql "where RTS_DN like '#11.#1.#2.#3.%'"  -table RTS_KEY

write-host "* Creating MemoQ import file for table WUNDATTR.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file WUNDATTR.TEXT -sql "where t.RTS_ID in (select rts_id from rts_keys where RTS_DN like '#11.#1.#2.#4.%')"  -table RTS_KEY_VAL

write-host "* Creating MemoQ import file for table WUNDATTR.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file WUNDATTR.TEXT -sql "where RTS_DN like '#11.#1.#2.#4.%'"  -table RTS_KEY

write-host "* Creating MemoQ import file for table ANAMNESE_CONTENT Values"
Invoke-MemoqExtractor -export:$toExport -language $language -file ANAMNESE_CONTENT -sql " where t.RTS_ID in (select rts_id from rts_keys where EDITOR > 0) "  -table RTS_KEY_VAL

write-host "* Creating MemoQ import file for table ANAMNESE_CONTENT Keys"
Invoke-MemoqExtractor -export:$toExport -language $language -file ANAMNESE_CONTENT -sql " where EDITOR > 0 "  -table RTS_KEY

write-host "* Creating MemoQ import file for table GR_INTERATTR kurz und lang"
Invoke-MemoqExtractor -export:$toExport -language $language -file GR_INTERATTR.KURZ_LANG  -table INTERVATTR

write-host "* Creating MemoQ import file for table SCALEN"
Invoke-MemoqExtractor -export:$toExport -language $language -file SCALEN  -table SCALEN

write-host "* Creating MemoQ import file for table GR_SCALEN_ELEMENT"
Invoke-MemoqExtractor -export:$toExport -language $language -file GR_SCALEN_ELEMENT  -table SCALENELEMENT

write-host "* Creating MemoQ import file for table SCALENGROUP"
Invoke-MemoqExtractor -export:$toExport -language $language -file GR_SCALEN_GROUP  -table SCALENGROUP

write-host "* Creating MemoQ import file for table SCALENSECTION"
Invoke-MemoqExtractor -export:$toExport -language $language -file GR_SCALEN_SECTION  -table SCALENSECTION

write-host "* Creating MemoQ import file for table SPEZIALISIERUNG"
Invoke-MemoqExtractor -export:$toExport -language $language -file SPEZIALISIERUNG  -table SPEZIALISIERUNG

write-host "* Creating MemoQ import file for table BERICHTSART"
Invoke-MemoqExtractor -export:$toExport -language $language -file GR_BERICHTSART -table BERICHTSART

write-host "* Creating MemoQ import file for table WEITERBUILDUNG"
Invoke-MemoqExtractor -export:$toExport -language $language -file WEITERBUILDUNG -table WEITERBUILDUNG

write-host "* Creating MemoQ import file for table PFLGMITB"
Invoke-MemoqExtractor -export:$toExport -language $language -file PFLGMITB  -table PFLGMITB

write-host "* Creating MemoQ import file for table SCALEEINST"
Invoke-MemoqExtractor -export:$toExport -language $language -file SCALEEINST  -table SCALEEINST

write-host "* Creating MemoQ import file for table GR_SYSLISTTEXT.TEXT"
Invoke-MemoqExtractor -export:$toExport -language $language -file TEXT  -table GR_SYSLISTTEXT

write-host "* Creating MemoQ import file for table AUFGABEN_TEXTE"
Invoke-MemoqExtractor -export:$toExport -language $language -file AUFGABEN_TEXTE  -table AUFGABEN_TEXTE

write-host "* Creating MemoQ import file for table GR_REPORTS"
Invoke-MemoqExtractor -export:$toExport -language $language -file GR_REPORTS  -table GR_REPORTS

write-host "* Creating MemoQ import file for table GR_REPORTCOL"
Invoke-MemoqExtractor -export:$toExport -language $language -file GR_REPORTCOL  -table GR_REPORTCOL

write-host "* Creating MemoQ import file for table MEDI_EINHEIT"
Invoke-MemoqExtractor -export:$toExport -language $language -file MEDI_EINHEIT  -table MEDI_EINHEIT

write-host "* Creating MemoQ import file for table GR_PL_INT_WERT LLIMIT und ULIMIT"
Invoke-MemoqExtractor -export:$toExport -language $language -file GR_PL_INT_WERT  -table GR_PL_INT_WERT

write-host "* Creating MemoQ import file for table ENP_CLUSTER"
Invoke-MemoqExtractor -export:$toExport -language $language -file ENP_CLUSTER -sql " where type_id = 9 "  -table ENP_CLUSTER

write-host "* Creating MemoQ import file for table DOKUMENTATION_ART"
Invoke-MemoqExtractor -export:$toExport -language $language -file DOKUMENTATION_ART  -table DOKUMENTATIONART

write-host "* Creating MemoQ import file for table GEBIET"
Invoke-MemoqExtractor -export:$toExport -language $language -file GEBIET  -table GEBIET

write-host "* Creating MemoQ import file for table MEDI_DAF_MED"
Invoke-MemoqExtractor -export:$toExport -language $language -file MEDI_DAF_MED  -table MEDI_DAF_MED

write-host "* Creating MemoQ import file for table PFLGMITLEL"
Invoke-MemoqExtractor -export:$toExport -language $language -file PFLGMITLEL  -table PFLGMITLEL

$totalTime.Stop();

write-host "run took $($totalTime.Elapsed.TotalSeconds) seconds"
