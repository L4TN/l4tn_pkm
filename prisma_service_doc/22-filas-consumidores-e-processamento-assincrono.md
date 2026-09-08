# Filas, consumidores e processamento assíncrono

## 1. Dois tipos de fila

O Prisma usa tanto fila persistida no banco quanto mensageria:

```text
TbFilaProcessamento
  -> prioridade, status, pai/filho e log

Azure Service Bus
  -> mensagens, consumers e handlers
```

A fila de banco é adequada para processos longos que precisam de consulta operacional, status e
reprocessamento. Service Bus é adequado para distribuição de eventos/comandos entre processos.

## 2. Fila persistida

O padrão observado em `FilaProcessamentoBsn` é:

```text
request
  -> registro pendente
  -> seleção por tipo/status
  -> prioridade
  -> worker
  -> logs de atividade
  -> status final/cancelamento
```

A consulta seleciona o item pendente por status e tipo, ordenando por `NrPrioridade`. O BSN cria escopo
próprio de `DbContext` para persistir logs em operações longas, evitando change tracker acumulado.

## 3. Service Bus

`ProgramFactory` possui modo de consumers, registra `BackgroundService` e executa `host.RunAsync`.
Os consumers e handlers ficam em `Jobs/<Job>/Consumers` e `Handlers`.

A estrutura separa:

- transporte e ciclo de vida no consumer;
- tratamento da mensagem no handler;
- regra de negócio no BSN;
- persistência no repository/contexto.

## 4. Reprocessamento e idempotência

Uma mensagem ou item de fila pode ser processado novamente por timeout, restart ou falha parcial. O
fluxo deve possuir uma chave de negócio e uma estratégia:

- verificar se o resultado já existe;
- usar unicidade no banco;
- inativar versão anterior e inserir a nova;
- atualizar status de forma monotônica;
- registrar log de atividade;
- tornar etapas repetíveis.

A existência de locks, status e bulk transacional mostra que o Prisma foi desenhado para operações
reexecutáveis, mas cada handler precisa documentar seu próprio contrato.

## 5. Cancelamento

`CancellationToken` atravessa `ProgramFactory`, worker, BSN, repository e chamadas externas. O token
permite que shutdown de Azure WebJobs interrompa operação antes de iniciar nova etapa.

Uma operação que ignora o token pode continuar usando DbContext ou credenciais depois do encerramento
solicitado.

## 6. Falha de consumer versus falha de negócio

O sistema deve distinguir:

```text
Mensagem inválida/erro funcional -> registrar rejeição e contexto
Falha transitória de dependência   -> retry/reentrega
Falha permanente                   -> dead-letter/alerta
Cancelamento                       -> encerramento controlado
```

Essa distinção precisa ser documentada por consumer, principalmente nos jobs financeiros.
