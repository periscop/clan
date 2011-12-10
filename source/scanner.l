
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **
    **---     /.\   -----------------------------------------------------**
    **   <|  [""M#                 scanner.l                             **
    **-   A   | #   -----------------------------------------------------**
    **   /.\ [""M#         First version: 30/04/2008                     **
    **- [""M# | #  U"U#U  -----------------------------------------------**
         | #  | #  \ .:/
         | #  | #___| #
 ******  | "--'     .-"  ******************************************************
 *     |"-"-"-"-"-#-#-##   Clan : the Chunky Loop Analyzer (experimental)     *
 ****  |     # ## ######  *****************************************************
 *      \       .::::'/                                                       *
 *       \      ::::'/     Copyright (C) 2008 University Paris-Sud 11         *
 *     :8a|    # # ##                                                         *
 *     ::88a      ###      This is free software; you can redistribute it     *
 *    ::::888a  8a ##::.   and/or modify it under the terms of the GNU Lesser *
 *  ::::::::888a88a[]:::   General Public License as published by the Free    *
 *::8:::::::::SUNDOGa8a::. Software Foundation, either version 2.1 of the     *
 *::::::::8::::888:Y8888:: License, or (at your option) any later version.    *
 *::::':::88::::888::Y88a::::::::::::...                                      *
 *::'::..    .   .....   ..   ...  .                                          *
 * This software is distributed in the hope that it will be useful, but       *
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY *
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License   *
 * for more details.      *
 *                                                                            *
 * You should have received a copy of the GNU Lesser General Public License   *
 * along with software; if not, write to the Free Software Foundation, Inc.,  *
 * 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA                     *
 *                                                                            *
 * Clan, the Chunky Loop Analyzer                                             *
 * Written by Cedric Bastoul, Cedric.Bastoul@u-psud.fr                        *
 *                                                                            *
 ******************************************************************************/


D                      [0-9]
L                      [a-zA-Z_]
H                      [a-fA-F0-9]
E                      [Ee][+-]?{D}+
P                      [Pp][+-]?{D}+
FS                     (f|F|l|L)
IS                     ((u|U)|(u|U)?(l|L|ll|LL)|(l|L|ll|LL)(u|U))


%{
   #include <stdlib.h>
   #include <string.h>
   
   #include <osl/vector.h>
   #include <osl/relation.h>
   #include <osl/relation_list.h>
   #include <parser.h>
   #include <clan/macros.h>
   #include <clan/symbol.h>

   void yyerror(char *);
   int  clan_scanner(int, char *);

   extern int           parser_recording; /**< Do we record what we read ? */
   extern char *        parser_record;    /**< What we record */
   extern clan_symbol_p parser_symbol;    /**< Top of the symbol table */

   int    scanner_parsing = CLAN_FALSE;   /**< Do we parse or not ? */
   int    scanner_comment = 0;            /**< Comment nesting depth */
   char * scanner_latest_text = NULL;     /**< Latest text read */
%}

%x LINECOMMENT
%x FULLCOMMENT

%%

<FULLCOMMENT>"*/"      {
                         scanner_comment --;
                         if (scanner_comment == 0)
                           BEGIN INITIAL;   /* Quit any mode */
                       }
<FULLCOMMENT>"/*"      { scanner_comment ++; }
<FULLCOMMENT>.         ; /* Do nothing */

<LINECOMMENT>\n        { BEGIN INITIAL;     /* Quit any mode */ }
<LINECOMMENT>.         ; /* Do nothing */

[ \t\n]*               ; /* Skip whitespaces */
"//"                   { BEGIN LINECOMMENT; /* Enter LINECOMMENT mode */ }
"/*"                   {
                         BEGIN FULLCOMMENT; /* Enter FULLCOMMENT mode */
                         scanner_comment ++;
                       }

"auto"                 { return clan_scanner(AUTO, "auto"); }
"_Bool"                { return clan_scanner(BOOL, "_Bool"); }
"break"                { return clan_scanner(BREAK, "break"); }
"case"                 { return clan_scanner(CASE, "case"); }
"char"                 { return clan_scanner(CHAR, "char"); }
"_Complex"             { return clan_scanner(COMPLEX, "_Complex"); }
"const"                { return clan_scanner(CONST, "const"); }
"continue"             { return clan_scanner(CONTINUE, "continue"); }
"default"              { return clan_scanner(DEFAULT, "default"); }
"do"                   { return clan_scanner(DO, "do"); }
"double"               { return clan_scanner(DOUBLE, "double"); }
"else"                 { return clan_scanner(ELSE, "else"); }
"enum"                 { return clan_scanner(ENUM, "enum"); }
"extern"               { return clan_scanner(EXTERN, "extern"); }
"float"                { return clan_scanner(FLOAT, "float"); }
"for"                  { return clan_scanner(FOR, "for"); }
"goto"                 { return clan_scanner(GOTO, "goto"); }
"if"                   { return clan_scanner(IF, "if"); }
"_Imaginary"           { return clan_scanner(IMAGINARY, "_Imaginary"); }
"inline"               { return clan_scanner(INLINE, "inline"); }
"int"                  { return clan_scanner(INT, "int"); }
"long"                 { return clan_scanner(LONG, "long"); }
"register"             { return clan_scanner(REGISTER, "register"); }
"restrict"             { return clan_scanner(RESTRICT, "restrict"); }
"return"               { return clan_scanner(RETURN, "return"); }
"short"                { return clan_scanner(SHORT, "short"); }
"signed"               { return clan_scanner(SIGNED, "signed"); }
"sizeof"               { return clan_scanner(SIZEOF, "sizeof"); }
"static"               { return clan_scanner(STATIC, "static"); }
"struct"               { return clan_scanner(STRUCT, "struct"); }
"switch"               { return clan_scanner(SWITCH, "switch"); }
"typedef"              { return clan_scanner(TYPEDEF, "typedef"); }
"union"                { return clan_scanner(UNION, "union"); }
"unsigned"             { return clan_scanner(UNSIGNED, "unsigned"); }
"void"                 { return clan_scanner(VOID, "void"); }
"volatile"             { return clan_scanner(VOLATILE, "volatile"); }
"while"                { return clan_scanner(WHILE, "while"); }
"min"                  { return clan_scanner(MIN, "min"); }
"max"                  { return clan_scanner(MAX, "max"); }
"ceild"                { return clan_scanner(CEILD, "ceild"); }
"floord"               { return clan_scanner(FLOORD, "floord"); }

"#pragma"[ ]+"scop"    { scanner_parsing = CLAN_TRUE;  /* Start parsing */ }
"#pragma"[ ]+"endscop" { scanner_parsing = CLAN_FALSE; /* Stop  parsing */ }
"#pragma"[ ]+"local-vars" { return clan_scanner(PRAGMALOCALVARS, "PRAGMALOCALVARS"); }
"#pragma"[ ]+"live-out" { return clan_scanner(PRAGMALIVEOUT, "PRAGMALIVEOUT"); }

[_A-Za-z]"."[A-Za-z0-9_]* |
[_A-Za-z]"->"[A-Za-z0-9_]* |
[_A-Za-z][A-Za-z0-9_]* {
                         if (scanner_parsing == CLAN_TRUE) { 
                           char * word;
                           CLAN_malloc(word, char *,
                                       (strlen(yytext) + 1) * sizeof(char));
                           strcpy(word, yytext);
                           yylval.symbol = word;
                         }
                         return clan_scanner(ID, "ID");
                       }
[0-9]+                 {
                         yylval.value = atoi(yytext) ;
                         return clan_scanner(INTEGER, "INTEGER");
                       }
0[xX]{H}+{IS}?         { return clan_scanner(CONSTANT, "CONSTANT_0"); }
0{D}+{IS}?             { return clan_scanner(CONSTANT, "CONSTANT_1"); }
{D}+{IS}?              { return clan_scanner(CONSTANT, "CONSTANT_2"); }
L?'(\\.|[^\\'\n])+'    { return clan_scanner(CONSTANT, "CONSTANT_3"); }
{D}+{E}{FS}?           { return clan_scanner(CONSTANT, "CONSTANT_4"); }
{D}*"."{D}+({E})?{FS}? { return clan_scanner(CONSTANT, "CONSTANT_5"); }
{D}+"."{D}*({E})?{FS}? { return clan_scanner(CONSTANT, "CONSTANT_6"); }
0[xX]{H}+{P}{FS}?      { return clan_scanner(CONSTANT, "CONSTANT_7"); }
0[xX]{H}*"."{H}+({P})?{FS}? { return clan_scanner(CONSTANT, "CONSTANT_8"); }
0[xX]{H}+"."{H}*({P})?{FS}? { return clan_scanner(CONSTANT, "CONSTANT_9"); }


L?\"(\\.|[^\\"\n])*\"  { return clan_scanner(STRING_LITERAL, "STRING"); }


