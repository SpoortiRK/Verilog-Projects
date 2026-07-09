INPUT_FILE  = "compressed_out.txt"
OUTPUT_FILE = "pwl_input.txt"

BIT_PERIOD = 10e-6   # seconds per bit (e.g. 10 us -> 100 kbps)
V_HIGH     = 5.0     # voltage for logic '1'
V_LOW      = 0.0     # voltage for logic '0'
RISE_TIME  = 1e-9    # transition time between levels (1 ns)


def bytes_to_bits(byte_list):
    """Convert a list of integers (0-255) to a list of bits (MSB first)."""
    bits = []
    for b in byte_list:
        for shift in range(7, -1, -1):
            bits.append((b >> shift) & 1)
    return bits


def read_compressed_bytes(filename):
    bytes_list = []
    with open(filename, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            bytes_list.append(int(line, 16))
    return bytes_list


def write_pwl(filename, bits, bit_period, v_high, v_low, rise_time):
    lines = []
    t = 0.0

    prev_level = v_low  # signal starts at 0 V
    lines.append(f"{t:.9e} {prev_level:.3f}")

    for bit in bits:
        level = v_high if bit == 1 else v_low

        if level != prev_level:
            t_ramp_end = t + rise_time
            lines.append(f"{t_ramp_end:.9e} {level:.3f}")
            t_seg_end = t + bit_period
        else:
            t_seg_end = t + bit_period

        lines.append(f"{t_seg_end:.9e} {level:.3f}")

        t = t_seg_end
        prev_level = level

    with open(filename, "w") as f:
        f.write("\n".join(lines) + "\n")

    return t


def main():
    byte_list = read_compressed_bytes(INPUT_FILE)
    print(f"Read {len(byte_list)} compressed bytes: "
          f"{[hex(b) for b in byte_list]}")

    bits = bytes_to_bits(byte_list)
    print(f"Expanded to {len(bits)} bits: {''.join(str(b) for b in bits)}")

    total_time = write_pwl(OUTPUT_FILE, bits, BIT_PERIOD, V_HIGH, V_LOW, RISE_TIME)

    print(f"Wrote {OUTPUT_FILE}")
    print(f"Total signal duration: {total_time*1e6:.3f} us "
          f"({len(bits)} bits x {BIT_PERIOD*1e6:.3f} us/bit)")
    print()
    print("In LTSpice, use a voltage source with:")
    print(f"  PWL file=\"{OUTPUT_FILE}\"")
    print("Set your .tran stop time to at least the total signal duration above.")


if __name__ == "__main__":
    main()