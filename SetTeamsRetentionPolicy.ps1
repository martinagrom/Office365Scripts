<#
.SYNOPSIS
    SetTeamsRetentionPolicy.ps1
    by atwork.at, Christoph Wilfing, Toni Pohl, Martina Grom
    24 July 2020    
.DESCRIPTION
    Powershell script demo to set a selected Retention Policy to a specific Team
.EXAMPLE
    PS C:\> .\SetTeamsRetentionPolicy.ps1
    Starts the script
.NOTES
    This script is ready to be used with an automation account as long as the service account is provided
    through an automation credential and the required modules are imported
#>
#Requires -Module MicrosoftTeams
#Requires -PSEdition Desktop
#Requires -Version 5.1

# Direct mode (not in Azure Automation)
if ($Null -eq $cred) {
    $cred = Get-Credential -Message 'Input Admin credentials to access the Microsoft 365 Tenant'
    # Useful modules...
    Connect-AzureAD -Credential $cred
    Connect-MicrosoftTeams -Credential $Cred
    # Connect to the Security Center Powershell.
    # Notes for the account: No MFA, Basic authentication must be enabled, sufficient permissions
    Import-PSSession ( `
            New-PSSession `
            -ConfigurationName Microsoft.Exchange `
            -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ `
            -Credential $cred `
            -Authentication Basic `
            -AllowRedirection `
            -Name 'Security' )`
        -AllowClobber | Out-Null 
}

# Retrieve all retention policies (if we need the list later...)
$RetentionPolicyList = Get-RetentionCompliancePolicy -DistributionDetail

# Get a specific policy (here the policy with Name "Delete 1")
$OnePolicy = $RetentionPolicyList | Where-Object { $_.Name -eq "<PolicyName1>" }

# Get a specific Team
$TeamList = Get-Team

# Get a specific policy (here the policy with Name "Delete 1")
$OneTeam = $TeamList | Where-Object { $_.DisplayName -eq "<TeamName1>" }

# Set the policy to a team (there could be more policies assigned already - this case is ignored here)
Set-RetentionCompliancePolicy -Identity $OnePolicy.Id -AddTeamsChannelLocation $OneTeam.GroupId

# Check it: Refresh the policy list
$RetentionPolicyList = Get-RetentionCompliancePolicy -DistributionDetail

# TeamsChannelLocation.ImmutableIdentity contains the Teams.GroupId if a policy is assigned
$AssignedPolicies = $RetentionPolicyList | Where-Object { $_.teamschannellocation.ImmutableIdentity -eq $OneTeam.GroupId }

# Show the assigned policies of $OneTeam
$AssignedPolicies | Format-List

# Cleanup the session
# Get-PSSession | Remove-PSSession

# end of script.
