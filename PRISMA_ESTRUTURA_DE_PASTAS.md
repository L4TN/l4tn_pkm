# Prisma Service — Mapa de Pastas Comentado

Árvore de diretórios do backend, com a função de cada pasta. Só pastas, sem arquivos.
Níveis expandidos onde a informação é útil; colapsados onde o padrão se repete.

---

## Raiz da solução

```
PrismaService.sln
│
├── Core/                         ⭐ Todas as bibliotecas compartilhadas. Nenhum projeto aqui
│                                    é executável — são referenciados pelas APIs e pelos jobs.
│
├── PrismaService/                🌐 API INTERNA. Autenticação Azure AD, consumida pelo front
│                                    corporativo (DevExtreme). 181 controllers.
│
├── PrismaServiceExternal/        🔌 API DE PARCEIROS. JWT próprio, superfície reduzida,
│                                    Swagger filtrado. 23 controllers.
│
├── Jobs/                         ⚙️ 17 processos background (Azure WebJobs): cargas, cálculos,
│                                    consumers de fila, disparo de e-mail.
│
├── Database/                     🗄️ Scripts SQL versionados por release. 1.287 arquivos.
│                                    O histórico real do banco antes do EF Migrations.
│
├── ReleaseWalkthrough/           📋 Planilhas de funcionalidades por release (artefato de
│                                    processo, não de código).
│
├── WHG1/ · WHGPalette/           🎨 Assets de identidade visual usados nos relatórios.
│
├── azure-pipelines*.yml          🚀 26 pipelines de CI/CD — uma por WebJob + as duas APIs.
└── appsettings.Common.json       ⚙️ Configuração compartilhada por TODOS os processos.
```

---

## `Core/` — o coração compartilhado

```
Core/
│
├── Domain/                       🧠 CAMADA MAIS INTERNA. Não referencia ninguém.
│                                    Entidades, contratos e regras que não dependem de
│                                    banco, HTTP ou framework.
│
├── Application/                  💼 REGRA DE NEGÓCIO. Orquestra Domain + Repositories +
│                                    Services. É onde vivem os BSNs.
│
├── Common/                       🧰 Biblioteca de apoio transversal. Extensions, utils,
│                                    exceções, conversores. Usada por TODAS as camadas.
│
├── IoC/                          🔌 COMPOSITION ROOT. O ConfigureIoC() que API e jobs
│                                    chamam. Também middlewares e startup tasks.
│
├── Repository.Common/            📦 Bases genéricas de repositório e de mapping EF,
│                                    independentes de provedor (SQL Server, Datalake).
│
├── Repository.SqlServer/         🗃️ Persistência principal. 12 DbContexts, 480 mappings.
│
├── Repository.SqlServer.Migrations/  🔄 Projeto SEPARADO só para gerar migrations,
│                                        com customizações no gerador de DDL.
│
├── Repository.Redis/             ⚡ Cache distribuído. Repositórios de cache por domínio.
│
├── Repository.Datalake/          📊 Segundo banco (analítico). Dados brutos e agregados
│                                    que não cabem no operacional.
│
└── Services/                     🌍 INTEGRAÇÕES EXTERNAS. 46 pastas, uma por parceiro/API.
```

**Regra de dependência:** `Domain` não referencia nada. `Application` referencia `Domain` + interfaces
de repositório. `Repository.*` e `Services` implementam as interfaces do `Domain`. `IoC` amarra tudo.

---

## `Core/Domain/` — o modelo

