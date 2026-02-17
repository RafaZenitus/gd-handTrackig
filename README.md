# Hand Tracking Frontend – Godot

This repository contains the **frontend application** of my Final Undergraduate Project, developed using the Godot engine.

The application works together with a Python backend responsible for real-time hand tracking. The Godot project acts as a **TCP server**, receiving processed hand landmark data and using it to drive interaction, visualization, and user feedback inside the application.

<img width="1912" height="1076" alt="Screenshot of the Godot Project" src="https://github.com/user-attachments/assets/18504178-79c7-4427-8ef5-1382d941cf0a" />

---

## Project Architecture

### Backend (Python)
- Captures webcam input
- Performs real-time hand tracking using MediaPipe
- Applies smoothing filters
- Sends JSON data via TCP socket

### Frontend (Godot – This Repository)
- Runs a TCP server
- Receives real-time hand landmark data
- Interprets visibility and position data
- Controls interactive elements and visual feedback
- Manages session metadata (patient name, date, time)

> Both repositories are required for the system to function correctly.

### Backend Repository
[Python Backend Repository](https://github.com/RafaZenitus/py-handTracking)

---

## Controls & Instructions

### Movement Patterns
- **A** and **S** keys activate horizontal movement patterns (top and bottom areas of the screen)  
- **D** and **F** keys activate vertical movement patterns  
- **Z** and **X** keys activate “C”-shaped (partial circular) movement patterns

### Spawn Direction
- **Arrow keys** define the direction of coin appearance (e.g., right to left or left to right in horizontal movements)

### Color Variation / Target Hand
- **Keys 1 to 3** change coin color patterns:
  - 1 – Yellow
  - 2 – Blue (Left Hand)
  - 3 – Red (Right Hand)

This encourages coordination and limb dissociation, requiring the user to interact with specific targets using the correct hand.

---

## Requirements
- A webcam is required for hand recognition
- Ensure the camera is properly connected and accessible before starting the system

---

## How to Run the System
1. Run the **Godot project** first (starts the TCP server)  
2. Run the **Python backend script** (hand tracking module)  
3. The system establishes a connection and starts real-time tracking

> The Python backend must be running for the interaction system to work correctly.

---

## Technologies Used
- Godot Engine  
- TCP Socket Communication  
- JSON Data Handling  
