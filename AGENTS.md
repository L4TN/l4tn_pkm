# AGENTS.md — Regras do cofre KØR

Vault pessoal KØR. Estrutura fixa:

- `01_Inbox/` — caixa de entrada (vazio por design; nada vive aqui)
- `.utils/` — utilidades fora das 4 áreas:
  - `Rotinas/` — 5 rotinas fixas por dia da semana: `Segunda.md`…`Sexta.md`
    (dia atípico = nota em DESVIOS abaixo do calendário em `Base-e-Operacao.md`,
    formatada `dia → troca (detalhe)`)
- `02_Cofre/` — as **4 áreas fixas** (pilares):
  - `Base-e-Operacao.md`
  - `Corpo-e-Saude.md`
  - `Mente-e-Equilibrio.md`
  - `Oficio-e-Expansao.md`

## Teto: 10k tokens por nota e por área

- **Cada nota** e **cada área** (`02_Cofre/<Área>.md`) tem teto duro de
  **10.000 tokens**.
- Medida prática (usada no app e no código): **1 token ≈ 4 caracteres**
  (português) → **10k tokens ≈ 40.000 caracteres**.
  - A tokenização real varia por modelo (Qwen / cl100k: ~3,5–4,5 chars/token);
    4 chars/token é a média segura. No código, a métrica é **contagem de
    caracteres** — simples e determinístico.
- **% de uso de uma área** = `caracteres do arquivo ÷ 40.000 × 100`.

## Compressão Diamante

- Quando uma área estoura o teto, a IA **reescreve o arquivo mais denso**:
  elimina redundância, mescla ideias similares, preserva fatos, links e
  checkboxes.
- **Nunca** se cria arquivo novo para "esconder" o estouro — a área é o
  limite, a densidade é o produto.
- Notas individuais (blocos `## [timestamp] Título` anexados pelo KØR)
  também respeitam o teto de 10k tokens.

## Convenções

- Notas do KØR são anexadas no fim da área como:

  ```markdown
  ## [AAAA-MM-DD HH:MM] Título

  - corpo do bloco (markdown limpo)

  > Lote AAAA-MM-DD · folha N
  ```

- 1 lote por dia, máx. 10 folhas por dia.
- Links entre notas: markdown padrão `[texto](caminho.md)` com caminho
  relativo (MarkText). Nunca wikilinks `[[...]]`.
- Não editar à mão as linhas de rastreabilidade (`> Lote …`).
- A IA roteia cada nota para **exatamente uma** das 4 áreas.
