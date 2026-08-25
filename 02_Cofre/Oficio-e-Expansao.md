# Ofício e Expansão

Tags: `#dev` `#trampo` `#estudos`

# Base — Comportamentos de Engenheiro

## 01. Avaliação e gestão de demandas

> Sempre fale apenas daquilo de que tem certeza. Nunca fale do que não tem certeza; argumente com bons argumentos e fatos, não com achismos. Por isso, prefira dizer que vai analisar antes de dizer algo.

- Nunca saia executando uma solicitação sem antes avaliar se ela faz sentido no contexto atual.
- Antes de iniciar, **estime o esforço e o escopo**. Desenhe a arquitetura ou solução e valide com alguém mais sênior se necessário.
- Não faça promessas de features que não estão no pipeline da sprint, salvo quando o *over delivery* não comprometa os compromissos já acordados.
- **Se não tiver certeza ou o usuário te pressionar, sempre diga que vai avaliar e retorne depois** — é preferível a dar uma resposta imprecisa na hora. Nunca se comprometa verbalmente; sempre avalie com seu head antes de qualquer comprometimento externo.
- **Tasks nascem de PETI ou solicitações por email**. O fluxo formal é: formalizar a spec por email → criar task e anexar o email original → criar branch e abrir PR vinculado à task → após aprovação do usuário, vincular o OK à task para rastreamento. Isso garante que PR, pipeline e Release fiquem conectados, com registro completo de quem autorizou cada subida.
- Antes de mostrar seu trabalho ou exportar para o time, **sempre verifique suas prioridades** — certifique-se de que aquilo que você está apresentando é realmente o que deveria estar fazendo naquele momento.

## 02. Antecipação e entrega de valor

- Ao receber um pedido de *feature* ou relato de problema, pense além do que foi pedido: **qual dor isso resolve?** O que o usuário vai precisar e ainda não sabe?
- Se o usuário não souber descrever bem a tela ou funcionalidade com problema, use o contexto das ferramentas que ele usa e o que você conhece do sistema para intuir e investigar.
- Entenda o **plano semestral de entregas** e o PETI. Saiba como o que você faz se encaixa no todo.
- **Forçar o usuário a usar a interface é mais importante que fazer pelo usuário**. Se existe uma tela para ele usar, force-o a usá-la — caso contrário, ele vai ficar te chamando toda hora para fazer manualmente. Empodere o usuário através da ferramenta que você constrói.

## 02.1 Proatividade Radical — Operar Acima do Esperado

- **Não faça só o que te pedem**. Observe o que ninguém quer fazer, o que está quebrado ou travando o time, e resolva.
  - Task entrou, task saiu — isso é manutenção, não é crescimento.
  - Promoção não vem só por "fazer bem feito". Vem quando você **opera em um nível acima do esperado**.

- **Antecipar problema é diferente de reagir**:
  - Não espera virar incidente ou alguém pedir. Se você já vê que algo vai quebrar, escalar ou travar o time, **você se antecipa e resolve**.
  - Isso é ownership verdadeiro — você assume responsabilidade pelo todo, não só pela sua task.

- **Comunicar o que você faz é fundamental**:
  - Não adianta resolver coisa importante se ninguém sabe. **Mostra contexto, explica decisão, deixa claro o impacto**.
  - Mensagem no chat do time: *"Encontrei X que ia causar Y. Resolvi com Z. Afeta [impacto]. Vejam e validem."*
  - Isso constrói reputação de alguém que **vê além da tarefa**.

- **Puxe responsabilidade que ainda não é sua**:
  - Feature travada? Integração mal feita? Processo ruim? Débito técnico acumulando?
  - Se você tem capacidade de destravar, **você entra no problema**.
  - Não é invadir escopo — é ampliar impacto. O time inteiro ganha.

