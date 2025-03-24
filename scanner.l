/* Definition section */
%{
     #include <stdio.h>
     #include <stdlib.h>
     #include <string.h>
 
     #define YY_NO_UNPUT
     #define YY_NO_INPUT
     #define print_token(token) \
         printf("%-8s \t %s\n", strcmp(token, "NEWLINE")? yytext: "", token)
 
     int line_num = 0;
     int comment_num = 0;
     int last_comment_line = -1;
%}
 
/* Define regular expression label */
letter      [a-zA-Z_]
digit       [0-9]
func        fn\ {letter}
ident       {letter}({letter}|{digit})*
intlit      [0-9]+
floatlit    [0-9]+\.[0-9]+
i32         i32[;|\ |,|\)]{1}
f32         f32[;|\ |,|\)]{1}
bool        bool[;|\ ]{1}

comment (\/\/(.)*|\/\*[.]*\*\/)
println println\(
print   print\(
true    true[;\)]
false   false[;\)]
let     let\ {letter}
mut     mut\ {letter}
as      as\ {letter}
if      if\ {letter}
else    else\ [{letter}|\{]
while   while\ {letter}
return  return\ {letter}
loop    loop\ [{letter}|\{]
break   break\ [{letter}|\{|\"]
for     for\ [{ident}]
in      in\ [.]*
/* string \"([^\"]*)\" */
/* comment (\/\/(.)*) */

/* Rules section */
%x multiln_comment
%x string

%%
"+"         { print_token("ADD"); }
"-"         { print_token("SUB"); }
"*"         { print_token("MUL"); }
"/"         { print_token("QUO"); }
"%"         { print_token("REM"); }
">"         { print_token("GTR"); }
"<"         { print_token("LSS"); }
">="        { print_token("GEQ"); }
"<="        { print_token("LEQ"); }
"=="        { print_token("EQL"); }
"!="        { print_token("NEQ"); }
"="         { print_token("ASSIGN"); }
"+="        { print_token("ADD_ASSIGN"); }
"-="        { print_token("SUB_ASSIGN"); }
"*="        { print_token("MUL_ASSIGN"); }
"/="        { print_token("QUO_ASSIGN"); }
"%="        { print_token("REM_ASSIGN"); }
"&"         { print_token("BAND"); }
"|"         { print_token("BOR"); }
"~"         { print_token("BNOT"); }
"&&"        { print_token("LAND"); }
"||"        { print_token("LOR"); }
"!"         { print_token("NOT"); }
">>"        { print_token("RSHIFT"); }
"<<"        { print_token("LSHIFT"); }
"->"        { print_token("ARROW"); }
"("         { print_token("LPAREN"); }
")"         { print_token("RPAREN"); }
"["         { print_token("LBRACK"); }
"]"         { print_token("RBRACK"); }
"{"         { print_token("LBRACE"); }
"}"         { print_token("RBRACE"); }
";"         { print_token("SEMICOLON"); }
":"         { print_token("COLON"); }
","         { print_token("COMMA"); }
"\""        { print_token("QUOTA"); }
"\n"        { print_token("NEWLINE"); line_num++; }
".."        { print_token("DOTDOT"); }
"true"      { print_token("TRUE"); }
"false"     { print_token("FALSE"); }
{func}      { yyless(3); print_token("FUNC"); }
{ident}     { print_token("IDENT"); }
{intlit}    { print_token("INT_LIT"); }
{floatlit}  { print_token("FLOAT_LIT"); }
{i32}       { yyless(yyleng - 1); print_token("INT"); }
{f32}       { yyless(yyleng - 1); print_token("FLOAT"); }
{bool}      { yyless(yyleng - 1); print_token("BOOL"); }

{comment}   { print_token("COMMENT"); comment_num++;}
{println}   { yyless(yyleng - 1); print_token("PRINTLN"); }
{print}     { yyless(yyleng - 1); print_token("PRINT"); }
{let}       { yyless(yyleng - 1); print_token("LET"); }
{mut}       { yyless(yyleng - 1); print_token("MUT"); }
{as}        { yyless(yyleng - 1); print_token("AS"); }
{if}        { yyless(yyleng - 1); print_token("IF"); }
{else}      { yyless(yyleng - 1); print_token("ELSE"); }
{while}     { yyless(yyleng - 1); print_token("WHILE"); }
{return}    { yyless(yyleng - 1); print_token("RETURN"); }
{loop}      { yyless(yyleng - 1); print_token("LOOP"); }
{break}     { yyless(yyleng - 1); print_token("BREAK"); }
{for}       { yyless(yyleng - 1); print_token("FOR"); }
{in}        { yyless(yyleng - 1); print_token("IN"); }
<<EOF>>     { line_num++; yyterminate(); }
[ \t]+      {;}
.           {;}

\/\*  { yymore(); BEGIN(multiln_comment); }
<multiln_comment>\*\/\ *\n      { yyless(yyleng - 1); print_token("MUTI_LINE_COMMENT"); BEGIN(INITIAL); comment_num++; }
<multiln_comment>\*\/\ *        { print_token("MUTI_LINE_COMMENT"); BEGIN(INITIAL); }
<multiln_comment>[^\*\n]*       { yymore(); }
<multiln_comment>\n             { yymore(); line_num++; comment_num++; }

\"[^\";)]       { yyless(1); print_token("QUOTA"); BEGIN(string); }
<string>\"      { yyless(yyleng - 1); print_token("STRING_LIT"); BEGIN(INITIAL); }
<string>[^\"]*  { yymore(); }
%%

/*  C Code section */
int yywrap(void) {
    return 1;
}

int main(int argc, char *argv[]) {
        if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }
    yylex();
    printf("\nFinish scanning,\n");
    printf("total line: %d\n", line_num);
    printf("comment line: %d\n", comment_num);
    fclose(yyin);
    return 0;
}