# 📘 **Microsoft Ecosystem Desktop Hub V1**  
### *Auto‑Slide Edge • Inline Search Engine • Windows 11 Fluent UI Launcher*





---

## 🟦 Überblick
Der **Microsoft Ecosystem Desktop Hub V1** ist ein vollständig eigenständiger, modularer Windows‑Launcher, der das gesamte Microsoft‑Ökosystem in einer kompakten, rahmenlosen Desktop‑App bündelt.

Er kombiniert:

- **Edge‑App‑Mode Launcher**  
- **Auto‑Slide‑Docking**  
- **Inline‑Search Engine (Copilot‑ähnlich)**  
- **Microsoft Learn API Integration**  
- **Bing News & Web RSS**  
- **Native Windows‑Protokolle (ms-settings:, windowsdefender:)**  
- **Fluent‑Design UI**  
- **Persistente Settings (INI‑Config)**  

Das Projekt ist vollständig **Open Source (MIT)** und kann frei erweitert werden.

---

## 🏆 Features

- **Auto‑Slide Edge Docking** — Orb gleitet an den Bildschirmrand  
- **Inline‑Search Engine**  
  - Wikipedia Summary  
  - Microsoft Learn API  
  - Bing News RSS  
  - Bing Web Fallback  
- **MSA / Entra ID Account Detection**  
- **Edge App‑Mode Launcher**  
- **40+ Microsoft Apps integriert**  
- **Windows‑Protokolle**  
  - `ms-settings:`  
  - `windowsdefender:`  
- **Persistente Einstellungen (INI)**  
- **Fluent‑Design UI**  
- **Dark Mode**  
- **Keine Telemetrie, keine Datenerfassung**  

---

## 📸 Screenshots

*(Hier kannst du später echte Bilder einfügen)*





---

## 🧩 Architektur

### **Module**
- `MSAccountDetector.cs`  
- `InlineSearchEngine.cs`  
- `AppItem.cs`  
- `HubPopupForm.cs`  
- `ConfigManager.cs`  
- `LauncherOrbForm.cs`  
- `Program.cs`  
- `build.ps1` (PowerShell Bootstrap)

### **Datenfluss**
```
User Input → InlineSearchEngine → (Wikipedia / MS Learn / Bing) → UI Renderer
AppTile Click → MSAccountDetector → Edge AppMode → Zielseite
Orb Movement → AutoSlideEdge → Persistente Position
```

---

## 🚀 Installation

### **1. Repository klonen**
```bash
git clone https://github.com/DEINNAME/MicrosoftEcosystemHub
```

### **2. Build ausführen**
```powershell
.\build.ps1
```

### **3. EXE starten**
Die Datei erscheint automatisch auf dem Desktop:

```
MicrosoftEcosystemHub.exe
```

---

## 🛠 Systemanforderungen
- Windows 10 / 11  
- .NET Framework 4.8  
- Microsoft Edge installiert  
- Internetverbindung für Inline‑Search  

---

## 📄 Lizenz (MIT)

```
MIT License

Copyright (c) 2026 Emanuel Schaaf

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

*(vollständiger Text in /LICENSE)*

---

## 🤝 Mitwirken

Pull Requests sind willkommen!  
Du kannst beitragen durch:

- neue App‑Module  
- UI‑Verbesserungen  
- neue Inline‑Search‑Quellen  
- Performance‑Optimierungen  
- Bugfixes  

---

## 💬 Kontakt

**Lead Architect:** Emanuel Schaaf  
Open Origin Architecture  
Pirmasens, Rheinland‑Pfalz, Deutschland

---

## 🔥 Bereit für den Upload?