- **Os 3 gatilhos de proatividade radical**:
  1. **Antecipação**: Vi que quebra, não espero quebrar. Aviso e resolvo.
  2. **Comunicação**: Fiz algo importante? Comunico. Contexto + decisão + impacto.
  3. **Ownership**: Puxo responsabilidade além do esperado se tiver capacidade.

## 03. Qualidade técnica e depuração

- **Teste e valide tudo que vai para PRD** — e pessoalmente verifique que está funcionando em produção. Cada linha de alteração deve ser justificada; **prefira ajustes mínimos e cirúrgicos**.
- Antes de rodar e depurar, **leia o código**. Muitas vezes só a leitura já revela o problema — suspeite sempre dos blocos de `if`, onde vivem as regras que mudam o fluxo.
- Fique atento a **possíveis nullables**: trace onde um valor pode ser nulo e quebrar antes mesmo de ir para o ambiente.
- Teste **como dev e como usuário**. O caminho feliz valida o fluxo principal — mas **agrida a tela ao máximo**: inputs fora do padrão, fluxos fora de ordem, campos inesperados. Na UI, nada pode estar torto: campos, botões e elementos devem estar visualmente alinhados na régua, sem desvios.
- Ao testar uma *feature*, documente o teste com **dados reais e o passo a passo**. Assim, se o usuário não souber testar, você tem um exemplo funcional para entregar.
- **Faça funcionar primeiro, refine depois**. Sempre busque o caminho mais simples possível para a solução: entregue algo funcional antes de qualquer otimização. Código que funciona de forma simples tem mais valor do que código elegante que ainda não roda. Pense sempre na forma mais simples possível — complexidade vem depois.
- Domine o perfeccionismo — não o elimine. A tendência ao perfeccionismo é um ativo, mas só quando aplicada no momento certo. O protocolo é: primeiro garanta o básico funcionando; só então use o perfeccionismo para refinar, rebuscar e elevar a qualidade. Perfeccionismo aplicado cedo vira procrastinação.
  - Você tem o defeito de ser muito perfeccionista? Foco em fazer o simples primeiro e funcional. Depois de garantir o básico funcionando, aí sim você pode refinar e rebuscar com o perfeccionismo.
- **Sempre acompanhe a promoção de sua feature para PRD**. Após testes validados, verifique pessoalmente se tudo está funcionando corretamente em produção. Formalize a subida com email, documentando o que foi testado — assim como deve fazer no ambiente de UAT. O dev é dono do resultado, não só do código: se algo falhar em PRD, você assume a solução.

### Debug e Investigação — Ferramentas e Técnicas

- **Use Notepad++ para investigar problemas de encode e caracteres ocultos**:
  - Problemas de encoding (UTF-8, Latin-1, etc) costumam deixar caracteres "invisíveis" no código que quebram tudo.
  - Notepad++ mostra exatamente esses caracteres ocultos — espaços, tabs, BOM, line breaks estranhos.
  - Ative "View → Show Symbol" para revelar o que está realmente lá. Muitas vezes o problema é um espaço invisível ou quebra de linha errada que você não consegue ver em outro editor.

- **Se algo deu problema e já estava lá há muito tempo no código**:
  - Suspeita: **algo de fora ou em volta mudou recentemente**, não o código em si.
  - Investigue: mudança de input, atualização de dependência, alteração na base de dados, mudança de ambiente, configuração diferente.
  - O código que funcionava por 6 meses não quebrou sozinho. Algo externo mudou. Trace o contexto.

- **Notepad++ é também uma ferramenta de produção**:
  - Use para escrever e revisar tasks em `.md` — markdown puro é melhor do que tools pesados.
  - Use para estruturar prompts e outputs de AI Generativa (Prompt Engineering): crie em `.md`, revise no editor, depois passe para a IA revisar e refinar.
  - Markdown limpo + Notepad++ = velocidade máxima em documentação e preparação de contexto para IA.

### Cuidados críticos com Produção

