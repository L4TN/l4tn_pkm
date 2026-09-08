# Runtime e Composition Root

## 1. O Prisma é uma plataforma com três executáveis

O código compartilhado atende três formas de execução:

| Runtime | Entrada | Responsabilidade |
|---|---|---|
| API interna | `PrismaService/Program.cs` + `Startup.cs` | Operação interna, Controllers DevEx, autenticação corporativa |
| API externa | `PrismaServiceExternal/Program.cs` + `Startup.cs` | Endpoints expostos a parceiros/clientes externos |
| WebJobs | `Jobs/*/Program.cs` + `Jobs/CommonWebJob/ProgramFactory.cs` | Cargas agendadas, consumidores e processamento assíncrono |

A composição é compartilhada por `Core/IoC/DependencyInjectionExtencion.cs` através de
`ConfigureIoC`. Isso evita que cada processo tenha sua própria interpretação de como registrar
repositories, serviços, options, validators e BSNs.

## 2. Sequência de composição

`ConfigureIoC` organiza o boot em blocos:

```text
Options
  -> CustomOptions
  -> Cache
  -> Validators
  -> Repositories/DbContexts
  -> Services/HttpClients
  -> Service Bus
  -> BSNs
  -> Domain Services
  -> AutoMapper
  -> Startup Tasks
  -> Microsoft Graph
```

A ordem é relevante. Options e infraestrutura ficam disponíveis antes das tarefas de startup; os
startup tasks podem carregar opções, mensagens e certificados antes do primeiro request ou trabalho.

## 3. Convention scanning

`ConfigureByBaseInterfaceAndBaseClass` procura classes concretas em todos os assemblies carregados e
registra implementações que combinam interface-base e classe-base.

O mecanismo é reutilizado para:

- `IRepository` + `BaseRepository<,>`;
- `IBaseBsn` + `BaseBsn<>`;
- `IBaseRepositoryCache` + `BaseRepositoryCache`;
- `IBaseMessagingService` + `BaseMessagingService<>`;
- `ICustomOptions` + `BaseCustomOptionsConfig<>`.

A convenção transforma a estrutura do tipo em configuração executável. Um novo componente é integrado
quando respeita a interface e a classe-base esperadas.

## 4. Lifetime por marker

O scanner consulta `ISingletonInstance` e `ITransientInstance`. Se nenhum marker específico existir,
o componente é registrado como scoped. Isso é usado em especial para options singleton e para serviços
que precisam ser recriados por resolução.

O sistema ganha baixo boilerplate, mas perde visibilidade no composition root. Uma mudança de herança
pode alterar o registro sem alterar `Startup.cs`. Testes de composição e validação do grafo são o
complemento natural desse padrão.

## 5. Estado estático inicializado explicitamente

`DependencyInjection.ConfigureStaticSingletonInstance` configura:

- `Common.Configuration`, com o `IConfiguration` global;
- `ValidatorExtension`, com o `IMessageDomainService`.

Esse método é chamado pela API e pelo `ProgramFactory` dos WebJobs. É uma ponte explícita entre o
container e extensões legadas/estáticas. O benefício é compatibilidade entre runtimes; o custo é que
essas dependências não aparecem no construtor e exigem ordem correta de inicialização.

## 6. API interna e externa

A API interna usa Microsoft Identity, exige usuário autenticado fora de Development e registra o
`ApplicationApiHandler` como filtro global. A externa possui `JwtMiddleware` e helpers próprios para
validar tokens de parceiros.

As duas APIs reutilizam `ConfigureIoC`, `DomainConfigMiddleware` e os serviços compartilhados, mas não
possuem exatamente o mesmo pipeline de segurança. Essa assimetria deve ser considerada ao alterar
tratamento de erros, claims ou autorização.

## 7. WebJobs como host compartilhado

`ProgramFactory<TProgram>` monta o host, carrega configuração comum, configura logging, registra
telemetria, executa startup tasks e cria scopes. Cada worker é registrado como `IBaseWebJobWorker` e
a execução recebe um scope próprio.

O mesmo host suporta dois modos mutuamente exclusivos:

```text
isBusConsumers = false -> AddWorker<TWorker>()
isBusConsumers = true  -> AddBusConsumer<TConsumer>()
```

O desenho impede misturar workers agendados com consumidores no mesmo modo operacional.

## 8. Leitura arquitetural

O composition root é a verdadeira fronteira da aplicação. Ele concentra decisões sobre:

- quais bancos estão disponíveis;
- quais parceiros podem ser chamados;
- qual implementação de autenticação está ativa;
- quais opções são obrigatórias;
- quais tarefas devem rodar no boot;
- quais serviços são singleton, scoped ou transient.

Ao investigar um comportamento do Prisma, o caminho correto começa no executável e no composition root,
não somente na Controller.
