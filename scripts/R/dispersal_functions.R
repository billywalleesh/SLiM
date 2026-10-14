## dispersal_functions.R
## Distance-decay migration function, taken unchanged from 32_dispersal_decay_function.R
## so it can be source()'d without running the plots and test code

linear_decay = function(d, a, b) { # d is the distance value, a the intercept, b is the slope

  mr = a + d*b # migration rate simple linear regression of d

  mr[mr<0] = 0 # negative migration values not allowed
  mr[d == 0] = NA # if distance is 0, return NAs

  return(mr)
}
