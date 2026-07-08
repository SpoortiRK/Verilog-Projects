# 1011 Sequence Detector (Mealy FSM)

## Overview

This project implements a **1011 Sequence Detector** using a **Mealy Finite State Machine (FSM)** in Verilog HDL. The detector continuously monitors a serial input stream and asserts the output (`dout`) whenever the sequence **1011** is detected. The design supports **overlapping sequence detection**.

---

## Features

- Mealy FSM implementation
- Detects the binary sequence **1011**
- Supports overlapping sequence detection
- Asynchronous active-high reset
- Written in Verilog HDL
- Verified using a Verilog testbench and ModelSim simulation

---

## State Diagram

| State | Description |
|-------|-------------|
| S0 | No bits matched |
| S1 | Detected `1` |
| S2 | Detected `10` |
| S3 | Detected `101` |

When the FSM is in **S3** and receives an input `1`, the sequence **1011** is detected and `dout` is asserted.

---

## Inputs

| Signal | Description |
|---------|-------------|
| `clk` | Clock signal |
| `reset` | Asynchronous active-high reset |
| `din` | Serial input data |

---

## Output

| Signal | Description |
|---------|-------------|
| `dout` | Goes HIGH when sequence **1011** is detected |

---

## Files

- `seq_detector_1011.v` – Verilog source code
- `seq_detector_1011_tb.v` – Testbench
- `waveform.png` – Simulation waveform
- `README.md` – Project documentation

---

## Simulation

The design was successfully verified using a Verilog testbench in **ModelSim**. The waveform confirms correct state transitions and detection of the sequence **1011**, including overlapping sequence detection.

---

## Tools Used

- Verilog HDL
- ModelSim

---

## Author

**Spoorti R Kademani**