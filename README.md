# 🗳️ Enterprise Blockchain Voting System

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Hyperledger Fabric](https://img.shields.io/badge/Hyperledger_Fabric-2F3134?style=for-the-badge&logo=hyperledger&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)
![Express.js](https://img.shields.io/badge/Express.js-404D59?style=for-the-badge&logo=express&logoColor=white)

A state-of-the-art, secure, and visually immersive blockchain voting simulation. Designed to demonstrate the immutability of distributed ledgers in electoral systems, this project pairs an enterprise-grade **Hyperledger Fabric** backend with a stunning, highly animated **Flutter Web** "Auditor Dashboard."

---

## ✨ Key Features

- **Premium Glassmorphism UI:** Built with Flutter Web, featuring true frosted-glass (`dart:ui BackdropFilter`), elegant `.slideY()` micro-animations, and interactive data visualization via `fl_chart`.
- **Hyperledger Fabric Gateway SDK:** The Express backend leverages the modern gRPC Fabric Gateway to submit transactions directly to the smart contracts (chaincode).
- **Smart "Mock Fallback" Engine:** No Docker? No problem. The API intelligently detects if the Fabric crypto-material is missing and gracefully falls back to an internal **Mock Simulation Mode**. This allows front-end developers and judges to run the app instantly without heavy environment setup.
- **Client-Side Visual Encryption:** Watch as voter hashes and ballot payloads are visually scrambled and encrypted in real-time before being transmitted to the network.
- **Red Team Simulator:** A built-in "Cyber Attack Terminal" that lets you launch simulated Sybil, Replay, and MITM attacks against the network to demonstrate the resilience of the blockchain.

---

## 🏗️ Architecture

1. **Frontend (Flutter):** A responsive web dashboard that handles voter registration, RSA client-side encryption visualization, and real-time election tallies.
2. **Middleware (Express.js):** Acts as the Key Management Service (KMS) and bridge. It exposes a REST API to the frontend and communicates with the blockchain via gRPC.
3. **Smart Contracts (Node.js):** Chaincode running on Hyperledger Fabric that enforces strict election rules (e.g., preventing double voting, rejecting unauthorized hashes).
4. **Blockchain Network (Docker):** A containerized Hyperledger Fabric network featuring multiple organizations (Election Commission & Independent Auditors) to ensure distributed consensus.

---

## 🚀 Quick Start (Mock Mode)

The fastest way to get the project running locally for demonstration purposes without needing Docker.

### 1. Start the Backend API
```bash
cd api
npm install
npm start
```
*(The API will automatically detect the absence of blockchain credentials and start in Mock Mode on port 3000).*

### 2. Start the Frontend Dashboard
Open a new terminal window:
```bash
cd flutter-app/vote_auditor
flutter pub get
flutter run -d chrome
```

---

## 🐳 Full Blockchain Deployment (Fabric Mode)

To run the system with the actual Hyperledger Fabric distributed ledger:

**Prerequisites:** Docker, Docker Compose, Windows WSL2 (or Linux/macOS).

1. **Generate Crypto Material & Start Network:**
   ```bash
   cd fabric-network/scripts
   ./setup.ps1
   ```
2. **Start the API:**
   Once the network is running and the `crypto-config` folder is generated, the API will automatically detect it and connect to the real Fabric Gateway.
   ```bash
   cd api
   npm start
   ```

---

## 🕹️ How to Use

1. **Initialize the Election:** When the app loads, click "Initialize Election" on the dashboard to mint the genesis block and open the polls.
2. **Register Voters:** Navigate to the Registration tab. Enter a name to generate a cryptographically secure, SHA-256 Voter Hash. *(Watch the matrix-style generation animation!)*
3. **Cast a Vote:** Go to the Voting Booth, enter your Voter Hash, select a candidate, and cast your ballot. The transaction will be cryptographically secured and appended to the ledger.
4. **Launch Attacks:** Visit the Red Team Control Room and try to hack the election using the Replay or Sybil attack buttons. Watch as the blockchain's consensus mechanisms automatically reject the fraudulent transactions!

---

## 🌐 Deployment 

- **Frontend:** Highly optimized for static hosting on **Vercel**, **Firebase**, or **Surge**. Just run `flutter build web --release` and deploy the `build/web` directory.
- **Backend:** Designed to be deployed on containerized platforms like **Render.com** or **Railway.app** to maintain persistent state and gRPC connections. (Remember to update the `baseUrl` in `api_service.dart` to your live API URL before building the frontend).
