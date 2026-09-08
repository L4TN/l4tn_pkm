# PARTE VI — RECOMENDAÇÕES DERIVADAS

As seções anteriores descrevem o sistema existente. Esta parte transforma as observações em um
modelo de adoção: não é uma descrição de que o Prisma Service já é assim, mas o que vale reproduzir,
adaptar ou evitar em um projeto novo.

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
