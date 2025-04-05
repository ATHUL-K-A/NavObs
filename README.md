# Navobs - Community Reporting System 🌍🚨

[![Flutter](https://img.shields.io/badge/Flutter-3.13.0-blue.svg)](https://flutter.dev)

A cross-platform mobile app for real-time community incident reporting with geolocation and role-based moderation.

<div align="center">
  <img src="assets/screenshots/demo.gif" width="300" alt="Navobs Demo">
</div>

## 📌 Features

### Core Functionalities
- **Role-based access**: Residents submit, admins verify reports
- **Precision geotagging**: GPS + Google Maps integration
- **Real-time updates**: Firebase-powered live sync
- **Offline support**: Queue reports without connectivity

### User Roles
| Role        | Permissions                          |
|-------------|--------------------------------------|
| Resident    | Submit/view reports                  |
| Admin       | Access to update verified section    |

## 🛠️ Tech Stack

| Component       | Technology                         |
|-----------------|------------------------------------|
| Frontend        | Flutter 3.13 (Dart)                |
| Backend         | Firebase Auth, Cloud Firestore     |
| Maps            | Google Maps SDK + Geolocator       |
| State Management| Provider (minimal)                 |

## 🚀 Installation

### Prerequisites
- Flutter SDK (>=3.13.0)
- Firebase project with enabled Auth/Firestore
- Google Maps API key

## Setup
- Add google map key to it to - android:value of android\app\src\main\AndroidManifest.xml and "current_key" present in android\app\google-services.json
- Run $flutter pub get   in a system with flutter
