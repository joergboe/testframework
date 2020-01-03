######################################################
# Utilities for testframework
#

function manbashpage () {
	less <<-EOF
Export Variables
================
The ro attribute (and others) is not availble in the child shell

Parameter Expansion
===================
\${parameter:=word}
              Assign Default Values.  If parameter is unset or null, the expansion of word is assigned to parameter. The value  of  parameter is
              then substituted.  Positional parameters and special parameters may not be assigned to in this way.
              
\${parameter=word}
              Assign Default Values.  If parameter is unset, the expansion of word is assigned to parameter. The value  of  parameter is
              then substituted.  Positional parameters and special parameters may not be assigned to in this way.
              
Conditionals
============
Prefer the [[ ]] expression (This is a Compound Command in bash man)
Word splitting and pathname expansion are not performed on the words between the [[ and ]];
tilde expansion, parameter and variable expansion,  arithmetic  expansion,  command  substitution, process substitution, and quote removal
are performed.  Conditional operators such as -f must be unquoted to be recognized as primaries.
- Quoting of variables is not required but is accepted
- Quoting of litarals which contain whitespaces is required
- But if characters * and ? are quoted, the special meaning is removes (pattern matching)
- Use unquoted parenthese
- Pattern matching with == and !=
- Regular expression match with =~
....
Therefore a
if [[ -n \$STFPRN_VERBOSE && -z \$STFPRN_VERBOSE_DISABLE ]]; then
is fine
help [[ ]]  -shows more

test and [ ] 
- Quote variables! 
- Quote parentheses! 
...

help test  - shows more

Redirections
============
>&2          directs std to error out
&> file      directs error and stdout to file
2>&1         directs error to stdout
2>&1 | tee ...

Variable Expansion
==================
\${#parameter}
              Parameter  length.
              
\${parameter:offset}
\${parameter:offset:length}
              Substring Expansion (offset is zero base; negative lengts - the value is used as an offset from the end of the value of parameter
              
\${parameter#word}
\${parameter##word}
              Remove matching prefix pattern (# - shortest; ## - longest)
              
\${parameter%word}
\${parameter%%word}
              Remove matching suffix pattern (% - shortest; %% - longest

\${!parameter}
             Indirect addressing
              

              
Words  of  the  form $'string' are treated specially.  The word expands to string, with backslash-escaped characters replaced as specified by the ANSI C standard.

Arrays
======

defines an indexed array use:
name=(value1 value2 value3) 
or with declare
declare -a name=()

To append a value to an indexed array use:
name+=(valuen)

To define a associative array use:
declare -A name=()
or with initialization
declare -A aa=( [key1]=value1 [key2]=value2 )

To set a specific element use:
name[index]=value
or
name[key]=value

To get the value of an specific element use:
\${name[index]}
or
\${name[key]}

To get the number of elements in an array use:
\${#name[@]} or \${#name[*]}

The expression 
\${#name[index/key]} gives the length of the specified element.

To get all values of an indexed array use:
\${name[@]} or \${name[*]}

To get all keys of an associative array use:
\${!name[@]} or \${!name[*]}

If the word is double-quoted, \${name[*]} expands to a single word with the value of 
each array member separated by the first character of the IFS special variable, and 
\${name[@]} expands each element of name to a separate word.

Pattern matching
=================
In a range e.g. [0-9a-zA-z_]  there must be:
 ] must be in the first place without ^
 - must be first or last place
 [*?. are not special here

EOF
}
