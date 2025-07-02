import matplotlib.pyplot as plt
import numpy as np

# Dataset: (Address, Observed Value)
data = [
    (0x9CD, 0xFFFF),
    (0x93F, 0xBA),
    (0x8CA, 0xFFFF),
    (0x700, 0xD800),
    (0x6E0, 0xFFFF),
    (0x600, 0xCE00),
    (0x5E9, 0xFFFF),
    (0x5E6, 0x5),
    (0x51B, 0xBA),
    (0x4EE, 0xFFFF),
    (0x4DF, 0x4),
    (0x3F4, 0x3),
    (0x309, 0x0),
    (0x300, 0x8000),
    (0x20E, 0x0),
    (0x1F5, 0xFFFF),
    (0x107, 0xBA),
    (0xFB, 0x0),
    (0x0, 0xBA)
]

# Constants
PATTERN = 0xFFFF
TOTAL_BITS_TESTED = 40960  # You mentioned this is the total number of tested bits

# Extract addresses and bit flips
addresses = [addr for addr, _ in data]
bit_flips = [bin(PATTERN ^ val).count('1') for _, val in data]

# Plotting
plt.figure(figsize=(12, 6))
(markerline, stemlines, baseline) = plt.stem(addresses, bit_flips, linefmt='g-', markerfmt=' ', basefmt='k-')
plt.setp(stemlines, linewidth=0.5)

plt.title('Bit Flips vs. Memory Address', fontsize=14)
plt.xlabel('Memory Address (Hex)', fontsize=12)
plt.ylabel('Bit Flips', fontsize=12)
plt.grid(True, alpha=0.3)

# X-axis ticks formatting
xtick_step = 0x100
xticks = list(range(min(addresses), max(addresses)+1, xtick_step))
xtick_labels = [f'0x{addr:X}' for addr in xticks]
plt.xticks(xticks, xtick_labels, rotation=45, ha='right')
plt.xlim(min(addresses) - 8, max(addresses) + 8)

# Stats
total_flips = sum(bit_flips)
bit_flip_percentage = (total_flips / TOTAL_BITS_TESTED) * 100
max_flips = max(bit_flips)
max_addr = addresses[bit_flips.index(max_flips)]

stats_text = (
    f"Total Bit Flips: {total_flips}   |   "
    f"Bit Flip %: {bit_flip_percentage:.3f}%   |   "
    f"Max Bit Flips: {max_flips} at 0x{max_addr:X}"
)
plt.figtext(0.99, 0.01, stats_text, fontsize=9, ha='right')

# Save and show
plt.tight_layout()
plt.savefig('bit_flips_plot.png', dpi=300)
plt.show()
