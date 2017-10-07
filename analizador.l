%{
/*===========================================*
 * Analizador lexico del pseudo-lenguaje     *
 *                 Alemán-C                  *
 *                                           *
 * ---- Programa principal: analizador ----  *
 *===========================================*/
#include <stdio.h>
#include <stdlib.h>
#include "pila.h"

#define MENSAJE_EMTERO(base) printf("Se ha encontrado el entero %ld que estaba en base %d\n",\
        strtol(yytext, NULL, (base)), (base))

/* ##### Prototipos de función ###### */
static void guardar_secuencia(char * secuencia);

/* ##### Variables de conteo y memoria ##### */
static Pila * pilaTokens;
static Pila * pilaIdentificadores;

static int numero_lineas = 1;

/* ##### Grupos de tokens ##### */

// Grupos básicos:
// digito            -> Digito decimal
// letra             -> Letra alemana
// identificador     -> Identificador
// reservada         -> Secuencia de caracteres
// palabraReservada  -> Palabra básica del lenguaje

// Palabras reservadas:
// Tipos de datos (Solo habrá tipos básicos sin modificadores):
//      Ganzzahlig          -> Entero
//      Glepktpunkt         -> Número de punto flotante
//      Charakter           -> Caracter
// Sentencias de control
//      whährend            -> Ciclo mientras
//      für                 -> Ciclo for
//      ob                  -> Sentencia if
//      sonst               -> Sentencia else
//      wechsein            -> Sentencia switch
//      gehen               -> Sentencia goto
//      fortsetzen          -> Sentencia continue
//      unterbrechen        -> Sentencia break
//      zurückkehrem        -> Sentencia return
// Definición de datos
//      Struktur            -> Palabra struct
//      Union               -> Palabra union
//      Aufzählung          -> Palabra enum
//      Typdefinition       -> Palabra typedef

// Constantes numéricas
//      int_decimal     : (+|-)?([1-9]{digito}+|0)
//                      (Los números decimales no pueden iniciar con 0)
//      int_octal       : (+|-)?0[0-7]+
//      int_hexa        : (+|-)?0x[0-9A-Fa-f]+
//      flt_decimal     : (+|-)?({digito}+(\.{digito}*)?|\.{digito}+)
//      flt_exp         : ({flt_decimal}|{(+|-)?[0-9]+})e(+|-)?[0-9]+
//                      (No se puede usar {int_decimal} en esta parte por
//                       que los enteros decimales no aceptan empezar con 0)
//

// Errores
//      err_cadena      : \".*
//      err_numero      : ({int_decimal}|{int_octal}|{int_hexa})|{letra}+

%}

digito              [0-9]
letra               [A-Za-zßÄÖÜäöü]
identificador       (_|{letra})(_|{letra}|{digito})*
cadena              "({letra}|{digito}|[_ \t]|\\n)*"
caracter            ('{letra}')
palabra_reservada (Ganzzahlig|Glepktpunkt|Charakter|whährend|für|ob|sonst|wechsein|gehen|fortsetzen|unterbrechen|zurückkehrem|Struktur|Union|Aufzählung|Typdefinition)
caracter_especial   "("|")"|"["|"]"|"{"|"}"|","|":"|";"

signo       (\+|-)?
int_sufijo  u?(l|L){0,2}|(l|L){0,2}u
flt_sufijo  f?

int_bin     {signo}0b[0-1]+{int_sufijo}
int_octal   {signo}0[0-7]+{int_sufijo}
int_decimal {signo}([1-9]{digito}*|0){int_sufijo}
int_hexa    {signo}0x[0-9A-Fa-f]+{int_sufijo}

flt_cuerpo  ({digito}+(\.{digito}*)?|\.{digito}+)
flt_decimal {signo}{flt_cuerpo}{flt_sufijo}
flt_exp     {signo}({flt_cuerpo}|[0-9]+)e{signo}[0-9]+{flt_sufijo}

