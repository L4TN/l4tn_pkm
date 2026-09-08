# Prisma Service — dissecção arquitetural

> Este conjunto de documentos descreve **como o Prisma Service funciona**, a partir da leitura do
> repositório. Não é um template genérico de backend nem uma proposta de reescrita do sistema.

## Escopo e método

A análise cobre um backend .NET 6 de aproximadamente 380 mil linhas, voltado à gestão e consolidação
 de portfólios financeiros. Foram lidos aproximadamente 80 de 3.500 arquivos; o foco é arquitetura,
fluxo e padrões, não a descrição completa de todas as regras de negócio.

O material separa:

- **observação:** comportamento ou estrutura encontrados no código;
- **evidência:** arquivo, classe ou trecho que demonstra o padrão;
- **ajuste recomendado:** melhoria derivada da análise, que não deve ser confundida com comportamento
  já implementado.

## Organização dos documentos

| Arquivo | Conteúdo |
|---|---|
| [01-panorama.md](01-panorama.md) | Processos, camadas, composição, pipeline HTTP e mapa das Controllers |
| [02-infraestrutura.md](02-infraestrutura.md) | DI, `BaseBsn`, autorização, exceções, auditoria, options, cache, jobs e filas |
| [03-legibilidade.md](03-legibilidade.md) | Convenções que tornam o backend navegável |
| [04-camadas-especificas.md](04-camadas-especificas.md) | Common, layouts posicionais, BI dinâmico, health checks e banco |
| [05-riscos-e-limites.md](05-riscos-e-limites.md) | O que não copiar e o que a leitura não cobriu |
| [06-recomendacoes-derivadas.md](06-recomendacoes-derivadas.md) | Templates e checklist derivados da dissecação |
| [07-arquivos-exemplares.md](07-arquivos-exemplares.md) | Exemplos canônicos por pasta |
| [08-mapa-de-pastas.md](08-mapa-de-pastas.md) | Árvore comentada da solução e das camadas |
| [09-analise-profunda-patterns.md](09-analise-profunda-patterns.md) | Relações entre os mecanismos, pontos fortes e padrões avançados |
| [10-runtime-e-composition-root.md](10-runtime-e-composition-root.md) | APIs, WebJobs e composition root |
| [11-pipeline-http-e-contratos-de-resposta.md](11-pipeline-http-e-contratos-de-resposta.md) | Pipeline HTTP, identidade e respostas centralizadas |
| [12-dominios-de-negocio.md](12-dominios-de-negocio.md) | Famílias funcionais e navegação por domínio |
| [13-fluxos-de-consolidacao.md](13-fluxos-de-consolidacao.md) | Escopo, datas, relatórios, filas e concorrência |
| [14-fluxos-de-posicao-e-performance.md](14-fluxos-de-posicao-e-performance.md) | Posição temporal e indicadores |
| [15-fluxos-de-precos-e-reconciliacao.md](15-fluxos-de-precos-e-reconciliacao.md) | Preços, matching e reconciliação |
| [16-fluxos-de-receitas-e-auditoria.md](16-fluxos-de-receitas-e-auditoria.md) | Receitas, auditoria e arquivos |
| [17-persistencia-e-contextos.md](17-persistencia-e-contextos.md) | DbContexts, mappings, repositories e integridade |
| [18-patterns-de-query-e-performance.md](18-patterns-de-query-e-performance.md) | Projeção, tracking, batch e MemoryJoin |
| [19-auditoria-transacoes-e-integridade.md](19-auditoria-transacoes-e-integridade.md) | Transações, constraints, locks e auditoria |
| [20-catalogo-de-integracoes.md](20-catalogo-de-integracoes.md) | Parceiros, mTLS, HttpClients e health checks |
| [21-runtime-de-webjobs.md](21-runtime-de-webjobs.md) | Workers, cron, scopes e shutdown |
| [22-filas-consumidores-e-processamento-assincrono.md](22-filas-consumidores-e-processamento-assincrono.md) | Fila de banco, Service Bus, retry e idempotência |
| [23-idempotencia-retry-e-reprocessamento.md](23-idempotencia-retry-e-reprocessamento.md) | Contratos de repetição e reprocessamento |
| [24-configuracao-options-e-feature-flags.md](24-configuracao-options-e-feature-flags.md) | Options, banco, segredos e feature flags |
| [25-seguranca-autenticacao-e-autorizacao.md](25-seguranca-autenticacao-e-autorizacao.md) | Claims, autorização, escopo de cliente e TLS |
| [26-observabilidade-health-checks-e-operacao.md](26-observabilidade-health-checks-e-operacao.md) | Logs, telemetria, health checks e operação |
| [27-catalogo-de-padroes-e-antipadroes.md](27-catalogo-de-padroes-e-antipadroes.md) | Catálogo de padrões fortes e riscos de cópia |
| [28-enums-e-arquivos-centrais.md](28-enums-e-arquivos-centrais.md) | Enums, `DescriptionAttribute` e arquivos de alavanca |
| [29-automapper-e-mapeamento.md](29-automapper-e-mapeamento.md) | Profiles, projeções, updates e traduções de contratos |
| [30-extensions-e-linguagem-de-dominio.md](30-extensions-e-linguagem-de-dominio.md) | Extensions, expressions e filtros dinâmicos |
| [31-validacao-e-mensagens-de-dominio.md](31-validacao-e-mensagens-de-dominio.md) | FluentValidation e catálogo de mensagens |
| [32-cache-redis-e-camadas-de-leitura.md](32-cache-redis-e-camadas-de-leitura.md) | Redis, compressão, TTL e cache por scope |
| [33-datalake-parquet-e-leitura-analitica.md](33-datalake-parquet-e-leitura-analitica.md) | Blob, Parquet, projeção de colunas e scopes |
| [34-mensageria-e-contratos.md](34-mensageria-e-contratos.md) | Service Bus, envelope e correlação |

## Ordem de leitura recomendada

1. Panorama e fluxo geral.
2. Infraestrutura transversal.
3. Legibilidade e convenções.
4. Camadas específicas.
5. Riscos e recomendações.
6. Leia a análise profunda para entender as relações entre os mecanismos.
7. Use arquivos exemplares e mapa de pastas como referência de navegação.
