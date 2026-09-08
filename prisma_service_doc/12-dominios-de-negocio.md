# Domínios de negócio e como navegar neles

## 1. O domínio aparece na árvore

O Prisma organiza o código por vocabulário funcional dentro de `Core/Domain`, `Core/Application/BSN`,
`PrismaService/Controllers` e `Core/Services`. A pasta não é apenas organização estética: ela cria um
mapa de navegação entre contrato, regra, persistência e integração.

## 2. Principais famílias

| Família | BSNs/áreas | Evidência típica |
|---|---|---|
| Clientes | `ClienteBsn`, documentos, master, acesso | dados cadastrais, contas e escopo |
| Ativos | `AtivosBsn`, `InstrumentBsn`, classificações | cadastro, fontes, preços e atributos |
| Trades | `TradeBsn`, `TradeEventoBsn`, `TradeOpcaoBsn` | boletas, eventos e reconciliação |
| Posições | loaders, `PosicaoAddeparBSN`, `PosicaoConsolidada` | posição por data e carteira |
| Consolidação | `ConsolidacaoBsn`, `PortfolioBsn`, reports | carteira, patrimônio e relatórios |
| Preços | `PriceBsn`, `PriceLoaderBsn` | cargas de índices, ativos e fontes |
| Performance | `IndicadoresBSN`, `DataPerformanceBSN` | métricas, retorno e drawdown |
| Receitas | `ReceitasBsn`, batimento de taxa | taxa, rebate e liberação |
| Compliance | `ComplianceBSN` | APIs externas e processamento de análise |
| Autorização | `AutorizacaoBsn`, filtro global | API, grupo e escopo de cliente |
| Auditoria | `AuditoriaBsn` e repository | ANBIMA, carteira administrada e evolução |
| XML/Anbima | loaders, matchers e jobs | arquivos posicionais e matching |

## 3. Padrão de navegação por domínio

Ao investigar uma funcionalidade, seguir a sequência:

```text
Controller
  -> interface BSN
  -> BSN concreto
  -> DTO/request/response
  -> repository/interface
  -> entidade/mapping
  -> DbContext/schema
  -> integração ou Job relacionado
```

Se o fluxo for assíncrono, adicionar:

```text
fila -> consumidor -> handler -> BSN -> status/log
```

## 4. BSN como orquestrador

Os BSNs não são apenas serviços CRUD. Eles frequentemente:

- montam escopo de clientes autorizados;
- combinam múltiplos DbContexts;
- chamam parceiros;
- aplicam regras temporais;
- iniciam cargas em fila;
- usam locks;
- executam bulk operations;
- produzem arquivos;
- calculam indicadores;
- coordenam transações locais.

Por isso, documentar somente a Controller perde a maior parte do comportamento real.

## 5. Contratos e entidades

`Core/Domain/DTOs` contém contratos específicos por problema de negócio. Entidades `Tb*` representam
tabelas, enquanto `View*` representam consultas/views e DTOs representam entrada, saída, integração ou
relatório.

Prefixos e pastas ajudam a distinguir:

```text
Tb*       -> tabela/entidade persistida
View*     -> view ou leitura especializada
*Request  -> entrada de operação
*Response -> saída de API
*Dto      -> transporte interno/externo
*Options  -> configuração
*Bsn      -> orquestração de aplicação
```

## 6. Como priorizar uma investigação

Começar pelos fluxos que cruzam mais boundaries:

1. consolidação e posição;
2. preços e matching;
3. receitas e batimentos;
4. auditoria e ANBIMA;
5. autorização e escopo por cliente;
6. cargas XML e Datalake.

Esses fluxos revelam melhor os padrões de concorrência, idempotência, persistência e integração do que
um cadastro simples.
