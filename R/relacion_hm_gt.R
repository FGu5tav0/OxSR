

#' Title
#'
#' @param data
#' @param smoothing_method
#' @param points_smoothing
#' @param hem_go_limits
#' @param peak_detect
#' @param pv_tolerance
#' @param name_wave
#' @param plot
#' @param model_regression
#'
#' @returns
#' @export
#'
#' @examples
relation_hm_gt <- function(data = data,
                            smoothing_method = "cubic_spline",
                            points_smoothing = 0.3,
                            hem_go_limits = list(hem = c(535,585),
                                                 gt = c(430,460)),
                            peak_detect = "range",
                            pv_tolerance = 10,
                            name_wave = "wave",
                            plot = TRUE,
                            model_regression = "Vidal"
                           ){

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

  # Kubelka-Munk transformation
  df_km <- data |> dplyr::mutate(across(
    .cols = -dplyr::starts_with("wave"),
    .fns = ~ (1 - . / 100)^2 / (2 * . / 100)
  ))


  # smoothing end second derivative
  if(smoothing_method == "cubic_spline"){

    df_cub_deriv <- df_km |>
      tidyr::pivot_longer(
        cols = !dplyr::starts_with("wave"),
        names_to = "variaveis",
        values_to = "valores"
      ) |>
      dplyr::group_by(variaveis) |>
      tidyr::nest() |>
      dplyr::mutate(
        model = purrr::map(
          data,
          ~ smooth.spline(
            x = .x$wavelength,
            y = .x$valores,
            spar = points_smoothing
          )
        ),
        secund_deriva = purrr::map2(
          data, model,
          ~ predict(.y,
                    x = .x$wavelength,
                    deriv = 2
          )
        )
      ) |>
      # Process of removing the nested list.
      dplyr::mutate(
        deriv_data = purrr::map(secund_deriva,
                                ~ tibble::tibble(x = .x$x, y = .x$y))
      ) |>
      dplyr::select(variaveis, deriv_data) |>
      tidyr::unnest(deriv_data)


  } else if(smoothing_method == "savitzky_golay"){

    df_cub_deriv <- df_km |>
      tidyr::pivot_longer(
        cols = !dplyr::starts_with("wave"),
        names_to = "variaveis",
        values_to = "valores"
      ) |>
      dplyr::group_by(variaveis) |>
      tidyr::nest() |>
      dplyr::mutate(
        model = purrr::map(
          data, ~ signal::sgolayfilt(.x$valores,
                                     # p = 3,
                                     n = 111, m = 2)
        ),
        data_with_model = purrr::map2(
          data, model, ~ dplyr::mutate(.x, model = .y)
        )
      ) |>
      dplyr::select(variaveis, data_with_model) |>
      tidyr::unnest(data_with_model) |>
      dplyr::rename(
        x = wavelength,
        y = model
      )

  } else {
    stop("The parameter `smoothing_method`was not found.")
  }

  if(peak_detect == "range"){

    df_wider_cub_deriv <- df_cub_deriv |> tidyr::pivot_wider(names_from = variaveis,
                                       values_from = y)

    result_list <- list()

    for (i in 2:length(df_wider_cub_deriv)) {
      min_gt <- min(df_wider_cub_deriv[df_wider_cub_deriv$x >= 415 & df_wider_cub_deriv$x <= 425, i], na.rm = TRUE)
      max_gt <- max(df_wider_cub_deriv[df_wider_cub_deriv$x >= 440 & df_wider_cub_deriv$x <= 450, i], na.rm = TRUE)
      min_hm <- min(df_wider_cub_deriv[df_wider_cub_deriv$x >= 530 & df_wider_cub_deriv$x <= 545, i], na.rm = TRUE)
      max_hm <- max(df_wider_cub_deriv[df_wider_cub_deriv$x >= 575 & df_wider_cub_deriv$x <= 590, i], na.rm = TRUE)

      result_list[[i - 1]] <- data.frame(samples = colnames(df_wider_cub_deriv)[i],min_gt, max_gt, min_hm, max_hm)
    }

    base_ <- do.call(rbind, result_list)

    base_$range_gt <- abs(base_$min_gt - base_$max_gt)
    base_$range_hm <- abs(base_$min_hm - base_$max_hm)

    base_$y2_y2y2 <- base_$range_hm/(base_$range_hm + base_$range_gt)

  } else if(peak_detect == "change_direction"){

    # peak and valley automatic
    posi_picos_vales <- df_cub_deriv |>
      dplyr::filter(x <= 600) |>
      tidyr::nest() |>
      dplyr::mutate(posi_vales = purrr::map(
        data,
        ~ quantmod::findValleys(.x$y) |> as.data.frame()
      ),
      posi_picos = purrr::map(
        data,
        ~ quantmod::findPeaks(.x$y) |> as.data.frame()
      )
      ) |>
      dplyr::select(variaveis, posi_picos, posi_vales) |>
      dplyr::rowwise() |>
      tidyr::unnest(posi_picos) |>
      tidyr::unnest(posi_vales) |>
      tidyr::pivot_longer(cols = starts_with("quant"), names_to = "var2",
                          values_to = "posicao") |>
      dplyr::mutate(var2 = stringr::str_replace(var2, ".*Pea.*", "pico"),
                    var2 = stringr::str_replace(var2, ".*Valley.*", "vale")) |>
      as.data.frame() |>
      dplyr::group_by(variaveis, var2) |>
      dplyr::distinct(posicao)

    # adição de coluna com a posião no banco processado com 2ª deriv
    df_teste_posi <- df_cub_deriv |>
      dplyr::filter(x <= 600) |>
      dplyr::mutate(posicao = dplyr::row_number(),
                    posicao = as.numeric(posicao)) |>
      as.data.frame()

    # obtendo apenas os picos
    final_picos <- df_teste_posi |>
      dplyr::semi_join(posi_picos_vales |>
                         dplyr::filter(var2 == "pico"),
                       by = dplyr::join_by(variaveis, posicao))

    # obtendo apenas os vales
    final_vales <- df_teste_posi |>
      dplyr::semi_join(posi_picos_vales |>
                         dplyr::filter(var2 == "vale"),
                       by = dplyr::join_by(variaveis, posicao))

    media_limites <- rect_data |>
      dplyr::group_by(mineral) |>
      dplyr::summarise(media = mean(c(xmin,xmax)))

    # picos
    picos_gt_hm <- final_picos |>
      dplyr::mutate(dif_gt = abs(x- as.numeric(media_limites[1,2])),
                    dif_hm = abs(x- as.numeric(media_limites[2,2])))

    gt_p <- picos_gt_hm |> dplyr::group_by(variaveis) |>
      dplyr::slice_min(dif_gt, n = 1, with_ties = TRUE) |>
      dplyr::rename(pico_goe = y ) |>
      dplyr::select(-dif_hm) |>
      dplyr::mutate(erro_p_gt = dplyr::if_else(dif_gt > pv_tolerance, "peak Gt", NA))

    hm_p <- picos_gt_hm |> dplyr::group_by(variaveis) |>
      dplyr::slice_min(dif_hm, n = 1, with_ties = TRUE) |>
      dplyr::rename(pico_hem = y ) |>
      dplyr::select(-dif_gt)|>
      dplyr::mutate(erro_p_hm = dplyr::if_else(dif_hm > pv_tolerance, "peak Hm", NA))

    # vales
    vales_gt_hm <- final_vales |>
      dplyr::mutate(dif_gt = abs(x - as.numeric(media_limites[1,2])),
                    dif_hm = abs(x - as.numeric(media_limites[2,2])))

    gt_v <- vales_gt_hm |> dplyr::group_by(variaveis) |>
      dplyr::slice_min(dif_gt, n = 1, with_ties = TRUE) |>
      dplyr::rename(vale_goe = y )|>
      dplyr::select(-dif_hm)|>
      dplyr::mutate(erro_v_gt = dplyr::if_else(dif_gt > pv_tolerance, "valley Gt", NA))

    hm_v <- vales_gt_hm |> dplyr::group_by(variaveis) |>
      dplyr::slice_min(dif_hm, n = 1, with_ties = TRUE) |>
      dplyr::rename(vale_hem = y ) |>
      dplyr::select(-dif_gt)|>
      dplyr::mutate(erro_v_hm = dplyr::if_else(dif_hm > pv_tolerance, "valley Hm", NA))

    # amplitutes --------------------------------------------------------------

    goethita <-
      dplyr::full_join(gt_p, gt_v, by = "variaveis") |>
      dplyr::mutate(amplitude_goe = pico_goe-vale_goe)

    hematita <-
      dplyr::full_join(hm_p,hm_v, by = "variaveis") |>
      dplyr::mutate(amplitude_hm = pico_hem-vale_hem)



    base_ <- dplyr::full_join(goethita, hematita, by = "variaveis") |>
      dplyr::mutate(y2_y2y2 =  amplitude_hm/(amplitude_hm + amplitude_goe))

  }else {
    stop("The parameter `smoothing_method`was not found.")
  }

  # Plot - peak and valley
  df_cub_deriv$variaveis <- factor(df_cub_deriv$variaveis)

  if (plot == TRUE) {

    # Rectangles of the minerals in the graph.
    rect_data <- data.frame(
      mineral = c("Hm","Gt"),
      xmin = c(hem_go_limits[[1]][1], hem_go_limits[[2]][1]),
      xmax = c(hem_go_limits[[1]][2], hem_go_limits[[2]][2]),
      ymin = c(-Inf, -Inf),
      ymax = c(+Inf, +Inf)
    )

    for (i in levels(df_cub_deriv$variaveis)) {
      df_split <-  df_cub_deriv[df_cub_deriv$variaveis == i,]

      p1 <- ggplot2::ggplot(data = df_split,
                            ggplot2::aes(x = x, y = y)) +
        ggplot2::ggtitle(paste("Sample: ", i)) +
        ggplot2::geom_line() +
        ggplot2::geom_hline(yintercept = 0, col = "gray70", alpha = .9) +
        ggplot2::geom_line(linewidth = .6) +
        ggpmisc::stat_valleys(colour = "blue", span = 10) +
        ggpmisc::stat_valleys(
          geom = "text", ggplot2::aes(label = ifelse(..x.. > 600, NA, ..x.label..)),
          col = "blue", span = 10, vjust = .5, hjust = -.1,
          y.label.fmt = "%0.0e", angle = 0
        ) +
        ggpmisc::stat_peaks(col = "red", span = 10) +
        ggpmisc::stat_peaks(
          geom = "text", ggplot2::aes(label = ifelse(..x.. > 600, NA, ..x.label..)),
          col = "red", span = 10, vjust = 0.1, hjust = -0.1,
          y.label.fmt = "%0.0e", angle = 0
        ) +
        ggplot2::annotate(
          geom = "rect", xmin = rect_data$xmin, xmax = rect_data$xmax,
          ymin = rect_data$ymin, ymax = rect_data$ymax,
          fill = "gold", alpha = 0.2, color = "transparent"
        ) +
        ggplot2::geom_text(data = rect_data,
                           ggplot2::aes(x = (xmin+xmax)/2,
                                        y = Inf, label = mineral),
                           vjust = 1.2,
                           inherit.aes = FALSE
        ) +
        ggplot2::scale_x_continuous(name = "Wavelength (nm)",
          expand = ggplot2::expansion(
            mult = c(0.01, 0),
            add = c(0, 0)
          ),
          limits = c(380, 1000)
        ) +
        ggplot2::scale_y_continuous(name = NULL,
          expand = ggplot2::expansion(
          mult = c(0.1, 0.1),
          add = c(0, 0.0001)
        )) +
        ggplot2::coord_cartesian(clip = "off") +
        ggplot2::theme_bw()

      print(p1)
    }
  }

  # Regression models!
  if(model_regression == "Vidal"){
    base_$relation_hm_gt <- round((-0.068 + (1.325 * base_$y2_y2y2)), digits = 4)
  } else if(model_regression == "Outro"){

  }



  # if (detail == FALSE) {
  #
  #   base_ <- base_ |> df
  #
  #
  # }


  # base_ <- dplyr::full_join(goethita, hematita, by = "variaveis") |>
  #   dplyr::mutate(y2_y2y2 =  amplitude_hm/(amplitude_hm + amplitude_goe),
  #          relacao_hm_gt = (-0.068 + (1.325 * y2_y2y2)),
  #          relacao_hm_gt = dplyr::case_when(
  #            relacao_hm_gt <= 0 ~ 0,
  #            erro_p_gt == "atencao" ~ 0,
  #            erro_p_hm == "atencao" ~ 0,
  #            erro_v_gt == "atencao" ~ 0,
  #            erro_v_hm == "atencao" ~ 0,
  #            .default = relacao_hm_gt
  #          ),
  #          relacao_hm_gt = relacao_hm_gt |> round(4)) |>
  #   dplyr::select(variaveis, relacao_hm_gt,
  #                 pico_goe, erro_p_gt,
  #                 vale_goe, erro_v_gt,
  #                 pico_hem, erro_p_hm,
  #                 vale_hem, erro_v_hm)

    return(base_)
  }




