# Define your Spotify Client ID and Client Secret
$spotifyClientId = "1120c6949df54792975a405bbdcaa3bf"
$spotifyClientSecret = $Env:SPOTIFY_CLIENT_SECRET

# Define your YouTube Data API Key
#$youtubeApiKey = $Env:YOUTUBE_API_KEY

# Define the YouTube channel ID to restrict searches
$youtubeChannelId = "UCQxOqOLPrgtWJAKJzOgR5uw" # Replace with your desired channel's ID

# Spotify token endpoint
$spotifyTokenUri = "https://accounts.spotify.com/api/token"

# Prepare the headers for Spotify authentication
$spotifyHeaders = @{
    "Content-Type" = "application/x-www-form-urlencoded"
}

# Prepare the body for Spotify authentication
$spotifyBody = @{
    grant_type    = "client_credentials"
    client_id     = $spotifyClientId
    client_secret = $spotifyClientSecret
}

# Request Spotify access token
$spotifyResponse = Invoke-RestMethod -Method Post -Uri $spotifyTokenUri -Headers $spotifyHeaders -Body $spotifyBody
$spotifyAccessToken = $spotifyResponse.access_token

# Spotify Show ID
$spotifyShowId = "27PyDccVtzuOWFtB7Qi84q"

# Spotify episodes API endpoint
$spotifyEpisodesUri = "https://api.spotify.com/v1/shows/$spotifyShowId/episodes?limit=50&offset=0"

# Prepare Spotify headers with the access token
$spotifyAuthHeaders = @{
    Authorization = "Bearer $spotifyAccessToken"
}

# Fetch episodes from Spotify
$spotifyEpisodesResponse = Invoke-RestMethod -Method Get -Uri $spotifyEpisodesUri -Headers $spotifyAuthHeaders
$episodes = $spotifyEpisodesResponse.items

# Function to fetch the full oEmbed response for a given Spotify episode URL
function Get-EpisodeOEmbed {
    param (
        [string]$episodeUrl
    )
    $oEmbedApi = "https://open.spotify.com/oembed?url=$episodeUrl"
    $oEmbedResponse = Invoke-RestMethod -Method Get -Uri $oEmbedApi
    return $oEmbedResponse
}

# Function to search YouTube for a video matching the episode title within a specific channel and return the video ID
# function Get-YouTubeVideoId {
#     param (
#         [string]$searchQuery
#     )
#     $youtubeSearchApi = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&q=$($searchQuery -replace ' ', '+')&channelId=$youtubeChannelId&key=$youtubeApiKey&maxResults=1"
#     $youtubeResponse = Invoke-RestMethod -Method Get -Uri $youtubeSearchApi

#     if ($youtubeResponse.items.Count -gt 0) {
#         return $youtubeResponse.items[0].id.videoId
#     }
#     else {
#         return $null
#     }
# }

# Augment episodes with oEmbed data and YouTube video ID
foreach ($episode in $episodes) {
    $episodeUrl = $episode.external_urls.spotify
    $oEmbedData = Get-EpisodeOEmbed -episodeUrl $episodeUrl

    # Add oEmbed properties dynamically
    $episode | Add-Member -MemberType NoteProperty -Name "oembed_title" -Value $oEmbedData.title
    $episode | Add-Member -MemberType NoteProperty -Name "oembed_thumbnail_url" -Value $oEmbedData.thumbnail_url
    $episode | Add-Member -MemberType NoteProperty -Name "oembed_html" -Value $oEmbedData.html
    $episode | Add-Member -MemberType NoteProperty -Name "oembed_url" -Value $oEmbedData.iframe_url

    ## Search YouTube using the episode's name and get the video ID
    #$youtubeVideoId = Get-YouTubeVideoId -searchQuery $episode.name
    ## Add the YouTube video ID dynamically
    #$episode | Add-Member -MemberType NoteProperty -Name "youtube_video_id" -Value $youtubeVideoId
}

# Define the target directory and file path
$targetDirectory = "site/data"
$targetFilePath = "$targetDirectory/episodes.json"

# Ensure the target directory exists
if (-Not (Test-Path -Path $targetDirectory)) {
    New-Item -Path $targetDirectory -ItemType Directory -Force
}

# Convert the augmented episodes to JSON
$jsonData = $episodes | ConvertTo-Json -Depth 10

# Save the JSON data to the file
Set-Content -Path $targetFilePath -Value $jsonData -Encoding UTF8

Write-Output "Episodes with oEmbed data and YouTube video IDs have been saved to $targetFilePath"
