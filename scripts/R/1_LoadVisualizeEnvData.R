### Environmental Datasets
### 
### In this script I will import and visualize the spatial datasets that I downloaded from CMEMS (2m temp 1940-2026) and GMRT (topography).


### 1) Load required libraries (install the required libraries using the Packages tab, if necessary)
library('terra') # library used to manipulate raster files 
library('sf') # library to manipulate spatial polygons
library('ggplot2') # library to produce advanced plots
library('ggsn') # library to add scalebars to ggplot maps -> to install: devtools::install_github('oswaldosantos/ggsn')
library("rnaturalearth") # library to add polygons of the countries to a map
library("rnaturalearthdata") # library to add polygons of the countries to a map


### 2) Import and visualize a raster file 

# The data we downloaded from GMRT (topography) is under the format .grd.
# In geographic information systems, this is referred to as a "raster" file. 
# A raster is an image that is georeferenced to a region. 
# Note that are other extensions for raster files that are commonly used, for instance geoTiff (.tif).
# We can open a raster file using the raster function. 

topo = rast('swiss_topography.tif') # use the file you downloaded from GMRT


# This creates a raster object. We can visualize its properties by calling the object:
topo

# Here we can observe the key features of this object, such as the number of cells (pixels), the resolution, the spatial extent covered or the coordinates reference system used (crs).
# We can see that the image is a pixel matrix of 2007 rows and 1424 columns. 
# We can visualize the values of the first 10 pixels (on the top-left corner) of the image using the following code:
topo[1:10]

# We can also visualize the topography map using the plot function.
plot(topo)

# We can also apply more complex filters by setting color "breaks" when plotting the map. 
# We first visualize the distribution of the topography values (i.e. for all the pixels)
hist(topo[])

# And we decide to set 4 bins defined by 5 breaks at: 0, 500, 1000, 2000, 3000 As we plot, we also set the colors to be used to represent the pixels falling within each bin. 
plot(topo, breaks=c(0, 250, 500, 1000, 2000, 3000, 4000), col=c('red','orange','yellow','green','blue', 'white'))


### 2) Import and visualize a stack of rasters
# The data we downloaded from CMEMS (temperature and salinity) is under the format .nc (Network Common Data Form). 
# This is a format used to store scientific variables with multiple dimensions. 
# In the case of the sea temperature, for instance, the data we downloaded covers 3 dimensions: longitude, latitude and time. 
# We can open a multidimensional file using the rast function.
# Let's try: 
SST = rast('2m_temp_1940-2026.grib')
SST

# Here you can see that an additional dimension is added to the object: nlayers. 
# nlayers is equal to 365: every layer of this object is the record of a different day of 2013. 
# We can plot SST for the first day of 2013 (01.01) using the command: 
plot(SST[[1]])

# ...for the second day...
plot(SST[[2]])
# ... and so on. 

# We can also visualize the first ten days all together:
plot(SST[[1:10]])

# Or even plot the difference in SST between two days
plot(SST[[1]]-SST[[2]])


### 3) Output a map
# We will now see how to produce maps of the environmental data that we downloaded. 
# For this exercise, we will produce a map of the topography profile of the study area.
# The map should have the following characteristics: 
# 1) topography colored on a scale from red to white low alt to high. 
# 2) The edge of the map showing the coordinates grid. 
# 3) Presence of a scale bar and a legend.
# 4) Format: PDF. 
# There are several ways of producing a map with these characteristics. 
# We will try two methods: A) using the native R functions for plotting; B) Using the ggplot package.


## (A) Map using the standard R functions

# Native R plot functions can be used to produce maps with simple customization options.

# We first need to create the new colorscale. The colorRampPalette function creates a function determining a color scale. 
CS = colorRampPalette(colors = c('yellow', 'red'))
# We can then use this colorscale function to set the colors to use in the map.
plot(topo, col=CS(5)) # creates a colorscale of 5 colors from blue to yellow
plot(topo, col=CS(500)) # creates a colorscale of 500 colors from blue to yellow

# A scalebar can be added using the sbar function
sbar(250, xy = 'topright', divs = 2, below = '250 km',labels = '' )

# Now that we saw how the commands work, we can create a PDF. 
# We first open a pdf graphic device...
pdf("topography_map.pdf", width=6.5, height=8)
# Then we add all the layers of the plot...
plot(topo, col=CS(500)) 
sbar(250, xy = 'topright', divs = 2, below = '250 km',labels = '' )
# ... and finally we close the device. 
dev.off()


## (B) Map using ggplot

# ggplot is a popular package for customizing plots in R.
# ggplot features a syntax that is different from the native of R plot. For this reason, it can appear quite complex for beginners. 
# However, once learned, the use of ggplot plot offers substantial advantages. 
# First of all, ggplot enables to produce plots with less code. Second, ggplot overcomes many limitations related to native R plotting functions, and enables a deeper degree of customization. 

# In order to plot a raster with ggplot, we need to convert it to a dataframe:
# Convert the SpatRaster to a data frame
topo_df <- as.data.frame(topo, xy = TRUE, na.rm = TRUE)

# Check the name of the elevation column
names(topo_df)


# Now we can plot the map. Note that the ggplot syntax adds element to the plot using the "+" connector. 
ggplot() + # create a plot
  geom_raster(data = topo_df , aes(x = x, y = y, fill = swiss_topography)) + # add the bathymetry raster. The "data" argument indicates the data to use, while the aes (aesthetic) object indicates the variables to use to draw the map.  
  scale_fill_gradientn(name = "Elevation (m)", colors = CS(500))  +  # set the colorscale for the bathymetry raster (note: we are using the same colorscale as above)
  theme(panel.background = element_rect(fill = "white", colour = "black"),  axis.title = element_blank()) # format the background of the map to a white canvas. 

# The plot can be saved using the ggsave function:
ggsave("topography_map_ggplot.pdf")
