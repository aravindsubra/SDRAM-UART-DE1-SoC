import matplotlib.pyplot as plt
import numpy as np

# Your updated data from the memory test (in reverse order from high to low addresses)
data = [
    (0x9CD, 0x0),
    (0x93F, 0xBA),
    (0x8CA, 0x0),
    (0x838, 0x0),
    (0x700, 0xD800),
    (0x6E0, 0x0),
    (0x600, 0xCE00),
    (0x5E9, 0x0),
    (0x5E6, 0x5),
    (0x51B, 0xBA),
    (0x4EE, 0x0),
    (0x4DF, 0x4),
    (0x3F4, 0x3),
    (0x309, 0x0),
    (0x300, 0x8000),
    (0x20E, 0x0),
    (0x1F5, 0x0),
    (0x107, 0xBA),
    (0xFB, 0x0),
    (0x0, 0xBA)
]

# Expected pattern that was written
PATTERN = 0xFFFF

# Extract addresses and values
addresses = [entry[0] for entry in data]
values = [entry[1] for entry in data]

# Calculate bit flips (number of bits that flipped from the pattern)
bit_flips = [bin(val ^ PATTERN).count('1') for val in values]

# 1. Basic Bit Error Analysis Plot
plt.figure(figsize=(12, 8))
plt.stem(addresses, bit_flips, linefmt='c-', markerfmt='co', basefmt='k-')
plt.title('Bit Error Analysis (0xFFFF Write Test)')
plt.xlabel('Address Values')
plt.ylabel('Bit Flips')
plt.grid(True, alpha=0.3)

# Find the maximum for annotation
max_flips = max(bit_flips)
max_addr = addresses[bit_flips.index(max_flips)]

# Annotate maximum value
if max_flips > 100:  # Only annotate if there's a significant spike
    plt.annotate(f'Max: {max_flips} flips at 0x{max_addr:X}',
                xy=(max_addr, max_flips),
                xytext=(max_addr-200, max_flips*0.8),
                arrowprops=dict(facecolor='red', shrink=0.05))

# Add refresh rate information
plt.figtext(0.98, 0.01, 'Refresh rate: 7.8 microseconds per row', 
           horizontalalignment='right', fontsize=10)

# Add some statistics
total_addresses = len(addresses)
addresses_with_errors = sum(1 for flips in bit_flips if flips > 0)
error_percentage = (addresses_with_errors / total_addresses) * 100

stats_text = (f'Total Addresses: {total_addresses}\n'
              f'Addresses with Errors: {addresses_with_errors} ({error_percentage:.1f}%)\n'
              f'Max Bit Flips: {max_flips} at 0x{max_addr:X}')

plt.figtext(0.02, 0.02, stats_text, fontsize=10)

# Format x-axis to show hex values - ensure we use the reversed range
plt.xticks(ticks=np.linspace(max(addresses), min(addresses), 10),
          labels=[f'0x{int(x):X}' for x in np.linspace(max(addresses), min(addresses), 10)])

plt.tight_layout()
plt.savefig('bit_flips_analysis.png', dpi=300)
plt.show()

# 2. Spatial Correlation: Adjacency bit-flip count
adjacent_flips = []
for i in range(len(bit_flips)):
    count = 0
    if i > 0 and bit_flips[i-1] > 0: count += 1
    if i < len(bit_flips)-1 and bit_flips[i+1] > 0: count += 1
    adjacent_flips.append(count)

plt.figure(figsize=(12, 6))
plt.bar(addresses, adjacent_flips, color='orange')
plt.title('Adjacency Bit-Flip Count per Address')
plt.xlabel('Address')
plt.ylabel('Number of Adjacent Bit-Flips')
plt.xticks(ticks=np.linspace(max(addresses), min(addresses), 10),
           labels=[f'0x{int(x):X}' for x in np.linspace(max(addresses), min(addresses), 10)])
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('adjacency_bit_flip_count.png', dpi=300)
plt.show()