```
Core/Domain/
│
├── Entities/                     🏛️ Entidades mapeadas para tabela (prefixo Tb) e para
│   │                                view (prefixo View). Organizadas por subdomínio.
│   │                                Na raiz ficam as ~51 INTERFACES MARCADORAS
│   │                                (IEntity, IIdUsuEntity, IDtCpuEntity...) que disparam
│   │                                comportamento automático de auditoria e histórico.
│   │
│   ├── Cadastro/                 Ativos, Clientes, Classificações, Fundos, Domínios.
│   │                             O maior subdomínio — é o master data do sistema.
│   ├── Movimentacao/             Boletas (10 tipos), passivo, carrying.
│   ├── Consolidacao/             Carteiras, portfólios, liberações — o núcleo do produto.
│   ├── Posicao/                  Posição por ativo/cliente/data.
│   ├── PosicaoConsolidada/       Posição já agregada (leitura pesada).
│   ├── Performance/              Rentabilidade, atribuição, séries históricas.
│   ├── Proposta/                 Carteira teórica e simulações de alocação.
│   ├── Precos/                   Cotações e indexadores.
│   ├── Autorizacao/              Grupos, funcionalidades, APIs — o modelo de permissão.
│   ├── Compliance/               Regras de enquadramento e restrição.
│   ├── IPS/                      Investment Policy Statement (política do cliente).
│   ├── CRM/ + Crm/               ⚠️ DUAS pastas para o mesmo assunto. Inconsistência real.
│   ├── Fila/                     Fila de processamento em tabela (jobs assíncronos).
│   ├── Arquivo/                  Upload/download e tipos de arquivo.
│   ├── Auditoria/                Registros de auditoria de negócio.
│   ├── BatimentoTxAdm/           Conciliação de taxa de administração.
│   ├── Receita/                  Centro de custo, categorias, gestão de receita.
│   ├── Societarios/              Estrutura societária de clientes.
│   ├── Credito/                  Operações de crédito.
│   ├── Pessoa/                   Cadastro de pessoa física/jurídica e KYC.
│   ├── PortfolioTaxa/            Taxas por portfólio e faixas.
│   ├── Email/ · Disparador/      Templates e disparo de e-mail.
│   ├── ExtracaoDinamica/         Consultas montadas pelo usuário (BI interno).
│   ├── ParamConsulta/            Parâmetros de consultas pré-definidas.
│   ├── Docusign/ · Financeiro/ · Protheus/ · OutSystems/ · Imbarq/ · Live/ · XpPosi/
│   │                             Entidades espelhando sistemas externos ou schemas próprios.
│   ├── Xml/                      Schema XML ANBIMA (arquivo de posição 4.01).
│   ├── Datalake/                 Entidades do banco analítico.
│   ├── Views/                    Read models mapeados para VIEW do banco (prefixo View).
│   └── Util/                     Entidades utilitárias (tutorial, configuração de tela).
│
├── Interfaces/                   📜 CONTRATOS. Domain define, infraestrutura implementa —
│   │                                é o que mantém a inversão de dependência.
│   ├── Repositories/             IGenericReadRepository / IGenericWriteRepository +
│   │                             interfaces específicas por agregado. Tem subpastas
│   │                             Base/, Cache/, Datalake/, Whg/, Societario/, Docusing/.
│   ├── DomainServices/           Serviços de domínio (mensagens, usuário).
│   ├── Messaging/                Contratos de mensagem para Service Bus.
│   ├── Entities/                 Interfaces de entidade específicas (ex.: Imbarq).
│   ├── Request/                  IPaginatedRequest e afins — contratos de entrada.
│   ├── DTOs/                     Contratos de DTO.
│   └── Common/                   Contratos genéricos.
│
├── Enums/                        🔢 Enums por subdomínio (Boleta, CRM, Cadastro, Posicao,
│                                    Opcao, Xml, Protheus...). Inclui os "type-safe enums"
│                                    que traduzem código de 1 letra do banco em nome legível.
│
├── Validators/                   ✅ BaseValidator (FluentValidation) com acesso ao
│                                    IServiceProvider para regras que consultam o banco.
│
├── VOs/                          💎 Value Objects. Hoje só PasswordVO — encapsula senha
│                                    criptografada, expõe GetPassword().
│
├── Options/                      ⚙️ Classes POCO de configuração tipada (as "options"
│                                    carregadas de appsettings + banco).
│
├── Messaging/                    📨 Contratos concretos de mensagem (IMessagingContract).
│
├── Services/                     🧩 Serviços de domínio puros (ex.: modelo de usuário).
│
├── DTOs/                         📤 DTOs de domínio — transporte entre camadas internas.
│
├── Mapper/                       🔀 Profiles do AutoMapper para tipos de domínio.
│
├── Converters/                   🔄 Conversores JSON de domínio (ex.: PasswordVOConverter).
│
├── Extensions/                   ➕ Extensions sobre entidades (TbAtivoExtension) e o
│                                    ValidatorExtension que cria as regras em português.
│
└── Insight/                      📈 Modelos de resposta de query KQL do Application Insights
                                     (usados pelos health checks de taxa de erro).
```

