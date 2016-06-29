############################################################### 
#
#   before send test message to Queue, download LATEST.json and rename to OLD.json   
#
###############################################################

#verify the DatePerformed of result JSON file is later than the one before putting the Queue message
function GetFileContent($Path,$ContentName){    #get the key value from JSON file
   $FileContent = get-content $Path | ConvertFrom-json
   return $FileContent.$ContentName
}

$BlobName = "e475bcae-fd1b-4fd7-9f04-015095e81e53/2/54ab6b58-8931-46dd-88ae-b9e80c7195c0/zhuw2k8r2spl300.melquest.dev.mel.au.qsft_sql2008r2_sqlserver/LATEST.json"
$StorageAccountName = "lucystagingstorageus" 
$StorageAccountKey = "s1bQ/9f2S5JxPMBw7OhKMSGAoqVBAhAtu4yyDnugD/kbIo/OXZRh8E8IYRkya2m7dxc9KFF4+9XkYYbdKfHznw==" 
$Context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
$ContainerName = "sqlserver-static-health-check"

#create local path for result JSON

$ResultJSONFolder = 'C:\json\result'
new-item -Path $ResultJSONFolder -ItemType Directory -Force

Function GetJSONFile ($ResultFolder){

    Get-AzureStorageBlobContent -Container $ContainerName -Blob $BlobName -Destination $ResultFolder -Context $Context -Force
    $AllChildItem = Get-ChildItem $ResultJSONFolder -Include *.json -Recurse  
    if($AllChildItem.Length -gt 0){
        write-host "JSON file in $ResultFolder is generated"
    }
    else {
        Write-warning "Unable to find JSON file in $ResultFolder"
    }
}


GetJSONFile ($ResultJSONFolder)

#change the json file name 
Get-ChildItem -Path $ResultJSONFolder -Filter '*.json' -Recurse | Rename-Item -NewName old.json -Force

###############################################################
#
#   send test message to Queue to trigger the schedule job
#
###############################################################

$StorageAccountName = "lucystagingstorageus" 
$StorageAccountKey = "s1bQ/9f2S5JxPMBw7OhKMSGAoqVBAhAtu4yyDnugD/kbIo/OXZRh8E8IYRkya2m7dxc9KFF4+9XkYYbdKfHznw==" 

function SendMessageToQueue($QueueName,$QueueMessage) {

    $Ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
    $data = Get-AzureStorageQueue -Name $QueueName -Context $Ctx
    $data.CloudQueue.AddMessage($queueMessage)  
    return 0
}

$QName = 'system-healthcheck-test'
$Qmsg = New-Object -TypeName Microsoft.WindowsAzure.Storage.Queue.CloudQueueMessage -ArgumentList '{"Command": "ProcessOwner", "OwnerGuid": "e475bcae-fd1b-4fd7-9f04-015095e81e53", "OwnerID": 29939}'

$Res = SendMessageToQueue -QueueName $Qname -QueueMessage $Qmsg
if ($Res -eq 0) {
    write-host "Message has been sent to $QName"
}
else{
    $host.UI.WriteErrorLine("Message has not been sent to $QName")
}


Start-Sleep -seconds 120  #set wait time for file is generated


###############################################################################
#
#  Download the result JSON file from container 'sqlserver-static-health-check' 
#
###############################################################################


#download the result JSON

$ResultJSONFolder = 'C:\json\result'
GetJSONFile ($ResultJSONFolder)


$OwnerGuid = "e475bcae-fd1b-4fd7-9f04-015095e81e53"
$ConnectionName = "zhuw2k8r2spl300.melquest.dev.mel.au.qsft_sql2008r2_sqlserver" 
$DiagnosticServerID = "54ab6b58-8931-46dd-88ae-b9e80c7195c0"


$ResultJSONfile = $ResultJSONFolder + "\"+ $OwnerGuid + "\2\"+$DiagnosticServerID+"\"+$ConnectionName+"\LATEST.json"
$OldResultJSONfile = $ResultJSONFolder + "\"+ $OwnerGuid + "\2\"+$DiagnosticServerID+"\"+$ConnectionName+"\old.json"

#convert the file content to json format

$LatestJSON = (Get-Content $ResultJSONfile) -join "`n" | ConvertFrom-Json
$OldJSON = (Get-Content $OldResultJSONfile) -join "`n" | ConvertFrom-Json

write-host "Update date of LATEST.json" $LATESTJSON.DatePerformed
write-host "Update date of old.json" $OldJSON.DatePerformed

#Compare the DatePerformed in LATEST.json and old.json
 
if($LatestJSON.DatePerformed -gt $OldJSON.DatePerformed){
     write-host "Correct JSON is generated"
   }
   else{
       $host.UI.WriteErrorLine("ERROR: $ResultJSONfile is not generated")
      }

