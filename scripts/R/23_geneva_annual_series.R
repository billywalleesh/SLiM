suppressPackageStartupMessages(library(terra))
slim <- "/tmp/ws/SLiM"
g <- rast(file.path(slim, "data/raw/2m_temp_1940-2026.grib"))
d <- as.Date(time(g)); yr <- as.integer(format(d, "%Y"))
v <- as.numeric(extract(g, cbind(6.1432, 46.2044))[1, -1]) - 273.15
ok <- yr %in% 1940:2025
ann <- tapply(v[ok], yr[ok], mean)
n   <- tapply(v[ok], yr[ok], length)
out <- data.frame(year = as.integer(names(ann)), temp = as.numeric(ann),
                  days = as.integer(n))
out <- out[out$days >= 360, ]                     # drop any part year
write.csv(out, "geneva_annual.csv", row.names = FALSE)
fit <- lm(temp ~ year, data = out)
cat(sprintf("years %d-%d  n=%d\n", min(out$year), max(out$year), nrow(out)))
cat(sprintf("mean first 30: %.2f   mean last 30: %.2f   diff %.2f\n",
            mean(head(out$temp, 30)), mean(tail(out$temp, 30)),
            mean(tail(out$temp, 30)) - mean(head(out$temp, 30))))
cat(sprintf("trend %.4f degC/yr  = %.2f degC per century; total over record %.2f\n",
            coef(fit)[2], coef(fit)[2]*100,
            coef(fit)[2]*(max(out$year)-min(out$year))))
cat(sprintf("coldest %d (%.2f)  warmest %d (%.2f)\n",
            out$year[which.min(out$temp)], min(out$temp),
            out$year[which.max(out$temp)], max(out$temp)))
