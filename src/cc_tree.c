// Copyright (c) 2016 Lucas Nodari 
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <stdio.h>
#include <stdlib.h>

#include "cc_tree.h"
#include "cc_misc.h"
#include "cc_ast.h"

extern FILE *intfp;
void *comp_tree_last = NULL;

void* tree_nodes[2048] = {0};
int tree_node_counter = 0;

#define ERRO(MENSAGEM) { fprintf (stderr, "[cc_tree, %s] %s.\n", __FUNCTION__, MENSAGEM); abort(); }

comp_tree_t* tree_new(void){
	comp_tree_t *tree = tree_make_node(NULL);
	return tree;
}

void tree_free(comp_tree_t *tree){
	int i = 0;
	for(i = 0; tree_nodes[i] != 0; ++i)
		free(tree_nodes[i]);
	tree_node_counter = 0;
}

comp_tree_t* tree_make_node(void *value){	
	comp_tree_t *node = malloc(sizeof(comp_tree_t));
	
	tree_nodes[tree_node_counter] = node;
	tree_node_counter++;
	
	if (!node)
		ERRO("Failed to allocate memory for tree node");

	node->value = value;
	node->childnodes = 0;
	node->first = NULL;
	node->last = NULL;
	node->next = NULL;
	node->prev = NULL;
	return node;
}

void tree_insert_node(comp_tree_t *tree, comp_tree_t *node){
	
	if (tree == NULL)
		ERRO("Cannot insert node, tree is null");
	if (node == NULL)
		ERRO("Cannot insert node, node is null");

	if (tree_has_child_nodes(tree)){
		tree->first = node;
		tree->last = node;
	} else {
		node->prev = tree->last;
		tree->last->next = node;
		tree->last = node;
	}
	++tree->childnodes;
	comp_tree_last = tree;
}

int tree_has_child_nodes(comp_tree_t *tree){
	if (tree != NULL){
		if (tree->childnodes == 0)
			return 1;
	}
	return 0;
}

comp_tree_t* tree_make_unary_node(void *value, comp_tree_t *node){
	comp_tree_t *newnode = tree_make_node(value);
	tree_insert_node(newnode,node);
	return newnode;
}

comp_tree_t* tree_make_binary_node(void *value, comp_tree_t *node1, comp_tree_t *node2){
	comp_tree_t *newnode = tree_make_node(value);
	tree_insert_node(newnode,node1);
	tree_insert_node(newnode,node2);
	return newnode;
}

comp_tree_t* tree_make_ternary_node(void *value, comp_tree_t *node1, comp_tree_t *node2, comp_tree_t *node3){
	comp_tree_t *newnode = tree_make_node(value);
	tree_insert_node(newnode,node1);
	tree_insert_node(newnode,node2);
	tree_insert_node(newnode,node3);
	return newnode;
}

static void print_spaces(int num){
	while (num-->0)
		putc(' ',stdout);
}

static void tree_debug_print_node(comp_tree_t *tree, int spacing){
	if (tree == NULL) return;
	print_spaces(spacing);
	printf("%p(%d): %s\n",tree,tree->childnodes,tree->value);
}

static void tree_debug_print_s(comp_tree_t *tree, int spacing){
	if (tree == NULL) return;

	comp_tree_t *ptr = tree;
	do {
		tree_debug_print_node(ptr,spacing);
		if (ptr->first != NULL)
			tree_debug_print_s(ptr->first,spacing+1);
		ptr = ptr->next;
	} while(ptr != NULL);
}

void tree_debug_print(comp_tree_t *tree){
	tree_debug_print_s(tree,0);
}

