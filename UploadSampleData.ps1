
#Download sample data for Azure blob
$TargetFolder = "C:\JSON"
if(!(Test-Path $TargetFolder))
{
    New-Item -Path $TargetFolder -ItemType Directory -Force
}
else
{
    Remove-Item -Path $TargetFolder -Recurse -Force
    New-Item -Path $TargetFolder -ItemType Directory -Force

}
$JSONzip = "https://spotlightautomation.blob.core.windows.net/sampledata/SampleData.zip"
$JSONFile = "C:\JSON\SampleData.zip"

Invoke-WebRequest -Uri $JSONzip -OutFile $JSONFile -UseBasicParsing


Function Unzip()
{
    param([string]$ZipFile,[string]$TargetFolder)
    $shellApp = New-Object -ComObject Shell.Application 
    $files = $shellApp.NameSpace($ZipFile).Items() 
    $shellApp.NameSpace($TargetFolder).CopyHere($files) 
}
#unzip the json files to target folder
unzip -ZipFile $JSONFile -TargetFolder $TargetFolder 


###############################################################
#
#   upload JSON files
#
###############################################################
# read UserToken from file
$UserToken = get-content "C:\JSON\0_usertoken.txt"

# define header info
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("x-user-token", $UserToken)

# Define URLs
$url = "https://testapi.spotlightessentials.com/"
$DSurl = $url + "/api/v2/diagnostic-servers"
$ProcedureUrl = $url + "/api/v2/procedure"
# Upload multiple connections
$ConnectionUrl = $url + "/api/v2/connections-sync"
# Get current timestamp
function ConvertTo-UnixTimestamp { 
        $epoch = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0        
        $input | % {            
                $milliSeconds = [math]::truncate($_.ToUniversalTime().Subtract($epoch).TotalMilliSeconds) 
                Write-Output $milliSeconds 
        }        
}   

$Timestamp = Get-Date | ConvertTo-UnixTimestamp
Write-Host "Current timestamp is" $Timestamp
$Procedulefiles = Get-Childitem C:\JSON\  -Recurse -Include HealthCheck*, sqllogins.json

# Upload DS
Write-Host "Uploading DS"
$DSjson = get-content "C:\JSON\1_DS.json" 
$Result = Invoke-RestMethod $DSurl -Method POST -Body $DSjson -ContentType 'application/json' -Headers $headers 
$Result

# Upload Connections
Write-Host "Uploading Connections"
$ConnectionJson = get-content "C:\JSON\2_Connections.json" 
$Result=Invoke-RestMethod $ConnectionUrl -Method POST -Body $ConnectionJson -ContentType 'application/json' -Headers $headers
$Result

# Upload Procudres data
Foreach($Pfile in $Procedulefiles)
{
    Write-Host "Uploading $Pfile" 
    $ProcedureJson = get-content $Pfile
    $ProcedureJson = $ProcedureJson -replace "{{Timestamp}}",$Timestamp
    $Result = Invoke-RestMethod $ProcedureUrl -Method PUT -Body $ProcedureJson -ContentType 'application/json' -Headers $headers
    $Result
}
