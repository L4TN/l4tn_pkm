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

## Ordem de leitura recomendada

1. Panorama e fluxo geral.
2. Infraestrutura transversal.
3. Legibilidade e convenções.
4. Camadas específicas.
5. Riscos e recomendações.
6. Leia a análise profunda para entender as relações entre os mecanismos.
7. Use arquivos exemplares e mapa de pastas como referência de navegação.
