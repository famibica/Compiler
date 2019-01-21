/* ***************************************************
   ******* Modificado por: ***************************
   ******* Felipe Einsfeld Kersting ******************
   ******* Pedro Sassen Veiga ************************
   ******* Matheus Claudino Bica *********************
   *************************************************** */
%{
#include <stdio.h>
#include <string.h>
#include "cc_misc.h"
#include "cc_ast.h"
#include "our_stack.h"

#define NODE_STR_VAL(x) (((symbol_value*)x)->value_string)
#define NODE_INT_VAL(x) (((symbol_value*)x)->value_int)
#define NODE_TYPE_VAL(x) (((symbol_value*)x->value)->tipo)
#define NODE_PRIMTYPE_VAL(x) (((symbol_value*)x->value)->tipo_primitivo)
	
extern comp_tree_t* ast;
extern comp_dict_t *dict;
extern comp_tree_t* comp_tree_last;
	
static stack_member_t* stack = NULL;
static int lvl = 0;
	
static int type_arg_list[64] = {0};
static int arg_list_count = 0;

comp_tree_t* programa = NULL;
comp_tree_t* last_node = NULL;
comp_tree_t* first_func = NULL;
comp_tree_t* last_cmd[512] = {};
comp_tree_t* last_exp[512] = {};

symbol_value programa_symbol = {AST_PROGRAMA, 0, 0};
symbol_value equal_symbol = {AST_ATRIBUICAO, 0, 0};
symbol_value ifelse_symbol = {AST_IF_ELSE, 0, 0};
symbol_value block_symbol = {AST_BLOCO, 0, 0};
symbol_value break_symbol = {AST_BREAK, 0, 0};
symbol_value return_symbol = {AST_RETURN, 0, 0};
symbol_value continue_symbol = {AST_CONTINUE, 0, 0};
symbol_value input_symbol = {AST_INPUT, 0, 0};
	
symbol_value sum_symbol = {AST_ARIM_SOMA, 0, 0};
symbol_value sub_symbol = {AST_ARIM_SUBTRACAO, 0, 0};
symbol_value mul_symbol = {AST_ARIM_MULTIPLICACAO, 0, 0};
symbol_value div_symbol = {AST_ARIM_DIVISAO, 0, 0};
	
symbol_value inv_symbol = {AST_ARIM_INVERSAO, 0, 0};
	
symbol_value and_symbol = {AST_LOGICO_E, 0, 0};
symbol_value or_symbol = {AST_LOGICO_OU, 0, 0};
symbol_value dif_symbol = {AST_LOGICO_COMP_DIF, 0, 0};
symbol_value eq_symbol = {AST_LOGICO_COMP_IGUAL, 0, 0};
symbol_value leq_symbol = {AST_LOGICO_COMP_LE, 0, 0};
symbol_value geq_symbol = {AST_LOGICO_COMP_GE, 0, 0};
symbol_value les_symbol = {AST_LOGICO_COMP_L, 0, 0};
symbol_value grt_symbol = {AST_LOGICO_COMP_G, 0, 0};

symbol_value dowhile_symbol = {AST_DO_WHILE, 0, 0};
symbol_value whiledo_symbol = {AST_WHILE_DO, 0, 0};
	
symbol_value not_symbol = {AST_LOGICO_COMP_NEGACAO, 0, 0};
symbol_value vector_symbol = {AST_VETOR_INDEXADO, 0, 0};
	
symbol_value call_symbol = {AST_CHAMADA_DE_FUNCAO, 0, 0};

symbol_value output_symbol = {AST_OUTPUT, 0, 0};
	
symbol_value shift_left_symbol = {AST_SHIFT_LEFT, 0, 0};
symbol_value shift_right_symbol = {AST_SHIFT_RIGHT, 0, 0};

#define check_exist_this_lvl(str_val_id, lvl, tipo, typemember) 	\
	int error;	\
	if (error = stack_identifier_exists_on_current_level(stack, str_val_id, lvl))	\
	{	\
		give_error(error);	\
		return error;	\
	}	\
	stack_member_t* temp = stack_create_member(str_val_id, tipo, lvl, typemember);	\
	stack = stack_push(temp, stack) \
	
#define check_exists(str_val_id, typemember, out_prim_type) 	\
	int error;	\
	if (error = stack_identifier_exists(stack, str_val_id, typemember, out_prim_type))	\
	{	\
		give_error(error);	\
		return error;	\
	}	\
	
%}