"..."                  { return clan_scanner(ELLIPSIS, "..."); }
">>="                  { return clan_scanner(RIGHT_ASSIGN, ">>="); }
"<<="                  { return clan_scanner(LEFT_ASSIGN, "<<="); }
"+="                   { return clan_scanner(ADD_ASSIGN, "+="); }
"-="                   { return clan_scanner(SUB_ASSIGN, "-="); }
"*="                   { return clan_scanner(MUL_ASSIGN, "*="); }
"/="                   { return clan_scanner(DIV_ASSIGN, "/="); }
"%="                   { return clan_scanner(MOD_ASSIGN, "%="); }
"&="                   { return clan_scanner(AND_ASSIGN, "&="); }
"^="                   { return clan_scanner(XOR_ASSIGN, "^="); }
"|="                   { return clan_scanner(OR_ASSIGN, "|="); }
">>"                   { return clan_scanner(RIGHT_OP, ">>"); }
"<<"                   { return clan_scanner(LEFT_OP, "<<"); }
"++"                   { return clan_scanner(INC_OP, "++"); }
"--"                   { return clan_scanner(DEC_OP, "--"); }
"->"                   { return clan_scanner(PTR_OP, "->"); }
"&&"                   { return clan_scanner(AND_OP, "&&"); }
"||"                   { return clan_scanner(OR_OP, "||"); }
"<="                   { return clan_scanner(LE_OP, "<="); }
">="                   { return clan_scanner(GE_OP, ">="); }
"=="                   { return clan_scanner(EQ_OP, "=="); }
"!="                   { return clan_scanner(NE_OP, "!="); }
";"                    { return clan_scanner(';', ";"); }
("{"|"<%")             { return clan_scanner('{', "{"); }
("}"|"%>")             { return clan_scanner('}', "}"); }
","                    { return clan_scanner(',', ","); }
":"                    { return clan_scanner(':', ":"); }
"="                    { return clan_scanner('=', "="); }
"("                    { return clan_scanner('(', "("); }
")"                    { return clan_scanner(')', ")"); }
("["|"<:")             { return clan_scanner('[', "["); }
("]"|":>")             { return clan_scanner(']', "]"); }
"."                    { return clan_scanner('.', "."); }
"&"                    { return clan_scanner('&', "&"); }
"!"                    { return clan_scanner('!', "!"); }
"~"                    { return clan_scanner('~', "~"); }
"-"                    { return clan_scanner('-', "-"); }
"+"                    { return clan_scanner('+', "+"); }
"*"                    { return clan_scanner('*', "*"); }
"/"                    { return clan_scanner('/', "/"); }
"%"                    { return clan_scanner('%', "%"); }
"<"                    { return clan_scanner('<', "<"); }
">"                    { return clan_scanner('>', ">"); }
"^"                    { return clan_scanner('^', "^"); }
"|"                    { return clan_scanner('|', "|"); }
"?"                    { return clan_scanner('?', "?"); }
.                      { 
                         if (scanner_parsing == CLAN_TRUE) {
                           CLAN_warning("unmatched characters by Lex");
                           yyerror("Lex: Unknown character");
                         }
                       }

