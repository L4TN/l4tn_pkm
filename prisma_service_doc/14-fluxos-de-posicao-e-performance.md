# Fluxos de posição e performance

## 1. Posição é dado temporal

No Prisma, posição não é somente “saldo atual”. Os fluxos trabalham com data de posição, cliente,
carteira, ativo, fonte, status e histórico. XML, XP Posi, Addepar e consolidação podem representar
visões diferentes do mesmo patrimônio.

## 2. Fontes recorrentes

- `ArquivoDePosicaoContext`: headers, arquivos e posições XML;
- `XpPosiContext`: posições e movimentações da XP;
- `WhgContext`: clientes, contas, carteiras e cadastro;
- serviços externos: Addepar, XP Wealth e outros;
- tabelas consolidadas: resultado pronto para consulta da API.

## 3. Estratégia de integração

O BSN geralmente calcula escopo e datas antes de consultar a fonte:

```text
cliente/carteira
  -> data de referência
  -> fonte de posição
  -> MemoryJoin por chave
  -> normalização
  -> consolidação
  -> indicador/performance
```

O uso de `MemoryJoin` reduz consultas amplas e permite restringir fontes grandes ao escopo da operação.

## 4. Performance financeira

`DataPerformanceBSN`, `IndicadoresBSN` e os relatórios de consolidação trabalham com séries, retorno
acumulado, drawdown, benchmark e janelas temporais. A documentação de cada fluxo precisa informar:

- se o retorno é diário, mensal, anual ou acumulado;
- qual benchmark é usado;
- como dias sem posição são tratados;
- como dados faltantes são tratados;
- como arredondamento é aplicado;
- se valores são brutos ou normalizados.

## 5. Concorrência e atualização

Cargas de posição e preço podem ocorrer simultaneamente. Os BSNs usam locks nomeados, bulk operations
e consultas por chaves para reduzir duplicidade e colisões.

A garantia completa depende também de constraints, status e idempotência no banco; lock local sozinho
não coordena réplicas.
