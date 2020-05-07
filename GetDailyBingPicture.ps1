#---------------------------------------------
# GetDailyBingPicture.ps1 
# Automate and download the daily Bing image 
# to the user´s Teams background folder
# Martina Grom, @magrom, atwork.at
#---------------------------------------------

# Use the Bing.com API. 
# The idx parameter determines the day: 0 is the current day, 1 is the previous day, etc. This goes back for max. 7 days. 
# The n parameter defines how many pictures you want to load. Usually, n=1 to get the latest picture (of today) only. 
# The mkt parameter defines the culture, like en-US, de-DE, etc.
$uri = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"

# Get the picture metadata
$response = Invoke-WebRequest -Method Get -Uri $uri

# Extract the image content
$body = ConvertFrom-Json -InputObject $response.Content
$fileurl = "https://www.bing.com/"+$body.images[0].url
$filename = $body.images[0].startdate+"-"+$body.images[0].title.Replace(" ","-").Replace("?","")+".jpg"

# Download the picture to %APPDATA%\Microsoft\Teams\Backgrounds\Uploads
$filepath = $env:APPDATA+"\Microsoft\Teams\Backgrounds\Uploads\"+$filename
Invoke-WebRequest -Method Get -Uri $fileurl -OutFile $filepath

# Show the generated picture filepath
$filepath

# Job done. 
# You can use that script manually, as daily task, or in your Startup folder. Enjoy!
