### Make weak and strong distance-weighted migration matrices for four demes.
###
### Rows are sources and columns are destinations. Diagonal entries are zero.
### Every weak row sums to 0.001 and every strong row sums to 0.010.
### Distance controls how each source's fixed total emigration is divided
### among the other three demes.

workspace <- Sys.getenv(
	"MSC_WORKSPACE",
	unset = "C:/Users/WilliamWallisch/msc_workspace"
)
input_directory <- file.path(
	workspace,
	"SLiM/input/grib_pop_index_local_adaptation"
)

population_file <- file.path(
	input_directory,
	"population_locations/grib_population_locations_4pop_swiss_plateau.csv"
)
weak_migration_file <- file.path(
	input_directory,
	"migration_matrix/grib_migration_matrix_4pop_weak.csv"
)
strong_migration_file <- file.path(
	input_directory,
	"migration_matrix/grib_migration_matrix_4pop_strong.csv"
)
details_metadata_file <- file.path(
	input_directory,
	"metadata/grib_migration_matrix_4pop_distance_details_metadata.csv"
)
summary_metadata_file <- file.path(
	input_directory,
	"metadata/grib_migration_matrix_4pop_distance_summary_metadata.csv"
)

total_emigration_rates <- c(
	weak = 0.001,
	strong = 0.010
)
migration_distance_scale_km <- 75
output_decimal_places <- 12L

degrees_to_radians <- function(degrees)
{
	degrees * pi / 180
}

haversine_distance_km <- function(lon1, lat1, lon2, lat2)
{
	earth_radius_km <- 6371

	lon1 <- degrees_to_radians(lon1)
	lat1 <- degrees_to_radians(lat1)
	lon2 <- degrees_to_radians(lon2)
	lat2 <- degrees_to_radians(lat2)

	d_lon <- lon2 - lon1
	d_lat <- lat2 - lat1

	a <- sin(d_lat / 2)^2 +
		cos(lat1) * cos(lat2) * sin(d_lon / 2)^2
	c <- 2 * atan2(sqrt(a), sqrt(1 - a))

	earth_radius_km * c
}

### Allocate integer units of 10^-12 so the decimal values written in every
### row sum exactly to the requested treatment total.
allocate_exact_rates <- function(weights, total_rate, decimal_places)
{
	scale <- 10^decimal_places
	total_units <- round(total_rate * scale)
	raw_units <- weights / sum(weights) * total_units
	rate_units <- floor(raw_units)
	unallocated_units <- total_units - sum(rate_units)

	if (unallocated_units > 0)
	{
		fractional_parts <- raw_units - rate_units
		recipient_order <- order(
			fractional_parts,
			decreasing = TRUE
		)
		recipients <- recipient_order[
			seq_len(unallocated_units)
		]
		rate_units[recipients] <-
			rate_units[recipients] + 1
	}

	if (sum(rate_units) != total_units)
		stop("Exact-rate allocation failed.")

	rate_units / scale
}

make_migration_matrix <- function(
	distance_matrix_km,
	total_rate,
	distance_scale_km,
	decimal_places
)
{
	number_of_populations <- nrow(distance_matrix_km)
	migration_matrix <- matrix(
		0,
		nrow = number_of_populations,
		ncol = number_of_populations
	)

	for (source in seq_len(number_of_populations))
	{
		destinations <- setdiff(
			seq_len(number_of_populations),
			source
		)
		distance_weights <- exp(
			-distance_matrix_km[source, destinations] /
				distance_scale_km
		)
		migration_matrix[source, destinations] <-
			allocate_exact_rates(
				distance_weights,
				total_rate,
				decimal_places
			)
	}

	migration_matrix
}

write_migration_matrix <- function(
	migration_matrix,
	output_file,
	decimal_places
)
{
	formatted_matrix <- matrix(
		formatC(
			as.vector(migration_matrix),
			format = "f",
			digits = decimal_places
		),
		nrow = nrow(migration_matrix),
		ncol = ncol(migration_matrix)
	)

	write.table(
		formatted_matrix,
		file = output_file,
		sep = ",",
		quote = FALSE,
		row.names = FALSE,
		col.names = FALSE
	)
}

populations <- read.csv(
	population_file,
	stringsAsFactors = FALSE
)
required_columns <- c("pop", "location", "lon", "lat")

