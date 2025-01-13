library(hexSticker)
library(ggplot2)
library(ggspectra)

# writexl::write_xlsx(x = df_secund_deriva,path = "F:/OneDrive/Área de Trabalho/hex_rehemgo.xlsx")

df_secund_deriva <- readxl::read_excel("F:/OneDrive/Área de Trabalho/hex_rehemgo.xlsx")

limite_inf_gt <- 410
limite_sup_gt <- 460
limite_inf_hm <- 525
limite_sup_hm <- 590

rect_data <- data.frame(
  mineral = c("GT", "HM"),
  xmin = c(410, 525),
  xmax = c(460, 590),
  ymin = c(-Inf, -Inf),
  ymax = c(+Inf, +Inf)
)

df_secund_deriva |>
  filter(variaveis == "rfb10") |> 
  mutate(y = case_when(
    x > 640 ~ 0,
    .default = y
  )) |> 
  ggplot(aes(x = x, y = y)) +
  geom_hline(yintercept = 0, col = "gray70", alpha = .9) +
  annotate(
    geom = "rect", xmin = rect_data$xmin,
    xmax = rect_data$xmax,
    ymin = rect_data$ymin, ymax = rect_data$ymax,
    fill = c("gold","firebrick"), alpha = 0.6, color = "transparent"
  ) +
  # geom_line(linewidth = .65, col = "white") +
  geom_line(linewidth = .6) +
  # ggpmisc::stat_valleys(colour = "blue", span = 10) +
  # ggpmisc::stat_valleys(
  #   geom = "text", aes(label = ifelse(..x.. > 600, NA, ..x.label..)),
  #   col = "blue", span = 10, vjust = .5, hjust = -.1,
  #   y.label.fmt = "%0.0e", angle = 0
  # ) +
  # ggpmisc::stat_peaks(col = "red", span = 10) +
  # ggpmisc::stat_peaks(
  #   geom = "text", aes(label = ifelse(..x.. > 600, NA, ..x.label..)),
  #   col = "red", span = 10, vjust = 0.1, hjust = -0.1,
  #   y.label.fmt = "%0.0e", angle = 0
  # ) +
  scale_x_continuous(
    expand = expansion(
      mult = c(0.01, 0),
      add = c(0, 0)
    ),
    limits = c(380, 1200)
  ) +
  scale_y_continuous(expand = expansion(
    mult = c(0.1, 0.1),
    add = c(0, 0.0001)
  )) +
  coord_cartesian(clip = "off") +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank()) +
  theme_void() +
  ggimage::theme_transparent() -> p

library(showtext)
## Loading Google fonts (http://www.google.com/fonts)
font_add_google("Oswald", "bell")
## Automatically use showtext to render text for future devices
showtext_auto()

sticker(p, 
        s_x=1, s_y=.99, s_width=1.4, s_height=1,
        package="OxSR",
        p_size=40, 
        p_y = 1.025,
        p_x = 1.25,
        p_color = "black",
        p_family = "bell",
        h_fill = "#bd9674",
        h_color = "#9d7857",
        filename="ggplot2.png", dpi = 600) |> print()






