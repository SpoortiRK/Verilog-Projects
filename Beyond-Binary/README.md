# Beyond Bits — SOI 2026

### SOI 2026 Project | IIT Dharwad Electronics Club

An end-to-end digital communication system implementing **Run-Length Encoding (RLE) compression**, **Amplitude Shift Keying (ASK) modulation**, **demodulation**, and **performance analysis** using **Verilog, Python, and LTspice**.

---
## Team

**Team Name:** **Beyond Binary**

**Team Member:** **Spoorti R Kademani** (EC25BT025)

Department of Electronics and Communication Engineering

Indian Institute of Technology Dharwad

**Email:** ec25bt025@iitdh.ac.in
---

## Project Overview

This project implements an end-to-end data compression and ASK modulation pipeline:

```
"AAAABBBCC"
    │
    ▼
[Stage 1] RLE Compression     → Verilog RTL (ModelSim)
    │
    ▼
[Stage 2] PWL Generation      → Python (gen_pwl.py)
    │
    ▼
[Stage 3] ASK Modulation      → LTSpice XVII (ask_modem.asc)
    │
    ▼
[Stage 4] Noise + Demodulation→ LTSpice XVII (envelope detector)
    │
    ▼
[Stage 5] Reconstruction      → Python (reconstruct.py)
    │
    ▼
[Stage 6] BER vs SNR Analysis → Python (ber_vs_snr.py)
    │
    ▼
"AAAABBBCC" ✓
```

---

## File Structure

```
Beyond Binary/
├── BeyondBits_Report.docx        ← Technical report
├── README.txt                     ← This file
│
├── verilog/
│   ├── rle_compress.v             ← RLE compressor (7-state FSM)
│   ├── rle_decompress.v           ← RLE decompressor (5-state FSM)
│   ├── tb_rle_roundtrip.v         ← Single round-trip testbench
│   └── tb_rle_multitest.v         ← 4-case automated testbench
│
├── python/
│   ├── gen_pwl.py                 ← Compressed bytes → PWL waveform
│   ├── reconstruct.py             ← LTSpice output → bytes + verify
│   ├── plot_cr.py                 ← Compression ratio bar chart
│   └── ber_vs_snr.py              ← Batch BER vs SNR analysis
│
├── ltspice/
│   └── ask_modem.asc              ← ASK modulator + noise + demodulator
│
├── data/
│   ├── compressed_out.txt         ← Compressed output from Verilog
│   ├── pwl_input.txt              ← PWL waveform for LTSpice
│   ├── demod_out_005              ← Demodulated output, noise = 0.05V
│   ├── demod_out_010              ← Demodulated output, noise = 0.10V
│   ├── demod_out_030              ← Demodulated output, noise = 0.30V
│   ├── demod_out_050              ← Demodulated output, noise = 0.50V
│   ├── demod_out_080              ← Demodulated output, noise = 0.80V
│   └── demod_out_100              ← Demodulated output, noise = 1.00V
│
└── results/
    ├── compression_ratio.png      ← Compression ratio bar chart
    └── ber_vs_snr.png             ← BER vs SNR plot
```

---

## How to Run the Complete System

### Prerequisites
- ModelSim (any version supporting Verilog-2001)
- LTSpice XVII
- Python 3.x with matplotlib installed
  ```
  pip install matplotlib
  ```

---

### Step 1 — RLE Compression (ModelSim)

1. Open ModelSim
2. Create a new project and add all files from the `verilog/` folder
3. Compile all files
4. Run the round-trip testbench:
   ```
   vsim tb_rle_roundtrip
   run -all
   ```
   Expected output: `=== TEST PASSED ===`

5. Run the multi-test testbench:
   ```
   vsim tb_rle_multitest
   run -all
   ```
   Expected output: `=== ALL 4 TESTS PASSED ===`

6. The file `compressed_out.txt` is generated automatically in the working directory.

---

### Step 2 — Generate PWL Waveform (Python)

```bash
cd python/
python gen_pwl.py
```

This reads `compressed_out.txt` and writes `pwl_input.txt`.
Expected output: `PWL file written: pwl_input.txt (64 bits, 640 us)`

---

### Step 3 — ASK Modulation and Demodulation (LTSpice)

1. Open `ltspice/ask_modem.asc` in LTSpice XVII
2. Verify V1 points to the correct path of `pwl_input.txt`
   - Right-click V1 → change path if needed
3. Click Run (green play button)
4. Click on the `demod_out` wire to plot it
5. Export: right-click waveform tab → File → Export data as text
6. Save as `demod_out_010` in the `data/` folder

Circuit parameters:
- V2 (carrier): SINE(0 1 1Meg) — 1 MHz carrier
- V3 (noise):   SINE(0 0.1 50k) — noise source
- D1 + R1 (1kΩ) + C1 (1nF): envelope detector, τ = 1 µs
- .tran 650u

---

### Step 4 — Reconstruct Original Data (Python)

```bash
cd python/
python reconstruct.py
```

Expected output:
```
Recovered bytes: FF 04 41 03 42 02 43 FE
=== RECONSTRUCTION PASSED ===
```

---

### Step 5 — Compression Ratio Chart (Python)

```bash
cd python/
python plot_cr.py
```

Saves `results/compression_ratio.png`

---

### Step 6 — BER vs SNR Analysis (Python)

Make sure all 6 demodulated output files are in the `data/` folder,
then run:

```bash
cd python/
python ber_vs_snr.py
```

Expected output:
```
File                  Noise(V)  SNR(dB)   Errors  BER
------------------------------------------------------------
demod_out_005         0.05      26.02     0       0.0000
demod_out_010         0.10      20.00     0       0.0000
demod_out_030         0.30      10.46     0       0.0000
demod_out_050         0.50      6.02      0       0.0000
demod_out_080         0.80      1.94      0       0.0000
demod_out_100         1.00      0.00      18      0.2813
```

Saves `results/ber_vs_snr.png`

---

## Key Results

| Metric | Value |
|--------|-------|
| Compression ratio (best case) | 4.0 : 1 (16 identical bytes) |
| Compression ratio (typical)   | 1.125 : 1 ("AAAABBBCC") |
| Carrier frequency             | 1 MHz |
| Bit rate                      | 100 kbps |
| BER at SNR = 26 dB            | 0.000 |
| BER at SNR = 0 dB             | 0.281 |
| Noise immunity range          | SNR > 1.94 dB → BER = 0 |

---

## Enhancement Implemented

**Channel Noise and BER vs SNR Analysis**

A sinusoidal noise source was added in series between the ASK modulator
output and the envelope detector input. Six noise amplitude levels were
tested (0.05V to 1.00V), corresponding to SNR values from 26 dB to 0 dB.
The BER was calculated for each level by comparing 64 received bits against
the known transmitted sequence. Results demonstrate the classic cliff effect
in digital communications.

---

## Tools Used

| Tool | Version | Purpose |
|------|---------|---------|
| ModelSim | - | Verilog RTL simulation |
| LTSpice XVII | - | ASK circuit simulation |
| Python | 3.x | PWL generation, reconstruction, analysis |
| matplotlib | - | Plotting compression ratio and BER charts |