%%

int yywrap(void)
{
  return 1;
}

/**
 * clan_scanner_free function:
 * this function frees the memory allocated for the scanner. It frees
 * flex's buffer (it supposes there is only one buffer) since flex does
 * never free it itself.
 * WARNING: this is probably *not* portable...
 */
void clan_scanner_free() {

  yy_delete_buffer(YY_CURRENT_BUFFER);
  free(yy_buffer_stack);
  free(scanner_latest_text);
}

/**
 * clan_scanner function:
 * This function achieves some basic work when Lex recognize something: it
 * prints a log information if necessary for debugging, it updates the string
 * scanner_latest_text with the string that have been read and returns the
 * token if we are scanning a SCoP or the special token IGNORE otherwise.
 * \param token   The token code to send to Yacc for the Lex item.
 * \param message A string to be printed for debugging.
 */
int clan_scanner(int token, char * message)
{
  if (CLAN_DEBUG)
    fprintf(stderr, "[Clan] Info: Lex yytext = %s (%s)\n",message, yytext);

  free(scanner_latest_text);
  scanner_latest_text = strdup(yytext);
  if (parser_recording) {
    CLAN_realloc(parser_record, char *,
                 (strlen(parser_record) + strlen(yytext) + 1) * sizeof(char));
    strcat(parser_record, yytext);
  }

  if (scanner_parsing == CLAN_TRUE)
    return token;
  else
    return IGNORE;
}
