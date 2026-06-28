#!/usr/bin/env python3
"""Transcribe both 怪獸訓練 audio files with faster-whisper."""
import os
import sys
import time
from pathlib import Path

from faster_whisper import WhisperModel

TRANSCRIPT_DIR = Path("/tmp/gymsong_transcripts")
AUDIO_FILES = [
    ("UbjFYu2tvQ0.mp3", "video1_ep122.txt"),
    ("-54gLGdnmQE.mp3", "video2_book.txt"),
]
INITIAL_PROMPT = (
    "這是一段關於肌力訓練、怪獸訓練、何立安老師、漸進式超負荷、週期化、"
    "最大肌力、肌肥大、肌耐力、爆發力、深蹲、硬舉、臥推、肩推、"
    "引體向上、農夫走路、課表設計、deload、RM 區間的繁體中文演講。"
)


def main():
    print("Loading model (medium, int8)...", flush=True)
    t0 = time.time()
    model = WhisperModel("medium", device="cpu", compute_type="int8", num_workers=2)
    print(f"Model loaded in {time.time() - t0:.1f}s", flush=True)

    for audio, out in AUDIO_FILES:
        in_path = TRANSCRIPT_DIR / audio
        out_path = TRANSCRIPT_DIR / out
        print(f"\n=== Transcribing {audio} ===", flush=True)
        t1 = time.time()
        segments, info = model.transcribe(
            str(in_path),
            language="zh",
            beam_size=5,
            initial_prompt=INITIAL_PROMPT,
            vad_filter=True,
        )
        print(f"Duration: {info.duration:.1f}s, lang_prob: {info.language_probability:.2f}", flush=True)

        with open(out_path, "w", encoding="utf-8") as f:
            for seg in segments:
                line = seg.text.strip()
                if line:
                    f.write(line + "\n")
                    # progress print every ~30s of audio
                    if int(seg.end) % 30 < 1:
                        print(f"  [{int(seg.end)}s/{int(info.duration)}s]", flush=True)

        elapsed = time.time() - t1
        rtf = elapsed / info.duration
        size = out_path.stat().st_size
        print(f"Done: {out} ({size} bytes, {elapsed:.1f}s wallclock, {rtf:.2f}x real-time)", flush=True)


if __name__ == "__main__":
    main()
