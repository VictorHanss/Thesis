import numpy as np
import matplotlib.pyplot as plt

rawfile = 'LV_exp-588_filtered-2_profile.csv'
medianfile = 'LV_exp-588_filtered-2_profile_median30.csv'
imageMeanValue = 40
protocolTitle = 'L.V.'
saveFileName = 'LV_plot.png'

## Change dataset files, plt.title and plt.savefile values for each pairs of profils.
## Adjust the value of the plt.axhline to the raw image mean value of pixels.

# Load raw dataset in text format with numpy
data1 = np.genfromtxt(rawfile, delimiter=',', skip_header=1)  # Replace 'dataset1.csv' with the actual path to your first CSV file

# Load median filtered dataset
data2 = np.genfromtxt(medianfile, delimiter=',', skip_header=1)  # Replace 'dataset2.csv' with the actual path to your second CSV file

# Extracts the x and y values for the raw dataset
x1 = data1[:, 0]
y1 = data1[:, 1]

# Extracts the x and y values for the filtered dataset
x2 = data2[:, 0]
y2 = data2[:, 1]

# Find minimum value in the filtered dataset
min_value_index = np.argmin(y2)  # Index of the minimum y-value
min_x = x2[min_value_index]  # x-value corresponding to the minimum y-value
min_y = y2[min_value_index]  # Minimum y-value

# Create plot
plt.figure(figsize=(10, 6))

# Plot datasets
plt.plot(x1, y1, label='Raw', color='gray', linestyle='-', linewidth = 1)
plt.plot(x2, y2, label='Median 30', color='red', linestyle='--', linewidth = 2)

# Add image mean value as an horizontal line
plt.axhline(y=imageMeanValue, color='green', linestyle='dotted', linewidth=1.5, label='Image Mean')

# Highlight the minimum value
plt.scatter(min_x, min_y, color='red', s=75, zorder=5, label='Min Value')  # Marker at the minimum point

# plot display parameters
plt.title('Profile of silver enhanced cell electroporated with {} protocol'.format(protocolTitle))
plt.xlabel('Pixel position')
plt.ylim([-10,265])
plt.ylabel('Grey Value')
plt.legend()  # Show legend
#plt.grid(True, axis ='y')  # Show grid
plt.grid(False)  # Show grid

#plt.rc('font', size=12)         # controls default text sizes
plt.rc('axes', titlesize=16)     # fontsize of the axes title
plt.rc('axes', labelsize=16)     # fontsize of the x and y labels
plt.rc('legend', fontsize=14)    # Legend axes
plt.rc('figure', titlesize=12)   # fontsize of the figure title

#Save plot as png -> has to be before plt.show() otherwise display is cleared and image is blank
plt.savefig(saveFileName,transparent=True, dpi=150)

# Show the plot
plt.show()
