Tela de PLD
 - Mudar o nome da coluna "Observacao" que tem nas regras para "DescriçãoSistema" OK 
 
 - Add coluna "Observação" (esta mesma tem que ser editável no data grid do devexpress na tela para ser salva no DB, é uma nova coluna na tabela) no Master (do Master Detail do DataGrid) OK 
 
 - Adicionar Botao de download do status anterior também (além do botao de download que já temos hj do Master) OK
 
 - Colocar data e horas nas Regras (para no download json aparecer) OK

 - colocar o tipo de "pessoas físicas" OK

 - Colocar "Observação" no detail Histórico OK

 - NO SelectDropDown de Seleção de Pessoas, adicionar a coluna Status(isso vai requerir um join no backend com os dados de Compliance) , assim espero mostrar NOK, OK, e quem não rodou ainda, adicionar também uma coluna que será a DtMax/última data que rodou no SelectDropDown de Pessoas OK
   
 - Fazer alusao as cores de atual e anterior nos botoes de download OK

 - Ser possível editar o passado/Detail (colocar os boteos de ações de aprovações + obs) OK

 - Mostrar custos da consulta (Ver preços api do bigdatacorp) e por essa coluna de custo da consulta no datagrid (calcular e colocar no pop -up de confirmação ao querer rodar uma consulta) DOING
 
 - Poder consultar datas do passado (exibir dia selecionar mas deixe um disclaimer claro que´são dados do passado) (mas nao é orbigatório), por padrao d-0 é o dia default OK

 - Mostrar custos da Análise que o usuário quer Processar (no pop de confirmação mostra o custo em reais que esse processamento irá gerar) e por essa coluna de custo da consulta no datagrid (calcular e colocar no pop -up de confirmação ao querer rodar uma consulta) DOING

Esses custos das APIs estaram atrelados as regras, ao abrir o  pop-up ele tem que 
* PEGAR PRIMEIRA FAIXA, PEGAR O CASO MAIS SIMPLES UNIT.
	KYC/PEP e Indicativo de Óbito: R$ 0,050 
Dados Básicos/CPF regular: R$ 0,090 
Valores baseados na tabela oficial da BigDataCorp (dataset pessoas e basic_data).

  - Use a tela de reconciliacao-portfolio para se inspirar, criar algo parecido com a seleção de Portflio
 Tipo e pessoa especifica, (na parte porfólio podemos selecionar se sao fundos, e porfólio especifico (COPIAR RECON)
   Fazer o mesmo na tela de PLD (item Pessoas) (por enquanto unica opção, ao selecionar essa oplão eu trago todas as pessoas , se a pessoa nao tiver o dado do dia, ela vai aparecer mas sem Status de NOK OU OK, e o seu detail estará vazio obviamente), obrigatorio colcoar o tipo de consulta (Pessoas)

- Seleção de Entidade virar radio button OK
- Filtros Rápidos OK
- Obrigar selecionar pelo menos uma regra, e remover clear buttond das regras e a calculadora(pop up de confirmação~) tem que se atualizar conforme essa mudança de regras e de pessoas selecionadas  OK
- Processar Analise Fica no Grid (Toolbar prepare) OK
- Tirar coluna Status do Seleção de pessoas (Tornar somente num grid de Pessoas), tirar Status e Dt última Análise OK
- Grid Arrancar coluna de Custos OK
- Mudar tela de Cad. Regras , add Coluna "PF"(vai ter que add na tabela e no map tbm do backend)(checkbox booleano para marcar se é PF ou nao a Regra)"  (pra marcar se a regra se aplica a pessoal física), e Mostrar na grid os que não foram executados mesmo assim
	-> Quando retornarmos uma pessoa que nao tem dado nenhum para determinada regra, ela só vai retornar as regras de PF se for PF, (se for PF vai retornar as regras de PF mesmo que essas estejam vazias sem dados, pq o intuito é mostrar pro usuário as regras aplicaveis a aquela pessoa e se estao em branco é pq nunca foi rodado) OK
	
	
Criar Seleção de Status 
	
- Bloquear a tela para nao ser utilizada ao estiver processando 
- Informar na tela quantos faltam processar 
- criar uma coluna de usu solicitacao, usuario que processa é prisma, mas o usuario que colocou a solicitacao é o Id_Usu_Solicitacao 






















