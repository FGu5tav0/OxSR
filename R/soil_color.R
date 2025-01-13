

#' Title
#'
#' @param data
#' @param name_wave
#' @param tri_values
#'
#' @returns
#' @export
#'
#' @examples
soil_color <- function(data = data,
                       name_wave = "wave",
                       tri_values = "std"){

  # Data input
  if(missing(data)) {
    stop("The parameter `data` are required.")
  }

  # Data must be data.frame
  if(!is.data.frame(data)) {
    stop("The `data` parameter must be a `data.frame`.")
  }
  # NA data
  if(any(is.na(data))) {
    data <- data |> na.omit()
  }

  # Wave columns
  colunas <- grep(
    pattern = paste0("^", name_wave, ""),
    ignore.case = T,
    names(data), value = TRUE
  )

  if(length(colunas) == 0){
    stop("The `data` does not contain the ´wavelength´ column.")
  }

  if(length(colunas) > 1){
    data <- data |>
      dplyr::select(-colunas[-1]) |>
      dplyr::rename("wavelength" = colunas[1])
  }

  if (tri_values == "std") {

    df_2filter <- data |>
      dplyr::filter(wavelength %in% tristimulusEX$wave) |>
      dplyr::arrange(wavelength)

    result_list <- list()

    for (i in 2:length(df_2filter)) {

      x1 <- sum(df_2filter[[i]] * tristimulusEX$x) / sum(tristimulusEX$x)
      y1 <- sum(df_2filter[[i]] * tristimulusEX$y) / sum(tristimulusEX$y)
      z1 <- sum(df_2filter[[i]] * tristimulusEX$z) / sum(tristimulusEX$z)

      result_list[[i - 1]] <- data.frame(samples = colnames(df_2filter)[i],x1,y1,z1)
    }

    base_ <- do.call(rbind, result_list)



  } else if(tri_values == "user"){

  }

  # munsel
  dfmun <- list()
  for (i in 1:dim(base_)[1]) {
    mun <- munsellinterpol::XYZtoMunsell(c(base_$x1[i] |> as.numeric(),
                                           base_$y1[i] |> as.numeric(),
                                           base_$z1[i] |> as.numeric()))
    dfmun[[i]] <- data.frame(sample = base_$samples[i],mun)
  }

  munsel_soil <- do.call(rbind, dfmun)
  munsel_soil$munsell <- row.names(munsel_soil)
  row.names(munsel_soil) <- NULL
  munsel_soil <- munsel_soil |>
    dplyr::relocate(munsell, .after = sample)

  rgb_munsellinte <- munsellinterpol::MunsellToRGB(MunsellSpec = munsel_soil$munsell)$RGB |> as.data.frame()
  rgb_munsellinte$munsell <- row.names(rgb_munsellinte)
  row.names(rgb_munsellinte) <- NULL
  rgb_para_plot <- cbind(sample = base_$samples, rgb_munsellinte)

  hex <- c()
  for (i in 1:length(row.names(rgb_para_plot))) {
    hex_code <- rgb(rgb_para_plot$R[i],
                    rgb_para_plot$G[i],
                    rgb_para_plot$B[i],
                    maxColorValue = 255)
    hex[i] <- hex_code
    # munsell::plot_hex(hex.colour = hex_code) |> print()
  }


  rgb_para_plot$hex <- hex

  graph_hex <- data.frame(x = rep(1,length(hex)),
                          y = rep(1,length(hex)),
                          sample = base_$samples,
                          color = hex)


  p1 <- graph_hex |>
    ggplot() +
    aes(x,y) +
    facet_wrap(~sample) +
    geom_rect(mapping = aes(fill = color,
                            xmin = 0, xmax = 1,
                            ymin = 0, ymax = 1)) +
    scale_fill_identity() +
    theme_minimal() +
    theme(axis.title = element_blank(),
          axis.text = element_blank(),
          axis.ticks = element_blank())
  print(p1)

  return(rgb_para_plot)

}


