# Persistência, contextos e fronteiras de dados

## 1. Vários contextos para vários mundos de dados

O Prisma não trata todas as tabelas como um único modelo indiferenciado. `ConfigureRepositories` registra
contextos SQL Server separados:

- `WhgContext`;
- `FinanceiroContext`;
- `LiveContext`;
- `XpPosiContext`;
- `ArquivoDePosicaoContext`;
- `OutSystemsContext`;
- `CreditoContext`;
- `SocietarioContext`;
- `ImbarqContext`;
- `SignatureContext`;
- `ReceitaContext`;
- `DatalakeDboContext`.

A configuração de conexão e timeout é compartilhada, mas o modelo, schema e responsabilidade permanecem
separados. Isso permite cruzar fontes conscientemente em BSNs de consolidação, auditoria e reconciliação.

## 2. Mapping automático por família

`Repository.SqlServer/BaseDbContext.cs` define um schema padrão e chama `AutomaticApplyModelCreating`
para as famílias de mapping:

```text
BaseWhgMap<>              -> dbo
BaseFinanceiroMap<>      -> financeiro
BaseLiveMap<>             -> live
BaseOutSystemsMap<>       -> outsystems
BaseXpPosiMap<>           -> xp_posi
BaseCreditoMap<>          -> credito
BaseSocietarioMap<>       -> societario
BaseSignatureMap<>        -> signature
BaseReceitaMap<>          -> receita
BaseArquivoDePosicaoMap<> -> xml
```

Esse padrão combina convenção de namespace, classe-base e schema físico. O mapping específico contém a
diferença; o registro de centenas de entidades não é repetido no contexto.

## 3. Repository base orientado a consulta

`BaseReadRepository<TDbContext,TEntity>` abstrai consultas comuns sem impedir expressões específicas.
Ele oferece:

- query como `IQueryable` quando composição é necessária;
- `AsNoTracking` opcional;
- `Select` tipado;
- `ProjectTo` para DTOs;
- agrupamento, ordenação e paginação;
- `FirstOrDefault`, `Single`, `Exists`, `Count`, `Min` e `Max`;
- cancelamento assíncrono.

A decisão mais importante é permitir projeção no banco:

```text
Entity -> ProjectTo<Dto>() -> SQL seleciona somente o necessário
```

Isso evita materializar grandes entidades quando o endpoint só precisa de um contrato de resposta.

## 4. Escrita em três velocidades

`BaseWriteRepository` oferece níveis diferentes de persistência:

| Nível | Uso |
|---|---|
| `Add`/`Update` + `SaveChanges` | cadastro e alteração transacional comum |
| `BatchUpdate`/`BatchDelete` | alteração SQL em lote sem carregar tudo |
| `BulkInsert`/`BulkUpdate`/`BulkDelete` | cargas de alto volume |

O Prisma reconhece que cadastro, importação de mercado e processamento de posições não possuem o mesmo
perfil de escrita.

## 5. Auditoria automática na última fronteira

`CommonBaseDbContext` intercepta `SaveChanges` e `SaveChangesAsync`. Para entidades que implementam
`IIdUsuEntity` ou `IIdUsuCriacaoEntity`, preenche o usuário técnico/aplicacional a partir de
`IDomainConfig`.

```text
Qualquer caminho de gravação
  -> ChangeTracker
  -> CustomSaveChanges
  -> usuário de contexto
  -> banco
```

Essa é uma proteção mais forte que preencher auditoria em Controllers, pois também cobre BSNs, jobs e
repositories.

## 6. Integridade traduzida em domínio

`BaseDbContext.HandleExceptions` converte erros SQL Server em `CustomConflictException`. Foreign key,
unique key, duplicate key e truncamento de campo recebem mensagens compreensíveis e, quando possível,
metadados extraídos de schema, tabela, coluna e constraint.

Isso cria uma fronteira clara:

```text
Detalhe técnico do banco -> conflito compreensível para a aplicação/API
```

## 7. Joins entre memória e banco

A extensão `MemoryJoin` aparece em relatórios e BSNs que primeiro calculam uma lista de chaves e depois
precisam filtrar uma tabela. É recorrente em:

- `ReportConsolidacaoBsn`;
- `ReportBaseConsolidacaoBsn`;
- `ClienteBsn`;
- `InstrumentBsn`;
- `AuditoriaRepository`.

O padrão evita SQL manual e permite usar uma lista derivada de outra fonte/contexto como escopo de query.
É especialmente importante quando a operação cruza WHG, XML, XP Posi e Financeiro.

## 8. Cross-context orchestration

A regra de negócio não tenta fingir que todas as fontes estão no mesmo banco. Em vez disso, o BSN ou
repository:

1. consulta uma fonte;
2. calcula chaves e escopo;
3. usa `MemoryJoin` na próxima fonte;
4. normaliza dados;
5. aplica regras temporais;
6. grava no contexto de destino.

Esse é o modelo de consolidação do Prisma. O custo é maior complexidade de consistência e desempenho,
mas o benefício é integrar sistemas que possuem ownership e schemas distintos.

## 9. Datalake como destino especializado

`DatalakeDboContext` possui options e repository próprios. Ele não é tratado simplesmente como mais um
schema transacional: cargas para Datalake são processos operacionais específicos e aparecem em Jobs e
serviços Blob/Synapse.

## 10. Pontos de atenção

- `IQueryable` exposto exige disciplina para não vazar persistência para qualquer camada;
- queries entre contextos não formam uma transação distribuída automaticamente;
- bulk operations podem não executar exatamente os mesmos hooks de entidades carregadas;
- `AsNoTracking` precisa ser escolhido conscientemente antes de alterações;
- contextos scoped não devem ser mantidos em workers por tempo indefinido;
- relatórios enormes devem controlar memória, paginação, locks e cancelamento.
