<div align="center">

  <h1>Uncensored Local AI — Moto G73 (MediaTek)</h1>

  <p><strong>Run unrestricted AI models entirely on your device.<br/>Optimized for the Motorola Moto G73 (Dimensity 930, 8 GB RAM).</strong></p>

  [Overview](#overview) · [Fork vs Main Project](#fork-vs-main-project) · [Download APK](#download-apk) · [Build from Source](#build-from-source) · [Install on Moto G73](#install-on-moto-g73) · [Quick Start](#quick-start) · [Recommended Models](#recommended-models)

</div>

---

## Overview

**Uncensored Local AI** is a mobile-first Flutter app that runs open-source GGUF models directly on your Android device — no cloud, no API keys, no content filters. Your conversations stay on your phone.

This repository is a **device-specific fork** of the upstream project, tuned for the **Motorola Moto G73** and other **MediaTek Dimensity** phones with **8 GB RAM**.

> Think of it as ChatGPT — but running **on your phone**, with **no rules**, and **no server**.

**Upstream (main project):** [techjarves/Uncensored-Local-AI-Multiplatform](https://github.com/techjarves/Uncensored-Local-AI-Multiplatform)

**Demo video (upstream):** [https://youtu.be/2Pnv68iHIaQ](https://youtu.be/2Pnv68iHIaQ)

---

## Fork vs Main Project

This fork inherits everything from the upstream **v2.0.0** release and adds Moto G73 / MediaTek fixes on top.

### Inherited from upstream (v2.0.0)

| Feature | Description |
|---------|-------------|
| **Zero censorship** | Runs abliterated / uncensored GGUF models with no corporate safety filters |
| **Total privacy** | All inference and chat history stay on-device |
| **Fully offline** | Works without internet after models are downloaded |
| **Model library** | Download, import, and manage `.gguf` models in-app |
| **Chat history** | Persistent conversations stored locally (Hive) |
| **Local OpenAI API** | Built-in HTTP server at `http://127.0.0.1:4891/v1` |
| **Live metrics** | Tokens/sec and model loading progress |
| **Global loading overlay** | Real-time feedback during large model imports |
| **Log viewer** | Share app logs for troubleshooting (Settings → Debugging) |
| **RAM/size validation** | Warns before loading models that may exceed device limits |
| **Instant model imports** | Fast file-move for local `.gguf` imports |
| **Cache management** | Clear temporary FilePicker cache from Settings |

See the upstream [CHANGELOG](CHANGELOG.md) and [v2.0.0 release notes](https://github.com/techjarves/Uncensored-Local-AI-Multiplatform/releases/tag/v2.0.0) for the full upstream history.

### Fork-specific changes (v1.1.1 — Moto G73)

These fixes address the two most common issues on MediaTek devices:

| Problem | Fix in this fork |
|---------|------------------|
| Chat runs out of tokens after 2–3 messages | Default context raised from **1024 → 2048** tokens; adaptive sizing by model size; automatic message trimming |
| Cannot switch LLM models | Explicit unload before switching; **Switch Model** button; CPU-safe defaults |
| OpenCL GPU crashes on MediaTek | **Apply Recommended Settings** now defaults to **CPU mode** (not OpenCL + 33 GPU layers) |
| Bloated system prompt eating context | Default system prompt shortened (~250 → ~30 tokens) |
| Wrong chat template per model | Chat UI now uses native `generateChatCompletion` (proper per-model templates) |
| No context control | New **Context Window** slider in Settings (1024–3072 tokens) |

> **After changing Settings → Context Window or Hardware Configuration, reload your model** for changes to take effect.

---

## Download APK

### Option A — GitHub Actions build (recommended)

Every push to `main` triggers an automatic ARM64 APK build.

1. Go to **[Actions](https://github.com/Inbodytester/uncensored-local-ai-multiplatform-MotoG73_Mediatek/actions)** on this repo
2. Click the latest **Build APK** workflow run with a green checkmark
3. Scroll to **Artifacts** at the bottom
4. Download **`app-arm64-v8a-release-spanish`** (this is the release APK despite the artifact name)
5. Unzip if needed — the file inside is `app-arm64-v8a-release.apk`

> **Moto G73 requires `arm64-v8a`.** Do not use x86 or armeabi builds.

### Option B — Build locally

See [Build from Source](#build-from-source) below, then install the APK from:

```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Option C — Upstream generic APK

If you want the unmodified upstream build (without Moto G73 fixes):

| APK | Link |
|-----|------|
| ARM64 (most phones) | [app-arm64-v8a-release.apk (v2.0.0)](https://github.com/techjarves/Uncensored-Local-AI-Multiplatform/releases/download/v2.0.0/app-arm64-v8a-release.apk) |

Use the **fork APK** for Moto G73 — the upstream build still has the 1024-token context limit and OpenCL defaults that cause problems on MediaTek.

---

## Build from Source

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel)
- **Java JDK 21** (for Android builds)
- Android SDK (via Android Studio or `flutter doctor` setup)
- macOS, Linux, or Windows

### Clone and build

```bash
git clone https://github.com/Inbodytester/uncensored-local-ai-multiplatform-MotoG73_Mediatek.git
cd uncensored-local-ai-multiplatform-MotoG73_Mediatek
flutter pub get
flutter build apk --release --target-platform android-arm64
```

The APK will be at:

```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Install directly to a connected phone (USB debugging enabled)

```bash
flutter install --release
```

### Build all Android architectures (optional)

```bash
flutter build apk --release
```

---

## Install on Moto G73

1. **Download** the `arm64-v8a` APK (see [Download APK](#download-apk))
2. On the phone: **Settings → Security → Install unknown apps** → enable for your browser or file manager
3. Open the downloaded APK and tap **Install**
4. If Android blocks it, confirm you trust the source — this app is not Play Store signed
5. Open **Uncensored Local AI**
6. When prompted, **disable battery optimization** for the app (prevents the OS from killing inference)
7. Go to **Models** → download **Gemma 2 2B Abliterated** (recommended for 8 GB RAM)
8. Tap **Load Model**, then start chatting

### First-time Settings (Moto G73)

1. Open **Settings**
2. Tap **Apply Recommended Settings** (sets CPU mode — safe for MediaTek)
3. Set **Context Window** to **2048** (good balance for 8 GB RAM)
4. Go back to **Models** and **reload** your model

---

## Quick Start

1. **Download & install** the APK ([instructions above](#install-on-moto-g73))
2. Open the app → **Models** tab
3. Download **Gemma 2 2B Abliterated** (~1.6 GB)
4. Tap **Load Model** and wait for the progress bar to reach 100%
5. Switch to **Chat** tab and send a message
6. To switch models: **Models** tab → tap **Switch Model** on another downloaded model

### Switching models

- Use the model picker in the chat top bar, or
- Go to **Models** and tap **Switch Model** on any downloaded model
- Stop any in-progress generation before switching

### Starting a fresh conversation

If the context window fills up on a long chat, tap **New Chat** (pencil icon) to start over with a clean history.

---

## Recommended Models

| Model | Size | Min RAM | Moto G73 (8 GB) |
|-------|------|---------|-----------------|
| **Gemma 2 2B Abliterated** | 1.6 GB | 4 GB | **Best choice — fast and stable** |
| **Phi-3.5 Mini** | 2.2 GB | 4 GB | Good alternative |
| **Dolphin 2.9 Llama 3 8B** | 4.9 GB | 8 GB | May load but slow; tight on RAM |
| **Gemma 4 E4B Heretic** | 5.3 GB | 8 GB | Not recommended — likely OOM or very slow |

> Models download inside the app from the **Models** tab. You can also import local `.gguf` files or add custom download URLs.

---

## Local API Server

Same as upstream — expose the loaded model to OpenAI-compatible clients:

1. Load a model in the app
2. **Settings → Local API Server** → toggle **ON**
3. Base URL: `http://127.0.0.1:4891/v1`
4. API key: `local` (if your client requires one)

```bash
curl http://127.0.0.1:4891/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"local","messages":[{"role":"user","content":"Hello"}]}'
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Chat stops after a few messages | Update to this fork's latest build; set Context Window to 2048; start a new chat |
| Model won't load / app crashes | Use **Gemma 2 2B**; apply **CPU** recommended settings; reduce GPU layers to 0 |
| Can't switch models | Stop generation first; use **Switch Model** button; wait for unload to finish |
| App killed in background | Disable battery optimization; keep screen on during first model load |
| Need help debugging | **Settings → Debugging → App Logs** → copy and share |

---

## Syncing with upstream

To pull in future changes from the main project:

```bash
git remote add upstream https://github.com/techjarves/Uncensored-Local-AI-Multiplatform.git
git fetch upstream
git merge upstream/main
# Resolve any conflicts, then test on Moto G73 before pushing
```

---

## Contributing

Bug reports and pull requests are welcome on this fork. If a fix applies to all devices, consider also contributing it upstream to [techjarves/Uncensored-Local-AI-Multiplatform](https://github.com/techjarves/Uncensored-Local-AI-Multiplatform).

---

## License

Based on the upstream **Uncensored Local AI Multi-Platform** project (MIT License).  
See upstream repo for full license details.

---

<div align="center">
  <sub>
    Fork of <a href="https://github.com/techjarves/Uncensored-Local-AI-Multiplatform">techjarves/Uncensored-Local-AI-Multiplatform</a>
    · Built with Flutter · Powered by <a href="https://github.com/ggerganov/llama.cpp">llama.cpp</a> via <a href="https://pub.dev/packages/llamadart">llamadart</a>
  </sub>
</div>