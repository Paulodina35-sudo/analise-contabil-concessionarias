# PRS_Aeroporto_25.R
# PRS Aeroportos S.A. - 2025 vs 2024 (valores em R$ mil).
# Rode com o diretório de trabalho na raiz do projeto (ex.: projeto do RStudio).

source("funcoes_padronizacao.R")

padronizar_planilha(
  entrada = "Coleta de dados/PRS Aeroporto/Planilha_aeroportos_PRS.xlsx",
  saida   = "Coleta de dados/PRS Aeroporto/Planilha_aeroportos_PRS_padronizado.xlsx"
)
