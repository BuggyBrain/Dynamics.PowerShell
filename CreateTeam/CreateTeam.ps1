function Create-Team{

[CmdletBinding()]
    PARAM(
        [parameter(Mandatory=$true)]
        [string]$OrgName,
        [parameter(Mandatory=$false)]
        [string]$DirectoryPath
    )
	
	try{

        $counter = 0	
	    
        ## $invocation = (Get-Variable MyInvocation).Value
        ## $directorypath = Split-Path $invocation.MyCommand.Path
       
        if($DirectoryPath -eq $null -OR $DirectoryPath -eq "" )
        {
            $DirectoryPath = (Get-Item -Path ".\").FullName
        }
       

        $importFilePath = "$DirectoryPath\CreateTeam.csv"
        $statusFilePath = "$DirectoryPath\CreateTeam_Status.txt"

		$csvData = Import-Csv $importFilePath
		
		out-file -filepath $statusFilePath -inputobject "Team, Business Unit Status"

        $Cred = Get-Credential
        $CRMConn = Get-CrmConnection -Credential $Cred -DeploymentRegion APAC –OnlineType Office365 –OrganizationName $OrgName
               
		foreach ($record in $csvData)
		{	
            $counter = $counter + 1

		    Write-Warning "Creating Record $counter"
        
            $businessUnit = $record.'BusinessUnit'
            $team = $record.'Team'
            $administrator = $record.'Administrator'
            
            ### Default value is Owner Team, incase of any wrong input will default it to owner team
            $teamType = 0;
                 
                 if($record.'TeamType' -ne $null -and $record.'TeamType' -ne "" -and $record.'TeamType' -eq "Access")
                 {
                    $teamType = 1;
                 }
            
            try 
            {
                Write-Output "Team: $team , Business Unit: $businessUnit"
			    
                $businessUnitRecord = Get-CrmRecords -conn $CRMConn -EntityLogicalName businessunit -FilterAttribute name -FilterOperator "eq" -FilterValue $businessUnit -Fields businessunitid                
                $administratorRecord = Get-CrmRecords -conn $CRMConn -EntityLogicalName systemuser -FilterAttribute domainname -FilterOperator "eq" -FilterValue $administrator -Fields systemuserid

                if($businessUnitRecord -ne $null -and $businessUnitRecord.Count -eq 1 -and 
                    $administratorRecord -ne $null -and $administratorRecord.Count -eq 1)
                {          
                
                       $businessUnitIdString = $businessUnitRecord.CrmRecords[0].businessunitid.Guid.ToString();                
			           Write-Output "Business Unit ID:  $businessUnitIdString " 

                       ##  ToDO: Create new Team Record 
                       New-CrmRecord -conn $CRMConn -EntityLogicalName team -Fields @{"name"=$team;"businessunitid"=$businessUnitRecord.CrmRecords[0].EntityReference; "administratorid" = $administratorRecord.CrmRecords[0].EntityReference; "teamtype" = New-CrmOptionSetValue -Value $teamType}
		               ##  $response = Add-CrmRecordAssociation -conn $CRMConn -EntityLogicalName1 team -Id1 $teamRecord.CrmRecords[0].teamid.Guid -EntityLogicalName2 systemuser -id2 $userRecord.CrmRecords[0].systemuserid.Guid -RelationshipName teammembership_association			
                        
                       out-file -filepath $statusFilePath -inputobject "Business Unit : $businessUnit, Team: $team,  Success" -Append
			           
                   
                }
                else
                {
                    $war1 = "Business Unit or Administrator Record not found"
                    Write-Warning $war1
                    out-file -filepath $statusFilePath -inputobject "Business Unit: $businessUnit, Team: $team,  $war1" -Append
    
                }
                
            }
            catch
            {
                Write-Error "S.No.  $counter  , Business Uuit : $businessUnit , Team: $team , Exception:  $_.Exception"
                out-file -filepath $statusFilePath -inputobject "Business Unit: $businessUnit, Team: $team,  $_.Exception" -Append
            }
			
		}
		
	}
	catch
    {
        Write-Warning $_.Exception
    }

    Write-Warning 'Completed'
	
}

       


   
   