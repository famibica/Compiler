/* ***************************************************
   ******* Modificado por: ***************************
   ******* Felipe Einsfeld Kersting ******************
   ******* Pedro Sassen Veiga ************************
   ******* José Mário Reisswitz **********************
   *************************************************** */

#ifndef __MISC_H
#define __MISC_H
#include <stdio.h>
#include "cc_dict.h"
#include "cc_tree.h"
#include "string.h"

#define SIMBOLO_LITERAL_INT 1
#define SIMBOLO_LITERAL_FLOAT 2
#define SIMBOLO_LITERAL_CHAR 3
#define SIMBOLO_LITERAL_STRING 4
#define SIMBOLO_LITERAL_BOOL 5
#define SIMBOLO_IDENTIFICADOR 6

//int getLineNumber (void);
void yyerror (char const *mensagem);
void main_init (int argc, char **argv);
void main_finalize (void);
void append_type_to_lexem(char* lexem, int type);

int get_tipo(char* tipo);

extern int line_count;
extern comp_dict_t *dict;
extern comp_tree_t *ast;

typedef int bool;

typedef struct symbol_v
{
	union
	{
		int value_int;
		float value_float;
		char value_char;
		char* value_string;
		bool value_bool;
	};
	int tipo;
	int line;
	int tipo_primitivo;
} symbol_value;

symbol_value* create_symbol_value(int node_type, int type, int line);

#endif
