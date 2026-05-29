# FinLedger 📊

A full-stack, responsive fintech application designed to manage clients, track invoices, and process atomic payments. Built from scratch using Flutter and Firebase.

## 🚀 Features

* **Authentication:** Secure email/password registration and login flow with an automated Auth Gate.
* **Real-time Database:** NoSQL relational architecture utilizing Cloud Firestore.
* **Atomic Transactions:** Guaranteed data integrity using Firestore Batch Writes for payment processing.
* **Responsive UI:** Built with `LayoutBuilder` to seamlessly adapt from Mobile (Bottom Nav) to Tablet/Desktop (Navigation Rail).
* **Analytics Dashboard:** Derived local state aggregations powering real-time Donut charts (`fl_chart`).
* **PDF Generation:** Vector-based invoice rendering for native iOS/Android sharing and printing.
* **Native Integrations:** Hardware bridging for phone dialers and `Dismissible` gesture controls.

## 🛠 Tech Stack

* **Framework:** Flutter (Dart)
* **Backend:** Firebase (Authentication, Cloud Firestore)
* **Key Packages:** `fl_chart`, `pdf`, `printing`, `url_launcher`

## 🧠 Architectural Highlights

* **Feature-First Structure:** Highly scalable domain-driven design (`features/auth`, `features/invoices`, etc.).
* **Service Layer Abstraction:** All Firebase logic is decoupled from the UI into dedicated Service classes.
* **StreamBuilders:** Pure reactive state management eliminating manual navigation routing.

## 🏃‍♂️ How to Run

1. Clone the repository.
2. Run `flutter pub get`.
3. *(If Public Repo)* Connect your own Firebase project using `flutterfire configure`.
4. Run `flutter run`.