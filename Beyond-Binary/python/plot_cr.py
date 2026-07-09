import matplotlib.pyplot as plt

# Results copied from ModelSim transcript (run -all on tb_rle_multitest)
test_labels = [
    "Test 0\n\"AAAABBBCC\"\n(9 bytes)",
    "Test 1\n\"AAAAAAAAAA\"\n(10 bytes)",
    "Test 2\n\"AABBCCDD\"\n(8 bytes)",
    "Test 3\n\"AAAA...A\"x16\n(16 bytes)",
]
original_sizes   = [9, 10, 8, 16]
compressed_sizes = [8, 4, 10, 4]
compression_ratios = [o / c for o, c in zip(original_sizes, compressed_sizes)]

fig, ax = plt.subplots(figsize=(9, 6))

bar_colors = ["#4C72B0" if cr >= 1.0 else "#C44E52" for cr in compression_ratios]
bars = ax.bar(test_labels, compression_ratios, color=bar_colors, edgecolor="black")

# Reference line at CR = 1.0 (break-even point)
ax.axhline(y=1.0, color="red", linestyle="--", linewidth=1.5,
           label="CR = 1.0 (no compression gain)")

# Label each bar with its exact CR value
for bar, cr in zip(bars, compression_ratios):
    height = bar.get_height()
    ax.text(bar.get_x() + bar.get_width() / 2, height + 0.05,
             f"{cr:.3f}", ha="center", va="bottom", fontweight="bold")

ax.set_ylabel("Compression Ratio (CR = Original / Compressed)")
ax.set_title("RLE Compression Ratio Across Different Input Patterns")
ax.set_ylim(0, max(compression_ratios) + 0.8)
ax.legend()
ax.grid(axis="y", linestyle=":", alpha=0.6)

plt.tight_layout()
plt.savefig("compression_ratio.png", dpi=200)
print("Saved chart as compression_ratio.png")
plt.show()