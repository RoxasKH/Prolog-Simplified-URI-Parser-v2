# Prolog URI Parser v2
> A simplified URI strings parser written in SWI-Prolog.

The program allows you to parse URI strings that follow a simplified grammar compared to the RFC3986 standard.
It checks that the string matches the grammar, and if so it returns its main components, otherwise it returns false.

## Table of Contents

- [Grammar](#grammar)
  - [Special Syntaxes](#special-syntaxes)
  - [Components of a URI](#components-of-a-uri)
- [Predicates](#predicates)
  - [uri_parse/2](#uri_parse2)
  - [uri_display/2 and uri_display/1](#uri_display2-and-uri_display1)
- [DCG (Definite Clause Grammar)](#dcg-definite-clause-grammar)
  - [uridcg](#uridcg)
  - [uripath, uriquery, urifragment and urizospath (mail_host, news_host and auth_port)](#uripath-uriquery-urifragment-and-urizospath-mail_host-news_host-and-auth_port)
  - [scheme](#scheme)
  - [authority](#authority)
  - [userinfo](#userinfo)
  - [host](#host)
  - [port](#port)
  - [ip](#ip)
  - [path](#path)
  - [query](#query)
  - [id](#id)
  - [id_host](#id_host)
  - [digit](#digit)
  - [zospath](#zospath)
  - [id44 (and rest_id44)](#id44-and-rest_id44)
  - [id8](#id8)
  - [id_alnum](#id_alnum)
- [Testing](#testing)
  - [Test files structure](#test-files-structure)
  - [Running Tests](#running-tests)


## Grammar

The respected simplified grammar is as follows:

```css
URI ::= URI1 | URI2

URI1 ::= scheme ‘:’ [authorithy] [[‘/’] [path] [‘?’ query] [‘#’ fragment]]
URI2 ::= scheme ‘:’ scheme-syntax

scheme ::= <identifier>
authorithy ::= ‘//’ [userinfo ‘@’] host [‘:’ port]
userinfo ::= <identifier>
host ::= <host-identifier> [‘.’ <host-identifier>]* | IP-address
port ::= <digit>+
IP-address ::= <NNN.NNN.NNN.NNN - with N one digit and NNN < 255>
path ::= <identifier> [‘/’ <identifier>]* [‘/’]
query ::= <characters excluding ‘#’>+
fragment ::= <characters>+
<identifier> ::= <characters excluding ‘/’, ‘?’, ‘#’, ‘@’, and ‘:’>+
<host-identifier> ::= <characters excluding ‘.’, ‘/’, ‘?’, ‘#’, ‘@’, and ‘:’>+
<digit> ::= ‘0’ | ‘1’ | ‘2’ | ‘3’ | ‘4’ | ‘5’ | ‘6’ | ‘7’ | ‘8’ | ‘9’

scheme-syntax ::= <special syntax>
```

### Special Syntaxes

URI2 represents the grammar to be respected for some special schemes. String parsing is case-insensitive so patterns like _ "MaIlTo" _ or _ "MAILTO" _ are recognized as special patterns _"mailto"_ and so on.

**Special schemes:**

_mailto_:

```css
scheme-syntax ::= [userinfo ['@' host]]
```

_news_:

```css
scheme-syntax ::= [host]
```

_tel_ and _fax_:

```css
scheme-syntax ::= [userinfo]
```

_zos_:

```css
scheme-syntax ::= [authorithy] [[‘/’] zospath [‘?’ query] [‘#’ fragment]]
zospath ::= <id44> [‘(’ <id8> ‘)’]
id44 ::= (<alphanumeric characters> | ‘.’) +
id8 ::= (<alphanumeric characters>) +

---

where both id44 and id8 must start with an alphabetic character and id44 cannot end with a period.
Furthermore, the length of id44 must not exceed 44 characters and that of id8 must not exceed 8.
```

### Components of a URI

The main components of a URI that are returned by the program are, in order:

`Scheme, Userinfo, Host, Port, Path, Query, Fragment`

In the structure returned by the program, the missing fields are returned as an empty list `[]`, instead if present they are returned as atoms, except for the port, which is returned as an integer (and as 80 by default if it's not present).

Note: port is returned as 80 by default even in cases where authority is not present at all and in special schemes that do not consider it.

## Predicates

### uri_parse/2

`uri_parse` is the main predicate with which you can parse a string.
In fact, it has 2 arguments, `URIString` and `URI`; the first is the string you want to parse, while the second is the resulting structure containing the components of the URI.
The predicate is not invertible but can answer queries with partially instantiated terms as per delivery.

Operation:

1. The predicate first checks that the String passed to it is actually a string.
2. It then converts the string to a character list using the `string_chars/2` predicate.
3. At this point, using `phrase/2`, it passes the list of characters to `uridcg` which takes care of the actual parsing and therefore of checking compliance with the grammar.
4. Finally, if the string passes the check, the resulting structure is returned, in the form

`uri(Scheme, Userinfo, Host, Port, Path, Query, Fragment).`

### uri_display/2 and uri_display/1

The `uri_display` are 2 predicates that allow the printing of a URI structure on a stream.

`uri_display/2` has 2 arguments, the URI structure and the stream it should print to, and uses the `format/3` predicate to print the URI components on the stream it is passed in a way that they are clearly distinguishable .

`uri_display/1` instead simply calls the predicate with 2 arguments, passing it `current_output` as a stream which is nothing more than the terminal of SWI-Prolog, thus allowing a more immediate printing on the terminal.

The predicates do not check the validity of the components of the structure that is passed to them, but they check that the passed structure is of the indicated form and therefore has the 7 elements necessary for printing.

However, it is possible to use them in combination with the `uri_parse` predicate in this way

`uri_parse(URIString, URI), uri_display(URI) .`

Passing it a URI in the form of a string. This way `uri_parse` will take care of checking the validity of the string, and if so,` uri_display` would print the resulting structure. If the string is invalid, false will be returned instead.

Note: using `uri_display_1` will also print side effect of `uri_parse` on the terminal.

## DCG (Definite Clause Grammar)

As mentioned earlier, the main predicate uses the `phrase/2` predicate to pass the list of characters obtained from the string to `uridcg` which is a DCG.

A DCG, or _Definite Clause Grammar_, is nothing more than "syntactic sugar" for the normal _Definite Clauses_ in Prolog, and in fact they can be translated into normal predicates if desired.

For example, the rules:

```prolog
a --> a, b.
a --> [a].
b --> [b].
```
They can be translated into
```prolog
a(A, C) :- a(A, B), b(B, C).
a([a|X], X).
b([b|X], X).
```

However, they greatly simplify the writing and readability of a program, and are particularly useful for describing a grammar and therefore also for parsing strings in general.

The rules of a DCG are made up, as in the example, of a head (head) and a body (body), separated by "-->".
In the body there may be other rules, terminal characters enclosed in square brackets (`[]`), and in braces (`{}`) you can add some normal Prolog code.

In the program, the DCGs in addition to checking if the list of characters respects the grammar they define, also return what respects it (except the delimiters), doing in this way much of the work and reconstructing the necessary elements by backtracking.

The use of numerous green cuts is also present to avoid that the query tries to unify with other predicates and returns only one result.

### uridcg
This rule defines the grammar of URI1 and URI2, checks their correctness on a list of characters and returns their structure

  uri(Scheme, Userinfo, Host, Port, Path, Query, Fragment)

As far as URI1 is concerned, 2 predicates are defined, one in which there is the block `[[‘/’] [path] [‘?’ Query] [‘#’ fragment]]` and one without.
The optionality of `[authority]` is instead managed in authority itself.
It also makes use of the additional predicate `not_special/1` to check that the parsed `scheme` does not belong to special schemes.

As for URI2, on the other hand, there are multiple predicates for each special scheme, which define their scheme-syntax and which exploit the `downcase_atom/2` predicate to temporarily convert the obtained scheme into lowercase and check if it is equal or not to the corresponding special scheme.
The use of the predicate is necessary to implement the case-insensitive of parsing.

### uripath, uriquery, urifragment and urizospath (mail_host, news_host and auth_port)
They are intermediate DCGs necessary for the conversion of path, query and fragment to atom through the use of the `atom_chars/2` predicate, but also for checking the presence of the latter.
The predicates _uriquery_ and _urifragment_ also respectively check for the presence of the '?' and '#' characters before query and fragment.
Finally, if present, they call the _path_, _query_ and _fragment_ DCGs to check their correctness and the absence of invalid characters.

The optionality of the slash '/' in URI1 grammar (and therefore also in that of URI2 specific to zos) is managed in the predicates _uripath_ and _urizospath_.

Instead, if they're not present, each predicate has a version which if it encounters the empty list, it returns the empty list.

The same reasoning applies to _mail_host_ and _news_host_ for their respective special schemes and for _auth_port_ for authority. The only difference is the use of `number_chars/2` in _auth_port_ to return the port as an integer instead of an atom.

### scheme
It simply calls _id_ and converts the result of _id_ to atom using atom_chars again.

### authority
3 predicates are implemented:
- the first 2 represent the authority grammar, in one there is userinfo while in the other no (the optionality of [':' port] is managed in _auth_port_)
- the last one unifies with the case in which authority is not present and is therefore "empty".

### userinfo
It behaves exactly like scheme.

### host
It has 3 predicates:
- the first checks if the host by chance unifies with _ip_, in this case the green cut prevents it from unifying with the following ones
- the other 2 instead recursively define the other host definition based on _id_host_, which is why you need to use a `flatten/2` to get a single list of characters, since host itself returns a list of characters.

### port
Recursively defines port as a sequence of _digit_.

### ip
Check that the list of characters respects the grammar of 4 triplets of _digit_ separated by periods as per definition.
It also uses the `check_ip/1` predicate which in turn relies on` number_string/2` to check if any triplet converted to integer is <= 255.

Note: `number_string` also works on character lists, as per [Official SWI-Prolog Documentation section 5.2.2](https://www.swi-prolog.org/pldoc/man?section=string-predicates).
In any case, a multi-step conversion could have been used using first `string_chars` on the character list and then `number_string` on the resulting string.

### path
It recursively defines the path and as for _host_ makes use of `flatten/2` to avoid nested lists.

### query
It recursively defines queries and checks that each character is different from '#' and therefore valid.

### fragment
Simply scan and go through the list of characters as is, each character being valid.

### id
It recursively defines id and also uses `is_id/1` to check that parsed characters are valid and respect grammar.

### id_host
It behaves the same as _id_ and uses `is_id_host/1` to check its validity.

### digit
Check that the character passed is a digit from 0 to 9 via the `is_digit/1` predicate.

### zospath
It has 2 predicates, one with the presence of id8 in round brackets and the other with only id44.
Also in zospath the correct length of id44 and id8 is checked, and `flatten/2` and `atom_chars/2` are used to get a single character list and convert it to atom.

### id44 (and rest_id44)
The predicate itself only checks that the first character is an alphabetic character using the predicate `char_type/2` with the second argument `alpha`, after which if other characters are present it calls _rest_id44_, which checks that the rest is made up of alphanumeric characters (via _id_alnum_) or dots '.'.
The recursive definition of _rest_id44_ does not allow the string to end with a period, it also uses `flatten/2` always to avoid nested lists.

### id8
Check that the first character is alphabetic again using `char_type/2` with `alpha`, finally check that the remainder if present is alphanumeric using _id_alnum_.
Use `flatten/2` to avoid nested lists.

### id_alnum
Check that the list is made up of only alphanumeric characters using the `char_type/2` predicate with the second argument `alnum`. Given the recursive definition it uses `flatten/2` to get a character-only list, with no nested lists.

## Testing

The testing is carried out through automatic tests written following the documentation on [Prolog Unit Tests](https://www.swi-prolog.org/pldoc/doc_for?object=section(%27packages/plunit.html%27)).

### Test files structure
The test file `uri-parse.plt` contains 1665 test cases which the program passes successfully.
It is possible to customize and write your own test file in `.plt` extension starting from the file already present.

The line of code has been added at the beginning of the main code of the `uri-parse.pl` project
```prolog
:- module(uri_parse, [uri_parse/2]).
```

In order to start the tests.

Successful tests are of the type
```prolog
test(true_scheme) :- uri_parse("s:", uri ('s', [], [], 80, [], [], [])).
```

And those with negative results
```prolog
test(false_scheme) :- \+ uri_parse("s", _).
```

As you can see, the `\+` operator is used which returns `true.` when it is not possible to unify and resolve a predicate test (and the terminal therefore returns `false.`).

The general structure is therefore
```prolog
test(test_id) :- predicate(input, result). | \+ predicate(input, _).
```

Where:
- `id_test` is the name given to the test, useful for understanding which tests fail
- `predicate` is the name of the predicate being tested
- `input` is the input that the predicate takes
- `result` is the correct result obtained with the passed input
- `\+` is used when a result cannot be obtained with the passed input (`_`)

### Running Tests
To run custom tests, make sure that the `.pl` file and the` .plt` test file are in the same directory.

Then mark the path of the directory where you put the program and the test files, which on windows will be of the type
```sh
C:/Users/.../Directory
```

At this point, open SWI-Prolog and run the command:
```prolog
working_directory(OldDir, 'NewDir').
```
Which will allow you to change to the new `NewDir` directory.
`NewDir` must obviously be replaced with the path of the folder where you put the files and that you have previously saved.

Then run the following commands:
```prolog
['uri-parse'].

load_test_files([]).

run_tests.
```

Alternatively, you can also run a single single command:
```prolog
['uri-parse'], load_test_files([]), run_tests.
```

_Note: in this case the command is `['uri-parse']`, but more generally it would be `['test_file_name']` with the name of your test file `.plt` as `test_file_name`._

![Alt text](Tests.png?Raw=true "Tests")
