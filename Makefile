EXE=tp2
CC=gcc
LEX=flex
YACC=yacc
TEST=testes/teste3.txt

all	:	test

test	:	$(TEST) $(EXE)
		./$(EXE) < $<
			
$(EXE)	:	yacc lex
		$(CC) lex.yy.c y.tab.c -o $@
			
lex	:	$(EXE).l y.tab.h
		$(LEX) $<
			
yacc	:	$(EXE).y
		$(YACC) -d $<
