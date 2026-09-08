# Análise profunda — os padrões que fazem o Prisma Service ser interessante

Este documento registra padrões que merecem ser entendidos como **decisões de engenharia**, não apenas
como uma lista de pastas. Ele complementa os documentos estruturais com as relações entre os arquivos.
Os exemplos abaixo são observações do código do Prisma Service; as ressalvas indicam pontos que exigem
cuidado ao copiar o padrão.

## 1. O sistema não tem um único runtime

O Prisma é uma plataforma compartilhada por três tipos de processo:

| Runtime | Composition root | Papel |
|---|---|---|
| API interna | `PrismaService/Startup.cs` | Controllers, BSNs, autenticação corporativa e health checks |
| API externa | `PrismaServiceExternal/Startup.cs` | Endpoints voltados a parceiros e autenticação própria |
| WebJobs | `Jobs/CommonWebJob/ProgramFactory.cs` | Processamento agendado, consumidores de Service Bus e cargas longas |

O ponto forte é que os três runtimes reutilizam `Core/IoC/DependencyInjectionExtencion.cs`.
`ConfigureIoC` compõe options, cache, validators, repositories, integrações, Service Bus, BSNs,
serviços de domínio, AutoMapper e startup tasks. Assim, a regra de composição não fica duplicada em
cada executável.

A consequência arquitetural é importante: `Core` não é somente uma biblioteca de entidades. Ele é o
**substrato operacional** compartilhado por HTTP, processos batch e consumidores de fila.

### Arquivos centrais

- `PrismaService/Startup.cs`
- `PrismaServiceExternal/Startup.cs`
- `Jobs/CommonWebJob/ProgramFactory.cs`
- `Core/IoC/DependencyInjectionExtencion.cs`
- `Core/IoC/DependencyInjection.cs`
- `Core/Common/Configuration.cs`

## 2. Composition root declarativo por convenção

O método privado `ConfigureByBaseInterfaceAndBaseClass` é um dos mecanismos mais poderosos do sistema.
Ele percorre os assemblies carregados, encontra classes concretas que implementam uma interface-base e
herdam de uma classe-base e registra automaticamente:

1. a implementação concreta;
2. as interfaces de negócio que ela implementa;
3. o lifetime apropriado.

A convenção é parametrizada. O mesmo mecanismo registra:

- `IRepository` + `BaseRepository<,>`;
- `IBaseBsn` + `BaseBsn<>`;
- `IBaseRepositoryCache` + `BaseRepositoryCache`;
- `IBaseMessagingService` + `BaseMessagingService<>`;
- `ICustomOptions` + `BaseCustomOptionsConfig<>`.

Isso transforma herança e interfaces em **metadados executáveis de DI**. Criar um novo BSN no lugar
certo, com a interface-base correta e a base correta, já o torna descobrível pelo container.

### Lifetime também é declarado pelo tipo

`ISingletonInstance` e `ITransientInstance` funcionam como markers. O scanner escolhe:

- singleton quando a classe implementa `ISingletonInstance`;
- transient quando implementa `ITransientInstance`;
- scoped como padrão.

Esse é um uso elegante de tipos para expressar uma decisão que normalmente ficaria escondida em uma
lista manual de `AddScoped`. A leitura do tipo revela o lifetime esperado.

### Trade-off

O ganho é enorme em consistência e redução de boilerplate. O custo é indireção: uma classe pode não
aparecer no `ConfigureIoC` e ainda assim ser registrada. Por isso, o mapa mental correto é:

```text
marker interface + classe base + assembly carregado
                    -> registro no container
```

Ao copiar o padrão, vale adicionar teste de composição/container validation; no Prisma, uma alteração
de herança pode alterar o registro sem uma linha explícita no composition root.

## 3. `BaseBsn<T>` é uma plataforma de aplicação, não apenas uma classe base

`Core/Application/BSN/Base/BaseBsn.cs` concentra capacidades transversais que aparecem em praticamente
todos os serviços de negócio:

- `ILogger<TBsn>`;
- `IMapper`;
- `IDomainConfig`;
- `IMessageDomainService`;
- `WhgContext`;
- repositories genéricos sob demanda;
- execução de validators;
- lock local por chave;
- retry para timeout/HTTP 504;
- execução em lote;
- execução de chunks em paralelo com limite de threads.

O BSN concreto fica livre para expressar o fluxo de negócio, enquanto o ritual operacional fica na base.
Esse é o motivo de `TradeBsn`, `PriceLoaderBsn`, `ConsolidacaoBsn` e outros poderem compartilhar
mecanismos sem uma hierarquia específica para cada domínio.

### 3.1 Service locator delimitado

`GetServiceSingleton<T>` é um service locator, mas seu uso está concentrado na classe-base para serviços
transversais e repositories genéricos. As dependências de negócio continuam aparecendo no construtor dos
BSNs. Essa separação é melhor do que espalhar `IServiceProvider` por todos os métodos.

A cache por tipo (`ConcurrentDictionary<Type, object>`) evita resolver repetidamente o mesmo serviço
dentro da instância do BSN. É uma otimização pequena, mas coerente com o lifetime scoped do BSN.

### 3.2 Concorrência local com chave semântica

`ExecuteWithLockAsync("LoadAtivosAsync", ...)` usa um `ConcurrentDictionary<string, SemaphoreSlim>`
estático. O lock não é por método, é por **recurso lógico**. Isso permite proteger operações distintas
que competem pelo mesmo processo de negócio.

O padrão é utilizado em cargas de preços, reconciliação, receitas, IPS e consolidação. É uma forma
prática de impedir reentrância dentro de uma mesma instância do processo.

> Limite: esse lock não coordena múltiplas réplicas. Para escala horizontal, o sistema também possui
> `IDistributedLock` e `Repository.SqlServer/DistributedTaskLock/SqlServerDistributedLock.cs`, que usa
> locks distribuídos do SQL Server via Medallion.Threading.

### 3.3 Retry e paralelismo com controle

A base diferencia retry para `CustomHttpRequestException` com status 504 e falhas cujo texto indica
timeout. Também fornece `ExecuteInBatchAsync` e `ExecuteInChunkInParallelAsync`, cujo `SemaphoreSlim`
limita o número de tarefas simultâneas.

Isso revela que integrações e cargas do Prisma foram desenhadas para lidar com:

- APIs que respondem por janelas ou lotes;
- datasets grandes demais para uma chamada única;
- limites de throughput de parceiros;
- timeouts transitórios;
- necessidade de não explodir o ThreadPool com paralelismo irrestrito.

## 4. Persistência poliglota por contextos com convenção de schema

O sistema não possui um único `DbContext`. Há contextos para `dbo`, financeiro, live, XP Posi, XML,
OutSystems, crédito, societário, assinatura, receita e Datalake. Todos recebem o mesmo timeout e a mesma
configuração base em `ConfigureRepositories`.

`Repository.SqlServer/BaseDbContext.cs` adiciona o schema padrão do contexto e aplica automaticamente os
mappings por família:

```text
BaseWhgMap<>             -> dbo
BaseFinanceiroMap<>     -> financeiro
BaseLiveMap<>            -> live
BaseOutSystemsMap<>      -> outsystems
BaseXpPosiMap<>          -> xp_posi
BaseArquivoDePosicaoMap<> -> xml
...
```

A aplicação consegue trabalhar com várias áreas do banco preservando a localização física no nome da
classe de mapping. A modelagem fica explícita sem repetir `modelBuilder.ApplyConfiguration(...)` para
centenas de entidades.

### 4.1 Repository genérico com projeção SQL

`BaseReadRepository` não oferece somente CRUD. Ele encapsula:

- `AsNoTracking` configurável;
- projeção com `AutoMapper.ProjectTo`;
- seleção tipada;
- agrupamento e ordenação paginada;
- `FirstOrDefault`, `Single`, `Exists`, `Count`, `Min` e `Max`;
- `CancellationToken` em todas as operações assíncronas.

O uso de `ProjectTo<TResult>` é especialmente relevante: o DTO é projetado no SQL em vez de carregar
a entidade completa e mapear tudo em memória.

