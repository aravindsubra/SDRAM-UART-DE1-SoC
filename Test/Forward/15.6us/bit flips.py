import numpy as np

# Your current dataset
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
total_address_space = 0x9C4 + 1  # 2501 addresses

bit_flips = [bin(val ^ PATTERN).count('1') for _, val in data]
bit_flip_sum = sum(bit_flips)

# Remaining addresses assumed to have 0 bit flips
full_avg = bit_flip_sum / total_address_space

print(f"Total addresses in range: {total_address_space}")
print(f"Total bit flips observed: {bit_flip_sum}")
print(f"Average bit flips per address (including assumed correct): {full_avg:.4f}")
