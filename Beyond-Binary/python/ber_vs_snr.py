"""
ber_vs_snr.py
-------------
Reads multiple demod_out_XXX.txt files (each exported from LTSpice at a
different noise amplitude), samples each one at the middle of every bit
period, converts back to bits, compares against the known transmitted
bits, and calculates:

    - Bit Error Rate (BER) for each noise level
    - SNR (dB) for each noise level
    - A BER vs SNR plot (classic communication systems result)

Usage:
    python ber_vs_snr.py

Make sure all demod_out_XXX.txt files listed in TEST_FILES below exist
in the same folder as this script.
"""

import matplotlib.pyplot as plt
import math

# ----------------------------------------------------------------
# Configuration - edit these to match your actual files / noise levels
# ----------------------------------------------------------------

# Each entry: (filename, noise_amplitude_volts)
# Signal amplitude (carrier V2) is 1.0 V in our circuit.
SIGNAL_AMPLITUDE = 1.0

TEST_FILES = [
    ("demod_out_005", 0.05),
    ("demod_out_010", 0.10),
    ("demod_out_030", 0.30),
    ("demod_out_050", 0.50),
    ("demod_out_080", 0.80),
    ("demod_out_100", 1.00),
]

BIT_PERIOD = 10e-6      # must match gen_pwl.py
NUM_BITS   = 64         # 8 bytes x 8 bits
THRESHOLD  = 0.3        # volts - tune if needed (see note below)

# Expected transmitted bits: FF 04 41 03 42 02 43 FE
EXPECTED_BYTES = [0xFF, 0x04, 0x41, 0x03, 0x42, 0x02, 0x43, 0xFE]
EXPECTED_BITS = []
for b in EXPECTED_BYTES:
    for shift in range(7, -1, -1):
        EXPECTED_BITS.append((b >> shift) & 1)


def read_ltspice_export(filename):
    """Read time,voltage pairs from an LTSpice exported text file."""
    times, values = [], []
    with open(filename, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.lower().startswith("time"):
                continue
            parts = line.split()
            if len(parts) < 2:
                continue
            try:
                t = float(parts[0])
                v = float(parts[1])
                times.append(t)
                values.append(v)
            except ValueError:
                continue
    return times, values


def sample_at_time(times, values, t_sample):
    """Find the voltage value at the time point closest to t_sample.
    Uses binary search since LTSpice exports are sorted by time."""
    lo, hi = 0, len(times) - 1
    while lo < hi:
        mid = (lo + hi) // 2
        if times[mid] < t_sample:
            lo = mid + 1
        else:
            hi = mid
    # check neighbour for closer match
    if lo > 0 and abs(times[lo - 1] - t_sample) < abs(times[lo] - t_sample):
        lo -= 1
    return values[lo]


def calc_ber(filename):
    """Returns (ber, num_errors, bits_received)."""
    times, values = read_ltspice_export(filename)
    if not times:
        raise ValueError(f"No data found in {filename}")

    received_bits = []
    for i in range(NUM_BITS):
        t_sample = (i + 0.5) * BIT_PERIOD
        v = sample_at_time(times, values, t_sample)
        bit = 1 if v > THRESHOLD else 0
        received_bits.append(bit)

    errors = sum(1 for a, b in zip(received_bits, EXPECTED_BITS) if a != b)
    ber = errors / NUM_BITS
    return ber, errors, received_bits


def calc_snr_db(signal_amp, noise_amp):
    """SNR in dB = 20*log10(signal/noise)."""
    if noise_amp == 0:
        return float("inf")
    return 20 * math.log10(signal_amp / noise_amp)


def main():
    results = []  # (noise_amp, snr_db, ber, errors)

    print(f"{'File':<22}{'Noise(V)':<10}{'SNR(dB)':<10}{'Errors':<8}{'BER':<10}")
    print("-" * 60)

    for filename, noise_amp in TEST_FILES:
        try:
            ber, errors, bits = calc_ber(filename)
        except (FileNotFoundError, ValueError) as e:
            print(f"  SKIPPED {filename}: {e}")
            continue

        snr_db = calc_snr_db(SIGNAL_AMPLITUDE, noise_amp)
        results.append((noise_amp, snr_db, ber, errors))

        print(f"{filename:<22}{noise_amp:<10.2f}{snr_db:<10.2f}{errors:<8d}{ber:<10.4f}")

    if not results:
        print("\nNo files could be processed. Check filenames/paths.")
        return

    print()

    # ---- Plot BER vs SNR ----
    snr_values = [r[1] for r in results]
    ber_values = [r[2] for r in results]

    fig, ax = plt.subplots(figsize=(9, 6))

    # Replace BER=0 with a small floor value so it's visible on log scale
    ber_plot = [b if b > 0 else 0.5 / NUM_BITS for b in ber_values]

    ax.semilogy(snr_values, ber_plot, marker="o", linestyle="-",
                color="#4C72B0", linewidth=2, markersize=8)

    for snr, ber_orig, ber_p in zip(snr_values, ber_values, ber_plot):
        label = f"{ber_orig:.3f}" if ber_orig > 0 else "0 (floor)"
        ax.annotate(label, (snr, ber_p), textcoords="offset points",
                    xytext=(0, 10), ha="center", fontsize=9)

    ax.set_xlabel("SNR (dB)")
    ax.set_ylabel("Bit Error Rate (BER)")
    ax.set_title("BER vs SNR for ASK Modulation (64-bit test stream)")
    ax.grid(True, which="both", linestyle=":", alpha=0.6)
    ax.invert_xaxis()

    plt.tight_layout()
    plt.savefig("ber_vs_snr.png", dpi=200)
    print("Saved chart as ber_vs_snr.png")
    plt.show()


if __name__ == "__main__":
    main()