`BaseWriteRepository` complementa com três níveis de escrita:

1. `SaveChanges` convencional;
2. operações em lote (`BatchUpdate`, `BatchDelete`);
3. `EFCore.BulkExtensions` para inserção/atualização/remoção em massa.

Essa gradação é adequada para um sistema que mistura cadastro transacional com cargas de mercado,
preços, posições e arquivos de alto volume.

### 4.2 `MemoryJoin`: ponte entre listas e queries SQL

O sistema usa extensivamente `MemoryJoin` para juntar uma lista já calculada em memória com uma query
EF de outro contexto. Isso aparece em `ReportConsolidacaoBsn`, `ClienteBsn`, `AuditoriaRepository`,
`InstrumentBsn` e dezenas de outros pontos.

O padrão resolve um problema real: o backend calcula chaves, escopos ou filtros em uma etapa e precisa
aplicá-los em SQL sem construir SQL manual ou fazer um `Contains` gigante e pouco previsível.

É um padrão particularmente importante nos relatórios, nos quais dados são combinados entre múltiplos
contextos: WHG, XP Posi, XML e Financeiro.

## 5. Auditoria e identidade atravessam todos os writes

O contrato `IIdUsuEntity` / `IIdUsuCriacaoEntity` transforma auditoria de usuário em comportamento de
infraestrutura. `CommonBaseDbContext.CustomSaveChanges()` inspeciona o `ChangeTracker` antes de cada
`SaveChanges` e preenche automaticamente:

- `IdUsu` em entidades novas;
- `IdUsuCriacao` em entidades novas.

A identidade vem de `IDomainConfig`, configurado por `DomainConfigMiddleware` a partir do claim de
email. Nos WebJobs, `ProgramFactory` chama `ConfigureDefaultUserPrisma()` para dar uma identidade
sistêmica aos processos sem usuário HTTP.

Isso cria uma cadeia elegante:

```text
claim HTTP / identidade do job
        -> IDomainConfig
        -> CommonBaseDbContext.CustomSaveChanges
        -> auditoria na entidade
```

Existe também `PrismaService/Auxiliar/InterceptorUserAndDate.cs`, usado em controllers DevEx para
preencher `IdUsu` e limpar `DtCpu` em payloads de edição. Ele representa a compatibilidade explícita da
camada HTTP, enquanto o `DbContext` é a última linha de garantia.

### Ponto forte

Mesmo que um caminho de aplicação esqueça de preencher o usuário, a persistência ainda tenta fazê-lo.
A regra importante está no lugar comum de todas as gravações, não em cada Controller.

### Limite

`IDomainConfig` é stateful e scoped. Um serviço singleton não deve capturar essa dependência nem reutilizar
estado de usuário entre requisições. Essa regra é essencial para não transformar a identidade de um
usuário em estado global.

## 6. O banco traduz falhas técnicas em conflitos de negócio

`Repository.SqlServer/BaseDbContext.HandleExceptions` interpreta números de erro SQL e converte detalhes
brutos em `CustomConflictException`:

| SQL Server | Tradução |
|---:|---|
| 547 | registro possui referências relacionadas |
| 2627 | valor viola chave única |
| 2601 | chave duplicada |
| 2628 | valor excede o tamanho da coluna |

Além de traduzir a mensagem, o código extrai schema, tabela, coluna, constraint e valor usando regex e
pode preencher `CustomObject`/`ConflictValue`. O filtro `ApplicationApiHandler` então transforma o
conflito em resposta HTTP 409.

Esse fluxo é um exemplo forte de **anti-corruption layer**: a Controller não precisa conhecer
`SqlException.Number`, e o cliente recebe linguagem de negócio.

```text
SQL Server -> BaseDbContext -> CustomConflictException -> ApplicationApiHandler -> HTTP 409
```

A mesma ideia aparece no tratamento de validações, not-found, forbidden e erros não tratados. A
recomendação registrada na documentação é consolidar a tabela de exceção/status/payload em uma fábrica
compartilhada, inclusive para middlewares fora do MVC.