---

## `Core/Application/` — a regra de negócio

```
Core/Application/
│
├── BSN/                          💼 "Business Service Network" — o nome próprio deste projeto
│   │                                para service de negócio. 177 classes, 32 subpastas.
│   │
│   ├── Base/                     BaseBsn<T>: service locator preguiçoso + toolkit de
│   │                             concorrência (lock, retry, batch, paralelismo). TODO BSN
│   │                             herda daqui. É a peça central da camada.
│   │
│   ├── Consolidacao/             ⭐ Núcleo do produto: PortfolioBsn, ConsolidacaoBsn,
│   │                             ReportConsolidacaoBsn (11.363 linhas).
│   ├── Trade/                    ⭐ TradeBsn (12.604 linhas) — a maior classe da solução.
│   │                             Boletas, aluguel, câmbio, opções, capital comprometido.
│   ├── Posicoes/                 ⭐ PosicaoBSN (10.802 linhas) — cálculo de posição.
│   ├── Ativos/                   ⭐ InstrumentBsn (9.741 linhas) — cadastro e precificação.
│   ├── BatimentoTxAdm/           ⭐ Conciliação de taxa de administração (7.098 linhas).
│   │
│   ├── Clientes/                 Cliente, conta, grupo de conta, master.
│   ├── Autorizacao/              AutorizacaoBsn — resolve permissões funcionais e de dados.
│   ├── Performance/              Rentabilidade, atribuição, séries.
│   ├── Prices/                   Carga e consolidação de preços (PriceLoaderBsn).
│   ├── Compliance/               Enquadramento e regras de restrição.
│   ├── Ips/                      Política de investimento, calls táticos, dashboard.
│   ├── Movimentacoes/            Movimentação de conta e cashflow.
│   ├── Dados/                    Pipeline, serviços de dados, status de carteira.
│   ├── Fila/                     FilaProcessamentoBsn — orquestra a fila em tabela.
│   ├── CRM/                      Atividades, campanhas, dashboards comerciais.
│   ├── Receitas/                 Gestão de receita, centro de custo.
│   ├── Societarios/              Estrutura societária.
│   ├── Credito/                  Operações de crédito.
│   ├── Pessoa/                   Cadastro e KYC.
│   ├── PortfolioTaxas/           Taxas e faixas por portfólio.
│   ├── SaldosLiquidos/           Saldo líquido XP.
│   ├── ClassesSubClassesAtivos/  Classificação de ativos.
│   ├── XmlAnbima/ · Xml5Anbima/  Download, carga e match de XML ANBIMA (duas versões).
│   ├── Signature/                Assinatura eletrônica (Docusign).
│   ├── Auditoria/                Relatórios de auditoria.
│   ├── NavControl/               Controle de NAV (valor da cota).
│   ├── LinkConsolidacao/         Vínculo entre carteira e portfólio.
│   ├── EG/                       Extranet Gateway (integração de caixa).
│   ├── OutSystems/               Workflows externos.
│   └── DTO/                      DTOs internos da camada BSN.
│
├── Models/                       📥📤 CONTRATOS DA API. 42 subpastas por assunto
│                                    (Portfolio, Client, Boleta, Trades, Position, Ips...).
│                                    Padrão rígido: *Request entra, *Response sai.
│                                    Um arquivo por classe.
│
├── DTOs/                         📦 Transporte interno — NÃO sai na API. Distinção
│                                    importante: Models é contrato público, DTOs é privado.
│
├── Interfaces/                   📜 I*Bsn — contratos dos serviços de negócio.
│                                    Subpasta BSN/ com Base/ dentro.
│
├── Reports/                      📄 GERAÇÃO DE DOCUMENTO. 88 relatórios DevExpress (.vsrepx)
│   │                                embutidos como recurso + templates de e-mail.
│   ├── Consolidacao/             Relatório consolidado ao cliente (o principal entregável).
│   ├── Performance/              Rentabilidade, drawdown, volatilidade.
│   ├── Proposta/                 Proposta de alocação.
│   ├── Posicao/ · Extrato/ · Opcoes/   Demais relatórios.
│   ├── Capa/                     Capas e disclaimers reutilizáveis.
│   └── Html/                     Templates de e-mail: Base/ (moldura) + Rows/ (linha de
│                                 tabela). Placeholders no formato [#Campo].
│
├── Filters/                      🛡️ ApplicationApiHandler — o IActionFilter global que faz
│                                    autorização por path E traduz exceção em HTTP status.
│                                    Uma das peças mais importantes do sistema.
│
├── Enums/                        🔢 Enums de aplicação (status, filtros de tela).
├── Mapper/                       🔀 Profiles do AutoMapper da camada.
├── Extensions/                   ➕ Extensions específicas de aplicação.
└── Utilitarios/                  🧰 Helpers da camada.
```