- **Nunca rode grandes períodos de processamentos de dados em PRD** — dados em background ou processamento pesado podem sobrecarregar o banco e derrubar o sistema.
- **Tome cuidado com grandes ranges e execuções de fila** — podem ser onerosos e atacar o banco de dados. Sempre teste o impacto antes de subir.
- **Crie observabilidade de erros em produção**: implemente try/catch com alertas via Teams que **vão SEMPRE para o time todo em cópia** (nunca para um único indivíduo). Use lambdas/functions de alertas para avisos críticos. Isso garante visibilidade coletiva e rápida resposta.
- **Revise seu código antes de mandar para PRD** — se algo quebrar em produção, você é responsável. Não deixe para o revisor ou para o ambiente descobrir.

## 04. Comunicação com usuários

- **Bom analista é sempre pró-ativo**: pergunta, comunica com o time, combina tudo, tira dúvidas e formaliza tudo por email. Isso cria um registro transparente do que foi acordado.
- **Pegue suportes para fazer, mesmo sendo difícil** — depois formalize por email o que foi feito. Solicite o OK do usuário e documente. Isso deixa a solução rastreável e evita retrabalho.
- **Leia bem o código que escreve** e revisa tudo antes de mandar para PRD. Após ser lançado, verifica se está tudo nos conformes.
- Não exponha **informações internas do time** — isso abre precedentes para o usuário opinar sobre processos e subestimar a complexidade do trabalho.
- **Nunca se comprometa com o usuário**. Sempre diga que vai avaliar e retorne depois com uma resposta bem fundamentada. Comprometimento verbal é uma armadilha — use email para tudo.
- Não faça promessas. Fale o necessário e **alinhe internamente antes de qualquer comprometimento externo**.
- Pergunte sempre se o suporte é urgente. **Priorize por criticidade**, não por ordem de chegada — quem está com mais dor é atendido primeiro.
- **Seja pró-ativo em suportes**: quando for um problema de usuário, dê a solução mais rápida e paliativa que conseguir, enquanto trabalha na definitiva em paralelo. Mostra que você está no topo.
- Mantenha **distância profissional**. Cordialidade excessiva cria precedentes de disponibilidade e consome tempo sem retorno real. Usuários que se fazem de amigos podem te sabotar na primeira oportunidade — não confie além do necessário.

## 05. Gestão de tempo e foco

- Seja **auto-gerenciado**. Faça planejamento diário: o foco principal é a feature da sprint; suportes ficam para o fim do dia.
- **Auto-gerencie as tarefas e desenhe sozinho a solução**. Não fique esperando instruções detalhadas — você tem capacidade de ver o escopo e executar.
- **Não deixe ninguém saber o quanto você consegue entregar de demandas** — não exponha sua capacidade. Seu "pote" é só seu. Se souberem quanto você aguenta, vão sobrecarregá-lo.
- **Em tarefas de mesma prioridade, faça as mais fáceis primeiro** — mostra que você não está travado e gera momentum. Sucesso em pequenas coisas é visível e constrói reputação de produtividade.
- Evite **calls longas** para assuntos simples. Gerencie seu tempo com maestria — ele é escasso e precisa ser investido nas prioridades certas.
- Se for urgente, acione o time imediatamente para resolver mais rápido. **Ser proativo em problemas críticos** é diferente de ser solícito o tempo todo.

## 06. Estabelecimento de limites

- Nunca segure a bola: **passe sempre ao usuário o que é responsabilidade dele**. Se ele consegue fazer via tela, deixe — intervenha somente no que é exclusivamente de dev.
- Ser proativo em resolver problemas é diferente de ser **solícito a tudo**. Abertura excessiva ao suporte cria precedente de que seu tempo é irrestrito.
- **Dizer não, quando necessário, é profissionalismo** — não descompromisso.

## 07. Alinhamento com time e cobertura

