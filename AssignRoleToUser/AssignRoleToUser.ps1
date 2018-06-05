function Assign-RoleToUser {

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
           
    
        $importFilePath = "$DirectoryPath\AssignRoleToUser.csv"
        $statusFilePath = "$DirectoryPath\AssignRoleToUser_Status.txt"
    
        $csvData = Import-Csv $importFilePath
            
        out-file -filepath $statusFilePath -inputobject "Email Id,SecurityRole,Status"
    
        $Cred = Get-Credential
        $CRMConn = Get-CrmConnection -Credential $Cred -DeploymentRegion APAC -OnLineType Office365 -OrganizationName $OrgName
                   
        foreach ($user in $csvData) {	
            $counter = $counter + 1
    
            Write-Warning "Record $counter"
            
            $emailAddress = $user.'EmailId'
            $securityRole = $user.'SecurityRole'
                
            try {
                Write-Output "Email Address: " $emailAddress , "Security Role: " $securityRole
                    
                $userRecord = Get-CrmRecords -conn $CRMConn -EntityLogicalName systemuser -FilterAttribute domainname -FilterOperator "eq" -FilterValue $emailAddress -Fields systemuserid
    
                if ($userRecord -ne $null) {
                    if ($userRecord.Count -eq 1) {
                    
                        Write-Output "User ID: $userRecord.CrmRecords[0].systemuserid.Guid -RelationshipName  Security Role: $securityRole"
    
                        Add-CrmSecurityRoleToUser -conn $CRMConn -UserId $userRecord.CrmRecords[0].systemuserid.Guid -SecurityRoleName $securityRole

                        out-file -filepath $statusFilePath -inputobject "Email Address: $emailAddress, Security  Role: $securityRole,  Success" -Append
                           
                    }
                    else {
                        $war1 = "Please check that user record is valid."
                        Write-Warning $war1
                        out-file -filepath $statusFilePath -inputobject "Email Address: $emailAddress, Security Role: $securityRole,  $war1" -Append
                    }
                }
                else {
                    $war2 = "User Record is null"
                    Write-Warning $war2
                    out-file -filepath $statusFilePath -inputobject "Email Address: $emailAddress, Security Role: $securityRole,  $war2" -Append
        
                }
                    
            }
            catch {
                Write-Error "S.No.  $counter  , Email: $emailAddress, Security Role: $securityRole , Exception:  $_.Exception"
                out-file -filepath $statusFilePath -inputobject "Email: $emailAddress, Security Role : $securityRole,  $_.Exception" -Append
            }
                
        }
            
    }
    catch {
        Write-Warning $_.Exception
    }
    
    Write-Warning 'Completed'
        
}
    
           
    
    
       
       