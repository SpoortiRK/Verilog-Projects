"""
reconstruct.py
--------------
Reads demod_out (exported from LTSpice),
samples it at the middle of each bit period,
converts back to bits → bytes,
and prints the recovered compressed bytes.
"""

INPUT_FILE  = "demod_out"
BIT_PERIOD  = 10e-6     # must match gen_pwl.py (10 us)
THRESHOLD   = 0.3       # volts - anything above this = logic 1
NUM_BITS    = 64        # 8 bytes x 8 bits

def read_ltspice_export(filename):
    """Read time,voltage pairs from LTSpice exported text file."""
    times  = []
    values = []
    with open(filename, "r") as f:
        for line in f:
            line = line.strip()
            # skip header lines (LTSpice adds a header row)
            if not line:
                continue
            if line.startswith("time") or line.startswith("Time"):
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
    """Find the voltage value closest to t_sample."""
    best_idx = 0
    best_diff = abs(times[0] - t_sample)
    for i in range(1, len(times)):
        diff = abs(times[i] - t_sample)
        if diff < best_diff:
            best_diff = diff
            best_idx = i
    return values[best_idx]

def main():
    print("Reading", INPUT_FILE, "...")
    times, values = read_ltspice_export(INPUT_FILE)
    print(f"Loaded {len(times)} data points")
    print(f"Time range: {times[0]*1e6:.1f}us to {times[-1]*1e6:.1f}us")
    print()

    # Sample at the MIDDLE of each bit period
    # e.g. bit 0 sampled at 5us, bit 1 at 15us, bit 2 at 25us ...
    bits = []
    print("Sampling bits:")
    for i in range(NUM_BITS):
        t_sample = (i + 0.5) * BIT_PERIOD
        voltage  = sample_at_time(times, values, t_sample)
        bit      = 1 if voltage > THRESHOLD else 0
        bits.append(bit)
        print(f"  bit {i:2d}: t={t_sample*1e6:6.1f}us  V={voltage:.3f}  → {bit}")

    print()
    print("Recovered bits:")
    print("  " + "".join(str(b) for b in bits))
    print()

    # Group bits into bytes (8 bits each, MSB first)
    recovered_bytes = []
    for i in range(0, NUM_BITS, 8):
        byte_bits = bits[i:i+8]
        byte_val  = 0
        for b in byte_bits:
            byte_val = (byte_val << 1) | b
        recovered_bytes.append(byte_val)
        print(f"  byte {i//8}: {byte_bits} = 0x{byte_val:02X}")

    print()
    print("Recovered compressed bytes:")
    print("  " + " ".join(f"0x{b:02X}" for b in recovered_bytes))
    print()

    # Check against expected: FF 04 41 03 42 02 43 FE
    expected = [0xFF, 0x04, 0x41, 0x03, 0x42, 0x02, 0x43, 0xFE]
    print("Expected bytes:")
    print("  " + " ".join(f"0x{b:02X}" for b in expected))
    print()

    errors = 0
    for i, (r, e) in enumerate(zip(recovered_bytes, expected)):
        if r != e:
            print(f"  MISMATCH at byte {i}: got 0x{r:02X}, expected 0x{e:02X}")
            errors += 1

    if errors == 0:
        print("=== RECONSTRUCTION PASSED ===")
        print("Recovered: FF 04 41 03 42 02 43 FE")
        print("This decompresses back to: AAAABBBCC")
    else:
        print(f"=== RECONSTRUCTION FAILED ({errors} byte errors) ===")
        print("Try adjusting THRESHOLD value in the script")

if __name__ == "__main__":
    main()