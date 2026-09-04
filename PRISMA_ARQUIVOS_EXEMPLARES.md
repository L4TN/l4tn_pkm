# Prisma Service — Arquivos Exemplares por Pasta

Companion do mapa de pastas. Para as pastas que mais importam, o **arquivo canônico** —
aquele que, se você entender, entende os outros 50 daquela pasta.

Cada bloco traz: onde fica · o que é · o código real · o padrão a extrair.

---

## Índice

| # | Pasta | Arquivo exemplar |
|---|---|---|
| 1 | `Core/Services/<Parceiro>/` | `AddeparService.cs` — cliente de API |
| 2 | `Core/Services/<Parceiro>Auth/` | `AlphaToolsAuthService.cs` — autenticação isolada |
| 3 | `Core/Application/BSN/` | `FilaProcessamentoBsn.cs` — service de negócio |
| 4 | `Core/Application/Interfaces/BSN/` | `IPortfolioTaxaBsn.cs` — contrato |
| 5 | `Core/Repository.SqlServer/Repositories/` | `ClasseAtivoRepository.cs` + `ConfiguracaoRepository.cs` |
| 6 | `Core/Repository.SqlServer/Mappings/` | `TbPortfolioConsolidacaoLiberacaoMap.cs` |
| 7 | `Core/Domain/Entities/` | `TbFilaProcessamento.cs` |
| 8 | `Core/Application/Models/` | `WalletRequest` / `GetSolicitacoesRequest` |
| 9 | `Core/Domain/Validators/` | `BoletaMargemValidator.cs` |
| 10 | `Core/IoC/CustomOptions/` | `WebJobCustomOptionsConfig.cs` + POCO |
| 11 | `Core/Services/Messaging/Contexts/` | `FinanceReceitaMessagingService.cs` |
| 12 | `Jobs/<Job>/` | `Program.cs` + `TablesToDatalakeWorker.cs` |
| 13 | `Jobs/<Job>/Consumers/` + `Handlers/` | `FinanceReceitaConsumer` + `Handler` |
| 14 | `PrismaService/HealthCheck/` | `HealthCheckAddepar.cs` |
| 15 | `PrismaService/Controllers/DevEx/` | trecho do `ConsolidacaoController` |
| 16 | `Core/Services/B3Imbarq/Dtos/` | `Imbarq013Registro20Dto.cs` |

---

## 1. `Core/Services/<Parceiro>/` — cliente de API externa

**Arquivo:** `Core/Services/Addepar/AddeparService.cs` (515 linhas) + `IAddeparService.cs` (20 linhas)

O contrato primeiro — pequeno, uma linha por operação de negócio, sempre com `CancellationToken`:

```csharp
namespace Services.Addepar
{
    public interface IAddeparService
    {
        Task<List<PosicaoAddepar>>     GetPositionsByDate(DateTime startDate, DateTime endDate, bool byClientLevel = false, string portfolioType = null, string portfolioId = null, CancellationToken cancellationToken = default);
        Task<List<MovimentacaoAddepar>> GetTransactionsByDate(DateTime startDate, DateTime endDate, CancellationToken cancellationToken = default);
        Task<HttpResponseMessage>       GetHealthCheckTransactionsByDate(DateTime startDate, DateTime endDate, CancellationToken cancellationToken = default);
        Task<Dictionary<string, string>> GetFinancialAccounts(CancellationToken cancellationToken = default);
        Task<List<ContaAddepar>>        GetAccountAttributes(DateTime startDate, DateTime endDate, string portfolioType = null, string portfolioId = null, CancellationToken cancellationToken = default);
        Task<AddeparApiResponse>        GetSecurities(DateTime startDate, DateTime endDate, string portfolioType = null, string portfolioId = null, CancellationToken cancellationToken = default);
    }
}
```

A implementação — construtor monta o `HttpClient` a partir da configuração, com timeout explícito:

```csharp
public class AddeparService : IAddeparService
{
    private string _apiUrl;
    private string _token;
    private readonly HttpClient _httpClient;
    protected readonly ILogger<AddeparService> _logger;
    private readonly IMemoryCache _memoryCache;

    public AddeparService(IConfiguration configuration, ILogger<AddeparService> logger, IMemoryCache memoryCache)
    {
        _apiUrl = configuration.GetSection("XpPosiWhgParceiros")["UrlAddeparApi"];
        _token  = configuration.GetSection("XpPosiWhgParceiros")["TokenAddeparApi"];

        _httpClient = new()
        {
            BaseAddress = new Uri($"{_apiUrl?.Trim(' ', '\\', '/')}/"),
            Timeout = TimeSpan.FromSeconds(300)      // integração lenta: 5 min
        };

        SetAuthHttpCLient(_httpClient, _token);
        _logger = logger;
        _memoryCache = memoryCache;
    }
```

E o método típico — cache, desserialização e **erro rico**:

