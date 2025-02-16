#' Organize Cary data
#' @description
#' Cleans the raw data extracted from the Cary 5000 UV-Vis-IR spectrophotometer, ensuring an organized dataset for analysis. During the process, duplicate columns containing `wavelength` are removed to avoid redundancy. Samples with missing data are also eliminated, ensuring that only complete measurements are retained. Additionally, the columns are reordered based on the sample names, making it easier to interpret and manipulate the data. The `wavelength` column is placed as the first column, followed by the sample columns.
#'
#' @param data A data.frame containing the wavelength and reflectance values. It should be obtained directly from the export of a CSV file.
#' @param prefix Indicates the prefix for columns where there is no sample. It is usually predefined as `x` or `.`.
#' @param name_wave Indicates the name of the wavelength column. The default is 'wave'.
#' @param range_wave Is the wavelength range used. The default is from 380 nm to 2500 nm.
#'
#' @returns The function returns an organized `data.frame`
#'
#' @examples
#' # example code
#' library(OxSR)
#' data(data_cary)
#'
#' clean_sheet_cary(data_cary, prefix = "x")
#'
#' # With pipe
#'
#' data_cary |> clean_sheet_cary(prefix = "x")
#'
#' @export
#' @importFrom janitor clean_names
#'
clean_sheet_cary <- function(data = data,
                             prefix = NULL,
                             name_wave = "Wave",
                             range_wave = c(380, 2500)) {
  # Data input
  if (missing(data)) {
    stop("The parameter `data` are required.")
  }

  # Data must be data.frame
  if (!is.data.frame(data)) {
    stop("The `data` parameter must be a `data.frame`.")
  }

  # Data input
  if (missing(prefix)) {
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

  colunas_para_manter <- grepl(
    pattern = paste0("^", name_wave, ""),
    ignore.case = T,
    names(data)
  )

  if (all(!colunas_para_manter)) {
    stop("\033[31m Attention! The column with the wavelength was not found.")
  }

  for (i in 1:length(data)) {
    data[[i]] <- as.numeric(data[[i]])
  }

  for (i in which(colunas_para_manter)) {
    menos <- which(data[[i]] == range_wave[1])
    mais <- which(data[[i]] == range_wave[2])

    valor_menos <- data[menos, i] |> as.numeric()
    valor_mais <- data[mais, i] |> as.numeric()

    if (!is.na(valor_menos) && valor_menos == range_wave[1] & !is.na(valor_mais) && valor_mais == range_wave[2]) {
      colunas_para_manter[i] <- F

      break
    }
  }

  if (is.na(valor_menos) && valor_menos != range_wave[1] & is.na(valor_mais) && valor_mais != range_wave[2]) {
    stop("The `data` does not have the specified limits!")
  }

  df_unique <- data[, !colunas_para_manter]

  col_index <- grep(paste0("^", name_wave), names(df_unique))

  df_unique <- df_unique[, c(
    col_index,
    setdiff(
      seq_along(df_unique),
      col_index
    )
  )]

  menos <- which(df_unique[[1]] == range_wave[1])
  mais <- which(df_unique[[1]] == range_wave[2])

  if (menos == 1) {
    df_unique <- df_unique[1:mais, ]
  } else if (mais == 1) {
    df_unique <- df_unique[1:menos, ]
  } else {
    stop("The parameter `data` are required.")
  }

  sum_na <- colSums(is.na(df_unique))

  df_unique <- df_unique[, sum_na == 0]
  df_unique <- janitor::clean_names(dat = df_unique)

  for (i in 1:length(sum_na)) {

    if (sum_na[i] >= 1) {
      cat(paste0(
        "\033[32m", "The column ",
        "\033[31m", names(sum_na)[i], "\033[32m",
        " contains ", "\033[31m", sum_na[i], "\033[32m",
        " missing values and was removed!\n\n", "\033[0m",
        sep = ""
      ))
      cat("---")
      cat("\n")
    }
  }

  return(df_unique)
}
