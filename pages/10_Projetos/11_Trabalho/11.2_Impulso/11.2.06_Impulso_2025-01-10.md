IMPULSO

TASK:

Investigar problema nos disparos de alguns templates

# confirmacao_matricula_utilidade 
Eu me chamo Sofia, sou coordenadora da unidade de  *_{{unidade}}_*. 
No dia *_{{data_matricula}}_* você realizou a matrícula do {{aluno}} e gostaría de confirmar alguma informações. 

Gostaria de parabenizar vocês pelo empenho com o futuro de seu filho e gostaríamos de confirmar as informações da matrícula.

• Responsável: *{{nome_responsavel}}*
• Nascimento do responsável: *{{nasc_responsavel}}*
• Aluno(a): *{{nome_aluno}}*
• Nascimento do aluno(a): *{{nasc_aluno}}*
• Endereço: *{{endereco}}*, CEP *{{cep}}*

Por segurança, não compartilhamos nem solicitamos números completos de documentos (CPF/RG) pelo WhatsApp.

*ERRO: Parametro faltando

Reproduzindo, vou criar um disparo de teste para meu número e deve dar ERRO


unidade
data_matricula
aluno
nome_responsavel
nasc_responsavel

nome_aluno
nasc_aluno
endereco
cep

O Sistema identificou 10 parametros, o template tem 10 parametros, mas percebi que cada "var" tem seu estilo específico de marcação, o erro pode estar aí

Olhando as vars salvas no Dynamo vi que twm 11 variavies(variavel de contato), pode ser que o template de erro por enviar 11 variaveis inves de 10


#appointment_scheduling_address 

Oi {{nome}}, estou entrando em contato para confirmar sua matrícula no nosso projeto centro de instrução mirim.
Está confirmado?

[TEMPLATE] confirmacao_matricula_utilidade (
aluno=Matheus Sousa Dias, 
cep=02280130, 
data_matricula=01/10/2025, 
endereco=Rua Professor Pereira Reis , 
nasc_aluno=19/11/2000, 
nasc_responsavel=19/11/1973, 
nome_aluno=Matheus Sousa Dias, 
nome_responsavel=Rogério, 
unidade=SiamesaDiadema)


confirmacao_matricula_utilidadev2

Cabeçalho

Olá, tudo bem?


body

Eu me chamo Sofia, sou coordenadora da unidade de  *_{{unidade}}_*. 
No dia *_{{data_matricula}}_* você realizou a matrícula do {{aluno}} e gostaría de confirmar alguma informações. 

Gostaria de parabenizar vocês pelo empenho com o futuro de seu filho e gostaríamos de confirmar as informações da matrícula.

• Responsável: *{{nome_responsavel}}*
• Nascimento do responsável: *{{nasc_responsavel}}*
• Aluno(a): *{{nome_aluno}}*
• Nascimento do aluno(a): *{{nasc_aluno}}*
• Endereço: *{{endereco}}*, CEP *{{cep}}*

Por segurança, não compartilhamos nem solicitamos números completos de documentos (CPF/RG) pelo WhatsApp.


Amostras de variáveis
Inclua amostras de todas as variáveis ​​na sua mensagem para ajudar a Meta a analisar seu modelo. Para fins de proteção de privacidade, lembre-se de não incluir informações do cliente.
Cabeçalho
Insira conteúdo para {{responsavel}}
{{responsavel}}
Insira conteúdo para {{responsavel}}
Kleber
Corpo
Insira conteúdo para {{unidade}}
{{unidade}}
Insira conteúdo para {{unidade}}
BOMBEIROS
Insira conteúdo para {{data_matricula}}
{{data_matricula}}
Insira conteúdo para {{data_matricula}}
13/09
Insira conteúdo para {{aluno}}
{{aluno}}
Insira conteúdo para {{aluno}}
Tiago
Insira conteúdo para {{nome_responsavel}}
{{nome_responsavel}}
Insira conteúdo para {{nome_responsavel}}
Kleber da Silva
Insira conteúdo para {{nasc_responsavel}}
{{nasc_responsavel}}
Insira conteúdo para {{nasc_responsavel}}
01/01/1990
Insira conteúdo para {{nome_aluno}}
{{nome_aluno}}
Insira conteúdo para {{nome_aluno}}
Enzo Lorenzo
Insira conteúdo para {{nasc_aluno}}
{{nasc_aluno}}
Insira conteúdo para {{nasc_aluno}}
01/01/2012
Insira conteúdo para {{endereco}}
{{endereco}}
Insira conteúdo para {{endereco}}
Rua sei la o que
Insira conteúdo para {{cep}}
{{cep}}
Insira conteúdo para {{cep}}
04477090
Rodapé
• Opcional
Rodapé do modelo de mensagem
Inserir texto
