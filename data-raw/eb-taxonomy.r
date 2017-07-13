library(tidyverse)
library(stringi)

# eBird taxonomy
# source: http://help.ebird.org/customer/en/portal/articles/1006825-the-ebird-taxonomy
# typically updated annually in the late summer
eb_taxonomy <- read_csv("data-raw/eBird_Taxonomy_v2016.csv",
                           na = c("NA", "")) %>%
  set_names(tolower(names(.))) %>%
  select(taxon_order, category, species_code,
         name_common = primary_com_name, name_scientific = sci_name,
         order = order, family = family, report_as) %>%
  # ascii conversion
  mutate(name_common = stri_trans_general(name_common, "latin-ascii")) %>%
  # fill report_as field to aid joining
  mutate(report_as = if_else(category == "species", species_code, report_as)) %>%
  as_tibble()

eb_taxonomy <- eb_taxonomy %>%
  filter(!is.na(report_as), category == "species") %>%
  select(report_as,
         species_common = name_common,
         species_scientific = name_scientific) %>%
  left_join(eb_taxonomy, ., by = "report_as")

write_csv(eb_taxonomy, "data-raw/eb-taxonomy.csv", na = "")
devtools::use_data(eb_taxonomy, overwrite = TRUE, compress = "xz")