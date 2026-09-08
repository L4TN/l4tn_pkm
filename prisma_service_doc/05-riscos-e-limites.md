# PARTE V — RISCOS

## 8. O que NÃO copiar

### 8.1 God classes

| Arquivo | Linhas |
|---|---:|
| `Core/Application/BSN/Trade/TradeBsn.cs` | 12.604 |
| `Core/Application/BSN/Consolidacao/ReportConsolidacaoBsn.cs` | 11.363 |
| `Core/Application/BSN/Posicoes/PosicaoBSN.cs` | 10.802 |
| `Core/Application/BSN/Ativos/InstrumentBsn.cs` | 9.741 |
| `Core/Application/BSN/BatimentoTxAdm/BatimentoTxAdmRelatorioBsn.cs` | 7.098 |
| `Core/Application/BSN/ReconciliacaoPortfolioBsn.cs` | 6.855 |
| `PrismaService/.../BoletasController.cs` | 1.512 |
| `PrismaService/.../ConsolidacaoController.cs` | 1.320 |

O `BaseBsn` com service locator é justamente o que viabiliza esse crescimento sem dor imediata —
adicionar a 26ª dependência não custa nada. A conta chega no code review, no onboarding e no merge conflict.

**Mitigação:** limite de linhas por classe no lint/review e composição por sub-serviços
(`TradeBsn` → `TradeValidacaoBsn`, `TradeCalculoBsn`, `TradeExportBsn`).

### 8.2 Zero testes automatizados

Não há nenhum projeto de teste na solution. Com ~380 mil linhas de lógica financeira (cálculo de
rentabilidade, consolidação de posições, taxas), esse é o maior risco estrutural do projeto — e a razão
mais forte para não copiar o service locator sem pensar.

### 8.3 Segredos versionados

`Core/Repository.SqlServer/WhgContext.cs` tem, comentadas no topo, connection strings de produção com
senha em texto puro (resquício de comandos `Scaffold-DbContext`). Se alguma credencial ainda estiver
válida, é **rotação urgente** — e o histórico do Git guarda tudo mesmo após remoção.

**Mitigação:** Azure Key Vault + Managed Identity, e scanner de segredo no pipeline
(`gitleaks`, `trufflehog`).

### 8.4 Acoplamento ao DevExtreme e vazamento de `DbContext`

Retomando os números da seção 3: **59% das controllers injetam `WhgContext` direto** e **61% usam
`DataSourceLoadOptions`**. A camada BSN é aspiracional, não arquitetural. Trocar o front exige reescrever
a superfície da API.

### 8.5 Inconsistências de convenção

- Sufixo: `PosicaoBSN` / `ComplianceBSN` vs `TradeBsn` / `ClienteBsn`
- Pastas duplicadas: `Domain/Entities/CRM` **e** `Domain/Entities/Crm`
- Rotas: três padrões coexistindo (seção 3)
- Construtores com parâmetros opcionais `= null` para dependências obrigatórias (`PosicaoController`),
  trocando erro de startup por `NullReferenceException` em runtime
- Dependência ora pela interface, ora pela classe concreta (`PortfolioBsn portfolioBsn` no construtor,
  campo `IPortfolioBsn`)
- 125 BSNs concretos para 90 interfaces — nem tudo tem contrato

### 8.6 Cache de autorização em memória de instância

`IMemoryCache` é por processo, com TTL de 24h na API interna. Em escala horizontal, **revogar acesso pode
levar até um dia para valer em todas as instâncias**. O Redis já está no projeto e resolveria com
invalidação centralizada.

### 8.7 Estado mutável em serviço scoped

```csharp
_autorizacaoBsn.Funcionalidades           = listAutorizacaoFuncionalidade;
_autorizacaoBsn.GrupoAcessoCliente        = listGrupoAcessoCliente;
_autorizacaoBsn.GrupoAcessoClienteExcecao = listGrupoAcessoClienteExcecao;
```

Funciona porque o BSN é scoped por request. Se alguém promover essa classe a singleton um dia, vira
vazamento de permissão entre usuários — falha silenciosa e grave. Preferível passar o contexto de
autorização explicitamente.

### 8.8 `ConcurrentDictionary` estático em filtro

```csharp
public static readonly ConcurrentDictionary<string, Stopwatch> _timers = new();
```

Só é limpo no `OnActionExecuted`. Requisição abortada antes disso deixa entrada órfã — vazamento lento
de memória.

### 8.9 CORS aberto

```csharp
app.UseCors(s => s.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
// TODO: alterar authentication CORS para nível da Azure
```

O `TODO` está lá desde sempre.

### 8.10 Outros pontos de atenção

- `catch` silencioso nos handlers de certificado Itaú/B3 (só loga e devolve handler sem cert — o oposto
  do que a XP faz)
- `handler.ServerCertificateCustomValidationCallback = (...) => true;` no cliente B3 desliga validação
  do certificado do servidor
- `CheckCanExecute()` chama `.Wait()` sobre método async (risco de deadlock fora de ASP.NET Core)
- `ExecuteWithTryCacheAsync` engole exceção do worker (loga e segue) — um job pode "passar" tendo falhado
- `Linq.Dynamic.Core` com entrada de usuário na Extração Dinâmica: superfície de injeção a auditar
- README ainda é o template padrão do Azure DevOps, com todos os `TODO:` intactos

---

## 9. O que não foi lido

Sendo honesto sobre o alcance: mesmo com duas passagens, foram lidos ~**80 de ~3.500 arquivos**.
O que permanece inexplorado, em ordem de relevância:

| Área | Volume | Por que importa |
|---|---:|---|
| `TradeBsn.cs` | 12.604 linhas | Núcleo do negócio; nenhuma linha lida |
| `ReportConsolidacaoBsn.cs` | 11.363 linhas | Motor dos relatórios ao cliente |
| `PosicaoBSN.cs` | 10.802 linhas | Cálculo de posição consolidada |
| `InstrumentBsn.cs` | 9.741 linhas | Cadastro/precificação de ativos |
| `BatimentoTxAdmRelatorioBsn.cs` | 7.098 linhas | Conciliação de taxa de administração |
| `ReconciliacaoPortfolioBsn.cs` | 6.855 linhas | Reconciliação Prisma × custodiante |
| `ArquivoDePosicao401.cs` | 7.763 linhas | Schema XML ANBIMA 4.01 |
| 46 serviços de integração | 43.074 linhas | Só 3 abertos (Addepar, XP auth, B3 Imbarq) |
| 480 mappings EF | 32.702 linhas | 4 lidos |
| 88 relatórios DevExpress `.vsrepx` | binário | Layout dos PDFs entregues ao cliente |
| 165 pastas de script SQL | 1.287 arquivos | Só nomes lidos, nenhum conteúdo |
| 1.353 entidades de domínio | 46.335 linhas | ~10 abertas |

**O que uma terceira passagem provavelmente revelaria:** as regras de negócio de verdade — cálculo de
rentabilidade, marcação a mercado, tratamento de eventos corporativos, regras de enquadramento
(existe uma `CustomEnquadramentoException` dedicada, o que sugere um motor de compliance relevante) e a
lógica de reconciliação.

---