op_aritmetico   "+"|"-"|"*"|"/"
op_logico       "&&"|"||"|"!"
op_bit          "&"|"|"|"^"|"<<"|">>"
op_incdec       "++"|"--"
op_asignacion   {op_aritmetico}=
op_relacional   "=="|"<"|">"|"<="|">="

err_cadena \".*
err_numero ({int_decimal}|{int_octal}|{int_hexa}){letra}+

espacio     [ \t]
salto_linea \n

%option noyywrap
%%
("//".*)|\/\*({espacio}|{letra}|{digito})*\*\/ {
                printf("Se encontró un comentario: %s\n", yytext); }
{salto_linea}       { numero_lineas++; }

{cadena}            { guardar_secuencia(yytext);
                      printf("Se encontró una cadena: %s\n", yytext); }
{caracter}          { guardar_secuencia(yytext);
                      printf("Se encontró un caracter: %s\n", yytext); }
{palabra_reservada} { guardar_secuencia(yytext);
                       printf("Se encontró una palabra reservada: %s\n", yytext); }
{identificador}     { guardar_secuencia(yytext);
                      printf("Se encontró un identificador: %s\n", yytext); }
{caracter_especial} { guardar_secuencia(yytext);
                      printf("Se encontro el caracter especial \"%s\"\n", yytext); }

{int_bin}           { guardar_secuencia(yytext); MENSAJE_EMTERO(2); }
{int_octal}         { guardar_secuencia(yytext); MENSAJE_EMTERO(8); }
{int_decimal}       { guardar_secuencia(yytext); MENSAJE_EMTERO(10); }
{int_hexa}          { guardar_secuencia(yytext); MENSAJE_EMTERO(16); }
{flt_decimal}|{flt_exp} { guardar_secuencia(yytext);
                          printf("Se encontró un flotante: %f\n", atof(yytext)); }

{op_aritmetico}     { guardar_secuencia(yytext);
                      printf("Se encontró el operador aritmético: \"%s\"\n", yytext); }
{op_logico}         { guardar_secuencia(yytext);
                      printf("Se encontró el operador lógico: \"%s\"\n", yytext); }
{op_bit}            { guardar_secuencia(yytext);
                      printf("Se encontró el operador bit a bit: \"%s\"\n", yytext); }
{op_incdec}         { guardar_secuencia(yytext);
                      printf("Se encontró el operador incremental: \"%s\"\n", yytext); }
{op_asignacion}     { guardar_secuencia(yytext);
                      printf("Se encontró el operador de asignación: \"%s\"\n", yytext); }
{op_relacional}     { guardar_secuencia(yytext);
                      printf("Se encontró el operador relacional: \"%s\"\n", yytext); }

{espacio}+          { /* Con los espacios en blanco no se hace nada */ }

{err_cadena}        { fprintf(stderr, "Cadena sin terminar en la línea: %d\n", numero_lineas); }
{err_numero}        { fprintf(stderr, "Valor numérico erroneo: %s\n", yytext); }

%%

void guardar_secuencia (char * secuencia)
{
    10 + 20;
}

void crear_tabla (char *cad)
{
    char carac[100];
    FILE *table;
    table = fopen("tabla1.txt","a");

    if (table == NULL) {
        perror("Error");
    } else {
        fprintf( table, "%s\n", cad );
        fclose(table);
    }
}

int main (int argc, const char *argv[])
{

    if ( argc > 1 ) {
        yyin = fopen(argv[1],"r");

        if ( yyin == NULL ) {
            fprintf(stderr, "No se pudo abrir el archivo\n");
            exit(EXIT_FAILURE);
        }

        pilaTokens          = Pila_Nueva();
        pilaIdentificadores = Pila_Nueva();

    } else {
        fprintf(stderr, "No se recibió el nombre del archivo\n");
        exit(EXIT_FAILURE);
    }

    yylex();    // Se llama al analizador

    return EXIT_SUCCESS;
}
