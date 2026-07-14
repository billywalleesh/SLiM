### Extend the GRIB-derived climate anomaly matrix to 2050 using a simple trend.
###
### Biological story:
### 1. Use observed annual climate anomalies from the GRIB through 2026.
### 2. Estimate each population's recent warming trend.
### 3. Project that trend forward to 2050.
### 4. SLiM can then hold the 2050 climate constant for a post-2050 recovery window.
###
### This is not a climate-model scenario. It is a transparent sensitivity test:
### "What if recent local warming trends continue until 2050?"

workspace <- "C:/Users/WilliamWallisch/msc_workspace"
input_directory <- file.path(workspace, "SLiM/input/grib_pop_index_local_adaptation")

observed_metadata_file <- file.path(input_directory, "metadata/grib_climate_matrix_2pop_metadata.csv")

trend_matrix_file <- file.path(input_directory, "climate_matrix/grib_climate_matrix_2pop_trend_2050.csv")
trend_years_file <- file.path(input_directory, "climate_matrix/grib_climate_years_2pop_trend_2050.csv")
trend_metadata_file <- file.path(input_directory, "metadata/grib_climate_matrix_2pop_trend_2050_metadata.csv")
trend_summary_file <- file.path(input_directory, "metadata/grib_climate_matrix_2pop_trend_2050_summary_metadata.csv")

### Use recent observed years to estimate the linear trend.
### This is the main assumption in this test scenario.
trend_years <- 1990:2026
forecast_years <- 2027:2050

if (!file.exists(observed_metadata_file))
	stop("Observed climate metadata not found. Run 3_grib_climate_matrix_2pop.R first.")

observed <- read.csv(observed_metadata_file)
pop_columns <- setdiff(names(observed), "year")

trend_rows <- observed$year %in% trend_years
if (!any(trend_rows))
	stop("No observed years found for trend_years.")

future <- data.frame(year = forecast_years)
trend_summary <- data.frame()

for (pop_column in pop_columns)
{
	trend_data <- data.frame(
		year = observed$year[trend_rows],
		anomaly = observed[[pop_column]][trend_rows]
	)
	
	trend_model <- lm(anomaly ~ year, data = trend_data)
	projected_anomaly <- predict(trend_model, newdata = data.frame(year = forecast_years))
	
	future[[pop_column]] <- projected_anomaly
	
	trend_summary <- rbind(
		trend_summary,
		data.frame(
			pop = pop_column,
			trend_start = min(trend_years),
			trend_end = max(trend_years),
			slope_c_per_year = coef(trend_model)[["year"]],
			observed_2026_anomaly = observed[[pop_column]][observed$year == 2026],
			projected_2050_anomaly = projected_anomaly[forecast_years == 2050]
		)
	)
}

extended <- rbind(
	observed[, c("year", pop_columns)],
	future[, c("year", pop_columns)]
)

climate_source <- ifelse(
	extended$year <= max(observed$year),
	"observed_grib",
	"linear_projection"
)

extended_metadata <- data.frame(
	year = extended$year,
	climate_source = climate_source,
	round(extended[, pop_columns], 4)
)

write.table(
	round(as.matrix(extended[, pop_columns]), 4),
	file = trend_matrix_file,
	sep = ",",
	row.names = FALSE,
	col.names = FALSE
)

write.table(
	extended$year,
	file = trend_years_file,
	sep = ",",
	row.names = FALSE,
	col.names = FALSE
)

write.csv(extended_metadata, trend_metadata_file, row.names = FALSE)
write.csv(trend_summary, trend_summary_file, row.names = FALSE)

print(tail(extended_metadata, 10))
message("Wrote trend-extended anomaly matrix to: ", trend_matrix_file)
message("Wrote trend-extended climate years to: ", trend_years_file)
message("Wrote trend metadata to: ", trend_metadata_file)
message("Wrote trend summary to: ", trend_summary_file)