```csharp
    public async Task<Dictionary<string, string>> GetFinancialAccounts(CancellationToken cancellationToken = default)
    {
        string requestUrl = $"entities?filter[entity_types]=financial_account";
        string cacheKey   = $"GetFinancialAccounts:{requestUrl}";

        if (!_memoryCache.TryGetValue(cacheKey, out Dictionary<string, string> dicEntityByAccount))
        {
            var response = await _httpClient.GetAsync(requestUrl).ConfigureAwait(false);

            var responseDeserialized = await response.Content
                .ReadAndDeserializeAsync<JObject>(null, cancellationToken).ConfigureAwait(false);

            if (response.StatusCode != HttpStatusCode.OK || responseDeserialized == null || !responseDeserialized.HasValues)
            {
                var content = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
                var message = $"Falha ao consultar posicoes Addepar";

                if (!response.IsSuccessStatusCode)      message += ". Retorno diferente de 200 OK";
                else if (string.IsNullOrEmpty(content)) message += ". Json retornou vazio";

                throw new CustomHttpRequestException(message, response.StatusCode, requestUrl, content);
            }
            // ...
        }
    }
```

**Padrão a extrair:**

- Interface enxuta, uma operação de negócio por método, `CancellationToken` sempre no fim
- `HttpClient` configurado no construtor com `BaseAddress` normalizado (`Trim(' ', '\\', '/')`)
- Timeout explícito por parceiro — não use o default de 100s para integração pesada
- **`CustomHttpRequestException` carrega status, URL e corpo da resposta.** É isso que permite o
  `ExecuteWithRetryAsync` do `BaseBsn` reagir só a 504, e o health check logar o payload no Blob
- A verificação de erro distingue "não deu 200" de "deu 200 com JSON vazio" — os dois quebram, mas
  a mensagem diz qual

---

## 2. `Core/Services/<Parceiro>Auth/` — autenticação isolada

**Arquivo:** `Core/Services/AlphaTools/AlphaToolsAuthService.cs` (47 linhas)

```csharp
public class AlphaToolsAuthService : IAlphaToolsAuthService
{
    private readonly HttpClient _httpClient;
    private string _apiUrl, _username, _password;

    public AlphaToolsAuthService(IConfiguration configuration)
    {
        _apiUrl   = configuration.GetSection("AlphaToolsCredentials")["UrlApi"];
        _username = configuration.GetSection("AlphaToolsCredentials")["Username"];
        _password = configuration.GetSection("AlphaToolsCredentials")["Password"];

        _httpClient = new() { BaseAddress = new Uri($"{_apiUrl?.Trim(' ', '\\', '/')}/") };
    }

    // O serviço de negócio ENVOLVE sua chamada aqui dentro
    public async Task<TResult> ExecuteWithAuthenticationAsync<TResult>(
        HttpClient httpClient, Func<Task<TResult>> func, CancellationToken cancellationToken = default)
    {
        SetAuthHttpClient(httpClient);
        return await func.Invoke().ConfigureAwait(false);
    }

    private void SetAuthHttpClient(HttpClient httpClient)
    {
        if (httpClient is null) throw new ArgumentNullException(nameof(httpClient));

        var credentials = Encoding.ASCII.GetBytes($"{_username}:{_password}");
        httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Basic", Convert.ToBase64String(credentials));
    }
}
```

E o consumo, no serviço de negócio:

```csharp
return await _alphaToolsAuthService.ExecuteWithAuthenticationAsync(_httpClient, async () =>
{
    string requestUrl = "/api/2/sync/portfolio/get_portfolio_assets_for_display";
    // ... monta corpo e chama
});
```

**Padrão a extrair:** o serviço de negócio **não sabe como autentica**. Ele passa seu `HttpClient` e um
delegate; o `*AuthService` decora e executa. Trocar Basic por OAuth, ou renovar token expirado com retry,
acontece num arquivo só, sem tocar em nenhum dos ~30 métodos do serviço de negócio.

É o par `XpAuth`/`XpWealth`, `ItauAuth`/`ItauIntrag`, `B3Auth`/`B3Imbarq` que aparece 8 vezes em `Services/`.

⚠️ **Ressalva:** este exemplo específico monta credencial a cada chamada e não cacheia token. Serve como
molde da *forma*, não da eficiência — o `XpAuth` faz o mesmo contrato com cache e mTLS.

---

## 3. `Core/Application/BSN/` — service de negócio

**Arquivo:** `Core/Application/BSN/Fila/FilaProcessamentoBsn.cs` (243 linhas)

Escolhi este porque é um BSN **de tamanho saudável** — os grandes (`TradeBsn`, 12.604 linhas) mostram o
anti-padrão, não o padrão.

```csharp
public class FilaProcessamentoBsn : BaseBsn<FilaProcessamentoBsn>, IFilaProcessamentoBsn
{
    private readonly IServiceProvider _serviceProvider;
    private readonly WhgContext _whgContext;
    private readonly IPublisherSubscriberService _publisherSubscriberService;

    public FilaProcessamentoBsn(
        IServiceProvider serviceProvider,
        WhgContext whgContext,
        IPublisherSubscriberService publisherSubscriberService) : base(serviceProvider)
    {
        _serviceProvider = serviceProvider;
        _whgContext = whgContext;
        _publisherSubscriberService = publisherSubscriberService;
    }
```

Consulta com prioridade — a fila em tabela na prática:

```csharp
    public async Task<TbFilaProcessamento> GetProcessamentoPendenteAsync(
        string tpFilaProcessamento, int? idFilaProcessamento, bool processamentoSincrono = false)
    {
        int idFilaProcessamentoStatus = processamentoSincrono
            ? 10  /* Pendente Sincrono */
            : 1;  /* Pendente */

        return await _whgContext.TbFilaProcessamento
            .Where(f => idFilaProcessamento == null || f.IdFilaProcessamento == idFilaProcessamento.Value)
            .Where(f => f.IdFilaProcessamentoStatus == idFilaProcessamentoStatus
                     && f.TpProcessamento.Equals(tpFilaProcessamento))
            .OrderByDescending(f => f.NrPrioridade)
            .Take(1)
            .SingleOrDefaultAsync();
    }
```

