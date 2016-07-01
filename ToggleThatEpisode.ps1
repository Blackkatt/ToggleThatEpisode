#requires -Version 3

#region DESCRIPTION
<#
		Author: Blackkatt
		Version: 1.0.0
		Name: ToggleThatEpisode

		Purpose: Unmonitor episode in sonarr.

		Instructions:
		1. get the kodi add-on "Kodi Callsbacks". ? http://kodi.wiki/view/HOW-TO:Install_add-ons
		2. in "Kodi Callbacks" settings/tasks/task select script. ? http://kodi.wiki/index.php?title=Add-on:Kodi%20Callbacks
		3. click "script executable file -browser" select "ToggleThatEpisodeLNCHR.cmd"

		What Will Happen:
		script gets playback from kodi. script tells sonarr to unmonitor episode. sonarr stops looking for upgrade.
#>
#endregion DESCRIPTION

#region SETUP
  
#	Kodi credentials
$user     = 'YourUsernameGoesHere'
$pass     = 'YourPasswordGoesHere'
$kodiHost = '127.0.0.1:8080'         # change if different, doh!
  
#	Sonarr credentials
$sonarrApiKey = 'YourApiKeyGoesHere' # http://127.0.0.1:8989/settings/general
$sonarrHost   = '127.0.0.1:8989'     # change if different, doh!
$getSeries    = "http://$sonarrHost/api/series"
$getEpisodes  = "http://$sonarrHost/api/episode?SeriesId="

#endregion SETUP

#region Kodi
  
# Get Current Playback
Function Get-JSON 
{
   param
   (
     [Object]
     $url,

     [Object]
     $object,

     [Object]
     $user,

     [Object]
     $pass
   )

	$cred = New-Object -TypeName System.Net.NetworkCredential -ArgumentList $user, $pass
	$bytes = [System.Text.Encoding]::ascii.GetBytes($object)
	$web = [System.Net.WebRequest]::Create($url)
	$web.Method = 'POST'
	$web.ContentLength = $bytes.Length
	$web.ContentType = 'application/json'
	$web.Credentials = $cred
	$stream = $web.GetRequestStream()
	$stream.Write($bytes,0,$bytes.Length)
	$stream.close()
	$reader = New-Object -TypeName System.IO.Streamreader -ArgumentList $web.GetResponse().GetResponseStream()
	return $reader.ReadToEnd() | ConvertFrom-Json
	$reader.Close()
}
  
$data = @{
   jsonrpc = '2.0'
    method = 'Player.GetItem'
    params = @{
properties = ('title', 'season', 'episode', 'showtitle')
  playerid = 1}
        id = 'VideoGetItem'
         }
  
$kodiReq = Get-JSON -url http://$kodiHost/jsonrpc -object (ConvertTo-Json -InputObject $data) -user $user -pass $pass
$kodiRes = $kodiReq.psobject.properties.Value.GetValue(2)
  
#endregion Kodi

#region Sonarr

# Get Series Id
$Series = Invoke-RestMethod -Uri $getSeries -Method Get -Headers @{'X-Api-Key' = $sonarrApiKey}
$SerieId = $Series |
Where-Object -FilterScript {$_.Title -eq $kodiRes.item.showtitle} |
Select-Object -ExpandProperty id
  
# Get Episode Id
$Episodes = Invoke-RestMethod -Uri $getEpisodes$SerieId -Method Get -Headers @{'X-Api-Key' = $sonarrApiKey}
$EpisodeId = $Episodes |
Where-Object -FilterScript {$_.seriesId -eq $SerieId -and $_.seasonNumber -eq $kodiRes.item.season -and $_.episodeNumber -eq $kodiRes.item.episode} |
Select-Object -ExpandProperty id
  
# Unmonitor Episode
$data = @{
 SeriesId = $SerieId
       id = $EpisodeId
monitored = 'false'
         }

$Toggle = Invoke-RestMethod -Uri $getEpisodes$EpisodeId -Method Put -Body (ConvertTo-Json -InputObject $data) -Headers @{'X-Api-Key' = $sonarrApiKey}
  
#endregion Sonarr

 
