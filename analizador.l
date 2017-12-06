%{
/*===========================================*
 * Analizador lexico del pseudo-lenguaje     *
 *                 Alemán-C                  *
 *                                           *
 * ---- Programa principal: analizador ----  *
 *===========================================*/

/* ##### Cabeceras de bibliotecas ##### */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pila.h"

#ifndef NDEBUG
#   define MENSAJE printf
#else
#   define MENSAJE(...)
#endif

/* ##### Definiciones ##### */

#define MENSAJE_EMTERO(base) printf("Se ha encontrado el entero %ld que estaba en base %d\n",\
        strtol(yytext, NULL, (base)), (base))
#define GUARDAR_AMBOS(_tipo) guardar_token(yytext, guardar_simbolo(yytext), (_tipo))

#define ARCHIVO_TABLA_SIMBOLOS "salida_programa/tabla_simbolos.dat"
#define ARCHIVO_TABLA_TOKENS   "salida_programa/tabla_tokens.dat"

/* Clases de token
 * 0 -> palabra reservada
 * 1 -> identificador
 * 2 -> numero entero
 * 3 -> numero real
 * 4 -> operador aritmético
 * 5 -> operador lógico
 * 6 -> operador relacional
 * 7 -> operador bit a bit
 * 8 -> operador incremento
 * 9 -> operador asignación
 * 10-> cadena
 * 11-> carácter
 * 12-> simbolo especial
 */

enum clase_token {
    PALABRA_RESERVADA, IDENTIFICADOR,
    NUMERO_ENTERO, NUMERO_REAL,
    OPERADOR_ARITMETICO, OPERADOR_LOGICO,
    OPERADOR_RELACIONAL, OPERADOR_BIT_A_BIT,
    OPERADOR_INCREMENTO, OPERADOR_ASIGNACION,
    CADENA, CARACTER, SIMBOLO_ESPECIAL
};

struct token {
    enum clase_token clase;

    union {
        int numero_simbolo;
        char *lexema;
    };
};

/* ##### Prototipos de función ###### */
static int guardar_simbolo(char * simbolo);
static void guardar_token(char * simbolo, int posicion, enum clase_token clase);
static void crear_tablas(void);
static int comparar_cadena(const void * cad1, const void * cad2);
static void recontar_lineas(char * comentario);
static void liberarToken(void * token);
static void liberarLexema(void * lexema);

/* ##### Variables de conteo y memoria ##### */
static Pila * pilaTokens;
static Pila * pilaSimbolos;

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

digito [0-9]
letra [A-Za-zßÄÖÜäöü]
identificador (_|{letra})(_|{letra}|{digito})*
cadena "({letra}|{digito}|[_ \t]|\\n)*"
caracter ('{letra}')
palabra_reservada (Ganzzahlig|Glepktpunkt|Charakter|whährend|für|ob|sonst|wechsein|gehen|fortsetzen|unterbrechen|zurückkehrem|Struktur|Union|Aufzählung|Typdefinition)
caracter_especial "("|")"|"["|"]"|"{"|"}"|","|":"|";"

signo (\+|-)?
int_sufijo u?(l|L){0,2}|(l|L){0,2}u
flt_sufijo f?

int_bin {signo}0b[0-1]+{int_sufijo}
int_octal {signo}0[0-7]+{int_sufijo}
int_decimal {signo}([1-9]{digito}*|0){int_sufijo}
int_hexa {signo}0x[0-9A-Fa-f]+{int_sufijo}

flt_cuerpo ({digito}+(\.{digito}*)?|\.{digito}+)
flt_decimal {signo}{flt_cuerpo}{flt_sufijo}
flt_exp {signo}({flt_cuerpo}|[0-9]+)e{signo}[0-9]+{flt_sufijo}

op_aritmetico "+"|"-"|"*"|"/"
op_logico "&&"|"||"|"!"
op_bit "&"|"|"|"^"|"<<"|">>"
op_incdec "++"|"--"
op_asignacion ({op_aritmetico}|{op_bit})?=
op_relacional "=="|"<"|">"|"<="|">="

