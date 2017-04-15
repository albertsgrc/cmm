assert = require 'assert'

{ Ast } = require './ast'
{ TYPES } = require './type'

module.exports = @

MALLOC_HEADER_SIZE = 272 # Needed for the malloc library
HEAP_INITIAL_ADDRESS = 0x80000000 + MALLOC_HEADER_SIZE

@MemoryReference = class MemoryReference extends Ast
    @HEAP: 0
    @STACK: 1
    @TMP: 2
    @RETURN: 3

    constructor: (type, address) ->
        assert type.isAssignable

        @get = 'get' + type.stdTypeName
        @set = 'set' + type.stdTypeName
        @address = address

        super type, address

    @from: (type, value, store) ->
        if type is TYPES.STRING
            new StringReference value
        else
            switch store
                when @HEAP then new HeapReference(type, value)
                when @STACK then new StackReference(type, value)
                when @TMP then new TmpReference(type, value)
                when @RETURN then new ReturnReference(type)
                else assert false

    getValue: -> #TODO: Access memory and return

    getType: -> @children[0]
    getAddress: -> @children[1]

    read: (memory) -> memory[@address >>> 31][@get](@address & 0x7FFFFFFF)
    write: (memory, value) -> memory[@address >>> 31][@set](@address & 0x7FFFFFFF, value)

    # [ type, address ] =  @children

@ReturnReference = class ReturnReference extends MemoryReference
    constructor: (type) -> super type, 0

    read: (memory) -> memory.return[@get](0)
    write: (memory, value) -> memory.return[@set](0, value)

@StackReference = class StackReference extends MemoryReference
    read: (memory) -> memory[@address >>> 31][@get]((@address & 0x7FFFFFFF) + memory.pointers.stack)
    write: (memory, value) -> memory[@address >>> 31][@set]((@address & 0x7FFFFFFF) + memory.pointers.stack, value)

@HeapReference = class HeapReference extends MemoryReference
    constructor: (type, address) ->
        super type, address + HEAP_INITIAL_ADDRESS

@TmpReference = class TmpReference extends MemoryReference
    isTemporary: true

    read: (memory) -> memory.tmp[@get](@address + memory.pointers.temporaries)
    write: (memory, value) -> memory.tmp[@set](@address + memory.pointers.temporaries, value)

@StringReference = class StringReference extends Ast
    constructor: (string) -> super string

    read: -> @child()
    write: (_, value) -> @setChild 0, value

    getType: -> TYPES.STRING