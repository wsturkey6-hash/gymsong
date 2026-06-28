# 怪獸訓練影片轉錄稿

這份資料夾收的是 `GymSong/Resources/monster_training_principles.md` 的原始參考來源——
何立安老師兩段 YouTube 影片的中文逐字轉錄稿。**不會被打包進 app**，純為 prompt 迭代用。

## 檔案

| 檔案 | 原始影片 | 長度 |
|---|---|---|
| `EP122_podcast_UbjFYu2tvQ0.txt` | [EP122 你需要的一本書：肌力課程設計](https://www.youtube.com/watch?v=UbjFYu2tvQ0) | 1:03:19 |
| `book_analysis_-54gLGdnmQE.txt` | [《怪獸訓練肌力課程設計：打造最強壯版本的自己》](https://www.youtube.com/watch?v=-54gLGdnmQE) | 49:26 |

## 怎麼產出來的

兩支影片都沒有官方字幕也沒自動字幕，所以做了：

1. `yt-dlp` 下載音訊（需要 `--extractor-args "youtube:player_client=ios,web_safari,android"` 繞過 YouTube 的 SABR streaming 強制）
2. `faster-whisper` 本地轉錄（medium 模型、int8 量化、Traditional Chinese、附帶 strength-training initial prompt 提升專業術語辨識）

執行 script：`transcribe.py`

辨識率約 90%，少數錯字（例如「肌力」變「激勵」、「Stuart McGill」變「術中麥可」）但脈絡都讀得懂。

## 何時需要動到這份檔案

**改 `GymSong/Resources/monster_training_principles.md` 時**——如果發現生成的課表偏離書中精神，
或想加強某個原則，回來這裡查作者原本怎麼講，比憑印象寫更準。

特別是有些原則只在 podcast 的閒談中提到一次（例如脊椎負重週期性），這裡留有完整脈絡。

## 重新轉錄其他影片

`transcribe.py` 寫死了現在這兩個檔案路徑，要轉新影片直接改 `AUDIO_FILES` 那個 list 就好。
依賴：
- `pip3 install --user yt-dlp faster-whisper`
- `ffmpeg`（macOS：到 https://evermeet.cx/ffmpeg/ 下載 zip，解壓後丟 `~/bin/`）

下載新影片音訊：

```sh
python3 -m yt_dlp -x --audio-format mp3 \
  --extractor-args "youtube:player_client=ios,web_safari,android" \
  -o "%(id)s.%(ext)s" \
  --ffmpeg-location ~/bin/ffmpeg \
  "<YouTube URL>"
```
