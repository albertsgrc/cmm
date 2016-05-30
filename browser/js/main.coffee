util = require 'util'

{ parser } = require '../../parser/grammar.jison'
{ checkSemantics } = require '../../semantics/'
interpreter = require '../../interpreter/'
Ast = require '../../parser/ast.coffee'

parser.yy = { Ast }

compile = (code) ->
    ast = parser.parse code
    checkSemantics ast


execute = (ast) ->
    interpreter.load ast
    interpreter.run()

setOutput = (s) -> $("#output").html(s)

$ -> # Equivalent to $(document).ready(function() {...})
    # Place the code editor
    codeMirror = CodeMirror(((elt) -> $("#code").replaceWith(elt)),
        {
            value:
                """
                    int main() {

                    }
                """
            theme: "material"
        }
    )

    $("#compile").click(->
        code = codeMirror.getValue()

        try
            ast = compile code
        catch error
            setOutput "<b>Compilation Error</b><br/>#{error.stack ? error.message}"
            return

        setOutput "<b>No compilation errors</b><br/>#{JSON.stringify(ast, null, 4)}"
    )

    $("#run").click(->
        code = codeMirror.getValue()

        try
            ast = compile code
        catch error
            setOutput "<b>Compilation Error</b><br/>#{error.stack ? error.message}"
            return

        try
            { output, status } = execute ast
            showableOutput = ""
            for line in output 
                showableOutput += " <br> " + line
            console.log output
            console.log showableOutput
            #output.replace(/(?:\r\n|\r|\n)/g, '<br />');
        catch error
            setOutput "<b>Execution Error</b><br/>#{error.stack ? error.message}"

        setOutput "<b>Exit Status:<b/> #{status}<br/><b>Output:</b><br/>#{showableOutput}"
    )