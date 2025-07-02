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
    (0x41C, 0x0),
    (0x3F4, 0x3),
    (0x309, 0x0),
    (0x300, 0x8000),
    (0x20E, 0x0),
    (0x1F5, 0xFFFF),
    (0x107, 0x0),
    (0xB8,  0x100),
    (0x0,   0x0)
]

PATTERN = 0xFFFF
TOTAL_BITS_TESTED = 40960  # 10 rows × 4096 bits (i.e., 2560 words × 16 bits)

# Calculate bit flips
bit_flips = [bin(PATTERN ^ val).count('1') for _, val in data]
bit_flip_sum = sum(bit_flips)
bit_flip_percentage = (bit_flip_sum / TOTAL_BITS_TESTED) * 100

# Output
print(f"Total Bit Flips: {bit_flip_sum}")
print(f"Bit Flip Percentage: {bit_flip_percentage:.3f}%")