if (!all(required_columns %in% names(populations)))
	stop("Population file needs columns: pop, location, lon, lat.")

populations <- populations[
	order(populations$pop),
	required_columns
]

if (
	nrow(populations) != 4L ||
	!identical(as.integer(populations$pop), 0:3)
)
	stop("Expected four sequential population IDs: 0, 1, 2, 3.")

number_of_populations <- nrow(populations)
distance_matrix_km <- matrix(
	0,
	nrow = number_of_populations,
	ncol = number_of_populations
)

for (source in seq_len(number_of_populations))
{
	for (destination in seq_len(number_of_populations))
	{
		if (source == destination)
			next

		distance_matrix_km[source, destination] <-
			haversine_distance_km(
				populations$lon[source],
				populations$lat[source],
				populations$lon[destination],
				populations$lat[destination]
			)
	}
}

migration_matrices <- lapply(
	total_emigration_rates,
	function(total_rate)
		make_migration_matrix(
			distance_matrix_km,
			total_rate,
			migration_distance_scale_km,
			output_decimal_places
		)
)

dir.create(dirname(weak_migration_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(details_metadata_file), recursive = TRUE, showWarnings = FALSE)

write_migration_matrix(
	migration_matrices$weak,
	weak_migration_file,
	output_decimal_places
)
write_migration_matrix(
	migration_matrices$strong,
	strong_migration_file,
	output_decimal_places
)

details_metadata <- do.call(
	rbind,
	lapply(
		names(migration_matrices),
		function(treatment)
		{
			migration_matrix <- migration_matrices[[treatment]]
			do.call(
				rbind,
				lapply(
					seq_len(number_of_populations),
					function(source)
					{
						destinations <- setdiff(
							seq_len(number_of_populations),
							source
						)
						data.frame(
							treatment = treatment,
							total_emigration_rate =
								unname(total_emigration_rates[treatment]),
							source_pop = populations$pop[source],
							source_location =
								populations$location[source],
							destination_pop =
								populations$pop[destinations],
							destination_location =
								populations$location[destinations],
							distance_km = round(
								distance_matrix_km[
									source,
									destinations
								],
								3
							),
							distance_weight = round(
								exp(
									-distance_matrix_km[
										source,
										destinations
									] /
										migration_distance_scale_km
								),
								8
							),
							migration_rate =
								migration_matrix[
									source,
									destinations
								]
						)
					}
				)
			)
		}
	)
)

summary_metadata <- do.call(
	rbind,
	lapply(
		names(migration_matrices),
		function(treatment)
		{
			row_totals <- rowSums(migration_matrices[[treatment]])
			data.frame(
				treatment = treatment,
				total_emigration_rate_target =
					unname(total_emigration_rates[treatment]),
				pop = populations$pop,
				location = populations$location,
				migration_distance_scale_km =
					migration_distance_scale_km,
				total_out_migration_rate = row_totals,
				expected_migrants_at_K500 =
					row_totals * 500,
				expected_migrants_at_K2000 =
					row_totals * 2000,
				expected_migrants_at_K5000 =
					row_totals * 5000
			)
		}
	)
)

write.csv(
	details_metadata,
	details_metadata_file,
	row.names = FALSE
)
write.csv(
	summary_metadata,
	summary_metadata_file,
	row.names = FALSE
)

written_matrices <- list(
	weak = as.matrix(read.csv(
		weak_migration_file,
		header = FALSE
	)),
	strong = as.matrix(read.csv(
		strong_migration_file,
		header = FALSE
	))
)

for (treatment in names(written_matrices))
{
	written_matrix <- written_matrices[[treatment]]
	target <- unname(total_emigration_rates[treatment])

	if (!identical(dim(written_matrix), c(4L, 4L)))
		stop(treatment, " migration matrix is not 4 x 4.")

	if (any(diag(written_matrix) != 0))
		stop(treatment, " migration matrix has a nonzero diagonal.")

	if (any(abs(rowSums(written_matrix) - target) > 1e-15))
		stop(
			treatment,
			" migration rows do not sum to ",
			target,
			"."
		)
}

message("Wrote weak migration matrix: ", weak_migration_file)
message("Wrote strong migration matrix: ", strong_migration_file)
message("Wrote migration details: ", details_metadata_file)
message("Wrote migration summary: ", summary_metadata_file)
print(migration_matrices)
print(summary_metadata)
