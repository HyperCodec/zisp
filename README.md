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

Unlike the `global` function, `def` is a sort of macro that can accept identifiers and contexts as their literal tokens.

### Primitives
- `int` - a 32-bit signed integer. literals defined by just typing the actual number characters.
- `str` - a variable-length string. literals defined using quotation marks.

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
- `+ arg1 arg2` - adds two numbers together. can also concatenate two strings together
- `- arg1 arg2` - subtracts the second number from the first
- `* arg1 arg2` - multiplies two numbers together
- `/ arg1 arg2` - divides the first number by the second
- `% arg1 arg2` - gets the modulo of the two numbers. follows the true mathematical moduluo
- `print arg` - prints the provided text to the console
- `println arg` - prints the provided text to the console (with a newline)
- `global arg1 arg2` - sets a global variable of name arg1 and value arg2