Escrita de log com escopo **próprio** de `DbContext` — porque o job roda por horas e o contexto de
longa duração acumularia change tracker:

```csharp
    public async Task PersistLogAsync(int idFilaProcessamento, string tpLog, string descLog,
        string idUsu, bool checkCancelamento = true, IServiceProvider serviceProviderN = null)
    {
        if (idFilaProcessamento == 0) return;

        if (descLog != null && descLog.Length > 500)
            descLog = descLog.Substring(0, 500);   // coluna tem 500 — trunca antes de estourar

        var whgContextScoped = (serviceProviderN ?? _serviceProvider)
            .CreateScope().ServiceProvider.GetRequiredService<WhgContext>();

        var processo = await GetFilaProcesssoAsync(idFilaProcessamento, whgContextScoped);

        processo.TbFilaProcessamentoLogAtividade.Add(new TbFilaProcessamentoLogAtividade
        {
            TpLog = tpLog, DescLog = descLog,
            IdFilaProcessamento = idFilaProcessamento, IdUsu = idUsu
        });

        if (checkCancelamento && processo.IdFilaProcessamentoStatus == 5 /* Pendente Cancelamento */)
        {
            processo.DtFimProcessamento = DateTime.Now;
            processo.IdFilaProcessamentoStatus = 7; /* Cancelado */
        }
        // ...
    }
```

**Padrão a extrair:**

- Herda `BaseBsn<TSelf>` e implementa `I<Nome>Bsn` — é isso que faz o registro automático no DI funcionar
- Dependências **de negócio** no construtor; logger/mapper/config vêm da base
- Escopo de DI criado sob demanda para operações longas
- Truncar antes de gravar em vez de deixar o SQL lançar
- ⚠️ Status como número mágico com comentário ao lado (`== 5 /* Pendente Cancelamento */`) — é o
  candidato óbvio a virar enum. Copie a estrutura, não isso.

---

## 4. `Core/Application/Interfaces/BSN/` — contrato de negócio

**Arquivo:** `Core/Application/Interfaces/BSN/IPortfolioTaxaBsn.cs`

```csharp
namespace Application.Interfaces.BSN
{
    public interface IPortfolioTaxaBsn : IBaseBsn
    {
        Task<List<PortfolioTaxaCliente>> GetPortfolioTaxaEscopoAsync(PortfolioTaxa req, CancellationToken cancellationToken = default);
        Task<List<PortfolioTaxa>>        GetPortfolioTaxaAsync(GetPortfolioTaxaRequest req, CancellationToken cancellationToken = default);
        Task SavePortfolioTaxaAsync(PortfolioTaxa req, CancellationToken cancellationToken = default);

        void RemoverFaixa(int idTipoTaxa, TbPortfolioTaxa model);
        void CreateAndValidateFaixa(int idTipoTaxa, TbPortfolioTaxa model, string fieldFaixa = null,
                                    IDictionary values = null, List<TbPortfolioTaxaFaixa> faixasOverride = null);
        void ValidacaoCadastroTaxa(TbPortfolioTaxa model);
        void CadastroFaixas(TbPortfolioTaxa model, List<TbPortfolioTaxaFaixa> faixas);

        Task<(string fileName, string filePath)> ExportArquivoAsync(ExportArquivoPortfolioTaxaDTO request, CancellationToken cancellationToken);
    }
}
```

**Padrão a extrair:**

- `: IBaseBsn` é o marcador que o `ConfigureByBaseInterfaceAndBaseClass` procura para registrar no DI
- Nomes em português de negócio (`ValidacaoCadastroTaxa`, `CadastroFaixas`) misturados com verbos
  técnicos em inglês (`GetAsync`, `SaveAsync`) — inconsistente, mas o vocabulário de domínio ganha
  de "purismo de idioma": um analista entende `CriarFaixa` melhor que `CreateBracket`
- Tupla nomeada como retorno (`(string fileName, string filePath)`) evita criar DTO para dois valores

---

## 5. `Core/Repository.SqlServer/Repositories/` — repositório concreto

**Caso 1 — nada além do CRUD genérico (o mais comum).** `ClasseAtivoRepository.cs`, 15 linhas:

```csharp
public class ClasseAtivoRepository : BaseWriteRepository<WhgContext, TbClasseAtivo>, IClasseAtivoRepository
{
    public ClasseAtivoRepository(IServiceProvider serviceProvider, WhgContext context)
        : base(serviceProvider, context) { }
}
```

E a interface, igualmente vazia:

```csharp
public interface IClasseAtivoRepository : IGenericWriteRepository<TbClasseAtivo> { }
```

O par existe **só para dar nome e registro no DI** — todo o comportamento (`FindAllAsync`,
`BulkCreateAsync`, `BatchUpdateAsync`, `FirstOrDefaultProjectToAsync`...) vem da base.

**Caso 2 — quando precisa de query própria.** `ConfiguracaoRepository.cs`:

```csharp
public class ConfiguracaoRepository : BaseWriteRepository<WhgContext, TbConfiguracao>, IConfiguracaoRepository
{
    public ConfiguracaoRepository(IServiceProvider serviceProvider, WhgContext context)
        : base(serviceProvider, context) { }

    public Task<List<ConfiguracaoDto>> GetConfigsByKeyAsync(
        EConfiguracao chave, string nmAplicacao, CancellationToken cancellationToken = default)
    {
        // FindAllProjectToAsync usa AutoMapper.ProjectTo — a projeção vai para o SQL,
        // não materializa a entidade inteira
        return FindAllProjectToAsync<ConfiguracaoDto>(x =>
            x.NmChave == chave && (string.IsNullOrEmpty(x.NmAplicacao) || x.NmAplicacao == nmAplicacao),
            cancellationToken);
    }

    public async Task<TbConfiguracao> GetConfigByIdAsync(int IdConfiguracao, CancellationToken cancellationToken = default)
        => await FirstOrDefaultAsync(x => x.IdConfiguracao == IdConfiguracao, false, cancellationToken)
                    .ConfigureAwait(false);
}
```

**Padrão a extrair:** o repositório concreto só existe quando há query específica. Se não há, ele é
15 linhas de boilerplate que o DI por convenção transforma em registro automático. É a diferença entre
"repositório genérico único" (que vaza `IQueryable` para todo lado) e "um por agregado" — aqui o
agregado tem nome, mas não paga custo de implementação.

---

## 6. `Core/Repository.SqlServer/Mappings/` — mapeamento EF

**Arquivo:** `Mappings/Whg/TbPortfolioConsolidacaoLiberacaoMap.cs`

```csharp
internal sealed class TbPortfolioConsolidacaoLiberacaoMap : BaseWhgMap<TbPortfolioConsolidacaoLiberacao>
{
    // nome da tabela e schema no construtor — o schema vem de fora
    public TbPortfolioConsolidacaoLiberacaoMap(string schema)
        : base("Tb_Portfolio_Consolidacao_Liberacao", schema, false) { }

    protected override void ConfigureMap(EntityTypeBuilder<TbPortfolioConsolidacaoLiberacao> builder)
    {
        // chave composta, com nome de constraint explícito
        builder.HasKey(e => new { e.IdPortfolioConsolidacao, e.DtLiberacao })
               .HasName("Pk_Tb_Portfolio_Consolidacao_Liberacao");

        builder.Property(e => e.IdPortfolioConsolidacao).HasColumnName("Id_Portfolio_Consolidacao");
        builder.Property(e => e.DtLiberacao).HasColumnName("Dt_Liberacao");
        builder.Property(e => e.IdFilaProcessamentoRelatorio).HasColumnName("Id_Fila_Processamento_Relatorio");
        builder.Property(e => e.IndCheckpoint).HasColumnName("Ind_Checkpoint");
        builder.Property(e => e.IndLiberacaoBloqueada).HasColumnName("Ind_Liberacao_Bloqueada");

        // ⭐ UMA LINHA configura Id_Usu, Dt_Cpu, Dt_Cpu_Fim, Fl_Ativo — deduzindo
        //    das interfaces marcadoras que a entidade implementa
        builder.ConfiguraBaseEntity();

        builder.HasOne(d => d.IdPortfolioConsolidacaoNavigation)
            .WithMany(p => p.TbPortfolioConsolidacaoLiberacao)
            .HasForeignKey(d => d.IdPortfolioConsolidacao)
            .OnDelete(DeleteBehavior.ClientSetNull)
            .HasConstraintName("Fk1_Tb_Portfolio_Consolidacao_Liberacao");

        builder.HasOne(d => d.IdFilaProcessamentoRelatorioNavigation)
            .WithMany(p => p.TbPortfolioConsolidacaoLiberacao)
            .HasForeignKey(d => d.IdFilaProcessamentoRelatorio)
            .OnDelete(DeleteBehavior.ClientSetNull)
            .HasConstraintName("Fk2_Tb_Portfolio_Consolidacao_Liberacao");
    }
}
```

Variante com conversão de coluna, do `TbExtracaoDinamicaMap`:

```csharp
builder.Property(e => e.JsonCampos).HasConversionJsonString().HasColumnName("Json_Campos");
builder.Property(e => e.TpCallPut).HasConversionEnumString().HasColumnName("Tp_Call_Put");
builder.HasIndex(e => e.NmExtracaoDinamica).HasDatabaseName("Uk_Extracao_Dinamica_Nm");
```

**Padrão a extrair:**

- `internal sealed` — o mapping nunca é referenciado fora do projeto de repositório
- `schema` injetado no construtor permite a mesma entidade em schemas diferentes
- **Todo nome de constraint é explícito** (`Pk_`, `Fk1_`, `Uk_`). Sem isso, o EF gera nomes aleatórios e
  a mensagem de erro traduzida (seção 4.7 da análise) não teria o que mostrar ao usuário
- `ConfiguraBaseEntity()` é o ponto onde estrutura vira comportamento

---

## 7. `Core/Domain/Entities/` — entidade

**Arquivo:** `Core/Domain/Entities/Fila/TbFilaProcessamento.cs`

