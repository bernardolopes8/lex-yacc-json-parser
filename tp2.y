%{

/* 	TRABALHO PRÁTICO 2 DE PL 
	FICHEIRO YACC
	BERNARDO LOPES - 32040
	TIAGO PADRÃO - 33061
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Variáveis globais

// String utilizada para guardar os valores que irão constituir a estrutura Data __json
char content[3000] = "Data __json = {";	

// String utilizada para guardar as chaves que irão constituir cada sub-estrutura
char structure_elements[6000] = ""; 	

// String auxiliar utilizada para guardar dados intermédios
char buffer[50]; 			

// String utilizada para guardar as chaves que irão constituir a estrutura principal
char main_structure_elements[6000] = "\ntypedef struct data{\n"; 

// Strings utilizadas para guardar a última chave lida e o último valor (string), respetivamente
char last_key[50], last_string_value[50];		

// Valor que indica o número de estruturas existentes dentro da estrutura principal, sendo incrementado cada vez que se encontra uma nova sub-estrutura
int structure_count = 0, 	

// Variável que pode ter três valores (0 - int, 1 - float, 2 - char), de forma a identificar o tipo do último valor lido
last_value_type, 	

// Variável de controlo utilizada para controlar se se está dentro de um array ou não	
is_array = 0, 	

// Variável que guarda o número de elementos do array que se está a processar		
array_element_count = 0, 	

// Varíavel que armazena o tamanho da maior string do array que se está a processar
string_length = 0, 		

// Variável de controlo utilizada para verificar se se está na estrutura principal ou não
is_main_structure = 1;		

// Declaração de funções
void new_structure();
void parse_structure();
void parse_main_structure();
void handle_key(int type);
void update_biggest_string_in_array();
%}

// Union utilizada para definir os tipos aceites pelo yylval. Desta forma, podem ser passados inteiros, strings e floats do Lex para o Yacc
%union 
{
        int integer;
        char *string;
	float fp;
}

// A análise sintática inicia-se no identificador object
%start object		

// Definição dos tokens que podem ser capturados através do Lex e associação aos tipos correspondentes da Union
%token <string> _KEY
%token <string> STRING
%token <integer> INTEGER
%token <fp> FLOAT
%token OBJECT_BEGIN OBJECT_END ARRAY_BEGIN ARRAY_END COMMA DOUBLE_DOTS

%%
// O objeto principal é delimitado por chavetas e é constituído por elementos que satisfaçam a regra 'data'
object	:	OBJECT_BEGIN data OBJECT_END {parse_main_structure();} 
	;

// Os sub-objetos são constituídos por um identificador, seguido de dois pontos e 'data' delimitada por chavetas
nested_object	:	field DOUBLE_DOTS {strcpy(buffer, $<string>1);} OBJECT_BEGIN {strcat(content, "{"); new_structure();} data OBJECT_END {strcat(content, "}"); parse_structure();}
		;
// A 'data' pode ser vazia, um par chave-valor, um array, um sub-objeto ou combinações destes elementos
data	:	
	|	pair
	|	array
	|	nested_object 
	|	data COMMA {strcat(content, ",");} data
	;

// Um array é constituído por um identificador, seguido de dois pontos e 'array_data' delimitada por parênteses retos
array	:	field DOUBLE_DOTS ARRAY_BEGIN {string_length = 0; strcat(content, "[");} array_data ARRAY_END {strcat(content, "]"); is_array = 1; handle_key(last_value_type); is_array = 0; array_element_count = 0; string_length = 0;}

// Um par chave-valor é constituído por dois identificadores separados por dois pontos
pair	:	field DOUBLE_DOTS field {handle_key(last_value_type);}
	;

// A 'array_data' pode ser constituído por um ou mais valores
array_data	:	field {array_element_count++;}
		|	field {array_element_count++;} COMMA {strcat(content, ",");} array_data
		;

// Um campo pode ser um identificador (key) ou um valor (integer, string ou float)
field	:	_KEY {$<string>$ = $1; strcpy(last_key, $<string>1);}

	|	STRING {$<string>$ = $1; strcat(content, "\""); strcat(content, $1); strcat(content, "\""); last_value_type = 2; strcpy(last_string_value, $1); update_biggest_string_in_array();}	

	|	INTEGER {$<integer>$ = $1; sprintf(buffer, "%d", $1); strcat(content, buffer); strcpy(buffer, ""); last_value_type = 0;}

	|	FLOAT {$<fp>$ = $1; sprintf(buffer, "%0.2f", $1); strcat(content, buffer); strcpy(buffer, ""); last_value_type = 1;}
	;


%%
// Função chamada ao ser encontrado o início de uma nova sub-estrutura
void new_structure() {

	// Indica que o processamento já não se encontra na estrutura principal
	is_main_structure = 0;	

	// Cria a definição da estrutura, indo buscar o seu nome ao buffer
	strcpy(structure_elements, "\ntypedef struct ");
	strcat(structure_elements, buffer);
	strcat(structure_elements, "{\n");

	// Copia a sub-estrutura para a definição da estrutura principal
	strcat(main_structure_elements, "struct ");
	strcat(main_structure_elements, buffer);
	strcat(main_structure_elements, " Data_");
	sprintf(buffer, "%d", structure_count + 1);
	strcat(main_structure_elements, buffer);
	strcat(main_structure_elements, ";\n");
	
	// Aumenta a contagem de sub-estruturas e limpa o buffer
	structure_count++;
	strcpy(buffer, "");
}

// Função chamada ao chegar ao fim de uma sub-estrutra
void parse_structure() {

	// Finaliza a definição da estrutura, adicionando o número respetivo
	strcat(structure_elements, "} ");
	sprintf(buffer, "%d", structure_count);
	strcat(structure_elements, "Data_");
	strcat(structure_elements, buffer);
	strcat(structure_elements, ";\n");
	
	// Limpa o buffer e a variável structure_elements para poderem ser utilizadas novamente
	// Imprime a definição da estrutura completa
	strcpy(buffer, "");
	printf("%s", structure_elements);
	strcpy(structure_elements, "");

	// Indica que o processamento regressou à estrutura principal
	is_main_structure = 1;
}

// Função invocada ao chegar ao fim da estrutura principal
void parse_main_structure() {

	// Limpar o buffer, termina a definição da estrutura principal e imprime-a
	strcpy(buffer, "");
	strcat(main_structure_elements, "} Data;\n\n");
	printf("%s", main_structure_elements);

	// Terminada a análise da string JSON, imprime a estrutura Data __json
	strcat(content, "};\n\n");
	printf("%s", content);		
}

// Função invocada ao ser analisada uma nova chave
void handle_key(int type) {
	
	// O destino da chave pode ser uma sub-estrutura ou a estrutura principal
	char *destination;
	if (is_main_structure == 1) destination = main_structure_elements;
	else destination = structure_elements;
	
	// O procedimento varia de acordo com o tipo a que corresponde a chave (0 - int, 1 - float, 2 - char)
	switch(type) {

		case 0: 
			// Copia o tipo da chave e o nome
			strcat(destination, "int "); 
			strcat(destination, last_key);
			
			// Verifica se a chave é o identificador de um array
			if (is_array == 1) {
				
				// Adiciona o tamanho do array
				strcat(destination, "["); 
				sprintf(buffer, "%d", array_element_count);
				strcat(destination, buffer);
				strcpy(buffer, "");
				strcat(destination, "]"); 
			}

			break;

		case 1: 
			// Copia o tipo da chave e o nome
			strcat(destination, "float "); 
			strcat(destination, last_key);

			// Verifica se a chave é o identificador de um array
			if (is_array == 1) {

				// Adiciona o tamanho do array
				strcat(destination, "["); 
				sprintf(buffer, "%d", array_element_count);
				strcat(destination, buffer);
				strcpy(buffer, "");
				strcat(destination, "]"); 
			}

			break;

		case 2: 
			// Copia o tipo da chave e o nome
			strcat(destination, "char "); 
			strcat(destination, last_key);

			// Verifica se a chave é o identificador de um array
			if (is_array == 1) {

				// Adiciona o tamanho do array
				strcat(destination, "["); 
				sprintf(buffer, "%d", array_element_count);
				strcat(destination, buffer);
				strcpy(buffer, "");
				strcat(destination, "]"); 
			}
			
			// Adiciona o tamanho da string
			strcat(destination, "["); 
			
			// Caso a chave seja o identificador de um array, o tamanho da string corresponde ao
			// tamanho da maior string existente no array
			if (is_array == 1) sprintf(buffer, "%d", string_length);
			else {

				// Caso contrário, o tamanho é o da última string lida
				int aux = strlen(last_string_value) + 1;
				sprintf(buffer, "%d", aux);
			}

			strcat(destination, buffer);
			strcpy(buffer, "");
			strcat(destination, "]");

			break;
	}

	strcat(destination, ";\n");
}

// Função que compara o tamanho da última string lida com o tamanho da maior string existente no array e atualiza o seu valor
void update_biggest_string_in_array() {
	if (strlen(last_string_value) >= string_length) string_length = strlen(last_string_value) + 1;
}

int main() {
	yyparse();
	return 0;
}

extern int yylineno;

int yyerror(char *s) {
	fprintf(stderr, "ERRO (L%d): %s\n", yylineno, s);
	return 0;
}
