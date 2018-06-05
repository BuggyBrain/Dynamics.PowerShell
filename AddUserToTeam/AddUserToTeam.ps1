function Add_User2Team{

[CmdletBinding()]
    PARAM(
        [parameter(Mandatory=$true)]
        [string]$OrgName,
        [parameter(Mandatory=$false)]
        [string]$DirectoryPath
    ) 
	
	try{

        $counter = 1	
	    
        ## $invocation = (Get-Variable MyInvocation).Value
        ## $directorypath = Split-Path $invocation.MyCommand.Path
       
        if($DirectoryPath -eq $null -OR $DirectoryPath -eq "" )
        {
            $DirectoryPath = (Get-Item -Path ".\").FullName
        }
       

        $importFilePath = "$DirectoryPath\AddUserToTeam.csv"
        $statusFilePath = "$DirectoryPath\AddUserToTeamStatus.txt"

		$csvData = Import-Csv $importFilePath
		
		out-file -filepath $statusFilePath -inputobject "Email Id,Team,Status"

        $Cred = Get-Credential
        $CRMConn = Get-CrmConnection -Credential $Cred -DeploymentRegion APAC –OnlineType Office365 –OrganizationName $OrgName
               
		foreach ($user in $csvData)
		{	
            $counter = $counter + 1

		    Write-Warning "Record $counter"
        
            $emailAddress = $user.'Email Id'
            $team = $user.'Team'
            
            try 
            {
                Write-Output "Email Address: " $emailAddress , "Team: " $team
			    
                $userRecord = Get-CrmRecords -conn $CRMConn -EntityLogicalName systemuser -FilterAttribute domainname -FilterOperator "eq" -FilterValue $emailAddress -Fields systemuserid
                $teamRecord = Get-CrmRecords -conn $CRMConn -EntityLogicalName team -FilterAttribute name -FilterOperator "eq" -FilterValue $team -Fields teamid

                if($userRecord -ne $null -and $teamRecord -ne $null)
                {
                    if($userRecord.Count -eq 1 -and  $teamRecord.Count -eq 1)
                    {
                
			            Write-Output "User ID: " $userRecord.CrmRecords[0].systemuserid.Guid -RelationshipName  "Team Id: " $teamRecord.CrmRecords[0].teamid.Guid -EntityLogicalName2

		                $response = Add-CrmRecordAssociation -conn $CRMConn -EntityLogicalName1 team -Id1 $teamRecord.CrmRecords[0].teamid.Guid -EntityLogicalName2 systemuser -id2 $userRecord.CrmRecords[0].systemuserid.Guid -RelationshipName teammembership_association			
                        
                        out-file -filepath $statusFilePath -inputobject "Email Address: $emailAddressTeam, Team: $team,  Success" -Append
			           
                    }
                    else
                    {
                        $war1 = "Please check that user or team record is valid. Either records not found or more than 1 team record with same name exist."
                        Write-Warning $war1
                        out-file -filepath $statusFilePath -inputobject "Email Address: $emailAddressTeam, Team: $team,  $war1" -Append
                    }
                }
                else
                {
                    $war2 = "User or Team Record is null"
                    Write-Warning $war2
                    out-file -filepath $statusFilePath -inputobject "Email Address: $emailAddressTeam, Team: $team,  $war2" -Append
    
                }
                
            }
            catch
            {
                Write-Error "S.No.  $counter  , Email: $emailAddress , Team: $team , Exception:  $_.Exception"
                out-file -filepath $statusFilePath -inputobject "Email Address: $emailAddressTeam, Team: $team,  $_.Exception" -Append
            }
			
		}
		
	}
	catch
    {
        Write-Warning $_.Exception
    }

    Write-Warning 'Completed'
	
}

       


   
   