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
