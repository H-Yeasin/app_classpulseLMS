# Opalmer Frontend (Education App)

This is the Flutter application for the Opalmer Education platform. It features an interactive UI with real-time communication, AI text recognition, and data visualization.

## Technologies & Packages Used
- **Flutter & Dart**: Cross-platform mobile framework (SDK `^3.10.4`).
- **Riverpod**: Robust and reactive state management (`flutter_riverpod`).
- **Dio**: Powerful HTTP client for API requests.
- **WebRTC & Socket.io**: For real-time video/audio calls and chat (`flutter_webrtc`, `socket_io_client`).
- **Google MLKit (Text Recognition)**: On-device machine learning for extracting text from images.
- **Camera & Image Picker**: Capturing and selecting media.
- **FL Chart**: Interactive data visualization and dashboard charts.
- **Printing**: Generating and printing PDF documents natively.
- **Flutter Secure Storage**: Securely storing authentication tokens and sensitive data.

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio and/or Xcode for emulators and building.

### Installation

1. Navigate to the frontend directory:
   ```bash
   cd opalmer_frontend
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

To run the application on a connected device or emulator:
```bash
flutter run
```

## Key Features
- **Real-time Calls**: Seamless audio and video calling powered by WebRTC.
- **Authentication**: Secure login, handling, and token storage.
- **Text Recognition**: Scan text easily using Google MLKit integration.
- **Analytics Dashboards**: Visualize academic and performance data using FL Chart.
- **File Management**: Create, pick, and print documents seamlessly.
