# convert 'dbupdate_*.xml'
# groups: enp icd10 ruleengine symx pkms
# implicit: basics (w/o group)
# future?: initial medi (w/o group)

if (-not ([System.Management.Automation.PSTypeName]'UtfStringWriter').Type)
{
    Add-Type -TypeDefinition @"
public sealed class UtfStringWriter : System.IO.StringWriter
{
    public override System.Text.Encoding Encoding { get { return System.Text.Encoding.GetEncoding("UTF-8"); } }
}
"@;
}

$utfsw = New-Object UtfStringWriter
$xmlWriter = New-Object System.XML.XMLTextWriter($utfsw)
$xmlWriter.Formatting = 'Indented'
$xmlWriter.Indentation = 1
$xmlWriter.IndentChar = "`t"

$xmlWriter.WriteStartDocument()
$xmlWriter.WriteStartElement('ContentUpdate')
$xmlWriter.WriteAttributeString('version', '1')


function copyNode {
    param(
        [System.Xml.XmlNode]$table,
        [System.Xml.XmlWriter]$xmlWriter,
        [string]$fromname,
        [string]$toname = $null,
        [bool]$cdata = $false
    )

    if (-not $toname)
    {
        $toname = $fromname
    }

    $node = $table.Item($fromname);
    if (-not $null -eq $node)
    {
        if ($cdata)
        {
            $xmlWriter.WriteStartElement($toname)
            $xmlWriter.WriteCData($node.InnerText)
            $xmlWriter.WriteEndElement()        
        } 
        else 
        {
            $xmlWriter.WriteElementString($toname, $node.InnerText)                
        }        
    }
}

function writeTable {
    param(
        [System.Xml.XmlNode]$table,
        [System.Xml.XmlWriter]$xmlWriter
    )
    
    $tableName = $table.'#text'.toUpper();

    Write-Host "Table: $tableName"
    
    $xmlWriter.WriteStartElement('Table')
    $xmlWriter.WriteAttributeString('name', $tableName)

    copyNode $table $xmlWriter 'order' 'Order'
    copyNode $table $xmlWriter 'limit' 'Where' $true

    # to be clarified
    copyNode $table $xmlWriter 'ignore' 
    copyNode $table $xmlWriter 'alternateDelete' -cdata $true
    copyNode $table $xmlWriter 'beforeSql' -cdata $true
    
    $xmlWriter.WriteEndElement() #Table
}


function writeGroup {
    param(
        [xml]$source,
        [string]$targetGroup,
        [System.Xml.XmlWriter]$xmlWriter
    )

    Write-Host "`nGroup: $targetGroup`n"

    $xmlWriter.WriteComment("Content definitions for group '$targetGroup'")
    $xmlWriter.WriteStartElement('Group')
    $xmlWriter.WriteAttributeString('name', $targetGroup)

    $nodes = $source.SelectNodes("/dbupdate/content/table")
    foreach($table in $nodes)
    {
        $group = $table.Item('group');
        $groupName = $group.InnerText;
        
        if ($targetGroup -eq 'initial' -and $null -eq $group)   
        {
            writeTable $table $xmlWriter
        }
    
        if ($targetGroup -eq 'medi' -and $null -eq $group)   
        {
            writeTable $table $xmlWriter
        }

        if ($targetGroup -eq 'basics' -and $null -eq $group)   
        {
            writeTable $table $xmlWriter
        }

        if ($targetGroup -eq $groupName)
        {
            writeTable $table $xmlWriter
        }
    }
    
    $xmlWriter.WriteEndElement() #Group
}

$source = [xml](get-content "$pwd\dbupdate_initial.xml")
writeGroup $source "initial" $xmlWriter

$source = [xml](get-content "$pwd\dbupdate_master.xml")
writeGroup $source "basics" $xmlWriter
writeGroup $source "icd10" $xmlWriter
writeGroup $source "pkms" $xmlWriter
writeGroup $source "ruleengine" $xmlWriter

$source = [xml](get-content "$pwd\dbupdate_medi.xml")
writeGroup $source "medi" $xmlWriter


$xmlWriter.WriteEndElement() #ContentUpdate


$xmlWriter.WriteEndDocument()
$xmlWriter.Flush()
$xmlWriter.Close()

$enc = [System.Text.Encoding]::GetEncoding("UTF-8");
[System.IO.File]::WriteAllText("$pwd\ContentDefinition.xml", $utfsw.toString(), $enc)