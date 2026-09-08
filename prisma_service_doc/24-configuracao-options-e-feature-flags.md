# Configuração, options e feature flags

## 1. Fontes de configuração

O Prisma combina fontes diferentes conforme o runtime:

```text
appsettings.Common.json (Jobs)
  -> appsettings.json
  -> appsettings.{Environment}.json
  -> environment variables
  -> seção tipada
  -> TbConfiguracao
  -> options customizada
```

A API usa o host ASP.NET; WebJobs usam `Configuration.CreateHostBuilder` e depois substituem as fontes
pelo conjunto comum + específico do Job.

## 2. Dois modelos de options

### `IOptions<T>` padrão

Usado para configurações estruturais e de integração, como `ItauOptions`, `B3Options`,
`EncryptionKeysOptions` e options de contexto.

### `ICustomOptions<T>`

Implementado por `BaseCustomOptionsConfig<T>`, é usado quando a configuração precisa ser carregada do
banco, atualizada, validada no startup ou variar por aplicação/produto.

Cada custom option possui:

- `OptionsName`;
- `Current` clonado;
- `Loaded`;
- `Required`;
- `UpdateOptionsAsync`;
- chave `EConfiguracao`;
- possibilidade de merge entre arquivo e banco.

## 3. Precedência e merge

`LoadOptionsFromAppsettingsAndDatabaseAsync` inicializa um objeto, faz bind de appsettings, aplica o
arquivo específico do ambiente em Development/Staging e, quando necessário, aplica configurações
persistidas em `TbConfiguracao`.

`LoadOptionsFromOnlyDatabaseAsync` busca configurações por chave e produto, ordena configuração geral e
específica e usa `JsonConvert.PopulateObject` para mesclar propriedades.

A ordem precisa permanecer documentada: mudar a precedência pode alterar comportamento financeiro sem
alteração de código.

## 4. Segredos e valores protegidos

A carga de options fornece `PasswordVOConverter` com a chave configurada em `EncryptionKeysOptions`.
Isso permite que o JSON persistido tenha valores protegidos sem forçar todos os consumidores a conhecerem
o formato de criptografia.

O segredo ainda precisa ser protegido no ambiente, no pipeline e nos logs. Converter um valor não elimina
o risco de exposição da chave.

## 5. Startup como fail-fast

`OptionsStartupTask` resolve todos os `ICustomOptions`, atualiza os que ainda não foram carregados e
agrega falhas de options obrigatórias. Uma configuração obrigatória inválida impede o início do
processo.

Esse comportamento é melhor que descobrir uma URL, certificado ou parâmetro faltando somente durante a
primeira execução de um Job.

## 6. Feature flags

A seleção de `IXpAuthService` usa `XpNewAuthCustomOptions.FlNovaAuthXp`. O contrato consumidor permanece
estável enquanto o implementation switch muda por configuração.

O mesmo modelo pode habilitar/desabilitar workers e alterar parâmetros de consolidação, prices,
carteira, Datalake e integrações.

Feature flag deve ter:

- dono;
- propósito;
- valor default seguro;
- plano de remoção;
- comportamento quando a configuração está ausente;
- log da decisão quando necessário.

## 7. Configuração dinâmica como domínio operacional

`TbConfiguracao` não é apenas tabela técnica. Ela funciona como mecanismo de parametrização do produto:
mensagens, jobs, integração, thresholds e regras operacionais podem ser mantidos sem recompilar.

Isso é poderoso, mas exige governança: histórico, permissões de alteração, validação e identificação da
aplicação precisam ser tratados como parte do processo de mudança.
