# Security Policy for Arivu AI (ಅರಿವು AI)

Arivu AI is committed to providing an uncompromising, air-gapped, privacy-first mobile AI assistant. We take security, supply-chain verification, and local hardware safety seriously.

---

## Supported Versions

Security updates and patches are applied to the active release branch:

| Version | Supported |
|---|---|
| 1.0.x | :white_check_mark: |
| < 1.0 | :x: |

---

## 🛡️ Zero-Cloud Threat Model & Security Posture

Arivu AI is architecturally engineered so that user data **never leaves the mobile device**.

### 1. Complete Air-Gapped Inference
- All text token generation, prompt evaluation, context management, and voice processing run strictly inside local process memory via embedded C++ `llama.cpp` (`llamadart`).
- No prompt, chat turn, document content, or voice sample is ever transmitted over the network or logged to external servers.

### 2. Network Boundary & Model Acquisition
- An active network connection is utilized **strictly and exclusively** during the initial download of quantized GGUF model weights from the Hugging Face CDN (or when downloading additional catalog models in Settings).
- The network interface is never opened or invoked during chat inference, voice conversation loops, document search, or tool execution.

### 3. Local Storage Isolation
- Conversation history, message turns, and scheduled reminders are stored in an internal SQLite database (`chat_history.db`) placed in Android's private app directory (`/data/data/com.example.arivu_ai/databases/`).
- `android:allowBackup="false"` is enforced in `AndroidManifest.xml` to prevent automated Google Drive cloud backups or unauthorized ADB desktop backup extraction.
- A permanent, atomic *Wipe All Chat History* action in Settings permanently deletes all local records from device flash storage.

### 4. Supply-Chain Integrity & Cryptographic Checksums
- Model weights fetched from public repositories are validated before being loaded into native memory:
  1. **Binary Magic Header**: Verified against GGUF specification bytes (`0x47, 0x47, 0x55, 0x46`).
  2. **Cryptographic Checksum**: Validated against known SHA-256 digests via streaming chunked hashing to prevent corrupted or tampered binaries from executing.

### 5. Local Hardware & Device Intent Safety
- Device actions (setting alarms, countdown timers, scheduled reminders, flashlight toggling, app launches) are dispatched through Android platform intents (`android_intent_plus`) and system services.
- Deterministic regex patterns ensure device tools execute safely without LLM hallucination or unintended actions.

---

## 🚨 Reporting a Vulnerability

If you discover a security vulnerability, unintended network transmission, or data leak within Arivu AI, please report it responsibly:

1. **Do not create a public GitHub issue.**
2. Send a detailed report to the maintainers via **GitHub Security Advisories** (`Security > Report a vulnerability`) or email the repository owner directly.
3. Please include:
   - A description of the issue and potential impact.
   - Exact steps or code to reproduce the vulnerability.
   - Operating system version and device model.
   - Any packet inspection or network capture logs if reporting unexpected network activity.

### Response & Disclosure Policy
- We will acknowledge receipt of your report within **48 hours**.
- We will provide a status assessment and coordinated disclosure plan within **7 days**.
- Once a fix is verified, a patch will be published in a new release and credited in our release notes.
