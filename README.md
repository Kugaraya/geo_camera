# MIADP GeoCamera

A Flutter camera app for Android that captures photos with embedded GPS metadata and organizes them by date, designed for the Mindanao Inclusive Agriculture Development Project (MIADP).

---

## Features

- 📸 **Camera Capture:** Take high-resolution photos using your device’s camera.
- 📍 **Automatic Geotagging:** Each photo is saved with accurate GPS coordinates (latitude and longitude) in the EXIF metadata.
- 🗂️ **Organized Storage:** Photos are automatically saved in subfolders under `DCIM/MIADP_GeoCamera`, grouped by the current date (e.g., `May 23, 2025`).
- 🏷️ **Custom EXIF Tag:** Each image includes a project-specific EXIF description:  
  `CY {currentYear} Mindanao Inclusive Agriculture Project`
- 🗂️ **Folder Preview:** Browse and preview images grouped by date folders in a convenient grid view.
- 🎯 **High Accuracy Location:** Uses the device’s best available location for precise geotagging.
- 🔒 **Permissions Handling:** Requests and manages camera and location permissions as needed.

---

## Screenshots

<!-- Add screenshots here if available -->

---

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/) (3.8.0 or newer)
- Android device (recommended for full functionality)

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/your-org/geo_camera.git
   cd geo_camera
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Run the app:**
   ```sh
   flutter run
   ```

### Permissions

The app requires:
- Camera access
- Location access (for geotagging)
- Storage access (for saving images)

Make sure to grant these permissions when prompted.

---

## Project Structure

- `lib/main.dart` – App entry point and Bloc setup
- `lib/camera_screen.dart` – Main camera UI and logic
- `lib/bloc/` – Bloc files for geotagging state management

---

## How It Works

1. **Open the app** – The camera preview is shown.
2. **Take a photo** – Tap the white circular shutter button.
3. **Photo is saved** – Under `DCIM/MIADP_GeoCamera/{Mon DD, YYYY}/`.
4. **EXIF metadata** – GPS coordinates and project description are embedded.
5. **Preview images** – Tap the grid icon to browse photos by date.

---

## Customization

- **Change EXIF Description:**  
  Edit the string in `camera_screen.dart` where the image description is written.
- **Change Folder Structure:**  
  Adjust the save path logic in `camera_screen.dart`.

---

## Troubleshooting

- **No GPS data in photos?**  
  Ensure location permissions are granted and GPS is enabled.
- **App crashes on startup?**  
  Check that all permissions are accepted and dependencies are installed.

---

## License

This project is developed for the Mindanao Inclusive Agriculture Development Project (MIADP).  
For inquiries, please contact the project maintainers.

---

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [native_exif](https://pub.dev/packages/native_exif)
- [geolocator](https://pub.dev/packages/geolocator)
- [camera](https://pub.dev/packages/camera)