```csharp
namespace Domain.Entities.Fila
{
    //  ↓ a linha de declaração É a ficha técnica: auditoria + histórico temporal automáticos
    public class TbFilaProcessamento : IIdUsuEntity, IDtCpuEntity
    {
        public TbFilaProcessamento()
        {
            // coleções inicializadas no construtor — evita null em navegação
            TbFilaProcessamentoArquivo      = new HashSet<TbFilaProcessamentoArquivo>();
            TbFilaProcessamentoLogAtividade = new HashSet<TbFilaProcessamentoLogAtividade>();
            TbPortfolioConsolidacaoLiberacao= new HashSet<TbPortfolioConsolidacaoLiberacao>();
            TbBatimentoTaxaMesRun           = new HashSet<TbBatimentoTaxaMesRun>();
            TbFilaProcessamentoFilho        = new HashSet<TbFilaProcessamento>();
        }

        public int       IdFilaProcessamento { get; set; }        // Id_  → chave
        public string    TpProcessamento { get; set; }            // Tp_  → tipo
        public int       IdFilaProcessamentoStatus { get; set; }
        public string    JsonRequest { get; set; }                // Json_→ payload livre
        public DateTime  DtEntradaFila { get; set; }              // Dt_  → data
        public DateTime? DtInicioProcessamento { get; set; }
        public DateTime? DtFimProcessamento { get; set; }
        public int       NrPrioridade { get; set; }               // Nr_  → número
        public string    IdUsuSolicitacao { get; set; }
        public int?      IdFilaProcessamentoPai { get; set; }     // auto-relacionamento

        // exigidos pelas interfaces marcadoras
        public string    IdUsu { get; set; }
        public DateTime  DtCpu { get; set; }
        public DateTime  DtCpuFim { get; set; }

        // navegações — sufixo Navigation é convenção do scaffold do EF
        public virtual TbFilaProcessamentoStatus FilaProcessamentoStatusNavigation { get; set; }
        public virtual TbFilaProcessamento       IdFilaProcessamentoPaiNavigation { get; set; }
        public virtual ICollection<TbFilaProcessamentoArquivo>      TbFilaProcessamentoArquivo { get; set; }
        public virtual ICollection<TbFilaProcessamentoLogAtividade> TbFilaProcessamentoLogAtividade { get; set; }
        public virtual ICollection<TbFilaProcessamento>             TbFilaProcessamentoFilho { get; set; }
    }
}
```

**Padrão a extrair:**

- Entidade é POCO puro: sem atributo, sem `using` de EF, sem lógica. Todo o mapeamento vive no `*Map`
- As interfaces na assinatura **valem mais que um comentário** — geram auditoria e temporal table
- Prefixo de coluna preservado na propriedade: você lê `NrPrioridade` e sabe que é numérico
- `HashSet` no construtor evita `NullReferenceException` ao adicionar filho antes do primeiro load

---

## 8. `Core/Application/Models/` — contrato de API

Um arquivo por classe, sempre. Pares `*Request` / `*Response` no mesmo diretório da feature.

**Entrada simples** (`Models/Portfolio/PortfolioExternalLoginRequest.cs`):

```csharp
namespace Application.Models.Portfolio
{
    public class PortfolioExternalLoginRequest
    {
        public string Token { get; set; }
        public string Password { get; set; }
    }
}
```

**Entrada com paginação** — herda o contrato de paginação em vez de repetir os campos:

```csharp
public class GetClienteRequest : PaginationParams   // PageNumber, PageSize
{
    public string         Nome { get; set; }
    public string         CpfCnpj { get; set; }
    public ETipoCliente?  TipoCliente { get; set; }     // nullable = filtro opcional
    public DateTime?      DataCriacaoInicio { get; set; }
    public DateTime?      DataCriacaoFim { get; set; }
    public string         OrderBy { get; set; } = "DataCriacao";
    public string         OrderDirection { get; set; } = "desc";
}
```

**Padrão a extrair:**

- `Models/` é contrato **público** (entra e sai da API). `DTOs/` é transporte **interno**. A separação
  evita que mudar um DTO quebre parceiro
- Filtro sempre `nullable` — `null` significa "não filtrar", e não "filtrar por zero"
- Default de ordenação no próprio contrato, não espalhado no service
- 42 subpastas em `Models/`, uma por assunto — mesmo nome da pasta em `BSN/` e em `Domain/Entities/`

---

## 9. `Core/Domain/Validators/` — validação

**Arquivo:** `Core/Application/Models/Boleta/Validators/BoletaMargemValidator.cs`

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

A extension que torna isso possível (`Domain/Extensions/ValidatorExtension.cs`):

```csharp
public static IRuleBuilderOptions<T, decimal> DeveSerMaiorQueZero<T>(this IRuleBuilder<T, decimal> ruleBuilder)
    => ruleBuilder.GreaterThan(0).WithMessage(_messageDomain.DeveSerMaiorQueZero());
```

E a base, que dá acesso ao container para regras que precisam consultar o banco:

```csharp
public abstract class BaseValidator<T> : AbstractValidator<T>
{
    private readonly ConcurrentDictionary<Type, object> _services = new();
    protected readonly IServiceProvider _serviceProvider;

    protected IMessageDomainService MessageDomain => GetService<IMessageDomainService>();

    protected TService GetService<TService>() =>
        (TService)_services.GetOrAdd(typeof(TService), t => _serviceProvider.GetRequiredService(t));
}
```

**Padrão a extrair:** a regra técnica (`GreaterThan(0)`) e a mensagem (`MessageDomain.json`) ficam
escondidas atrás de um nome de negócio. O validador vira lista de requisitos legível por não-programador.
Sobrecargas para `int`, `int?`, `decimal`, `decimal?` existem só para a chamada continuar sendo uma linha.

