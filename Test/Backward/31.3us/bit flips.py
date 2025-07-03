# Updated dataset: (Address, Observed Value)
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

# Constants
PATTERN = 0xFFFF
TOTAL_BITS_TESTED = 40960  # 10 rows × 4096 bits

# Calculate bit flips
bit_flips = [bin(val ^ PATTERN).count('1') for _, val in data if val != PATTERN]
bit_flip_sum = sum(bit_flips)
bit_flip_percentage = (bit_flip_sum / TOTAL_BITS_TESTED) * 100

# Output
print(f"Total bit flips observed: {bit_flip_sum}")
print(f"Bit flip percentage: {bit_flip_percentage:.4f}%")
