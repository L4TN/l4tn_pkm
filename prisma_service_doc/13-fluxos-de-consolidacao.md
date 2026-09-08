# Fluxos de consolidação

## 1. Por que consolidação é o núcleo técnico

Consolidação cruza carteiras, clientes, ativos, posições, movimentações, preços, regras de liberação e
fontes externas. É o melhor domínio para observar o Prisma como plataforma de dados e não como API CRUD.

Arquivos de referência:

```text
Core/Application/BSN/Consolidacao/ConsolidacaoBsn.cs
Core/Application/BSN/Consolidacao/PortfolioBsn.cs
Core/Application/BSN/Consolidacao/ReportConsolidacaoBsn.cs
Core/Application/BSN/Consolidacao/ReportBaseConsolidacaoBsn.cs
PrismaService/Controllers/DevEx/Consolidacao/ConsolidacaoController.cs
```

## 2. Padrão de escopo

Os fluxos normalmente começam calculando chaves de clientes, carteiras, ativos ou processamentos.
Depois usam `MemoryJoin` para aplicar essas chaves nos DbContexts corretos.

```text
filtro/request
  -> chaves autorizadas
  -> MemoryJoin
  -> query por contexto
  -> projeção
  -> regra temporal
  -> DTO/relatório
```

Isso evita carregar todo o banco para memória e evita depender de uma query monolítica contra um único
contexto.

## 3. Relatórios temporais

`ReportBaseConsolidacaoBsn` concentra operações comuns de relatório e `ReportConsolidacaoBsn` constrói
relatórios maiores, inclusive séries temporais, retorno acumulado, drawdown e dados de carteira.

A data é parte da identidade da consulta. O fluxo deve sempre esclarecer:

- data de posição;
- data de referência;
- data máxima disponível;
- janela histórica;
- status da carteira na data;
- se o valor é atual, histórico ou manual.

## 4. Escrita e fila

Consolidação também aparece associada à `TbFilaProcessamento`. O fluxo pode separar:

```text
solicitação
  -> registro de fila
  -> worker/BSN
  -> processamento por etapa
  -> log de atividade
  -> status final
```

A fila permite executar operações longas fora do request e acompanhar progresso, cancelamento e prioridade.

## 5. Concorrência

`ExecuteWithLockAsync` é usado para proteger inserções e cargas de consolidação. Isso evita que duas
execuções simultâneas processem o mesmo recurso lógico dentro do processo.

Para múltiplas instâncias, a proteção precisa usar `IDistributedLock` ou uma estratégia de unicidade/idempotência
no banco.

## 6. O que documentar por fluxo

Para cada operação de consolidação, registrar:

- request inicial;
- escopo de cliente/carteira;
- fontes consultadas;
- joins entre contextos;
- regra de data;
- cálculo financeiro;
- tabelas gravadas;
- fila e worker responsável;
- lock utilizado;
- comportamento de repetição;
- resposta síncrona ou assíncrona.
