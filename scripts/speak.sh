#!/usr/bin/env bash
# GET WILD 退勤 — Siri起動フレーズをmacOSの say で発話する。
# 近くのApple端末(iPhone/Mac/HomePod)の「Hey Siri」が拾って曲を再生することを狙う。
# （同じMacのSiriに直接届かせても良い。）
#
# 使い方:
#   ./speak.sh                          # 既定フレーズを発話
#   ./speak.sh --phrase "..."           # フレーズ指定（-Phrase も可）
#   ./speak.sh --out out.aiff           # 発話せずファイルに書き出し（-OutFile も可・無音）
#
set -euo pipefail

PHRASE="ヘイSiri、GET WILDを流して"
OUT=""

while [ $# -gt 0 ]; do
    case "$1" in
        -Phrase|--phrase) PHRASE="$2"; shift 2 ;;
        -OutFile|--out)   OUT="$2";    shift 2 ;;
        *) shift ;;
    esac
done

# 日本語ボイスがあれば優先（Kyoko/Otoya など）。無ければ既定ボイス。
VOICE=()
if say -v '?' 2>/dev/null | grep -qi 'Kyoko'; then
    VOICE=(-v Kyoko)
elif say -v '?' 2>/dev/null | grep -qi 'Otoya'; then
    VOICE=(-v Otoya)
fi

if [ -n "$OUT" ]; then
    say "${VOICE[@]}" -o "$OUT" "$PHRASE"   # 無音でファイルに合成（動作確認用）
    echo "wrote: $OUT"
else
    say "${VOICE[@]}" "$PHRASE"             # スピーカーから発話
    echo "spoke: $PHRASE"
fi
