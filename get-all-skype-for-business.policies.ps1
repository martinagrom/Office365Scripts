<#
----------------------------------------------------
get-all-skype-for-business-policies.ps1
PowerShell Script to get all SFB policies
in Office 365 for further use in Excel
atwork.at, Martina Grom, 7/10/2016
----------------------------------------------------
#>

# Connect to your tenant first before running this script!
$separator = ","
$ignorefields = "XsAnyElements,XsAnyAttributes,PSComputerName,RunspaceId,PSShowComputerName,Element,ScopeClass,Anchor,Identity,TypedIdentity"

# get all policies first
$policies = Get-CsConferencingPolicy | select Identity

function GetHeader ([string]$policy, $properties) {
    $p = "`"Identity`"$separator"
    $properties.PSObject.Properties | foreach-object {
        $propname = $_.Name.Tostring()
        if ($ignorefields -notmatch $propname) {
            $p += "`"$propname`"$separator"
        }
    }
    $p += [Environment]::NewLine
    return $p
}

function GetProperties ([string]$policy, $properties) {
    $p = "`"$policy`"$separator"
    $properties.PSObject.Properties | foreach-object {
        $propname = $_.Name.Tostring()
        $propvalue = $_.Value
         if ($ignorefields -notmatch $propname) {
            if ($propvalue -and $propvalue.Tostring().StartsWith("<")) {
                $propvalue ="`"[XML]`""
            }
            $p += "`"$propvalue`"$separator"
        }
    }
    $p += [Environment]::NewLine
    return $p
}

$out = ''
$i = 0
Foreach ($policy in $policies) { 
    $i ++
    Write-Output $policy.Identity

    # read all properties per policy
    $properties = Get-CsConferencingPolicy -Identity $policy.Identity 

    if ($i -eq 1) { 
        # create the header only once
        $out += GetHeader $policy.Identity $properties
    }
    # read the properties and values
    $out += GetProperties $policy.Identity $properties
}

Out-File .\skypepolicies.csv -inputObject $out
Write-Host "Done, check $out and use Excel with Data filter for finding the desired policy."
# end.
