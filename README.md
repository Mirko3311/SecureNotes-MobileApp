<div align="center">

# 🔐 SecureNotes Mobile App

**A secure mobile notes app with JWT authentication and two-factor authentication (TOTP)**

![Java](https://img.shields.io/badge/Java_21-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=for-the-badge&logo=springboot&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![JWT](https://img.shields.io/badge/JWT-000000?style=for-the-badge&logo=jsonwebtokens&logoColor=white)

*Bachelor's thesis project – Faculty of Electrical Engineering, University of Banja Luka (2026)*

</div>

---

## 🎬 Demo

[https://github.com/user-attachments/assets/bdaf14e0-776b-4cd3-93f0-c87dfb3d1417]

---

## ✨ Features

| | Feature | Description |
|---|---|---|
| 👤 | **Registration & Login** | Account creation with secure password storage |
| 🔑 | **Two-Factor Authentication** | TOTP codes via Google Authenticator, Microsoft Authenticator, etc. |
| 📱 | **QR Code Setup** | Scan a QR code to link your authenticator app |
| 👆 | **Biometric Unlock** | Fingerprint / face unlock on the device |
| 📝 | **Notes Management** | Create, view, edit and delete private notes |
| 🛡️ | **JWT Security** | Every API request is protected with a signed access token |
| 🔒 | **Encrypted Secrets** | TOTP secrets stored encrypted in the database (AES-GCM) |
| ⏱️ | **Brute-Force Protection** | Temporary lockout and limited attempts for login and 2FA codes |

---

## 🏗️ Architecture

```
┌──────────────────────┐    HTTPS / JSON     ┌──────────────────────┐        ┌─────────┐
│   Flutter Mobile App │ ──────────────────► │  Spring Boot REST API │ ─────► │  MySQL  │
│  (secure storage,    │ ◄────────────────── │  (Spring Security,    │        │         │
│   biometrics, QR)    │     JWT tokens      │   JWT, TOTP, AES-GCM) │        │         │
└──────────────────────┘                     └──────────────────────┘        └─────────┘
```

---

## 🛠️ Tech Stack

**Backend**
- Java 21, Spring Boot 4, Spring Security
- Spring Data JPA (Hibernate), MySQL
- JWT, TOTP, AES-GCM encryption

**Mobile App**
- Flutter & Dart
- `flutter_secure_storage` – secure token storage
- `local_auth` – biometric authentication
- `qr_flutter` – QR code for 2FA setup
- `http` – REST communication

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/register` | Register a new user |
| `POST` | `/api/auth/login` | Log in (step 1) |
| `POST` | `/api/auth/totp/enrollment` | Start 2FA setup (get QR code) |
| `POST` | `/api/auth/totp/enrollment/verify` | Confirm 2FA setup |
| `POST` | `/api/auth/totp/authentication/verify` | Verify 2FA code (step 2) |
| `GET` | `/api/notes` | Get all notes |
| `GET` | `/api/notes/{id}` | Get a single note |
| `POST` | `/api/notes` | Create a note |
| `PUT` | `/api/notes/{id}` | Update a note |
| `DELETE` | `/api/notes/{id}` | Delete a note |
| `GET` | `/api/health` | Health check |

---

## 📁 Project Structure

```
├── SecureNotes/                          # Spring Boot backend
│   └── src/main/java/.../securenotes/
│       ├── config/                       # Security & JWT configuration
│       ├── controller/                   # REST controllers
│       ├── dto/                          # Request / response objects
│       ├── entity/                       # JPA entities
│       ├── exception/                    # Custom exceptions & global handler
│       ├── repository/                   # Data access
│       └── service/                      # Business logic
├── SecureNotesFlutterApp/
│   └── secure_notes_mobile/              # Flutter mobile app
├── secure_notes.sql                      # Database schema
└── secure_notes.png                      # Database diagram
```

---

## 🚀 Getting Started

### Prerequisites
- Java 21+
- MySQL 8+
- Flutter SDK
- Android emulator or a physical device

### 1️⃣ Backend

**Create the database:**
```sql
CREATE DATABASE secure_notes;
```
> Tables are created automatically when the server starts.

**Configure** your MySQL username and password in
`SecureNotes/src/main/resources/application.properties`.

**Set environment variables:**

| Variable | Description |
|---|---|
| `JWT_SECRET_BASE64` | Base64 key for signing JWT tokens |
| `TOTP_ENCRYPTION_KEY_BASE64` | Base64 key for AES-GCM encryption of TOTP secrets |

<details>
<summary>💡 How to generate a key</summary>

```bash
openssl rand -base64 32
```
Or in PowerShell:
```powershell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
```
</details>

**Run the server:**
```bash
cd SecureNotes
./mvnw spring-boot:run
```
The API runs at `http://localhost:8080`.

### 2️⃣ Mobile App

```bash
cd SecureNotesFlutterApp/secure_notes_mobile
flutter pub get
flutter run
```

> **Note:** The app is configured for the Android emulator (`http://10.0.2.2:8080` in `lib/core/network/api_config.dart`).
> To run it on a physical device, replace it with the IP address of the computer running the backend.

---
