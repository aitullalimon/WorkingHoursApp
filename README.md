# WorkingHoursApp
WorkingHoursApp is an iOS SwiftUI app for tracking work hours across multiple companies. Users can add companies, log time entries, set hourly rates, and view summaries or invoices. Includes custom date range filtering, company-based totals, and clean UI for easy time and earnings management.


# WorkingHoursApp

A SwiftUI-based time tracking and company management app for iOS. It allows users to log work hours, manage companies, view monthly summaries, and track payments with a clean and intuitive interface. Designed for freelancers, contractors, student part-time job and small businesses to easily calculate earnings and view custom date range summaries.

## 📂 Features
- Add and manage multiple companies
- Record work hours and hourly rates
- Monthly summary with company-wise totals
- Custom date range earnings calculation
- Payment tracking (future feature)
- Simple, modern SwiftUI interface

---

## 📲 Installation Guide

### 1. Prerequisites
- macOS with the latest **Xcode** installed
- An **Apple Developer Account**
- iPhone with USB cable or connected to the same Wi-Fi as your Mac

### 2. Clone the Repository
```bash
git clone https://github.com/YourUsername/WorkingHoursApp.git
cd WorkingHoursApp
open WorkingHoursApp.xcodeproj

** 1. Connect Your iPhone **
Plug in your iPhone to your Mac
On iPhone: Settings → General → Device Management → Trust your Mac (if prompted)

** 2. Configure Code Signing **
In Xcode, select the project name from the sidebar
Go to Targets → Signing & Capabilities
Select your Team (Apple ID)
Set a unique Bundle Identifier (e.g., com.yourname.workinghoursapp)

** 3. Build & Run **
Select your iPhone from the device list in Xcode
Press Cmd + R or click the Run ▶️ button
Xcode will build and install the app on your iPhone

** 4. Trust the Developer Profile (First Time Only) **
On iPhone: Settings → General → VPN & Device Management
Tap your developer profile and select Trust

** 📌 Notes **
The free Apple Developer account allows sideloading to your personal iPhone, but the app will expire after 7 days unless rebuilt from Xcode.
A paid Apple Developer subscription allows you to distribute the app via the App Store or TestFlight.
```

**Sample UI Preview**

<img width="283" height="562" alt="Screenshot 2025-08-13 at 14 03 54" src="https://github.com/user-attachments/assets/b866bf08-c038-4e5c-ab87-71c8e89243bc" />
<img width="283" height="566" alt="Screenshot 2025-08-13 at 14 04 43" src="https://github.com/user-attachments/assets/74b559f8-7e84-4d02-9a23-a919ce9e64dd" />
<img width="283" height="564" alt="Screenshot 2025-08-13 at 14 06 42" src="https://github.com/user-attachments/assets/3284be7f-0cb7-46d0-b372-d00a7f00411b" />
<img width="284" height="563" alt="Screenshot 2025-08-13 at 14 07 28" src="https://github.com/user-attachments/assets/8a4d7a52-e58e-4163-ab38-d36d28e2843e" />
<img width="284" height="562" alt="Screenshot 2025-08-13 at 14 08 03" src="https://github.com/user-attachments/assets/d4b394b7-3867-49b7-bbee-898dfe1f8e2a" />
<img width="284" height="565" alt="Screenshot 2025-08-13 at 14 08 59" src="https://github.com/user-attachments/assets/7798d481-0c40-45fe-86d5-aba24232569a" />
<img width="284" height="570" alt="Screenshot 2025-08-13 at 14 08 36" src="https://github.com/user-attachments/assets/d46a5f95-7f80-4aae-85d8-fc1bec0c19ed" />