/* Declaração dos tokens da linguagem */
%token TK_PR_INT
%token TK_PR_FLOAT
%token TK_PR_BOOL
%token TK_PR_CHAR
%token TK_PR_STRING
%token TK_PR_IF
%token TK_PR_THEN
%token TK_PR_ELSE
%token TK_PR_WHILE
%token TK_PR_DO
%token TK_PR_INPUT
%token TK_PR_OUTPUT
%token TK_PR_RETURN
%token TK_PR_CONST
%token TK_PR_STATIC
%token TK_PR_FOREACH
%token TK_PR_FOR
%token TK_PR_SWITCH
%token TK_PR_CASE
%token TK_PR_BREAK
%token TK_PR_CONTINUE
%token TK_PR_CLASS
%token TK_PR_PRIVATE
%token TK_PR_PUBLIC
%token TK_PR_PROTECTED
%token TK_OC_LE
%token TK_OC_GE
%token TK_OC_EQ
%token TK_OC_NE
%token TK_OC_AND
%token TK_OC_OR
%token TK_OC_SL
%token TK_OC_SR
%token<ptr> TK_LIT_INT
%token<ptr> TK_LIT_FLOAT
%token<ptr> TK_LIT_FALSE
%token<ptr> TK_LIT_TRUE
%token<ptr> TK_LIT_CHAR
%token<ptr> TK_LIT_STRING
%token<ptr> TK_IDENTIFICADOR
%token TOKEN_ERRO

%type<node> tipo_variavel
%type<it> literal
%type<node> comando
%type<node> expressao
%type<node> lista_declaracoes
%type<node> declaracao_funcao
%type<node> declaracao
%type<node> bloco_de_comandos
%type<node> lista_comandos
%type<node> comando_if
%type<node> comando_nao_vazio
%type<node> atribuicao_var_primitivas
%type<node> comando_entrada
%type<node> variavel_global

%type<node> parametro
%type<node> lista_parametros
%type<ptr> chamada_de_funcao
%type<node> lista_expressoes
%type<node> comando_saida
%type<node> comando_shift

%union 
{
	char *str;
	char ch;
	float fl;
	int it;
	struct comp_tree* node;
	struct symbol_v* ptr;
}

%nonassoc TK_PR_THEN
%nonassoc TK_PR_ELSE

%left '+' '-'
%left '*' '/'
%right TK_OC_AND TK_OC_OR
%left TK_OC_LE TK_OC_GE TK_OC_EQ TK_OC_NE '<' '>'
%left '!'

%%
/* Regras (e ações) da gramática */

programa:
| lista_declaracoes 
{
	if(first_func)
	{
		programa = tree_make_node(&programa_symbol);
		tree_insert_node(ast, programa);
		tree_insert_node(programa, first_func);
	}
}
;

lista_declaracoes:
lista_declaracoes declaracao	{ $$ = $1; }
| declaracao					{ $$ = $1; }
;

declaracao:
  variavel_global
| declaracao_tipo
| declaracao_funcao		{ $$ = $1; }
;

/* Regras para funcoes */

