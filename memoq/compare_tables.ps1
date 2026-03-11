# PowerShell-Skript zum Vergleich der Tabellennamen in TranslationContent.xml und ContentDefinition.xml
# Gibt alle Tabellennamen aus, die in TranslationContent.xml enthalten sind, aber nicht in ContentDefinition.xml

# Pfade zu den XML-Dateien (relative Pfade vom Skript-Verzeichnis aus)
$translationContentPath = "TranslationDefinition.xml"
$contentDefinitionPath = "..\ContentDefinition.xml"

# Laden der XML-Dateien
try {
    $xmlTranslation = [xml](Get-Content $translationContentPath -Encoding UTF8)
    $xmlContentDef = [xml](Get-Content $contentDefinitionPath -Encoding UTF8)
} catch {
    Write-Host "Fehler beim Laden der XML-Dateien: $_"
    exit 1
}

# Extrahieren der Tabellennamen aus TranslationDefinition.xml
$tablesTranslation = $xmlTranslation.TranslationDefinition.Table | Select-Object -ExpandProperty name

# Extrahieren der Tabellennamen aus ContentDefinition.xml
$tablesContentDef = $xmlContentDef.ContentUpdate.Group.Table | Select-Object -ExpandProperty name

# Finden der Tabellen, die in TranslationDefinition.xml sind, aber nicht in ContentDefinition.xml
$missingTables = $tablesTranslation | Where-Object { $_ -notin $tablesContentDef }

# Ausgabe der Ergebnisse
if ($missingTables.Count -eq 0) {
    Write-Host "Alle Tabellen aus TranslationDefinition.xml sind in ContentDefinition.xml vorhanden."
} else {
    Write-Host "Folgende Tabellen sind in TranslationDefinition.xml enthalten, aber nicht in ContentDefinition.xml:"
    $missingTables | ForEach-Object { Write-Host "- $_" }
}