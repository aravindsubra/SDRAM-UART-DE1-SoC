import matplotlib.pyplot as plt
import numpy as np

# Dataset
data = [
    (0xC, 0xC),
    (0x1C, 0xFFFF),
    (0x71, 0x0),
    (0x73, 0xFF),
    (0x7C, 0x7C00),
    (0xA0, 0x0),
    (0xA1, 0xB),
    (0xA2, 0xFF),
    (0xA4, 0xDA6D),
    (0xCE, 0x0),
    (0xCF, 0x2),
    (0xD7, 0x303),
    (0xDD, 0x0),
    (0xDE, 0x1F03),
    (0xDF, 0x0),
    (0xE0, 0x203),
    (0xE8, 0x0),
    (0xF3, 0x13),
    (0xF5, 0x300),
    (0x1B0, 0xB00),
    (0x1F2, 0x1B09),
    (0x232, 0x200),
    (0x245, 0xFB5B),
    (0x262, 0x85),
    (0x263, 0xFFFF),
    (0x2B1, 0x3),
    (0x2B4, 0x300),
    (0x2B5, 0x302),
    (0x2B8, 0x3),
    (0x2B9, 0x1B03),
    (0x3AC, 0x3),
    (0x3B1, 0x1B02),
    (0x5E9, 0xFFFF),
    (0x622, 0xFFFF)
]

PATTERN = 0xFFFF
X_LIMIT = 0x3B1  # x-axis max

# Filter and sort data up to limit
data_sorted = sorted([(addr, val) for addr, val in data if addr <= X_LIMIT], key=lambda x: x[0])
addresses = [addr for addr, _ in data_sorted]
bit_flips = [bin(PATTERN ^ val).count('1') for _, val in data_sorted]

# Plot
plt.figure(figsize=(12, 6))
(markerline, stemlines, baseline) = plt.stem(addresses, bit_flips, linefmt='g-', markerfmt=' ', basefmt='k-')
plt.setp(stemlines, linewidth=0.5)  # Make vertical lines thinner

plt.title('Bit Flips vs. Memory Address (Refresh: 62.5µs)', fontsize=14)
plt.xlabel('Memory Address (Hex)', fontsize=12)
plt.ylabel('Bit Flips', fontsize=12)
plt.grid(True, alpha=0.3)

# Uniformly spaced x-axis ticks
xtick_step = 0x40  # 64 bytes
xticks = list(range(min(addresses), X_LIMIT + 1, xtick_step))
xtick_labels = [f'0x{addr:X}' for addr in xticks]
plt.xticks(xticks, xtick_labels, rotation=45, ha='right')
plt.xlim(min(addresses), X_LIMIT)

# Stats
total_flips = sum(bit_flips)
affected_addrs = sum(1 for b in bit_flips if b > 0)
max_flips = max(bit_flips)
max_addr = addresses[bit_flips.index(max_flips)]
stats_text = (
    f"Max Bit Flips: {max_flips} at 0x{max_addr:X}"
)
plt.figtext(0.99, 0.01, stats_text, fontsize=9, ha='right')

# Save and show
plt.tight_layout()
plt.savefig('Bit Flips Plot @31.3us.png', dpi=300)
plt.show()
