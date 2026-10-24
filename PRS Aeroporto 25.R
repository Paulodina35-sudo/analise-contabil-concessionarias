library(readxl)
library(dplyr)

arquivo <- "Coleta de dados/PRS Aeroporto/Planilha_aeroportos_PRS.xlsx"

dados <- read_excel(arquivo)

dados <- dados %>%
  rename(
    indicador_original = `MEDIDAS FINANCEIRAS`
  )

dados <- dados %>%
  mutate(
    variacao = `2025` - `2024`
  )

dados <- dados %>%
  mutate(
    variacao_percentual = (`2025` - `2024`) / `2024` * 100
  )

dados <- dados %>%
  mutate(
    variacao_percentual = round(variacao_percentual, 2)
  )

dados <- dados %>%
  mutate(
    variacao_percentual = ifelse(
      is.nan(variacao_percentual),
      NA,
      variacao_percentual
    )
  )

dados <- dados %>%
  mutate(
    indicador_original = recode(
      indicador_original,
      "Intagível" = "Intangível"
    )
  )

library(writexl)

write_xlsx(
  dados,
  "Coleta de dados/PRS Aeroporto/Planilha_aeroportos_PRS_padronizado.xlsx"
)
