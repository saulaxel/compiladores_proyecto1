/*===========================================*
 * Analizador lexico del pseudo-lenguaje     *
 *                 Alemán-C                  *
 *                                           *
 *    ----- Estructura Pila: cabecera ----   *
 *===========================================*/

#ifndef PILA_H
#define PILA_H

/* ##### Cabeceras con definiciones globalmente ##### */
#include <stdbool.h>    // Para hacer uso de datos booleanos

typedef struct pila Pila;   // Declaración anticipada de la pila

/* ##### Prototipos de función ##### */
Pila * Pila_Nueva(void);
void   Pila_Borrar(Pila * p);

bool Pila_Insertar(Pila * p, void * elemento);

void * Pila_RevisarPosicion(Pila * p, int posicion);

#endif /* PILA_H */
