# Plano de Execução: WHG como Submodule + Clone Independente

**Data:** 2026-03-01
**Status:** Pendente
**Objetivo:** Extrair `11_Trabalho` do PKM para um repo Git próprio (WHG), manter como submodule no PKM, e clonar separadamente em `~/source/` ao lado do Prisma para uso com GitHub Spec Kit (SDD).

---

## Contexto

**Estrutura Atual:**

```
~/source/l4tn_pkm/              (repo git: github.com/L4TN/l4tn_pkm)
└── pages/10_Projetos/11_Trabalho/
    ├── 11.1_WHG/          (32 arquivos - notas gerais)
    ├── 11.2_Impulso/      (8 arquivos - notas Impulso)
    ├── 11.3_Sprints_WHG/  (7 arquivos - specs/sprints)
    └── 11.4_Sprints_Prisma/ (17 arquivos - specs migração)

~/source/Prisma/                (sem git na raiz)
├── Prisma_FrontEnd/            (.git próprio)
└── Prisma_Backend/             (.git próprio)
```

**Estrutura Desejada:**

```
~/source/l4tn_pkm/              (repo git pessoal)
└── pages/10_Projetos/11_Trabalho/  → submodule → github.com/L4TN/whg

~/source/WHG/                   (clone independente do mesmo repo)
├── 11.1_WHG/
├── 11.2_Impulso/
├── 11.3_Sprints_WHG/
└── 11.4_Sprints_Prisma/

~/source/Prisma/
├── Prisma_FrontEnd/ (.git)
└── Prisma_Backend/  (.git)
```

---

## Passo a Passo

### Fase 1: Criar o Repo WHG no GitHub

**1.1 - Criar o repositório remoto**

Vá no GitHub e crie um novo repo:
- Nome: `whg` (ou o nome que preferir)
- Visibilidade: **Privado**
- NÃO inicialize com README, .gitignore ou license

Ou via CLI:

```bash
gh repo create L4TN/whg --private --description "WHG - Specs e Tasks para SDD com Spec Kit"
```

### Fase 2: Inicializar o Repo WHG com o conteúdo atual

**2.1 - Copiar o conteúdo para uma pasta temporária**

```bash
# Cria pasta temporária
mkdir ~/source/WHG_temp
cp -r ~/source/l4tn_pkm/pages/10_Projetos/11_Trabalho/* ~/source/WHG_temp/
```

**2.2 - Inicializar o git e fazer o primeiro commit**

```bash
cd ~/source/WHG_temp
git init
git add .
git commit -m "feat: importa conteúdo de trabalho do PKM (WHG, Impulso, Sprints)"
```

**2.3 - Conectar ao remote e fazer push**

```bash
git remote add origin https://github.com/L4TN/whg.git
git branch -M main
git push -u origin main
```

**2.4 - Verificar**

```bash
# Deve mostrar todos os arquivos no GitHub
gh repo view L4TN/whg --web
```

### Fase 3: Converter a pasta no PKM em Submodule

**3.1 - Remover a pasta original do PKM (do git, não do disco ainda)**

```bash
cd ~/source/l4tn_pkm

# Remove a pasta do rastreamento do git (mas mantém no disco por segurança)
git rm -r --cached pages/10_Projetos/11_Trabalho

# Agora remove a pasta do disco (já temos cópia em WHG_temp e no GitHub)
rm -rf pages/10_Projetos/11_Trabalho

# Commit da remoção
git commit -m "refactor: remove 11_Trabalho para migração para submodule WHG"
```

**3.2 - Adicionar como submodule**

```bash
cd ~/source/l4tn_pkm

# Adiciona o submodule apontando pro repo WHG
git submodule add https://github.com/L4TN/whg.git pages/10_Projetos/11_Trabalho

# Isso cria/atualiza dois arquivos:
# - .gitmodules (config do submodule)
# - pages/10_Projetos/11_Trabalho (referência ao commit do WHG)
```

**3.3 - Commit e push do PKM**

```bash
cd ~/source/l4tn_pkm
git add .gitmodules pages/10_Projetos/11_Trabalho
git commit -m "feat: adiciona WHG como submodule em 11_Trabalho"
git push
```

### Fase 4: Clonar WHG separado em ~/source/

**4.1 - Clone independente**

```bash
# Remove a pasta temporária
rm -rf ~/source/WHG_temp

# Clona o repo WHG direto
cd ~/source
git clone https://github.com/L4TN/whg.git WHG
```

**4.2 - Verificar estrutura final**

```bash
ls ~/source/WHG/
# Deve mostrar: 11.1_WHG/  11.2_Impulso/  11.3_Sprints_WHG/  11.4_Sprints_Prisma/

ls ~/source/Prisma/
# Deve mostrar: Prisma_FrontEnd/  Prisma_Backend/
```

---

## Fluxo de Trabalho no Dia a Dia

### Trabalhando no WHG (specs/tasks)

```bash
cd ~/source/WHG
# Edita arquivos de spec...
git add .
git commit -m "spec: adiciona task X para migração Y"
git push
```

### Atualizando o submodule no PKM (quando quiser)

Não precisa fazer toda vez. Só quando quiser que o PKM reflita a versão mais recente:

```bash
cd ~/source/l4tn_pkm
git submodule update --remote pages/10_Projetos/11_Trabalho
git add pages/10_Projetos/11_Trabalho
git commit -m "chore: atualiza submodule WHG"
git push
```

### Clonando o PKM em outra máquina (com WHG)

```bash
git clone --recurse-submodules https://github.com/L4TN/l4tn_pkm.git
```

### Clonando só o WHG em outra máquina

```bash
git clone https://github.com/L4TN/whg.git
```

---

## Comandos de Referência para Submodules

| Ação | Comando |
|------|---------|
| Ver status do submodule | `git submodule status` |
| Atualizar submodule pra último commit | `git submodule update --remote` |
| Inicializar submodule após clone | `git submodule init && git submodule update` |
| Entrar no submodule e trabalhar | `cd pages/10_Projetos/11_Trabalho && git pull` |

---

## Checklist de Validação

- [ ] Repo `L4TN/whg` criado no GitHub (privado)
- [ ] Todos os 64 arquivos de 11_Trabalho presentes no repo WHG
- [ ] PKM tem o submodule configurado em `.gitmodules`
- [ ] `git submodule status` no PKM mostra o WHG
- [ ] Clone independente em `~/source/WHG` funcionando
- [ ] Push e pull funcionando tanto no WHG independente quanto via submodule
- [ ] Estrutura `~/source/` tem WHG e Prisma lado a lado

---

## Riscos e Rollback

Se algo der errado, o conteúdo original está seguro em pelo menos dois lugares:
1. No histórico de commits do PKM (antes da remoção)
2. No repo WHG no GitHub

Para reverter completamente:
```bash
# Volta ao commit anterior do PKM
cd ~/source/l4tn_pkm
git log  # encontra o hash do commit antes da remoção
git revert <hash-da-remoção>
git submodule deinit pages/10_Projetos/11_Trabalho
git rm pages/10_Projetos/11_Trabalho
```