- Alinhe tudo com seu head antes de executar — **nunca o atropele**. Coisas que o usuário tenta empurrar sem alinhamento devem ser escaladas.
- Quando estiver travado, consulte rapidamente os sêniors. A dúvida resolvida cedo gera velocidade; a dúvida guardada gera retrabalho.
- Mantenha **amizade genuína com o time** — eles ampliam sua capacidade. Com usuários, mantenha profissionalismo.
- Peça feedback regularmente aos seus pares e principalmente ao seu gestor. **Não espere a avaliação formal** — vá atrás. Quem pede feedback sinaliza maturidade e se posiciona melhor para crescer.
- Se perceber que vai atrasar uma tarefa, comunique ao seu gestor com **pelo menos 3 dias de antecedência**. Mesmo que ele estime prazos com gordura, o aviso é necessário — previsibilidade permite que o head replaneje sem ser surpreendido. Atraso sem aviso é pior do que o atraso em si.

## 08. Conhecimento organizacional e documentação

- Entenda a **estrutura, hierarquia e famílias internas** da empresa. Ser conhecido e transitar bem entre as áreas facilita alinhamentos e aumenta sua influência positiva.
- Documente processos e **estude o contexto estratégico** — PETI, PE e planos semestrais. Entender onde seu trabalho se encaixa no todo é diferencial de senioridade.
- Usuários devem entregar **boas specs**. Na ausência delas, o dev assume — mas isso deve ser registrado e tratado como exceção, não padrão.
- **Compreenda profundamente o que você está fazendo e o porquê**. Você só evolui de júnior quando para de focar em cargo e começa a entender de verdade: por que essa solução? Como esse sistema funciona por baixo? Qual dor real estou resolvendo? Dev que conhece apenas a tarefa é descartável. Dev que entende o sistema, a lógica de negócio e o propósito é insubstituível. Invista em compreensão estrutural, não em tarefas.

## 09. Presença e relacionamentos estratégicos

- Chegue cedo e saia tarde — mas **respeite seu contrato**. O primeiro e o último a sair constroem reputação de comprometimento. Em ambientes sem ponto rígido, isso é ainda mais visível e lembrado.
- Almoce com seus **usuários finais** quando possível — aproxima, acalma conflitos e humaniza a relação. Se não for viável, almoce com pares de outras equipes: negócios, produto, operações. Esses momentos constroem pontes que agilizam qualquer alinhamento futuro.
- **Ser conhecido é um ativo**. Quanto mais pessoas souberem quem você é e o que você entrega, mais fácil é alinhar, influenciar e crescer dentro da organização.

## 10. Mentalidade e comportamentos de elite

### Arquitetura e Sistema

- **Pense em sistemas, não em features**. Cada entrega tem efeitos de segunda ordem — o que quebra quando isso escalar 10x? O que mais no sistema isso toca? Devs 10x enxergam o todo antes de codar a parte.
- **Torne estruturas flexíveis e genéricas como conceitos distintos**:
  - *Flexível*: Estruturas adaptáveis a diferentes casos de uso sem perder coesão.
  - *Genérica*: Componentes ou lógicas reutilizáveis em múltiplos contextos do sistema.
  - **Não otimize o que deveria ser deletado**. Antes de refatorar ou generalizar, pergunte: *"esse código realmente precisa existir ou está gerando mais complexidade do que valor?"* A melhor linha é a que não precisa ser escrita.

### Tomada de Decisão

- **Conforto com ambiguidade**. Dev júnior espera a spec perfeita. Dev 10x toma uma decisão, documenta a premissa e avança — sabe que nenhuma spec sobrevive ao contato com a realidade.
- **Discorde e comprometa-se**. Levante sua objeção com clareza e dados. Mas quando a decisão for tomada, execute com total comprometimento — sem resistência passiva. Isso é maturidade profissional.
- Para **decisões importantes do time** (ex.: definições de arquitetura, priorização de *features*, adoção de novas tecnologias):
  - **Pergunte no chat do time o que todos acham** antes de ir adiante.
  - **Documente a decisão e os motivos** no mesmo canal para rastreabilidade.
  - **Dê suporte prioritário às pessoas importantes do negócio**, mas sempre comunique isso no chat do time para manter transparência e alinhamento.
