
function checkKey {
    param(
        [string]$tableName
    )

    #Write-Host "Table: $tableName"

    $command =
"SELECT COUNT(COLUMN_NAME)
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_SCHEMA + '.' + QUOTENAME(CONSTRAINT_NAME)), 'IsPrimaryKey') = 1
AND TABLE_NAME = '$tableName';"

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