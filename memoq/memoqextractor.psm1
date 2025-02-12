function New-Definition{
    Param
    (
         [Parameter(Mandatory=$true)]
         [string]$table,
         [Parameter(Mandatory=$true)]
         $keys,
         [Parameter(Mandatory=$true)]
         $field,
         [Parameter(Mandatory=$false)]
         [Switch]$rtf,
         [Parameter(Mandatory=$false)]
         [Switch]$olli,
         [Parameter(Mandatory=$false)]
         [Switch]$rts10,
         [Parameter(Mandatory=$false)]
         [Switch]$rts7,
         [Parameter(Mandatory=$false)]
         [string]$explain = $null,
         [Parameter(Mandatory=$false)]
         [string]$orderby = $null,
         [Parameter(Mandatory=$false)]
         [string]$typeOverride
    )

    $type = 'plain';
    if($rtf){
        $type = 'rtf';
    }elseif($olli){
        $type = 'obscure' # 'olli';
    }elseif($rts10){
        $type = 'rts@10';
    }elseif($rts7){
        $type = 'rts@7';
    }

    $keycols = (($keys) -join ',');
    #$fields = (($field) -join ',');

    #$types =  (((1..$field.length) | %{ return $type}) -join ',')

    if($typeOverride){
        $types = $typeOverride
    }
    
    if(-not $orderby){
        $orderby = $keycols
    }

    $def = @{
        table = $table
        keycols = $keys #$keycols
        field = $field #$fields
        type = $type #$types
        explain = $explain
        orderby = $orderby
    }
    return $def
}

