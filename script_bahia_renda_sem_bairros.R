# Script para gerar mapas de Renda Média por Setor Censitário
# 20 maiores municípios da Bahia
# Usando o pacote cnefetools e mapview para visualização interativa

library(cnefetools)
library(dplyr)
library(geobr)
library(mapview)
library(leafpop)
library(htmlwidgets)

cat("=======================================================\n")
cat("MAPAS DE RENDA - 20 MAIORES MUNICÍPIOS DA BAHIA\n")
cat("=======================================================\n\n")

# 1. Lista dos 20 maiores municípios da Bahia
municipios_maiores <- data.frame(
  name_muni = c(
    "Salvador",
    "Feira de Santana",
    "Vitoria da Conquista",
    "Camaçari",
    "Juazeiro",
    "Itabuna",
    "Lauro de Freitas",
    "Ilheus",
    "Jequie",
    "Teixeira de Freitas",
    "Barreiras",
    "Alagoinhas",
    "Porto Seguro",
    "Simoes Filho",
    "Paulo Afonso",
    "Eunapolis",
    "Santo Antonio de Jesus",
    "Luis Eduardo Magalhaes",
    "Valença",
    "Guanambi"
  ),
  stringsAsFactors = FALSE
)

cat("Municípios a processar:\n")
print(municipios_maiores)
cat("\n")

# 2. Obter códigos IBGE dos municípios
cat("Obtendo códigos IBGE...\n")
municipios_maiores$code_muni <- sapply(municipios_maiores$name_muni, function(nome) {
  resultado <- lookup_muni(name_muni = nome)
  if (!is.null(resultado) && nrow(resultado) > 0) {
    # Filtrar por estado Bahia se houver múltiplos resultados
    resultado_ba <- resultado[resultado$abbrev_state == "BA", ]
    if (nrow(resultado_ba) > 0) {
      return(resultado_ba$code_muni[1])
    }
  }
  return(NA)
})

# Remover municípios não encontrados
municipios_maiores <- municipios_maiores |>
  filter(!is.na(code_muni))

cat(sprintf("\nMunicípios encontrados: %d\n\n", nrow(municipios_maiores)))

# 3. Criar pasta para os mapas se não existir
if (!dir.exists("docs")) {
  dir.create("docs")
}
if (!dir.exists("docs/mapas")) {
  dir.create("docs/mapas")
}
if (!dir.exists("docs/mapas/sem_bairros")) {
  dir.create("docs/mapas/sem_bairros")
}

# 4. Função para criar popup customizado
criar_popup_renda_setor <- function(data) {
  popup_html <- sprintf(
    "<b>Setor Censitário:</b> %s<br/>
     <b>Renda Média (R$):</b> %s<br/>
     <b>População:</b> %s pessoas<br/>
     <hr>
     <small>Município: %s</small>",
    data$code_tract,
    format(round(data$avg_inc_resp), big.mark = ".", decimal.mark = ","),
    format(round(data$pop_ph), big.mark = ".", decimal.mark = ","),
    data$name_muni
  )
  return(popup_html)
}