declaracao_funcao: tipo_variavel TK_IDENTIFICADOR 
{
	check_exist_this_lvl(NODE_STR_VAL($2), lvl, get_tipo($1), MEMBER_TYPE_FUNCTION);
}
'(' lista_parametros ')' bloco_de_comandos
{
	if(first_func == NULL)
	{
		if($7)
			last_node = tree_make_unary_node($2, $7);
		else
			last_node = tree_make_node($2);

		first_func = last_node;
	}
	else
	{
		comp_tree_t* temp = NULL;
		if($7)
			temp = tree_make_unary_node($2, $7);
		else
			temp =  tree_make_node($2);
		
		tree_insert_node(last_node, temp);
		last_node = temp;
	}
} 
| TK_PR_STATIC tipo_variavel TK_IDENTIFICADOR '(' lista_parametros ')'
{
	check_exist_this_lvl(NODE_STR_VAL($3), lvl, get_tipo($2), MEMBER_TYPE_FUNCTION);
}	
bloco_de_comandos
{
	if(first_func == NULL)
	{
		if($8)
			last_node = tree_make_unary_node($3, $8);
		else
			last_node = tree_make_node($3);

		first_func = last_node;
	}
	else
	{
		comp_tree_t* temp = NULL;
		if($8)
			temp = tree_make_unary_node($3, $8);
		else
			temp =  tree_make_node($3);
		
		tree_insert_node(last_node, temp);
		last_node = temp;
	}
}
;
	
lista_parametros:
| parametro	
| lista_parametros ',' parametro
;

parametro:
  tipo_variavel TK_IDENTIFICADOR						{ stack_member_t* temp = stack_create_member(NODE_STR_VAL($2), get_tipo($1), lvl + 1, MEMBER_TYPE_ARGUMENT); stack = stack_push(temp, stack); 
														 stack_member_t* last_func = find_first_function(stack, lvl + 1);
														  last_func->type_parameters[last_func->num_params++] = get_tipo($1);
														}
| TK_PR_CONST tipo_variavel TK_IDENTIFICADOR
| TK_IDENTIFICADOR TK_IDENTIFICADOR
| TK_PR_CONST TK_IDENTIFICADOR TK_IDENTIFICADOR
| error 												{ yyerror("Invalid parameter\n"); return 1; }
;
	
/* Regras para variavel global */
tipo_variavel: 
  TK_PR_INT					{ $$ = "int"; }
| TK_PR_FLOAT				{ $$ = "float"; }
| TK_PR_CHAR				{ $$ = "char"; }
| TK_PR_STRING				{ $$ = "string"; }
| TK_PR_BOOL				{ $$ = "bool"; }
;

variavel_global:
  tipo_variavel TK_IDENTIFICADOR ';'									{ check_exist_this_lvl(NODE_STR_VAL($2), lvl, get_tipo($1), MEMBER_TYPE_VARIABLE); }
| TK_IDENTIFICADOR TK_IDENTIFICADOR ';'
| TK_PR_STATIC tipo_variavel TK_IDENTIFICADOR ';'						{ check_exist_this_lvl(NODE_STR_VAL($3), lvl, get_tipo($2), MEMBER_TYPE_VARIABLE); }
| TK_PR_STATIC TK_IDENTIFICADOR TK_IDENTIFICADOR ';'
| TK_IDENTIFICADOR TK_IDENTIFICADOR '[' expressao ']' ';'
| tipo_variavel TK_IDENTIFICADOR '[' expressao ']' ';'					{ check_exist_this_lvl(NODE_STR_VAL($2), lvl, get_tipo($1), MEMBER_TYPE_VECTOR); }
| TK_PR_STATIC tipo_variavel TK_IDENTIFICADOR '[' expressao ']' ';'		{ check_exist_this_lvl(NODE_STR_VAL($3), lvl, get_tipo($2), MEMBER_TYPE_VECTOR); }

| error { yyerror("Invalid global variable declaration\n"); return 1; }
;


/* Regras para declaracao de classe */

declaracao_tipo: TK_PR_CLASS TK_IDENTIFICADOR '[' lista_campos ']'';' {  }
;

lista_campos: 
| encapsulamento tipo_variavel TK_IDENTIFICADOR separador_decl
;

encapsulamento: TK_PR_PRIVATE
| TK_PR_PUBLIC
| TK_PR_PROTECTED
| error { yyerror("Invalid access modifier\n"); return 1; }
;

separador_decl: 
| ':' lista_campos
;

/* Regras para comandos */

lista_comandos_virgula:
lista_comandos_virgula ',' comando
| comando
;

lista_comandos:
  comando	{ $$ = $1; }
