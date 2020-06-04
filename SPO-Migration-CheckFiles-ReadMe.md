# SPO-Migration-CheckFiles

by [atwork.at](https://www.atwork-it-com/), Toni Pohl, Christoph Wilfing, Martina Grom

The PowerShell scripts SPO-Migration-CheckFiles-1.ps1 and SPO-Migration-CheckFiles-2.ps2 help to analyze files in a local file system before migrating them to SharePoint Online or OneDrive. The operation includes the following scripts:

- **SPO-Migration-CheckFiles-1.ps1** runs through a specified folder of a local drive like "C:\Data" or a network drive like ""\\nas01.atwork.org\department a" recursively. All files in that folder will be logged with their last modified date and their file size in Bytes to a single CSV file.
- **SPO-Migration-CheckFiles-2.ps1** reads the created CSV file and analyzes the files. The script checks if the file size is too big to be imported, if the file extension should be ignored, if the last modified date of the file is older than a specified date (e.g. if the file has not been accessed in the last 3 years), and if the path length is below 400 characters. These criteria must be ok to have the file info written to the import.csv list. If one of the criteria is not met, the file info will be written to the noimport.csv list. Adapt the conditions as needed.
- SPO-Migration-CheckFiles-ReadMe.md this short description. See more comments in the scripts.

As a result, the generated files can be checked:

- **SPO-Migration-CheckFiles-files-demo.csv** is a demo file generated from SPO-Migration-CheckFiles-1.ps1. This csv file contains ALL files in a specified folder or network path.
- **import.csv** is the file that shows all files that SHOULD be migrated.
- **noimport.csv** is the file that shows all files that SHOULD NOT be migrated. The comments field shows the reasons why this file should be ignored.

Adapt the scripts as needed.
We hope the scripts help to migrate existing content to the cloud. In case of questions, pls. contact us.
