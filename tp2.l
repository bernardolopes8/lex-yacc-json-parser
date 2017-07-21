%{

/* 	TRABALHO PRÁTICO 2 DE PL 
	FICHEIRO LEX
	BERNARDO LOPES - 32040
	TIAGO PADRÃO - 33061
*/

#include "y.tab.h"
%}

%option noyywrap

/* Estados usados para controlar a identificação das chaves e dos valores */

%x KEY VALUE

%%
\"				BEGIN(KEY);
<KEY>\"				BEGIN(INITIAL);
<KEY>(\\.|[^"])*		{yylval.string = strdup(yytext); return _KEY;}

\'				BEGIN(VALUE);
<VALUE>\'			BEGIN(INITIAL);

<VALUE>-?[0-9]+			{yylval.integer = atoi(yytext); return INTEGER;}
<VALUE>-?[0-9]+\.[0-9]+		{yylval.fp = atof(yytext); return FLOAT;}
<VALUE>(\\.|[^'])*		{yylval.string = strdup(yytext); return STRING;}

\{				return OBJECT_BEGIN;
\}				return OBJECT_END;
\[				return ARRAY_BEGIN;
\]				return ARRAY_END;
\:				return DOUBLE_DOTS;
\,				return COMMA;

[ \t\n]+			/* Ignora os espaços em branco, tabs e mudanças de linhas */
			
%%
