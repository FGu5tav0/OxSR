
#' Title
#'
#' @param data A data.frame containing the wavelength and reflectance values obtained from the Cary 5000 UV-Vis-IR spectrophotometers. It should be obtained directly from the export of a CSV file.
#' @param prefix Indicates the prefix defined for columns with no name.
#' @param name_wave Indicates the default name of the wavelength column.
#' @param range_wave Is the wavelength range used. The default is from 380 nm to 2500 nm.
#'
#' @returns  The function returns a data.frame with the columns organized, removing duplicate columns and placing the wavelength column in the first position of the data.frame.
#'
#' @export
#'
#' @examples
#'
clean_sheet_cary <- function(data = data,
                             prefix = NULL,
                             name_wave = "Wave",
                             range_wave = c(380,2500)) {

  # Data input
  if(missing(data)) {
    stop("The parameter `data` are required.")
  }

  # Data must be data.frame
  if(!is.data.frame(data)) {
    stop("The `data` parameter must be a `data.frame`.")
  }

  # Data input
  if(missing(prefix)) {
    stop("The parameter `prefix` are required.")
  }

  filtro_x <- startsWith(x = colnames(data), prefix)

  col_x <- colnames(data)[filtro_x]
  col_nx <- colnames(data)[!filtro_x]

  if (length(col_x) > length(col_nx)) {
    col_nx <- c(col_nx, "empty")
  } else if (length(col_x) < length(col_nx)) {
    col_x <- c(col_x, "empty")
  }

  line_1 <- data[1, ]

  for (i in 1:length(data)) {
    for (j in 1:length(col_nx)) {
      if (colnames(data)[i] == col_x[j]) {
        colnames(data)[i] <- col_nx[j]
      } else if (colnames(data)[i] == col_nx[j]) {
        colnames(data)[i] <- line_1[1, i]
      }
    }
  }

  data <- data[-1, ]

  colunas_para_manter <- grepl(pattern =  paste0("^", name_wave, ""),
                               ignore.case = T,
                               names(data)
  )

  if (all(!colunas_para_manter)) {
    stop(" \033[31m Attention! The column with the specified wavelength was not found.")
  }

  for (i in 1:length(data)) {
    data[[i]] <- as.numeric(data[[i]])
  }

  for (i in which(colunas_para_manter)) {

    menos <- which(data[[i]] == range_wave[1])
    mais <- which(data[[i]] == range_wave[2])

    valor_menos <- data[menos,i] |> as.numeric()
    valor_mais <- data[mais,i] |> as.numeric()

    if(!is.na(valor_menos) && valor_menos == range_wave[1] & !is.na(valor_mais) && valor_mais == range_wave[2]) {

      colunas_para_manter[i] <- F

      break
    }

  }

  if(is.na(valor_menos) && valor_menos != range_wave[1] & is.na(valor_mais) && valor_mais != range_wave[2]){
    stop("The `data` does not have the specified limits!")
  }

  df_unique <- data[, !colunas_para_manter]

  col_index <- grep(paste0("^", name_wave), names(df_unique))

  df_unique <- df_unique[, c(col_index,
                                setdiff(seq_along(df_unique),
                                        col_index))]

  menos <- which(df_unique[[1]] == range_wave[1])
  mais <- which(df_unique[[1]] == range_wave[2])

  if (menos == 1 ) {
    df_unique <- df_unique[1:mais, ]
  } else if (mais == 1) {
    df_unique <- df_unique[1:menos, ]
  } else {
    stop("The parameter `data` are required.")
  }

  for (i in 1:length(df_unique)) {
    na_ok <- sum(is.na(df_unique[[i]]))

    if (na_ok >= 1) {

      cat(paste(
        "\033[32m", "Attention! The column",
        "\033[31m", names(df_unique)[i], "\033[32m",
        "contains", "\033[31m", na_ok, "\033[32m",
        "missing values!\n\n", "\033[0m", sep = " "
      ))
      cat("---")
      cat("\n")
    }
  }

  return(df_unique)
}






