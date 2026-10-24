library(readxl)
  
arquivo <- "Coleta de dados/Aeroporto Rio Janeiro 2025.xlsx"

dados <- read_excel(arquivo)

library(dplyr)

dados <- dados %>%
  rename(
    indicador_original = `MEDIDAS FINANCEIRAS`
  )

str(dados)

dados <- dados %>%
  mutate(
    variacao = `2025` - `2024`
  )
dados <- dados %>%
  mutate(
    variacao_percentual = (`2025` - `2024`) / `2024` * 100
  )

colSums(is.na(dados))

dados <- dados %>%
  mutate(
    variacao_percentual = (`2025` - `2024`) / `2024` * 100
  )

dados <- dados %>%
  mutate(
    indicador_original = recode(
      indicador_original,
      "Intagível" = "Intangível"
    )
  )  

dados <- dados %>%
  mutate(
    variacao_percentual = round(variacao_percentual, 2)
  )
install.packages("writexl")
library(writexl)

write_xlsx(
  dados,
  "Coleta de dados/Aeroporto Rio Janeiro 2025_padronizado.xlsx"
)
