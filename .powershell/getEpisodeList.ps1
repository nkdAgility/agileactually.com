# Define your Client ID and Client Secret
$clientId = "1120c6949df54792975a405bbdcaa3bf"
$clientSecret = $Env:SPOTIFY_CLIENT_SECRET

# Define the token endpoint
$tokenUri = "https://accounts.spotify.com/api/token"

# Prepare the headers
$headers = @{
    "Content-Type" = "application/x-www-form-urlencoded"
}

# Prepare the body
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
}

# Send the request to get the access token
$response = Invoke-RestMethod -Method Post -Uri $tokenUri -Headers $headers -Body $body
$accessToken = $response.access_token

# Define the Spotify Show ID
$showId = "27PyDccVtzuOWFtB7Qi84q"

# Set the API endpoint
$episodesUri = "https://api.spotify.com/v1/shows/$showId/episodes?limit=50&offset=0"

# Prepare the headers with the access token
$headers = @{
    Authorization = "Bearer $accessToken"
}

# Send the request to get the episodes
$response = Invoke-RestMethod -Method Get -Uri $episodesUri -Headers $headers

# Define the target directory and file path
$targetDirectory = "site/data"
$targetFilePath = "$targetDirectory/episodes.json"

# Ensure the target directory exists; create it if it doesn't
if (-Not (Test-Path -Path $targetDirectory)) {
    New-Item -Path $targetDirectory -ItemType Directory -Force
}

# Convert the episode data to JSON
$jsonData = $response.items | ConvertTo-Json -Depth 10

# Save the JSON data to the file
Set-Content -Path $targetFilePath -Value $jsonData -Encoding UTF8

Write-Output "Episodes have been saved to $targetFilePath"
