# REBS HRMS – Employee Workspace

A Flutter-based employee workspace developed as part of the Flutter Developer Assignment for TeqBae.

The application allows employees to view attendance, check in and check out with GPS validation, manage leave requests, and record attendance while offline.

## Features

### Employee Dashboard
- Employee name, ID and department.
- Today's attendance status and working duration.
- Check-in and check-out times.
- Available leave balance.
- Recent attendance history.
- Cached employee information for offline access.

### Attendance Management
- Check-in and check-out functionality.
- GPS-based office location validation.
- Configurable office coordinates and 200-metre radius.
- Company timezone support.
- Prevention of duplicate attendance actions.
- Local storage of attendance timestamps and GPS coordinates.

### Offline Synchronisation
- SQLite-based local persistence.
- Offline check-in and check-out.
- Pending Sync, Synced and Rejected statuses.
- Pending events preserved after app restart.
- Manual and automatic synchronisation.
- Ordered processing of pending attendance events.

### Leave Management
- Casual and Sick leave applications.
- Date and reason validation.
- Leave balance validation.
- Overlapping request validation.
- Leave request history and status tracking.
- Cached leave requests available offline.
- Internet connection required for new submissions.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter & Dart | Application development |
| BLoC | State management |
| Dio | API communication |
| SQLite (sqflite) | Local persistence |
| Geolocator | GPS validation |
| connectivity_plus | Connectivity monitoring |
| timezone | Company timezone handling |
| UUID | Unique attendance event IDs |
| Node.js & Express | Mock backend API |

## Architecture

The application follows a feature-based architecture with separation of presentation, business logic and data access.

```text
lib/
├── core/
│   ├── constants/
│   ├── database/
│   ├── location/
│   ├── network/
│   └── widgets/
│
├── features/
│   ├── dashboard/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── attendance/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── leave/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── main.dart
```

**Layer responsibilities:**
- **Presentation:** Flutter UI and BLoC state management.
- **Domain:** Attendance actions, synchronisation and leave validation.
- **Data:** API communication, local data sources, models and repositories.
- **Core:** Database, networking, location services and shared widgets.

## Getting Started

### Prerequisites
- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android device or emulator
- Node.js and npm

### Flutter Setup

```bash
git clone https://github.com/Antony-Maxwell/REBS-HRMS-Employee-Workspace.git
cd REBS-HRMS-Employee-Workspace
flutter pub get
```

Configure the API base URL in:

```text
lib/core/constants/api_constants.dart
```

For a physical Android device, use your computer's LAN IP address or an active tunnel URL instead of `localhost`.

Run the application:

```bash
flutter run
```

### Mock API

The application communicates with a separate Node.js/Express mock backend.

The mock server is maintained separately from this Flutter repository and is not included in the project source.

To run the application with API integration:
1. Start the mock API server separately.
2. Configure the API base URL in `lib/core/constants/api_constants.dart`.
3. Ensure the Android device or emulator can reach the server.

For a physical Android device, use your computer's LAN IP address or an active tunnel URL instead of `localhost`.

### Mock API Setup

Navigate to the mock server directory and install its dependencies:

```bash
cd mock_server
npm install
node server.js
```

Update the Flutter API base URL to point to the running server.

> Adjust the directory and startup command above to match the actual mock server files in the repository.

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/employee/me` | Fetch employee details |
| GET | `/attendance?month=YYYY-MM` | Fetch attendance history |
| POST | `/attendance/events` | Submit attendance events |
| GET | `/leave/balance` | Fetch leave balance |
| GET | `/leave/requests` | Fetch leave requests |
| POST | `/leave/requests` | Submit a leave application |

## Offline Attendance Flow

1. Attendance events are saved locally in SQLite with a unique event ID.
2. New offline events are marked as Pending Sync.
3. When connectivity returns, pending events are submitted in timestamp order.
4. Successful events are marked Synced.
5. Server-rejected events are marked Rejected.
6. Network failures leave events pending for retry.

The application does not perform background synchronisation after termination.

## Configuration and Testing

- The application uses one preconfigured employee; authentication is not implemented.
- Office coordinates, attendance radius and company timezone are obtained from employee details.
- The default attendance radius is 200 metres.
- For location testing, configure the emulator's GPS coordinates to match the office location.
- Overnight attendance shifts are not supported.
- All calendar days count towards leave duration; weekends and holidays are not excluded.
- Server-side validation is required in a production implementation.

## Limitations

- Uses a mock backend rather than production HRMS services.
- Supports one preconfigured employee.
- Authentication and authorisation are not implemented.
- Leave approval is not a complete HR workflow.
- Background synchronisation after application termination is not implemented.
- Production-grade backend security is outside the assignment scope.

## Development Details

**Development time:** Approximately 8 hours.

**AI disclosure:** AI tools, including ChatGPT, were used as development assistance for implementation, debugging and documentation. 

