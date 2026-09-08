# AutoMapper e o sistema de mapeamento do Prisma

## 1. AutoMapper é composição de contratos, não apenas conversão de propriedades

O Prisma configura um `IMapper` singleton em `Core/IoC/DependencyInjectionExtencion.cs`:

```csharp
var mapper = new MapperConfiguration(mc =>
{
    mc.AddProfile(typeof(ApplicationMapperProfile));
    mc.AddProfile(typeof(ApplicationImbarqMapperProfile));
    mc.AddProfile(typeof(DomainMapperProfile));
    mc.AddProfile(typeof(RepositoryCommonMapperProfile));
}).CreateMapper();

services.AddSingleton(mapper);
```

Os profiles são separados por responsabilidade:

| Profile | Responsabilidade |
|---|---|
| `ApplicationMapperProfile` | requests, responses, posições, CRM, consolidação e contratos de aplicação |
| `ApplicationImbarqMapperProfile` | layouts/DTOs Imbarq para entidades persistidas |
| `DomainMapperProfile` | projeções de entidades e DTOs compartilhados do domínio |
| `RepositoryCommonMapperProfile` | configuração de operações bulk |

O mapper único é compartilhado por BSNs e repositories, mas os mapas ficam organizados por camada.

## 2. Três usos diferentes

### Mapeamento em memória

```csharp
var entity = Mapper.Map<TbEntity>(request);
```

Usado para converter requests em entidades, respostas intermediárias e objetos de integração.

### Projeção no banco

```csharp
query.ProjectTo<ClienteDto>(Mapper.ConfigurationProvider);
```

`CreateProjection`/`ProjectTo` permite que a expressão seja traduzida para SQL. O DTO é montado no
banco, reduzindo materialização e evitando carregar colunas que não serão usadas.

### Mapeamento de atualização

```csharp
Mapper.Map(dto, entity);
```

O Prisma usa mapas request → entidade com `IgnoreAllNull()`/conditions para atualizar somente campos
presentes. Isso é importante para PATCH-like updates e para não apagar dados quando o request não trouxe
uma propriedade.

## 3. Separação entre `CreateMap` e `CreateProjection`

O sistema diferencia mapas que precisam executar em memória de projeções que precisam ser traduzíveis
pelo EF Core.

Exemplos de projeção:

- `TbHeader` → `HeaderCarteiraDto`;
- entidades de cliente → `ClDetalhesDto`/`FiDetalhesDto`;
- `TbAtivoCotacao` → `AtivoCotacaoResponse`;
- `TbExtracaoDinamica` → `ExtracaoDinamicaResponse`;
- `TbConfiguracao` → `ConfiguracaoDto`.

O repository base expõe `FindAllProjectToAsync` e `FirstOrDefaultProjectToAsync`, conectando o perfil ao
padrão de consulta:

```text
Repository query
  -> Mapper.ConfigurationProvider
  -> ProjectTo<DTO>
  -> SQL/projeção
```

## 4. Mapas que carregam regra de transformação

Os profiles não fazem somente cópia de nomes. Eles também expressam transformação de contrato:

- `Posicao` → `TbPosicaoConsolidada` troca nomes de origem externa por nomes internos;
- `PosicaoConsolidada` → `Position` define fonte XML, BRL e defaults;
- produto de posição → `TypePosition` por classificação;
- `TypeProvision` é derivado de produto e instrumento;
- contrato societário arredonda valores e deriva `HasArquivo`;
- CRM só aplica IDs/datas quando valores são válidos;
- campos JSON de extração são convertidos para DTOs de resposta;
- `ETpOrigem` vira texto amigável em resposta de consolidação.

Isso torna AutoMapper uma parte da camada de tradução entre modelos, não uma abstração neutra.

## 5. Herança de mappings para layouts de posição

`ApplicationMapperProfile` usa `IncludeBase` para separar campos comuns de campos específicos:

```text
swap_type -> SwapDTO
Swap      -> SwapDTO (IncludeBase + IDs concretos)

futuros_type -> FutureDTO
Futuro       -> FutureDTO (IncludeBase + IDs concretos)

cotas_type -> CotaDTO
Cota       -> CotaDTO (IncludeBase + IDs concretos)
```

O padrão é valioso para XMLs e modelos derivados: o layout base mapeia campos comuns e o tipo persistido
adiciona IDs/relacionamentos que não existem no contrato externo.

## 6. Imbarq: polimorfismo de contrato externo

`ApplicationImbarqMapperProfile` mapeia interfaces como `IImbarqHeader` e `IImbarqTrailer` para entidades
com `Include` de vários DTOs de registro.

Ele também converte strings de layout para enums e números:

```csharp
.ForMember(dest => dest.TpOperacao,
    opt => opt.MapFrom(src => Enum.Parse<EImbarqTpOperacao>(src.NaturezaOperacao)))
```

Esse profile funciona como anti-corruption layer do layout Imbarq:

```text
DTO textual externo -> conversão tipada -> entidade interna
```

## 7. `IgnoreAllNull` como estratégia de update

`AnonymousObjectMutatorExtension` e os resolvers `IgnoreNullResolver`/`IgnoreNullValueResolver`
centralizam a política de não sobrescrever destino com `null`.

O padrão é utilizado em requests de CRM, societário, cliente, capital comprometido e outros cadastros.

Benefício:

```text
request parcial -> somente campos enviados alterados
```

Risco: não é possível representar “quero limpar o campo” somente com `null`. O contrato precisa
oferecer um mecanismo explícito para limpar valores quando necessário.

## 8. Mapeamento com navegações

Alguns mapas percorrem relações profundas:

```text
TbAtivo
  -> TbAtivoFundo
  -> TbAtivoFundoInterno
  -> classificação/estratégia/mercado
  -> AtivoDto
```

Em memória isso depende de navegações carregadas; em projeção, a expressão precisa ser traduzível pelo
EF. O mesmo map não deve ser presumido seguro para os dois modos sem verificar a query gerada.

## 9. Defaults, `Ignore` e segurança de escrita

Os profiles usam `Ignore` para campos que não devem ser preenchidos pelo request ou que dependem de
outra etapa:

- IDs gerados pelo banco;
- navegações;
- dados calculados;
- campos preenchidos pelo contexto;
- propriedades que precisam de regra de negócio.

Isso evita que um DTO de entrada sobrescreva acidentalmente relacionamentos ou identificadores.

## 10. Pontos de atenção

- `CreateMap` com regras complexas pode esconder regra de negócio relevante;
- expressões usadas em `ProjectTo` precisam ser compatíveis com EF Core;
- `ReverseMap` nem sempre é semanticamente seguro para entrada e saída;
- `IgnoreAllNull` pode impedir limpeza intencional;
- maps duplicados ou profiles muito grandes dificultam descobrir qual contrato é canônico;
- `CreateMapper` singleton exige que a configuração seja imutável após o boot;
- `AssertConfigurationIsValid` deveria ser executado em teste/boot para detectar mapas incompletos;
- converter strings externas com `Enum.Parse` precisa de tratamento para valores desconhecidos.

## 11. Como navegar pelo AutoMapper

Ao estudar um endpoint, pesquisar:

```text
CreateMap<Origem, Destino>
CreateProjection<Origem, Destino>
ProjectTo<Destino>
Mapper.Map<Destino>
IgnoreAllNull
IncludeBase
ForMember
```

Depois classificar o mapa:

1. entrada HTTP → entidade;
2. entidade → response;
3. entidade → DTO de query;
4. integração externa → entidade;
5. domínio → modelo de relatório;
6. configuração operacional → contrato.

O valor do AutoMapper no Prisma está em formar uma malha de tradução entre banco, integrações, domínio,
relatórios e API, mantendo a Controller fora da maior parte da conversão estrutural.