---

## `Core/Common/` — a biblioteca de apoio

```
Core/Common/
│
├── Extensions/                   ⭐ A pasta mais usada do projeto. 24 arquivos.
│                                    StringExtension (627 linhas) é vocabulário do domínio
│                                    financeiro BR: ToMaskCPFCNPJ, ValidarCNPJ, ReadAsDecimal,
│                                    RemoverAcentos. Também ILoggerExtension (executa+loga+
│                                    cronometra), TaskExtension (HandleException fluente),
│                                    LinqExtension, QueryExtension, EncryptExtension.
│
├── Auxiliar/                     🧰 17 utilitários: ExcelUtil, PdfUtil, DateTimeUtil
│                                    (com GetDateNowTimeBrasilia), CertificateLoaderUtil,
│                                    PositionalDataUtil (parser de arquivo posicional),
│                                    KMBUtil (1.500.000 → "1,5M"), NomeSiglaUtil.
│
├── Exceptions/                   ⚠️ Hierarquia de exceções de domínio, todas herdando de
│                                    CustomException. É o que permite o filtro global mapear
│                                    exceção → status HTTP, e o monitoramento separar erro
│                                    de negócio de erro de sistema.
│
├── Attributes/                   🏷️ Atributos customizados.
│   └── PositionalData/           ⭐ [PositionData(1,2)], [DecimalPositionData],
│                                    [DateOnlyPositionData], [FilterPositionalData].
│                                    Transformam layout de arquivo de largura fixa (B3/CETIP)
│                                    em declaração C#.
│
├── Converters/                   🔄 10 conversores JSON para lidar com API de parceiro:
│                                    SingleOrArrayConverter (às vezes objeto, às vezes array),
│                                    DateTimeWithoutKindConverter, DecimalConverter.
│
├── Interfaces/                   📜 ISingletonInstance / ITransientInstance (marcadores de
│                                    ciclo de vida para o DI por convenção), ICustomOptions,
│                                    IStartupTask, IDistributedLock.
│
├── Responses/                    📤 LoadOptionsResponse<T> (lista + total, formato DevExtreme)
│                                    e EnumResponse (id + descrição para dropdown).
│
├── Http/                         🌐 CustomHttpResponse — wrapper de sucesso/erro/arquivo.
├── Comparers/                    🔍 ReflectionEqualityComparer — compara objetos campo a campo.
│                                    Infraestrutura de reconciliação, não utilitário genérico.
├── AutoMapper/                   🔀 Resolvers customizados (ignorar nulo no mapeamento).
└── DTOs/                         📦 DTOs genéricos.
```

