This repository contains the frontend application of my Final Undergraduate Project, developed using the Godot engine.

The application works together with a Python backend responsible for real-time hand tracking. The Godot project acts as a TCP server, receiving processed hand landmark data and using it to drive interaction, visualization, and user feedback inside the application.

<img width="1912" height="1076" alt="Captura de tela 2026-02-17 182345" src="https://github.com/user-attachments/assets/18504178-79c7-4427-8ef5-1382d941cf0a" />

Backend (Python)

- Captures webcam input

- Performs real-time hand tracking

- Applies smoothing filters

- Sends JSON data via TCP socket

🔹 Frontend (Godot – This Repository)

- Runs a TCP server

- Receives real-time hand landmark data

- Interprets visibility and position data

- Controls interactive elements and visual feedback

- Manages session metadata (patient name, date, time)

Both repositories are required for the system to function correctly.

Backend (Python) Repository: [https://github.com/RafaZenitus/gd-handTrackig](https://github.com/RafaZenitus/py-handTracking)
