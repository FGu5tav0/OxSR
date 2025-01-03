
df <- data.frame(a = 1,
                 a = 2)
nomes <- names(df) |> startsWith("a")
duplicated(nomes)




relation_hm_gt <- function(data = data,
                            smoothing_method = "cubic_spline",
                            points_smoothing = 0.3,
                            hem_go_limits = list(hem = c(535,585),
                                                 gt = c(430,460)),
                            pv_tolerance = 10,
                            model_conversion = "Barrón, 2002"
                           ){

  # Data input
  if (missing(data)) {
    stop("The parameter `data` are required.")
  }
  # Data must be data.frame
  if (!is.data.frame(data)) {
    stop("The `data` parameter must be a `data.frame`.")
  }

  # Wave coluns




}

relation_hm_gt()