com_linea "//".*
com_multilinea "/*"[^/]*"*/"

err_cadena \".*
err_numero ({int_decimal}|{int_octal}|{int_hexa}){letra}+
err_comentario "/*"[^(\*\/)]*?

espacio [ \t]
salto_linea \n

%option noyywrap
%%
{com_linea}|{com_multilinea} {
                      MENSAJE("Se encontró un comentario:\n%s\n", yytext);
                      recontar_lineas(yytext); }
{salto_linea}       { numero_lineas++; }

{cadena}            { MENSAJE("Se encontró una cadena: %s\n", yytext);
                      GUARDAR_AMBOS(CADENA); }
{caracter}          { MENSAJE("Se encontró un caracter: %s\n", yytext);
                      GUARDAR_AMBOS(CARACTER);}

{palabra_reservada} { MENSAJE("Se encontró una palabra reservada: %s\n", yytext);
                      GUARDAR_AMBOS(PALABRA_RESERVADA); }
{identificador}     { MENSAJE("Se encontró un identificador: %s\n", yytext);
                      GUARDAR_AMBOS(IDENTIFICADOR); }
{caracter_especial} { MENSAJE("Se encontro el simbolo especial \"%s\"\n", yytext);
                      guardar_token(yytext, -1, SIMBOLO_ESPECIAL); }

{int_bin}           { MENSAJE_EMTERO(2);  GUARDAR_AMBOS(NUMERO_ENTERO); }
{int_octal}         { MENSAJE_EMTERO(8);  GUARDAR_AMBOS(NUMERO_ENTERO); }
{int_decimal}       { MENSAJE_EMTERO(10); GUARDAR_AMBOS(NUMERO_ENTERO); }
{int_hexa}          { MENSAJE_EMTERO(16); GUARDAR_AMBOS(NUMERO_ENTERO); }
{flt_decimal}|{flt_exp} { printf("Se encontró un flotante: %f\n", atof(yytext));
                          GUARDAR_AMBOS(NUMERO_REAL); }

{op_aritmetico}     { MENSAJE("Se encontró el operador aritmético: \"%s\"\n", yytext);
                      guardar_token(yytext, -1, OPERADOR_ARITMETICO); }
{op_logico}         { MENSAJE("Se encontró el operador lógico: \"%s\"\n", yytext);
                      guardar_token(yytext, -1, OPERADOR_LOGICO); }
{op_bit}            { MENSAJE("Se encontró el operador bit a bit: \"%s\"\n", yytext);
                      guardar_token(yytext, -1, OPERADOR_BIT_A_BIT); }
{op_incdec}         { MENSAJE("Se encontró el operador incremental: \"%s\"\n", yytext);
                      guardar_token(yytext, -1, OPERADOR_INCREMENTO); }
{op_asignacion}     { MENSAJE("Se encontró el operador de asignación: \"%s\"\n", yytext);
                      guardar_token(yytext, -1, OPERADOR_ASIGNACION); }
{op_relacional}     { MENSAJE("Se encontró el operador relacional: \"%s\"\n", yytext);
                      guardar_token(yytext, -1, OPERADOR_RELACIONAL); }

{espacio}+          { /* Con los espacios en blanco no se hace nada */ }

{err_cadena}        { fprintf(stderr, "Cadena sin terminar en la línea: %d\n", numero_lineas); }
{err_numero}        { fprintf(stderr, "Valor numérico erroneo %s en la línea %d\n",
                      yytext, numero_lineas); }
{err_comentario}    { fprintf(stderr, "Comentario multilinea sin cerrar en la línea %d\n",
                      numero_lineas); }

%%

