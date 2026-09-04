# Prisma Service — Análise Arquitetural Completa

> Dissecação de um backend .NET 6 de ~380 mil linhas para gestão e consolidação de portfólios financeiros.
> Documento único, consolidando duas passagens de leitura do código-fonte.
>
> **Foco:** padrões arquiteturais reaproveitáveis, técnicas de legibilidade, trade-offs, riscos e um
> template pronto para inspirar um backend novo.
>
> **Alcance honesto:** foram lidos ~80 de ~3.500 arquivos. A análise é sobre **arquitetura e forma**,
> não sobre as regras de negócio. A seção 9 lista explicitamente o que ficou de fora.

---

## Sumário

**PARTE I — PANORAMA**
1. [Números da base](#1-números-da-base)
2. [Arquitetura em camadas](#2-arquitetura-em-camadas)
3. [Mapa das 181 controllers](#3-mapa-das-181-controllers)

**PARTE II — INFRAESTRUTURA**

4. [Os 12 padrões que valem roubar](#4-os-12-padrões-que-valem-roubar)

**PARTE III — LEGIBILIDADE**

5. [A tese: estrutura em vez de documentação](#5-a-tese-estrutura-em-vez-de-documentação)
6. [As 8 técnicas de legibilidade](#6-as-8-técnicas-de-legibilidade)

**PARTE IV — CAMADAS ESPECÍFICAS**

7. [Common, parser posicional, BI dinâmico, health checks e o banco](#7-camadas-específicas)

**PARTE V — RISCOS**

8. [O que NÃO copiar](#8-o-que-não-copiar)
9. [O que não foi lido](#9-o-que-não-foi-lido)

**PARTE VI — APLICAÇÃO PRÁTICA**

10. [Template: estrutura de pastas](#10-template-estrutura-de-pastas)
11. [Template: controller, BSN e contratos](#11-template-controller-bsn-e-contratos)
12. [Template: injeção de dependência](#12-template-injeção-de-dependência)
13. [Checklist de adoção](#13-checklist-de-adoção)
14. [Veredito](#14-veredito)

---
---

# PARTE I — PANORAMA

## 1. Números da base

| Camada | Arquivos `.cs` | Linhas |
|---|---:|---:|
| `Core/Application` (BSNs, DTOs, Reports) | 717 | 196.497 |
| `Core/Domain` (entidades, VOs, contratos) | 1.353 | 46.335 |
| `Core/Services` (46 integrações externas) | 422 | 43.074 |
| `PrismaService` (181 controllers) | 181 | 42.450 |
| `Core/Repository.SqlServer` (480 mappings) | 567 | 32.702 |
| `PrismaServiceExternal` | 29 | 7.769 |
| `Jobs` (17 WebJobs) | 118 | 6.625 |
| `Core/Common` | 83 | 6.136 |
| `Core/IoC` | 55 | 2.466 |
| `Core/Repository.Datalake` | 29 | 2.015 |
| `Core/Repository.Common` | 13 | 1.027 |
| `Core/Repository.Redis` | 7 | 891 |

**Fora do C#:**

| Artefato | Volume |
|---|---:|
| Scripts SQL versionados (`Database/`) | 1.287 arquivos em 165 releases |
| Relatórios DevExpress (`.vsrepx`) | 88 |
| Templates de e-mail HTML | 18 |
| Pipelines Azure DevOps | 26 |

**Stack:** .NET 6 · C# · Clean Architecture com sufixo próprio (**BSN** = Business Service Network)
· 12 `DbContext` · 177 classes BSN · 46 serviços de integração
· Azure App Service, Azure SQL, Redis, Service Bus, Blob Storage, Web PubSub, Application Insights, Synapse/Datalake

---

## 2. Arquitetura em camadas

```
┌──────────────────────────────────────────────────────────────────┐
│  ENTRY POINTS                                                    │
│  PrismaService          (interno, Azure AD)                      │
│  PrismaServiceExternal  (parceiros, JWT próprio)                 │
│  17 WebJobs             (workers cron + consumers Service Bus)   │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│  Core/Application                                                │
│  BSN/ (regra de negócio) · Models/ (contratos API) · DTOs/       │
│  Filters/ · Interfaces/BSN/ · Mapper/ · Reports/ (DevExpress)    │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│  Core/Domain                                                     │
│  Entities/ · Interfaces/ · VOs/ · Validators/ · Enums/           │
│  Messaging/Contracts/ · Options/ · Services/                     │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────┬─────────────────────────────────┐
│  Core/Repository.*             │  Core/Services                  │
│  SqlServer · Redis · Datalake  │  XP · Itaú · B3 · Anbima        │
│  Common (bases genéricas)      │  Addepar · AlphaTools · Docusign│
│  SqlServer.Migrations          │  MsGraph · Azure · Protheus ... │
└────────────────────────────────┴─────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│  Core/IoC     → ConfigureIoC(): ponto ÚNICO de composição        │
│  Core/Common  → extensions, utils, exceptions, converters        │
└──────────────────────────────────────────────────────────────────┘
```

### A decisão estrutural mais importante

**`ConfigureIoC()` é o único ponto de composição da solução inteira.** API interna, API externa e todos
os 17 WebJobs chamam o mesmo método:

```csharp
// PrismaService/Startup.cs
services.ConfigureIoC(Configuration);

// Jobs/CommonWebJob/ProgramFactory.cs
services.ConfigureIoC(host.Configuration, CommandTimeoutDb);
```

Consequência prática: registrar uma dependência nova é uma linha, e 20 processos passam a enxergá-la.
É o que torna administrável ter quase 200 BSNs compartilhados entre API e batch.

O método é decomposto em blocos temáticos:

```csharp
public static IServiceCollection ConfigureIoC(this IServiceCollection services,
    IConfiguration configuration, TimeSpan? commandTimeoutDb = null)
{
    services.ConfigureOptions();
    services.ConfigureCustomOptions(configuration);
    services.ConfigureCache(configuration);
    services.ConfigureValidators();
    services.ConfigureRepositories(configuration, commandTimeoutDb);
    services.ConfigureServices();
    services.ConfigureServiceBus(configuration);
    services.ConfigureBsns();
    services.ConfigureDomainServices(configuration);
    services.ConfigureAutoMapperProfiles();
    services.ConfigureStartupTask();
    services.ConfigureMsGraph();

    return services;
}
```

### Pipeline HTTP (`Startup.Configure`)

```csharp
app.UseHttpsRedirection();
app.UseRouting();
app.UseAuthentication();
app.UseMiddleware<DomainConfigMiddleware>();   // popula IDomainConfig a partir do claim
app.UseAuthorization();
app.UseCors(...);
app.UseEndpoints(...);

DependencyInjection.ConfigureStaticSingletonInstance(app.ApplicationServices);
```

O `DomainConfigMiddleware` roda **entre** autenticação e autorização — precisa do usuário já resolvido,
e precisa estar pronto antes de qualquer coisa tocar o banco (é ele que alimenta a auditoria automática).

### Boot: startup tasks antes de servir tráfego

```csharp
public static async Task Main(string[] args)
{
    var host = CreateHostBuilder(args).Build();

    var startupTasks = host.Services.GetServices<IStartupTask>();
    foreach (var startupTask in startupTasks)
        await startupTask.ExecuteAsync().ConfigureAwait(false);

    await host.RunAsync();
}
```

Três tarefas registradas por reflexão: carregar certificados mTLS do Blob, carregar mensagens de domínio,
carregar options dinâmicas (com **fail fast** se alguma `Required` falhar).

---

## 3. Mapa das 181 controllers

### Distribuição por domínio

| Pasta | Controllers | Tamanho | Conteúdo |
|---|---:|---:|---|
| `DevEx/Cadastro/` | 50+ | 1,1 MB | Ativos, Clientes, Classificações, Fundos, Domínios, LiberacaoPortfolio |
| `DevEx/Movimentacao/` | 20+ | 220 KB | Boletas (10 tipos), Carrying/BBI, Cashflow, ExtranetGateway |
| `DevEx/Dados/` | 12 | 160 KB | Arquivos, Pipeline, Reprocessamento, Reconciliação, Receita |
| `DevEx/Autorizacao/` | 8 | 112 KB | Grupos, Funcionalidades, APIs, Usuários externos |
| `DevEx/Utils/` | 5 | 92 KB | ExtracaoDinamica, DisparadorEmail, GestaoTutorial, LinkConsolidacao |
| `DevEx/Proposta/` | 4 | 72 KB | CarteiraTeorica, AtivoProposta, Correlação |
| `DevEx/Arquivo/` | 2 | 64 KB | Arquivos e tipos |
| `DevEx/Consolidacao/` | 1 | 56 KB | **Núcleo** — 1.320 linhas |
| `DevEx/CRM/` | 6 | 52 KB | Atividade, Campanha, Dashboard |
| `DevEx/Posicao/` | 4 | 52 KB | Posição, Extrato, Performance, MovimentaçãoConta |
| `DevEx/Ips/` | 4 | 32 KB | IPS, CallsTáticos, Dashboard, TelaDeGuerra |
| `DevEx/Compliance/` | 1 | 24 KB | Compliance |
| `PrismaServiceExternal/` | 23 | ~200 KB | API de parceiros |
| Raiz + outros | ~10 | ~40 KB | Configurações, PubSub, Preferências |

### As três maiores

| Controller | Linhas | Papel |
|---|---:|---|
| `BoletasController` | 1.512 | Boletas: Aluguel, Câmbio, Estratégia, Evento, Fix, Margem, Opção, Reserva, Capital Comprometido |
| `ConsolidacaoController` | 1.320 | Wallet, Portfolio, Ranking, Solicitações — 12 dependências BSN |
| `PosicaoController` | 467 | Trabalha com 3 contextos: `ArquivoDePosicaoContext`, `WhgContext`, `XpPosiContext` |

### Rotas e convenções

```csharp
[Route("api/devex/[controller]")]            // maioria — action no atributo HTTP
[Route("api/devex/[controller]/[action]")]   // BoletasController
[Route("api/[controller]/[action]")]         // PosicaoController
[Route("api/[controller]")]                  // PrismaServiceExternal
```

Três padrões coexistindo — inconsistência real, tratada na seção 8.

### A camada BSN não é obrigatória

Este é o dado mais importante desta seção, e corrige uma impressão que a leitura superficial dá:

| Métrica | Valor |
|---|---:|
| Controllers na API interna | 181 |
| Que injetam `WhgContext` **direto** | **107 (59%)** |
| Que usam `DataSourceLoadOptions` (DevExtreme) | **110 (61%)** |

Em quase 60% dos casos a controller consulta EF direto e monta a projeção anônima na própria action —
e isso está **correlacionado** com o DevExtreme: a controller precisa devolver o formato que o
`DataSourceLoader` espera, então corta caminho pela camada de negócio.

```csharp
[HttpGet("solicitacoes/getCarteiras")]
[Produces("application/json")]
[Authorize]
public async Task<IActionResult> GetCarteiras(DataSourceLoadOptions loadOptions,
    [FromQuery] GetSolicitacoesRequest req)
{
    var query = _portfolioBsn.GetSolicitacoesCarteira(req).Select(i => new
    {
        i.IdCliente, i.IdConta, i.IdAtivo, i.IdCarteiraConsolidacao,
        NrCpfCnpjTitular = i.NrCpfCnpjTitular.ToMaskCPFCNPJ(),
        i.NmMaster, i.NmRm, i.NmInvestor, i.FlAtivo
    }).OrderBy(i => i.IdCliente);

    return Json(await DataSourceLoader.LoadAsync(query, loadOptions));
}
```

**Consequência séria:** o backend está acoplado ao protocolo de grid do DevExtreme em 61% das rotas.
Trocar o front (para React puro, por exemplo) exige reescrever a superfície da API, não só a UI.

Ponto positivo dentro do problema: mesmo cortando caminho, a projeção continua legível — as extensions
de `Common` (`ToMaskCPFCNPJ()`) mantêm a expressão limpa e o mascaramento de PII vira uma linha.

### Documentação: onde existe e onde não existe

| API | Actions HTTP | Blocos `/// <summary>` | Cobertura |
|---|---:|---:|---:|
| PrismaService (interno) | 1.197 | 47 | **~4%** |
| PrismaServiceExternal (parceiros) | 189 | 93 | **~49%** |

E só 20 das 181 controllers (11%) usam `#region`.

A API externa é 12× mais documentada porque o XML alimenta o Swagger que parceiros consomem
(`c.IncludeXmlComments(filePath)` no `Startup`). **Documentação onde há leitor externo; nomenclatura
onde o leitor é o próprio time.** É uma escolha, não descuido — e é a chave da Parte III deste documento.

---
---

# PARTE II — INFRAESTRUTURA

## 4. Os 12 padrões que valem roubar

### 4.1 Registro de DI por convenção + reflexão

Em vez de centenas de linhas de `AddScoped`, um varredor de `AppDomain` registra tudo que herda de uma
classe base **e** implementa uma interface marcadora:

```csharp
services.ConfigureByBaseInterfaceAndBaseClass(typeof(IBaseBsn),             typeof(BaseBsn<>));
services.ConfigureByBaseInterfaceAndBaseClass(typeof(IRepository),          typeof(BaseRepository<,>));
services.ConfigureByBaseInterfaceAndBaseClass(typeof(ICustomOptions),       typeof(BaseCustomOptionsConfig<>), true);
services.ConfigureByBaseInterfaceAndBaseClass(typeof(IBaseRepositoryCache), typeof(BaseRepositoryCache), false);
services.ConfigureByBaseInterfaceAndBaseClass(typeof(IBaseMessagingService),typeof(BaseMessagingService<>));
```

```csharp
private static void ConfigureByBaseInterfaceAndBaseClass(
    this IServiceCollection services,
    Type interfaceBaseMap, Type classBaseMap, bool implementBaseInterface = false)
{
    var queryClassesForMap = AppDomain.CurrentDomain.GetAssemblies()
       .SelectMany(x => x.GetTypes())
       .Where(x => x.IsClass && !x.IsAbstract && !x.IsInterface)
       .Where(x => x.BaseType is not null)
       .Where(x => x.GetInterfaces().Any(y => y == interfaceBaseMap));

    if (classBaseMap.IsGenericType)
        queryClassesForMap = queryClassesForMap
            .Where(x => x.IsSubclassOfGenericClass(classBaseMap.GetGenericTypeDefinition()));
    else
        queryClassesForMap = queryClassesForMap
            .Where(x => !x.BaseType.IsGenericType)
            .Where(x => x.IsSubclassOfGenericClass(classBaseMap));
    // ...
}
```

**Ganho:** classe nova entra no container só por herdar da base certa. Sem esquecer registro,
sem merge conflict eterno no arquivo de IoC.
**Custo:** o container fica "mágico"; erro de convenção só aparece em runtime.
**Mitigação:** um teste que resolve o grafo inteiro no boot.

---

### 4.2 Ciclo de vida declarado por marker interface

O lifetime não é decidido no arquivo de IoC — é decidido pela própria classe, implementando interface vazia:

```csharp
namespace Common.Interfaces
{
    public interface ISingletonInstance { }
    public interface ITransientInstance { }
    // ausência das duas = Scoped (default)
}
```

```csharp
var isSingletonInstance = typeof(ISingletonInstance).IsAssignableFrom(classForMap);
var isTransientInstance = typeof(ITransientInstance).IsAssignableFrom(classForMap);

if (isSingletonInstance)       services.AddSingleton(classForMap);
else if (!isTransientInstance) services.AddScoped(classForMap);

foreach (var interfaceForMap in interfacesForMap)
{
    if (isSingletonInstance)
        services.AddSingleton(interfaceForMap, sp => sp.GetRequiredService(classForMap));
    else if (!isTransientInstance)
        services.AddScoped(interfaceForMap, sp => sp.GetRequiredService(classForMap));
    else
        services.AddTransient(interfaceForMap, classForMap);
}
```

**Sutileza que salva bug:** a classe concreta é registrada uma vez, e cada interface resolve
**para a mesma instância** (`sp => sp.GetRequiredService(classForMap)`). Sem isso, um serviço que
implementa 3 interfaces viraria 3 objetos distintos no mesmo escopo — falha silenciosa e difícil de achar.

---

### 4.3 `BaseBsn<T>`: service locator preguiçoso com cache

O maior truque de ergonomia do projeto. Um BSN com 25 dependências não tem construtor com 25 parâmetros:

```csharp
public abstract class BaseBsn<TBsn> where TBsn : BaseBsn<TBsn>, IBaseBsn
{
    private static readonly ConcurrentDictionary<string, SemaphoreSlim> _semaphores = new();
    private readonly ConcurrentDictionary<Type, object> _services = new();

    protected readonly IServiceProvider ServiceProvider;

    protected IHostEnvironment       _hostEnvironment => GetServiceSingleton<IHostEnvironment>();
    protected ILogger<TBsn>          _logger         => GetServiceSingleton<ILogger<TBsn>>();
    protected IMapper                Mapper          => GetServiceSingleton<IMapper>();
    protected IDomainConfig          DomainConfig    => GetServiceSingleton<IDomainConfig>();
    protected IMessageDomainService  MessageDomain   => GetServiceSingleton<IMessageDomainService>();
    protected WhgContext             WhgContext      => GetServiceSingleton<WhgContext>();

    protected BaseBsn(IServiceProvider serviceProvider) => ServiceProvider = serviceProvider;

    protected TService GetServiceSingleton<TService>() =>
        (TService)_services.GetOrAdd(typeof(TService), ServiceProvider.GetRequiredService<TService>());

    protected IGenericReadRepository<TEntity>  GetReadRepository<TEntity>()  where TEntity : class, IEntity
        => GetServiceSingleton<IGenericReadRepository<TEntity>>();
    protected IGenericWriteRepository<TEntity> GetWriteRepository<TEntity>() where TEntity : class, IEntity
        => GetServiceSingleton<IGenericWriteRepository<TEntity>>();
}
```

Na classe filha, cada dependência específica vira **uma linha nomeada** no topo:

```csharp
public class ExtracaoDinamicaBsn : BaseBsn<ExtracaoDinamicaBsn>, IExtracaoDinamicaBsn
{
    private ICustomOptions<ExtracaoDinamicaCustomOptions> CustomOptions
        => GetServiceSingleton<ICustomOptions<ExtracaoDinamicaCustomOptions>>();

    private IExtracaoDinamicaRepository ExtracaoDinamicaRepository
        => GetServiceSingleton<IExtracaoDinamicaRepository>();

    public ExtracaoDinamicaBsn(IServiceProvider serviceProvider) : base(serviceProvider) { }
```

**Trade-off honesto:** isto é Service Locator, um anti-pattern clássico. Esconde as dependências reais
da classe e dificulta teste unitário (você mocka um `IServiceProvider`, não parâmetros explícitos).
Num grafo com ~200 BSNs interdependentes, resolve dor real de dependência circular e de construtor gigante —
mas é justamente o que permite uma classe crescer até 12 mil linhas sem que ninguém sinta.

**Como copiar com segurança:** mantenha o construtor explícito para dependências de negócio e use
propriedades preguiçosas só para transversais (logger, mapper, config). Você fica com a legibilidade
sem perder a visibilidade do acoplamento.

---

### 4.4 `BaseBsn` como toolkit de concorrência

Além do locator, a base entrega primitivas que todo BSN herda de graça.

**Lock nomeado (in-process):**

```csharp
protected static async Task<T> ExecuteWithLockAsync<T>(string keyLock, Func<Task<T>> func,
    CancellationToken cancellationToken = default)
{
    var semaphore = _semaphores.GetOrAdd(keyLock, new SemaphoreSlim(1, 1));
    await semaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
    try   { return await func.Invoke().ConfigureAwait(false); }
    finally { semaphore.Release(); }
}
```

**Retry seletivo** — só reprocessa 504 e timeout, o resto propaga imediatamente:

```csharp
protected async Task<TResult> ExecuteWithRetryAsync<TResult>(Func<Task<TResult>> func,
    int attempts = 5, CancellationToken cancellationToken = default)
{
    for (int i = 0; i < attempts; i++)
    {
        cancellationToken.ThrowIfCancellationRequested();
        try { return await func.Invoke().ConfigureAwait(false); }
        catch (CustomHttpRequestException ex)
        {
            if (ex.StatusCode == HttpStatusCode.GatewayTimeout && i <= attempts)
            {
                _logger.LogError(ex, "Endpoint retornando 504, nova tentativa será efetuada");
                continue;
            }
            throw;
        }
        catch (Exception ex)
        {
            if (ex.Message?.ToLower().Contains("timeout") == true && i <= attempts) continue;
            throw;
        }
    }
    return default;
}
```

**Lote e paralelismo com throttle:**

```csharp
protected static Task<List<TResult>> ExecuteInBatchAsync<TInput, TResult>(
    Func<List<TInput>, Task<List<TResult>>> func, List<TInput> listExecution, int batchSize);

protected static async Task<List<TResult>> ExecuteInChunkInParallelAsync<TInput, TResult>(
    Func<List<TInput>, Task<List<TResult>>> func, List<TInput> listExecution,
    int chunckSize, int threadPoolSize, CancellationToken cancellationToken = default)
{
    var throttler = new SemaphoreSlim(initialCount: threadPoolSize);

    foreach (var partialExecutions in listExecution.ChunkBy(chunckSize))
    {
        await throttler.WaitAsync(cancellationToken);
        listTask.Add(Task.Run(async () =>
        {
            try   { return await func.Invoke(partialExecutions); }
            finally { throttler.Release(); }
        }));
    }

    await Task.WhenAll(listTask);
    // ...
}
```

Para um sistema que faz carga em massa de preços, posições e trades, ter isso na base evita
reimplementação (e reimplementação errada) em cada BSN.

---

### 4.5 Autorização data-driven por path

O `ApplicationApiHandler` (um `IActionFilter` global) não usa policies em código. Ele cruza
**grupos do Azure AD** (claim `groups`) com tabelas de autorização, comparando o **path da requisição**
contra um `HashSet<string>` de URLs permitidas:

```csharp
hashAutorizacaoGrupoFuncionalidadeApi =
    (from func in listAutorizacaoFuncionalidade
     join autorizacaoApi in _context.TbAutorizacaoFuncionalidadeApi
        on func.CodFuncionalidade equals autorizacaoApi.CodFuncionalidade
     join api in _context.TbAutorizacaoApi on autorizacaoApi.IdApi equals api.IdApi
     where api.UrlApi is not null && api.CodAplicacao == _productName
     select api.UrlApi.ToLower()).Distinct().ToHashSet();
```

Modelo de dados:

```
Azure AD (claim "groups")
   → Tb_Autorizacao_Grupo
      → Tb_Autorizacao_Grupo_Funcionalidade → Tb_Autorizacao_Funcionalidade
         → Tb_Autorizacao_Funcionalidade_Api → Tb_Autorizacao_Api (UrlApi, CodAplicacao)
      → Tb_Grupo_Acesso_Cliente / Tb_Grupo_Acesso_Cliente_Excecao   (acesso a DADOS)
```

Duas dimensões separadas e independentes:

- **Funcional** — pode chamar este endpoint?
- **De dados** — quais clientes/contas este usuário enxerga? (`GrupoAcessoCliente` + lista de exceções)

Tudo cacheado em `IMemoryCache` por e-mail (24h na API interna, 1h na externa), com uma chave-índice
(`TbAutorizacaoAllKeys`) registrando todas as chaves para invalidação posterior. Há trilha separada para
usuário externo (`TbAutorizacaoUsuarioExterno` + `FlPermiteUsuExterno` na API) e um escape hatch:

```csharp
public class SkipAuthenticationControllerHandler : Attribute { }
```

O filtro também aplica o acesso de dados no BSN de autorização, para as queries filtrarem por cliente:

```csharp
_autorizacaoBsn.Funcionalidades           = listAutorizacaoFuncionalidade;
_autorizacaoBsn.GrupoAcessoCliente        = listGrupoAcessoCliente;
_autorizacaoBsn.GrupoAcessoClienteExcecao = listGrupoAcessoClienteExcecao;
```

E as controllers consomem isso naturalmente:

```csharp
var _accessTpClient = _autorizacaoBsn.HasAccessTpCliente(_autorizacaoBsn.Funcionalidades);
var ListClientesAutorizados = _clienteBsn.GetContasByColaborares();

var queryBoletas = _context.TbBoleta
    .Where(b => _accessTpClient.Contains(b.IdClienteNavigation.TpVeiculo))
    .Where(b => ListClientesAutorizados.Contains((int)b.IdClienteNavigation.IdConta));
```

**Ganho real:** conceder acesso a um endpoint novo é `INSERT` em tabela — sem deploy.

---

### 4.6 Exceções de domínio → HTTP status em um lugar só

O mesmo filtro converte exceção em resposta HTTP no `OnActionExecuted`. É por isso que muitas controllers
não precisam de `try/catch`:

| Exceção | Status HTTP |
|---|---|
| `CustomNotFoundException` | 404 Not Found |
| `CustomConflictException` | 409 Conflict |
| `CustomValidationException` | 400 Bad Request |
| `CustomForbiddenException` | 400 Bad Request |
| qualquer outra | 500 + `LogError` |

Hierarquia enxuta, tudo herdando de `CustomException`, com `CustomObject` para payload estruturado:

```csharp
public class CustomException : Exception
{
    public object CustomObject { get; set; }

    public CustomException(string message, Exception innerException, object customObject)
        : base(message, innerException) => CustomObject = customObject;
}
```

Quando o `InnerException` é `AggregateException`, ele é explodido em `Items[]` — o front recebe **todos**
os erros de uma vez, cada um com seu payload:

```csharp
objectResult = new ObjectResult(new
{
    ex.Message,
    Items = aggregateException.InnerExceptions.Select(x =>
    {
        if (x is CustomException customException)
            return (object)new { x.Message, customException.CustomObject };
        return new { x.Message };
    }).ToList()
});

objectResult.StatusCode = (int)statusCode;
context.Result = objectResult;
context.ExceptionHandled = true;
```

O filtro ainda cronometra cada request com `Stopwatch` guardado por `TraceIdentifier`.

**Dividendo inesperado:** essa taxonomia consistente permite que o monitoramento (seção 7.4) exclua
erro de negócio da taxa de falha do sistema — `CustomValidationException` não conta como incidente.

---

### 4.7 Erro de SQL traduzido para linguagem de negócio

No `BaseDbContext.SaveChanges`, `SqlException` vira mensagem para humano, com regex extraindo
tabela/coluna/constraint da mensagem do servidor:

```csharp
private static void HandleExceptions(Exception exception)
{
    if (exception is DbUpdateException dbUpdateEx &&
        dbUpdateEx.InnerException is SqlException sqlException)
    {
        switch (sqlException.Number)
        {
            case 547:  // Foreign Key constraint violation
                var constraint = sqlException.Message?.GetRegexCaptureGroup(@"constraint\s+""(?<constraint>[^""]+)""", "constraint");
                var table      = sqlException.Message?.GetRegexCaptureGroup(@"table\s+""[^.]*\.(?<table>[^""]+)""", "table");
                var column     = sqlException.Message?.GetRegexCaptureGroup(@"column\s+'(?<column>[^""]+)'", "column");

                throw new CustomConflictException(
                    "Não é possível inserir/excluir este registro porque há referências relacionadas a ele.",
                    new CustomConflictException($"...tabela: '{table}', campo: '{column}', constraint: '{constraint}'."));

            case 2627: // Unique constraint
            case 2601: // Duplicated key
                throw new CustomConflictException($"O valor '{valueUK}' já existe na base.");

            case 2628: // String or binary data would be truncated
                throw new CustomConflictException($"O valor informado é muito longo para o campo '{truncColumn}'...");
        }
    }
    throw exception;
}
```

Combinado com o item anterior, uma FK violada vira **409 com mensagem legível**, sem uma linha de
validação defensiva na aplicação.

---

### 4.8 Auditoria automática em dois níveis

**Nível 1 — autoria (quem mexeu).** O `CommonBaseDbContext` intercepta o `ChangeTracker`:

```csharp
public override Task<int> SaveChangesAsync(bool acceptAllChangesOnSuccess, CancellationToken ct = default)
{
    CustomSaveChanges();
    return base.SaveChangesAsync(acceptAllChangesOnSuccess, ct);
}

private void CustomSaveChanges()
{
    IDomainConfig domainConfig = null;

    foreach (var e in GetEntities<IIdUsuEntity>(EntityState.Added))
        if (e.IdUsu == null)
        {
            domainConfig ??= this.GetService<IDomainConfig>();
            e.IdUsu = domainConfig.CurrentUserId;
        }

    foreach (var e in GetEntities<IIdUsuCriacaoEntity>(EntityState.Added))
        if (e.IdUsuCriacao == null) { /* idem */ }
}
```

O `IDomainConfig` vem do middleware (request HTTP) ou de `ConfigureDefaultUserPrisma()` (WebJob) —
**auditoria coerente entre request e batch**.

**Nível 2 — histórico (o que mudou).** No `BaseEntityMap`, qualquer entidade `IDtCpuEntity` vira
**temporal table do SQL Server** automaticamente:

```csharp
if (MigrationState.IsDesignTime && typeof(IDtCpuEntity).IsAssignableFrom(typeof(TEntity)))
{
    builder.ToTable(x => x.IsTemporal(b =>
    {
        b.HasPeriodStart("Dt_Cpu");
        b.HasPeriodEnd("Dt_Cpu_Fim");
        b.UseHistoryTable($"{_name}_Log", _schema);
    }));
}
```

**Implementar uma interface vazia numa entidade gera versionamento completo de linha, no motor do banco.**
Existe até um `CustomMigrationsSqlGenerator` que reescreve o DDL removendo `HIDDEN` das colunas de período.

---

### 4.9 Configuração em camadas, com segredo criptografado

`BaseCustomOptionsConfig<T>` monta options em cascata:

```
appsettings.Common.json
   → appsettings.{Environment}.json
      → Tb_Configuracao (JSON por chave e por aplicação, no banco)
         → override específico da aplicação
```

```csharp
protected async Task LoadOptionsFromOnlyDatabaseAsync(bool onlyApplication, CancellationToken ct = default)
{
    var configs = await _configuracaoRepository.GetConfigsByKeyAsync(ChaveOptions, _productName, ct);

    configs = configs.EmptyIfNull()
        .Where(x => !x.JsOpcoes.IsNullOrEmpty())
        .OrderBy(x => x.NmAplicacao.IsNullOrEmpty() ? 0 : 1)   // genérico primeiro, específico sobrepõe
        .ToList();

    _current ??= new();

    foreach (var config in configs)
        JsonConvert.PopulateObject(config.JsOpcoes, _current, new JsonSerializerSettings
        {
            Converters = new[] { new PasswordVOConverter(_encryptionKeysOptions.Value?.GenericEncryptKey, true) }
        });
}
```

**Senha como Value Object:**

```csharp
public class PasswordVO
{
    private string _password;
    public  string _encryptedPassword;

    public PasswordVO(string encryptKey, bool encrypted, string password)
    {
        if (encrypted) { _encryptedPassword = password; _password = password.Decrypt(encryptKey); }
        else           { _password = password; _encryptedPassword = password.Encrypt(encryptKey); }
    }

    public string EncryptedPassword => _encryptedPassword;
    public string GetPassword() => _password;
}
```

**Dois detalhes finos:**

```csharp
public T Current => (T)_current?.Clone();   // ninguém muda a config do singleton por acidente
```

```csharp
// OptionsStartupTask: fail fast no boot se uma option Required falhar
if (erros.Any()) throw new AggregateException("Erros ao carregar Options", erros);
```

Existem ~35 arquivos `*OptionsConfig.cs` — cada feature grande tem configuração dinâmica, alterável em
produção sem deploy.

**Feature flag trocando implementação no container:**

```csharp
services.AddScoped<IXpAuthService>(serviceProvider =>
{
    var xpNewAuthOptions = serviceProvider.GetRequiredService<ICustomOptions<XpNewAuthCustomOptions>>();

    if (xpNewAuthOptions.Current?.FlNovaAuthXp == true)
        return ActivatorUtilities.CreateInstance<XpNewAuthService>(serviceProvider);

    return ActivatorUtilities.CreateInstance<XpAuthService>(serviceProvider);
});
```

Migração de autenticação de parceiro com rollback por flag no banco. Sem branch, sem deploy.

---

### 4.10 Cache em dois níveis com compressão

`BaseRepositoryCache`:

- **L1** — memoização por escopo com `ConcurrentDictionary<string, Lazy<Task<object>>>`, que mata
  *cache stampede* dentro da mesma request
- **L2** — Redis (`StackExchange.Redis`)

```csharp
private readonly ConcurrentDictionary<string, Lazy<Task<object>>> _cacheMemoryScope = new();

public async Task<T> GetOrSetObjectWithMemoryScopeAsync<T>(string key, Func<T> funcObj, ...)
{
    return (T)await _cacheMemoryScope
        .GetOrAdd(key, x => new Lazy<Task<object>>(async () =>
            await GetOrSetObjectAsync(key, funcObj, expiry, skipCache, throwIfError, cancellationToken)))
        .Value;
}
```

**Objetos grandes vão comprimidos** (`GetOrSetLargeObjectAsync` + GZip):

```csharp
static byte[] Compress(string value)
{
    using var output = new MemoryStream();
    using (var gz = new GZipStream(output, CompressionLevel.Optimal)) { /* ... */ }
    return output.ToArray();
}
```

Mais: timeout próprio por repositório via `CancellationTokenSource.CancelAfter(GetDefaultTimeout())`,
kill-switch global (`ConfigCache:DesativarCache`), e política de que **falha de cache é logada,
nunca propagada** — a menos que se peça `throwIfError: true`:

```csharp
catch (Exception ex)
{
    if (throwIfError) throw;
    _logger.LogError(ex, $"Erro gravar cache chave: {key}");
}
```

Repositórios concretos: `PosicaoRepositoryCache`, `ConsolidacaoRepositoryCache`, `AtivoCotacaoRepositoryCache`,
`DaysRepositoryCache`, `CapitalComprometidoRepositoryCache`, `SystemRepositoryCache` — cada um com seu
`GetDefaultExpiry()` / `GetDefaultTimeout()`.

---

### 4.11 Um único `ProgramFactory` para 17 WebJobs

O `Program.cs` de cada job tem 6 linhas:

```csharp
class Program
{
    public static async Task Main(string[] args)
    {
        var factory = new ProgramFactory<Program>(args);
        factory.AddWorker<FilaProcessamentoWorker>();
        await factory.StartAsync().ConfigureAwait(false);
    }
}
```

A fábrica centraliza configuração, logging, Application Insights, startup tasks,
`domainConfig.ConfigureDefaultUserPrisma()` e shutdown. Quatro coisas que raramente se vê feitas direito:

**a) Cron dentro do worker (NCrontab).** O Azure dispara de 5 em 5 minutos; o worker decide se é a
*sua* janela — e a agenda vem do banco, mudável sem deploy:

```csharp
CrontabSchedule schedule = CrontabSchedule.Parse(_workerConfig.CronJob);
DateTime nextRun = schedule.GetNextOccurrence(currentTimeForCron);

var canExecute = currentTime >= nextRun && currentTime <= nextRun.AddMinutes(5);
if (!canExecute)
{
    _logger.LogInformation($"Não está no período de execução. Próxima execução: {nextRun:dd/MM/yyyy HH:mm}");
    return;
}
```

**b) Shutdown gracioso do Azure WebJobs** — o sinal oficial é um arquivo:

```csharp
var pathShutdownFile = Environment.GetEnvironmentVariable("WEBJOBS_SHUTDOWN_FILE");

using var watcher = new FileSystemWatcher(dir) { Filter = file, EnableRaisingEvents = true };
watcher.Created += (_, __) => { Console.WriteLine("[STOP] Shutdown signal..."); Cancel(); };

Console.CancelKeyPress              += (_, e) => { e.Cancel = true; Cancel(); };
AppDomain.CurrentDomain.ProcessExit += (_, __) => Cancel();
```

**c) Heartbeat** a cada 30s no stdout, para o job não parecer travado no log:

```csharp
while (!cts.IsCancellationRequested)
{
    Console.WriteLine($"[HB] {DateTime.UtcNow:o}");
    await Task.Delay(TimeSpan.FromSeconds(30), cts.Token);
}
```

**d) Flush do telemetry no `finally`** — sem isso, log de job curto simplesmente se perde:

```csharp
var cancelSource = new CancellationTokenSource();
cancelSource.CancelAfter(TimeSpan.FromMinutes(1));

await host.Services.GetRequiredService<TelemetryClient>().FlushAsync(cancelSource.Token);
await Task.Delay(TimeSpan.FromSeconds(5), cancelSource.Token); // necessário por conta do flush
```

**Consumers de Service Bus** usam a mesma fábrica (`isBusConsumers: true`) com `BaseWebJobBusConsumer`:

```csharp
var options = new ServiceBusProcessorOptions
{
    MaxConcurrentCalls          = _consumerConfig.MaxConcurrentCalls ?? 1,
    PrefetchCount               = _consumerConfig.Prefetch ?? 1,
    AutoCompleteMessages        = false,                     // complete manual
    MaxAutoLockRenewalDuration  = TimeSpan.FromMinutes(_consumerConfig.LockRenewalMinutes ?? 10)
};
```

Cada mensagem cria seu próprio escopo de DI e, em erro, é abandonada com a exceção anexada:

```csharp
using var scope = _serviceProvider.CreateScope();

await _logger.ExecuteWithLogTimerAsync("processamento mensagem", true, async () =>
{
    var bodyMessage = args.Message.Body.ToObjectFromJson<TContract>();
    var handler = ActivatorUtilities.CreateInstance<THandler>(scope.ServiceProvider);
    await handler.HandleAsync(bodyMessage, args.CancellationToken);
    await args.CompleteMessageAsync(args.Message);
})
.HandleExceptionAsync<Exception>(async ex =>
{
    var options = new Dictionary<string, object> { { "Exception", ex.ToString() } };
    await args.AbandonMessageAsync(args.Message, options);
});
```

E o produtor carimba metadados padronizados em toda mensagem:

```csharp
serviceBusMessage.CorrelationId = Guid.NewGuid().ToString();
serviceBusMessage.ApplicationProperties["MessageType"] = typeof(T).Name;
serviceBusMessage.ApplicationProperties["RequestUser"] = _domainConfig.CurrentUserId;
serviceBusMessage.ApplicationProperties["NmAplicacao"] = productName;
```

---

### 4.12 Fila de processamento no banco

Além do Service Bus, existe uma fila em tabela — o backbone das operações longas (consolidação, relatórios):

```csharp
public class TbFilaProcessamento : IIdUsuEntity, IDtCpuEntity
{
    public int       IdFilaProcessamento { get; set; }
    public string    TpProcessamento { get; set; }
    public int       IdFilaProcessamentoStatus { get; set; }
    public string    JsonRequest { get; set; }              // payload livre
    public DateTime  DtEntradaFila { get; set; }
    public DateTime? DtInicioProcessamento { get; set; }
    public DateTime? DtFimProcessamento { get; set; }
    public int       NrPrioridade { get; set; }             // priorização
    public string    IdUsuSolicitacao { get; set; }
    public int?      IdFilaProcessamentoPai { get; set; }   // hierarquia pai/filho

    public virtual ICollection<TbFilaProcessamentoArquivo>      TbFilaProcessamentoArquivo { get; set; }
    public virtual ICollection<TbFilaProcessamentoLogAtividade> TbFilaProcessamentoLogAtividade { get; set; }
    public virtual ICollection<TbFilaProcessamento>             TbFilaProcessamentoFilho { get; set; }
}
```

O usuário enfileira pelo endpoint e acompanha status/log/arquivos gerados. O disparo tem **dois modos
alternáveis por config**: polling ou **Azure Web PubSub via WebSocket** (`IsByPubSub`).

**Exclusão mútua entre instâncias** (o semáforo do `BaseBsn` só protege in-process):

```csharp
public class SqlServerDistributedLock : IDistributedLock
{
    public async Task ExecuteWithLockAsync(string resourceName, Func<Task> action,
        TimeSpan? timeout = null, CancellationToken cancellationToken = default)
    {
        var lockProvider = new SqlDistributedSynchronizationProvider(_connectionString);
        var lockHandle = lockProvider.CreateLock(resourceName);

        await using (await lockHandle.AcquireAsync(timeout ?? TimeSpan.FromMinutes(1), cancellationToken))
            await action();
    }
}
```

---

### 4.13 Bônus: detalhes de infraestrutura que valem nota

**12 DbContexts, uma connection string** — bounded contexts dentro do mesmo banco, sem microserviço:

```csharp
services.AddDbContext<ArquivoDePosicaoContext>(UseSqlServer);   // schema xml
services.AddDbContext<WhgContext>(UseSqlServer);                // schema dbo
services.AddDbContext<XpPosiContext>(UseSqlServer);             // schema xp_posi
services.AddDbContext<CreditoContext>(UseSqlServer);            // schema credito
services.AddDbContext<SocietarioContext>(UseSqlServer);         // schema societario
services.AddDbContext<ReceitaContext>(UseSqlServer);            // schema receita
services.AddDbContext<LiveContext>(UseSqlServer);               // schema live
// + FinanceiroContext, OutSystemsContext, ImbarqContext, SignatureContext
services.AddDbContext<DatalakeDboContext>(UseSqlServerDatalake); // outro banco
```

Isola modelo e change tracker por domínio com custo operacional zero. Forma barata e honesta de
modularizar um monólito. Timeout parametrizável por processo (API 180s; jobs podem pedir mais).

**Repositórios genéricos ricos** — `IGenericWriteRepository<T>` cobre operações em massa:

```csharp
Task BulkCreateAsync(IList<TEntity> entities, CancellationToken ct = default);
Task BulkUpdateAsync(IList<TEntity> entities, Action<BulkConfigDto> action, CancellationToken ct = default);
Task BulkDeleteAsync(IList<TEntity> entities, CancellationToken ct = default);

Task<int> BatchUpdateAsync(Expression<Func<TEntity,bool>> expression,
                           Expression<Func<TEntity,TEntity>> expressionUpdate, CancellationToken ct = default);
Task<int> BatchDeleteAsync(Expression<Func<TEntity,bool>> expression, CancellationToken ct = default);
```

`Bulk*` usa EFCore.BulkExtensions; `Batch*` gera `UPDATE`/`DELETE` direto no banco, sem materializar
entidade — essencial em carga de preços e posições.

**Certificados mTLS baixados de Blob no boot** (`LoadCertificatesStartupTask`), com handlers HTTP
dedicados por parceiro. O da XP **falha rápido** em vez de subir handler sem certificado:

```csharp
if (!certificate.HasPrivateKey)
    throw new InvalidOperationException($"Cert XP carregado SEM chave privada. Thumbprint={certificate.Thumbprint}");

if (expirado)
    throw new InvalidOperationException($"Cert XP EXPIRADO. NotAfter={certificate.NotAfter}");
// ...
catch (Exception ex)
{
    log.LogError(ex, "Erro ao carregar certificado Xp IoC");
    throw; // falha rapido em vez de subir handler sem cert -> 401 silencioso
}
```

O comentário no código diz tudo: sem isso, o sintoma seria um 401 misterioso em produção.

**Swagger filtrado por atributo** na API externa — só endpoints marcados aparecem na doc pública:

```csharp
public class CustomSwaggerFilter : IDocumentFilter
{
    public void Apply(OpenApiDocument swaggerDoc, DocumentFilterContext context)
    {
        // coleta paths cujos métodos têm [ShowExternalSwagger]
        var nonPublic = swaggerDoc.Paths.Where(x => !apis.Contains(x.Key.ToLower())).ToList();
        nonPublic.ForEach(x => swaggerDoc.Paths.Remove(x.Key));
    }
}

public class ShowExternalSwagger : Attribute { }
```

Uma API, duas superfícies: tudo funciona, só parte é anunciada.

---
---

# PARTE III — LEGIBILIDADE

## 5. A tese: estrutura em vez de documentação

Este backend **não** é legível por ter documentação — tem 4% de cobertura de `/// <summary>` na API interna
e `#region` em 11% das controllers. Ele é legível por outro caminho:
**conhecimento estrutural em vez de conhecimento textual**.

| Abordagem | Como você descobre uma coisa |
|---|---|
| Documentação (texto) | Lendo um `.md` que pode estar desatualizado |
| **Estrutura (este projeto)** | Olhando onde o arquivo está e como ele se chama |

A aposta: **caminho de pasta + nome de arquivo + nome de tipo** carregam a informação melhor que prosa.
E o projeto leva isso ao extremo — 1.353 arquivos em `Domain`, uma classe por arquivo, quase todos com
menos de 50 linhas.

O resultado é que você responde perguntas **sem abrir arquivo nenhum**:

```
"Onde fica a regra de negócio de consolidação?"
  → Core/Application/BSN/Consolidacao/

"Qual o contrato de entrada do ranking?"
  → Core/Application/Models/Portfolio/GetRankingRequest.cs

"Como a tabela Tb_Boleta é mapeada?"
  → Core/Repository.SqlServer/Mappings/Whg/Boletas/TbBoletaMap.cs

"O que mudou no banco na release 70?"
  → Database/Creates and Drops/v70_MelhoriasConsolidacaoContaRelGlobal/
```

Isso é navegação por **dedução**, não por busca. E é o que sustenta um monólito de 380 mil linhas
com dezenas de desenvolvedores.

---

## 6. As 8 técnicas de legibilidade

### 6.1 Espelhamento de árvore entre camadas

A mesma feature ocupa o mesmo caminho relativo em todas as camadas:

```
Feature "Extração Dinâmica" vive em 8 lugares, com o MESMO nome:

Core/Application/BSN/ExtracaoDinamicaBsn.cs
Core/Application/Interfaces/BSN/IExtracaoDinamicaBsn.cs
Core/Application/Models/ExtracaoDinamica/         ← contratos da API
Core/Application/DTOs/ExtracaoDinamica/           ← transporte interno
Core/Domain/Entities/ExtracaoDinamica/            ← entidade
Core/Domain/DTOs/ExtracaoDinamica/
Core/Domain/Enums/ExtracaoDinamica/
Core/Repository.SqlServer/Mappings/Whg/ExtracaoDinamica/
PrismaService/Controllers/DevEx/Utils/ExtracaoDinamicaController.cs
```

Você aprende **um** caminho e ganha os outros sete de graça. É convenção-sobre-configuração aplicada à
árvore de diretórios em vez do container de DI. Vale igual para `Consolidacao`, `Movimentacao/Boletas`,
`Cadastro/Ativos`, `CRM`, `Ips`, `Compliance`, `Receita`.

---

### 6.2 Prefixo de tipo como namespace visual

| Prefixo | Significa | Onde vive |
|---|---|---|
| `Tb*` | Entidade mapeada para tabela | `Domain/Entities/` |
| `View*` | Entidade mapeada para view (read model) | `Domain/Entities/Views/` |
| `Tbe*` | Entidade do Datalake | `Repository.Datalake/Mappings/` |
| `Raw*` | Dado bruto ingerido (B3, IBGE) | `Repository.Datalake/Mappings/` |
| `I*Bsn` | Contrato de regra de negócio | `Application/Interfaces/BSN/` |
| `*Bsn` | Regra de negócio | `Application/BSN/` |
| `*Request` / `*Response` | Contrato de API | `Application/Models/<Feature>/` |
| `*Dto` | Transporte interno (não sai na API) | `Application/DTOs/`, `Domain/DTOs/` |
| `E*` | Enum | `Domain/Enums/`, `Application/Enums/` |
| `Custom*Exception` | Exceção de domínio | `Common/Exceptions/` |
| `Base*` | Classe base abstrata | qualquer camada |
| `*Map` | Configuração EF Core | `Repository.*/Mappings/` |
| `*OptionsConfig` | Configuração dinâmica | `IoC/CustomOptions/` |
| `HealthCheck*` | Verificação de saúde | `PrismaService/HealthCheck/` |
| `WebJob*` | Processo background | `Jobs/` |

`TbeAumConsolidado` diz "entidade de Datalake, AUM consolidado" antes de você ler uma linha.
`RawB3Instruments` diz "dado cru da B3, ainda não tratado".

**Ganho:** um `Ctrl+T` por `Tb` lista o modelo de dados inteiro. Por `Bsn`, a lista de regras de negócio.
Por `Request`, todos os contratos de entrada.

---

### 6.3 Prefixo de coluna do banco no nome da propriedade

O padrão vem do modelo de dados e sobe até o C#:

```csharp
public class TbFilaProcessamento : IIdUsuEntity, IDtCpuEntity
{
    public int      IdFilaProcessamento { get; set; }        // Id_   → chave
    public string   TpProcessamento { get; set; }            // Tp_   → tipo/categoria
    public string   JsonRequest { get; set; }                // Json_ → payload serializado
    public DateTime DtEntradaFila { get; set; }              // Dt_   → data
    public int      NrPrioridade { get; set; }               // Nr_   → número
}
```

Vocabulário completo: `Id_`, `Nm_` (nome), `Cd_` (código), `Dt_` (data), `Vlr_` (valor),
`Qtd_`/`Nr_` (quantidade/número), `Tp_` (tipo), `Fl_`/`Ind_` (flag/indicador), `Perc_` (percentual),
`Json_` (JSON), `Bit_` (bitmask).

Você lê `PercMaximo`, `VlrBoleta`, `FlAtivo`, `DtLiquidacao` e sabe o tipo antes de ver a declaração.
Num domínio financeiro cheio de campo numérico, isso elimina uma classe inteira de erro de leitura.

---

### 6.4 Interfaces marcadoras como documentação executável

São 51 interfaces em `Domain/Entities/*.cs`, quase todas vazias ou com uma propriedade:

```csharp
public interface IEntity { }
public interface IIdUsuEntity : IEntity { public string IdUsu { get; set; } }
public interface IDtCpuEntity : IEntity { /* Dt_Cpu / Dt_Cpu_Fim */ }
public interface IFlAtivoEntity : IEntity { /* Fl_Ativo */ }
public interface IIdClienteEntity : IEntity { }
public interface IValorCotaEntity : IEntity { }
public interface IPuEntity : IEntity { }
public interface ITaxaIndicativaEntity : IEntity { }
// ... + 43
```

A declaração da entidade vira uma **ficha técnica**:

```csharp
public class TbExtracaoDinamica : IIdUsuEntity, IDtCpuEntity
```

Essa linha diz, sem comentário nenhum: *"tem autoria automática, tem histórico temporal no banco,
o mapping configura as colunas transversais sozinho"*. E não é decorativo — cada interface dispara
comportamento real:

```csharp
public static void ConfiguraBaseEntity<TEntity>(this EntityTypeBuilder<TEntity> builder)
    where TEntity : class, IEntity
{
    var genericArgument = builder.GetType().GetGenericArguments().First();

    if (typeof(IIdUsuEntity).IsAssignableFrom(genericArgument))
        builder.CallMethodInterfaceEntity(genericArgument, nameof(ConfigureIIdUsuEntity));

    if (typeof(IDtCpuEntity).IsAssignableFrom(genericArgument))
        builder.CallMethodInterfaceEntity(genericArgument, nameof(ConfigureIDtCpuEntity));

    if (typeof(IIdUsuCriacaoEntity).IsAssignableFrom(genericArgument))
        builder.CallMethodInterfaceEntity(genericArgument, nameof(ConfigureIIdUsuCriacaoEntity));

    if (typeof(IDtCriacaoEntity).IsAssignableFrom(genericArgument))
        builder.CallMethodInterfaceEntity(genericArgument, nameof(ConfigureIDtCriacaoEntity));

    if (typeof(IFlAtivoEntity).IsAssignableFrom(genericArgument))
        builder.CallMethodInterfaceEntity(genericArgument, nameof(ConfigureIFlAtivoEntity));
}
```

No mapping, uma linha resolve tudo:

```csharp
builder.ConfiguraBaseEntity();
```

**Documentação que não pode mentir**, porque se ela mentisse o comportamento mudava.

---

### 6.5 Dependências como propriedades nomeadas

Efeito colateral **bom** do service locator. O topo da classe vira um índice legível:

```csharp
private ICustomOptions<ExtracaoDinamicaCustomOptions> CustomOptions
    => GetServiceSingleton<ICustomOptions<ExtracaoDinamicaCustomOptions>>();

private IExtracaoDinamicaRepository ExtracaoDinamicaRepository
    => GetServiceSingleton<IExtracaoDinamicaRepository>();
```

Comparado ao construtor real do `ConsolidacaoController`:

```csharp
public ConsolidacaoController(PortfolioBsn portfolioBsn, IDomainBsn domainBsn,
    ILogger<ConsolidacaoController> logger, ClienteBsn clienteBsn,
    ReportConsolidacaoBsn reportConsolidacaoBsn, IFileBsn fileBsn,
    IDomainConfig domainConfig, ITradeBsn tradeBsn,
    IReportBaseConsolidacaoBsn reportBaseConsolidacaoBsn, IInstrumentBsn _instrumentBsn,
    IReportConsolidacaoBsn reportBsn, IReconciliacaoPortfolioBsn reconciliacaoPortfolioBsn)
{ /* 12 atribuições */ }
```

O primeiro se lê; o segundo se tolera. Note o typo `IInstrumentBsn _instrumentBsn` (parâmetro com prefixo
de campo) — sintoma de que 12 parâmetros já passaram do limite de atenção humana.

---

### 6.6 Type-safe enum para códigos de 1 letra

O banco guarda `"C"` e `"D"`. O código nunca vê isso:

```csharp
namespace Domain.Enums.Opcao
{
    public class TipoMonitoramentoBarreiraOpcao
    {
        private TipoMonitoramentoBarreiraOpcao(string value) { Value = value; }

        public string Value { get; private set; }

        public static TipoMonitoramentoBarreiraOpcao Continuo => new("C");
        public static TipoMonitoramentoBarreiraOpcao Discreto => new("D");

        public override string ToString() => Value;
    }
}
```

Vários assim: `TipoCallPutOpcao` (`CALL`/`PUT`), `TipoListadaFlexOpcao` (`L`/`F`),
`TipoPrecoOpcao` (`U`=Último / `M`=Médio).

`if (tp == "D")` vira `if (tp == TipoMonitoramentoBarreiraOpcao.Discreto)`. Num domínio inteiro de códigos
de uma letra herdados de arquivo CETIP/B3, isso separa código lido de código decifrado.

*(Ressalva técnica: cada acesso instancia um objeto novo e não há `Equals`/`==` sobrecarregados, então
comparação por referência não funciona — na prática compara-se `.Value`. É um Smart Enum incompleto,
mas o ganho de legibilidade se mantém. Se copiar, implemente `Equals`/`GetHashCode`.)*

---

### 6.7 Enum de flags com descrição legível

```csharp
[Flags]
public enum IndicadoresBoleta
{
    [Description("Transferência")]      FlTransferencia   = 1,
    [Description("Chamada de capital")] FlChamadaCapital  = 2,
    [Description("Opção")]              FlBoletaOpcao     = 4,
    [Description("Aluguel")]            FlBoletaAluguel   = 8,
    [Description("Câmbio")]             FlBoletaCambio    = 16,
    [Description("Offshore")]           FlBoletaOffshore  = 32,
    [Description("Margem")]             FlBoletaMargem    = 64,
    [Description("Reserva")]            FlBoletaReserva   = 128,
    [Description("Fix")]                FlBoletaFix       = 256,
    [Description("Estrategia")]         FlBoletaEstrategia= 512,
    [Description("Evento")]             FlBoletaEvento    = 1024
}
```

Uma coluna `int` (`Bit_Indicadores`) guarda 11 booleanos. Na query fica declarativo:

```csharp
.Where(b => !((IndicadoresBoleta)b.BitIndicadores).HasFlag(IndicadoresBoleta.FlBoletaOpcao))
.Where(b => !((IndicadoresBoleta)b.BitIndicadores).HasFlag(IndicadoresBoleta.FlBoletaEvento));
```

E o `[Description]` alimenta a UI direto:

```csharp
public static List<EnumResponse> GetEnumValuesWithDescriptions<T>() where T : Enum
    => Enum.GetValues(typeof(T)).Cast<T>()
           .Select(e => new EnumResponse { Id = Convert.ToInt32(e), Descricao = e.GetDescription() })
           .ToList();
```

**Um enum serve três consumidores:** banco (bitmask), lógica (`HasFlag`) e front (label). Zero duplicação.

---

### 6.8 Validação que se lê em português

Mensagem centralizada em `IoC/MessageDomain.json`, carregada no boot:

```json
{
  "SemAcessoInfo": "SEM ACESSO A INFO",
  "SemAcessoAoCliente": "SEM ACESSO AO CLIENTE",
  "IdClienteNaoEncontrado": "Id cliente {0} não encontrado!",
  "MaisDeUmEncontrado": "Mais de um item encontrado com os parâmetros informados!",
  "DeveSerMaiorQueZero": "Valor deve ser maior que zero!"
}
```

Extension fluente esconde a regra técnica atrás do vocabulário do negócio:

```csharp
public static IRuleBuilderOptions<T, decimal> DeveSerMaiorQueZero<T>(this IRuleBuilder<T, decimal> ruleBuilder)
    => ruleBuilder.GreaterThan(0).WithMessage(_messageDomain.DeveSerMaiorQueZero());
```

E o validador vira quase declaração de requisito:

```csharp
public class BoletaMargemValidator : BaseValidator<BoletaMargemRequest>
{
    public BoletaMargemValidator(IServiceProvider serviceProvider) : base(serviceProvider)
    {
        RuleFor(x => x.VlrTotal).DeveSerMaiorQueZero();
        RuleFor(x => x.VlrPu).DeveSerMaiorQueZero();
    }
}
```

Um analista de negócio lê isso. Sobrecargas cobrem `int`, `int?`, `decimal`, `decimal?` — cada uma existe
só para que a chamada continue sendo uma linha.

---
---

# PARTE IV — CAMADAS ESPECÍFICAS

## 7. Camadas específicas

### 7.1 `Common`: a biblioteca que ninguém elogia

83 arquivos, 6.136 linhas. É onde mora boa parte da legibilidade do resto.

**`StringExtension` — 627 linhas, ~50 métodos.** Não é utilitário genérico: é **vocabulário do domínio
financeiro brasileiro**.

```csharp
// Documento
public static string ToMaskCPFCNPJ(this string field);
public static long?  FromCPFCNPJ(this string field);
public static bool   ValidarCNPJ(this string cnpj);
public static bool   IsValidCPF(this string cpf);
public static bool   EqualsCPFCNPJ(this string origem, string destino);

// Parsing tolerante (arquivo de parceiro vem sujo)
public static decimal? ReadAsDecimal(this string str);
public static bool     TryReadAsDateTime(this string str, string format, bool tryDefaultParse, out DateTime? value);
public static long?    ReadAsLong(this string str);

// Higienização
public static string RemoverAcentos(this string texto);
public static string RemoveCaracteresEspeciais(this string texto);
public static string RemovePathInvalidChars(this string filename);
public static string OnlyNumber(this string str);

// Guard clauses que encurtam if
public static bool   IsNullOrEmpty(this string str);
public static string IfIsNullOrEmpty(this string str, string valueDefault);
public static string Truncate(this string str, int maxLength, string addEndIfTruncate);

// Regex nomeado — usado no tratamento de SqlException (4.7)
public static string GetRegexCaptureGroup(this string input, string pattern, string groupName);
```

Efeito prático: a controller escreve `NrCpfCnpjTitular.ToMaskCPFCNPJ()` dentro de uma projeção LINQ,
sem helper, sem `if`, sem serviço injetado. Mascaramento de PII vira detalhe de uma linha.

**`ILoggerExtension` — o padrão "executa e loga".** 164 linhas que eliminam try/catch/stopwatch repetido:

```csharp
public static async Task ExecuteWithLogTimerAsync(this ILogger logger, string message,
    bool throwException, bool logError, bool errorCritial, Func<Task> func)
{
    var sw = Stopwatch.StartNew();
    try
    {
        logger.LogInformation($"Inicia {message}.");
        await func.Invoke().ConfigureAwait(false);
        sw.Stop();
        logger.LogInformation($"Finalizado {message}. [ {sw.Elapsed} ]");
    }
    catch (Exception ex)
    {
        sw.Stop();
        if (logError)
            logger.Log(errorCritial ? LogLevel.Critical : LogLevel.Error, ex, $"Erro {message}. [ {sw.Elapsed} ]");
        // ...
    }
}
```

Com sobrecargas que ligam `BeginScope` automaticamente. Início, fim, duração e erro — de graça,
com escopo de log correlacionado.

**`TaskExtension` — tratamento de erro sem aninhar.** Seis sobrecargas de `HandleException` que
transformam try/catch em continuação fluente:

```csharp
public static async Task HandleExceptionAsync<TException>(this Task task, Func<TException, Task> handle)
    where TException : Exception
{
    try   { await task.ConfigureAwait(false); }
    catch (TException ex) { await handle.Invoke(ex).ConfigureAwait(false); }
}
```

Uso real, com a exceção esperada **explícita na assinatura da lambda**:

```csharp
return _egCashierService.GetClientTransactionAsync(DateTime.Now.AddDays(-10), null, true, cancellationToken)
    .HandleException((CustomHttpRequestException ex) =>
    {
        _instrumentalizacaoBlobService.SendLogRequestToBlobAsync(/* ... */);
        throw new CustomException($"Api retornou um código diferente de sucesso => StatusCode: {(int)ex.StatusCode}...");
    });
```

**O resto do `Common`:**

| Pasta | Conteúdo |
|---|---|
| `Auxiliar/` (17 utils) | `ExcelUtil`, `PdfUtil`, `DateTimeUtil` (com `GetDateNowTimeBrasilia()`), `CertificateLoaderUtil`, `KMBUtil` (1.500.000 → "1,5M"), `NomeSiglaUtil`, `FotoAvatarUtil`, `ColorUtil`, `ReflectionUtil` |
| `Converters/` (10) | `OnlyDateConverter`, `DateTimeWithoutKindConverter`, `SingleOrArrayConverter` (API que às vezes devolve objeto, às vezes array), `DecimalConverter`, `IntToBooleanConverter` |
| `Attributes/` | `DecimalPrecisionAttribute`, `DateTimeTypeAttribute`, `ListEnumJsonConverter`, família `PositionalData` |
| `Exceptions/` (7) | Hierarquia herdando de `CustomException`, com `CustomObject` para payload estruturado |
| `Responses/` | `LoadOptionsResponse<T>` (`List` + `OriginalCount`), `EnumResponse` |
| `Comparers/` | `ReflectionEqualityComparer` — compara dois objetos campo a campo por reflexão |
| `Interfaces/` | Marcadores de lifetime, `ICustomOptions`, `IStartupTask`, `IDistributedLock` |

`ReflectionEqualityComparer` merece nota: num sistema cujo negócio é **reconciliar** posição do Prisma
contra posição do custodiante, comparar objeto genérico por reflexão é infraestrutura de domínio,
não utilitário.

---

### 7.2 Parsing declarativo de arquivo posicional

O padrão mais elegante do projeto.

**Contexto:** a B3 entrega arquivos IMBARQ em **layout posicional de largura fixa** (herança de mainframe).
A abordagem ingênua é `substring(0,2)`, `substring(2,17)`, e um bug de deslocamento a cada release.

Aqui, o layout **é** a classe:

```csharp
[FilterPositionalData(1, 2, "20")]        // esta classe só lê linhas cujo tipo (pos 1-2) seja "20"
public class Imbarq013Registro20Dto : IPositionalDataItem<Imbarq013Registro20Dto>
{
    [PositionData(1, 2)]     public int    TpRegistro { get; set; }
    [PositionData(3, 17)]    public string CodParticipanteSolicitante { get; set; }
    [PositionData(18, 32)]   public string CodInvestidorSolicitante { get; set; }
    [PositionData(63, 81)]   public long   NrOferta { get; set; }
    [PositionData(82, 83)]   public int    Situacao { get; set; }

    [DateOnlyPositionData(86, 95, "yyyy-MM-dd")]
    public DateOnly DtCriacaoOferta { get; set; }
    // ...
}
```

Atributos especializados por tipo:

```csharp
[AttributeUsage(AttributeTargets.Property)]
public class PositionDataAttribute : Attribute, IPositionalDataAttribute
{
    public int PosicaoInicial { get; }
    public int PosicaoFinal { get; }
}

public sealed class DecimalPositionDataAttribute : PositionDataAttribute
{
    public int CasasDecimais { get; }   // decimal implícito, sem separador no arquivo
}

public sealed class DateOnlyPositionDataAttribute : PositionDataAttribute
{
    // formato da data embutido
}
```

O parser genérico resolve por reflexão, inclusive header + N registros + trailer:

```csharp
public static T DeserializarFile<T>(string content) where T : class, IPositionalData, new()
{
    var lines = content.Split(new[] { '\n', '\r' }).Where(x => !x.IsNullOrWhiteSpace()).ToArray();

    foreach (PropertyInfo property in typeof(T).GetProperties())
    {
        // Propriedade única → DeserializeDataItem  (header/trailer)
        // Propriedade array  → DeserializeDataItems (registros)
        var nameMethod = property.PropertyType.IsArray
            ? nameof(DeserializeDataItems)
            : nameof(DeserializeDataItem);
        // ...
    }
    return instance;
}
```

Com validação explícita quando falta o filtro:

```csharp
var filtersAttribute = type.GetCustomAttributes<FilterPositionalDataAttribute>()
    ?? (requiredFilter
        ? throw new InvalidOperationException($"O {type.Name} precisa ter o {nameof(FilterPositionalDataAttribute)} configurado.")
        : null);
```

**Por que isso é legibilidade e não só engenharia:** o arquivo C# vira transcrição literal do manual de
layout da B3. Conferir código contra a documentação do parceiro é comparação visual, linha a linha.
São 11 layouts implementados (`Imbarq002` a `Imbarq014`), cada um numa pasta.

---

### 7.3 Extração Dinâmica: o BI dentro do backend

O usuário monta consultas próprias, sem SQL e sem deploy.

```csharp
public class TbExtracaoDinamica : IIdUsuEntity, IDtCpuEntity
{
    public int    IdExtracaoDinamica { get; set; }
    public string NmExtracaoDinamica { get; set; }
    public string NmRaiz { get; set; }                                  // entidade-raiz da navegação

    public List<ExtracaoDinamicaCampoDto>  JsonCampos { get; set; }     // campos escolhidos
    public ExtracaoDinamicaResultadoDto    JsonResultado { get; set; }  // config do resultado
}
```

As "raízes" navegáveis não estão no código — vêm de `CustomOptions`, ou seja, do banco:

```csharp
private async Task<List<RaizDto>> GetRaizesDtoAsync(CancellationToken cancellationToken = default)
{
    await CustomOptions.UpdateOptionsAsync(false, cancellationToken);
    return CustomOptions.Current.Raizes;
}
```

A execução usa `System.Linq.Dynamic.Core` para montar a projeção em runtime. As colunas JSON são
mapeadas com uma extension de uma linha:

```csharp
builder.Property(e => e.JsonCampos).HasConversionJsonString().HasColumnName("Json_Campos");
builder.Property(e => e.JsonResultado).HasConversionJsonString().HasColumnName("Json_Resultado");
```

```csharp
public static PropertyBuilder<T> HasConversionJsonString<T>(this PropertyBuilder<T> builder) where T : class, new()
    => builder.HasConversion(x => JsonConvert.SerializeObject(x),
                             x => JsonConvert.DeserializeObject<T>(x) ?? new());

public static PropertyBuilder<TEnum> HasConversionEnumString<TEnum>(this PropertyBuilder<TEnum> builder) where TEnum : struct
    => builder.HasConversion(x => x.ToString(), x => Enum.Parse<TEnum>(x));

public static PropertyBuilder<string> HasConversionEncryptString(this PropertyBuilder<string> builder, string encryptKey)
    => builder.HasConversion(x => x?.Encrypt(encryptKey), x => x?.Decrypt(encryptKey));
```

**O padrão de fundo:** o projeto trata "estrutura complexa numa coluna" como caso resolvido. Enum vira
string legível no banco (não `int` mágico) e string sensível é criptografada em trânsito para a coluna.
Três problemas recorrentes, três extensions de uma linha.

**Risco a monitorar:** `Linq.Dynamic.Core` com entrada de usuário é superfície de injeção. Vale conferir
se a whitelist de raízes/campos é aplicada antes de montar a expressão.

---

### 7.4 Observabilidade: health checks que perguntam

São **15 verificações ativas**, e várias fazem chamada real ao parceiro:

```csharp
services.AddHealthChecks()
   .AddSqlServer(connectionString: Configuration.GetConnectionString("PrismaDatabase"))
   .AddRedis(Configuration.GetValue<string>("ConnectionStrings:AzureRedis"))
   .AddCheck<HealthCheckXmlXp>("route xml carteira-Xp")
   .AddCheck<HealthCheckTokenXp>("auth token-Xp")
   .AddCheck<HealthCheckSaldoLiquidoXp>("route saldo liquido-Xp")
   .AddCheck<HealthCheckMovimentacaoXp>("route movimentações-Xp")
   .AddCheck<HealthCheckAdNnet>("route razão contábil-AdNnet")
   .AddCheck<HealthCheckAddepar>("route movimentação-Addepar")
   .AddCheck<HealthCheckEG>("route cashier-Eg")
   .AddCheck<HealthCheckAT>("route estratégias-ALPHA TOOLS")
   .AddCheck<HealthCheckBradescoCarrying>("route bradesco carrying")
   .AddCheck<HealthCheckOutSystems>("route worflow-Outsystems")
   .AddCheck<HealthCheckInsightsRequest>("route insights requests")
   .AddCheck<HealthCheckInsightsExceptions>("route insights exceptions")
   .AddCheck<HealthCheckInsightsDependencies>("route insights dependencies")
   .AddCheck<HealthCheckDataLake>("datalake");

services.AddHealthChecksUI(options =>
{
    options.SetEvaluationTimeInSeconds((int)TimeSpan.FromMinutes(10).TotalSeconds);
    options.MaximumHistoryEntriesPerEndpoint(100);
    options.AddHealthCheckEndpoint("Prisma", "/health");
}).AddInMemoryStorage();
```

Dashboard em `/healthdashboard`, 100 execuções de histórico por endpoint. E o nome de cada check é
**frase em português com o parceiro** — quem está de plantão lê o painel sem manual.

**Health check que consulta o próprio Application Insights.** Três checks executam **KQL** para verificar
taxa de erro das últimas 2 horas:

```kql
let start = datetime(<agora-2h>);
let end   = datetime(<agora>);
let requestsDataset = requests
    | where timestamp > start and timestamp < end
    | where client_Type != "Browser"
    | where success == false
    | where url != "GET /health" and name != "GET /"
    | where url !contains "localhost"
    | where url !contains "uat";
let exceptionsDataset = exceptions
    | where timestamp > start and timestamp < end
    | where type != "Common.Exceptions.CustomValidationException"
    | where type != "Common.Exceptions.CustomException";
requestsDataset
| join (exceptionsDataset) on $left.operation_Id == $right.operation_Id
| summarize failedCount = sumif(itemCount, success == false),
            impactedUsers = dcountif(user_Id, success == false),
            totalCount = sum(itemCount)
  by operation_Name, resultCode, url
```

Repare no filtro: `CustomValidationException` e `CustomException` **não contam como falha de saúde** —
são erro de negócio, não de sistema. **A taxonomia de exceções (4.6) pagou dividendo aqui:** o alerta
distingue "usuário digitou errado" de "o sistema quebrou", sem heurística. Também exclui `/health`
(senão o check monitoraria a si mesmo) e o ambiente `uat`.

**Base comum com log de escopo:**

```csharp
public abstract class HealthCheckBase<T> : IHealthCheck where T : HealthCheckBase<T>
{
    protected abstract Task CustomCheckHealthAsync(HealthCheckContext context, CancellationToken ct = default);

    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken ct = default)
    {
        var name = $"HealthCheck: {typeof(T).Name}";
        using (_logger.BeginScope($"{name}"))
        {
            try
            {
                await CustomCheckHealthAsync(context, ct);
                return HealthCheckResult.Healthy();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Erro {name}");
                return HealthCheckResult.Unhealthy(ex.Message, ex);
            }
        }
    }
}
```

Mesmo padrão de `BaseBsn`, `BaseWebJobWorker`, `BaseEntityMap`, `BaseValidator`, `BaseRepositoryCache`,
`BaseCustomOptionsConfig`, `BaseHttpClientService`, `BaseMessagingService`: **a base cuida do ritual
(escopo de log, try/catch, cronômetro) e o filho implementa um método abstrato com o essencial.**

Quando você aprende uma base, aprende todas. Mesma economia cognitiva do espelhamento de pastas,
aplicada a classes.

**Blob de instrumentação.** Quando um parceiro falha, o corpo da resposta vai para o Blob antes de a
exceção subir:

```csharp
await _instrumentalizacaoBlobService.SendLogRequestToBlobAsync(
    "", "", null, (int?)response?.StatusCode, response.Content, cancellationToken: cancellationToken);

throw new CustomException($"Api retornou um código diferente de sucesso => StatusCode: {(int)response.StatusCode}...",
                          new CustomException($"{message.Truncate(500)}"));
```

Payload completo no Blob para investigação, mensagem truncada em 500 no log. Separa o que se lê no
alerta do que se investiga depois.

---

### 7.5 O banco como cidadão de primeira classe

A pasta `Database/` tem **1.287 arquivos**.

```
Database/
├── Creates and Drops/   1.015 arquivos  — 165 pastas de release (v01 → v77)
├── Load/                  181 arquivos  — cargas de dados por release
└── Grants/                 91 arquivos  — permissões por schema/grupo
```

**Release train nomeado por feature:**

```
v64_Consolidacao_Backlog
v64_Enquadramento_Carteira_Teorica
v65_Devolucao_Chamada_Capital
v66_controleAcessoFdoExclusivo
v67_CapitalComprometidoV2
v69_PipelineProspeccao
v70_MelhoriasConsolidacaoContaRelGlobal
v72_CadastroFlashOffshore
v75_ContraparteAdmGestor
v77_MelhoriasReceitasAbr2026
```

Uma versão pode ter várias pastas (features paralelas na mesma release). O nome carrega a intenção de
negócio, não o número do ticket.

**Script com ordem e ação no nome:**

```
v70_MelhoriasConsolidacaoContaRelGlobal/
├── 01 - ALTER TABLE - Tb_Conta - ADD COLUMN Fl_Relatorio_Global.sql
├── 02 - ALTER TABLE - Tb_Tipo_Regra_Liberacao_Portfolio - ADD COLUMN Fl_Regra_Data_Exception.sql
├── 03 - ALTER TABLE - Tb_Liberacao_Portfolio_Regra - ADD COLUMN Id_Regra_Origem.sql
├── 04 - CREATE TABLE - Tb_Liberacao_Portfolio_Segregacao.sql
├── 05 - LOAD - Tb_Configuracao.sql
└── 06 - LOAD - Parametro Generico Envio Email.sql
```

Formato: `NN - AÇÃO - Objeto - Detalhe.sql`. **O nome do arquivo é o changelog.** Você lê a pasta e sabe
o que a release fez no banco, na ordem de execução, sem abrir um `.sql`. Vale para os grants também:

```
04 - CREATE USER SCHEMA.sql
GRANT ALL db Middle - GRP-COO-ASSET.sql
GRANT SELECT - app_dados - schema receitas.sql
```

Permissão versionada por grupo do AD e por schema — coerente com o modelo de autorização data-driven.

**A transição para EF Migrations.** O projeto de migrations tem **uma** migration:

```
Core/Repository.SqlServer.Migrations/Migrations/
├── 20251001234954_StartMigrations.cs
├── 20251001234954_StartMigrations.Designer.cs
└── SqlServerDbContextMigrationsModelSnapshot.cs
```

165 releases de script manual (histórico) e, em **outubro/2025**, um baseline de EF Migrations capturando
o estado atual. Migração de processo em andamento — daí o `SqlServerMigrationsModelDiffer` e o
`CustomMigrationsSqlGenerator` customizados, e a flag `MigrationState.IsDesignTime` espalhada pelos mappings.

Aquele `if (MigrationState.IsDesignTime)` que aparece em `ConfiguraBaseEntity`, `HasConversionEnumString`
e no temporal table é exatamente isso: **regras que valem para gerar DDL, mas não para consultar o banco
legado**, que ainda não está normalizado. Um comentário admite:

```csharp
#warning Mapeamento parcial do IdUsu
// Tem alguns casos nulos no banco de dados.
// Depois de normalizar, remover todo o if (MigrationState.IsDesignTime) e deixar somente a linha abaixo.
```

**Débito técnico marcado no compilador.** Só 3 `#warning` na base inteira — mas o uso é exemplar:
o compilador **grita a cada build** sobre uma inconsistência conhecida, com a instrução de como resolver.
Comparado a 117 `// TODO` (que ninguém vê), o `#warning` é a diferença entre débito registrado e
débito lembrado.

---
---

# PARTE V — RISCOS

## 8. O que NÃO copiar

### 8.1 God classes

| Arquivo | Linhas |
|---|---:|
| `Core/Application/BSN/Trade/TradeBsn.cs` | 12.604 |
| `Core/Application/BSN/Consolidacao/ReportConsolidacaoBsn.cs` | 11.363 |
| `Core/Application/BSN/Posicoes/PosicaoBSN.cs` | 10.802 |
| `Core/Application/BSN/Ativos/InstrumentBsn.cs` | 9.741 |
| `Core/Application/BSN/BatimentoTxAdm/BatimentoTxAdmRelatorioBsn.cs` | 7.098 |
| `Core/Application/BSN/ReconciliacaoPortfolioBsn.cs` | 6.855 |
| `PrismaService/.../BoletasController.cs` | 1.512 |
| `PrismaService/.../ConsolidacaoController.cs` | 1.320 |

O `BaseBsn` com service locator é justamente o que viabiliza esse crescimento sem dor imediata —
adicionar a 26ª dependência não custa nada. A conta chega no code review, no onboarding e no merge conflict.

**Mitigação:** limite de linhas por classe no lint/review e composição por sub-serviços
(`TradeBsn` → `TradeValidacaoBsn`, `TradeCalculoBsn`, `TradeExportBsn`).

### 8.2 Zero testes automatizados

Não há nenhum projeto de teste na solution. Com ~380 mil linhas de lógica financeira (cálculo de
rentabilidade, consolidação de posições, taxas), esse é o maior risco estrutural do projeto — e a razão
mais forte para não copiar o service locator sem pensar.

### 8.3 Segredos versionados

`Core/Repository.SqlServer/WhgContext.cs` tem, comentadas no topo, connection strings de produção com
senha em texto puro (resquício de comandos `Scaffold-DbContext`). Se alguma credencial ainda estiver
válida, é **rotação urgente** — e o histórico do Git guarda tudo mesmo após remoção.

**Mitigação:** Azure Key Vault + Managed Identity, e scanner de segredo no pipeline
(`gitleaks`, `trufflehog`).

### 8.4 Acoplamento ao DevExtreme e vazamento de `DbContext`

Retomando os números da seção 3: **59% das controllers injetam `WhgContext` direto** e **61% usam
`DataSourceLoadOptions`**. A camada BSN é aspiracional, não arquitetural. Trocar o front exige reescrever
a superfície da API.

### 8.5 Inconsistências de convenção

- Sufixo: `PosicaoBSN` / `ComplianceBSN` vs `TradeBsn` / `ClienteBsn`
- Pastas duplicadas: `Domain/Entities/CRM` **e** `Domain/Entities/Crm`
- Rotas: três padrões coexistindo (seção 3)
- Construtores com parâmetros opcionais `= null` para dependências obrigatórias (`PosicaoController`),
  trocando erro de startup por `NullReferenceException` em runtime
- Dependência ora pela interface, ora pela classe concreta (`PortfolioBsn portfolioBsn` no construtor,
  campo `IPortfolioBsn`)
- 125 BSNs concretos para 90 interfaces — nem tudo tem contrato

### 8.6 Cache de autorização em memória de instância

`IMemoryCache` é por processo, com TTL de 24h na API interna. Em escala horizontal, **revogar acesso pode
levar até um dia para valer em todas as instâncias**. O Redis já está no projeto e resolveria com
invalidação centralizada.

### 8.7 Estado mutável em serviço scoped

```csharp
_autorizacaoBsn.Funcionalidades           = listAutorizacaoFuncionalidade;
_autorizacaoBsn.GrupoAcessoCliente        = listGrupoAcessoCliente;
_autorizacaoBsn.GrupoAcessoClienteExcecao = listGrupoAcessoClienteExcecao;
```

Funciona porque o BSN é scoped por request. Se alguém promover essa classe a singleton um dia, vira
vazamento de permissão entre usuários — falha silenciosa e grave. Preferível passar o contexto de
autorização explicitamente.

### 8.8 `ConcurrentDictionary` estático em filtro

```csharp
public static readonly ConcurrentDictionary<string, Stopwatch> _timers = new();
```

Só é limpo no `OnActionExecuted`. Requisição abortada antes disso deixa entrada órfã — vazamento lento
de memória.

### 8.9 CORS aberto

```csharp
app.UseCors(s => s.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
// TODO: alterar authentication CORS para nível da Azure
```

O `TODO` está lá desde sempre.

### 8.10 Outros pontos de atenção

- `catch` silencioso nos handlers de certificado Itaú/B3 (só loga e devolve handler sem cert — o oposto
  do que a XP faz)
- `handler.ServerCertificateCustomValidationCallback = (...) => true;` no cliente B3 desliga validação
  do certificado do servidor
- `CheckCanExecute()` chama `.Wait()` sobre método async (risco de deadlock fora de ASP.NET Core)
- `ExecuteWithTryCacheAsync` engole exceção do worker (loga e segue) — um job pode "passar" tendo falhado
- `Linq.Dynamic.Core` com entrada de usuário na Extração Dinâmica: superfície de injeção a auditar
- README ainda é o template padrão do Azure DevOps, com todos os `TODO:` intactos

---

## 9. O que não foi lido

Sendo honesto sobre o alcance: mesmo com duas passagens, foram lidos ~**80 de ~3.500 arquivos**.
O que permanece inexplorado, em ordem de relevância:

| Área | Volume | Por que importa |
|---|---:|---|
| `TradeBsn.cs` | 12.604 linhas | Núcleo do negócio; nenhuma linha lida |
| `ReportConsolidacaoBsn.cs` | 11.363 linhas | Motor dos relatórios ao cliente |
| `PosicaoBSN.cs` | 10.802 linhas | Cálculo de posição consolidada |
| `InstrumentBsn.cs` | 9.741 linhas | Cadastro/precificação de ativos |
| `BatimentoTxAdmRelatorioBsn.cs` | 7.098 linhas | Conciliação de taxa de administração |
| `ReconciliacaoPortfolioBsn.cs` | 6.855 linhas | Reconciliação Prisma × custodiante |
| `ArquivoDePosicao401.cs` | 7.763 linhas | Schema XML ANBIMA 4.01 |
| 46 serviços de integração | 43.074 linhas | Só 3 abertos (Addepar, XP auth, B3 Imbarq) |
| 480 mappings EF | 32.702 linhas | 4 lidos |
| 88 relatórios DevExpress `.vsrepx` | binário | Layout dos PDFs entregues ao cliente |
| 165 pastas de script SQL | 1.287 arquivos | Só nomes lidos, nenhum conteúdo |
| 1.353 entidades de domínio | 46.335 linhas | ~10 abertas |

**O que uma terceira passagem provavelmente revelaria:** as regras de negócio de verdade — cálculo de
rentabilidade, marcação a mercado, tratamento de eventos corporativos, regras de enquadramento
(existe uma `CustomEnquadramentoException` dedicada, o que sugere um motor de compliance relevante) e a
lógica de reconciliação.

---
---

# PARTE VI — APLICAÇÃO PRÁTICA

## 10. Template: estrutura de pastas

Versão destilada para um backend novo, mantendo o espelhamento de árvore da seção 6.1:

```
YourProject/
├── src/
│   ├── Presentation/
│   │   └── Controllers/
│   │       ├── V1/
│   │       │   ├── Clientes/ClienteController.cs
│   │       │   └── Pedidos/PedidoController.cs
│   │       ├── Filters/ApiExceptionFilter.cs
│   │       └── BaseController.cs
│   │
│   ├── Application/
│   │   ├── Services/                      ← equivalente ao BSN
│   │   │   ├── Base/BaseService.cs
│   │   │   └── Clientes/ClienteService.cs
│   │   ├── Interfaces/Services/
│   │   │   ├── Base/IBaseService.cs
│   │   │   └── IClienteService.cs
│   │   ├── Models/                        ← contratos de API (Request/Response)
│   │   │   └── Clientes/
│   │   │       ├── CreateClienteRequest.cs
│   │   │       ├── GetClienteRequest.cs
│   │   │       └── ClienteResponse.cs
│   │   ├── DTOs/                          ← transporte interno
│   │   ├── Validators/CreateClienteValidator.cs
│   │   └── Mapper/ClienteProfile.cs
│   │
│   ├── Domain/
│   │   ├── Entities/
│   │   │   ├── IEntity.cs                 ← interfaces marcadoras
│   │   │   ├── IAuditableEntity.cs
│   │   │   ├── ITemporalEntity.cs
│   │   │   └── Clientes/Cliente.cs
│   │   ├── Enums/Clientes/
│   │   ├── Interfaces/Repositories/Base/
│   │   ├── VOs/
│   │   └── Validators/BaseValidator.cs
│   │
│   ├── Infrastructure/
│   │   ├── Contexts/{App}DbContext.cs
│   │   ├── Mappings/
│   │   │   ├── Base/BaseEntityMap.cs
│   │   │   └── Clientes/ClienteMap.cs
│   │   ├── Repositories/Base/
│   │   ├── Cache/BaseRepositoryCache.cs
│   │   └── Services/                      ← integrações externas
│   │
│   └── CrossCutting/
│       ├── IoC/DependencyInjection.cs     ← ponto ÚNICO de composição
│       ├── Common/
│       │   ├── Extensions/                ← StringExtension, TaskExtension, ILoggerExtension
│       │   ├── Exceptions/                ← hierarquia Custom*Exception
│       │   ├── Interfaces/                ← ISingletonInstance, ITransientInstance, IStartupTask
│       │   └── Auxiliar/
│       └── Messages/MessageDomain.json
│
├── workers/
│   ├── Common/WorkerFactory.cs
│   └── MyWorker/Program.cs
│
├── database/
│   ├── v01_FeatureInicial/
│   │   ├── 01 - CREATE TABLE - Cliente.sql
│   │   └── 02 - LOAD - Configuracao.sql
│   └── v02_OutraFeature/
│
└── tests/                                 ← o que faltou no original
    ├── Application.Tests/
    └── Domain.Tests/
```

---

## 11. Template: controller, BSN e contratos

### Controller enxuta (sem try/catch — o filtro global cuida)

```csharp
/// <summary>Operações de cliente.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/[controller]")]
[ApiController]
[Authorize]
public class ClienteController : BaseController
{
    private readonly IClienteService _clienteService;
    private readonly ILogger<ClienteController> _logger;

    public ClienteController(IClienteService clienteService, ILogger<ClienteController> logger)
    {
        _clienteService = clienteService;
        _logger = logger;
    }

    /// <summary>Lista clientes com filtros e paginação.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(PaginatedResponse<ClienteResponse>), 200)]
    public Task<PaginatedResponse<ClienteResponse>> GetAll(
        [FromQuery] GetClienteRequest request, CancellationToken ct = default)
        => _clienteService.GetAllAsync(request, ct);

    /// <summary>Obtém um cliente pelo ID.</summary>
    /// <response code="404">Cliente não encontrado</response>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(ClienteResponse), 200)]
    public Task<ClienteResponse> GetById(int id, CancellationToken ct = default)
        => _clienteService.GetByIdAsync(id, ct);   // lança CustomNotFoundException → 404 pelo filtro

    /// <summary>Cria um novo cliente.</summary>
    /// <response code="409">Já existe cliente com este CPF/CNPJ</response>
    [HttpPost]
    [ProducesResponseType(typeof(ClienteResponse), 201)]
    public async Task<IActionResult> Create(
        [FromBody] CreateClienteRequest request, CancellationToken ct = default)
    {
        var resultado = await _clienteService.CreateAsync(request, ct);
        return CreatedAtAction(nameof(GetById), new { id = resultado.IdCliente }, resultado);
    }

    /// <summary>Atualiza um cliente existente.</summary>
    [HttpPut("{id}")]
    public Task<ClienteResponse> Update(
        int id, [FromBody] UpdateClienteRequest request, CancellationToken ct = default)
    {
        request.IdCliente = id;
        return _clienteService.UpdateAsync(request, ct);
    }

    /// <summary>Inativa um cliente (soft delete).</summary>
    [HttpDelete("{id}")]
    [ProducesResponseType(204)]
    public async Task<IActionResult> Delete(int id, CancellationToken ct = default)
    {
        await _clienteService.DeleteAsync(id, ct);
        return NoContent();
    }

    /// <summary>Exporta clientes em Excel.</summary>
    [HttpPost("exportar")]
    public async Task<IActionResult> Exportar(
        [FromBody] GetClienteRequest request, CancellationToken ct = default)
    {
        var (stream, fileName) = await _clienteService.ExportarAsync(request, ct);
        return File(stream, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
    }
}
```

Compare com a versão "defensiva" (try/catch em toda action, `ApiResponse<T>` montado à mão):
o filtro global e as exceções de domínio eliminam ~60% do código de cada action, sem perder resposta HTTP correta.

### Filtro global de exceção

```csharp
public class ApiExceptionFilter : IActionFilter
{
    private readonly ILogger<ApiExceptionFilter> _logger;

    public void OnActionExecuting(ActionExecutingContext context) { }

    public void OnActionExecuted(ActionExecutedContext context)
    {
        if (context.Exception is null) return;

        var status = context.Exception switch
        {
            NotFoundException   => HttpStatusCode.NotFound,
            ConflictException   => HttpStatusCode.Conflict,
            ValidationException => HttpStatusCode.BadRequest,
            ForbiddenException  => HttpStatusCode.Forbidden,
            _                   => HttpStatusCode.InternalServerError
        };

        if (status == HttpStatusCode.InternalServerError)
            _logger.LogError(context.Exception, "Erro não tratado");

        context.Result = new ObjectResult(BuildBody(context.Exception)) { StatusCode = (int)status };
        context.ExceptionHandled = true;
    }

    private static object BuildBody(Exception ex)
    {
        // Explode AggregateException em Items[] — front recebe todos os erros de uma vez
        if (ex.InnerException is AggregateException agg)
            return new { ex.Message, Items = agg.InnerExceptions.Select(x => new { x.Message }).ToList() };

        return new { ex.Message };
    }
}
```

### Service (equivalente ao BSN) com construtor explícito

```csharp
public class ClienteService : BaseService<ClienteService>, IClienteService
{
    private readonly IClienteRepository _repository;
    private readonly IValidator<CreateClienteRequest> _createValidator;

    // Dependências de negócio: explícitas no construtor (visibilidade do acoplamento)
    // Transversais (Mapper, Logger, DomainConfig): herdadas da base como propriedades preguiçosas
    public ClienteService(
        IServiceProvider serviceProvider,
        IClienteRepository repository,
        IValidator<CreateClienteRequest> createValidator) : base(serviceProvider)
    {
        _repository = repository;
        _createValidator = createValidator;
    }

    public async Task<ClienteResponse> CreateAsync(CreateClienteRequest request, CancellationToken ct = default)
    {
        var validation = await _createValidator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            throw new ValidationException(string.Join("; ", validation.Errors.Select(e => e.ErrorMessage)));

        if (await _repository.ExistsAsync(c => c.CpfCnpj == request.CpfCnpj, ct))
            throw new ConflictException("Já existe um cliente com este CPF/CNPJ.");

        var cliente = Mapper.Map<Cliente>(request);

        await _repository.CreateAsync(cliente, ct);   // CreatedBy preenchido no SaveChanges

        _logger.LogInformation("Cliente criado. Id: {Id}", cliente.IdCliente);

        return Mapper.Map<ClienteResponse>(cliente);
    }

    public async Task<ClienteResponse> GetByIdAsync(int id, CancellationToken ct = default)
    {
        var cliente = await _repository.FirstOrDefaultAsync(c => c.IdCliente == id, true, ct)
            ?? throw new NotFoundException($"Cliente {id} não encontrado.");

        return Mapper.Map<ClienteResponse>(cliente);
    }
}
```

### Contratos e entidade

```csharp
// Application/Models/Clientes/CreateClienteRequest.cs — um arquivo por classe
public class CreateClienteRequest
{
    [Required] [StringLength(150, MinimumLength = 3)]
    public string Nome { get; set; }

    [Required] [EmailAddress]
    public string Email { get; set; }

    [Required] [StringLength(14, MinimumLength = 11)]
    public string CpfCnpj { get; set; }

    [Required]
    public ETipoCliente TipoCliente { get; set; }
}
```

```csharp
// Application/Models/Clientes/GetClienteRequest.cs — filtros herdam paginação
public class GetClienteRequest : PaginationParams
{
    public string        Nome { get; set; }
    public string        CpfCnpj { get; set; }
    public ETipoCliente? TipoCliente { get; set; }
    public EStatusCliente? Status { get; set; }
    public DateTime?     DataCriacaoInicio { get; set; }
    public DateTime?     DataCriacaoFim { get; set; }
    public string        OrderBy { get; set; } = "DataCriacao";
    public string        OrderDirection { get; set; } = "desc";
}
```

```csharp
// Domain/Entities/Clientes/Cliente.cs — a declaração é a ficha técnica
public class Cliente : IAuditableEntity, ITemporalEntity
{
    public int            IdCliente { get; set; }
    public string         NmCliente { get; set; }
    public string         CpfCnpj { get; set; }
    public ETipoCliente   TpCliente { get; set; }
    public EStatusCliente StatusCliente { get; set; }

    // IAuditableEntity → preenchido no SaveChanges
    public string   CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }

    // ITemporalEntity → temporal table gerada no mapping
    public DateTime ValidFrom { get; set; }
    public DateTime ValidTo { get; set; }
}
```

```csharp
// Domain/Enums/Clientes/ETipoCliente.cs — Description alimenta a UI
public enum ETipoCliente
{
    [Description("Pessoa Física")]        PessoaFisica       = 1,
    [Description("Pessoa Jurídica")]      PessoaJuridica     = 2,
    [Description("Fundo de Investimento")] FundoInvestimento = 3
}
```

```csharp
// Infrastructure/Mappings/Clientes/ClienteMap.cs — uma linha resolve o transversal
internal sealed class ClienteMap : BaseEntityMap<Cliente>
{
    public ClienteMap(string schema) : base("Tb_Cliente", schema, false) { }

    protected override void ConfigureMap(EntityTypeBuilder<Cliente> builder)
    {
        builder.HasKey(e => e.IdCliente).HasName("Pk_Tb_Cliente");
        builder.Property(e => e.IdCliente).HasColumnName("Id_Cliente");
        builder.Property(e => e.NmCliente).HasColumnName("Nm_Cliente").HasMaxLength(150).IsRequired();
        builder.Property(e => e.CpfCnpj).HasColumnName("Cd_Cpf_Cnpj").HasMaxLength(14);
        builder.Property(e => e.TpCliente).HasColumnName("Tp_Cliente").HasConversionEnumString();

        builder.ConfiguraBaseEntity();   // auditoria + temporal, deduzido das interfaces
        builder.HasIndex(e => e.CpfCnpj).HasDatabaseName("Uk_Tb_Cliente_Cpf_Cnpj").IsUnique();
    }
}
```

---

## 12. Template: injeção de dependência

### `Program.cs`

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers(options => options.Filters.Add<ApiExceptionFilter>());
builder.Services.AddApiVersioning();
builder.Services.AddSwaggerGen(c =>
{
    c.IncludeXmlComments(Path.Combine(AppContext.BaseDirectory, "Api.xml"));
});

builder.Services.ConfigureIoC(builder.Configuration);   // ponto único

var app = builder.Build();

// Startup tasks ANTES de servir tráfego (fail fast)
foreach (var task in app.Services.GetServices<IStartupTask>())
    await task.ExecuteAsync();

if (!app.Environment.IsProduction())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseRouting();
app.UseAuthentication();
app.UseMiddleware<UserContextMiddleware>();   // popula IUserContext p/ auditoria
app.UseAuthorization();
app.MapControllers();

app.Run();
```

### `ConfigureIoC`

```csharp
public static class DependencyInjection
{
    public static IServiceCollection ConfigureIoC(this IServiceCollection services, IConfiguration config)
    {
        services.ConfigureOptions(config);
        services.ConfigureCache(config);
        services.ConfigureRepositories(config);
        services.ConfigureExternalServices();
        services.ConfigureApplicationServices();
        services.ConfigureValidators();
        services.ConfigureAutoMapper();
        services.ConfigureStartupTasks();
        return services;
    }

    private static IServiceCollection ConfigureRepositories(this IServiceCollection services, IConfiguration config)
    {
        var connectionString = config.GetConnectionString("DefaultConnection");

        services.AddDbContext<AppDbContext>((sp, options) =>
        {
            options.UseSqlServer(connectionString, o => o.CommandTimeout(180));
            options.UseApplicationServiceProvider(sp);
#if DEBUG
            options.EnableSensitiveDataLogging();
#endif
        });

        services.RegisterByConvention(typeof(IRepository), typeof(BaseRepository<,>));
        return services;
    }

    private static IServiceCollection ConfigureApplicationServices(this IServiceCollection services)
    {
        services.RegisterByConvention(typeof(IBaseService), typeof(BaseService<>));
        return services;
    }

    private static IServiceCollection ConfigureStartupTasks(this IServiceCollection services)
    {
        var startupInterfaceType = typeof(IStartupTask);

        var implementations = Assembly.GetAssembly(typeof(DependencyInjection))
            .GetTypes()
            .Where(x => x.IsClass && !x.IsAbstract && x.IsAssignableTo(startupInterfaceType));

        foreach (var impl in implementations)
            services.AddTransient(startupInterfaceType, impl);

        return services;
    }
}
```

### Registro por convenção com lifetime por marcador

```csharp
public static void RegisterByConvention(this IServiceCollection services,
    Type interfaceBaseMap, Type classBaseMap, bool includeBaseInterface = false)
{
    var classes = AppDomain.CurrentDomain.GetAssemblies()
        .SelectMany(a => a.GetTypes())
        .Where(t => t.IsClass && !t.IsAbstract)
        .Where(t => t.BaseType is not null)
        .Where(t => t.GetInterfaces().Any(i => i == interfaceBaseMap))
        .Where(t => classBaseMap.IsGenericType
            ? t.IsSubclassOfGenericClass(classBaseMap.GetGenericTypeDefinition())
            : t.IsSubclassOfGenericClass(classBaseMap))
        .ToList();

    foreach (var impl in classes)
    {
        var interfaces = impl.GetInterfaces()
            .Where(i => includeBaseInterface || i != interfaceBaseMap)
            .Where(i => interfaceBaseMap.IsAssignableFrom(i))
            .ToList();

        if (!interfaces.Any()) continue;

        var isSingleton = typeof(ISingletonInstance).IsAssignableFrom(impl);
        var isTransient = typeof(ITransientInstance).IsAssignableFrom(impl);

        // registra a classe concreta UMA vez...
        if (isSingleton)       services.AddSingleton(impl);
        else if (!isTransient) services.AddScoped(impl);

        // ...e cada interface aponta para a MESMA instância
        foreach (var iface in interfaces)
        {
            if (isSingleton)       services.AddSingleton(iface, sp => sp.GetRequiredService(impl));
            else if (!isTransient) services.AddScoped(iface, sp => sp.GetRequiredService(impl));
            else                   services.AddTransient(iface, impl);
        }
    }
}
```

### Auditoria automática no `SaveChanges`

```csharp
public abstract class BaseDbContext<TContext> : DbContext where TContext : DbContext
{
    public override Task<int> SaveChangesAsync(bool acceptAll, CancellationToken ct = default)
    {
        ApplyAudit();
        try   { return base.SaveChangesAsync(acceptAll, ct); }
        catch (Exception ex) { HandleSqlExceptions(ex); throw; }
    }

    private void ApplyAudit()
    {
        IUserContext userContext = null;

        foreach (var entry in ChangeTracker.Entries()
                     .Where(e => e.State == EntityState.Added)
                     .Select(e => e.Entity)
                     .OfType<IAuditableEntity>())
        {
            if (entry.CreatedBy is null)
            {
                userContext ??= this.GetService<IUserContext>();
                entry.CreatedBy = userContext.CurrentUserId;
                entry.CreatedAt = DateTime.UtcNow;
            }
        }
    }

    private static void HandleSqlExceptions(Exception ex)
    {
        if (ex is DbUpdateException { InnerException: SqlException sql })
        {
            switch (sql.Number)
            {
                case 547:  throw new ConflictException("Existem registros relacionados a este item.");
                case 2627:
                case 2601: throw new ConflictException("Este valor já existe na base.");
                case 2628: throw new ConflictException("O valor informado é muito longo para o campo.");
            }
        }
    }
}
```

### Temporal table por interface marcadora

```csharp
public abstract class BaseEntityMap<TEntity> : IEntityTypeConfiguration<TEntity> where TEntity : class
{
    private readonly string _name, _schema;
    private readonly bool _isView;

    protected abstract void ConfigureMap(EntityTypeBuilder<TEntity> builder);

    public void Configure(EntityTypeBuilder<TEntity> builder)
    {
        if (_isView) builder.ToView(_name, _schema);
        else
        {
            builder.ToTable(_name, _schema);

            if (MigrationState.IsDesignTime && typeof(ITemporalEntity).IsAssignableFrom(typeof(TEntity)))
                builder.ToTable(x => x.IsTemporal(b =>
                {
                    b.HasPeriodStart("Valid_From");
                    b.HasPeriodEnd("Valid_To");
                    b.UseHistoryTable($"{_name}_Log", _schema);
                }));
        }

        ConfigureMap(builder);

        builder.ConfigureDateOnly();
        builder.ConfigureTimeOnly();
    }
}
```

### `WorkerFactory` para processos background

```csharp
var factory = new WorkerFactory<Program>(args);
factory.AddWorker<MyWorker>();
await factory.StartAsync();
```

Com cron vindo de config, shutdown gracioso (`WEBJOBS_SHUTDOWN_FILE` / `CancelKeyPress` / `ProcessExit`),
heartbeat a cada 30s e flush de telemetria no `finally`.

---

## 13. Checklist de adoção

### Estrutura e legibilidade — adote desde o primeiro commit

| Prática | Custo | Impacto |
|---|---|---|
| Espelhamento de árvore entre camadas | Zero | Altíssimo |
| Prefixo de tipo (`Tb`/`View`/`Request`/`Response`/`Base`/`Map`) | Zero | Altíssimo |
| Prefixo de coluna na propriedade (`Vlr`/`Dt`/`Fl`/`Nr`/`Tp`) | Zero | Alto |
| Um arquivo por classe | Zero | Alto |
| Interfaces marcadoras (`IAuditableEntity`, `ITemporalEntity`) | Baixo | Altíssimo |
| Classes base que absorvem ritual (log, try/catch, timer) | Baixo | Alto |
| Extensions de domínio (`ToMaskCPFCNPJ`, `DeveSerMaiorQueZero`) | Baixo | Alto |
| Hierarquia de exceções de domínio | Baixo | Altíssimo |
| Enum com `[Description]` alimentando banco + lógica + UI | Baixo | Médio |
| Type-safe enum para códigos de 1 letra (com `Equals`!) | Médio | Médio |

### Infraestrutura — adote com adaptação

| Padrão | Adotar? | Observação |
|---|---|---|
| `ConfigureIoC()` único compartilhado | ✅ Sim | Ganho imediato, custo zero |
| Marker interfaces de lifetime | ✅ Sim | Simples e explícito |
| Registro por convenção via reflexão | ✅ Com teste | Valide o grafo do container no boot |
| Filtro exceção → HTTP status | ✅ Sim | Limpa todas as controllers |
| Tradução de `SqlException` | ✅ Sim | Elimina validação defensiva |
| Auditoria no `SaveChanges` | ✅ Sim | Interface marcadora + interceptação |
| Temporal tables automáticas | ✅ Sim | Só se o banco suportar (SQL Server 2016+) |
| Config em camadas + fail fast | ✅ Sim | Segredo no Key Vault, não no banco |
| Cache L1+L2 com compressão | ✅ Sim | Kill-switch é essencial |
| `WorkerFactory` para background | ✅ Sim | Padroniza N processos |
| Fila em tabela com prioridade | ✅ Sim | Ótimo para operação longa com acompanhamento |
| Lock distribuído | ✅ Sim | Obrigatório em escala horizontal |
| Health checks ativos + KQL | ✅ Sim | Nomeie em português; exclua erro de negócio |
| Scripts SQL versionados por feature | ✅ Sim | `NN - AÇÃO - Objeto.sql` |
| Parser posicional declarativo | ✅ Sim | Se você lê arquivo de largura fixa |
| Autorização data-driven | ⚠️ Adaptar | Use Redis; TTL curto |
| Service Locator na base | ⚠️ Cuidado | Só transversais; negócio no construtor |
| BI dinâmico (`Linq.Dynamic.Core`) | ⚠️ Cuidado | Whitelist obrigatória de campos/raízes |

### Nunca

| Anti-padrão | Por quê |
|---|---|
| `DbContext` injetado na controller | Vaza persistência para a apresentação; acopla ao front |
| Zero testes | O maior débito do projeto original |
| Segredo em arquivo versionado | Key Vault + scanner no pipeline |
| CORS `AllowAnyOrigin` | Whitelist por ambiente |
| Classe sem limite de tamanho | Vira `TradeBsn.cs` com 12.604 linhas |
| `catch` que engole exceção em worker | Job "passa" tendo falhado |

---

## 14. Veredito

O Prisma Service é um monólito modular **excelente nos alicerces e comprometido na disciplina**.

Os alicerces são de time maduro: composição única, registro por convenção, auditoria automática por tipo,
config dinâmica em camadas, cache em dois níveis, padronização completa de background jobs, autorização
sem deploy, health checks que interrogam parceiros e o próprio Application Insights.

A disciplina é onde escorrega: classes de 12 mil linhas, nenhum teste automatizado, segredo versionado,
59% das controllers falando com o `DbContext` direto, convenções divergentes entre módulos.

Mas a leitura mais interessante do projeto é outra, e é a que vale levar:

> **Este projeto fez uma aposta explícita: investir em estrutura em vez de documentação.**

Cada peça examinada confirma a mesma decisão:

- Não escreveram doc de arquitetura → **espelharam a árvore de pastas** entre camadas
- Não comentaram entidades → **codificaram os fatos em interfaces marcadoras**
- Não documentaram códigos de banco → **encapsularam em type-safe enums**
- Não escreveram changelog → **nomearam os scripts SQL com a ação inteira**
- Não fizeram guia de layout de arquivo B3 → **transcreveram o layout em atributos**
- Não padronizaram por convenção escrita → **padronizaram por classe base**
- Não escreveram runbook → **nomearam health checks em português com o parceiro**

E a aposta **funciona**: dá para navegar 380 mil linhas por dedução. Um dev novo acha a regra de
consolidação sem perguntar a ninguém.

Onde a aposta cobra o preço: **estrutura não expressa comportamento complexo.** Uma pasta bem nomeada não
te diz por que `TradeBsn` tem 12 mil linhas nem o que acontece lá dentro. Estrutura orienta *onde procurar*;
não substitui teste (que documenta comportamento) nem decomposição (que limita o que precisa ser entendido
de uma vez).

**Para se inspirar, na ordem certa:**

1. **Copie a estrutura sem hesitar.** É o melhor deste backend e é barato de adotar desde o dia um.
2. **Copie a infraestrutura com adaptação.** Os 12 padrões da Parte II, ajustados ao seu contexto.
3. **Adicione o que faltou.** Teste automatizado, limite de linhas por classe no review, segredo em
   Key Vault, e uma camada de aplicação que não vaze `DbContext` para a controller.

A estrutura te dá um sistema **navegável**. Teste e decomposição te dão um sistema **modificável**.
Este projeto acertou o primeiro em cheio e deixou o segundo para depois — e o "depois" tem 12.604 linhas.
