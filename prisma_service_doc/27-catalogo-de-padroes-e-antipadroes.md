# Catálogo de padrões e anti-padrões

## Padrões de plataforma

### Composition root compartilhado

`ConfigureIoC` é usado por APIs e WebJobs. Uma mudança de infraestrutura se propaga pelos runtimes.

### Convention scanning

Interfaces e classes-base funcionam como metadados de registro. Reduz configuração manual, mas exige
testes de composição.

### Marker interfaces de lifetime

`ISingletonInstance` e `ITransientInstance` tornam lifetime uma propriedade visível do tipo.

### Startup tasks

Options, mensagens e certificados são carregados antes do trabalho. A plataforma falha cedo em
configuração obrigatória inválida.

## Padrões de aplicação

### BaseBsn como toolkit

Logger, mapper, configuração, repositories, validação, locks, retry e paralelismo ficam disponíveis sem
repetição em cada BSN.

### Exceção tipada como contrato

A aplicação comunica intenção com `CustomNotFoundException`, `CustomConflictException` e similares.
O filtro traduz intenção para HTTP.

### Mensagens executáveis

Métodos públicos do `MessageDomainService` são comparados ao catálogo JSON por reflexão no startup.

### Autorização data-driven

Grupos, funcionalidades, APIs, produto, path e cliente participam da autorização. Alterações podem ser
feitas no banco sem deploy.

## Padrões de persistência

### Mapping por família e schema

Classes-base de mapping representam schemas e reduzem configuração repetitiva.

### Projection-first

`ProjectTo` permite retornar contratos sem materializar entidades inteiras.

### Três velocidades de escrita

SaveChanges, batch e bulk atendem perfis transacionais e cargas de volume.

### Auditoria na última fronteira

`CommonBaseDbContext` preenche usuário durante SaveChanges, cobrindo API, Job e integração.

### SQL para domínio

Códigos de erro SQL viram conflitos de aplicação com mensagens e metadados.

### MemoryJoin

Lista de chaves calculada no processo pode ser aplicada à query EF sem SQL manual, especialmente em
relatórios cross-context.

## Padrões de integração

### Adapter/anti-corruption layer

Serviços de parceiro isolam DTOs, autenticação, normalização e erros externos.

### Feature flag de implementação

O contrato `IXpAuthService` permanece enquanto a implementação muda por option.

### mTLS no handler

Certificado, validação e headers vivem na composição do HttpClient, não dentro da regra de negócio.

## Padrões de processamento

### Template Method de worker

A base controla cron, logging, timer, options e falhas; o worker implementa `WorkAsync`.

### Lock local e distribuído

`BaseBsn` protege concorrência no processo; `IDistributedLock` protege recursos entre réplicas.

### Carga idempotente por inativação

Registros anteriores são inativados e a nova versão é inserida, preservando histórico lógico.

### Shutdown coordenado

Heartbeat, shutdown file, Ctrl+C, ProcessExit, cancellation token e telemetry flush usam a mesma
estratégia de encerramento.

## Anti-padrões e limites observados

- Controllers com `DbContext` direto;
- BSNs com milhares de linhas;
- filtro global acumulando autorização, cache, métricas e exceções;
- service locator usado fora das bases transversais;
- cache de autorização apenas local;
- CORS aberto;
- validação TLS permissiva;
- status HTTP divergente entre MVC e middleware;
- worker que captura erro sem informar falha ao scheduler;
- options singleton com estado mutável;
- ausência de testes automatizados suficientes;
- números mágicos em status e domínio;
- jobs/contextos com lifetime excessivamente longo.

## Regra para copiar o Prisma

Copiar a intenção, não somente a classe:

```text
Padrão bom
  -> entender problema resolvido
  -> identificar fronteira
  -> medir lifetime/concurrency
  -> adicionar teste
  -> adaptar ao contexto
```

A maior força do Prisma é ter transformado conhecimento operacional em infraestrutura compartilhada. A
maior ameaça é essa infraestrutura ficar tão implícita que somente quem conhece o histórico consiga
alterá-la com segurança.
