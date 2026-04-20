# 🧠 CerebroSim: Mobile Neural Research Lab

CerebroSim is a high-performance, mobile-first neuroscience sandbox built with Flutter. It simulates cerebellar learning dynamics based on the **Marr-Albus-Ito** theory of motor learning. 

Originally an educational prototype, CerebroSim has evolved into a dynamic research utility where users can configure complex neural topologies, run real-time reinforcement learning simulations, and save their architectural blueprints to a cloud-based community vault.

---

## ✨ Key Features

* **Real-Time 3D Neural Canvas:** A custom-painted, interactive 3D canvas that visualizes molecular, purkinje, and granular layers. Neurons light up and bloom dynamically as they fire in real-time.
* **Dynamic Network Configurator:** Break past hardcoded limits. Safely scale specific cell types (Granule Cells, Purkinje Cells, Basket Cells, Stellate Cells) to test how network topology affects learning convergence and processing speed.
* **Live Data Visualization:** Monitor learning progress with a high-performance Signal Plotter and a live Convergence Chart that tracks TD Error and Gain ratios directly below the simulation.
* **Four distinct Cerebellar Environments:**
  * 👁️ **Eyeblink Conditioning:** Pavlovian timing and association.
  * 〰️ **Sine Wave Tracking:** Rhythmic predictive adaptation.
  * 🔄 **Vestibulo-Ocular Reflex (VOR):** Simulating motor gain adaptation.
  * 🦾 **Arm Reaching:** Complex multi-joint kinematics.
* **The Research Vault:** Save specific snapshots of your experiments—including the exact network topology and learned synaptic weights—to Firebase. Browse, filter, and load public experiments from other researchers seamlessly using Deep Links.

---

## 🛠️ Tech Stack & Architecture

* **Framework:** [Flutter](https://flutter.dev/) (Mobile & Web)
* **State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod`) - Ensuring robust isolation between the mathematical simulation engine, UI state, and cloud sync.
* **Routing:** [GoRouter](https://pub.dev/packages/go_router) for strict, declarative deep-link support (`app_links`).
* **Backend:** [Firebase](https://firebase.google.com/) (FirebaseAuth for user identity, Firestore for Vault snapshots and database sync).
* **Architecture:** Strictly decoupled Domain-Driven Design (Models -> Providers -> Services -> UI/Widgets).

---

## 🚀 Getting Started

### 1. Prerequisites
* Flutter SDK (3.10+ recommended)
* Android Studio / Xcode (for mobile emulation)
* Firebase CLI installed (`npm install -g firebase-tools`)

### 2. Firebase Configuration
Because CerebroSim relies on Firebase for authentication and the Research Vault, you must provide your own Firebase configuration files to build the project.

1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Register an Android app with the package name: `com.mirkodibra.cerebrosim`
3. Download the `google-services.json` file and place it inside `android/app/`. *(Note: This file is intentionally `.gitignore`d).*
4. Run the FlutterFire CLI to generate your Dart configuration:
   ```bash
   flutterfire configure
   ```
   *(This will generate `lib/firebase_options.dart`, which is also `.gitignore`d).*

### 3. Build and Run
Clean your dependencies and run the application:

```bash
flutter clean
flutter pub get
flutter run
```

*(Note: Web deep-linking is handled natively by the browser, while Android/iOS use the `app_links` package. The app includes built-in safeguards to prevent unsupported stream initialization on the Web).*

---

## 📂 Project Structure

```text
lib/
├── main.dart                 # App entry point, Firebase init, Riverpod scope
├── models/                   # Immutable data classes (NetworkConfig, NeuronModel, SimulationState)
├── providers/                # Riverpod state notifiers (Simulation, Vault, Environment, Auth)
├── router/                   # GoRouter configuration and DeepLink handling
├── screens/                  # Top-level UI pages (SimulateScreen, VaultScreen, NetworkConfigScreen)
├── services/                 # Core logic (SimulationEngine, Auth/Database services, Environments)
└── widgets/                  # Reusable UI components (NeuralCanvas3D, SignalPlotter, HUD overlays)
```

---

## 🧪 Simulation Engine Guardrails
To prevent device overheating and CPU throttling, CerebroSim enforces biologically inspired topological limits (e.g., max 50 Granule Cells). Building networks exceeding 30 total neurons will trigger a UI warning regarding potential `10x` simulation speed degradation. The UI is completely isolated from the mathematical engine, meaning adjusting slider configurations will never interrupt an actively running episode until explicitly applied.

---
*Developed by Mirko Dibra.*