int main(int argc, const char *argv[])
{

    if ( argc > 1 ) {
        yyin = fopen(argv[1],"r");

        if ( yyin == NULL ) {
            fprintf(stderr, "No se pudo abrir el archivo\n");
            exit(EXIT_FAILURE);
        }

        pilaTokens   = Pila_Nueva();
        pilaSimbolos = Pila_Nueva();

    } else {
        fprintf(stderr, "No se recibió el nombre del archivo\n");
        exit(EXIT_FAILURE);
    }

    yylex();    // Se llama al analizador

    crear_tablas();

    Pila_Borrar(pilaTokens, liberarToken);
    Pila_Borrar(pilaSimbolos, liberarLexema);
}

static int guardar_simbolo(char * simbolo)
{
    int posicion = Pila_ObtenerPosicion(pilaSimbolos, simbolo, comparar_cadena);

    if ( posicion == -1 ) {
        char * a_guardar = malloc(strlen(simbolo) + 1);
        strcpy(a_guardar, simbolo);
        Pila_Insertar(pilaSimbolos, a_guardar);
        return pilaSimbolos->tope;
    }

    return posicion; // posicion no es -1
}

static void guardar_token(char * secuencia, int posicion, enum clase_token clase)
{
    struct token * nuevo_token = malloc(sizeof(struct token));

    nuevo_token->clase = clase;

    if ( posicion == -1 ) {
        nuevo_token->lexema = malloc(strlen(secuencia) + 1);
        strcpy(nuevo_token->lexema, secuencia);
    } else {
        nuevo_token->numero_simbolo = posicion;
    }

    Pila_Insertar(pilaTokens, nuevo_token);
}

static void crear_tablas(void)
{
    FILE * archivo = NULL;

    // Creando la tabla de símbolos
    archivo = fopen(ARCHIVO_TABLA_SIMBOLOS, "w");

    if (archivo == NULL) {
        perror("Error");
        return;
    }

    for (int pos = 0; pos <= pilaSimbolos->tope; pos++) {
        fprintf(archivo, "%s\n",
                (char *) pilaSimbolos->elementos[pos]);
    }

    fclose(archivo);

    // Creando la tabla de tokens
    archivo = fopen(ARCHIVO_TABLA_TOKENS, "w");

    if ( archivo == NULL ) {
        perror("Error");
        return;
    }

    for (int pos = 0; pos <= (pilaTokens->tope); pos++) {
        struct token * actual = pilaTokens->elementos[pos];

        switch ( actual->clase ) {
            case PALABRA_RESERVADA:
            case IDENTIFICADOR:
            case NUMERO_ENTERO:
            case NUMERO_REAL:
            case CADENA:
            case CARACTER: {
                fprintf(archivo, "%d\t%d\n",
                        actual->clase, actual->numero_simbolo);
            } break;

            case OPERADOR_ARITMETICO:
            case OPERADOR_LOGICO:
            case OPERADOR_RELACIONAL:
            case OPERADOR_BIT_A_BIT:
            case OPERADOR_INCREMENTO:
            case OPERADOR_ASIGNACION:
            case SIMBOLO_ESPECIAL: {
                fprintf(archivo, "%d\t%s\n",
                        actual->clase, (char *)actual->lexema);
            } break;
        }
    }

    fclose(archivo);
}

static void recontar_lineas(char * comentario) {
    while ( strchr(comentario, '\n') != NULL ) {
        numero_lineas++;
        comentario = strchr(comentario, '\n') + 1;
    }
}

static int comparar_cadena(const void * cad1, const void * cad2)
{
    return strcmp(cad1, cad2);
}

static void liberarToken(void * token)
{
    struct token * t = token;

    switch ( t->clase ) {
        case OPERADOR_ARITMETICO:
        case OPERADOR_LOGICO:
        case OPERADOR_RELACIONAL:
        case OPERADOR_BIT_A_BIT:
        case OPERADOR_INCREMENTO:
        case OPERADOR_ASIGNACION:
        case SIMBOLO_ESPECIAL: {
            free(t->lexema);
        } break;

        default: /* No se hace nada si no se asigno memoria para una cadena */;
    }

    free(token);
}

static void liberarLexema(void * lexema)
{
    free(lexema);
}