---

## `Core/IoC/` — o composition root

```
Core/IoC/
│
│  (na raiz: DependencyInjectionExtencion.cs, 655 linhas — o ConfigureIoC() que
│   TODOS os processos chamam. Registro por convenção + reflexão.)
│
├── CustomOptions/                ⚙️ ~35 classes de configuração DINÂMICA. Cada feature
│   │                                grande tem a sua. Carregam de appsettings + tabela
│   │                                Tb_Configuracao, permitindo mudar comportamento em
│   │                                produção sem deploy.
│   └── Base/                     BaseCustomOptionsConfig<T> — cascata de configuração,
│                                 descriptografia de senha, Clone() no Current.
│
├── Configures/                   🔧 Configuração de options por área.
│   ├── Services/                 Options de cada integração (Azure, B3, Itaú, Docusign...).
│   ├── Repositories/             Options de contexto (Datalake).
│   └── Base/                     Base compartilhada.
│
├── StartupTasks/                 🚦 Executam ANTES de servir tráfego:
│                                    carregar certificados mTLS do Blob, carregar mensagens
│                                    de domínio, carregar options (com fail fast).
│
├── Middlewares/                  🔗 DomainConfigMiddleware — extrai o e-mail do claim e
│                                    popula IDomainConfig. É o que alimenta a auditoria
│                                    automática do SaveChanges.
│
├── Configs/                      ⚙️ DomainConfig — implementação do "usuário atual",
│                                    com fallback para 'prisma.whg' nos jobs.
│
├── DomainServices/               🧩 MessageDomainService (mensagens de validação) e
│                                    UserDomainService.
│
└── CustomLogger/                 📊 CustomTelemetryInitializer — enriquece a telemetria
                                     do Application Insights.
```

---

## `Core/Repository.*` — persistência

```
Core/Repository.Common/           📦 Bases INDEPENDENTES de provedor.
├── Repositories/                 BaseRepository / BaseReadRepository / BaseWriteRepository —
│                                 CRUD genérico + Bulk* (EFCore.BulkExtensions) + Batch*
│                                 (UPDATE/DELETE direto no banco, sem materializar entidade).
├── Extensions/                   ⭐ EfCoreExtension: HasConversionJsonString,
│                                 HasConversionEnumString, HasConversionEncryptString e o
│                                 AutomaticApplyModelCreating (aplica mappings por reflexão).
│                                 BasesEntityExtension: ConfiguraBaseEntity() — configura
│                                 colunas transversais deduzindo das interfaces marcadoras.
└── Attributes/                   CustomMigrationAttribute — marca o que entra na migration.

Core/Repository.SqlServer/        🗃️ PERSISTÊNCIA PRINCIPAL.
│  (na raiz: 12 DbContexts — WhgContext, ArquivoDePosicaoContext, XpPosiContext,
│   CreditoContext, SocietarioContext, ReceitaContext... todos apontando para o MESMO
│   banco, cada um com seu schema default. Bounded contexts sem microserviço.)
│
├── Mappings/                     🗺️ 480 arquivos de IEntityTypeConfiguration, uma pasta por
│   │                                schema. É aqui que nome de tabela, coluna, índice,
│   │                                FK e temporal table são definidos.
│   ├── Base/                     BaseWhgMap<T>, BaseXpPosiMap<T>... uma base por schema.
│   ├── Whg/                      Schema dbo — o maior. Tem subpastas por subdomínio.
│   ├── ArquivoDePosicao/         Schema xml (XML ANBIMA).
│   ├── XpPosi/ · Credito/ · Societario/ · Receita/ · Financeiro/ · Live/
│   ├── OutSystems/ · Compliance/ · Docusign/ · Imbarq/
│
├── Repositories/                 Implementações concretas por agregado.
├── Extensions/                   DbContextExtension (transação, bulk com transação),
│                                 PaginatedRequestExtension (paginação + ordenação dinâmica).
├── DistributedTaskLock/          🔒 SqlServerDistributedLock — exclusão mútua ENTRE
│                                 instâncias (o semáforo do BaseBsn só protege in-process).
└── Enums/                        ESchemas — a lista de schemas do banco.

Core/Repository.SqlServer.Migrations/   🔄 Projeto SEPARADO. Existe só para gerar DDL.
├── Migrations/                   Uma única migration (baseline de out/2025). Antes disso,
│                                 o histórico está em Database/ como script manual.
└── MigrationOverrides/           Customizações do EF: gerador de SQL que corrige o DDL de
                                  temporal table e um ModelDiffer próprio.

Core/Repository.Redis/            ⚡ CACHE DISTRIBUÍDO.
└── Repositories/                 BaseRepositoryCache (L1 em memória por escopo + L2 Redis,
                                  GZip para objeto grande, kill-switch por config) e
                                  repositórios por domínio: Posicao, Consolidacao,
                                  AtivoCotacao, Days, CapitalComprometido, System.

Core/Repository.Datalake/         📊 BANCO ANALÍTICO (segundo banco).
├── Mappings/                     Entidades Tbe* (tratadas) e Raw* (cru: B3, IBGE).
├── Repositories/                 Leitura pesada e escrita em massa.
├── DTOs/ · Utils/ · Extensions/
```

