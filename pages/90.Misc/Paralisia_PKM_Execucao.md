# Paralisia por Análise, PKM e Execução
Autor: Matheus (anotações assistidas)  
Última atualização: 18/12/2025

## 1. Conceitos básicos

### 1.1. Paralisia por análise

Paralisia por análise é o estado em que o excesso de reflexão, análise ou busca de informação impede a tomada de decisão ou a ação, levando à inação ou atrasos.  
Ela costuma aparecer quando existe:

- Sobrecarga de informação ou opções  
- Medo de errar ou perfeccionismo  
- Falta de objetivos claros  
- Ansiedade e insegurança na decisão  

Em ambientes de desenvolvimento de software, isso se manifesta como:

- Ficar desenhando arquitetura, diagramas, documentos e planos sem começar a codar  
- Reescrever o plano, reorganizar tarefas e notas infinitamente  
- Nunca se sentir “pronto o bastante” para iniciar a implementação  

### 1.2. Planejamento vs ação

Planejamento e ação formam um ciclo: planejar → executar → verificar → ajustar → planejar de novo (PDCA).  

Na prática:

- Planejamento precisa ser **suficiente**, não perfeito  
- A ação gera informação real que melhora o planejamento seguinte  
- Ficar muito tempo só no “Plan” sem entrar no “Do” é o núcleo da paralisia por análise  

---

## 2. Limites saudáveis entre planejamento e ação

### 2.1. Quando o planejamento ajuda

Planejamento saudável:

- Dá direção  
- Dá foco  
- Define critérios de pronto  

Em desenvolvimento:

- Escopo claro de feature  
- Lista de tarefas principais  
- Critérios mínimos de aceite  

### 2.2. Quando o planejamento vira procrastinação

Sinais:

- Mais tempo organizando do que executando  
- Plano vira zona de conforto  
- Sistema importa mais que entrega  
- Toda ação parece precisar de mais planejamento  

---

## 3. PKM: ferramenta ou distração?

### 3.1. O que é PKM

PKM é o conjunto de práticas para capturar, organizar e reutilizar conhecimento pessoal.

Benefícios:

- Evita retrabalho  
- Melhora decisões  
- Acelera aprendizado  

### 3.2. Quando PKM vira desculpa

- Otimização do sistema em vez da entrega  
- Muitas notas, pouco uso  
- Organização sem output  

---

## 4. Estrutura de PKM de trabalho

Estrutura apresentada:

```
10_Work
├── 11_Strategy_Index
├── 12_Tech_Index
├── 13_Projects
└── 14_Work_Sprints
    └── 14.01_Prisma_Sprint
        ├── Sprint_Overview
        ├── Specification
        └── Tasks
```

É uma estrutura **sofisticada**, mas com custo cognitivo alto se não for enxuta.

---

## 5. Problema identificado

- Tasks muito grandes  
- Muito contexto, pouca ação  
- Peso mental alto  
- Facilita paralisia  

---

## 6. Como devs produtivos trabalham

- Pragmatismo  
- Tasks pequenas  
- Próxima ação clara  
- Feedback rápido  

Doc pesado ≠ nota pessoal.

---

## 7. Template de sprint mais saudável

- Foco principal claro  
- Backlog enxuto  
- Uma linha de escopo por task  
- Blocos:
  - Hoje  
  - Próximos passos  
  - Notas  

Ajustes:

- Remover duplicações  
- Preferir checkbox simples  
- Máx. 2–3 bullets por bloco  

---

## 8. Recomendações práticas

### 8.1. Critério de saúde

Pergunte:

- Começo em 2 cliques?  
- Sei o que fazer em 25 minutos?  
- Isso gera ação?  

### 8.2. Separar doc e nota

- Doc pesado → repositório oficial  
- PKM → decisão diária  

### 8.3. Voltar para a ação

- Bloco “Hoje / Now”  
- 1–3 tasks  
- Próxima ação executável  
- Planejamento máx. 15 min  
- Sempre gerar output real  

---

## 9. Gerar PDF

Via VS Code, Typora, Obsidian ou:

```
pandoc arquivo.md -o arquivo.pdf
```
