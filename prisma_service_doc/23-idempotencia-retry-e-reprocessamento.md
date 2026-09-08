# Idempotência, retry e reprocessamento

## 1. Retry não é idempotência

`BaseBsn.ExecuteWithRetryAsync` repete chamadas em timeout e HTTP 504. Isso resolve falhas transitórias,
mas só é seguro quando repetir a operação não duplica efeito.

```text
retry = repetir chamada
idempotência = repetir não altera resultado indevidamente
```

## 2. Estratégias observadas

O sistema usa combinações de:

- locks nomeados;
- constraints únicas;
- busca por chave antes da gravação;
- inativação de versão anterior;
- bulk transacional;
- status de fila;
- logs de atividade;
- scopes próprios para operações longas.

## 3. Operação reexecutável

Uma operação financeira deve declarar:

```text
chave da operação
estado inicial permitido
efeito de sucesso
estado intermediário
como detectar execução anterior
como retomar após falha
```

## 4. Retry de integrações

Retry deve considerar:

- status HTTP;
- timeout;
- método seguro ou não;
- backoff;
- limite de tentativas;
- cancellation token;
- logging sem segredo;
- resposta parcial do parceiro.

Retry cego em POST ou em carga financeira pode gerar duplicidade.

## 5. Reprocessamento de fila

A fila persistida oferece status, prioridade e logs. O consumidor de Service Bus precisa definir
ack/reentrega/dead-letter. O worker precisa definir se captura a exceção ou retorna falha ao host.

A documentação de cada Job deve conter um runbook simples:

```text
falha -> localizar execução -> verificar status -> verificar efeitos -> reprocessar/compensar
```
