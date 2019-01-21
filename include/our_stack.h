#ifndef __STACK_H
#define __STACK_H
#include <stdlib.h>
#include "errors.h"
#include "cc_misc.h"

#define MEMBER_TYPE_VARIABLE 1
#define MEMBER_TYPE_FUNCTION 2
#define MEMBER_TYPE_VECTOR 3
#define MEMBER_TYPE_ARGUMENT 4

typedef struct stack_member
{
	char* id;
	int tipo;
	int lvl;
	int member_type;
	int type_parameters[64];
	int num_params;
	struct stack_member* next;
} stack_member_t;

stack_member_t* stack_create_member(char* id, int tipo, int lvl, int member_type)
{
	stack_member_t* result = (stack_member_t*)malloc(sizeof(stack_member_t));
	result->id = id;
	result->tipo = tipo;
	result->lvl = lvl;
	result->member_type = member_type;
	result->next = NULL;
	result->num_params = 0;	
	
	return result;
}


// retorna topo da pilha
stack_member_t* stack_push(stack_member_t* member, stack_member_t* topo)
{
	if(topo == NULL)
	{
		member->next = NULL;
		return member;
	}
	member->next = topo;
	return member;
}

// deleta todos membros do lvl atual, voltando ao lvl anterior
stack_member_t* stack_pop_prev_lvl(stack_member_t* topo, int current_lvl)
{
	stack_member_t* temp_topo;
	if (topo == NULL) return NULL;
	if (topo->lvl == 0) return topo;
	if(topo->lvl != (current_lvl + 1)) return topo;
	while (1)
	{
		if(topo->next == NULL)
		{
			temp_topo = topo;
			topo = topo->next;
			free(temp_topo);
			break;
		}
		else if(topo->lvl != topo->next->lvl)
		{
			temp_topo = topo;
			topo = topo->next;
			free(temp_topo);
			break;
		}

		temp_topo = topo;
		topo = topo->next;
		free(temp_topo);
	}
	return topo;
}

int stack_identifier_exists(stack_member_t* topo, char* id, int member_type, int* out_primitive_type)
{
	stack_member_t* temp_topo;
	temp_topo = topo;

	if (topo == NULL) return IKS_ERROR_UNDECLARED;
	
	while (temp_topo != NULL)
	{
		if (!strcmp(temp_topo->id, id))
		{	
			
			if (temp_topo->member_type != member_type)
			{
				switch(temp_topo->member_type)
				{
					case MEMBER_TYPE_VARIABLE:	return IKS_ERROR_VARIABLE;	break;
					case MEMBER_TYPE_FUNCTION:	return IKS_ERROR_FUNCTION;	break;
					case MEMBER_TYPE_VECTOR:	return IKS_ERROR_VECTOR;	break;	
					default:
						break;
				}
			}
			if(out_primitive_type)
				*out_primitive_type = temp_topo->tipo;
			return IKS_SUCCESS;
		}

		temp_topo = temp_topo->next;
	}
	
	return IKS_ERROR_UNDECLARED;
}

stack_member_t* get_stack_member_of_id(stack_member_t* topo, char* id)
{
	stack_member_t* temp_topo;
	temp_topo = topo;

	if (topo == NULL) return 0;
	
	while (temp_topo != NULL)
	{
		if (!strcmp(temp_topo->id, id))
		{	
			return temp_topo;
		}
		temp_topo = temp_topo->next;
	}
	return 0;
}

int get_stack_identifier_type(stack_member_t* topo, char* id)
{
	stack_member_t* temp_topo;
	temp_topo = topo;

	if (topo == NULL) return -1;
	
	while (temp_topo != NULL)
	{
		if (!strcmp(temp_topo->id, id))
			return temp_topo->tipo;

		temp_topo = temp_topo->next;
	}
	
	return -1;
}

int stack_identifier_exists_on_current_level(stack_member_t* topo, char* id, int lvl)
{
	stack_member_t* temp_topo;
	temp_topo = topo;
	
	if (topo == NULL) return IKS_SUCCESS;
	
	while (temp_topo != NULL)
	{
		if (temp_topo->lvl != lvl) break;
		if (!strcmp(temp_topo->id, id))
		{
			return IKS_ERROR_DECLARED;
		}
		
		temp_topo = temp_topo->next;
	}
	
	return IKS_SUCCESS;
}

int types_dont_coerce(int left, int right)
{
	if(right == SIMBOLO_LITERAL_STRING && left != SIMBOLO_LITERAL_STRING)
		return IKS_ERROR_STRING_TO_X;
	if(right == SIMBOLO_LITERAL_CHAR && left != SIMBOLO_LITERAL_CHAR)
		return IKS_ERROR_CHAR_TO_X;
	if (right != left)
		return IKS_ERROR_WRONG_TYPE;
	
	return 0;
}

stack_member_t* find_first_function(stack_member_t* topo, int lvl)
{
	stack_member_t* temp_topo = topo;
	while(temp_topo->lvl == lvl)
		temp_topo = temp_topo->next;
	
	return temp_topo;
}

void give_error(int error)
{
	
	switch(error)
	{
		case IKS_ERROR_VARIABLE: 		yyerror("Identifier must be used as variable."); break;
		case IKS_ERROR_FUNCTION: 		yyerror("Identifier must be used as function."); break;
		case IKS_ERROR_VECTOR:			yyerror("Identifier must be used as vector."); break;
		case IKS_ERROR_UNDECLARED: 		yyerror("Undeclared identifier."); break;
		case IKS_ERROR_DECLARED:		yyerror("Identifier already declared."); break;
		case IKS_ERROR_STRING_TO_X:		yyerror("Incorrect string coercion."); break;
		case IKS_ERROR_CHAR_TO_X:		yyerror("Incorrect char coercion."); break;
		case IKS_ERROR_MISSING_ARGS:	yyerror("Function call missing arguments."); break;
		case IKS_ERROR_EXCESS_ARGS:		yyerror("Function call excess of arguments."); break;
		case IKS_ERROR_WRONG_TYPE_ARGS:	yyerror("Function call wrong type arguments."); break;
		case IKS_ERROR_WRONG_PAR_RETURN: yyerror("Function returns wrong type."); break;
	}
}

#endif