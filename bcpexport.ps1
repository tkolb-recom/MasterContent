# export data from db using definition in 'ContentDefinition.xml'
# groups: enp icd10 ruleengine pkms
# implicit: basics
# future?: initial medi

$global:dbServer    = "vidab-2"
$global:dbUser      = "sa"
$global:dbPassword  = "dev_sa"
$global:dbName      = "MasterContent"
$global:groupName   = "basics"

function exportGroup {
    param(
        [string]$groupName,
        [string]$dbName
    )

    Write-Host "`nDB export of group: $groupName`n"

    $source = [xml](get-content "$pwd\ContentDefinition.xml")
    $group = $source.SelectSingleNode("/ContentUpdate/Group[@name='$groupName']")
    if (-not $null -eq $group)
    {
        $tables = $group.SelectNodes('Table')

        foreach($table in $tables)
        {
            $tableName = $table.name
            $clauseNode = $table.Item('Where')

            Write-Host "Table: $tableName"

            # export format xml
            & bcp.exe "$dbName.dbo.$tableName" format nul -S $global:dbServer -U $global:dbUser -P $global:dbPassword -f ".\Export\$tableName.xml" -x -N

            if ($null -eq $clauseNode)
            {
                #export completely
                Write-Host "completely"

                & bcp.exe "$dbName.dbo.$tableName" out ".\Export\$tableName.bcp" -S $global:dbServer -U $global:dbUser -P $global:dbPassword -N
            }
            else 
            {
                #export regarding clause
                $clause = $clauseNode.InnerText
                Write-Host "where $clause"

                & bcp.exe "`"select * from $dbName.dbo.$tableName where $clause;`"" queryout  ".\Export\$tableName.bcp" -S $global:dbServer -U $global:dbUser -P $global:dbPassword -N
            }

            Write-Host "`n--------------------`n"
        }

        Write-Host "Clean up content definition`n"
        $target = [xml](get-content "$pwd\ContentDefinition.xml")
        $groups = $target.SelectNodes("/ContentUpdate/Group")
        foreach ($g in $groups)
        { 
            if (-not ($groupName -eq $g.name))
            {
                Write-Host "remove $($g.name)"
                $null = $g.ParentNode.RemoveChild($g)
            }
        }
        $target.Save("$pwd\Export\ContentDefinition.xml")

        Write-Host "`n--------------------`n"
        Write-Host "Archive"

        & 7z.exe a -t7z -sdel ".\Export\bulkdata.7z" ".\Export\*.xml" ".\Export\*.bcp"

        Write-Host "`n--------------------`n"
    }
}

Remove-Item ".\Export\*.*"

exportGroup $global:groupName $global:dbName