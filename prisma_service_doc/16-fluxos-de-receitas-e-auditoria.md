# Receitas, auditoria e regras temporais

## 1. Auditoria como fluxo cross-system

`AuditoriaBsn` e `AuditoriaRepository` combinam Customer API, contas WHG, XML, TEDs e evolução de cota.
O resultado é uma visão de carteira administrada em uma data de referência.

## 2. Data de referência

O fluxo aplica a data em várias dimensões:

- posição disponível até a referência;
- aceite do termo anterior à referência;
- movimentação após aceite;
- janela de 12 meses;
- evolução no mês;
- encerramento ou distrato até a data.

A data não é apenas filtro SQL: ela altera status, elegibilidade, taxa e conteúdo do relatório.

## 3. Threshold e classificação

O repository consulta parâmetros de `TbParametroGenerico`, calcula volume financeiro e pode transformar
uma carteira ativa em inativa quando o patrimônio fica abaixo do threshold. Também zera métricas de
carteiras inelegíveis.

Parâmetros desse tipo devem ser documentados com unidade, vigência e owner, pois são regras de produto.

## 4. Upload idempotente

`UploadEvolucaoCotaPLTaxaCarteiraAsync` resolve contas, identifica registros pela combinação de conta e
data, inativa o existente e faz bulk update/insert em transação.

```text
mesma chave + nova carga
  -> versão antiga inativa
  -> versão nova inserida
```

Essa estratégia preserva histórico e permite reprocessamento controlado.

## 5. Arquivos de auditoria

O BSN também exporta CSV com configuração explícita de:

- delimitador `|`;
- encoding ISO-8859-1;
- decimal com vírgula;
- formato de data `dd/MM/yyyy`;
- precisão decimal definida.

Formato de arquivo é contrato externo e deve ser documentado junto com o fluxo, não somente no código.