## 7. Configuração em camadas com options clonáveis

`BaseCustomOptionsConfig<T>` implementa um mecanismo de configuração maior que o `IOptions<T>` padrão.
Cada configuração:

1. é identificada por um `EConfiguracao`;
2. lê seção de `appsettings`;
3. pode aplicar configuração específica do ambiente;
4. pode mesclar configuração persistida em `TbConfiguracao`;
5. usa `PasswordVOConverter` para valores protegidos;
6. expõe uma cópia clonada por `Current`;
7. informa `Loaded` e `Required`;
8. pode ser atualizada em runtime por `UpdateOptionsAsync`.

A ordem de `LoadOptionsFromOnlyDatabaseAsync` é deliberada: configurações gerais e específicas da
aplicação são ordenadas antes de `JsonConvert.PopulateObject`, de forma que a camada mais específica
possa complementar/sobrescrever a anterior.

`OptionsStartupTask` descobre todas as opções via `ICustomOptions`, carrega-as antes de iniciar o
processamento e agrega erros das opções obrigatórias. O processo falha cedo quando uma configuração
essencial não pode ser carregada, em vez de falhar no meio de uma operação financeira.

### Padrão relevante

Configuração deixou de ser apenas arquivo estático: virou uma capacidade versionável, atualizável e
validável do domínio. Isso permite ajustar regras operacionais, jobs e integrações sem recompilar todo o
sistema, mantendo uma trilha central de carregamento.

## 8. Mensagens como contrato executável

`MessageDomainService` combina:

- `Core/IoC/MessageDomain.json` como catálogo base;
- mensagens persistidas em configuração de banco;
- métodos fortemente nomeados em português de negócio;
- formatação de parâmetros;
- helpers que lançam `CustomException`, `CustomValidationException` e `CustomNotFoundException`.

O ponto mais interessante acontece no boot: por reflexão, o serviço lista seus métodos públicos que
retornam `string` e verifica se cada nome possui uma chave no catálogo. Uma mensagem ausente não vira
um erro silencioso em produção; vira falha de startup.

Assim, a API do serviço e o catálogo de mensagens funcionam como um contrato:

```text
método público de mensagem -> chave JSON -> texto parametrizado -> exceção de domínio
```

Esse padrão também reduz strings duplicadas em BSNs e concentra vocabulário funcional em um ponto
localizável.

## 9. Startup tasks como pipeline de boot

`IStartupTask` permite adicionar tarefas de inicialização sem acoplar todas ao `Program.cs`. O registro
é feito por reflexão em `ConfigureStartupTask`; hoje há tarefas para:

- carregar options;
- carregar mensagens;
- carregar certificados.

A mesma sequência é executada pela API e por `ProgramFactory` dos WebJobs. O sistema, portanto, tem uma
fase explícita de **preparação antes de servir tráfego ou processar trabalho**.

Isso é particularmente bom para dependências que devem estar prontas antes do primeiro request:
certificados mTLS, configuração de parceiro e mensagens de domínio.

## 10. WebJobs: um runtime operacional unificado

`ProgramFactory<TProgram>` é uma fábrica de hosts para dezenas de WebJobs. Ele normaliza:

- carregamento de `appsettings.Common.json` e `appsettings.json`;
- DI compartilhada;
- logging e Application Insights;
- startup tasks;
- heartbeat de 30 segundos;
- cancelamento por `WEBJOBS_SHUTDOWN_FILE`;
- `CancelKeyPress` e `ProcessExit`;
- flush de telemetria antes de encerrar;
- modo worker agendado ou modo Service Bus consumer.

A API de composição é simples:

```text
ProgramFactory
  AddWorker<TWorker>()
  ou
  AddBusConsumer<TConsumer>()
  StartAsync()
```

O uso de dois modos mutuamente exclusivos evita iniciar acidentalmente workers e consumers no mesmo
processo. A factory ainda cria scopes separados por worker, importante para `DbContext` e serviços
scoped em operações longas.

### Cron com janela de execução

