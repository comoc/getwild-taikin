# GET WILD 退勤アラーム

設定した退勤時刻になると、PC の音声合成(TTS)で **「ヘイSiri、GET WILDを流して」** と発話し、
近くの Apple 端末（iPhone / Mac / HomePod、Hey Siri 有効）にそれを拾わせて
Apple Music で GET WILD を再生させる、退勤アラームスキルです。

退勤の瞬間に自動で曲が流れ出す、あの演出を実現します。

## 仕組み

このスキルは常駐プロセスではなく、Claude Code のセッション自身が `ScheduleWakeup` で
退勤時刻まで眠り、起きて発話します。つまり **セッションと PC が起動している間だけ**有効です。

```
退勤時刻を受け取る
  → 現在時刻を実測して差分を計算
  → ScheduleWakeup で刻んで待機（60〜3600秒の制限に対応してループ）
  → 到達したら speak.ps1 で発話
  → 近くの Apple 端末が Hey Siri で拾って再生
```

## 構成

```
getwild-taikin/
├── SKILL.md            スキル本体（動作仕様）
├── scripts/speak.ps1   TTS発話スクリプト（Windows / System.Speech）
├── evals/evals.json    テストケース
└── README.md
```

## Claude へのインストール

Claude Code の**ユーザースキル**として登録すると、どのプロジェクトからでも使えます。
`~/.claude/skills/` 配下にこのリポジトリを置くだけです（`SKILL.md` がフォルダ直下に来るように配置）。

```bash
# ユーザースキルとして clone（推奨）
git clone git@github.com:comoc/getwild-taikin.git ~/.claude/skills/getwild-taikin
```

Windows（PowerShell）の場合：

```powershell
git clone git@github.com:comoc/getwild-taikin.git "$env:USERPROFILE\.claude\skills\getwild-taikin"
```

特定のプロジェクトだけで使いたいときは、`~/.claude/skills/` の代わりに
そのプロジェクトの `.claude/skills/getwild-taikin` に置きます。

インストール後、Claude Code を起動し直すとスキルが認識されます。
配置を確認するには `/skills`（または起動時のスキル一覧）に `getwild-taikin` が出ていればOKです。

> パッケージ版 `.skill` ファイルを使う場合は、その `.skill` を Claude 側のスキル取り込み手順に従って読み込んでください。

## 使い方

Claude Code に次のように話しかけると起動します（スキル名を明示しなくてもOK）：

- 「退勤時刻を18:00にして。定時になったらSiriにGET WILD流させて」
- 「あと30分後に退勤アラーム鳴らして」

**事前準備**：Apple 端末側で「Hey Siri」を有効にし、PC スピーカーの声が届く場所に置き、音量を確保してください。

### スクリプト単体で動かす

```powershell
# 既定フレーズを発話
pwsh -File scripts/speak.ps1

# フレーズ指定（Siri が反応しないときは英語寄りに）
pwsh -File scripts/speak.ps1 -Phrase "Hey Siri, GET WILDを流して"

# 音を出さず合成だけ確認（WAV書き出し）
pwsh -File scripts/speak.ps1 -OutFile "$env:TEMP/gw_test.wav"
```

## つまずいたら

- **Siri が反応しない** … Hey Siri が有効か、音量が十分か、端末が声の届く距離にあるか確認。
  日本語ボイスの "Hey Siri" 発音が甘い場合は `-Phrase "Hey Siri, GET WILDを流して"` を試す。
- **曲が違う / 見つからない** … フレーズを「TM NETWORKのGET WILDを流して」等に具体化する。
- **時刻がずれる** … スキルは待機のたびに現在時刻を実測して再計算します。

## Claude を閉じても毎日自動で鳴らしたい場合

Windows タスクスケジューラに `speak.ps1` を登録すると、Claude もセッションも不要になります。

```powershell
$action  = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument '-File "D:/Skills/getwild-taikin/scripts/speak.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 18:00
Register-ScheduledTask -TaskName "GetWildTaikin" -Action $action -Trigger $trigger -Description "退勤時刻にSiri起動フレーズを発話"
```

## 動作環境

- Windows（PowerShell / System.Speech による TTS）
- Hey Siri 対応の Apple 端末（声の届く距離）
- Apple Music で GET WILD が再生可能なこと
