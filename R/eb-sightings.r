#' Read a eBird personal sightings file
#'
#' Your personal eBird sightings can be downloaded as a CSV file through the
#' [eBird website](http://ebird.org/ebird/downloadMyData). This function reads
#' the eBird data file, cleans up the variable names, and performs some basic
#' processing.
#'
#' @param file character; name of your personal eBird sightings files. This file
#'   can be downloaded from the
#'   [eBird website](http://ebird.org/ebird/downloadMyData).
#' @param countable logical; whether to only return countable species, i.e.
#'   those that are counted on your life list by eBird.
#'
#' @details Some "species" reported on ebird are not true species. For example,
#'   they may be domestic or not resolved to the species level (e.g. *Empidonax
#'   sp.* or *Greater/Lesser Yellowlegs*), in which case they do not count
#'   towards your life list. Alternatively, sightings may be reported below the
#'   species level (e.g. subspecies or recognizable forms), in which case they
#'   must be rolled up to species level prior to reporting. Addiontal fields
#'   from the ebird taxonomy ([`eb_taxonomy`]) are added to the sightings data
#'   set to resolve these cases. The `category` field can be used to identify
#'   different categories of "species". The `report_as`, `species_common`, and
#'   `species_scientific` fields identify the true species corresponding to taxa
#'   reported below species. these fields are all `NA` for taxa not resolvable
#'   to species.
#'
#' @return A [dplyr::tibble], with additional class `eb_sightings`, containing
#'   your personal sightings.
#' @export
#' @examples
#' system.file("extdata/MyEBirdData.csv", package = "auklet") %>%
#'   eb_sightings()
eb_sightings <- function(file, countable = FALSE) {
  # checks
  stopifnot(is.character(file), length(file) == 1, file.exists(file))

  # check that columns are correct
  if (!all(get_header(file) == eb_data_cols)) {
    stop("Problem detected with the eBird sightings file header")
  }

  # read
  col_formats <- readr::cols(
    .default = readr::col_character(),
    Latitude = readr::col_double(),
    Longitude = readr::col_double(),
    Time = readr::col_time(format = "%I:%M %p"),
    Date = readr::col_date(format = "%m-%d-%Y"),
    `Duration (Min)` = readr::col_integer(),
    `All Obs Reported` = readr::col_logical(),
    `Distance Traveled (km)` = readr::col_double(),
    `Number of Observers` = readr::col_integer()
  )
  s <- suppressWarnings(
    readr::read_csv(file, col_types = col_formats, na = "")
  )

  # drop problems related to missing final columns
  probs <- readr::problems(s) %>%
    dplyr::filter(!(is.na(.data$col) & .data$expected > .data$actual))
  if (nrow(probs) > 0) {
    m <- paste0(nrow(probs), " problems parsing eBird sightings file\n",
                "Use readr::problems(x) to view errors")
    warning(m)
    probs <- NULL
  }
  attr(s, "problems") <- probs

  # clean names
  nm <- s %>%
    names() %>%
    tolower() %>%
    stringr::str_replace_all(" \\([a-z]+\\)", "") %>%
    stringr::str_replace_all("[^a-z]", "_")
  names(s) <- nm

  # split state and country
  s_p <- stringr::str_split(s$state_province, "-", n = 2, simplify = TRUE)
  s$state_province <- NULL
  s$country <- s_p[, 1]
  s$state_province <- s_p[, 2]

  # bring in taxonomy
  s <- s %>%
    dplyr::select(-.data$common_name, -.data$taxonomic_order) %>%
    dplyr::select(.data$submission_id, .data$count, .data$country,
                  .data$state_province, dplyr::everything()) %>%
    dplyr::rename(name_scientific = .data$scientific_name) %>%
    dplyr::right_join(auklet::eb_taxonomy, ., by = "name_scientific") %>%
    dplyr::select(.data$submission_id, dplyr::everything())
  # warn if any species were not found
  n_miss <- sum(is.na(s$species_code))
  if (n_miss != 0) {
    m <- paste0("Error joining sightings to taxonomy: ",
                format(n_miss, big.mark = ","),
                " records not found in taxononmy\n",
                "Try updating this package and re-downloading your sightings")
    warning(m)
  }
  if (countable) {
    s <- eb_countable(s)
  }
  class(s) <- c("eb_sightings", class(s))
  return(s)
}

eb_data_cols <- c(
  "Submission ID", "Common Name", "Scientific Name", "Taxonomic Order",
  "Count", "State/Province", "County", "Location", "Latitude", "Longitude",
  "Date", "Time", "Protocol", "Duration (Min)", "All Obs Reported",
  "Distance Traveled (km)", "Area Covered (ha)", "Number of Observers",
  "Breeding Code", "Species Comments", "Checklist Comments"
)
