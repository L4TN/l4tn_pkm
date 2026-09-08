# Datalake, Parquet e leitura analítica

## 1. O Datalake tem repository próprio

`Repository.Datalake` não é apenas outro `DbContext`. Ele combina:

- Azure Blob como armazenamento;
- Parquet como formato colunar;
- metadata de entidade/mapping;
- leitura seletiva de colunas;
- escopo reutilizável de reader;
- progresso de processamento;
- repositories específicos de posição, B3 e AUM.

## 2. Leitura orientada a colunas

`BaseReadRepositoryDatalake` cria `ParquetSchema` a partir de `ParquetDataFields` e lê somente as colunas
necessárias para where/select. A expressão informa nomes de propriedades:

```text
Expression where/select
  -> PropertyInfo names
  -> colunas Parquet necessárias
  -> download/reader
  -> entidades
  -> filtro/projeção
```

É uma versão analítica do projection-first usado no EF.

## 3. Scope de Datalake

`BeginScopeDatalake` cria `ScopeDatalakeConfig` com cache de readers por arquivo e diretório temporário.
Ao dispor o scope, readers, colunas e arquivos temporários são limpos.

Isso permite que uma operação leia vários arquivos sem baixar/reabrir tudo a cada chamada.

## 4. Leitura paralela e progresso

A leitura de múltiplos Parquets usa `Parallel.ForEachAsync`, `ConcurrentBag` e callback de progresso.
Arquivos duplicados são agrupados antes da leitura.

O pattern é adequado para cargas grandes, mas precisa controlar:

- paralelismo contra Blob;
- memória de materialização;
- cancelamento;
- tempo de vida do scope;
- limpeza de arquivos temporários.

## 5. Datalake como fonte histórica

Repositories como `PosicaoConsolidadaRepositoryDatalake` suportam data específica, última posição,
existência, seleção e leitura de múltiplos arquivos. O consumidor não precisa conhecer download Blob,
ParquetReader ou path físico.

```text
BSN -> repository Datalake -> Blob/Parquet
```

## 6. Distinção importante

EF traduz expressão para SQL. O repository Parquet compila a expressão e aplica em entidades carregadas
após ler colunas. A mesma assinatura de repository esconde mecanismos de execução diferentes.

Isso é uma abstração poderosa, mas performance deve ser avaliada separadamente para SQL e Parquet.
