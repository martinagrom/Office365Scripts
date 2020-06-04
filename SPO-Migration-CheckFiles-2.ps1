#----------------------------------------------------------------------------
# SPO-Migration-CheckFiles-2.ps1 
# by atwork.at, Toni Pohl, Christoph Wilfing, Martina Grom
# Read the CSV file and analyze the files.
# Files that can and shall be imported will be written to import.csv.
# Files that will be not imported will be written to noimport.csv.
# Adapt the conditions as needed.
#----------------------------------------------------------------------------

# The csv file to analyze (created with SPO-Migration-CheckFiles-1.ps1).
$Path = ".\SPO-Migration-CheckFiles-files-demo.csv"
# The resulting files to import and to ignore.
$Import = ".\import.csv"
$NoImport = ".\noimport.csv"
# The date to identify old files. 
# Add the months or years that identify how long files are considered to be valid for importing.
$age = (Get-date).AddYears(-1)
# In SharePoint, the limit for a document's URL is 400 characters long. Adapt as needed.
$MaxURLLength = 400
# Define the maximum file size to be imported. In SPO, the max file size is 15*1GB (as of May 2020, 100GB in future).
[bigint]$MaxSize = 15GB

# Add the file name extension that exclude files to be imported, e.g. ".exe", etc.
$IgnoreExtensions = @(
    '.cache',
    '.cat',
    '.cer',
    '.cfg',
    '.chm',
    '.config',
    '.crt',
    '.dat',
    '.db',
    '.dll',
    '.edb',
    '.exe',
    '.grd',
    '.inf',
    '.ini',
    '.iso',
    '.lnk',
    '.lock',
    '.manifest',
    '.msi',
    '.ocx',
    '.plg',
    '.pst',
    '.ptn',
    '.ptn',
    '.req',
    '.sig',
    '.sis',
    '.spm',
    '.sys',
    '.url',
    '.vhd',
    '.vhdx',
    '.vss',
    '.xen'  
)

# If required, check for invalid characters. See more here:
# https://support.office.com/en-us/article/invalid-file-names-and-file-types-in-onedrive-and-sharepoint-64883a5d-228e-48f5-b3d2-eb39e07630fa
# Characters that aren't allowed in file and folder names in OneDrive, OneDrive for Business on Microsoft 365, and SharePoint Online: " * : < > ? / \ |
# Usually, these characters should not be possible in the file system. Anyway, include additional checks if needed.

# Let´s start the process...
$csv = Import-csv -path $path -Delimiter ";"

# Delete existing result files if existing.
if ([System.IO.File]::Exists($Import)) { Remove-Item $Import }
if ([System.IO.File]::Exists($Noimport)) { Remove-Item $Noimport }

# Create new result arrays.
$ResultImport = New-Object -TypeName System.Collections.ArrayList
$ResultNoImport = New-Object -TypeName System.Collections.ArrayList

# Initializing.
Write-Host "Check: Working on files." -NoNewline
$CountAll = $csv.Length
$CountYes = 0
$CountNo = 0
$count = 1 # we start with a header...

# Start the loop thru the csv files.
foreach ($line in $csv) { 

    # For each line, we are using flags for the result. We want to add all info why a file is ignored in the comment.
    # Write-Host "." -NoNewline
    $ok = $true
    $comment = ""
    $count++

    # Adapt the date format of your CSV as needed. In our sample, the csv file contains the last modified date as here:
    # Date format in CSV: 22/05/2019 10:44:47
    $helper = [DateTime]::ParseExact($line.LastWriteTime, 'dd/MM/yyyy HH:mm:ss', [CultureInfo]::GetCultureInfo("de-DE"))

    # Check if one of the following conditions is met.
    if ($helper -le $age) {
        $ok = $false
        $comment += "Too old. "
    }
    if ("" -ne $IgnoreExtensions.Where({ $line.FullName.tolower().EndsWith($_) })) {
        $ok = $false
        $comment += "Ignored file extension. "
    }
    if ([bigint]$line.Length -gt $MaxSize) {
        $ok = $false
        $comment += "Too big ($([bigint]$line.Length/1GB) GB, max. $($MaxSize/1GB) GB). "
    }
    if ($line.FullName.Length -gt $MaxURLLength) {
        $ok = $false
        $comment += "URL too long ($([int]$line.FullName.Length) chars, max. $($MaxURLLength) chars). "
    }

    # Write the files info to the import list or to the noimport list.
    # We include the original line number in the result as a reference in the comment field.
    if ($ok) {
        $CountYes++
        [void]$ResultImport.Add([PSCustomObject]@{
                Filename = $line.FullName
                Size     = $line.Length
                Date     = $line.LastWriteTime
                Comment  = "Line $count."
            })
    }
    else {
        $CountNo++
        [void]$ResultNOImport.Add([PSCustomObject]@{
                Filename = $line.FullName
                Size     = $line.Length
                Date     = $line.LastWriteTime
                Comment  = "Line $count. $comment"
            })
    }
}

# Show a summary and write the csv result files to disk.
Write-Host "`nCompleted."
Write-Host "`nLines: $CountAll`nImport: $CountYes`nNoImport: $CountNo"
$ResultImport | Export-Csv -Delimiter ";" -NoClobber -NoTypeInformation -Encoding UTF8 -Path $import
$ResultNoImport | Export-Csv -Delimiter ";" -NoClobber -NoTypeInformation -Encoding UTF8 -Path $NoImport
Write-Host "`nCheck $import and $NoImport.`n"
# End. Check the results.
# Then, migrate the files with the import list csv file and a tool.
