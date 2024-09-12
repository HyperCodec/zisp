# zisp
A simple lisp implemented in zig. (my first zig project :D)

## CLI
`zisp --path <PATH>`

### Optional Arguments
- `--show-ast` - Prints the abstract syntax tree to the console.
- `--help` - Shows a help menu with more info.

## Syntax

### If statements
The syntax for if statements is the following:
```
if (condition) (body)
```

Additionally, you can supply an else case:
```
if (condition) (body1) (body2)
```

### Calling a function
You can call a function by running `functionName arg1 arg2 ...`

### Defining a function
You can define a function with the following syntax:
```
def functionName (argname1 argname2) (body)
```

Unlike the `global` function, `def` is a sort of macro that can accept identifiers and contexts as their literal tokens. Functions reside in the local scope and can be run by value.

### OOP
Zisp has a `runMethod` function, which will pass a value into `self`. Consider the following:
```
(var "epicTable" (createTable))
(put epicTable "counter" 0)

// first define a method that accepts `self` as the first argument.
(def count (self) (
    (var "counter" (kget self "counter"))
    (print "Count: ")
    (println counter)
    (put self "counter" (+ counter 1))
))

// next, put that method in the table like a regular value.
(put epicTable "count" count)

// now, we can use `runMethod` to run our method.
(runMethod epicTable "count" [])
```

### Builtin Types
- `bool` - either true or false. same format in literals.
- `int` - a 32-bit signed integer. literals defined by just typing the actual number characters.
- `str` - a variable-length string. literals defined using quotation marks.
- `list` - A list containing variable types and of variable length. delimited by square brackets, with whitespace separating elements (ex: ["a" "b" "c"]).
- `table` - Maps a key to a value. To create one, use the `createTable` function.
- `function` - A literal function as defined by `def`. This type is mainly only referenced in function calls and OOP.

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
- `pop list1 | pop list1 index` - Removes the value from the list at the optionally specified index and returns it. If the index is not specified, it defaults to the last element in the list.
- `createTable` - Returns a new table.
- `put table key val` - Puts a value in the table at a specified key.
- `kget table key` - Returns the value in a table with a specified key.
- `runMethod table key args` - Gets and runs a method in a table, passing the table as the first argument. `args` is a list.
- `eq arg1 arg2 ...` - Returns true if all args are equal, false otherwise.
- `neq arg1 arg2 ...` - Opposite of eq.
- `not arg` - Reverses a boolean value.
- `or arg1 arg2 ...` - Returns true if any of the args are true, false otherwise.
- `and arg1 arg2 ...` - Returns true if all of the args are true, false otherwise.
- `< arg1 arg2` - returns whether the first value is less than the second.
- `<= arg1 arg2` - returns whether the first value is less than or equal to the second.
- `> arg1 arg2` - returns whether the first value is greater than the second.
- `>= arg1 arg2` - returns whether the firs tvalue is greater than or equal to the second.