# Consultas F3 customizada

* ConsFile
   * Fonte pra criar uma consulta F3 customizada a partir de um select ou a partir de um tabela (SX ou Top)
Esse fonte utiliza um arquivo txt que deve ser colocado na protheus_data do servidor, utiliza as configurações do txt para apresentar a tela.

* ConsArq
  * Fonte para pesquisar um arquivo, utiliza a função cGetFile() para buscar o nome do arquivo.

Exemplo de arquivo da função CONSFILE

Expressão:<br />
U_ConsFile("\consulta\consulta_produto.txt")<br />
Retorno:<br />
U_RetConsf()<br />

Exemplo de um arquivo txt com as configurações necessárias

```
--INICIO_PARAM
--TITULO_JANELA
Consulta Funcionário
--RETORNO_CONSULTA
EMPFILMAT
--TAMANHO_TELA_COLUNA
700
--INI_PESQUISAS
Empresa,EMPRESA
Matricula,RA_MAT
Nome,RA_NOME
EmpFilMat,EMPFILMAT
--FIM_PESQUISAS
--INI_COLUNAS
Empresa,5,EMPRESA
Filial,5,RA_FILIAL
Matricula,10,RA_MAT
Nome,50,RA_NOME
Emp Fil Mat,15,EMPFILMAT
--FIM_COLUNAS
--FIM_PARAM
--INICIO_SQL
SELECT * FROM SRAMULTEMP
--FIM_SQL
--INICIO_PARAM_SQL
01,ACOLS[N,ASCAN(AHEADER,{|| X[02]=="AF8_PROJET" })]
--FIM_PARAM_SQL
```
Consulta SX
```
--TITULO_JANELA
Consulta Parametros SX6
--TAMANHO_TELA_COLUNA
650
--RETORNO_CONSULTA
X6_VAR
X6_DESCRIC
X6_DESC1
X6_DESC2
--FIM_RETORNO_CONSULTA
--INI_PESQUISAS
Parametro,X6_VAR
--FIM_PESQUISAS
--INI_COLUNAS
Parametro,12,X6_VAR
Tipo,3,X6_TIPO
Descricão,50,X6_DESCRIC
Descricão 1,50,X6_DESC1
Descricão 2,50,X6_DESC2
--FIM_COLUNAS
--TABELA
SX6
```




