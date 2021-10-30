# Funcão generica para substituir getsxenum
* criada para corrigir o fato de existir codigos que não devem ser considerados para pegar o proximo.

* Essa função sempre executa um select MAX para buscar o proximo registro
evitando a perda de posições.
* Permite passar parametros para desconsiderar ou considerar certos codigos, de forma que os 
codigos cadastrados errados não interferem para trazer o proximo registro
* Caso 2 ou mais usuarios busquem o proximo numero a rotina consegue trazer de forma 
correta pois nesse caso será utilizado um arquivo criado dinamicamente para buscar 
o proximo numero

Exemplo:

Colocar a função abaixo no inicializador do campo de codigo a ser utilizado<br />
U_CGENX01("SA1","A1_COD","A",,.T.)
