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
