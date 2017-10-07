# Instrucciones de compilacion para el analizador lexico
# en aleman

# Compilador de C
CC = gcc

# Compilador de flex
FC = flex

# Banderas
CFLAGS = -std=gnu11 -Wall -Wextra -O3

analizador: analizador_lex.yy.o pila.o
	$(CC) -o $@ $< $(CFLAGS)

analizador_lex.yy.o: analizador_lex.yy.c
	$(CC) -c -o $@ $< $(CFLAGS)

pila.o: pila.c pila.h
	$(CC) -c -o $@ pila.c

analizador_lex.yy.c: analizador.l
	$(FC) -o $@ $<

clean:
	rm *.o *.yy.c
