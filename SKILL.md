---
name: getwild-taikin
description: >-
  設定した退勤時刻になったら、TTS(音声合成)で「ヘイSiri、GET WILDを流して」と発話し、
  近くのApple端末(iPhone/Mac/HomePod)のHey Siriに GET WILD を再生させる退勤アラーム。
  ユーザーが「退勤時刻を◯◯にして」「退勤したらGET WILD流して」「退勤アラーム」「定時になったらSiriに言わせて」
  などと言ったら、明示的にスキル名を出されなくても必ずこのスキルを使うこと。
  時刻の監視はこのセッション自身が ScheduleWakeup で行う。Windows前提。
---

# GET WILD 退勤アラーム

退勤時刻になったら、この PC の音声合成で「ヘイSiri、GET WILDを流して」と発話する。
狙いは、声の届く距離にある Apple 端末（iPhone / Mac / HomePod、Hey Siri 有効）がそれを拾い、
Apple Music で GET WILD を再生すること。退勤の瞬間に自動で曲が流れ出す、あの演出を実現する。

## 仕組み（このセッションが時計を見張る）

このスキルは常駐プロセスではなく、セッション自身が `ScheduleWakeup` で退勤時刻まで眠って、
起きて発話する。つまり **この Claude Code セッションと PC が起動している間だけ**有効。
（Claude を閉じても毎日自動で鳴らしたい場合は、末尾「代替案」を参照。）

## 手順

### 1. 退勤時刻を確定する

ユーザーの指定（例「18:00」「定時＝17:30」「あと2時間後」）を今日の目標時刻として解釈する。
現在時刻は必ず実測する。PowerShell なら `Get-Date -Format "yyyy-MM-dd HH:mm:ss"`、
Bash なら `date "+%Y-%m-%d %H:%M:%S"`。頭の中の時刻で計算しない（ずれる）。

- 目標時刻が**まだ先**なら、その差分（秒）を計算して 2. へ。
- 目標時刻が**すでに過ぎている**なら、勝手に翌日にせず、
  「もう過ぎています。明日のこの時刻でセットしますか？」と一度確認する。

セット完了時は、ユーザーに「◯時◯分に『ヘイSiri、GET WILDを流して』と発話します」と伝える。
併せて、Apple 端末側の準備（Hey Siri を有効化し、声の届く場所に置く／音量確保）を一言リマインドする。

### 2. 退勤時刻まで眠って待つ（ScheduleWakeup ループ）

`ScheduleWakeup` の `delaySeconds` は 60〜3600 に制限される。退勤まで1時間以上あるなら、
一度で待ち切れないので、起きるたびに残り時間を計算し直しながら刻んで待つ。

各回の判断：
- 残り秒 `R` を実測時刻から再計算する。
- `R > 3300` … `delaySeconds ≒ 3000` でまた眠る（`prompt` は同じ /loop 入力を渡し、次回もこの手順に戻す）。
- `75 < R <= 3300` … `delaySeconds = R - 60` くらいで眠り、目標の少し手前で起きる。
- `R <= 75` … これが最終レグ。ここで発話（3. へ）。1分程度の誤差は退勤チャイムとして許容範囲。

`ScheduleWakeup` を使わずユーザーが `/loop` 経由で起動している場合も、考え方は同じ
（毎ティックで残り時間を見て、到達したら発話）。

### 3. 発話する

同梱スクリプトを実行する。パスはこのスキルの `scripts/speak.ps1`。

```
pwsh -File "<スキルのベースディレクトリ>/scripts/speak.ps1"
```

既定フレーズが「ヘイSiri、GET WILDを流して」。別フレーズを指定したいときは
`-Phrase "..."` を付ける。スクリプトは日本語ボイスがあれば選び、音量を最大にして発話する。

発話後、「退勤発話しました。おつかれさまでした。」と短く伝えて終了する。ここは演出を盛らない。

## 動作確認（音を出さずにテスト）

セットアップ前に合成が通るか確かめたいときは、WAV に書き出す（スピーカーは鳴らない）：

```
pwsh -File "<スキルのベースディレクトリ>/scripts/speak.ps1" -OutFile "%TEMP%/gw_test.wav"
```

ファイルが生成されれば音声合成は動作している。実際に Siri が反応するかは、
一度スピーカーから鳴らして Apple 端末が拾うか各自で確認してもらう。

## つまずきやすい点

- **Siri が拾わない**：Apple 端末の「Hey Siri」が有効か、PC スピーカーの音量が十分か、
  端末が声の届く距離にあるかを確認。日本語ボイスの「Hey Siri」発音が甘い場合は、
  `-Phrase "Hey Siri, GET WILDを流して"` のように英語寄りに調整して試す。
- **曲が違う／再生されない**：Siri 側の言語設定と、Apple Music で "GET WILD" が
  再生可能かに依存する。フレーズを「TM NETWORKのGET WILDを流して」等に具体化すると当たりやすい。
- **時刻がずれる**：計算前に必ず現在時刻を実測する。長時間待つ場合は起きるたびに再計算する。

## 代替案：Claude を閉じても毎日自動で鳴らす

セッション常駐が煩わしく、毎営業日に自動で鳴らしたいだけなら、Windows タスクスケジューラに
`speak.ps1` を登録するほうが確実。ユーザーが希望したらこの方式に切り替える：

```
$action  = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument '-File "D:/Skills/getwild-taikin/scripts/speak.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 18:00
Register-ScheduledTask -TaskName "GetWildTaikin" -Action $action -Trigger $trigger -Description "退勤時刻にSiri起動フレーズを発話"
```

時刻や曜日（平日のみ等）は要望に合わせて調整する。この方式なら Claude も本セッションも不要になる。
