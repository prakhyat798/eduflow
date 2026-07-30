<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=Outfit&weight=700&size=40&pause=1000&color=6C63FF&center=true&vCenter=true&width=600&lines=EduFlow+%F0%9F%8E%93;AI-Powered+Learning%2C+Reimagined" alt="EduFlow" />

<br/>

**EduFlow** is a next-generation AI-powered skill learning and productivity app built with Flutter. It transforms how you learn — combining micro-lessons, AI tutoring, smart focus modes, and habit tracking into one seamless experience.

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Gemini AI](https://img.shields.io/badge/Gemini_AI-Powered-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-6C63FF?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-success?style=for-the-badge)](https://flutter.dev)

</div>

---

## ✨ Features

| Feature | Description |
|---|---|
| 🤖 **AI Micro-Lessons** | Bite-sized AI-generated lessons tailored to your learning goals |
| 🗺️ **Roadmap Generator** | Personalized learning roadmaps powered by Gemini AI |
| 📝 **Smart Quiz** | Adaptive quizzes that test and reinforce your knowledge |
| 📄 **PDF Scanner & Reader** | Scan physical documents or import PDFs and study from them |
| 🎙️ **Voice Input** | Interact with the AI tutor using your voice via speech-to-text |
| 🔔 **Smart Alarms & Reminders** | Schedule study sessions with a built-in alarm system |
| 🔥 **Streak Tracker** | Stay consistent with daily learning streak tracking |
| 🧘 **Focus Mode** | Distraction-free study sessions with a dedicated focus screen |
| 📊 **Stats & History** | Visualize your learning progress, history, and milestones |
| 🗒️ **Notes** | Take and save notes while studying |

---

## 🛠️ Tech Stack

<div align="center">

| Layer | Technology |
|---|---|
| **Framework** | [Flutter](https://flutter.dev) (Dart) |
| **AI Engine** | [Google Gemini AI](https://ai.google.dev) (`google_generative_ai`) |
| **Voice** | Speech-to-Text + Flutter TTS |
| **PDF** | Syncfusion PDF · File Picker · Document Scanner |
| **Storage** | Shared Preferences |
| **Fonts** | Google Fonts |
| **Alarms** | `alarm` package |
| **Sharing** | `share_plus` |
| **Platform** | Android · iOS · Web · macOS · Windows · Linux |

</div>

---

## 📁 Project Structure

```
eduflow/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── models/
│   │   └── item.dart              # Data models
│   ├── screens/
│   │   ├── home_screen.dart       # Main dashboard
│   │   ├── main_screen.dart       # Navigation shell
│   │   ├── onboarding_screen.dart # First-launch onboarding
│   │   ├── micro_lesson_screen.dart  # AI-powered micro lessons
│   │   ├── roadmap_screen.dart    # Learning roadmap generator
│   │   ├── quiz_screen.dart       # Adaptive quiz engine
│   │   ├── focus_screen.dart      # Focus / Pomodoro mode
│   │   ├── alarm_ring_screen.dart # Alarm & reminder system
│   │   ├── notes_screen.dart      # Notes editor
│   │   ├── pdf_screen.dart        # PDF reader
│   │   ├── scanner_screen.dart    # Document scanner
│   │   ├── history_screen.dart    # Learning history
│   │   └── stats_screen.dart      # Progress statistics
│   └── services/
│       ├── ai_service.dart        # Gemini AI integration
│       ├── reminder_service.dart  # Alarm & notification logic
│       └── streak_service.dart    # Daily streak management
├── assets/
│   ├── images/focus_bg.jpg        # Focus mode background
│   └── alarm.mp3                  # Alarm sound
├── pubspec.yaml                   # Dependencies
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- [Dart SDK](https://dart.dev/get-dart) `>=3.0.0`
- A Google Gemini API key ([get one here](https://aistudio.google.com/app/apikey))

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/prakhyat798/eduflow.git
cd eduflow

# 2. Install dependencies
flutter pub get

# 3. Add your Gemini API key
#    Open lib/services/ai_service.dart and set your API key

# 4. Run the app
flutter run
```

### Build for Release

```bash
# Android APK
flutter build apk --release

# iOS (requires macOS + Xcode)
flutter build ios --release

# Web
flutter build web --release
```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 📬 Contact

**Prakhyat** — [@prakhyat798](https://github.com/prakhyat798)

Project Link: [https://github.com/prakhyat798/eduflow](https://github.com/prakhyat798/eduflow)

---

<div align="center">

Made with ❤️ and Flutter

⭐ Star this repo if you found it helpful!

</div>
