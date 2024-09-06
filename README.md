# zisp
A simple lisp implemented in zig. (my first zig project :D)

## CLI
`zisp --path <PATH>`

### Optional Arguments
- `--show-ast` - Prints the abstract syntax tree to the console.
- `--help` - Shows a help menu with more info.

## Syntax

### Calling a function
You can call a function by running `functionName arg1 arg2 ...`

### Defining a function
You can define a function with the following syntax:
```
def functionName (argname1 argname2) (body)
```

Unlike the `global` function, `def` is a sort of macro that can accept identifiers and contexts as their literal tokens. Functions do reside in the global scope, meaning that 

### Builtin Types
- `int` - a 32-bit signed integer. literals defined by just typing the actual number characters.
- `str` - a variable-length string. literals defined using quotation marks.
- `list` - A list containing variable types and of variable length. delimited by square brackets, with whitespace separating elements (ex: ["a" "b" "c"]).

### Contexts
A context is used to separate a call from other calls. For instance:
```
println (+ 1 2)
```

The output of `+ 1 2` is passed to `println` as a single argument.


Contexts are also used in separating multiple sequential calls as well. Take this for example:
```
(println "foo")
(println "bar")
```

The contexts are used here to tell the interpreter that these are two separate calls.

### Comments
Comments can be added with `//`. When a comment character is reached, the interpreter will ignore the rest of the line.

## Internal functions
- `+ a b` - adds two numbers together. can also concatenate two strings together
- `- a b` - subtracts the second number from the first
- `* a b` - multiplies two numbers together
- `/ a b` - divides the first number by the second
- `% a b` - gets the modulo of the two numbers. follows the true mathematical moduluo
- `print arg` - prints the provided text to the console
- `println arg` - prints the provided text to the console (with a newline)
- `input arg` - prints the provided text to the console and waits for user input. returns a string.
- `global name val` - sets a global variable of name and value
- `var name val` - sets a local variable of name and value
- `iget list index` - retrieves the value at the specified index from the list
- `append list item` - appends an item to the end of the list
- `insert list index item` - inserts an item at the index of the list and pushes everything else over
- `extend list1 list2` - Adds the contents of list2 to list1