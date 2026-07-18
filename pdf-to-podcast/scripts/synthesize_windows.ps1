# Windows-only: synthesize speech using the built-in System.Speech API.
# Only works when run directly on Windows - not available in this sandbox.
# Usage: powershell -File synthesize_windows.ps1 -InputFile script.txt -OutputFile podcast.wav [-Voice "Microsoft Zira Desktop"] [-Rate 0]
#
# List available voices with:
#   Add-Type -AssemblyName System.Speech
#   (New-Object System.Speech.Synthesis.SpeechSynthesizer).GetInstalledVoices() | ForEach-Object { $_.VoiceInfo.Name }
#
# Output is WAV (Windows has no built-in mp3 encoder). Convert afterwards with ffmpeg if needed:
#   ffmpeg -i podcast.wav -codec:a libmp3lame -qscale:a 2 podcast.mp3

param(
    [Parameter(Mandatory=$true)][string]$InputFile,
    [Parameter(Mandatory=$true)][string]$OutputFile,
    [string]$Voice = "",
    [int]$Rate = 0
)

Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

if ($Voice -ne "") {
    $synth.SelectVoice($Voice)
}
$synth.Rate = $Rate

$text = Get-Content -Raw -Path $InputFile
$synth.SetOutputToWaveFile($OutputFile)
$synth.Speak($text)
$synth.Dispose()

Write-Host "Saved $OutputFile"
