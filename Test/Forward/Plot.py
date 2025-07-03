import matplotlib.pyplot as plt

# Data: (Refresh Period in µs, Bit Flip Percentage)
refresh_periods_us = [15.6, 31.3, 62.5, 125.0]
bit_flip_percentages = [0.4226, 0.5788, 0.764, 1.47]

# Plotting
plt.figure(figsize=(8, 5))
plt.plot(refresh_periods_us, bit_flip_percentages, marker='o', linestyle='-', color='b', label='Bit Flip %')

# Annotate each point with its percentage, slightly above each marker
for x, y in zip(refresh_periods_us, bit_flip_percentages):
    plt.text(x, y + 0.05, f'{y:.2f}%', ha='center', va='bottom', fontsize=10, color='darkblue')

# Formatting
plt.title('Bit Flip Percentage vs. Refresh Period', fontsize=14)
plt.xlabel('Refresh Period per Row (µs)', fontsize=12)
plt.ylabel('Bit Flip Percentage (%)', fontsize=12)
plt.grid(True)
plt.xticks(refresh_periods_us)
plt.ylim(0, max(bit_flip_percentages) * 1.3)  # Add some headroom on y-axis
plt.legend(fontsize=10)
plt.tight_layout()

# Save before showing
plt.savefig("bit_flip_vs_refresh.png", dpi=300)
plt.show()
