/* ***************************************************
   ******* Modificado por: ***************************
   ******* Felipe Einsfeld Kersting ******************
   ******* Pedro Sassen Veiga ************************
   *************************************************** */
%{
#include "parser.h" //arquivo automaticamente gerado pelo bison
#include "cc_misc.h"

int line_count = 1;
int previous_token = 0;
char buffer[2048];
char buffer_appended[2048];

#define R_TOK previous_token = 0
#define S_TOK previous_token = 1

#define get_symbol_dict(A, B) ((symbol_value*)dict_get(A, B))->value_string

symbol_value* fill_symbol_value(int line_count, int tipo, char* value)
{
	symbol_value* tmp_value = malloc(sizeof(symbol_value));

	tmp_value->line = line_count;
	tmp_value->tipo = tipo;
	tmp_value->tipo_primitivo = tipo;
	switch(tipo)
	{
		case SIMBOLO_LITERAL_INT:
		tmp_value->value_int = atoi(value);
		break;
		case SIMBOLO_LITERAL_FLOAT:
		tmp_value->value_float = atof(value);
		break;
		case SIMBOLO_LITERAL_CHAR:
		tmp_value->value_char = value[0];
		break;
		case SIMBOLO_LITERAL_STRING:
		tmp_value->value_string = malloc(strlen(value) + 1);
		strcpy(tmp_value->value_string, value);
		break;
		case SIMBOLO_LITERAL_BOOL:
		tmp_value->value_bool = (value[0] == 't') ? 1 : 0;
		break;
		case SIMBOLO_IDENTIFICADOR:
		tmp_value->value_string = malloc(strlen(value) + 1);
		strcpy(tmp_value->value_string, value);
		break;
	}
	return tmp_value;
}

%}

DIGIT		[0-9]
IDENTIFIER	[_a-zA-Z]+[_a-zA-Z0-9]*
SINGLECOMMENT	"//"[^\r\n]*
WHITESPACE	[ \t\v\f\r]
CHARACTER	.
NL		\n

%%

"/*"		{
			register int c;

			for ( ; ; )
			{
				while ( (c = input()) != '*' && c != EOF )
					{ if( c == '\n' ) line_count++; }

				if ( c == '*' )
				{
					while ( (c = input()) == '*' )
					;
					if ( c == '/' )
						break;
				}

				if ( c == EOF )
				{
					error( "EOF in comment" );
					break;
				}
				if( c == '\n' ) line_count++; 
			}
			R_TOK;
		}

{SINGLECOMMENT}			{ R_TOK; }

{WHITESPACE}			{ /*S_TOK;*/ }

{NL}				{ R_TOK; line_count++; }

"int"				{ R_TOK; return TK_PR_INT; }
"float"				{ R_TOK; return TK_PR_FLOAT; }
"bool"				{ R_TOK; return TK_PR_BOOL; }
"char"				{ R_TOK; return TK_PR_CHAR; }
"string"			{ R_TOK; return TK_PR_STRING; }
"if"				{ R_TOK; return TK_PR_IF; }
"then"				{ R_TOK; return TK_PR_THEN; }
"else"				{ R_TOK; return TK_PR_ELSE; }
"while"				{ R_TOK; return TK_PR_WHILE; }
"do"				{ R_TOK; return TK_PR_DO; }
"input"				{ R_TOK; return TK_PR_INPUT; }
"output"			{ R_TOK; return TK_PR_OUTPUT; }
"return"			{ R_TOK; return TK_PR_RETURN; }
"const"				{ R_TOK; return TK_PR_CONST; }
"static"			{ R_TOK; return TK_PR_STATIC; }
"foreach"			{ R_TOK; return TK_PR_FOREACH; }
"for"				{ R_TOK; return TK_PR_FOR; }
"switch"			{ R_TOK; return TK_PR_SWITCH; }
"case"				{ R_TOK; return TK_PR_CASE; }
"break"				{ R_TOK; return TK_PR_BREAK; }
"continue"			{ R_TOK; return TK_PR_CONTINUE; }
"class"				{ R_TOK; return TK_PR_CLASS; }
"private"			{ R_TOK; return TK_PR_PRIVATE; }
"public"			{ R_TOK; return TK_PR_PUBLIC; }
"protected"			{ R_TOK; return TK_PR_PROTECTED; }

'{CHARACTER}'			{

	strcpy(buffer, yytext); 
	remove_single_quotes(buffer);

	strcpy(buffer_appended, buffer);
	append_type_to_lexem(buffer_appended, SIMBOLO_LITERAL_CHAR);

	void* last_value = dict_get(dict, buffer_appended);

	if(!last_value)
	{
		symbol_value* tmp_value = fill_symbol_value(line_count, SIMBOLO_LITERAL_CHAR, buffer);
		dict_put(dict, buffer_appended, tmp_value);
	}
	else
		((symbol_value*)last_value)->line = line_count;
	R_TOK;

	yylval.ptr = dict_get(dict, buffer_appended);
	return TK_LIT_CHAR;
}

\"(\\.|[^\\"])*\"		{

	strcpy(buffer, yytext);
	remove_double_quotes(buffer);
	
	strcpy(buffer_appended, buffer);
	append_type_to_lexem(buffer_appended, SIMBOLO_LITERAL_STRING);

	void* last_value = dict_get(dict, buffer_appended);

	if(!last_value)
	{
		symbol_value* tmp_value = fill_symbol_value(line_count, SIMBOLO_LITERAL_STRING, buffer);
		dict_put(dict, buffer_appended, tmp_value);
	}
	else
		((symbol_value*)last_value)->line = line_count;
	R_TOK;

	yylval.ptr = dict_get(dict, buffer_appended);
	return TK_LIT_STRING;
}

