# 🚦 Traffic Light Controller using Verilog

## Overview

This project implements a Finite State Machine (FSM) based Traffic Light Controller using Verilog HDL. It controls traffic lights for two directions (North and East) by cycling through predefined states in a safe and organized manner.

---

## Features

- Finite State Machine (FSM) based design
- 6 traffic light states
- Synchronous state transitions using clock
- Asynchronous reset
- Separate Red, Yellow, and Green signals for both directions
- Verified using a Verilog testbench and ModelSim simulation

---

## State Sequence

| State | North Road | East Road |
|--------|------------|-----------|
| S0 | Green | Red |
| S1 | Yellow | Red |
| S2 | Red | Red |
| S3 | Red | Green |
| S4 | Red | Yellow |
| S5 | Red | Red |

The controller continuously cycles through:

S0 → S1 → S2 → S3 → S4 → S5 → S0

---

## Inputs

- `clk` – System clock
- `reset` – Asynchronous reset

---

## Outputs

### North Road
- `north_red`
- `north_yellow`
- `north_green`

### East Road
- `east_red`
- `east_yellow`
- `east_green`

---

## FSM States

```verilog
S0 = North Green, East Red
S1 = North Yellow, East Red
S2 = All Red
S3 = North Red, East Green
S4 = North Red, East Yellow
S5 = All Red
```

---

## Files

- `traffic_light.v` – Traffic Light Controller (RTL)
- `traffic_light_tb.v` – Testbench
- `waveform.png` – Simulation waveform
- `README.md`

---

## Simulation

The design was successfully simulated in ModelSim.

Simulation verifies:

- Correct state transitions
- Correct output signals
- Proper reset operation
- Continuous cyclic operation

---

## Tools Used

- Verilog HDL
- ModelSim

---

## Author

**Spoorti R Kademani**

B.Tech Electronics and Communication Engineering  
IIT Dharwad