| lista_comandos ';' comando
{
	if($1)
	{
		if($3)
		{
			if(last_cmd[lvl])
				tree_insert_node(last_cmd[lvl], $3);
			else
				tree_insert_node($1, $3);
			last_cmd[lvl] = $3;
		}
		$$ = $1;
	}
	else
	{
		$$ = $3;
	}
}
;

bloco_de_comandos: 
'{' { lvl++; } lista_comandos '}'				{ $$ = $3; last_cmd[lvl] = 0; lvl--; stack = stack_pop_prev_lvl(stack, lvl); }
;

comando: 			{ $$ = NULL;}
| comando_nao_vazio	{ $$ = $1; }
;

comando_nao_vazio:
 bloco_de_comandos
{
	if($1)
		$$ = tree_make_unary_node(&block_symbol, $1);
	else
		$$ = tree_make_node(&block_symbol);
}
| decl_var_local																							{ $$ = NULL; }
| atribuicao_var_primitivas 																				{ $$ = $1; }
| atribuicao_var_usuario	// default
| comando_entrada			// default
| comando_saida
| chamada_de_funcao																							{ $$ = $1; }
| comando_shift
| TK_PR_RETURN expressao																					
{
	if (NODE_PRIMTYPE_VAL($2) != find_first_function(stack, lvl)->tipo)
	{
		give_error(IKS_ERROR_WRONG_PAR_RETURN);
		return IKS_ERROR_WRONG_PAR_RETURN;
	}
	
	$$ = tree_make_unary_node(&return_symbol, $2);
}
| TK_PR_BREAK																								{ $$ = tree_make_node(&break_symbol); }
| TK_PR_CONTINUE																							{ $$ = tree_make_node(&continue_symbol); }
| TK_PR_CASE TK_LIT_INT ':'
| TK_PR_FOREACH '(' TK_IDENTIFICADOR ':' lista_expressoes ')' comando_nao_vazio
| TK_PR_FOR '(' lista_comandos_virgula ':' expressao ':' lista_comandos_virgula ')' comando_nao_vazio
| TK_PR_WHILE '(' expressao ')' TK_PR_DO comando_nao_vazio ';'												{ $$ = tree_make_binary_node(&whiledo_symbol, $3, $6); }
| TK_PR_DO comando_nao_vazio ';' TK_PR_WHILE '(' expressao ')'												{ $$ = tree_make_binary_node(&dowhile_symbol, $2, $6); }
| TK_PR_DO comando_nao_vazio TK_PR_WHILE '(' expressao ')'
| TK_PR_SWITCH '(' expressao ')' comando_nao_vazio
| comando_if
| error 																									{ yyerror("Invalid command\n"); return 1; }
;

/* Regras para variaveis locais */

literal: 
  TK_LIT_INT 		{ $$ = tree_make_node($1); }
| TK_LIT_FLOAT 		{ $$ = tree_make_node($1); }
| TK_LIT_FALSE 		{ $$ = tree_make_node($1); }
| TK_LIT_TRUE 		{ $$ = tree_make_node($1); }
| TK_LIT_CHAR 		{ $$ = tree_make_node($1); }
| TK_LIT_STRING 	{ $$ = tree_make_node($1); }
| error 			{ yyerror("Invalid literal\n"); return 1;}
;

decl_var_local: 
  TK_PR_STATIC TK_PR_CONST tipo_variavel TK_IDENTIFICADOR								{ check_exist_this_lvl(NODE_STR_VAL($4), lvl, get_tipo($3), MEMBER_TYPE_VARIABLE); }
| TK_PR_STATIC tipo_variavel TK_IDENTIFICADOR											{ check_exist_this_lvl(NODE_STR_VAL($3), lvl, get_tipo($2), MEMBER_TYPE_VARIABLE); }
| TK_PR_CONST tipo_variavel TK_IDENTIFICADOR											{ check_exist_this_lvl(NODE_STR_VAL($3), lvl, get_tipo($2), MEMBER_TYPE_VARIABLE); }
| tipo_variavel TK_IDENTIFICADOR														{ check_exist_this_lvl(NODE_STR_VAL($2), lvl, get_tipo($1), MEMBER_TYPE_VARIABLE); }										
| TK_PR_STATIC TK_PR_CONST tipo_variavel TK_IDENTIFICADOR TK_OC_LE literal
| TK_PR_STATIC tipo_variavel TK_IDENTIFICADOR TK_OC_LE literal
| TK_PR_CONST tipo_variavel TK_IDENTIFICADOR TK_OC_LE literal
| tipo_variavel TK_IDENTIFICADOR TK_OC_LE literal

