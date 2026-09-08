# Preços, matching e reconciliação

## 1. Preço é pipeline, não simples CRUD

`PriceLoaderBsn` concentra cargas de índices, ativos e fontes como Anbima/B3. O pipeline pode envolver
obtenção externa, validação, matching, seleção de fonte, atualização em lote e disponibilização para
consolidação.

## 2. Locks nomeados

O loader usa `ExecuteWithLockAsync` para operações como carga de ativos, índices e análise de cadastro.
A chave nomeada representa o recurso lógico, evitando que duas execuções locais processem o mesmo lote.

## 3. Matching de ativo

Os fluxos de preço precisam resolver correspondência entre códigos externos e ativos internos. O
matching pode envolver:

- código do parceiro;
- tipo de ativo;
- fonte;
- moeda;
- classe/subclasse;
- estratégia;
- status do cadastro.

O resultado deve ser documentado como decisão de domínio, não escondido como detalhe de query.

## 4. Reconciliação

`ReconciliacaoPortfolioBsn` e BSNs de trade/posição comparam fontes diferentes e persistem diferenças.
Um fluxo de reconciliação deve separar:

```text
escopo
  -> leitura fonte A
  -> leitura fonte B
  -> normalização
  -> comparação por chave
  -> divergência
  -> liberação/ajuste
  -> auditoria
```

## 5. Risco de cópia superficial

A infraestrutura de lock, bulk e projection é reutilizável. As regras de matching, tolerância,
prioridade de fonte e arredondamento são específicas do domínio financeiro e não devem ser copiadas sem
entender seus contratos.
