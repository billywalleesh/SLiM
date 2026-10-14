## build a function of linear decay 

linear_decay = function(d, a, b) { # d is the distance value, a the intercept, b is the slope
  
  mr = a + d*b # migration rate simple linear regression of d
  
  mr[mr<0] = 0 # negative migration values not allowed
  mr[d == 0] = NA # if distance is 0, return NAs
  
  return(mr)
}


## Let's try the function on different distance data
d = 1:1000 # distance from 1 to 1000 km 

mr = linear_decay(d, a = 0.005, b = -0.001/100) 
# a = 0.005 means that at distance ~0 migration rate is 0.005
# b = 0.001/100 means that every 100 km migration rates drop by 0.001

# we can visualize this relationship across many distances
plot(d, mr, type='l')


### We can try a weaker distance decay, for example 0.001 by 200 km (= strong dispersal)
mr = linear_decay(d, a=0.005, b=-0.001/200) 
plot(d, mr, type='l')

### Or a stronger distance decay, for example 0.001 by 50 km  (= weak dispersal)
mr = linear_decay(d, a=0.005, b=-0.001/50) 
plot(d, mr, type='l')



#### Test on real data


## Coordinates of cities
coordinates = data.frame()
coordinates['geneva',1:2]=c(46.211464648492914, 6.14748447123683)
coordinates['lausanne',1:2]   = c(46.5197, 6.6323)
coordinates['neuchatel',1:2]  = c(46.9896, 6.9293)
coordinates['bern',1:2] =c(46.94798849012668, 7.446219548848173)
coordinates['solothurn',1:2]  = c(47.2088, 7.5372)
coordinates['lucerne',1:2]    = c(47.0502, 8.3093)
coordinates['winterthur',1:2] = c(47.4988, 8.7237)
coordinates['stgallen',1:2] = c(47.42899841401629, 9.376234097036747)
coordinates

## Calculate distances
library(sf)

colnames(coordinates) = c('lat','lon') 

# set coordinates to spatial object
coord_sp <- st_as_sf(coordinates, coords = c("lon", "lat"), crs = 4326)

# calculate distances in km
geoD = as.matrix(st_distance(coord_sp)/1000)
colnames(geoD)=rownames(geoD)= rownames(coordinates)
geoD = units::drop_units(geoD)

# convert distance from km to migration rates using the function 
linear_decay(geoD, a = 0.005, b=-0.001/100)

linear_decay(geoD, a = 0.005, b=-0.001/200) # stronger dispersal 

linear_decay(geoD, a = 0.005, b=-0.001/50) # weaker dispersal 






