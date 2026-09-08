# Prisma Service — documentação arquitetural

Esta pasta contém a dissecação do funcionamento do **Prisma Service**. O material foi dividido por
responsabilidade para que cada assunto possa ser lido e atualizado sem navegar por um único Markdown
de milhares de linhas.

## Índice

- [Índice e método](prisma_service_doc/00-indice-e-metodo.md)
- [Panorama e fluxo](prisma_service_doc/01-panorama.md)
- [Infraestrutura transversal](prisma_service_doc/02-infraestrutura.md)
- [Legibilidade e convenções](prisma_service_doc/03-legibilidade.md)
- [Camadas específicas](prisma_service_doc/04-camadas-especificas.md)
- [Riscos e limites](prisma_service_doc/05-riscos-e-limites.md)
- [Recomendações derivadas](prisma_service_doc/06-recomendacoes-derivadas.md)
- [Arquivos exemplares](prisma_service_doc/07-arquivos-exemplares.md)
- [Mapa de pastas](prisma_service_doc/08-mapa-de-pastas.md)
- [Análise profunda de patterns](prisma_service_doc/09-analise-profunda-patterns.md)
- [Runtime e composition root](prisma_service_doc/10-runtime-e-composition-root.md)
- [Pipeline HTTP e respostas](prisma_service_doc/11-pipeline-http-e-contratos-de-resposta.md)
- [Domínios de negócio](prisma_service_doc/12-dominios-de-negocio.md)
- [Fluxos de consolidação](prisma_service_doc/13-fluxos-de-consolidacao.md)
- [Posição e performance](prisma_service_doc/14-fluxos-de-posicao-e-performance.md)
- [Preços e reconciliação](prisma_service_doc/15-fluxos-de-precos-e-reconciliacao.md)
- [Receitas e auditoria](prisma_service_doc/16-fluxos-de-receitas-e-auditoria.md)
- [Persistência e contextos](prisma_service_doc/17-persistencia-e-contextos.md)
- [Queries e performance](prisma_service_doc/18-patterns-de-query-e-performance.md)
- [Auditoria, transações e integridade](prisma_service_doc/19-auditoria-transacoes-e-integridade.md)
- [Catálogo de integrações](prisma_service_doc/20-catalogo-de-integracoes.md)
- [Runtime de WebJobs](prisma_service_doc/21-runtime-de-webjobs.md)
- [Filas e processamento assíncrono](prisma_service_doc/22-filas-consumidores-e-processamento-assincrono.md)
- [Idempotência e reprocessamento](prisma_service_doc/23-idempotencia-retry-e-reprocessamento.md)
- [Configuração e feature flags](prisma_service_doc/24-configuracao-options-e-feature-flags.md)
- [Segurança e autorização](prisma_service_doc/25-seguranca-autenticacao-e-autorizacao.md)
- [Observabilidade e operação](prisma_service_doc/26-observabilidade-health-checks-e-operacao.md)
- [Catálogo de padrões e anti-padrões](prisma_service_doc/27-catalogo-de-padroes-e-antipadroes.md)
- [Enums e arquivos centrais](prisma_service_doc/28-enums-e-arquivos-centrais.md)

## Escopo

Os documentos descrevem o código existente e distinguem explicitamente observações de recomendações.
A análise é arquitetural e não substitui a leitura das regras de negócio dos BSNs maiores.
