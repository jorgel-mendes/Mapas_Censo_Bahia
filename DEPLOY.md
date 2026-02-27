# 🚀 Guia de Deploy - Mapas de Renda da Bahia

Este guia fornece instruções passo a passo para gerar os mapas e fazer o deploy no GitHub Pages.

## 📋 Pré-requisitos

### 1. Instalar o R

Se ainda não tem o R instalado:
- Baixe em: [https://cran.r-project.org/](https://cran.r-project.org/)
- Recomendado: R versão 4.0 ou superior

### 2. Instalar os Pacotes R Necessários

Abra o R ou RStudio e execute:

```r
# Instalar pacotes do CRAN
install.packages(c(
  "dplyr",
  "geobr",
  "mapview",
  "leafpop",
  "htmlwidgets"
))

# Instalar cnefetools (pode estar no GitHub)
# Se o cnefetools não estiver disponível no CRAN:
install.packages("remotes")
remotes::install_github("ipeaGIT/cnefetools")
```

### 3. Verificar Cache (Opcional)

O pacote `cnefetools` faz cache dos dados baixados. Por padrão, são salvos em:
- Windows: `C:/Users/SEU_USUARIO/AppData/Local/cnefetools/`
- Linux/Mac: `~/.cache/cnefetools/`

Isso reduz muito o tempo nas próximas execuções!

## 🗺️ Gerar os Mapas

### Opção 1: Gerar Todos os Mapas de Uma Vez

Execute ambos os scripts em sequência:

```r
# 1. Mapas com bairros (municípios com bairros cadastrados)
source("script_bahia_renda_com_bairros.R")

# 2. Mapas sem bairros (20 maiores municípios)
source("script_bahia_renda_sem_bairros.R")
```

⏱️ **Tempo total estimado:** 50-100 minutos na primeira execução
   - As execuções seguintes serão muito mais rápidas devido ao cache

### Opção 2: Gerar Mapas Individualmente

#### Apenas municípios COM bairros:

```r
source("script_bahia_renda_com_bairros.R")
```

❗ **Atenção:** Este script pode demorar bastante na primeira execução, pois:
- Identifica automaticamente todos os municípios da Bahia com bairros
- Baixa dados do CNEFE para cada município
- Faz interpolação dasimétrica para cada um

#### Apenas os 20 maiores municípios:

```r
source("script_bahia_renda_sem_bairros.R")
```

## 🔍 Verificar Resultados

Após executar os scripts, você deve ter:

```
docs/
├── index.html
└── mapas/
    ├── com_bairros/
    │   ├── salvador.html
    │   ├── feira_de_santana.html
    │   └── ... (outros municípios)
    └── sem_bairros/
        ├── salvador.html
        ├── feira_de_santana.html
        └── ... (até 20 arquivos)
```

## 🌐 Testar Localmente

1. Abra o arquivo `docs/index.html` em um navegador
2. Navegue pelo menu e teste alguns mapas
3. Verifique se os links estão funcionando

⚠️ **Importante:** Alguns navegadores podem bloquear JavaScript em arquivos locais. 
Se tiver problemas, use um servidor local:

```bash
# Python 3
cd docs
python -m http.server 8000

# Acesse: http://localhost:8000
```

## 📤 Deploy no GitHub Pages

### Passo 1: Inicializar Git (se ainda não fez)

```bash
git init
git add .
git commit -m "Initial commit - Mapas de Renda da Bahia"
```

### Passo 2: Criar Repositório no GitHub

1. Acesse [https://github.com/new](https://github.com/new)
2. Nome do repositório: `Mapas_Censo_Bahia` (ou outro nome de sua escolha)
3. Descrição: "Mapas interativos de renda dos municípios da Bahia - Censo 2022"
4. **Público** ou Privado (sua escolha)
5. **NÃO** marque "Initialize with README" (já temos um!)
6. Clique em "Create repository"

### Passo 3: Conectar ao Repositório Remoto

```bash
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/Mapas_Censo_Bahia.git
git push -u origin main
```

### Passo 4: Ativar GitHub Pages

1. Vá até o repositório no GitHub
2. Clique em **Settings** (⚙️)
3. No menu lateral, clique em **Pages**
4. Em **Source**:
   - Branch: `main`
   - Folder: `/docs` ✅
5. Clique em **Save**
6. GitHub irá processar e em alguns minutos mostrará a URL

### Passo 5: Acessar o Site

Após alguns minutos, seu site estará disponível em:

```
https://SEU_USUARIO.github.io/Mapas_Censo_Bahia/
```

## 🔄 Atualizar os Mapas

Quando quiser atualizar os mapas (por exemplo, com novos dados ou correções):

```bash
# 1. Regenerar os mapas (execute os scripts R novamente)
source("script_bahia_renda_com_bairros.R")
source("script_bahia_renda_sem_bairros.R")

# 2. Adicionar mudanças ao Git
git add docs/
git commit -m "Atualização dos mapas"

# 3. Fazer push
git push origin main
```

O GitHub Pages será atualizado automaticamente em alguns minutos!

## 🐛 Solução de Problemas

### Erro: "package 'cnefetools' is not available"

```r
# Instalar do GitHub
install.packages("remotes")
remotes::install_github("ipeaGIT/cnefetools")
```

### Erro: "Cannot open URL" ou problemas de conexão

O script precisa baixar dados do IBGE. Verifique:
- Conexão com a internet
- Firewall não está bloqueando R
- Tente novamente mais tarde (servidores do IBGE podem estar ocupados)

### Erro: "No data available for municipality"

Alguns municípios podem não ter dados completos no Censo 2022:
- O script irá pular esses municípios automaticamente
- Verifique o relatório final para ver quais municípios falharam

### Demora muito para processar

É normal! Na primeira execução:
- Cada município pode levar 2-5 minutos
- O cache do `cnefetools` irá acelerar muito nas próximas vezes
- Dica: Execute em horários de menor tráfego (noite/madrugada)

### GitHub Pages não está funcionando

Verifique:
1. O repositório está público ou você tem GitHub Pro? (Pages privado requer Pro)
2. A pasta `/docs` foi selecionada corretamente?
3. Aguarde 5-10 minutos após ativar Pages
4. Limpe o cache do navegador e tente novamente

## 📊 Customizações

### Adicionar Mais Municípios aos 20 Maiores

Edite o arquivo `script_bahia_renda_sem_bairros.R` e adicione o nome do município na lista:

```r
municipios_maiores <- data.frame(
  name_muni = c(
    "Salvador",
    "Feira de Santana",
    # ... outros municípios
    "SEU_NOVO_MUNICIPIO"  # Adicione aqui
  ),
  stringsAsFactors = FALSE
)
```

### Mudar as Cores dos Mapas

Edite a paleta de cores em ambos os scripts:

```r
col.regions = colorRampPalette(c("#440154", "#31688e", "#35b779", "#fde724"))(100)
#                                 ^ roxo      ^ azul      ^ verde     ^ amarelo
```

### Adicionar Mais Variáveis

No campo `vars` dos scripts, adicione outras variáveis do Censo:

```r
vars = c('pop_ph', 'avg_inc_resp', 'SUA_VARIAVEL')
```

Consulte a documentação do `cnefetools` para variáveis disponíveis.

## 🎉 Conclusão

Parabéns! Seu projeto de mapas de renda da Bahia está no ar! 🚀

Não esqueça de:
- ⭐ Dar estrela no repositório original
- 📢 Compartilhar com colegas e pesquisadores
- 🐛 Reportar bugs ou sugestões via Issues

---

Desenvolvido com ❤️ para o Observatório FIEB
