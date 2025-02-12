# export colmun values regarding the file TranslationDefinition.xml


if (-not ([System.Management.Automation.PSTypeName]'UtfStringWriter').Type)
{
    Add-Type -TypeDefinition @"
public sealed class UtfStringWriter : System.IO.StringWriter
{
    public override System.Text.Encoding Encoding { get { return System.Text.Encoding.GetEncoding("UTF-8"); } }
}
"@;
}


$global:connectionString = "Data Source=vidab-2;Database=MasterContent;User ID=sa;Password=dev_sa;"


function getPrimaryKeys {
    param(
        [string] $tableName
    )

    $command =
"SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_SCHEMA + '.' + QUOTENAME(CONSTRAINT_NAME)), 'IsPrimaryKey') = 1
AND TABLE_NAME = '$tableName';"

    $row = Invoke-Sqlcmd -ConnectionString $global:connectionString -Query $command
    $columns = $row.ItemArray

    if ($columns.Count -eq 0)
    {
        return @()
    }

    return $columns
}

function getColumnType {
    param (
        [string] $tableName
    )

    $command = 
"SELECT COLUMN_NAME as name, DATA_TYPE as type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '$tableName';"
    
    $columns = Invoke-Sqlcmd -ConnectionString $global:connectionString -Query $command

    $hash = @{}
    foreach ($col in $columns)
    {
        $hash.add($col['name'], $col['type'])
    }
    return $hash
}


function getColumnValues {
    param (
        [string[]] $columns
    )

    $columnsText = $columns -join ', '

    $command = "SELECT $columnsText FROM $tableName;"
    Write-Host $command
    
    $values = Invoke-Sqlcmd -ConnectionString $global:connectionString -Query $command
    return $values
}

function processTables {
    param(
        [System.Xml.XmlWriter] $xmlWriter
    )

    $source = [xml](get-content "$PSScriptRoot/TranslationDefinition.xml")

    $tables = $source.SelectNodes('/TranslationDefinition/Table')

    foreach ($table in $tables)
    {
        $tableName = $table.name

        $keys = $table.SelectNodes('Key') | ForEach-Object{$_.name}
        $primaryKeys = getPrimaryKeys $tableName

        Write-Host "Table: $tableName ($keys)"

        if ($keys.Count -gt 0)
        {
            $xmlWriter.WriteStartElement('Table')
            $xmlWriter.WriteAttributeString('name', $tableName)

            foreach ($key in $keys)
            {
                $xmlWriter.WriteStartElement("KeyDef")
                $xmlWriter.WriteAttributeString('name', $key)

                $xmlWriter.WriteAttributeString('primaryKey', ($primaryKeys -contains $key))

                $xmlWriter.WriteEndElement()    #KeyDef
            }

            $columns = $table.SelectNodes('Column') 
            $colTypes = getColumnType $tableName             
            $textColumns = @()

            foreach ($col in $columns)
            {
                $xmlWriter.WriteStartElement("Column")

                $name = $col.name
                $type = $colTypes[$name]
                $xmlWriter.WriteAttributeString('name', $name)
                $xmlWriter.WriteAttributeString('type', $type)

                $xmlWriter.WriteEndElement()    #Column

                if (-not $textColumns -contains $name)
                {
                    $textColumns += $name
                }
            }

            Write-Host $textColumns

            $data = getColumnValues $($keys; $textColumns)

            foreach ($d in $data)
            {
                $xmlWriter.WriteStartElement("Row")

                foreach ($k in $keys)
                {
                    $xmlWriter.WriteStartElement("Key")
                    $xmlWriter.WriteAttributeString('name', $k)
                    $xmlWriter.WriteAttributeString('value', $d[$k])
                    $xmlWriter.WriteEndElement()    #Key
                }

                foreach ($t in $textColumns)
                {
                    $xmlWriter.WriteStartElement("Value")
                    $xmlWriter.WriteAttributeString('column', $t)
                    $value = $d[$t]
                    if ($null -eq $value)
                    {
                        $xmlWriter.WriteAttributeString('isnull', 'true')
                    } 
                    else 
                    {
                        # no one knows what content is in there, so use mark data not parsable
                        $xmlWriter.WriteCData($d[$t])
                    }
                    $xmlWriter.WriteEndElement()    #Value
                }

                $xmlWriter.WriteEndElement()    #Row
            }

            $xmlWriter.WriteEndElement() #Table
        } 

        if ($primaryKeys.Count -gt 0)
        {
            Write-Host "----- ERROR: NO PK -----"
        }

        Write-Host
    }

    Write-Host
}


$utfsw = New-Object UtfStringWriter
$xmlWriter = New-Object System.XML.XMLTextWriter($utfsw)
$xmlWriter.Formatting = 'Indented'
$xmlWriter.Indentation = 2
$xmlWriter.IndentChar = " "

$xmlWriter.WriteStartDocument()
$xmlWriter.WriteStartElement('TranslationContent')
$xmlWriter.WriteAttributeString('version', '1')

processTables $xmlWriter

$xmlWriter.WriteEndElement() #TranslationContent


$xmlWriter.WriteEndDocument()
$xmlWriter.Flush()
$xmlWriter.Close()

$enc = [System.Text.Encoding]::GetEncoding("UTF-8");
[System.IO.File]::WriteAllText("$PSScriptRoot/TranslationContent.xml", $utfsw.toString(), $enc)