#----------------------------------------------------------------------------
# SPO-Migration-CheckFiles-1.ps1
# by atwork.at, Toni Pohl, Christoph Wilfing, Martina Grom
# Read all files of a folder recursively and write the output to a CSV file.
# The csv file can then be analyzed with the next script.
#----------------------------------------------------------------------------
Write-Output "SPO-Migration-CheckFiles-1.ps1`nGet a recursive list of all files with last modified date and file size in a CSV file."

# The folder you want to run through.
$folder = "C:\Temp"
# The files in that folder will be written to that file: 
$result = ".\SPO-Migration-CheckFiles-files-demo.csv"

get-childitem $folder -rec | `
    where {!$_.PSIsContainer} | `
    select-object FullName, LastWriteTime, Length | `
    export-csv -notypeinformation -delimiter ';' -path $result

Write-Output "Done. Check $($result)"
# End. Continue with SPO-Migration-CheckFiles-2.ps1
