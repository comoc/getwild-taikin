# GET WILD 退勤 — Siri起動フレーズをTTSで発話する。
# 近くのApple端末(iPhone/Mac/HomePod)の「Hey Siri」が拾って曲を再生することを狙う。
#
# 使い方:
#   pwsh -File speak.ps1                       # 既定フレーズを発話
#   pwsh -File speak.ps1 -Phrase "..."         # フレーズ指定
#   pwsh -File speak.ps1 -OutFile out.wav      # 発話せずWAVに書き出し(テスト用/無音)
#
param(
    [string]$Phrase = "ヘイSiri、GET WILDを流して",
    [string]$OutFile = ""
)

Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.Volume = 100   # 0-100。Siriに届くよう最大。
$synth.Rate = 0       # -10..10。0=標準。

# 日本語ボイスがあれば優先（"Hey Siri"の英語混じりも実用上は拾われる）。
$jp = $synth.GetInstalledVoices() |
    Where-Object { $_.VoiceInfo.Culture.Name -like "ja*" } |
    Select-Object -First 1
if ($jp) { $synth.SelectVoice($jp.VoiceInfo.Name) }

if ($OutFile) {
    $synth.SetOutputToWaveFile($OutFile)   # 無音でファイルに合成（動作確認用）
    $synth.Speak($Phrase)
    $synth.SetOutputToDefaultAudioDevice()
    Write-Output "wrote: $OutFile"
} else {
    $synth.Speak($Phrase)                  # スピーカーから発話
    Write-Output "spoke: $Phrase"
}
$synth.Dispose()
