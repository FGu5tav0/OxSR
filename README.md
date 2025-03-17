
# Overview  <a href="https://fgu5tav0.github.io/OxSR"><img src="man/figures/logo.png" align="right" height="139" alt="OxSR website" /></a>

<!-- badges: start -->
![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/OxSR)&nbsp; 
![CRAN Downloads](https://cranlogs.r-pkg.org/badges/grand-total/OxSR)&nbsp;
![License](https://img.shields.io/badge/license-GPL--3-gold)&nbsp; 
<!-- badges: end -->

The OxSR package calculates the ratio between hematite and goethite oxides in soil via diffuse reflectance.

In soil science, understanding the mineral composition is often a starting point for research in various areas.

Iron oxides are widely studied and play a role in a range of studies, from fertilization and nutrient dynamics to contamination and sustainable practices.

Techniques for determining these minerals are often expensive and time-consuming. Therefore, practical, rapid, and sensitive methods such as diffuse reflectance in the visible spectrum have gained importance. This technique can also be used to determine soil color, another parameter that helps in understanding the environment.

## Installation

``` {r, eval = FALSE}
install.packages("OxSR")
```

``` {r}
library(OxSR)
```

## Example

## Function: `relation_hm_gt()`

```{r  fig.width=6, fig.height=4, dpi=600}

# database
data("soil_refle")

# one sample
dados_relacao <- relation_hm_gt(data = soil_refle[,c(1,2)], 
               plot = T,
               name_wave = "wave",
               points_smoothing = 0.3, 
               pv_tolerance = c(1,1,1,1),
               hm_gt_limits = list(hm = c(535, 585),
                                   gt = c(430, 470)))

# with several samples
soil_refle |> 
relation_hm_gt() |> 
  dplyr::mutate(dplyr::across(2:7, ~ format(., scientific = TRUE, digits = 3))) |>
  gt::gt()

```