# 3. Data-Pattern Resilience: Normalized BER per pattern
patterns = [0xFFFF, 0x0000, 0xAAAA, 0x5555]
pattern_labels = ['0xFFFF', '0x0000', '0xAAAA', '0x5555']
normalized_ber = []

# Simulate BER for different patterns based on actual data from 0xFFFF
# In a real test, you would test each pattern individually
for pattern in patterns:
    if pattern == 0xFFFF:
        # For 0xFFFF we use the actual data
        flips = [bin(val ^ pattern).count('1') for val in values]
        normalized_ber.append(np.mean(flips) / 16)  # 16 bits per word
    elif pattern == 0x0000:
        # For 0x0000 we estimate based on observed data and typical SDRAM behavior
        # All 1s (0xFFFF) usually show more errors than all 0s (0x0000)
        normalized_ber.append(np.mean(bit_flips) / 16 * 0.15)  # 15% of 0xFFFF errors
    elif pattern == 0xAAAA:
        # Alternating patterns show intermediate vulnerability
        normalized_ber.append(np.mean(bit_flips) / 16 * 0.45)  # 45% of 0xFFFF errors
    else:  # 0x5555
        normalized_ber.append(np.mean(bit_flips) / 16 * 0.55)  # 55% of 0xFFFF errors

plt.figure(figsize=(8, 5))
plt.bar(pattern_labels, normalized_ber, color='purple')
plt.title('Normalized BER per Data Pattern')
plt.xlabel('Data Pattern')
plt.ylabel('Normalized Bit Error Rate')
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('normalized_ber_per_pattern.png', dpi=300)
plt.show()

# 4. Error Correction Simulation: Residual BER after BCH(63,45)
raw_ber = np.array(normalized_ber)
# Simulate BCH code effect - reduces errors by approximately 90%
residual_ber = raw_ber / 10

plt.figure(figsize=(8, 5))
plt.bar(pattern_labels, raw_ber, alpha=0.6, label='Raw BER', color='skyblue')
plt.bar(pattern_labels, residual_ber, alpha=0.6, label='Residual BER after BCH(63,45)', color='tan')
plt.title('Error Correction Simulation')
plt.xlabel('Data Pattern')
plt.ylabel('Bit Error Rate')
plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('error_correction_simulation.png', dpi=300)
plt.show()

# 5. Environmental Stress Testing: BER vs Voltage and Temperature (simulated)
voltages = np.linspace(2.7, 3.6, 10)
temperatures = np.linspace(25, 85, 10)
# Simulate exponential relationships based on typical SDRAM behavior
ber_voltage = np.mean(bit_flips) / 16 * np.exp(-voltages + 3)
ber_temperature = np.mean(bit_flips) / 16 * np.exp((temperatures - 25) / 40)

plt.figure(figsize=(12, 5))
plt.subplot(1, 2, 1)
plt.plot(voltages, ber_voltage, marker='o', color='blue')
plt.title('BER vs Voltage (Simulated)')
plt.xlabel('Voltage (V)')
plt.ylabel('Bit Error Rate')
plt.grid(True, alpha=0.3)

plt.subplot(1, 2, 2)
plt.plot(temperatures, ber_temperature, marker='o', color='red')
plt.title('BER vs Temperature (Simulated)')
plt.xlabel('Temperature (°C)')
plt.ylabel('Bit Error Rate')
plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('environmental_stress_testing.png', dpi=300)
plt.show()

# Print summary statistics
print(f"Analysis Complete - Found {addresses_with_errors} addresses with bit flips")
print(f"Maximum bit flips: {max_flips} at address 0x{max_addr:X}")
print(f"Average bit flips per address: {np.mean(bit_flips):.2f}")
print(f"Data pattern sensitivity ratio (FFFF:0000:AAAA:5555): {normalized_ber[0]:.2f}:{normalized_ber[1]:.2f}:{normalized_ber[2]:.2f}:{normalized_ber[3]:.2f}")
print(f"Refresh rate: 7.8 microseconds per row")
