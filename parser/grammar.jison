/* description: Parses and executes mathematical expressions. */

/* lexical grammar */
%lex
%%

"//".*                /* ignore comment */
"/*"(.|\n|\r)*?"*/"   /* ignore multiline comment */
\s+                   /* skip whitespace */
// I think we should make all the tokens return a name rathen than itself
"++"                                        return '++'
"--"                                        return '--'
"+="                                        return '+='
"-="                                        return '-='
"*="                                        return '*='
"/="                                        return '/='
"%="                                        return '%='

"*"                                         return 'MUL'
"/"                                         return 'DIV'
"-"                                         return 'MINUS'
"%"                                         return 'MOD'
"+"                                         return 'PLUS'

"!="                                        return '!='

"or"|"||"                                   return 'OR'
"and"|"&&"                                  return 'AND'
"not"|"!"                                   return 'NOT'

"<<"                                        return '<<'
">>"                                        return '>>'

">="                                        return '>='
"<="                                        return '<='
">"                                         return '>'
"<"                                         return '<'
"=="                                        return '=='

"="                                         return 'DIRECT_ASSIGN' // TODO: Replace by ASSIGN and rethink the whole assign parsing

";"                                         return ';'
"{"                                         return '{'
"}"                                         return '}'
"("                                         return '('
")"                                         return ')'
","                                         return ','
"#"                                         return '#'

"return"                                    return 'RETURN'

"cin"                                       return 'CIN'
"cout"                                      return 'COUT'

"endl"                                      return 'ENDL'

"int"                                       return 'INT'
"double"                                    return 'DOUBLE'
"char"                                      return 'CHAR'
"bool"                                      return 'BOOL'
"string"                                    return 'STRING'
"void"                                      return 'VOID'

"include"                                   return 'INCLUDE'
'using'                                     return 'using'
'namespace'                                 return 'NAMESPACE'
'std'                                       return 'std'

"if"                                        return 'IF'
"else"                                      return 'ELSE'
"while"                                     return 'WHILE'
"for"                                       return 'FOR'

"true"|"false"                              return 'BOOL_LIT'
[0-9]+("."[0-9]+)\b                         return 'DOUBLE_LIT'
([1-9][0-9]*|0)                             return 'INT_LIT'
\'([^\\\']|\\.)\'                           return 'CHAR_LIT'
\"([^\\\"]|\\.)*\"                          return 'STRING_LIT'

([a-z]|[A-Z]|_)([a-z]|[A-Z]|_|[0-9])*       return 'ID'

<<EOF>>                                     return 'EOF'

.                                           return 'INVALID'

/lex

/* operator associations and precedence */
%right '+=' '-=' '*=' '/=' '%=' DIRECT_ASSIGN
%left OR
%left AND
%left '==' '!='
%left '<' '>' '<=' '>='
%left PLUS MINUS
%left MUL DIV MOD
%right NOT UPLUS UMINUS
%right PRE_INC PRE_DEC
%left POST_INC POST_DEC
%right THEN ELSE

%start prog

%% /* language grammar */

prog
    : block_includes block_functions EOF
        { return new yy.Ast('PROGRAM', [$1, $2]); }
    ;

block_includes
    : block_includes include
        {$$.addChild($2);}
    |
        {$$ = new yy.Ast('BLOCK-INCLUDES', []);}
    ;

include
    : '#' INCLUDE '<' id '>'
        {$$ = new yy.Ast('INCLUDE', [$4]);}
    | 'using' NAMESPACE 'std' ';'
        {$$ = new yy.Ast('NAMESPACE', [$4]);}
    ;

block_functions
    : block_functions function
        {$$.addChild($2);}
    |
        {$$ = new yy.Ast('BLOCK-FUNCTIONS', []);}
    ;

function
    : type id '(' arg_list ')' '{' block_instr '}'
        {$$ = new yy.Ast('FUNCTION',[$1,$2,$4,$7]);}
    ;

arg_list
    : arg_list ',' arg
        {$$.addChild($3);}
    | arg
        {$$ = new yy.Ast('ARG-LIST', [$1]);}
    |
        {$$ = new yy.Ast('ARG-LIST', []);}
    ;

arg
    : type id
        {$$ = new yy.Ast('ARG', [$1, $2]);}
    ;

block_instr
    : block_instr instruction
        {$$.addChild($2);}
    |
        {$$ = new yy.Ast('BLOCK-INSTRUCTIONS', []);}
    ;

instruction
    : basic_stmt ';'
    | if
    | while
    | for
    | return_stmt ';'
    | ';'
        {$$ = new yy.Ast('NOP', []);}
    ;

basic_stmt
    : block_assign
    | declaration
    | cin
    | cout
    | expr
    ;

return_stmt
    : RETURN expr
        {$$ = new yy.Ast('RETURN', [$2]);}
    | RETURN
        {$$ = new yy.Ast('RETURN', [])}
    ;

funcall
    : id '(' param_list ')'
        {$$ = new yy.Ast('FUNCALL', [$1,$3]);}
    ;

param_list
    : param_list ',' param
        {$$.addChild($3);}
    | param
        {$$ = new yy.Ast('PARAM-LIST', [$1]);}
    |
        {$$ = new yy.Ast('PARAM-LIST', []);}
    ;

param
    : expr
        {$$ = $1;}
    ;

if
    : IF '(' expr ')' instruction_body %prec THEN
        {$$ = new yy.Ast('IF-THEN', [$3, $5]);}
    | IF '(' expr ')' instruction_body else
        {$$ = new yy.Ast('IF-THEN-ELSE', [$3, $5, $6]);}
    ;

while
    : WHILE '(' expr ')' instruction_body
        {$$ = new yy.Ast('WHILE', [$3, $5]);}
    ;

