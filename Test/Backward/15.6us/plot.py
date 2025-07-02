import matplotlib.pyplot as plt
import numpy as np

# New dataset: (Address, Observed Value)
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
    (0x1F5, 0xFFFF),
    (0x0, 0xBA),
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
N = 2
xticks_filtered = addresses[::N]
xtick_labels_filtered = [f'0x{addr:X}' for addr in xticks_filtered]
plt.xticks(xticks_filtered, xtick_labels_filtered, rotation=45, ha='right')

# Stats box
total_flips = sum(bit_flips)
affected_addrs = sum(1 for b in bit_flips if b > 0)
max_flips = max(bit_flips)
max_addr = addresses[bit_flips.index(max_flips)]
stats_text = (
    f"Total Bit Flips: {total_flips}\n"
    f"Affected Addresses: {affected_addrs}\n"
    f"Max Bit Flips: {max_flips} at 0x{max_addr:X}"
)
plt.figtext(0.99, 0.01, stats_text, fontsize=9, ha='right')

plt.tight_layout()
plt.savefig('Bit Flips Plot @15.6us.png', dpi=300)
plt.show()
