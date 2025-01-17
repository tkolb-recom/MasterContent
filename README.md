
1. convert-dbupdate ausführen

2. XSD erzeugen:
`xsd.exe .\ContentDefinition.xml`

3. Serialisierungsklasse erzeugen:
`xsd.exe .\ContentDefinition.xsd /e:ContentUpdate /c /language:CS`

![image](https://github.com/user-attachments/assets/4c110f11-6328-4d83-891f-75930df9e611)

4. bcpexport ausführen