| TK_PR_STATIC TK_PR_CONST TK_IDENTIFICADOR TK_IDENTIFICADOR
| TK_PR_STATIC TK_IDENTIFICADOR TK_IDENTIFICADOR
| TK_PR_CONST TK_IDENTIFICADOR TK_IDENTIFICADOR
| TK_IDENTIFICADOR TK_IDENTIFICADOR

;

lista_expressoes:
  expressao									{ type_arg_list[arg_list_count++] = NODE_PRIMTYPE_VAL($1); }
| lista_expressoes ',' expressao 			{ type_arg_list[arg_list_count++] = NODE_PRIMTYPE_VAL($3); }
{
	if($1)
	{
		if($3)
		{
			if(last_exp[lvl])
				tree_insert_node(last_exp[lvl], $3);
			else
				tree_insert_node($1, $3);
			last_exp[lvl] = $3;	
		}
		$$ = $1;
	}
	else
	{
		$$ = $3;
	}
};
;

/* Regras para comando de atribuicao */

atribuicao_var_primitivas: TK_IDENTIFICADOR '=' expressao
{ 
	$$ = tree_make_binary_node(&equal_symbol, tree_make_node($1), $3); 
	int id_primitive_type = 0;
	check_exists(NODE_STR_VAL($1), MEMBER_TYPE_VARIABLE, &id_primitive_type)	// note: no ';'
		
	int coercion_error = types_dont_coerce(id_primitive_type, NODE_PRIMTYPE_VAL($3));
	if(coercion_error)
	{
		give_error(coercion_error);
		return coercion_error;
	}
	
}
| TK_IDENTIFICADOR '[' expressao ']' '=' expressao
{ 
	$$ = tree_make_binary_node(&equal_symbol, tree_make_binary_node(&vector_symbol, tree_make_node($1), $3), $6);
	int id_primitive_type = 0;
	check_exists(NODE_STR_VAL($1), MEMBER_TYPE_VECTOR, &id_primitive_type)		// note: no ';'
	
	if (NODE_PRIMTYPE_VAL($3) == SIMBOLO_LITERAL_STRING)
	{
		give_error(IKS_ERROR_STRING_TO_X);
		return IKS_ERROR_STRING_TO_X;
	}
	if (NODE_PRIMTYPE_VAL($3) == SIMBOLO_LITERAL_CHAR)
	{
		give_error(IKS_ERROR_CHAR_TO_X);
		return IKS_ERROR_CHAR_TO_X;
	}
}
;

atribuicao_var_usuario:
  TK_IDENTIFICADOR '!' TK_IDENTIFICADOR '=' expressao
;

/* Regras para comandos de entrada e saida */

comando_entrada:
TK_PR_INPUT expressao						{ $$ = tree_make_unary_node(&input_symbol, $2); }
;

comando_saida:
TK_PR_OUTPUT lista_expressoes				{ $$ = tree_make_unary_node(&output_symbol, $2); }
;

/* Regras para chamada de função */
	
chamada_de_funcao:
TK_IDENTIFICADOR '(' lista_expressoes ')'			{ $$ = tree_make_binary_node(&call_symbol, tree_make_node($1), $3);
											 			check_exists(NODE_STR_VAL($1), MEMBER_TYPE_FUNCTION, NULL)	// note: no ';'
														// verificar se o numero de parametros está correto
													 	stack_member_t* func_used = get_stack_member_of_id(stack, NODE_STR_VAL($1));
													 	if(arg_list_count < func_used->num_params)
														{
															give_error(IKS_ERROR_MISSING_ARGS);
															return IKS_ERROR_MISSING_ARGS;
														}
													 	if(arg_list_count > func_used->num_params)
														{
															give_error(IKS_ERROR_EXCESS_ARGS);
															return IKS_ERROR_EXCESS_ARGS;
														}
													 	for (int i=0; i<arg_list_count; ++i)
															if (func_used->type_parameters[i] != type_arg_list[i])
															{
																give_error(IKS_ERROR_WRONG_TYPE_ARGS);
																return IKS_ERROR_WRONG_TYPE_ARGS;
															}
													 	arg_list_count = 0;
													}
