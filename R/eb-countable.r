#' Remove taxa that don't count towards your life list
#'
#' Removes any records from your eBird data reporting taxa that can't be
#' resolved to a countable species. This includes slashes, spuhs, undescribed
#' forms, and domestic species.
#'
#' @param x [eb_sightings] object; your personal eBird sightings
#'
#' @return An [eb_sightings] object.
#' @export
#' @examples
#' f <- system.file("extdata/MyEBirdData.csv", package = "auklet")
#' ebird_data <- eb_sightings(f)
#' nrow(ebird_data)
#' nrow(eb_countable(ebird_data))
eb_countable <- function(x) {
  UseMethod("eb_countable")
}

#' @export
eb_countable.eb_sightings <- function(x) {
  dplyr::filter(x, !is.na(.data$report_as))
}

#' @export
eb_countable.data.frame <- function(x) {
  eb_countable.eb_sightings(df_to_eb(x))
}
