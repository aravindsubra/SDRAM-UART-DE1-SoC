import matplotlib.pyplot as plt
import numpy as np

# New dataset: (Address, Observed Value)
data = [
    (0x9CD, 0xFFFF),
    (0x93F, 0x00BA),
    (0x8CA, 0xFFFF),
    (0x838, 0x0000),
    (0x700, 0xD800),
    (0x6E0, 0xFFFF),
    (0x600, 0xCE00),
    (0x5E9, 0xFFFF),
    (0x5E6, 0x0005),
    (0x51B, 0x00BA),
    (0x4EE, 0xFFFF),
    (0x4DF, 0x0004),
    (0x3F4, 0x0003),
    (0x309, 0x0000),
    (0x300, 0x8000),
    (0x20E, 0x0000),
    (0x1F5, 0xFFFF),
    (0x107, 0x00BA)
]

PATTERN = 0xFFFF

# Define x-axis range to cover the relevant address range
x_min = 0x100  # Start slightly before lowest address in dataset
x_max = 0xA00  # End slightly after highest address
x_range = np.arange(x_min, x_max + 1)

# Create an array for bit flips aligned with the full x_range
bit_flips_full = np.zeros_like(x_range, dtype=int)

# Populate bit flip counts into the range
for addr, val in data:
    if x_min <= addr <= x_max:
        idx = addr - x_min
        bit_flips_full[idx] = bin(val ^ PATTERN).count('1') if val != PATTERN else 0

# Plotting vertical lines for each address with bit flips
plt.figure(figsize=(14, 5))
for i, flips in enumerate(bit_flips_full):
    if flips > 0:
        plt.vlines(x_range[i], 0, flips, color='green', linewidth=0.8)

plt.xlim(x_min, x_max)
plt.ylim(0, max(bit_flips_full) + 1)
plt.xlabel('Memory Address (hex)')
plt.ylabel('Number of Bit Flips')
plt.title('Bit Flips per Address (New Dataset, Refresh Period = 31.3µs)')

# Format x-axis ticks
tick_step = max(1, (x_max - x_min) // 16)
ticks = x_range[::tick_step]
plt.xticks(ticks, [f'0x{addr:X}' for addr in ticks], rotation=45, ha='right')

plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()

# Save and show the plot
plt.savefig("bit_flips_31_3us_updated_dataset.png", dpi=300, bbox_inches='tight')
plt.show()
