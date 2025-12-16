- Se eu pesquisar uma regra X, o OK tem que ser da regra X

- Remover o status e data aqui da legenda de pessoas (pessoa selecionada)

- Criar combo "Seleção de Status" (OKs NOKs e Não executado)
e esse serão checkboxes e nao Radio Buttons (todos marcados por default e regra de ao menos um selecionado)
	Com: Todos OK, Todos NOK, Todos não executados

- Adicionar nao executados nos cards de Total OK NOK 

- padrao , 20 resultados na paginação do data grid

- Trazer todos os clientes caso ao Selecionar Nenhum

- Nem todas as Regras deveriam aparecer (Cad. Regras)
- Quando são pessoas sem dados, retorna somente as Regras do Cad. Regras, mas quando a pessoa tem dados, está trazendo todas as regras (Errado!)

- Exibit no master detail o historico, e nao d-1 pra frente, tem que exibir todos até o master atual no historico de detail

- Mandar pesquisa para o final e o globo sendo o primeiro item

- ajustar a data acima para trazer ultima data (checkbox de Ultima posição vai liberar ou não a data) (ver exemplo Luis tela de IPS/opções)


-----------------------------
- Remover o status e data aqui da legenda de pessoas (pessoa selecionada) OK 
- Adicionar nao executados nos cards de Total OK NOK     OK
- Deixar 20 resultados exibidos no DataGrid omo padrão na paginação OK
- Na barra de ferramentas do DataGrid, colocar o "Pesquisar" por último, e colocar em primeiro o "Globo" de "Processar Análises" OK
- Criar na tela uma "Seleção de Status"(pra nao ficar junto com Seleção de Pessoas como é hoje) (OKs NOKs e Não executado) e esse serão checkboxes e nao Radio Buttons (todos marcados por default e regra de ao menos um selecionado) OK
	Com: Todos OK, Todos NOK, Todos não executados 
BACKEND
- Nem todas as Regras deveriam aparecer (Cad. Regras), Quando são pessoas sem dados, retorna somente as Regras do Cad. Regras, mas quando a pessoa tem dados, está trazendo todas as regras (Errado!) OK
BACKEND
- Trazer todos os clientes caso ao selecionar Nenhuma Pessoa (vai retornar todos os clientes selecionados nao só aqueles que tem dados , como ocorre hj), quando eu seleciono alguma pessoa que nao tem dados , ela é retornada, mas se nao seleciono nenhuma pessoa, só retorna as pessoas que tem dados, esta errado, se eu nao seleciono nenhuma pessoa, tem que retornar todas as pessoas com dados e sem dados (essa sem dados terao valores vazios asism como ocorre quando selecionamos uma pessoa que nao tem dados) OK

BACKEND
- No Detail do DataGrid, hj mostramos o historico anterior a d-0 (d-1 pra frente),invés disso temos que exibir todos até o master atual no historico de detail
	-> Quero dizer que o dado que aparece no Master tem que estar no detail tbm, vamos mostrar no detalhe d-0 tambem 

- Ter a opção de trazer as últimas datas disponivel de cada Pessoa para trazer ultima data (checkbox de Ultima posição vai liberar ou não a data de referencia) 
Exemplo:
    <div class="col-4">
      <div class="caption">Data Posição</div>
      <hr />
      <div class="row horizontal-align">
        <div class="col-5">
          <div class="dx-field">
            <dx-check-box style="margin-right: 10px" [(value)]="filtroAtual.FlUltimaPosicao"></dx-check-box>
            Última Posição
          </div>
        </div>
        <div class="col-7">
          <div class="dx-field">
            <dx-date-box applyValueMode="useButtons" displayFormat="dd/MM/yyyy"
              [(value)]="filtroAtual.DtPosicao"
              placeholder="Data Posição" [disabled]="filtroAtual?.FlUltimaPosicao === true">
              <dxi-button name="dropDown"></dxi-button>
            </dx-date-box>
          </div>
        </div>
      </div>
    </div>


(ver exemplo Luis tela de IPS/opções)

- Se eu pesquisar por uma pessoa e por uma regra X, o OK tem que ser da regra X, o Get de pessoas precisa considerar a regra que estou selecionando no frontend para considerar, pois da forma que esta hj ele considera o Ok se todas as regras da pessoa estao Ok, e na vdd deveria considerar OK somente da regra ou regras perguntadas.
Hoje a seleção de pessoas trás o Ok da pessoa considerando todas as regras, e deveriam considerar somente as regras selecionadas para gerar esse OK ou Não
	



	Suportes Consolidação
		Pedro
		Cotrim
	
	
	
	
	
	
	Criar o banco no supabase com base no MER do Rogerio 	com email coreimpulso@gmail.com OK 
	Ajustar MER OK
	Como Banco Ajustar mocks das lambdas para usar valores de parametro
	
	