---

## 10. `Core/IoC/CustomOptions/` — configuração dinâmica

**O config** (`WebJobCustomOptionsConfig.cs`, 23 linhas):

```csharp
public class WebJobCustomOptionsConfig : BaseCustomOptionsConfig<WebJobCustomOptions>
{
    //                          ↓ a chave na tabela Tb_Configuracao
    public WebJobCustomOptionsConfig(IServiceProvider serviceProvider, IConfiguration configuration)
        : base(EConfiguracao.ConfigWebJob, serviceProvider, configuration) { }

    protected override async Task LoadOptionsAsync(CancellationToken cancellationToken = default)
    {
        // este só lê do banco; outros usam LoadOptionsFromAppsettingsAndDatabaseAsync
        await LoadOptionsFromOnlyDatabaseAsync(true, cancellationToken).ConfigureAwait(false);
    }
}
```

**O POCO** (`Domain/Options/WebJobCustomOptions.cs`, 16 linhas):

```csharp
public class WebJobCustomOptions : ICloneable
{
    public bool               Enabled { get; set; }
    public WorkerConfig[]     Workers { get; set; }
    public BusConsumerConfig[] Consumers { get; set; }

    public object Clone() => MemberwiseClone();   // exigido: Current retorna cópia

    public record WorkerConfig(string NmWorker, bool Enabled, string CronJob);
    public record BusConsumerConfig(string NmConsumer, bool Enabled,
                                    int? MaxConcurrentCalls, int? Prefetch, int? LockRenewalMinutes);
}
```

**Padrão a extrair:**

- Duas classes por configuração: o POCO (em `Domain`, sem dependência) e o loader (em `IoC`)
- `ICloneable` + `Clone()` não é decoração — `BaseCustomOptionsConfig.Current` devolve
  `(T)_current?.Clone()`, então ninguém corrompe a instância singleton
- `record` posicional para configuração aninhada: imutável e conciso
- **É aqui que mora o cron dos jobs.** Mudar `CronJob` numa linha da `Tb_Configuracao` reagenda um
  worker em produção sem deploy

---

## 11. `Core/Services/Messaging/Contexts/` — produtor de mensagem

**Arquivo:** `Contexts/Finance/FinanceReceitaMessagingService.cs`

```csharp
public class FinanceReceitaMessagingService
    : BaseMessagingService<FinanceReceitaMessagingService>, IFinanceReceitaMessagingService
{
    public FinanceReceitaMessagingService(
        ILogger<FinanceReceitaMessagingService> logger,
        ServiceBusClient serviceBusClient,
        ICustomOptions<BusQueuesCustomOptions> customOptions,
        IDomainConfig domainConfig)
        : base(logger, serviceBusClient, customOptions, domainConfig) { }

    // corpo do método: uma linha. Nome da fila vem da configuração dinâmica.
    public Task SendMessageAsync(FinanceReceitaProcessamentoDto message, CancellationToken cancellationToken = default)
        => SendMessageAsync(_busQueues.FinanceReceitaProcessamento, message);
}
```

**O contrato da mensagem** (`Domain/Messaging/Contracts/Finance/FinanceReceitaProcessamentoDto.cs`):

```csharp
public class FinanceReceitaProcessamentoDto : IMessagingContract
{
    public string   TpProcessamento { get; set; }
    public DateTime DtInicio { get; set; }
    public DateTime DtFim { get; set; }
    public string   DescObservacao { get; set; }

    public IMessagingProperties Properties { get; set; }   // preenchido pelo consumer
}
```

**Padrão a extrair:** o serviço concreto é trivial porque a base carimba metadados (`CorrelationId`,
`MessageType`, `RequestUser`, `NmAplicacao`) em toda mensagem. O nome da fila vive na configuração,
não no código — dá para redirecionar tráfego sem deploy. Uma pasta por **contexto de negócio**
(`Finance`, `Compliance`), não por fila.

---

## 12. `Jobs/<Job>/` — worker agendado

**O `Program.cs` inteiro** (`Jobs/WebJobTablesToDatalake/Program.cs`):

```csharp
class Program
{
    public static async Task Main(string[] args)
    {
        var factory = new ProgramFactory<Program>(args);

        factory.CommandTimeoutDb = TimeSpan.FromDays(2);   // job pesado: timeout próprio de banco

        factory.AddWorker<TablesToDatalakeWorker>();

        await factory.StartAsync().ConfigureAwait(false);
    }
}
```

**O worker inteiro** (`Workers/TablesToDatalakeWorker.cs`, 33 linhas):

```csharp
public class TablesToDatalakeWorker : BaseWebJobWorker<TablesToDatalakeWorker>
{
    private readonly ICustomOptions<TablesToDatalakeCustomOptions> _options;
    private readonly ITablesToDatalakeBsn _tablesToDatalakeBsn;

    public TablesToDatalakeWorker(
        ICustomOptions<TablesToDatalakeCustomOptions> options,
        ITablesToDatalakeBsn tablesToDatalakeBsn,
        ILogger<TablesToDatalakeWorker> logger) : base(logger)
    {
        _options = options;
        _tablesToDatalakeBsn = tablesToDatalakeBsn;
    }

    // liga/desliga vem do banco
    protected override bool IsEnabled() => _options.Current?.Enabled == true;

    // TODO o trabalho é uma chamada ao BSN — o job é só o gatilho
    protected override Task WorkAsync(CancellationToken cancellationToken = default)
        => _tablesToDatalakeBsn.TablesToDatalakeAsync(cancellationToken);
}
```

