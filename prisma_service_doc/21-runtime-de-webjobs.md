# Runtime de WebJobs

## 1. `ProgramFactory` como host comum

Todos os WebJobs podem usar `Jobs/CommonWebJob/ProgramFactory.cs`. A factory configura:

- `appsettings.Common.json`;
- `appsettings.json` do job;
- configuração por ambiente;
- logging console com scopes;
- Application Insights em Staging/Production;
- `ConfigureIoC` compartilhado;
- startup tasks;
- heartbeat;
- cancelamento;
- flush de telemetria.

O Job individual precisa declarar principalmente qual worker ou consumer deseja iniciar.

## 2. Dois modelos de execução

```text
Worker agendado
  ProgramFactory.AddWorker<TWorker>()
  -> CheckCanExecute()
  -> DoWorkAsync()

Consumer
  ProgramFactory.AddBusConsumer<TConsumer>()
  -> AddHostedService<TConsumer>()
  -> host.RunAsync()
```

A factory impede misturar os dois modos e exige pelo menos um componente antes do boot.

## 3. Escopos por worker

Para workers, `ProgramFactory` cria um `IServiceScope` por tipo registrado e resolve o worker dentro dele.
Isso reduz o risco de compartilhar `DbContext` entre execuções independentes e permite que cada worker
possua seu ciclo de vida.

Em operações longas, esse detalhe é essencial: contexto EF, caches scoped e `IDomainConfig` não devem
ser tratados como singleton do processo.

## 4. Cron e janela de execução

`BaseWebJobWorker.CheckCanExecute` lê `WorkerConfig`, valida enabled e cron, calcula a ocorrência e
executa somente dentro de uma janela de cinco minutos. A configuração do cron fica fora do código do
worker.

O worker também calcula `DtUltimaExecucao`, permitindo que o processamento saiba a janela anterior e
possa buscar dados incrementalmente.

## 5. Template Method operacional

A subclasse fornece `WorkAsync`. A base fornece:

- log de início e fim;
- cronômetro;
- scope de logging;
- tratamento de erro;
- verificação de habilitação;
- carregamento de options;
- cancellation token.

Esse é um caso claro de Template Method: o algoritmo operacional é fixado na base, e o domínio fornece
o passo variável.

## 6. Shutdown gracioso

`StartHeartbeat` observa:

- `WEBJOBS_SHUTDOWN_FILE`;
- `Console.CancelKeyPress`;
- `AppDomain.CurrentDomain.ProcessExit`.

Todos chamam o mesmo cancelamento. O loop de heartbeat registra atividade a cada 30 segundos, o que
ajuda a diferenciar processo vivo de processo travado.

No `finally`, a factory tenta cancelar o heartbeat, faz flush de `TelemetryClient` e aguarda tempo para
o envio das métricas.

## 7. Falha e semântica de sucesso

`BaseWebJobWorker.ExecuteWithTryCacheAsync` registra exceções e não necessariamente as relança. Isso
pode ser desejável para um job recorrente, mas cria uma pergunta operacional importante:

```text
O scheduler deve considerar o job concluído ou falho?
```

A resposta precisa ser documentada por worker. Em cargas financeiras, capturar e continuar pode impedir
reprocessamento automático ou mascarar uma execução incompleta.

## 8. WebJobs e domínio técnico

Os jobs configuram `IDomainConfig` como `prisma.whg`, executam startup tasks e usam os mesmos BSNs,
repositories, options e integrações das APIs. Assim, o domínio não possui uma implementação paralela
para processamento batch.

O mesmo fluxo de auditoria no `SaveChanges` funciona para uma requisição humana e para uma carga
agendada, mudando apenas a identidade técnica.