---

## `Core/Services/` — integrações externas

```
Core/Services/                    🌍 46 pastas. Regra: uma pasta por parceiro/API.
│                                    Serviços de autenticação ficam SEPARADOS do serviço de
│                                    negócio (par *Auth + *): XpAuth/XpWealth,
│                                    ItauAuth/ItauIntrag, B3Auth/B3Imbarq, AnbimaAuth/Anbima.
│
├── Base/                         Fundação comum.
│   ├── HttpClientService/        BaseHttpClientService<TService, TOptions> — monta URI,
│   │                             expõe HttpClient e Options tipadas.
│   └── Options/                  Options compartilhadas (B3, Itaú).
│
├── Messaging/                    📨 AZURE SERVICE BUS.
│   ├── Base/                     BaseMessagingService — envia com metadados padronizados
│   │                             (CorrelationId, MessageType, RequestUser, NmAplicacao).
│   └── Contexts/                 Um serviço por contexto de negócio: Compliance, Finance.
│
├── Blob/                         💾 AZURE BLOB STORAGE, separado por finalidade.
│   ├── Whg/                      Arquivos gerais + certificados.
│   ├── Datalake/                 Arquivos do analítico.
│   ├── Compliance/               Documentos de compliance (bureau).
│   ├── Instrumentalizacao/       ⭐ Payload de request/response com falha de parceiro —
│   │                             o log grande vai pro Blob, a mensagem curta vai pro log.
│   └── Base/
│
├── XpAuth/ XpWealth/ XpWealthV2/ XpWealthAnbima/ XpCustomers/ XpDataAccess/
│   XpSecurities/ XpFundsAdministration/ XpPomacWhgParceiros/ XpMock/
│                                 🏦 XP — o maior parceiro. 10 pastas: autenticação (mTLS),
│                                    custódia, cadastro, títulos, fundos, e um mock.
│
├── ItauAuth/ ItauIntrag/         🏦 Itaú — carteira diária, passivo de fundos, gestão de caixa.
├── B3Auth/ B3Imbarq/             🏦 B3 — arquivos IMBARQ em layout posicional (11 layouts).
├── AnbimaAuth/ Anbima/           📊 ANBIMA — índices e XML de fundos.
├── CmdAuth/ CmdInstruments/ CmdPortfolios/ CmdPrices/ CmdReports/ CmdTrades/ CmdWallets/
│                                 📊 CMD — sistema de mercado. 7 pastas por área funcional.
├── Addepar/                      📊 Addepar — consolidação internacional.
├── AlphaTools/                   📊 AlphaTools — estratégias e classificação.
├── AdnNetAuth/ AdnNet/           📊 AdnNet — razão contábil.
├── BigCorpDataAuth/ BigDataCorp/ 🔍 Enriquecimento cadastral (KYC).
├── ExtranetGatewayAuth/ ExtranetGatewayCashier/   💰 Gateway de caixa.
├── ProtheusAuth/ Protheus/       💼 ERP Protheus (financeiro).
├── ExtratoHub/                   📄 Hub de extratos.
├── OutSystems/                   🔄 Workflows low-code corporativos.
├── Docusign/                     ✍️ Assinatura eletrônica.
├── MsGraph/                      👥 Microsoft Graph — usuários e grupos do AD.
├── AzureAuth/ AzureSynapse/      ☁️ Autenticação Azure e consulta ao Synapse.
├── PublisherSubscriber/          📡 Azure Web PubSub — dispara a fila via WebSocket.
├── AIModels/ ModelsAI/           🤖 Integração com modelos de IA.
└── Extensions/                   ➕ Extensions da camada de serviço.
```