$lookup = @{
    PRO_DEF = New-Definition -table 'PROBLEM' -keys 'PROBLEM_ID' -field 'PROB_DEF_F' -rtf -explain "ueberschrift"
    PRO_DEF_F = New-Definition -table 'PROBLEM' -keys 'PROBLEM_ID' -field 'PROB_DEF' -explain "ueberschrift"
    DLG_CONT_EXPL = New-Definition -table 'DLGTEIL_KURZ' -keys 'DLGTEIL_ID' -field 'EXPLANATION' -explain 'inhalt'
    ACTION_HINT = New-Definition -table 'MASSNAHM' -keys 'MASSNAHME_ID' -field 'HINWEISE' -rtf -explain 'TEXT'
    DLG_CONT_PROB = New-Definition -table 'DLGTEIL_KURZ' -keys 'DLGTEIL_ID' -field 'INHALT' -explain 'p.text'
    DLG_CONT_MASSN = New-Definition -table 'DLGTEIL_KURZ' -keys 'DLGTEIL_ID' -field 'INHALT' -explain 'm.text'
    TARGET_TXT_0 = New-Definition -table 'ZIEL' -keys 'ZIEL_ID' -field 'TEXT' -rtf
    ACTION = New-Definition -table 'MASSNAHM' -keys 'MASSNAHME_ID' -field 'TEXT' -rtf -explain "HINWEISE"
    PRO_TEXT = New-Definition -table 'PROBLEM' -keys 'PROBLEM_ID' -field 'TEXT' -rtf
    PRO_HEADER = New-Definition -table 'PROBLEM' -keys 'PROBLEM_ID' -field 'UEBERSCHRIFT' -olli
    HEADER = New-Definition -table 'UEBERSCH' -keys 'UEBERSCHRIFT_ID' -field 'UEBERSCHRIFT' -olli
    THEME = New-Definition -table 'THEMEN' -keys 'THEMA_ID' -field 'THEMA' -olli
    GR_SYSTEXT = New-Definition -table 'GR_SYSTEXT' -keys 'TEXT_ID' -field 'TEXT'
    GR_SYSTEXTLONG = New-Definition -table 'GR_SYSTEXT' -keys 'TEXT_ID' -field 'LONGTEXT'
    MEDI_FORM = New-Definition -table 'MEDI_FORM' -keys 'ID' -field 'BEZEICHNUNG'
    MEDI_APPL_ART = New-Definition -table 'MEDI_APPLART' -keys 'ID' -field 'BEZEICHNUNG'
    DYNBAUM = New-Definition -table 'DYNBAUM' -keys 'DYB_ID' -field 'DYB_KNTXT'
    STICHWORT = New-Definition -table 'STICHWORT' -keys 'ST_WORT_ID' -field 'STICHWORT'
    PERS_FUNKTIONS = New-Definition -table 'PERS_FUNKTIONS' -keys 'FUNK_ID' -field 'FUNKL_LBZG'
    PLANINTERVENTION = New-Definition -table 'PLANINTERVENTION' -keys 'INTERVENT_ID' -field 'INTERVENTION'
    RTS_KEY = New-Definition -table 'RTS_KEYS' -keys 'RTS_ID' -field 'RTS_TEXT'
    RTS_KEY_RTS = New-Definition -table 'RTS_KEYS' -keys 'RTS_ID' -field 'XMLDATA','XMLDATA' -typeOverride 'rts@7,rts@10'
    RTS_KEY_VAL = New-Definition -table 'RTS_KEY_VAL' -keys 'RTS_ID','KEY_IDENT' -field 'KEY_TEXT' -explain '(select rts_text from rts_keys where rts_id = t.rts_id)'
    INTERVATTR = New-Definition -table 'gr_intervattr' -keys 'ID' -field 'kurzbez','bezeichnung'
    SCALEN = New-Definition -table 'scalen' -keys 'scalen_ID' -field 'bezeichg'
    SCALENELEMENT = New-Definition -table 'gr_scalen_element' -keys 'scalen_ID','group_id','str' -field 'text' -explain "(select first 1 (trim(s.BEZEICHG) || ', ' || trim(sg.TEXT)) from GR_SCALEN_GROUP sg join SCALEN s on (sg.SCALEN_ID = s.SCALEN_ID) where s.scalen_ID = t.scalen_ID and sg.group_id = t.group_id)"
    SCALENGROUP = New-Definition -table 'gr_scalen_group' -keys 'scalen_ID','section_id','group_id','sorting' -field 'text' -explain "(select first 1 (trim(s.BEZEICHG) || ', ' || trim(ss.NAME)) from GR_SCALEN_SECTION ss join SCALEN s on (ss.SCALEN_ID = s.SCALEN_ID) where s.scalen_ID = t.scalen_ID and ss.section_id = t.section_id)"
    SCALENSECTION = New-Definition -table 'gr_scalen_section' -keys 'scalen_ID','section_id' -field 'text' -explain '(select bezeichg from SCALEN where scalen_id = t.scalen_id)'
    SPEZIALISIERUNG = New-Definition -table 'spezialisierung' -keys 'id' -field 'description'
    BERICHTSART = New-Definition -table 'gr_berichtart' -keys 'berartid' -field 'bez_kurz','bezeichnung'
    WEITERBUILDUNG = New-Definition -table 'weiterbuildung' -keys 'id' -field 'description'
    PFLGMITB = New-Definition -table 'PFLGMITB' -keys 'PFLGMIT_beridx' -field 'PFLGMIT_ber'
    SCALEEINST = New-Definition -table 'scal_einst' -keys 'scalen_id','einstuf_id' -field 'text' -explain '(select bezeichg from SCALEN where scalen_id = t.scalen_id)'
    GR_SYSLISTTEXT = New-Definition -table 'GR_SYSLISTTEXT' -keys 'id' -field 'TEXT'
    AUFGABEN_TEXTE = New-Definition -table 'aufgaben_texte' -keys 'gruppe','wert' -field 'TEXT'
    GR_REPORTS = New-Definition -table 'GR_REPORTS' -keys 'report_id' -field 'reportname'
    GR_REPORTCOL = New-Definition -table 'GR_REPORTCOL' -keys 'id' -field 'COLNAME'
    MEDI_EINHEIT = New-Definition -table 'Medi_Einheit' -keys 'id' -field 'bzg','bmp_name'
    GR_PL_INT_WERT = New-Definition -table 'GR_PL_INT_WERT' -keys 'intervent_id','v_alter' -field 'l_limit_inf','u_limit_inf'
    ENP_CLUSTER = New-Definition -table 'ENP_CLUSTER' -keys 'cluster_id' -field 'text'
    DOKUMENTATIONART = New-Definition -table 'DOKUMENTATION_ART' -keys 'ID' -field 'BEZEICHNUNG'
    GEBIET = New-Definition -table 'GEBIET' -keys 'GEBIET_ID' -field 'GEBIET'
    MEDI_DAF_MED = New-Definition -table 'MEDI_DAF_MED' -keys 'KEY_DAF' -field 'NAME','bmp_shortname'
    BERUFSGRUPPE = New-Definition -table 'GR_BERUFSGRUPPE' -keys 'ID' -field 'BEZEICHNUNG'
    INTERVENTIONGROUP = New-Definition -table 'GR_INTERVENTIONGROUP' -keys 'ID' -field 'GroupName'
    MEDISORTINGGROUP = New-Definition -table 'GR_MEDISORTINGGROUP' -keys 'ID' -field 'GroupName'
    ERSETZE_STRINGS_ERSATZ = New-Definition -table 'ERSETZE_STRINGS' -keys 'ERSATZ_ID' -field 'ERSATZ'
    ERSETZE_STRINGS_ZUERSETZEN = New-Definition -table 'ERSETZE_STRINGS' -keys 'ERSATZ_ID' -field 'ZUERSETZEN'
    MICROSTD = New-Definition -table 'MICROSTD' -keys 'MICRO_ID' -field 'MICRO_DEF'
    PFLGMITLEL = New-Definition -table 'PFLGMITLEL' -keys 'PFLGMIT_IDX' -field 'PFLGMIT_BEZ'
};

