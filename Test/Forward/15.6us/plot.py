import matplotlib.pyplot as plt
import numpy as np

# Dataset: (Address, Observed Value)
data = [
    (0x0, 0xBA),
    (0xF2, 0xFFFF),
    (0x100, 0xAC00),
    (0x1FC, 0x1),
    (0x2F3, 0x2),
    (0x309, 0x0),
    (0x3FB, 0xFFFF),
    (0x41C, 0xBA),
    (0x4E1, 0x4),
    (0x4EE, 0xFFFF),
    (0x51B, 0xBA),
    (0x5E8, 0x5),
    (0x5E9, 0xFFFF),
    (0x612, 0x0),
    (0x6E0, 0xFFFF),
    (0x715, 0xBA),
    (0x7E7, 0xFFFF),
    (0x800, 0xA00),
    (0x838, 0x0),
    (0x8CA, 0xFFFF),
    (0x93F, 0xBA),
    (0x9C4, 0xFFFF)
]

PATTERN = 0xFFFF

# Extract addresses and calculate bit flips
addresses = [addr for addr, _ in data]
bit_flips = [bin(PATTERN ^ val).count('1') for _, val in data]

# Plot
plt.figure(figsize=(12, 6))
plt.stem(addresses, bit_flips, linefmt='g-', markerfmt=' ', basefmt='k-')  # markerfmt=' ' disables dots
plt.title('Bit Flips (Refresh: 15.6µs)', fontsize=14)
plt.xlabel('Memory Address (Hex)', fontsize=12)
plt.ylabel('Bit Flips', fontsize=12)
plt.grid(True, alpha=0.3)

# Show every Nth label to reduce clutter
N = 3  # Adjust this for more or fewer labels
xticks_filtered = addresses[::N]
xtick_labels_filtered = [f'0x{addr:X}' for addr in xticks_filtered]
plt.xticks(xticks_filtered, xtick_labels_filtered, rotation=45, ha='right')

# Stats box
total_flips = sum(bit_flips)
affected_addrs = sum(1 for b in bit_flips if b > 0)
max_flips = max(bit_flips)
max_addr = addresses[bit_flips.index(max_flips)]
stats_text = (
    f"Max Bit Flips: {max_flips} at 0x{max_addr:X}"
)
plt.figtext(0.99, 0.01, stats_text, fontsize=9, ha='right')

plt.tight_layout()
plt.show()
plt.savefig('Bit Flips Plot @15.6us.png', dpi=300)

