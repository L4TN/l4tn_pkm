# Observabilidade, health checks e operação

## 1. Observabilidade como parte da execução

O Prisma não trata telemetria apenas como pacote instalado. Logging, scopes, timers, Application
Insights, health checks e heartbeat aparecem nos runtimes HTTP e nos WebJobs.

## 2. Request telemetry

`DomainConfigMiddleware` associa o email do usuário ao `RequestTelemetry`. `ApplicationApiHandler`
mede duração por `TraceIdentifier` e registra informações da action, host, query, path e connection id.

Essa combinação permite relacionar:

```text
request -> usuário -> action -> duração -> dependência/erro
```

O filtro também evita log repetitivo de sucesso usando cache por email/path durante uma hora.

## 3. Application Insights

`Startup` configura telemetria em Staging/Production, ajusta adaptive sampling e dependency tracking.
WebJobs fazem configuração própria e executam flush no encerramento.

O flush no shutdown é importante em processos curtos: sem ele, logs e métricas do fim da carga podem
ficar no buffer.

## 4. Health checks ativos

`HeathCheckServiceOptions` registra checks para parceiros e dependências como XP, Addepar, AdNnet,
Alpha Tools, EG, Bradesco, OutSystems, Insights e Datalake.

A API expõe `/health` e `/healthdashboard` em produção. Os nomes dos checks descrevem o parceiro e a
operação, tornando o resultado acionável para suporte.

## 5. Health check não é teste de negócio completo

Um health check deve validar capacidade operacional com timeout curto. Ele não deve executar uma
consolidação inteira nem depender de estado mutável da requisição.

Há três sinais diferentes:

```text
Liveness  -> processo está vivo
Readiness -> dependências mínimas estão disponíveis
Diagnóstico -> qual parceiro/consulta está falhando
```

O Prisma possui checks diagnósticos ricos; ao evoluir o sistema, vale separar liveness/readiness de
checagens caras ou externas.

## 6. Logs de processos

`ProgramFactory` cria scope com nome do WebJob, e `BaseWebJobWorker` cria scope com nome do worker.
Isso preserva contexto mesmo quando o mesmo runtime executa múltiplos workers.

O worker registra início, fim, duração e exceção. O heartbeat mostra que o processo continua executando,
enquanto o cron e o nome do worker permitem reconstruir a agenda.

## 7. Mensagens e erros

`MessageDomainService` centraliza textos funcionais e valida o catálogo no startup. Isso reduz mensagens
inconsistentes e torna erros pesquisáveis.

`BaseDbContext` traduz erros SQL; `ApplicationApiHandler` traduz exceções de domínio. A observabilidade
pode então separar:

- falha técnica;
- conflito esperado;
- validação de usuário;
- ausência de recurso;
- indisponibilidade de parceiro.

Essa classificação é melhor que contar qualquer exceção como incidente.

## 8. Perguntas operacionais que a documentação deve responder

- Qual job executou uma carga?
- Qual usuário ou identidade técnica fez a gravação?
- Qual parceiro estava indisponível?
- Qual request originou o erro?
- Foi erro de negócio ou falha técnica?
- O job pode ser reexecutado?
- O health check falhou por timeout, autenticação ou dados inválidos?
- O telemetry flush ocorreu antes do processo terminar?
