# Concessionaria_dos_Aeroportos_de_Manaus.R
# Concessionária dos Aeroportos da Amazônia S.A. - 2024 vs 2023 (valores em R$ mil).
# ATENÇÃO: a planilha desta concessionária traz 2024 e 2023 (e não 2025 e 2024),
# pois a demonstração de origem é a de 31/12/2024. A função detecta os anos sozinha.
# Use nomes de arquivo sem acento (evita erro de leitura no Windows). Ajuste o nome
# da planilha abaixo se o seu arquivo tiver outro nome.
# Rode com o diretório de trabalho na raiz do projeto (ex.: projeto do RStudio).

source("funcoes_padronizacao.R")

padronizar_planilha(
  entrada = "Coleta de dados/Aeroporto de Manaus/planilha_preenchida_Concessionaria_dos_Aeroportos.xlsx",
  saida   = "Coleta de dados/Aeroporto de Manaus/planilha_concessionaria_padronizada.xlsx"
)
