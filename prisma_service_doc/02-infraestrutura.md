# PARTE II — INFRAESTRUTURA

## 4. Os 13 padrões e mecanismos transversais

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
| `CustomForbiddenException` | 403 Forbidden |
| `HttpRequestException` com status conhecido | status original (4xx/5xx) |
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

#### Ajuste recomendado: saída de exceções realmente centralizada

O padrão deve ser mantido, mas com uma única responsabilidade para a tradução
**exceção → status HTTP → payload**. A regra recomendada para o Prisma Service é:

1. Controllers não devem montar `StatusCode(...)` dentro de `catch` para erros de negócio;
2. a camada de aplicação deve lançar `CustomNotFoundException`, `CustomValidationException`,
   `CustomConflictException` ou `CustomForbiddenException`;
3. um `ExceptionResponseFactory`/`ExceptionHandlingFilter` global deve ser o único ponto que
   cria a resposta de erro;
4. exceções que ocorram fora do MVC (por exemplo, validação do JWT ou outro middleware) devem
   reutilizar o mesmo mapeador, nunca ter uma tabela de status paralela;
5. a resposta deve ser escrita somente se `Response.HasStarted == false`.

O contrato central deve ser equivalente a:

```csharp
public sealed record ExceptionResponse(int StatusCode, object Body);

public static ExceptionResponse From(Exception exception) => exception switch
{
    CustomNotFoundException => new(404, new { exception.Message }),
    CustomConflictException conflict => new(409, BuildConflictBody(conflict)),
    CustomValidationException validation => new(400, BuildValidationBody(validation)),
    CustomForbiddenException forbidden => new(403, new { forbidden.Message }),
    HttpRequestException http when http.StatusCode is >= HttpStatusCode.BadRequest
        and <= HttpStatusCode.NetworkAuthenticationRequired
        => new((int)http.StatusCode.Value, new { http.Message }),
    _ => new(500, new { Message = "Erro interno do servidor." })
};
```

O `ApplicationApiHandler` deve consumir esse contrato no `OnActionExecuted`, definir
`context.Result` e marcar `context.ExceptionHandled = true`. O middleware externo deve consumir
o mesmo contrato e copiar `response.StatusCode` para `HttpContext.Response.StatusCode`.
Assim, não ocorre a inconsistência atual em que o corpo informa `500` (ou o status original)
e o status HTTP real é forçado para `400`.

Também é importante distinguir autenticação de autorização:

- token ausente/inválido: `401 Unauthorized`;
- usuário autenticado sem acesso à rota: `403 Forbidden`.

A migração pode ser gradual: primeiro centralizar a fábrica e o filtro, depois remover os
`catch` redundantes das Controllers. Os `catch` que adicionam contexto de domínio ou fazem
rollback continuam válidos, desde que relancem a exceção (`throw`) após o log.

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