---

## `PrismaService/` — API interna

```
PrismaService/
│
├── Controllers/                  🌐 181 controllers.
│   └── DevEx/                    Prefixo herdado do front DevExpress/DevExtreme.
│       │                         Quase tudo vive aqui.
│       │
│       ├── Cadastro/             🔝 50+ controllers, 1,1 MB. O maior grupo.
│       │                         Subpastas: Ativos, Clientes, Classificacoes, Fundos,
│       │                         Dominios, LiberacaoPortfolio.
│       ├── Movimentacao/         20+ controllers. Subpastas: Boletas (10 tipos),
│       │                         CarryingBBI, Cashflow.
│       ├── Dados/                Arquivos, pipeline, reprocessamento, reconciliação.
│       │                         Subpasta Receita/ com 7 controllers.
│       ├── Autorizacao/          8 controllers — administração de permissões.
│       ├── Utils/                Extração dinâmica, disparo de e-mail, tutorial.
│       ├── Proposta/             Carteira teórica e simulações.
│       ├── Consolidacao/         ⭐ 1 controller de 1.320 linhas — o núcleo.
│       ├── Posicao/              Posição, extrato, performance, movimentação de conta.
│       ├── CRM/ · Ips/ · Compliance/ · Arquivo/ · Auditoria/ · ParamConsulta/
│       ├── Passivo/ · Societario/
│
├── HealthCheck/                  ⭐ 15 verificações ATIVAS — várias chamam o parceiro de
│   │                                verdade. Três consultam o próprio Application Insights
│   │                                via KQL para medir taxa de erro, excluindo erro de
│   │                                negócio da conta.
│   ├── Base/                     HealthCheckBase<T> — escopo de log + try/catch padronizado.
│   └── Configure/                Registro dos checks e do dashboard (/healthdashboard).
│
├── Auxiliar/                     🧰 Helpers específicos da API.
├── Models/                       📤 Modelos exclusivos desta API (poucos — o grosso está
│                                    em Application/Models).
├── Images/                       🖼️ Assets usados em relatório e e-mail.
├── Properties/                   ⚙️ launchSettings.json.
└── wwwroot/                      📁 173 MB de front estático (bundle do DevExtreme).
                                     Não é código de backend.
```

---

## `PrismaServiceExternal/` — API de parceiros

```
PrismaServiceExternal/
│
├── Controllers/                  🔌 23 controllers, SEM subpastas — a superfície é pequena
│                                    o bastante para ser plana. Nomes em inglês
│                                    (Portfolios, Trades, Position, Reports, Users).
│
└── Helpers/                      🛡️ O que diferencia esta API da interna:
                                     JwtMiddleware (valida JWT próprio e TRADUZ grupo do
                                     Azure em grupo do Prisma), AuthorizeAttribute próprio,
                                     CustomSwaggerFilter (só endpoints com
                                     [ShowExternalSwagger] aparecem na doc pública).
```

---

