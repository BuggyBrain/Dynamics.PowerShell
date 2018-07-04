function Change-UserBU {

    [CmdletBinding()]
    PARAM(
        [parameter(Mandatory = $true)]
        [string]$OrgName,
        [parameter(Mandatory = $false)]
        [string]$DirectoryPath
    ) 
        
    try {
    
        $counter = 0	
            
        ## $invocation = (Get-Variable MyInvocation).Value
        ## $directorypath = Split-Path $invocation.MyCommand.Path
           
        if ($DirectoryPath -eq $null -OR $DirectoryPath -eq "" ) {
            $DirectoryPath = (Get-Item -Path ".\").FullName
        }
           
    
        $importFilePath = "$DirectoryPath\ChangeUserBU.csv"
        $statusFilePath = "$DirectoryPath\ChangeUserBU_Status.txt"
    
        $csvData = Import-Csv $importFilePath
            
        out-file -filepath $statusFilePath -inputobject "Email Id,BusinessUnit,Status"
    
        $Cred = Get-Credential
        $CRMConn = Get-CrmConnection -Credential $Cred -DeploymentRegion APAC -OnLineType Office365 -OrganizationName $OrgName
                   
        foreach ($user in $csvData) {	
            $counter = $counter + 1
    
            Write-Warning "Record $counter"
            
            $emailAddress = $user.'EmailId'
            $businessUnit = $user.'BusinessUnit'
                
            try {
                Write-Output "Email Address: " $emailAddress , "Business Unit: " $businessUnit
                    
                $userRecord = Get-CrmRecords -conn $CRMConn -EntityLogicalName systemuser -FilterAttribute domainname -FilterOperator "eq" -FilterValue $emailAddress -Fields systemuserid
    
                if ($userRecord -ne $null) {
                    if ($userRecord.Count -eq 1) {
                    
                        Write-Output "User ID: $emailAddress  Business Unit: $businessUnit"
                              
                        $businessUnitRecord = Get-CrmRecords -conn $CRMConn -EntityLogicalName businessunit -FilterAttribute name -FilterOperator eq -FilterValue $businessUnit -Fields businessunitid
    
                        if($businessUnitRecord.CrmRecords.Count -eq 0)
                        {
                            out-file -filepath $statusFilePath -inputobject "Email Address: $emailAddress, Business Unit: $businessUnit, Business Unit $businessUnit does not exist"    -Append
                            Write-Error "Business Unit $businessUnit does not exist"                            
                        }
                        else
                        {
                            Write-Output "Move user to $businessUnit"
                            $businessUnitId = $businessUnitRecord.CrmRecords[0].businessunitid.Guid
                          
                            Set-CrmUserBusinessUnit -conn $CRMConn -BusinessUnitId $businessUnitId -UserId $userRecord.CrmRecords[0].systemuserid.Guid -ReassignUserId $userRecord.CrmRecords[0].systemuserid.Guid
                          
                            out-file -filepath $statusFilePath -inputobject "Email Address: $emailAddress, Business Unit: $businessUnit,  Success" -Append
                        }    
                       
                        out-file -filepath $statusFilePath -inputobject "Email Address: $emailAddress, Business Unit: $businessUnit,  Success" -Append
                           
                    }
                    else {
                        $war1 = "Please check that user record is valid."
                        Write-Warning $war1
                        out-file -filepath $statusFilePath -inputobject "Email Address: $emailAddress, Business Unit: $businessUnit,  $war1" -Append
                    }
                }
                else {
                    $war2 = "User Record is null"
                    Write-Warning $war2Business Unit
                    out-file -filepath $statusFilePath -inputobject "Email Address: $emailAddress, Business Unit: $businessUnit,  $war2" -Append
        
                }
                    
            }
            catch {
                Write-Error "S.No.  $counter  , Email: $emailAddress, Business Unit: $businessUnit , Exception:  $_.Exception"
                out-file -filepath $statusFilePath -inputobject "Email: $emailAddress, Business Unit : $businessUnit,  $_.Exception" -Append
            }
                
        }
            
    }
    catch {
        Write-Warning $_.Exception
    }
    
    Write-Warning 'Completed'
        
}
    
           
    
    
       
       