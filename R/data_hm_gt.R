

# dados de refletância de exemplo -----------------------------------------

soil_refle <- readxl::read_excel(path = "1ª serie 001-026.xls") |>
  janitor::clean_names()

usethis::use_data(soil_refle, internal = F)

# dados de cor de exemplo -------------------------------------------------