- **Dono do resultado, não só do código**. Se algo vai à produção com problema, dev 10x não diz *"minha parte estava certa"*. Ele assume o resultado final como seu. *Ownership* total.

### Comunicação e Processos

- **Reputação se constrói pela consistência**, não por heroísmo. Entregar no prazo toda semana vale mais do que uma virada de noite épica a cada trimestre. **Confiabilidade é o maior diferencial**.
- **Gerencie seu gestor** — não espere ele vir até você. Atualizações proativas evitam reuniões. Uma mensagem curta de status no momento certo vale mais do que 1h de call.
- **Proteja sua manhã**. As primeiras 2h do dia são ouro para trabalho profundo. Email, Slack e reuniões vão para a tarde. Devs que não protegem esse bloco trabalham o dobro para entregar o mesmo.
- **Defina um time-box para bloqueios**. Se estiver travado por mais de 30 minutos, escale — não fique 3h num problema que um sênior resolve em 5 minutos. Saber a hora de pedir ajuda é habilidade, não fraqueza.
- **Comunique em escrita sempre que possível**. Decisões escritas são rastreáveis, assíncronas e evitam o jogo do telefone sem fio. Dev que escreve bem resolve problemas sem precisar de reunião.
- **Seu PR é um documento de comunicação**. Uma boa descrição conta o que mudou, por que, o que o revisor deve olhar e como testar. PR sem contexto é trabalho empurrado para quem vai revisar.
- **Mostre o trabalho cedo**. Feedback no início do desenvolvimento é barato. Feedback em produção é caro. Compartilhe rascunhos, WIPs e protótipos antes de estar perfeito.
- **Seja totalmente autogerenciado**. Você é seu próprio gestor — não espere supervisor, deadline externo ou validação para se organizar. Autodisciplina é diferencial de dev 10x.
- **Organize seu dia em blocos de trabalho**. Agrupe tarefas por tipo e proteja períodos contínuos para trabalho profundo. Isso reduz custo de contexto e amplifica produtividade.
- **Sempre priorize função sobre forma**. Notas simples em papel ou markdown enxuto funcionam melhor que documentação perfeita nunca iniciada. O que funciona agora vale mais que o que seria perfeito amanhã.
- **Comece sempre com a solução mais simples possível**; refine e rebusque *depois* de garantir o básico funcionando. Evite a armadilha da preparação excessiva — é procrastinação disfarçada de perfeccionismo.
- **Economize energia cognitiva** aplicando rigorosamente as técnicas descritas no guia de produtividade (`Produtividade.md`: blocos de tempo, priorização, redução de complexidade). Sistematizar workflows economiza combustível mental para o que realmente importa.
- **Entenda seu verdadeiro diferencial**. Você não vence em código — dev indiano sabe mais, IA programa melhor. Sua vantagem é irreplicável: disponibilidade, rosto, voz, presença. O capital humano que você oferece é o que máquinas não conseguem entregar.
- **Apareça nas reuniões**. Câmera ligada, compareça presencialmente quando puder, fale com pessoas. Invisibilidade é morte profissional — você não pode ser insubstituível se ninguém sabe quem você é.
- **Demonstre genuíno interesse**. Interesse em entender o problema, nos usuários, no negócio. Interesse pela qualidade do que você entrega. Pessoas trabalham com quem elas gostam — e gostam de quem genuinamente se importa.
- **Construa reputação como ativo estratégico**. Ser conhecido, confiável e acessível — mesmo que você não seja o melhor programador — te torna impossível de substituir. Reputação leva anos para construir e segundos para perder. Proteja-a como seu bem mais valioso.

### Negócio e Impacto

