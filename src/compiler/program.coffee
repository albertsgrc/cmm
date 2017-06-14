{ IO } = require '../runtime/io'
utils = require '../utils'

module.exports = @

@Program = class Program
    @ENTRY_FUNCTION: ".text"
    @MAIN_FUNCTION: "main"

    # Sets a property on each instruction which indicates which variables are alive at that instruction
    # Uses debug instructions that are inserted during the compilation step, and removes then after the tagging is
    # complete
    tagInstructionsVariables = (functions) ->
        definedVariables = {}

        definedVariablesStack = []

        defineVariable = (defIns) ->
            [ variable ] = defIns.children
            definedVariables[variable.id] ?= []
            definedVariables[variable.id][definedVariablesStack.length] = variable

        openScope = ->
            variablesCopy = {}

            for variable, scopes of definedVariables
                variablesCopy[variable] = utils.clone scopes

            definedVariablesStack.push variablesCopy


        closeScope = -> definedVariables = definedVariablesStack.pop()

        getVisibleVariables = ->
            visibleVariables = {}

            for variable, scopes of definedVariables
                visibleVariables[variable] = scopes[scopes.length - 1]

            visibleVariables

        tagInstructions = (funcId) ->
            for instruction, i in functions[funcId].instructions
                switch
                    when instruction.variableDeclaration then defineVariable instruction
                    when instruction.functionDefinition then tagInstructions(instruction.children[0])
                    when instruction.openScope then openScope()
                    when instruction.closeScope then closeScope()
                    else
                        functions[funcId].instructions[i].visibleVariables = getVisibleVariables()

        tagInstructions(Program.ENTRY_FUNCTION)

    constructor: (@variables, @functions, @globalsSize) ->
        @outputListeners = []

        tagInstructionsVariables(@functions)

        for funcId, func of @functions
            func.instructions = (instruction for instruction in func.instructions when not instruction.isDebugInfo)



    instructionsToString: ->
        s = ""
        for funcId, func of @functions
            s += funcId + ":" + "\n"
            for instruction in func.instructions
                s += instruction.toString().split("\n").map((x) -> "    " + x).join("\n") + "\n"

        s

    writeInstructions: ->
        for funcId, func of @functions
            console.log funcId + ":"
            for instruction in func.instructions
                console.log instruction.toString().split("\n").map((x) -> "    " + x).join("\n")

    attachMemory: (@memory) ->
    attachOutputListener: (fn, stream = IO.INTERLEAVED) -> @outputListeners.push({ fn, stream })
