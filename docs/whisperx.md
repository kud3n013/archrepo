# WhisperX (`whisperx`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-3.8.6--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-GitHub-informational)](https://github.com/m-bain/whisperX)

Automatic speech recognition with word-level timestamps and speaker diarization, built on faster-whisper, wav2vec2 alignment and pyannote.

---

## 📥 Installation

```bash
sudo pacman -S whisperx
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `whisperx` |
| **Current Version** | `3.8.6-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [m-bain/whisperX](https://github.com/m-bain/whisperX) |
| **Category** | Audio & Video |

---

### Overview
WhisperX transcribes audio with faster-whisper, then aligns every word to the audio with a wav2vec2 model, so subtitles and transcripts get accurate word-level timestamps. With `--diarize` it also labels speakers through pyannote.

Upstream pins `torch ~= 2.8.0` and Python `< 3.14`. Arch ships a newer PyTorch and Python 3.14, so this package does not use them. It carries its own standalone CPython 3.13 (installed by `uv`) in `/opt/whisperx`, with WhisperX and its dependencies from PyPI. The WhisperX wheel itself is pinned by checksum; the dependencies resolve at build time within upstream's pins. `/usr/bin/whisperx` links to the CLI.

The `pypi` check in `check-upstream.sh` follows PyPI, not GitHub tags, so a new version is built only once its wheel is on PyPI.

### CPU only
PyTorch is the CPU build. The CUDA build with NVIDIA's runtime wheels is several gigabytes and would exceed GitHub's 2 GiB limit per release asset, and torch 2.8 needs CUDA 12.8 while Arch ships CUDA 13. `triton`, which only serves `torch.compile` on CUDA, is left out.

Use `--device cpu --compute_type int8` (or `float32`); the default `float16` is GPU-only:

```bash
whisperx audio.mp3 --model small --device cpu --compute_type int8 --language en
```

### Notes
- **Models download on first use.** Whisper models go to `~/.cache/huggingface`, alignment models to `~/.cache/torch`, and NLTK sentence data to `~/nltk_data`. Point `HF_HOME`, `TORCH_HOME` and `NLTK_DATA` elsewhere to move them.
- **Speaker diarization** needs a Hugging Face read token (`--hf_token`) and the accepted user agreement for [pyannote/speaker-diarization-community-1](https://huggingface.co/pyannote/speaker-diarization-community-1).
- **Not importable from system Python.** The `whisperx` module lives in `/opt/whisperx`, which uses Python 3.13. Run scripts with `/opt/whisperx/bin/python3.13` to `import whisperx`.
- **ffmpeg** decodes the input audio, so any format ffmpeg reads works.

## 🔗 Related Links

- [m-bain/whisperX](https://github.com/m-bain/whisperX)
- [whisperx on PyPI](https://pypi.org/project/whisperx/)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