- **Entenda o modelo de negócio**. Saiba como a empresa ganha dinheiro. Todo *trade-off* técnico tem uma consequência de negócio — devs que falam *"business"* avançam muito mais rápido na carreira.
- **No ITIL v5, TI é função estratégica do negócio**. O novo perfil exigido é dev que compreende business, alinha soluções técnicas aos objetivos organizacionais e entende como a tecnologia gera valor. Isso não é conhecimento opcional — é diferencial de senioridade.
- **Compartilhe conhecimento ativamente**. Dev 10x não acumula contexto sozinho — documenta, explica, sobe os *juniors*. Time que compartilha conhecimento é resiliente; time que sila é frágil.

---

# Guia de Técnicas de Produtividade

> Princípio: o sistema deve gastar **menos energia cognitiva do que economiza**. O mais simples que resolve o problema é superior ao mais complexo que o resolve marginalmente melhor.

---

## Gerenciamento temporal

**Pomodoro** (Cirillo, 1980s): 25 min de trabalho + 5 de pausa; pausa longa de 15-30 após 4 pomodoros. Variações 50/10 e 90/20 (ritmos ultradianos). Usar para tarefas complexas.

**GTD** (David Allen): Capturar → Clarificar (acionável? próximo passo?) → Organizar → Refletir (revisões) → Engajar.

**52/17** (DeskTime 2014): 52 min de trabalho + 17 de pausa. ⚠️ Repetição de 2021 achou ótimo em **112/26**.

**Time Blocking**: dividir o dia em blocos por tipo de trabalho (deep work, reuniões, admin, estudo).

**Timeboxing**: tempo máximo fixo por tarefa; quando acaba, completa ou reavalia. Combate perfeccionismo.

## Priorização

**Matriz de Eisenhower**: Q1 fazer agora, Q2 agendar (maior valor estratégico), Q3 delegar, Q4 eliminar.

**ABCDE** (Brian Tracy): A=consequências severas, B=moderadas, C=sem consequências, D=delegável, E=eliminável.

**MoSCoW**: Must (essencial), Should (importante), Could (desejável), Won't (excluído). Escopo de projetos/sprints.

**Pareto 80/20**: 80% dos resultados vêm de 20% dos esforços — foque no 20% mais impactante.

**Ivy Lee** (1918): à noite, liste as 6 tarefas mais importantes de amanhã em ordem de importância; execute em sequência sem desviar; não concluídas rolam para o dia seguinte.

**Must/Should/Want**: equilibrar obrigações com motivação (ex.: 4h Must, 2h Should, 1h Want). Evita burnout.

**Scrum Poker + Eisenhower** (priorização com critério objetivo):
1. Eisenhower → peso: Imp+Urg=4, Imp+NãoUrg=3, NãoImp+Urg=2, NãoImp+NãoUrg=1
2. Estime esforço com Fibonacci (1, 2, 3, 5, 8, 13)
3. `Score = Peso ÷ Esforço` → score alto sobe na lista

## Foco e trabalho profundo

**Deep Work** (Cal Newport): atenção focada que produz novos conhecimentos/habilidades. Regras: trabalhe em profundidade, abrace o tédio, saia das redes sociais, elimine distractivos.

**Flowtime**: trabalhe enquanto estiver em fluxo; pause quando o fluxo naturalmente terminar. Melhor para trabalho criativo.

**BPT — Biological Prime Time** (Sam Carpenter; Chris Bailey): usar os picos naturais de energia. Rastreie energia por 3+ semanas, proteja os picos para Deep Work e reserve os vales para admin.

## Hábitos

**Don't Break the Chain**: marque X no calendário por dia praticado; o medo de quebrar a sequência motiva. ⚠️ Atribuição ao Seinfeld é mito (negada por ele).

**Eat the Frog**: faça a tarefa mais difícil/desagradável primeiro, antes de tudo.

