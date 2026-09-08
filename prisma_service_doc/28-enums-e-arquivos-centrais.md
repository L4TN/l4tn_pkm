# Enums e arquivos centrais reutilizáveis

## 1. Sim: enums são um pattern importante do Prisma

A pasta `Core/Domain/Enums` concentra dezenas de enums por domínio, como:

- `EConfiguracao`;
- `EConsolidacaoSourceReplication`;
- `ETipoIndexador`;
- `ETipoOperacao`;
- `EFormatFile`;
- `ETpProcessamento`;
- `EStatusLiberacaoPortfolio`;
- `EProcessamentoStatus`;
- enums de CRM, Boleta, XML, Posicao e Receita.

O enum é usado para representar código controlado, status, origem, tipo de processamento, formato e
operação sem espalhar strings e números mágicos.

## 2. `DescriptionAttribute` como contrato entre camadas

Muitos enums possuem `[Description("valor funcional") ]`. O valor legível não fica preso à tela:
`EnumExtension.GetDescription` permite usá-lo em mensagens, arquivos, integrações e respostas.

Exemplo conceitual:

```csharp
public enum ETipoOperacao
{
    [Description("Inclusão")]
    Inclusao,

    [Description("Alteração")]
    Alteracao
}
```

O enum possui valor técnico para o código e descrição de domínio para comunicação.

## 3. Conversão centralizada

`Core/Common/Extensions/EnumExtension.cs` fornece:

- `GetDescription()` para obter texto legível;
- `EnumHelper.GetEnumValuesWithDescriptions<T>()` para retornar `Id` + `Descricao`;
- `EnumHelper.GetEnumFromDescription<T>()` para converter texto de volta;
- fallback para o nome do membro quando não existe `Description`.

Isso permite que Controllers e serviços não reimplementem reflexão de enum.

O padrão é especialmente útil para dropdowns e filtros do DevExtreme:

```text
enum de domínio -> EnumHelper -> lista Id/Descrição -> UI
```

## 4. Enums como anti-magic-number

O Prisma ainda possui pontos com números mágicos, principalmente status em fluxos antigos. A direção
mais forte do projeto é substituir:

```csharp
if (status == 5) { ... }
```

por:

```csharp
if (status == EProcessamentoStatus.PendenteCancelamento) { ... }
```

Quando o banco exige código específico, o enum deve documentar o valor e a descrição. O importante é
não mudar o valor persistido sem migration/compatibilidade.

## 5. Limites dos enums

Enums gerados por XML ou contrato externo, como os tipos dentro de `ArquivoDePosicao401.cs`, precisam
ser tratados diferente dos enums de domínio manual. Eles representam schema externo e não devem receber
renomeação casual.

Também há enums dentro de entidades e DTOs. A localização nem sempre é uniforme; ao criar novos tipos,
preferir `Core/Domain/Enums/<Domínio>` quando o enum for compartilhado.

## 6. Arquivos centrais: onde o comportamento realmente se concentra

Os arquivos abaixo funcionam como pontos de alavanca da plataforma:

| Arquivo | Papel |
|---|---|
| `Core/IoC/DependencyInjectionExtencion.cs` | composition root compartilhado, scanning e lifetimes |
| `Core/Application/BSN/Base/BaseBsn.cs` | toolkit de aplicação, retry, locks, batches e resolução de serviços |
| `Core/Repository.Common/Repositories/BaseRepository.cs` | infraestrutura comum dos repositories |
| `Core/Repository.Common/Repositories/BaseReadRepository.cs` | queries, projeções e leitura |
| `Core/Repository.Common/Repositories/BaseWriteRepository.cs` | CRUD, batch e bulk |
| `Core/Repository.Common/CommonBaseDbContext.cs` | auditoria automática em SaveChanges |
| `Core/Repository.SqlServer/BaseDbContext.cs` | schemas, mappings e tradução de erros SQL |
| `Core/IoC/CustomOptions/Base/BaseCustomOptionsConfig.cs` | options arquivo + banco + criptografia |
| `Core/IoC/DomainServices/MessageDomainService.cs` | catálogo de mensagens e contrato validado por reflexão |
| `Core/IoC/StartupTasks/*.cs` | preparação obrigatória no boot |
| `Core/Application/Filters/ApplicationApiHandler.cs` | autorização, timer e resposta de exceção |
| `Core/IoC/Middlewares/DomainConfigMiddleware.cs` | identidade contextual da requisição |
| `Jobs/CommonWebJob/ProgramFactory.cs` | host, workers, consumers e shutdown |
| `Jobs/CommonWebJob/BaseWebJobWorker.cs` | cron, options, logging e ciclo de worker |
| `PrismaService/HealthCheck/Configure/*.cs` | health checks e dashboard |
| `Core/Common/Extensions/*.cs` | capacidades reutilizáveis de linguagem/infraestrutura |

## 7. Como estudar um arquivo central

Para cada base, documentar quatro dimensões:

```text
Quem chama?
Qual estado mantém?
Qual lifetime possui?
Qual contrato todos os consumidores passam a obedecer?
```

Uma classe-base pequena pode alterar centenas de fluxos. Por isso o impacto de `BaseBsn`,
`BaseDbContext`, `ApplicationApiHandler` e `ProgramFactory` é maior que o número de linhas sugere.

## 8. Padrão geral do Prisma

O projeto frequentemente converte convenção em comportamento:

```text
nome/pasta/interface/base/attribute
  -> scanner ou extension
  -> comportamento compartilhado
  -> menos código repetido nos consumidores
```

Enums, markers, attributes, classes-base e extensions são diferentes formas da mesma estratégia:
codificar conhecimento operacional em tipos e estrutura para que o sistema possa reutilizá-lo.