**Padrão a extrair:** o job **não tem lógica**. Host, logging, telemetria, cron, shutdown gracioso e
heartbeat vêm do `ProgramFactory` + `BaseWebJobWorker`. O worker só declara: estou ligado? e chame este
BSN. Isso é o que permite 17 jobs somarem apenas 6.625 linhas — e é o que faz a mesma regra rodar
igual pela API e pelo batch.

`CommandTimeoutDb` no `Program.cs` mostra a granularidade: cada processo escolhe seu timeout de banco
(a API usa 180s; este usa 2 dias).

---

## 13. `Jobs/<Job>/Consumers/` + `Handlers/` — consumo de fila

**O consumer inteiro** (`Consumers/FinanceReceitaConsumer.cs`, 17 linhas):

```csharp
internal class FinanceReceitaConsumer
    : BaseWebJobBusConsumer<FinanceReceitaConsumer, FinanceReceitaHandler, FinanceReceitaProcessamentoDto>
    //                       ↑ ele mesmo          ↑ quem processa      ↑ contrato da mensagem
{
    public FinanceReceitaConsumer(IServiceProvider serviceProvider) : base(serviceProvider) { }

    protected override string GetQueueName(BusQueuesCustomOptions busQueues)
        => busQueues.FinanceReceitaProcessamento;
}
```

**O handler** (`Handlers/FinanceReceitaHandler.cs`):

```csharp
internal class FinanceReceitaHandler : IBaseWebJobQueueHandler<FinanceReceitaProcessamentoDto>
{
    private readonly IReceitasBsn _receitasBsn;
    // ... outras deps

    public async Task HandleAsync(FinanceReceitaProcessamentoDto message, CancellationToken cancellationToken = default)
    {
        if (message == null) throw new ArgumentNullException(nameof(message));

        cancellationToken.ThrowIfCancellationRequested();

        await _receitasBsn.DoReprocessamentoAsync(message, cancellationToken);
    }
}
```

**Padrão a extrair:** três genéricos amarram consumer, handler e contrato **em tempo de compilação** —
não dá para plugar o handler errado numa fila. O consumer só resolve o nome da fila (que vem de config);
o handler só delega ao BSN. Concorrência, prefetch, renovação de lock, escopo de DI por mensagem,
`Complete`/`Abandon` — tudo na base.

Registro no `Program.cs` do job:

```csharp
var factory = new ProgramFactory<Program>(args, isBusConsumers: true);
factory.AddBusConsumer<FinanceReceitaConsumer>();
factory.AddBusConsumer<CompliancePldConsumer>();
await factory.StartAsync();
```

---

## 14. `PrismaService/HealthCheck/` — verificação ativa

**Arquivo:** `HealthCheck/HealthCheckAddepar.cs`

```csharp
public class HealthCheckAddepar : HealthCheckBase<HealthCheckAddepar>
{
    private readonly IAddeparService _addeparService;
    private readonly IInstrumentalizacaoBlobService _instrumentalizacaoBlobService;

    public HealthCheckAddepar(IAddeparService addeparService, IServiceProvider serviceProvider,
        IInstrumentalizacaoBlobService instrumentalizacaoBlobService) : base(serviceProvider)
    {
        _addeparService = addeparService;
        _instrumentalizacaoBlobService = instrumentalizacaoBlobService;
    }

    protected override async Task CustomCheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        // chamada REAL ao parceiro, com janela conservadora (D-10 a D-5)
        var response = await _addeparService.GetHealthCheckTransactionsByDate(
            DateTime.Now.AddDays(-10), DateTime.Now.AddDays(-5));

        if (response?.IsSuccessStatusCode != true)
        {
            var message = await response.Content.ReadAsStringAsync();

            // payload COMPLETO vai pro Blob (para investigar depois)
            await _instrumentalizacaoBlobService.SendLogRequestToBlobAsync(
                "", "", null, (int?)response?.StatusCode, response.Content, cancellationToken: cancellationToken);

            // mensagem CURTA sobe como exceção (o que aparece no painel)
            throw new CustomException(
                $"Api retornou um código diferente de sucesso => StatusCode: {(int)response.StatusCode} {response.StatusCode}",
                new CustomException($"{message.Truncate(500)}"));
        }
    }
}
```

**Padrão a extrair:**

- A base cuida de escopo de log, try/catch e conversão em `Healthy`/`Unhealthy`; o filho só implementa
  a pergunta
- Health check que **realmente chama** o parceiro — não é `return Healthy()` decorativo
- Janela histórica (D-10 a D-5) evita falso negativo por dado ainda não disponibilizado
- **Separação log curto / payload longo:** o que se lê no alerta ≠ o que se investiga depois

---

## 15. `PrismaService/Controllers/DevEx/` — controller

**Arquivo:** trecho do `Controllers/DevEx/Consolidacao/ConsolidacaoController.cs`

Action simples — delega e loga, sem try/catch (o filtro global cuida):

```csharp
/// <summary>
/// Criar ou atualizar uma carteira
/// </summary>
[HttpPost("wallet/createOrUpdateWallet")]
[Produces("application/json")]
[Authorize]
public async Task<int> CreateOrUpdateWallet(WalletRequest request)
{
    var payload = JsonConvert.SerializeObject(request);
    _logger.LogInformation($"Payload: {payload}");

    return await _portfolioBsn.CreateOrUpdateWalletAsync(request);
}
```