# 5. Função para processar um município
processar_municipio <- function(code_muni, name_muni) {
  cat(sprintf("\n--- Processando: %s ---\n", name_muni))
  
  tryCatch({
    # Ler setores censitários do município
    cat("  Carregando setores censitários...\n")
    setores <- read_census_tract(code_tract = code_muni, year = 2022, simplified = FALSE)
    
    cat(sprintf("  Setores encontrados: %d\n", nrow(setores)))
    
    # Interpolar dados de renda média e população
    cat("  Interpolando dados...\n")
    setores_int <- tracts_to_polygon(
      code_muni = code_muni,
      polygon = setores,
      vars = c('pop_ph', 'avg_inc_resp'),
      verbose = FALSE
    )
    
    # Filtrar setores com dados válidos
    setores_int <- setores_int |>
      filter(!is.na(avg_inc_resp), !is.na(pop_ph), pop_ph >= 5) |>
      mutate(
        renda_inteira = round(avg_inc_resp, 0),
        pop_inteira = round(pop_ph, 0),
        name_muni = name_muni  # Adicionar nome do município
      )
    
    if (nrow(setores_int) == 0) {
      cat("  ⚠️ Nenhum setor com dados válidos\n")
      return(FALSE)
    }
    
    cat(sprintf("  Setores com dados válidos: %d\n", nrow(setores_int)))
    cat(sprintf("  Renda média: R$ %.2f\n", mean(setores_int$avg_inc_resp, na.rm = TRUE)))
    cat(sprintf("  Renda mínima: R$ %.2f\n", min(setores_int$avg_inc_resp, na.rm = TRUE)))
    cat(sprintf("  Renda máxima: R$ %.2f\n", max(setores_int$avg_inc_resp, na.rm = TRUE)))
    
    # Criar popups
    popups <- sapply(1:nrow(setores_int), function(i) 
      criar_popup_renda_setor(setores_int[i, ]))
    
    # Criar labels com classificação de renda
    setores_int <- setores_int |>
      mutate(
        classe_renda = case_when(
          avg_inc_resp < 1000 ~ "Muito Baixa (< R$ 1.000)",
          avg_inc_resp < 2000 ~ "Baixa (R$ 1.000-2.000)",
          avg_inc_resp < 3000 ~ "Média-Baixa (R$ 2.000-3.000)",
          avg_inc_resp < 5000 ~ "Média (R$ 3.000-5.000)",
          avg_inc_resp < 10000 ~ "Média-Alta (R$ 5.000-10.000)",
          TRUE ~ "Alta (> R$ 10.000)"
        )
      )
    
    # Criar mapa interativo
    mapa_renda <- mapview(
      setores_int, 
      zcol = 'renda_inteira',
      layer.name = paste("Renda Média (R$) -", name_muni),
      alpha.regions = 0.8,
      popup = popups,
      label = setores_int$classe_renda,
      col.regions = colorRampPalette(c("#440154", "#31688e", "#35b779", "#fde724"))(100)
    )
    
    # Salvar mapa como HTML
    # Criar nome de arquivo seguro (sem espaços ou caracteres especiais)
    nome_arquivo <- iconv(name_muni, to="ASCII//TRANSLIT")
    nome_arquivo <- gsub("[^A-Za-z0-9]", "_", nome_arquivo)
    nome_arquivo <- tolower(nome_arquivo)
    caminho_arquivo <- sprintf("docs/mapas/sem_bairros/%s.html", nome_arquivo)
    
    htmlwidgets::saveWidget(
      mapa_renda@map, 
      file = caminho_arquivo, 
      selfcontained = FALSE,
      title = paste("Renda por Setor -", name_muni)
    )
    
    cat(sprintf("  ✓ Mapa salvo: %s\n", caminho_arquivo))
    
    return(TRUE)
  }, error = function(e) {
    cat(sprintf("  ✗ Erro ao processar %s: %s\n", name_muni, e$message))
    return(FALSE)
  })
}

# 6. Processar todos os municípios
cat("\n=======================================================\n")
cat("INICIANDO PROCESSAMENTO DOS MUNICÍPIOS\n")
cat("=======================================================\n")

resultados <- data.frame(
  municipio = character(),
  sucesso = logical(),
  stringsAsFactors = FALSE
)

for (i in 1:nrow(municipios_maiores)) {
  code <- municipios_maiores$code_muni[i]
  name <- municipios_maiores$name_muni[i]
  
  sucesso <- processar_municipio(code, name)
  
  resultados <- rbind(resultados, data.frame(
    municipio = name,
    sucesso = sucesso,
    stringsAsFactors = FALSE
  ))
}

# 7. Relatório final
cat("\n=======================================================\n")
cat("RELATÓRIO FINAL\n")
cat("=======================================================\n\n")

cat(sprintf("Total de municípios processados: %d\n", nrow(resultados)))
cat(sprintf("Mapas criados com sucesso: %d\n", sum(resultados$sucesso)))
cat(sprintf("Municípios com erro: %d\n\n", sum(!resultados$sucesso)))

if (sum(!resultados$sucesso) > 0) {
  cat("Municípios com erro:\n")
  print(resultados[!resultados$sucesso, ])
}

cat("\nMapas salvos em: docs/mapas/sem_bairros/\n")
cat("=======================================================\n")