###############################################################################
#
#  Check health check result 
#
###############################################################################
function CheckIndividualResult([decimal]$Result0,$Result1,$Result2,$Result3,$Result4,$Result5,$Result6,$Result7)
{
 
$Pattern = "e475bcae-fd1b-4fd7-9f04-015095e81e53/2/54ab6b58-8931-46dd-88ae-b9e80c7195c0/zhuw2k8r2spl300.melquest.dev.mel.au.qsft_sql2008r2_sqlserver/LATEST.json" 
$JSONFile = "C:\JSON\Result\" + $Pattern
$Params = (Get-Content $JSONFile) -join "`n" | ConvertFrom-Json

$Params0 = $Params.TotalScoreIncludingIgnoredChecks 
$Params1 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "memory_physical_memory_pressure"}).HealthCheckScore
$Params2 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "memory_adhoc_workload_configuration"}).HealthCheckScore
$Params3 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "security_password_policy"}).HealthCheckScore
$Params4 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "security_guest_access"}).HealthCheckScore 
$Params5 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "dr_backup"}).HealthCheckScore 
$Params6 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "dr_simple_recovery_model"}).HealthCheckScore
$Params7 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "configuration_database_compatibility_level"}).HealthCheckScore

   if ($Result0 -eq $Params0) {return $true} 
   if ($Result1 -eq $Params1) {return $true}
   if ($Result2 -eq $Params2) {return $true} 
   if ($Result3 -eq $Params3) {return $true}
   if ($Result4 -eq $Params4) {return $true}
   if ($Result5 -eq $Params5) {return $true}
   if ($Result6 -eq $Params6) {return $true}
   if ($Result7 -eq $Params7) {return $true}
}

function CheckResult
{

$Pattern = "e475bcae-fd1b-4fd7-9f04-015095e81e53/2/54ab6b58-8931-46dd-88ae-b9e80c7195c0/zhuw2k8r2spl300.melquest.dev.mel.au.qsft_sql2008r2_sqlserver/LATEST.json" 
$JSONFile = "C:\JSON\Result\" + $Pattern
$Params = (Get-Content $JSONFile) -join "`n" | ConvertFrom-Json


$ParamHashTable = @{}

$Params0 = $Params.TotalScoreIncludingIgnoredChecks 
$Params1 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "memory_physical_memory_pressure"}).HealthCheckScore
$Params2 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "memory_adhoc_workload_configuration"}).HealthCheckScore
$Params3 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "security_password_policy"}).HealthCheckScore
$Params4 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "security_guest_access"}).HealthCheckScore 
$Params5 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "dr_backup"}).HealthCheckScore 
$Params6 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "dr_simple_recovery_model"}).HealthCheckScore
$Params7 = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "configuration_database_compatibility_level"}).HealthCheckScore

$CheckResult0 = $ParamHashTable.TotalScoreIncludingIgnoredChecks = ('{0:n2}' -f $params0 -eq [decimal]"74.28")
$CheckResult1 = $ParamHashTable.memory_physical_memory_pressure = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "memory_physical_memory_pressure"}).HealthCheckScore -eq [int]"100.0"
$CheckResult2 = $ParamHashTable.memory_adhoc_workload_configuration = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "memory_adhoc_workload_configuration"}).HealthCheckScore -eq [int]"100.0"
$CheckResult3 = $ParamHashTable.security_password_policy = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "security_password_policy"}).HealthCheckScore -eq $null
$CheckResult4 = $ParamHashTable.security_guest_access = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "security_guest_access"}).HealthCheckScore -eq [int]"100.0"
$CheckResult5 = $ParamHashTable.dr_backup = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "dr_backup"}).HealthCheckScore -eq [int]"0"
$CheckResult6 = $ParamHashTable.dr_simple_recovery_model = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "dr_simple_recovery_model"}).HealthCheckScore -eq [int]"100.0"
$CheckResult7 = $ParamHashTable.configuration_database_compatibility_level = ($Params.StaticHealthChecks | ? {$_.HealthCheckName -eq "configuration_database_compatibility_level"}).HealthCheckScore -eq [int]"99"

$strings = @(("TotalScoreIncludingIgnoredChecks","memory_physical_memory_pressure","memory_adhoc_workload_configuration","security_password_policy","security_guest_access","dr_backup","dr_simple_recovery_model","configuration_database_compatibility_level",`
$Params0,$Params1,$Params2,$Params3,$Params4,$Params5,$Params6,$Params7),`
("74.28","100.0","100.0","90","100.0","0","100.0","99",$CheckResult0,$CheckResult1,$CheckResult2,$CheckResult3,$CheckResult4,$CheckResult5,$CheckResult6,$CheckResult7))

$ResultOutput = for($i=0;$i -le 7;$i++) {StringVersions -inputString $strings[0][$i] -ExpectedValueString $strings[1][$i] -ActualValue $strings[0][$i+8] -Result $strings[1][$i+8] }
$ResultOutput

if ($ParamHashTable.Values -ccontains $false)
{
    return "False"}
else {return "All True"}
#Remove-Item -Path c:\temp\e475bcae-fd1b-4fd7-9f04-015095e81e53 -Force -Recurse
}

function StringVersions {
param([string]$inputString,$ExpectedValueString,$ActualValue,$Result)
  $obj = New-Object PSObject
  $obj | Add-Member NoteProperty -name 'Health Check Name' -value $inputString
  $obj | Add-Member NoteProperty -name 'ExpectedValue'-Value $ExpectedValueString
  $obj | Add-Member NoteProperty -name 'ActualValue' -Value $ActualValue
  $obj | Add-Member NoteProperty -name 'Result' -Value $Result

  Write-Host ($obj | Format-Table | Out-String)
}  
