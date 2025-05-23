# 💸 ExpenseMate – Smart Offline Expense & Budget Tracker

**ExpenseMate** is a clean, offline-first personal finance app built with **Flutter** and **SQLite**, allowing users to record transactions, manage monthly budgets, and generate insights without internet connectivity.

---

## 📘 Executive Summary

ExpenseMate empowers users to:
- Track expenses and income anytime, anywhere (offline)
- Set and monitor monthly budget goals
- Generate visual and PDF reports
- Access a clean UI with categorized transactions
- Export data securely from device storage

---

## 🎯 Objectives

- Provide a reliable offline solution for personal budgeting
- Help users visualize spending patterns and control habits
- Offer a responsive and intuitive cross-platform UI
- Enable full privacy with local encrypted storage

---

## ✅ Functional Requirements

### 👤 User Features
- Offline registration/login using local storage
- Add/edit/delete transactions (income or expense)
- Categorize transactions (Food, Grocery, Medicine, etc.)
- View summaries (Today, Week, Month, Year)
- Export reports as PDF
- Profile photo update & secure logout
- Budget alerts and monthly goal tracking

---

## 🔐 Non-functional Requirements

- 🔐 **Local security:** Passwords hashed and data encrypted
- ⚡ **Fast offline access:** SQLite database with optimized queries
- 📱 **Responsive UI:** Designed using Flutter for all screen sizes
- ☁ **No cloud dependency:** 100% offline usage
- 📊 **Chart visualizations:** Weekly bar graphs for quick insight

---

## 🧱 Architecture

### 📂 Data-Centered Architecture
- Uses a centralized **SQLite** database for storing all transaction and user data locally

### 🎛 MVC Architecture
- **Model:** `DatabaseHelper`, user/transaction models
- **View:** Flutter widget tree (UI)
- **Controller:** User actions handled in screens and methods

---

## 🗄️ Database Schema (SQLite)

### 🧍 `User`
- id (int, PK)
- name (text)
- email (text, unique)
- phone (text)
- password (text, hashed)

### 💵 `Transaction`
- id (int, PK)
- amount (real)
- category (text)
- type (text – Income/Expense)
- note (text)
- date (text)
- userEmail (text, FK)

---

## 🧪 Sample Test Cases

| ID      | Description                         | Expected Result                      |
|---------|-------------------------------------|--------------------------------------|
| UC-001  | Register new user                   | Stored locally, navigates to home    |
| UC-002  | Login with valid credentials        | Opens Dashboard                      |
| UC-003  | Add new expense                     | Reflected in summary and history     |
| UC-004  | Export PDF report                   | PDF file generated successfully      |
| UC-005  | View statistics                     | Chart updates with accurate data     |

---

## 🖥 UI Screens

- Welcome Screen
- Login / Signup
- Dashboard with Income/Expense summary
- Add Transaction
- Transaction History with filters
- Statistics Chart (Weekly)
- Profile Page with Export to PDF
- Settings (Change Password, Reset Data)

> 📸 Screenshots located in `/screenshots/` folder

---

## 🛠 Tools & Technologies

| Tool / Tech     | Usage                          |
|-----------------|--------------------------------|
| Flutter         | UI Framework                   |
| Dart            | Programming Language           |
| SQLite          | Local Database (offline)       |
| Figma           | UI/UX Design                   |
| SharedPreferences | User session & budget config |
| PDF Generator   | Report Export                  |

---

## 🧩 Local API-Like Methods

Though offline, ExpenseMate uses internal helper methods like:

- `registerUser(name, email, phone, password)`
- `loginUser(email, password)`
- `addTransaction(amount, category, type, note, date)`
- `getAllTransactionsByUser(email)`
- `generatePDFReport(dateRange)`
- `updatePassword(email, oldPass, newPass)`

---

## 🚀 Future Features

- Cloud sync option (Firebase)
- Multi-currency support
- Dark mode UI
- Passcode lock for app security
- Dashboard analytics with pie chart view

---

## 👨‍💻 Developer Info

**Rohit Sarkar**  
🎓 ID: 0802310405101055  
📧 rohit.sarkar55555555@gmail.com  
📱 +8801615755420  
🏫 BAUST, Saidpur, Bangladesh

---

## 📁 Suggested GitHub Structure

```
ExpenseMate/
├── lib/
│   ├── db/
│   │   └── database_helper.dart
│   ├── screens/
│   │   ├── add_transaction_screen.dart
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── register_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── statistics_screen.dart
│   │   ├── transaction_screen.dart
│   │   └── welcome_screen.dart
│   ├── pdf_helper.dart
│   └── main.dart
├── assets/
├── README.md
└── pubspec.yaml
```

---

## 🔐 Data Privacy Note

> All data is encrypted and stored **only on the user's device**. No internet required.  
> Users have full control over their data, which can be exported or deleted any time.