**Tiny Habits** (BJ Fogg): `Após [gatilho existente], eu faço [micro-hábito]`. Comece mínimo, cresça depois.

## Sistemas baseados em listas

**Bullet Journal** (Ryder Carroll): `•` tarefa, `-` nota, `x` completo, `>` migrado, `<` agendado.

**Kanban Pessoal**: colunas A Fazer → Fazendo → Feito, com limite WIP.

**AutoFocus** (Mark Forster): leia a lista e faça a tarefa que "brilhar" para você naquele momento (prontidão psicológica).

**Do It Tomorrow** (Mark Forster): lista de hoje fechada (10-15 itens); qualquer novo item vai para amanhã. Reduz culpa e ansiedade. Combina com Ivy Lee 6.

**FVP — Final Version** (Mark Forster): marque a 1ª tarefa como âncora e percorra perguntando "esta deveria ser feita antes da âncora?"; a última âncora é a tarefa. Comparação relativa elimina paralisia decisória.

**A4 Macro → Micro**: uma folha A4 com Macro (3-6 meses) / Meso (3-5 iniciativas) / Micro (tarefas concretas). **Apenas regras de negócio** (sem detalhes técnicos). 1 folha = 1 coisa; revisão semanal.

---

## Comparação geral

| Técnica | Tipo | Melhor para | Desvantagem |
|---|---|---|---|
| Pomodoro | Tempo | Iniciantes, tarefas pequenas | Estruturado demais p/ Deep Work |
| GTD | Completo | Muitas tarefas, reduzir ansiedade | Curva de aprendizado |
| 52/17 | Tempo | Ritmos biológicos | Inflexível |
| Time Blocking | Agendamento | Foco por tipo de trabalho | Requer flexibilidade |
| Timeboxing | Tempo | Combater perfeccionismo | Pode sacrificar qualidade |
| Eisenhower | Priorização | Urgência vs importância | Subjetivo |
| ABCDE | Priorização | Granularidade fina | Muitos A's paralisam |
| MoSCoW | Priorização | Escopo de sprints | Requer consenso |
| Pareto 80/20 | Priorização | Maior impacto | Requer dados reais |
| Must/Should/Want | Priorização | Equilíbrio/motivação | Subjetivo |
| Scrum Poker | Estimativa | Esforço relativo | Não mede tempo |
| Ivy Lee 6 | Listas | Simplicidade + foco diário | Rígido |
| Bullet Journal | Listas | Registro flexível | Manual, difícil de buscar |
| Kanban | Visual | Fluxo visual | WIP management |
| AutoFocus | Listas | Flexibilidade | Pode parecer caótico |
| Do It Tomorrow | Listas | Dias com interrupções | Acumula amanhã |
| FVP | Listas | Decisões difíceis | Processo mais lento |
| Deep Work | Foco | Alta qualidade cognitiva | Requer ambiente controlado |
| Flowtime | Foco | Trabalho criativo | Menos disciplina |
| BPT | Foco/Energia | Otimizar picos de energia | 3+ semanas de setup |
| A4 Macro→Micro | Estratégia | Clareza de visão | Atualização semanal |
| Don't Break the Chain | Hábitos | Consistência | Uma quebra desmoraliza |
| Eat the Frog | Hábitos | Vencer procrastinação | Pressão matinal |
| Tiny Habits | Hábitos | Iniciar comportamentos | Não garante crescimento |

---

## Os 6 fundamentos cognitivos

Todas as técnicas são variações de 6 mecanismos (Poulin: "são componentes, não sistemas — mesmos blocos funcionais, rótulos diferentes"). Escolha **uma técnica por fundamento**.

