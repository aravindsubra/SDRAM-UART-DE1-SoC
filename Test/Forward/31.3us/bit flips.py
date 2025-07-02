import numpy as np

# Additional dump dataset from 31.3 µs refresh testing
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

# Constants
PATTERN = 0xFFFF
TOTAL_ADDRESS_SPACE = 0x09FF + 1  # 2560 addresses (0x0000 to 0x09FF)

# Bit flip calculation
bit_flips = [bin(val ^ PATTERN).count('1') for _, val in data]
bit_flip_sum = sum(bit_flips)

# Average over all addresses
average_flips = bit_flip_sum / TOTAL_ADDRESS_SPACE

# Output
print(f"Total addresses in range: {TOTAL_ADDRESS_SPACE}")
print(f"Observed entries with errors or test values: {len(data)}")
print(f"Total bit flips observed: {bit_flip_sum}")
print(f"Average bit flips per address (across all memory): {average_flips:.6f}")