function Invoke-MemoqExtractor{
    Param
    (
         [Parameter(Mandatory=$true)]
         [Switch]$export,
         [Parameter(Mandatory=$true)]
         [string]$file,
         [Parameter(Mandatory=$false)]
         [string]$sql = $null,
         [parameter(Mandatory = $true)]
         [string]$table,
         [Parameter(Mandatory=$false)]
         [string]$language
    )

    $filepath = '';
    $postfix = '';
    if(-not $export){
        if(-not $language){
            throw "you need to pass in a language";
        }

        $filepath = '';
        $postfix = "_$language";
    }

    $tableDef = $lookup[$table]

    if(-not $tableDef){
        throw "Unknown tabledata for '$table'"
    }

    $tablename = $tableDef.table.ToUpper()
    $keycolumn = "`"$($tableDef.keycols)`""

    $fieldToExport = "`"$($tableDef.field)`""
    $typeOfField = "`"$($tableDef.type)`""

    $explain = $tableDef.explain
    $orderBy = $tableDef.orderby

    if(-not $explain){
        $explain = '""'
    }
    
    $sqlwhere = "`"$sql order by $orderby`""

<#    
    $outfilename = "$($env:INEXTR_OUTFILENAME)\$($filepath)\$($tablename).$($file)$($postfix).xlsx";
      
    if((-not $export) -and !(Test-Path $outfilename)){
        write-host "could not find file '$outfilename' to import, skip"
        return;
    }

    write-host "Call $exePath/tool_i18nextractor.exe"

    & "$exePath/tool_i18nextractor.exe" -d Recom.Core.Database.FirebirdDatabase -m $mode -c $datasource -o $outfilename -k $keycolumn -t $tablename -f $fieldToExport -a $typeOfField -w $sqlwhere -e $explain
    if($LastExitCode -ne 0){
        throw "error in execution of i18ntool"
    }
#>  

    $xml = [xml](Get-Content -Path "$PSScriptRoot/TranslationDefinition.xml")

    $parent = $xml.TranslationDefinition;

    $tableNode = $parent.SelectSingleNode("Table[@name='$tablename']")
    if ($null -eq $tableNode)
    {   
        $tableNode = $xml.CreateElement("Table")
        $tableNode.SetAttribute("name", $tablename)
        $parent.AppendChild($tableNode)

        foreach ($k in $tableDef.keycols)
        {
            $keyNode = $xml.CreateElement("Key")
            $keyNode.SetAttribute("name", $k)
            $tableNode.AppendChild($keyNode) 
        }

        if ($tableDef.orderby)
        {
            $orderNode = $xml.CreateElement("OrderBy")
            $orderNode.InnerText = $tableDef.orderby
            $tableNode.AppendChild($orderNode)
        }

        if ($tableDef.explain)
        {
            $explainNode = $xml.CreateElement("Explain")
            $cdata = $xml.CreateCDataSection($tableDef.explain)
            $explainNode.AppendChild($cdata)
            $tableNode.AppendChild($explainNode)
        }
    }

    foreach ($c in $tableDef.field)
    {
        $colNode = $xml.CreateElement("Column")
        $colNode.SetAttribute("name", $c)
        $colNode.SetAttribute("type", $tableDef.type)

        if ($sql)
        {
            $whereNode = $xml.CreateElement("Where")
            $cdata = $xml.CreateCDataSection($sql)
            $whereNode.AppendChild($cdata)
            #$whereNode.InnerText = $sql
            $colNode.AppendChild($whereNode)
        }

        $tableNode.AppendChild($colNode) 
    }

    $xml.Save("$PSScriptRoot/TranslationDefinition.xml")

    write-host ""
}


export-modulemember -function Invoke-MemoqExtractor