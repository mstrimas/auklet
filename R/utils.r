get_header <- function(x, sep = ",") {
  readLines(x, n = 1) %>%
    stringr::str_split(sep) %>%
    `[[`(1) %>%
    trimws()
}
