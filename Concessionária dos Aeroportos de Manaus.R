library(readxl)
library(dplyr)
library(writexl)

arquivo <- "C:/Users/Admin/OneDrive/Documentos/Coleta de dados/Aeroporto de Manaus/planilha_concessionaria_padronizada.xlsx"

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

write_xlsx(
  dados,
  "C:/Users/Admin/OneDrive/Documentos/Coleta de dados/Aeroporto de Manaus/planilha_concessionaria_padronizada.xlsx"
)

