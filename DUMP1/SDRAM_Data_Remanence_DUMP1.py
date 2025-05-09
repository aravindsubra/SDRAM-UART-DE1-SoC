import matplotlib.pyplot as plt
import numpy as np

# Your data from the memory test
data = [
    (0x0, 0xBA),
    (0x1F5, 0x0),
    (0x200, 0x9600),
    (0x20E, 0x0),
    (0x2F3, 0x2),
    (0x309, 0x0),
    (0x3FB, 0x0),
    (0x41C, 0xBA),
    (0x4EE, 0x0),
    (0x51B, 0x0),
    (0x612, 0xBA),
    (0x715, 0xBA),
    (0x7E7, 0x0),
    (0x7EA, 0x7),
    (0x8CA, 0x0),
    (0x93F, 0xBA),
    (0x9CD, 0x0)
]

PATTERN = 0xFFFF

addresses = [entry[0] for entry in data]
values = [entry[1] for entry in data]

# Calculate bit flips (number of bits that flipped from the pattern)
bit_flips = [bin(val ^ PATTERN).count('1') for val in values]

# --- CORRECTED ADJACENCY CALCULATION ---
def count_adjacent_bit_flips(val, pattern=PATTERN, bits=16):
    flipped = val ^ pattern
    count = 0
    for i in range(bits - 1):
        # Check if both adjacent bits are flipped
        if ((flipped >> i) & 0b11) == 0b11:
            count += 1
    return count

adjacent_flips = [count_adjacent_bit_flips(val) for val in values]

plt.figure(figsize=(12, 6))
plt.bar(addresses, adjacent_flips, color='orange')
plt.title('Adjacency Bit-Flip Count per Address (within 16-bit word)')
plt.xlabel('Address')
plt.ylabel('Number of Adjacent Bit-Flips')
plt.xticks(ticks=np.linspace(min(addresses), max(addresses), 10),
           labels=[f'0x{int(x):X}' for x in np.linspace(min(addresses), max(addresses), 10)])
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('adjacency_bit_flip_count_corrected.png', dpi=300)
plt.show()

# Print a check for addresses with max bit flips
for addr, flips, adj in zip(addresses, bit_flips, adjacent_flips):
    if flips == 16:
        print(f"Address 0x{addr:X}: {flips} bit flips, {adj} adjacent bit flips (should be 15 if all are adjacent)")