for
    : FOR '(' basic_stmt ';' expr ';' basic_stmt ')' instruction_body
        {$$ = new yy.Ast('FOR', [$3, $5, $7, $9])}
    ;

else
    : ELSE instruction_body
        {$$ = $2;}
    ;

// TODO: Treat cin and cout as simple predefined objects like true and false of type STREAM
// TODO: Then make << and >> operators
cin
    : CIN block_cin
        {$$ = $2;}
    ;

block_cin
    : block_cin '>>' expr
        {$$.addChild($3);}
    | '>>' expr
        {$$ = new yy.Ast('CIN', [$2]);}
    ;

cout
    : COUT block_cout
        {$$ = $2;}
    ;

block_cout
    : block_cout '<<' expr
        {$$.addChild($3);}
    | block_cout '<<' ENDL
        {$$.addChild(new yy.Ast('ENDL', []));}
    | '<<' expr
        {$$ = new yy.Ast('COUT', [$2]);}
    | '<<' ENDL
        {$$ = new yy.Ast('COUT', [new yy.Ast('ENDL', [])]);}
    ;

instruction_body
    : instruction
        {$$ = new yy.Ast('BLOCK-INSTRUCTIONS', [$1]);}
    | '{' block_instr '}'
        {$$ = $2;}
    ;

direct_assign
    : id DIRECT_ASSIGN expr
        {$$ = new yy.Ast('ASSIGN', [$1, $3]);}
    ;

declaration
    : type declaration_body
        {$$ = new yy.Ast('DECLARATION', [$1, $2]);}
    ;

declaration_body
    : declaration_body ',' direct_assign
        {$$.push($3);}
    | declaration_body ',' id
        {$$.push($3);}
    | direct_assign
        {$$ = [$1];}
    | id
        {$$ = [$1];}
    ;


type
    : INT
        { $$ = 'INT' }
    | DOUBLE
        { $$ = 'DOUBLE' }
    | CHAR
        { $$ = 'CHAR' }
    | BOOL
        { $$ = 'BOOL' }
    | STRING
        { $$ = 'STRING' }
    | VOID
        { $$ = 'VOID' }
    ;

expr
    : expr PLUS expr
        {$$ = new yy.Ast('PLUS', [$1,$3]);}
    | expr MINUS expr
        {$$ = new yy.Ast('MINUS', [$1,$3]);}
    | expr MUL expr
        {$$ = new yy.Ast('MUL', [$1,$3]);}
    | expr DIV expr
        {$$ = new yy.Ast('DIV', [$1,$3]);}
    | expr MOD expr
        {$$ = new yy.Ast('MOD', [$1,$3]);}
    | expr AND expr
        {$$ = new yy.Ast('AND', [$1,$3]);}
    | expr OR expr
        {$$ = new yy.Ast('OR', [$1,$3]);}
    | MINUS expr
        {$$ = new yy.Ast('UMINUS', [$2]);}
    | PLUS expr
        {$$ = new yy.Ast('UPLUS', [$2]);}
    | NOT expr
        {$$ = new yy.Ast('NOT', [$2]);}
    | expr '<' expr
        {$$ = new yy.Ast('<', [$1,$3]);}
    | expr '>' expr
        {$$ = new yy.Ast('>', [$1,$3]);}
    | expr '<=' expr
        {$$ = new yy.Ast('<=', [$1,$3]);}
    | expr '>=' expr
        {$$ = new yy.Ast('>=', [$1,$3]);}
    | expr '==' expr
        {$$ = new yy.Ast('==', [$1,$3]);}
    | expr '!=' expr
        {$$ = new yy.Ast('!=', [$1,$3]);}
    | DOUBLE_LIT
        {$$ = new yy.Ast('DOUBLE_LIT', [$1]);}
    | INT_LIT
        {$$ = new yy.Ast('INT_LIT', [$1]);}
    | CHAR_LIT
        {$$ = new yy.Ast('CHAR_LIT', [$1])}
    | BOOL_LIT
        {$$ = new yy.Ast('BOOL_LIT', [$1]);}
    | STRING_LIT
        {$$ = new yy.Ast('STRING_LIT', [$1]);}
    | direct_assign
     | '++' id %prec PRE_INC
        {$$ = new yy.Ast('ASSIGN', [$2, new yy.Ast('PLUS', [$2, new yy.Ast('INT_LIT', [1])])]);}
    | '--' id %prec PRE_DEC
        {$$ = new yy.Ast('ASSIGN', [$2, new yy.Ast('MINUS', [$2, new yy.Ast('INT_LIT', [1])])]);}
    | id '++' %prec POST_INC
        {$$ = new yy.Ast('POST_INC', [$1]);}
    | id '--' %prec POST_DEC
        {$$ = new yy.Ast('POST_DEC', [$1]);}
    | id '+=' expr
        {$$ = new yy.Ast('ASSIGN', [$1, new yy.Ast('PLUS', [$1,$3])]);}
    | id '-=' expr
        {$$ = new yy.Ast('ASSIGN', [$1, new yy.Ast('MINUS', [$1,$3])]);}
    | id '*=' expr
        {$$ = new yy.Ast('ASSIGN', [$1, new yy.Ast('MUL', [$1,$3])]);}
    | id '/=' expr
        {$$ = new yy.Ast('ASSIGN', [$1, new yy.Ast('DIV', [$1,$3])]);}
    | id '%=' expr
        {$$ = new yy.Ast('ASSIGN', [$1, new yy.Ast('MOD', [$1,$3])]);}
    | id
    | funcall
    | '(' expr ')'
        {$$ = $2}
    ;

id
    : ID
        {$$ = new yy.Ast('ID', [$1]);}
    ;
