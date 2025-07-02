import matplotlib.pyplot as plt
import numpy as np

# Dataset for 31.3µs refresh period
data = [
    (0x3C, 0xFFFF),
    (0x31E, 0xFFFF),
    (0x3E7, 0xFFFF),
    (0x4A6, 0xFE1F),
    (0x4E2, 0xFFFF),
    (0x500, 0xFFFF),
    (0x55A, 0x3),
    (0x55D, 0xB),
    (0x55E, 0x0),
    (0x56E, 0x130B),
    (0x570, 0x0),
    (0x571, 0x0),
    (0x572, 0x31B),
    (0x573, 0x4B00),
    (0x575, 0x300),
    (0x57E, 0x5B02),
    (0x582, 0x1),
    (0x58C, 0x0),
    (0x58F, 0x1B1B),
    (0x591, 0x302),
    (0x5AF, 0x0),
    (0x5B0, 0x0),
    (0x5B1, 0x0),
    (0x5D3, 0x1B00),
    (0x5E3, 0xFFFF),
    (0x5FD, 0xFFFF),
    (0x605, 0xFFFF),
    (0x618, 0xFFFF),
    (0x6CF, 0x0)
]

PATTERN = 0xFFFF

# Define uniform x-axis range from 0x49C to 0x6D0
x_min = 0x49C
x_max = 0x6D0
x_range = np.arange(x_min, x_max + 1)

# Create an array for bit flips aligned with the full range, default 0
bit_flips_full = np.zeros_like(x_range, dtype=int)

# Map bit flips data into full array
for addr, val in data:
    if x_min <= addr <= x_max:
        idx = addr - x_min
        bit_flips_full[idx] = bin(val ^ PATTERN).count('1')

# Plot vertical green lines for addresses with bit flips
plt.figure(figsize=(14, 5))
for i, flips in enumerate(bit_flips_full):
    if flips > 0:
        plt.vlines(x_range[i], 0, flips, color='green', linewidth=0.8)

plt.xlim(x_min, x_max)
plt.ylim(0, max(bit_flips_full) + 1)
plt.xlabel('Memory Address (hex)')
plt.ylabel('Number of Bit Flips')
plt.title('Bit Flips per Address (Refresh Period = 31.3µs)')

# Show fewer hex ticks, spaced evenly
tick_step = max(1, (x_max - x_min) // 12)
ticks = x_range[::tick_step]
plt.xticks(ticks, [hex(addr) for addr in ticks], rotation=45, ha='right')

plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()

# Save the figure
plt.savefig("bit_flips_31_3us_uniform_range.png", dpi=300, bbox_inches='tight')
plt.show()