## `Jobs/` — processos background

```
Jobs/
│
├── CommonWebJob/                 ⭐ A FÁBRICA. ProgramFactory (host, logging, telemetria,
│                                    shutdown gracioso, heartbeat), BaseWebJobWorker (cron
│                                    via NCrontab vindo do banco) e BaseWebJobBusConsumer
│                                    (consumer de Service Bus). Todo job abaixo herda daqui
│                                    e tem Program.cs de 6 linhas.
│
├── WebJobFilaProcessameto/       🔁 Consome a fila em tabela. Modo polling ou WebSocket.
├── WebJobPriceLoader/            💲 Carga de preços e cotações.
├── WebJobPosicaoConsolidada/     📊 Cálculo da posição consolidada.
├── WebJobXmlAnbima/              📄 Download e carga do XML ANBIMA.
├── WebJobCarteiraXP/             🏦 Carteira da XP.
├── WebJobSaldoLiquidoXpConsumirApi/  🏦 Saldo líquido XP.
├── WebJobMatchMativo/            🔗 Match de ativos entre fontes.
├── WebJobAberturaBoletador/      📈 Abertura do dia no boletador.
├── WebJobFechamentoBoletador/    📉 Fechamento do dia.
├── WebJobBoletadorPnt/           📈 Boletador — pendências.
├── WebJobBoletadorPntExecutor/   📈 Boletador — execução.
├── WebJobDisparadorEmail/        📧 Envio de e-mail em lote.
├── WebJobRelatorioNav/           📄 Relatório de NAV.
├── WebJobTablesToDatalake/       📊 Replicação operacional → analítico.
├── WebJobOutsystemsLoader/       🔄 Carga vinda do OutSystems.
├── WebJobPrisma/                 🧹 Rotinas gerais (expurgo, rebuild de índice).
├── WebJobPrismaBusiness/         💼 Rotinas de negócio agendadas.
└── WebJobBusPrismaBusiness/      📨 Consumer de Service Bus de negócio.
```

---

## `Database/` — o banco versionado

```
Database/                         🗄️ 1.287 arquivos. O histórico REAL do banco.
│
├── Creates and Drops/            1.015 arquivos em 165 pastas de release (v01 → v77).
│                                 Nome da pasta = feature (v70_MelhoriasConsolidacaoContaRelGlobal).
│                                 Nome do arquivo = changelog:
│                                 "01 - ALTER TABLE - Tb_Conta - ADD COLUMN Fl_Relatorio_Global.sql"
│                                 Formato: NN - AÇÃO - Objeto - Detalhe.sql
│
├── Load/                         181 arquivos — cargas de dados (parâmetros, domínios,
│                                 configuração) organizadas pelas mesmas versões.
│
└── Grants/                       91 arquivos — permissões por schema e por grupo do AD.
                                  Coerente com o modelo de autorização data-driven.
```

---

## Três leituras da árvore

**1. Espelhamento.** Uma feature ocupa o mesmo caminho relativo em toda camada. "Consolidacao" aparece
em `Domain/Entities/`, `Application/BSN/`, `Application/Models/`, `Repository.SqlServer/Mappings/Whg/`
e `Controllers/DevEx/`. Você aprende um caminho e deduz os outros quatro.

**2. Base/ é sempre o ponto de entrada.** `BSN/Base/`, `Mappings/Base/`, `Services/Base/`,
`Repositories/Base/`, `HealthCheck/Base/`, `Messaging/Base/`. Quando quiser entender uma camada nova,
abra a pasta `Base/` primeiro — é onde está o contrato que todo o resto segue.

**3. Autenticação separada do negócio.** Em `Services/`, os pares `XpAuth`/`XpWealth`,
`ItauAuth`/`ItauIntrag`, `B3Auth`/`B3Imbarq`, `AnbimaAuth`/`Anbima` não são redundância — token
tem ciclo de vida, cache e falha próprios, e isolar isso evita que a lógica de renovação vaze para
o serviço de negócio.
