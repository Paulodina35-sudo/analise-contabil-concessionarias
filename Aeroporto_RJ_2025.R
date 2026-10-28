# Aeroporto_RJ_2025.R
# Concessionária Aeroporto Rio de Janeiro S.A. - 2025 vs 2024 (valores em R$ mil).
# Rode com o diretório de trabalho na raiz do projeto (ex.: projeto do RStudio).

source("funcoes_padronizacao.R")

padronizar_planilha(
  entrada = "Coleta de dados/Aeroporto Rio Janeiro 2025.xlsx",
  saida   = "Coleta de dados/Aeroporto Rio Janeiro 2025_padronizado.xlsx"
)
