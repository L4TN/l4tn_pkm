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
