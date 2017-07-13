#' eBird daily life list
#'
#' Generate a daily life list, i.e. for each day of the year list the species
#' seen on that day regardless of year. For each species, the year in which that
#' species was first observed is shown. Use [summary()] to summarize the list of
#' species seen each day into counts of the number of species seen each day.
#' To visualize your day life lists, use [plot()].
#'
#' @param x [eb_sightings] object; your personal eBird sightings
#'
#' @return A [dplyr::tibble], with additional class `eb_daylist`, containing
#'   your personal sightings.
#' @export
#' @examples
#' day_list <- system.file("extdata/MyEBirdData.csv", package = "ebird") %>%
#'   eb_sightings() %>%
#'   eb_daylist()
#' summary(day_list)
#' plot(day_list, target = 50)
eb_daylist <- function(x) {
  UseMethod("eb_daylist")
}

#' @export
eb_daylist.eb_sightings <- function(x) {
  # determine species list
  day_list <- x %>%
    dplyr::filter(!is.na(.data$report_as)) %>%
    dplyr::mutate(year = lubridate::year(.data$date),
                  month = lubridate::month(.data$date),
                  day = lubridate::day(.data$date)) %>%
    # species seen on each day
    dplyr::group_by(.data$report_as, .data$month, .data$day) %>%
    dplyr::arrange(.data$report_as, .data$month, .data$day, .data$year) %>%
    dplyr::filter(dplyr::row_number(.data$year) == 1) %>%
    dplyr::ungroup() %>%
    dplyr::select(.data$year, .data$month, .data$day, .data$report_as)

  # bring in taxonomuy
  day_list <- auklet::eb_taxonomy %>%
    dplyr::filter(!is.na(.data$report_as), .data$category == "species") %>%
    dplyr::select(.data$report_as, .data$order, .data$family,
                  .data$species_common, .data$species_scientific) %>%
    dplyr::left_join(day_list, ., by = "report_as") %>%
    dplyr::rename(species_code = .data$report_as) %>%
    dplyr::arrange(.data$month, .data$day, .data$year, .data$species_code)

  class(day_list) <- c("eb_daylist", class(day_list))
  return(day_list)
}

#' @param object `eb_daylist` object; your daily life lists.
#' @param by_year logical; whether to retain the year first when tallying up
#'   species. Set this to `TRUE` if, for example, you're interested in how many
#'   new species you added each year on a given day.
#' @param ... not used
#'
#' @describeIn eb_daylist Summarize daily life lists into counts of species seen
#'   on each day.
#' @export
summary.eb_daylist <- function(object, by_year = FALSE, ...) {
  stopifnot(is.logical(by_year), length(by_year) == 1)

  # tally up species seen each day
  if (by_year) {
    object %>%
      dplyr::group_by(.data$year, .data$month, .data$day) %>%
      dplyr::summarize(n = dplyr::n_distinct(.data$species_code)) %>%
      dplyr::ungroup() %>%
      dplyr::select(.data$year, .data$month, .data$day, .data$n)
  } else {
    object %>%
      dplyr::group_by(.data$month, .data$day) %>%
      dplyr::summarize(n = dplyr::n_distinct(.data$species_code)) %>%
      dplyr::ungroup() %>%
      dplyr::select(.data$month, .data$day, .data$n)
  }
}

#' @param target numeric; add a line to the plot showing your targeted number
#'   of species to see each day.
#' @param title character; plot title.
#' @param subtitle character; plot subtitle.
#' @describeIn eb_daylist Visualize your day life lists
#' @export
plot.eb_daylist <- function(x, target, title, subtitle, ...) {
  # daily counts
  x <- summary(x, by_year = TRUE) %>%
    # use 2016 becaues it's a leap year
    dplyr::mutate(date = lubridate::ymd(paste(2016, .data$month, .data$day,
                                              sep = "-")))

  # put target at 0 if not given
  if (missing(target)) {
    target <- 0
  } else {
    stopifnot(is.numeric(target), length(target) == 1)
  }
  # default titles
  if (missing(title)) {
    title <- "eBird Daily Life Lists"
  } else {
    stopifnot(is.character(title), length(title) == 1)
  }
  if (missing(subtitle)) {
    subtitle <- "Number of species reported on eBird on each day of the year"
  } else {
    stopifnot(is.character(subtitle), length(subtitle) == 1)
  }

  # legend breaks
  yr_brks <- as.integer(range(x$year))
  nm <- c(yr_brks[1], "year first reported", yr_brks[2])
  yr_brks <- c(yr_brks[1], mean(yr_brks), yr_brks[2])
  names(yr_brks) <- nm

  # y axis
  yrng <- dplyr::group_by(x, .data$month, .data$day) %>%
    dplyr::summarize(n = sum(.data$n))
  ymax <- max(yrng$n)
  ymax <- max(ymax, target)
  # determin sensible breaks
  if (ymax < 200) {
    brk <- 25
  } else if (ymax < 500) {
    brk <- 50
  } else {
    brk <- 100
  }
  ymax <- ceiling(ymax / brk) * brk
  y_brks <- seq(0, ymax, by = brk)

  # plot
  ggplot2::ggplot(x, ggplot2::aes_string(x = "date", y = "n")) +
    ggplot2::geom_hline(yintercept = target, color = "light blue", size = 1) +
    ggplot2::geom_bar(ggplot2::aes_string(fill = "year"), stat = "identity",
                      width = 1) +
    ggplot2::geom_hline(yintercept = 0, color = "#666666", size = 1.5) +
    ggplot2::scale_x_date(NULL, date_breaks = "months", date_labels = "%b",
                          limits = c(as.Date("2016-01-01"),
                                     as.Date("2016-12-31")),
                          expand = c(0, 0)) +
    ggplot2::scale_y_continuous(NULL, limits = c(0, ymax), breaks = y_brks,
                                expand = c(0, 0)) +
    viridis::scale_fill_viridis("", breaks = yr_brks, labels = names(yr_brks)) +
    ggplot2::labs(title = title, subtitle = subtitle) +
    ggplot2::theme(legend.key.width = ggplot2::unit(0.1, "npc"),
                   legend.key.height = ggplot2::unit(10, "pt"),
                   legend.position = "bottom",
                   panel.background = ggplot2::element_rect(fill = "#ffffff"),
                   panel.grid.minor = ggplot2::element_blank(),
                   panel.grid.major = ggplot2::element_line(linetype = "dotted",
                                                            color = "#666666",
                                                            size = 0.25),
                   axis.ticks = ggplot2::element_blank())
}