"true"				{
	strcpy(buffer, yytext);

	strcpy(buffer_appended, buffer);
	append_type_to_lexem(buffer_appended, SIMBOLO_LITERAL_BOOL);

	void* last_value = dict_get(dict, buffer_appended);

	if(!last_value)
	{
		symbol_value* tmp_value = fill_symbol_value(line_count, SIMBOLO_LITERAL_BOOL, buffer);
		dict_put(dict, buffer_appended, tmp_value);
	}
	else
		((symbol_value*)last_value)->line = line_count;
	R_TOK;

	yylval.ptr = dict_get(dict, buffer_appended);
	return TK_LIT_TRUE;
}

"false"				{
	strcpy(buffer, yytext);

	strcpy(buffer_appended, buffer);
	append_type_to_lexem(buffer_appended, SIMBOLO_LITERAL_BOOL);
	
	void* last_value = dict_get(dict, buffer_appended);

	if(!last_value)
	{
		symbol_value* tmp_value = fill_symbol_value(line_count, SIMBOLO_LITERAL_BOOL, buffer);
		dict_put(dict, buffer_appended, tmp_value);
	}
	else
		((symbol_value*)last_value)->line = line_count;
	R_TOK;
	
	yylval.ptr = dict_get(dict, buffer_appended);
	return TK_LIT_FALSE;
}

{IDENTIFIER}			{

	strcpy(buffer, yytext);

	strcpy(buffer_appended, buffer);
	append_type_to_lexem(buffer_appended, SIMBOLO_IDENTIFICADOR);
	
	void* last_value = dict_get(dict, buffer_appended);

	if(!last_value)
	{	
		symbol_value* tmp_value = fill_symbol_value(line_count, SIMBOLO_IDENTIFICADOR, buffer);
		dict_put(dict, buffer_appended, tmp_value);
	}
	else
		((symbol_value*)last_value)->line = line_count;
	S_TOK;

	yylval.ptr = dict_get(dict, buffer_appended);
	return TK_IDENTIFICADOR;
}

[+-]?{DIGIT}+			{

	strcpy(buffer, yytext);

	strcpy(buffer_appended, buffer);
	append_type_to_lexem(buffer_appended, SIMBOLO_LITERAL_INT);

	void* last_value = dict_get(dict, buffer_appended);

	if(!last_value)
	{
		symbol_value* tmp_value = fill_symbol_value(line_count, SIMBOLO_LITERAL_INT, buffer);
		dict_put(dict, buffer_appended, tmp_value);
	}
	else
		((symbol_value*)last_value)->line = line_count;
	if((yytext[0] == '+' || yytext[0] == '-') && previous_token == 1) { REJECT; }
	S_TOK;

	yylval.ptr = dict_get(dict, buffer_appended);
	return TK_LIT_INT;
}

[+-]?{DIGIT}+"."{DIGIT}*	{

	strcpy(buffer, yytext);

	strcpy(buffer_appended, buffer);
	append_type_to_lexem(buffer_appended, SIMBOLO_LITERAL_FLOAT);

	void* last_value = dict_get(dict, buffer_appended);

	if(!last_value)
	{
		symbol_value* tmp_value = fill_symbol_value(line_count, SIMBOLO_LITERAL_FLOAT, buffer);
		dict_put(dict, buffer_appended, tmp_value);
	}
	else
		((symbol_value*)last_value)->line = line_count;
	if((yytext[0] == '+' || yytext[0] == '-') && previous_token == 1) { REJECT; }
	S_TOK;

	yylval.ptr = dict_get(dict, buffer_appended);
	return TK_LIT_FLOAT;
}


","				{ R_TOK; return yytext[0]; }
";"				{ R_TOK; return yytext[0]; }
":"				{ R_TOK; return yytext[0]; }
"("				{ R_TOK; return yytext[0]; }
")"				{ S_TOK; return yytext[0]; }
"["				{ R_TOK; return yytext[0]; }
"]"				{ S_TOK; return yytext[0]; }
"{"				{ R_TOK; return yytext[0]; }
"}"				{ R_TOK; return yytext[0]; }
"+"				{ R_TOK; return yytext[0]; }
"-"				{ R_TOK; return yytext[0]; }
"*"				{ R_TOK; return yytext[0]; }
"/"				{ R_TOK; return yytext[0]; }
"<"				{ R_TOK; return yytext[0]; }
">"				{ R_TOK; return yytext[0]; }
"="				{ R_TOK; return yytext[0]; }
"!"				{ R_TOK; return yytext[0]; }
"&"				{ R_TOK; return yytext[0]; }
"$"				{ R_TOK; return yytext[0]; }
"%"				{ R_TOK; return yytext[0]; }
"#"				{ R_TOK; return yytext[0]; }
"^"				{ R_TOK; return yytext[0]; }

"<="				{ R_TOK; return TK_OC_LE; }
">="				{ R_TOK; return TK_OC_GE; }
"=="				{ R_TOK; return TK_OC_EQ; }
"!="				{ R_TOK; return TK_OC_NE; }
"&&"				{ R_TOK; return TK_OC_AND; }
"||"				{ R_TOK; return TK_OC_OR; }
"<<"				{ R_TOK; return TK_OC_SL; }
">>"				{ R_TOK; return TK_OC_SR; }



.				{ R_TOK; return TOKEN_ERRO; }

%%
