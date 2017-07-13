#' Convert a data frame to a eb_sightings object
#'
#' An [eb_sightings] object is just a data frame with the additional class
#' `eb_sightings`. When working with these S3 objects using functions outside
#' this package, it is possible that the class will be dropped and they will be
#' reverted to plain data frames. Use `df_to_eb` to convert a data frame back to
#' an `eb_sightings` object. Checks are performed to ensure that column names,
#' ordering, and data types have been preserved.
#'
#' @param x data.frame; eBird sightings stored as a data frame.
#'
#' @return An [eb_sightings] object.
#' @export
#' @examples
#' # convert sightings to plain data frame
#' eb_data <- system.file("extdata/MyEBirdData.csv", package = "auklet") %>%
#'   eb_sightings() %>%
#'   as.data.frame()
#' class(eb_data)
#' class(df_to_eb(eb_data))
df_to_eb <- function(x) {
  stopifnot(is.data.frame(x))
  x <- dplyr::as_tibble(x)
  if (inherits(x, "eb_sightings")) {
    return(x)
  }

  # check for correct number of columns
  if (ncol(x) != ncol(eb_template)) {
    m <- paste("Cannont convert to an eb_sightings object. Incorrect number of",
               "columns.")
    stop(m)
  }

  # check for correct names
  if (!all(names(x) == names(eb_template))) {
    m <- paste("Cannont convert to an eb_sightings object. Variable names or",
               "ordering is not correct.")
    stop(m)
  }

  # check for correct types
  class_vec <- function(y) {class(y)[1]}
  if (!all(vapply(x, class_vec, "") == vapply(eb_template, class_vec, ""))) {
    m <- paste("Cannont convert to an eb_sightings object. Column data types",
               "are not correct")
    stop(m)
  }

  class(x) <- c("eb_sightings", class(x))
  return(x)
}
