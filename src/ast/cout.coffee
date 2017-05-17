{ Ast } = require './ast'
{ BASIC_TYPES } = require './type'
{ Write } = require './write'

module.exports = @

@Cout = class Cout extends Ast
    compile: (state) ->
        # Comprovar/castejar que tots els fills siguin strings
        # Retorna void

        instructions = []

        for value in @children
            { result, instructions: valueInstructions } = value.compile state
            state.releaseTemporaries result
            instructions = instructions.concat valueInstructions
            instructions.push new Write result

        instructions.forEach((x) => x.locations = @locations)

        return { type: BASIC_TYPES.VOID, instructions }