void tree_print_node(comp_tree_t *tree, FILE* file) {
	symbol_value* tv = (symbol_value*)tree->value;

	if (tree == NULL) return;
	if(!tree->value)
		fprintf(file, "node_%p [label=\"%s\"]\n", tree, "root");
	else
	{
		if(tv->tipo == 0)
		{
			fprintf(file, "node_%p [label=", tree);
			switch(tv->value_int)
			{
				case AST_PROGRAMA: 		fprintf(file, "\"%s\"", "programa"); break;
				case AST_ATRIBUICAO: 	fprintf(file, "\"%s\"", "="); break;
				case AST_IF_ELSE:		fprintf(file, "\"%s\"", "ifelse"); break;
				case AST_BLOCO:			fprintf(file, "\"%s\"", "block"); break;
				case AST_BREAK:			fprintf(file, "\"%s\"", "break"); break;
				case AST_RETURN:		fprintf(file, "\"%s\"", "return"); break;
				case AST_CONTINUE:		fprintf(file, "\"%s\"", "continue"); break;
				case AST_INPUT:			fprintf(file, "\"%s\"", "input"); break;
					
				case AST_ARIM_SOMA:				fprintf(file, "\"%s\"", "+"); break;
				case AST_ARIM_SUBTRACAO:		fprintf(file, "\"%s\"", "-"); break;
				case AST_ARIM_MULTIPLICACAO:	fprintf(file, "\"%s\"", "*"); break;
				case AST_ARIM_DIVISAO:			fprintf(file, "\"%s\"", "/"); break;
					
				case AST_ARIM_INVERSAO:			fprintf(file, "\"%s\"", "-"); break;
					
				case AST_LOGICO_E:				fprintf(file, "\"%s\"", "&&"); break;
				case AST_LOGICO_OU:				fprintf(file, "\"%s\"", "||"); break;
				case AST_LOGICO_COMP_DIF:		fprintf(file, "\"%s\"", "!="); break;
				case AST_LOGICO_COMP_IGUAL:		fprintf(file, "\"%s\"", "=="); break;
				case AST_LOGICO_COMP_LE:		fprintf(file, "\"%s\"", "<="); break;
				case AST_LOGICO_COMP_GE:		fprintf(file, "\"%s\"", ">="); break;
				case AST_LOGICO_COMP_L:			fprintf(file, "\"%s\"", "<"); break;
				case AST_LOGICO_COMP_G:			fprintf(file, "\"%s\"", ">"); break;
					
				case AST_DO_WHILE:				fprintf(file, "\"%s\"", "dowhile"); break;
				case AST_WHILE_DO:				fprintf(file, "\"%s\"", "whiledo"); break;
					
				case AST_LOGICO_COMP_NEGACAO:	fprintf(file, "\"%s\"", "!"); break;
					
				case AST_VETOR_INDEXADO:		fprintf(file, "\"%s\"", "[]"); break;
					
				case AST_CHAMADA_DE_FUNCAO:		fprintf(file, "\"%s\"", "call"); break;
					
				case AST_OUTPUT:				fprintf(file, "\"%s\"", "output"); break;
					
				case AST_SHIFT_LEFT: 			fprintf(file, "\"%s\"", "<<"); break;
				case AST_SHIFT_RIGHT: 			fprintf(file, "\"%s\"", ">>"); break;
			}
			fprintf(file, "]\n");
		}
		else
		{
			switch(tv->tipo)
			{
				case SIMBOLO_LITERAL_INT: 	fprintf(file, "node_%p [label=\"%d\"]\n", tree, tv->value_int); break;
				case SIMBOLO_LITERAL_FLOAT: 	fprintf(file, "node_%p [label=\"%f\"]\n", tree, tv->value_float); break;
				case SIMBOLO_LITERAL_CHAR: 	fprintf(file, "node_%p [label=\"%c\"]\n", tree, tv->value_char); break;
				case SIMBOLO_LITERAL_STRING: 	fprintf(file, "node_%p [label=\"%s\"]\n", tree, tv->value_string); break;
				case SIMBOLO_LITERAL_BOOL: 
					if(tv->value_int != 0)
						fprintf(file, "node_%p [label=\"true\"]\n", tree); 
					else
						fprintf(file, "node_%p [label=\"false\"]\n", tree); 
				break;
				case SIMBOLO_IDENTIFICADOR: 	fprintf(file, "node_%p [label=\"%s\"]\n", tree, tv->value_string); break;
			}
		}
	}
}

void tree_print_s(comp_tree_t *tree, FILE* file) {
	if (tree == NULL) return;

	comp_tree_t *ptr = tree;
	
	tree_print_node(ptr, file);
	switch (ptr->childnodes)
	{
		case 0: return;
		case 1: {
			if (ptr->first != NULL)
				tree_print_s(ptr->first, file);
			fprintf(file, "node_%p -> node_%p\n", ptr, ptr->first);
		}break;
		case 2: {
			if (ptr->first != NULL)
				tree_print_s(ptr->first, file);
			if (ptr->last != NULL)
				tree_print_s(ptr->last, file);

			fprintf(file, "node_%p -> node_%p\n", ptr, ptr->first);
			fprintf(file, "node_%p -> node_%p\n", ptr, ptr->last);
		}break;
		case 3:{
			if (ptr->first != NULL)
				tree_print_s(ptr->first, file);
			if (ptr->first != NULL && ptr->first->next != NULL)
				tree_print_s(ptr->first->next, file);
			if (ptr->last != NULL)
				tree_print_s(ptr->last, file);

			fprintf(file, "node_%p -> node_%p\n", ptr, ptr->first);
			fprintf(file, "node_%p -> node_%p\n", ptr, ptr->first->next);
			fprintf(file, "node_%p -> node_%p\n", ptr, ptr->last);
		}break;
	}
}
