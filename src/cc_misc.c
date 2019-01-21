/* ***************************************************
   ******* Modificado por: ***************************
   ******* Felipe Einsfeld Kersting ******************
   ******* Pedro Sassen Veiga ************************
   ******* José Mário Reisswitz **********************
   *************************************************** */

#include "cc_misc.h"
#include "cc_tree.h"
#include <string.h>


comp_dict_t *dict;
comp_tree_t *ast;

symbol_value* normal_nodes[1024] = {0};
static int normal_nodes_count = 0;
	
symbol_value* create_symbol_value(int node_type, int type, int line) 
{
	symbol_value* sv = 0;// (symbol_value*)malloc(sizeof(symbol_value));	
	sv->value_int = node_type;
	sv->tipo = type;
	sv->line = 0;
	normal_nodes[normal_nodes_count++] =  sv;
	return sv;
}

void symbols_free()
{
	for(int i = 0; normal_nodes[i] != 0; ++i)
		free(normal_nodes[i]);
}

int get_tipo(char* tipo)
{
	int comp = 0;
	comp = strcmp(tipo, "int");
	if(!comp)
		return SIMBOLO_LITERAL_INT;
	comp = strcmp(tipo, "float");
	if(!comp)
		return SIMBOLO_LITERAL_FLOAT;
	comp = strcmp(tipo, "char");
	if(!comp)
		return SIMBOLO_LITERAL_CHAR;
	comp = strcmp(tipo, "string");
	if(!comp)
		return SIMBOLO_LITERAL_STRING;
	comp = strcmp(tipo, "bool");
	if(!comp)
		return SIMBOLO_LITERAL_BOOL;
	return 0;
}

int comp_get_line_number (void)
{
  return line_count;
}

void yyerror (char const *mensagem)
{
  fprintf (stderr, "%s\nline: %d\n", mensagem, comp_get_line_number()); //altere para que apareça a linha
}
	
void main_init (int argc, char **argv)
{
  dict = dict_new();
  ast = tree_new();
}

void main_finalize (void)
{
  symbol_value* tmp_value;
  int i = 0;

  //comp_print_table();
	

  for (i=0; i<dict->size; i++)
  {
    while(dict->data[i])
    {
       tmp_value = (symbol_value*)dict->data[i]->value;
       
       if(tmp_value->tipo == SIMBOLO_LITERAL_STRING || tmp_value->tipo == SIMBOLO_IDENTIFICADOR)
	{
		free(tmp_value->value_string);
	}

       free(tmp_value);
       dict_remove(dict, dict->data[i]->key); 
    }
  }
  dict_free(dict);
  symbols_free();
  //tree_print_s(ast, stderr);
  //tree_free(ast);

}

void comp_print_table (void)
{
  int i, l, strlen_dict;
  char buffer[2048];
  for (i = 0, l = dict->size; i < l; ++i) {
    if (dict->data[i]) {
      strlen_dict = strlen(dict->data[i]->key);
      strcpy(buffer, dict->data[i]->key);
      buffer[strlen_dict-2] = 0;
      symbol_value* tmp_value = (symbol_value*)dict->data[i]->value;
      cc_dict_etapa_2_print_entrada(buffer, tmp_value->line, (int)(buffer[strlen_dict-1] - 0x30));
      //cc_dict_etapa_2_print_entrada(dict->data[i]->key, line_count, 0);
    }
  }
}

void remove_single_quotes(char* text)
{
  text[0] = text[1];
  text[1] = 0;
}

void remove_double_quotes(char* text)
{
  int length, i;

  length = strlen(text);

  for (i=0; i<(length-1); i++)
  {
     text[i] = text[i+1];
  }

  text[length-2] = 0;
}

void append_type_to_lexem(char* lexem, int type)
{
	int length, i;
	length = strlen(lexem);

	lexem[length] = '_';
	lexem[length+1] = type+0x30;
	lexem[length+2] = 0;
}
