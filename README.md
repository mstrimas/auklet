<!-- README.md is generated from README.Rmd. Please edit that file -->
auklet: Analysis and visualization of your eBird sightings
==========================================================

`auklet` provides tools for analyzing and visualizing your personal [eBird](http://ebird.org) data. Your personal sightings can be downloaded as a CSV file from the [Download My Data](http://ebird.org/ebird/downloadMyData) page on the eBird website.

Installation
------------

Install `auklet` from GitHub using:

``` r
# install.packages("devtools")
devtools::install_github("CornellLabofOrnithology/auk")
```

Usage
-----

All functions in `auklet` begin with `eb_` (for eBird) to aid tab completion. Import your eBird sightings data into a data frame with `eb_sightings()`:

``` r
library(auklet)
library(dplyr)
# load example data inclued with the package
ebird_data <- system.file("extdata/MyEBirdData.csv", package = "ebird") %>%
  eb_sightings()
ebird_data
#> # A tibble: 7,048 x 29
#>    submission_id taxon_order category species_code
#>            <chr>       <dbl>    <chr>        <chr>
#>  1     S18674562         214  species      wfwduc1
#>  2     S18586095         215  species       bbwduc
#>  3     S12725047         237  species       gwfgoo
#>  4      S9656769         237  species       gwfgoo
#>  5      S7828071         237  species       gwfgoo
#>  6     S28965809         237  species       gwfgoo
#>  7      S7828071         251 domestic      gragoo1
#>  8      S7828048         254  species       snogoo
#>  9      S7828071         254  species       snogoo
#> 10     S28961871         254  species       snogoo
#> # ... with 7,038 more rows, and 25 more variables: name_common <chr>,
#> #   name_scientific <chr>, order <chr>, family <chr>, report_as <chr>,
#> #   species_common <chr>, species_scientific <chr>, count <chr>,
#> #   state <chr>, province <chr>, county <chr>, location <chr>,
#> #   latitude <dbl>, longitude <dbl>, date <date>, time <time>,
#> #   protocol <chr>, duration <int>, all_obs_reported <lgl>,
#> #   distance_traveled <dbl>, area_covered <chr>,
#> #   number_of_observers <int>, breeding_code <chr>,
#> #   species_comments <chr>, checklist_comments <chr>
```

In addition to true, countable species, your eBird data includes other taxa that can't be resolved to the species level (e.g. "spuhs" such as *Empidonax sp.*) or aren't countable (e.g. domestic species). Other taxa in your data may be reported at a level below species (e.g. subspecies or recognizable forms). `eb_sightings()` contains additional fields to help in resolving these issues. `species_code`, `species_common`, and `species_scientific` are `NA` for taxa that aren't resolvable to countable species, and give the corresponding species for taxa reported below species.

Once your eBird data are imported, you can begin summarizing and visualizing them. For example, use `eb_daylist()` to creat daily life lists, i.e. a data frame of species seen on each day of the year.

``` r
day_lists <- eb_daylist(ebird_data)
# species seen on feb 14
filter(day_lists, month == 2, day == 14) %>% 
  select(month, day, species_common)
#> # A tibble: 10 x 3
#>    month   day           species_common
#>    <dbl> <int>                    <chr>
#>  1     2    14            Brown Pelican
#>  2     2    14        California Condor
#>  3     2    14     California Scrub-Jay
#>  4     2    14 Double-crested Cormorant
#>  5     2    14         Great Blue Heron
#>  6     2    14              Great Egret
#>  7     2    14          Red-tailed Hawk
#>  8     2    14           Turkey Vulture
#>  9     2    14         Western Bluebird
#> 10     2    14     White-throated Swift
```

These day lists can be summarized to daily counts with `summary()` or visualized with `plot()`.

``` r
summary(day_lists) %>% 
  head()
#> # A tibble: 6 x 3
#>   month   day     n
#>   <dbl> <int> <int>
#> 1     1     1    23
#> 2     1     2    33
#> 3     1     3     6
#> 4     1     4    12
#> 5     1     6    30
#> 6     1     7     1
plot(day_lists)
```

<img src="README-summ-plot-1.png" style="display: block; margin: auto;" />