Action que devolve arquivo:

```csharp
[HttpPost("portfolios/exportControleAcessoChecker")]
[Authorize]
public async Task<FileStreamResult> ExportControleAcessoChecker()
{
    (var memoryStream, var filePath) = await _portfolioBsn.ExportControleAcessoCheckerAsync(HttpContext.RequestAborted);

    return File(memoryStream, Common.Auxiliar.FileUtil.GetContentType(filePath), "ExportAcessos.xlsx");
}
```

Action com grid DevExtreme — o padrão de 61% das rotas:

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
        NrCpfCnpjTitular = i.NrCpfCnpjTitular.ToMaskCPFCNPJ(),   // extension de Common
        i.NmMaster, i.NmRm, i.NmInvestor, i.FlAtivo
    }).OrderBy(i => i.IdCliente);

    return Json(await DataSourceLoader.LoadAsync(query, loadOptions));
}
```

**Padrão a extrair:**

- `HttpContext.RequestAborted` como `CancellationToken` — usuário fecha a aba, a query para
- Projeção anônima devolve só o necessário, e o mascaramento de PII é uma extension inline
- `[Authorize]` cobre autenticação; a autorização real (qual endpoint, quais clientes) é do
  `ApplicationApiHandler`
- ⚠️ Copie a primeira e a segunda action. A terceira funciona, mas é onde o backend se acopla ao
  protocolo de grid do front — e é por isso que 59% das controllers acabam injetando `WhgContext` direto

---

## 16. `Core/Services/B3Imbarq/Dtos/` — layout posicional declarativo

**Arquivo:** `Dtos/Imbarq013/Imbarq013Registro20Dto.cs`

```csharp
//         ↓ só processa linhas cujas posições 1-2 sejam "20"
[FilterPositionalData(1, 2, "20")]
public class Imbarq013Registro20Dto : IPositionalDataItem<Imbarq013Registro20Dto>
{
    [PositionData(1, 2)]     public int    TpRegistro { get; set; }
    [PositionData(3, 17)]    public string CodParticipanteSolicitante { get; set; }
    [PositionData(18, 32)]   public string CodInvestidorSolicitante { get; set; }
    [PositionData(33, 47)]   public string CodParticipanteSolicitado { get; set; }
    [PositionData(63, 81)]   public long   NrOferta { get; set; }
    [PositionData(82, 83)]   public int    Situacao { get; set; }

    [DateOnlyPositionData(86, 95, "yyyy-MM-dd")]
    public DateOnly DtCriacaoOferta { get; set; }

    [PositionData(96, 102)]  public string ParticipanteDoador { get; set; }
    [PositionData(103, 117)] public string InvestidorParticipanteDoador { get; set; }
    // ...
}
```

Uso:

```csharp
var arquivo = PositionalDataUtil.DeserializarFile<Imbarq013>(conteudo);
```

**Padrão a extrair:** o arquivo C# vira **transcrição literal do manual de layout do parceiro**.
Conferir código contra a documentação da B3 é comparação visual, linha a linha. Zero `substring`,
zero bug de deslocamento. Existem atributos especializados por tipo (`DecimalPositionData` com casas
decimais implícitas, `DateOnlyPositionData` com formato). São 11 layouts implementados assim.

Se você lê qualquer arquivo de largura fixa — banco, CETIP, SPED, CNAB — este é o padrão mais valioso
deste repositório inteiro.

---

## Resumo: o formato que se repete

Reparando nos 16 exemplos, o mesmo esqueleto aparece em toda camada:

```
Base<T> abstrata           →  cuida do ritual (log, escopo, try/catch, timer, retry)
   ↑
Classe concreta            →  implementa 1 método abstrato + declara dependências
   ↑
Interface marcadora        →  faz o DI registrar automaticamente
```

| Camada | Base | Método abstrato | Marcador |
|---|---|---|---|
| Negócio | `BaseBsn<T>` | — (livre) | `IBaseBsn` |
| Repositório | `BaseWriteRepository<TCtx,TEnt>` | — (livre) | `IRepository` |
| Mapping | `BaseEntityMap<T>` | `ConfigureMap` | — (por herança) |
| Cache | `BaseRepositoryCache` | `GetDefaultExpiry` | `IBaseRepositoryCache` |
| Config | `BaseCustomOptionsConfig<T>` | `LoadOptionsAsync` | `ICustomOptions` |
| Integração | `BaseHttpClientService<T,O>` | `HttpClient`, `Options` | — |
| Mensageria | `BaseMessagingService<T>` | — | `IBaseMessagingService` |
| Worker | `BaseWebJobWorker<T>` | `WorkAsync` | `IBaseWebJobWorker` |
| Consumer | `BaseWebJobBusConsumer<T,H,C>` | `GetQueueName` | `IBaseWebJobBusConsumer` |
| Health check | `HealthCheckBase<T>` | `CustomCheckHealthAsync` | `IHealthCheck` |
| Validação | `BaseValidator<T>` | — (regras no ctor) | — |

**Aprenda uma, aprendeu todas.** É a mesma economia cognitiva do espelhamento de pastas, aplicada a
classes — e é o motivo real de 380 mil linhas continuarem navegáveis.
