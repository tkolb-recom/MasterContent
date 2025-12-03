
function checkKey {
    param(
        [string]$tableName
    )

    #Write-Host "Table: $tableName"

    $command =
"SELECT COUNT(*) AS PrimaryKeyColumnCount
FROM sys.key_constraints kc
JOIN sys.index_columns ic 
    ON kc.parent_object_id = ic.object_id
   AND kc.unique_index_id = ic.index_id
WHERE kc.type = 'PK'
  AND OBJECT_NAME(kc.parent_object_id) = '$tableName';"

    $connectionString = "Data Source=vidab-2;Database=MasterContent;User ID=sa;Password=dev_sa;"

    $row = Invoke-Sqlcmd -ConnectionString $connectionString -Query $command
    $count = $row.Item(0)

    if ($count -eq 0)
    {
        Write-Host $tableName
    }
}

function checkKeys {

    $source = [xml](get-content "$pwd\ContentDefinition.xml")
    $groups = $source.SelectNodes("/ContentUpdate/Group")
    foreach ($group in $groups)
    {
        Write-Host $group.Name
        Write-Host "---------------"

        $tables = $group.SelectNodes('Table')

        foreach($table in $tables)
        {
            $tableName = $table.name

            checkKey $tableName
        }

        Write-Host
    }
}

checkKeys