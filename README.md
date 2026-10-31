# 📘 Microsoft Ecosystem Desktop Hub V1  
### *Kurze Projektbeschreibung & Funktionsübersicht*

---

## 🟦 **Kurzbeschreibung**
Der **Microsoft Ecosystem Desktop Hub V1** ist ein kompakter, rahmenloser Windows‑Launcher, der das gesamte Microsoft‑Ökosystem in einer einzigen App bündelt.  
Er bietet schnellen Zugriff auf Microsoft‑Dienste, eine integrierte Inline‑Suchmaschine und eine moderne Fluent‑Design‑Oberfläche — komplett ohne Telemetrie und vollständig lokal auf deinem System.

---

## 🧩 **Was das Tool enthält**

### 🔹 **1. Edge‑App‑Mode Launcher**  
Öffnet alle Microsoft‑Dienste direkt im Edge‑App‑Fenster (`--app`), ohne Browser‑Rahmen.

### 🔹 **2. Auto‑Slide‑Orb (Docking)**  
Der Launcher kann an den Bildschirmrand gleiten und dort als kleiner Orb „parken“.

### 🔹 **3. Inline‑Search Engine (Copilot‑ähnlich)**  
Die Suchfunktion kombiniert mehrere Quellen:
- Wikipedia Summary  
- Microsoft Learn / Docs API  
- Bing News RSS  
- Bing Web Fallback  

Ergebnisse werden direkt im Hub angezeigt.

### 🔹 **4. Microsoft Account Detection (MSA / Entra ID)**  
Das Tool erkennt:
- Windows‑Registry‑Einträge  
- Edge‑Profil‑Daten  
und zeigt an, ob ein Microsoft‑Konto aktiv ist.

### 🔹 **5. 40+ Microsoft‑Apps integriert**  
Beispiele:
- Outlook  
- OneDrive  
- Copilot  
- Office 365  
- Teams  
- Xbox Cloud  
- MS Store  
- Azure Portal  
- Defender  
- Windows Update  
- Bing Maps  
- Power BI  
u.v.m.

### 🔹 **6. Native Windows‑Protokolle**  
Unterstützt direkte Systemaufrufe:
- `ms-settings:`  
- `windowsdefender:`  

### 🔹 **7. Persistente Einstellungen (INI‑Datei)**  
Speichert:
- Position  
- AlwaysOnTop  
- AppMode  
- AutoSlideEdge  

### 🔹 **8. PowerShell‑Buildsystem**  
Im Ordner **build/** liegt die Datei:

```
build.ps1
```

Sie kompiliert das Projekt und erzeugt die EXE + Icon.

---

## 🛠 **Verzeichnisstruktur (vereinfacht)**

```
MicrosoftEcosystemHub/
│
├── src/              → C#‑Code
├── build/            → build.ps1
├── README.md         → Projektbeschreibung
├── LICENSE           → MIT‑Lizenz
└── .gitignore
```

---

## 📝 **README‑Kurzversion (für GitHub)**

Hier ist die **komplette, kurze README**, die du direkt einfügen kannst:

---

# Microsoft Ecosystem Desktop Hub V1

Der Microsoft Ecosystem Desktop Hub ist ein kompakter Windows‑Launcher, der das gesamte Microsoft‑Ökosystem in einer einzigen App bündelt.  
Er bietet schnellen Zugriff auf über 40 Microsoft‑Dienste, eine integrierte Inline‑Suchmaschine (Wikipedia, Microsoft Learn, Bing) sowie native Windows‑Protokolle wie `ms-settings:` und `windowsdefender:`.

## Features
- Edge‑App‑Mode Launcher (`--app`)
- Auto‑Slide‑Orb (Docking)
- Inline‑Search Engine (Wikipedia / MS Learn / Bing)
- Microsoft Account Detection (MSA / Entra ID)
- 40+ Microsoft‑Apps integriert
- Native Windows‑Protokolle
- Persistente Einstellungen (INI)
- PowerShell‑Buildsystem (build.ps1)
- Keine Telemetrie, vollständig lokal

## Build
Im Ordner **build/** befindet sich die Datei:

```
build.ps1
```

Sie kompiliert das Projekt und erzeugt die ausführbare Datei.

## Lizenz
MIT License — frei nutzbar, veränderbar und erweiterbar.