`BaseWebJobWorker.CheckCanExecute` interpreta o cron configurado, calcula a próxima ocorrência e só
executa se o horário atual estiver dentro de uma janela de cinco minutos. O worker não precisa conhecer
Azure WebJobs Scheduler nem implementar parsing de cron.

`DoWorkAsync` padroniza escopo de log, cronômetro, tratamento de erro e atualização de options antes
do trabalho. É um caso claro de Template Method: a base define o ciclo operacional e a subclasse fornece
apenas `WorkAsync`.

### Ressalva operacional

O base worker registra a exceção, mas `ExecuteWithTryCacheAsync` não relança automaticamente o erro.
Isso é útil para jobs recorrentes que devem terminar com telemetria, mas pode mascarar falha para o
orquestrador. Ao reutilizar o padrão, a política `throwException` deve ser conectada à decisão real de
retry/exit code.

## 11. Integrações externas com autenticação especializada

`ConfigureServices` não trata integrações como um único cliente genérico. Cada parceiro possui seu
contrato, serviço, autenticação e options, por exemplo:

- XP: autenticação nova/antiga selecionada por feature flag;
- XP mTLS: certificado carregado, validado, logado e anexado ao `HttpClientHandler`;
- Itaú: certificado temporário montado e apagado no `finally`;
- B3: certificado de container e handler próprio;
- Extranet Gateway: `BaseUrl` e `User-Agent` provenientes de options;
- Microsoft Graph: `ClientSecretCredential` e escopo configurado;
- Azure Blob, Synapse, Service Bus, Datalake e APIs de mercado.

O padrão relevante é tratar segurança de transporte como parte do composition root do cliente, não como
código solto dentro de cada chamada.

A seleção condicional de `IXpAuthService` por `FlNovaAuthXp` é um padrão de rollout progressivo:
o contrato permanece estável enquanto a implementação pode mudar por configuração.

## 12. Autorização data-driven e cache consciente do produto

`ApplicationApiHandler` combina autenticação, autorização, cache e medição de request em um filtro
central. A autorização não depende somente de atributos fixos: ela consulta tabelas de grupos,
funcionalidades, APIs e acesso de cliente.

O caminho da requisição é usado como chave de autorização. O filtro monta caches para:

- usuários externos;
- APIs liberadas para externos;
- funcionalidades dos grupos do usuário;
- APIs associadas às funcionalidades;
- escopo de clientes e exceções.

A autorização pode mudar no banco sem novo deploy. O produto e o email participam da chave, e o tempo de
cache é diferente para API interna e externa.

Esse desenho combina RBAC (grupos/funcionalidades) com autorização contextual por cliente. Não é apenas
“usuário tem role”; é “usuário, grupos, produto, path e escopo de cliente podem acessar esta operação”.

### Riscos documentados

- o filtro contém muita responsabilidade e merece decomposição futura;
- cache em memória não invalida automaticamente entre réplicas;
- respostas de acesso negado e códigos 401/403 precisam ser padronizados;
- `ConcurrentDictionary`/listas de chaves exigem cuidado em concorrência e invalidação.

## 13. Health checks que exercitam o ecossistema

Os health checks de produção não se limitam a `SELECT 1`. `HeathCheckServiceOptions.cs` registra checks
para XP, AdNnet, Addepar, EG, Alpha Tools, Bradesco, OutSystems, Datalake e consultas do Application
Insights.

A aplicação expõe `/health` e `/healthdashboard` e usa o mesmo sistema para observar dependências
externas que realmente determinam a capacidade operacional do Prisma. Os nomes descrevem a rota e o
parceiro, tornando o dashboard útil para suporte.

Há uma distinção operacional importante:

- health check técnico: dependência responde;
- regra de negócio: operação retornou dados válidos.

O sistema aproxima os dois mundos, o que é valioso para integrações financeiras, mas cada check deve
manter timeout e escopo pequenos para não transformar o endpoint de saúde em uma operação pesada.

## 14. Relatórios como orquestração temporal entre fontes

`AuditoriaRepository` mostra uma classe de problema que não aparece em uma arquitetura CRUD simples.
Ele combina dados de:

- clientes XP;
- contas WHG;
- XML de posição;
- movimentações TED;
- evolução de cota, patrimônio e taxas;
- parâmetros de volume financeiro.

O algoritmo cria escopos, restringe cada fonte por data e cliente, faz joins em memória com SQL e depois
calcula estado temporal: ativo, inativo, encerrado, primeiro aporte, posição dos últimos 12 meses,
benchmark, rentabilidade, taxas e threshold financeiro.

Isso demonstra que os BSNs funcionam como **orquestradores de consistência entre sistemas externos e
bases internas**, não somente como services CRUD. O tratamento de “data de referência” é um conceito
central do domínio e deve ser documentado ao lado das entidades, não somente nos métodos.

## 15. Transações de bulk com estratégia de substituição

Em `AuditoriaRepository.UploadEvolucaoCotaPLTaxaCarteiraAsync`, o sistema:

1. identifica contas distintas;
2. resolve IDs de cliente via `MemoryJoin`;
3. identifica registros existentes por chave composta;
4. inativa registros anteriores;
5. executa `BulkUpdate` e `BulkInsert` dentro de transação;
6. preserva histórico lógico com `FlAtivo`.

É um padrão de carga idempotente baseado em **inativação + inserção da versão nova**, em vez de atualizar
silenciosamente o registro histórico. A estratégia é adequada para arquivos e snapshots de mercado,
onde a mesma chave pode reaparecer com nova versão.

## 16. Leitura geral dos pontos fortes

Os pontos fortes mais relevantes do Prisma não estão isolados em uma classe; estão nas conexões:

1. **Composição única para vários runtimes:** API, API externa e jobs compartilham infraestrutura.
2. **Convenções executáveis:** markers, classes-base e reflexão reduzem configuração manual.
3. **Base classes com propósito:** BSN, repository e worker absorvem ritual repetitivo.
4. **Persistência como boundary:** auditoria automática e tradução de SQL protegem o domínio.
5. **Configuração operacional:** options carregadas, mescladas, clonadas e validadas no boot.
6. **Integração tratada como produto:** cada parceiro tem autenticação, options, health check e cliente.
7. **Escala pragmática:** bulk, batches, chunks paralelos, locks locais e distribuídos.
8. **Autorização rica:** path, grupo, funcionalidade, cliente e aplicação entram na decisão.
9. **Observabilidade de processo:** scopes, timers, Application Insights, heartbeat e flush gracioso.
10. **Conhecimento codificado na estrutura:** namespaces, markers, nomes de schemas e arquivos revelam
    como o backend deve ser estendido.

## 17. O que eu copiaria e o que eu não copiaria sem revisão

### Copiaria

- `ConfigureIoC` modularizado por responsabilidade;
- scanner de DI por interface/base, com teste de composição;
- `IStartupTask` para boot explícito;
- tradução de erros de persistência para exceções de domínio;
- auditoria no `SaveChanges`;
- `ProjectTo` e repositories orientados a projeção;
- base de worker com cron, heartbeat e graceful shutdown;
- health checks por dependência real;
- options com fonte em arquivo e banco, quando houver necessidade operacional;
- lock distribuído para jobs concorrentes.

### Revisaria antes de copiar

- service locator dentro de bases;
- filtro HTTP com autenticação, autorização, cache, métricas e exceção juntos;
- listas de cache em memória sem invalidação distribuída;
- `AllowAnyOrigin` no CORS da API;
- handler B3 que aceita qualquer certificado do servidor;
- `ExecuteTaskWithScopeBackgroud`, que cria scope mas não o descarta explicitamente;
- captura de exceções de worker sem política clara de falha;
- estado mutable em singletons de options, mensagens e integrações;
- classes BSN que cresceram para milhares de linhas.

A lição principal é que o Prisma acumulou uma infraestrutura de plataforma muito rica. O próximo salto
não é adicionar mais abstrações: é preservar esses mecanismos, tornar seus contratos mais explícitos,
adicionar testes de composição/integração e dividir os grandes orquestradores por fluxo de negócio.