| Fundamento | Técnicas | Pergunta |
|---|---|---|
| **Clareza de prioridade** | Eisenhower, ABCDE, MoSCoW, Pareto, FVP, Poker, Must/Should/Want | "O que importa mais?" |
| **Limitação de escopo** | Ivy Lee 6, Do It Tomorrow, Kanban WIP, A4, MoSCoW | "Quanto é demais?" |
| **Gestão de energia/atenção** | Pomodoro, 52/17, Timeboxing, Blocking, Deep Work, Flowtime, BPT | "Quando focar?" |
| **Externalização cognitiva** | GTD, Bullet Journal, Kanban, A4, Ivy Lee 6 | "Isso precisa estar na cabeça?" (memória de trabalho: 7±2, Miller) |
| **Consistência comportamental** | Chain, Eat the Frog, Tiny Habits | "Como garantir que eu faça?" |
| **Organização sistêmica** | GTD, Kanban, Poker, A4, Time Blocking | "Onde isso vive no sistema?" |

## Stack mínimo recomendado

Usar todas as técnicas cria regras e fricções demais. Use **uma por fundamento**:

| Fundamento | Recomendado |
|---|---|
| Estratégia + Escopo | **A4 Macro → Micro** |
| Prioridade | **Eisenhower + Scrum Poker** |
| Execução diária | **Ivy Lee 6** |
| Foco | **Deep Work no BPT** |
| Consistência | **Don't Break the Chain** |

Regra de adição: dor real → fundamento já coberto? (substitua, não adicione) → teste 2 semanas → nunca por curiosidade.

> Produtividade é um canivete suíço: você não usa todas as lâminas ao mesmo tempo.

## Recomendações por nível

- **Iniciante**: Ivy Lee 6 + Pomodoro 25/5 + A4 Macro→Micro. Repetir 2 semanas.
- **Intermediário**: Eisenhower + Kanban + Ivy Lee 6 + A4. Domingo: A4 da semana + backlog no Eisenhower; Sexta: retrospectiva 1h.
- **Avançado**: Ivy Lee 6 + A4 + BPT + Deep Work + FVP + Chain. Use FVP quando o Ivy Lee não resolver conflitos.

### Fluxo diário integrado
```
NOITE (10 min):  Ivy Lee 6 para amanhã; revisar BPT (quando é o pico?)
MANHÃ (Deep Work): tarefa #1 em Pomodoro 50/5 × 3, sem slack/e-mail
MEIO-DIA:         tarefas #2-4, e-mail, reuniões, admin
TARDE (15 min):   capturar notas do dia, registrar ideias
FIM DO DIA (10 min): quantas do Ivy Lee completei? o que bloqueou? lista de amanhã; marcar X no Chain
```

---

## Stack do Gestor (WHG) — dicas de William Ribeiro

- **Rotina** com planner (OneNote); metas alcançáveis; mesclar com Kanban.
- **Prioridades**: Pareto 80/20 — os 80% são as tarefas simples.
- **Evite distrações**: conectado com SLA curto, mas suportes organizados.
- **Prazos**: balanço no fim do dia.
- **5 min com o colega** (nada de celular) — treina o cérebro a não procrastinar.
- **Pomodoro só para tarefas complexas**; resto: celular com timer e planner.
- **Profissional guiado** (executa tarefas simples revisáveis) vs **coordenado** (desenha do início ao fim). Bom profissional faz os dois; revise o desenho em pares, com feedbacks simultâneos, antes de colocar a mão no código.


---

## [2026-08-24 23:29] Anotações sobre Cândido Portinari

- Biografia de Cândido Portinari:
  - Data de nascimento anotada: 30 de dezembro de 1930
  - Mudou-se de São Paulo aos 15 anos de idade

> 📄 Lote 2026-08-24 · folha 1 · lida com confiança


---

## [2026-08-25 09:22] Anotações Biográficas sobre Cândido Portinari

- Dados biográficos sobre Cândido Portinari.
- Registro de nascimento em 30 de dezembro de 1930.
- Mudança: Deixou São Paulo aos 15 anos de idade para fixar nova residência.

> 📄 Lote 2026-08-25 · folha 1 · lida com confiança