| TK_IDENTIFICADOR '(' ')'							{ $$ = tree_make_unary_node(&call_symbol, tree_make_node($1));
											 			check_exists(NODE_STR_VAL($1), MEMBER_TYPE_FUNCTION, NULL)	// note: no ';'
															
														stack_member_t* func_used = get_stack_member_of_id(stack, NODE_STR_VAL($1));

														if(0 != func_used->num_params)
														{
															give_error(IKS_ERROR_MISSING_ARGS);
															return IKS_ERROR_MISSING_ARGS;
														}
													 	arg_list_count = 0;
													}
;

/* Regras para shift */

comando_shift:
TK_IDENTIFICADOR TK_OC_SL TK_LIT_INT		{$$ = tree_make_binary_node(&shift_left_symbol, tree_make_node($1), tree_make_node($3)); }
| TK_IDENTIFICADOR TK_OC_SR TK_LIT_INT		{$$ = tree_make_binary_node(&shift_right_symbol, tree_make_node($1), tree_make_node($3)); }
;

/* Comandos de controle de fluxo */

comando_if:
  TK_PR_IF '(' expressao ')' TK_PR_THEN comando_nao_vazio ';'
{
	$$ = tree_make_binary_node(&ifelse_symbol, $3, $6);
}
| TK_PR_IF '(' expressao ')' TK_PR_THEN comando_nao_vazio ';'  TK_PR_ELSE comando_nao_vazio ';'
{
	$$ = tree_make_ternary_node(&ifelse_symbol, $3, $6, $9);
}
;

/* Expressões aritmeticas e lógicas */
expressao:  
  '!' expressao						{ $$ = tree_make_unary_node(&not_symbol, $2); }
|  expressao '+' expressao 			{ $$ = tree_make_binary_node(&sum_symbol, $1, $3); }
| expressao '-' expressao			{ $$ = tree_make_binary_node(&sub_symbol, $1, $3); }
| expressao '*' expressao			{ $$ = tree_make_binary_node(&mul_symbol, $1, $3); }
| expressao '/' expressao			{ $$ = tree_make_binary_node(&div_symbol, $1, $3); }
| expressao TK_OC_LE expressao		{ $$ = tree_make_binary_node(&leq_symbol, $1, $3); }
| expressao TK_OC_GE expressao		{ $$ = tree_make_binary_node(&geq_symbol, $1, $3); }
| expressao TK_OC_EQ expressao		{ $$ = tree_make_binary_node(&eq_symbol, $1, $3); }
| expressao TK_OC_NE expressao		{ $$ = tree_make_binary_node(&dif_symbol, $1, $3); }
| expressao TK_OC_OR expressao		{ $$ = tree_make_binary_node(&or_symbol, $1, $3); }
| expressao TK_OC_AND expressao		{ $$ = tree_make_binary_node(&and_symbol, $1, $3); }
| expressao '<' expressao			{ $$ = tree_make_binary_node(&les_symbol, $1, $3); }
| expressao '>' expressao			{ $$ = tree_make_binary_node(&grt_symbol, $1, $3); }
| literal							{ $$ = $1; }
| TK_IDENTIFICADOR					{ $$ = tree_make_node($1); $1->tipo_primitivo = get_stack_identifier_type(stack, NODE_STR_VAL($1)); }
| '(' expressao ')'					{ $$ = $2; }
| chamada_de_funcao					{ $$ = $1; }
| TK_IDENTIFICADOR '[' expressao ']' {$$ = tree_make_binary_node(&vector_symbol, tree_make_node($1), $3);}
| '-' expressao						{ $$ = tree_make_unary_node(&inv_symbol, $2); }
;


%%
