# zisp
a simple lisp implemented in zig

## CLI
`zisp --path <PATH>`

### Optional Arguments
- `--show-ast` - Prints the abstract syntax tree to the console.
- `--help` - Shows a help menu with more info.

## Syntax

### Calling a function
You can call a function by running `functionName arg1 arg2 ...`

### Contexts
A context is used to separate a call from other calls. For instance:
```
println (+ 1 2)
```

The output of `+ 1 2` is passed to `println` as a single argument.


Contexts are also used in separating multiple sequential calls as well. Take this example:
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