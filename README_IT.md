# Prolog URI Parser v2
> Un Parser per stringhe URI semplificate scritto in SWI-Prolog.

Il programma permette di effettuare il parsing di stringhe URI che seguono una grammatica semplificata rispetto allo standard RFC3986.
Esso controlla che la stringa rispetti la grammatica, e se così è ne restituisce le componenti principali, altrimenti restituisce false.

## Table of Contents

- [Grammatica](#grammatica)
	- [Sintassi Speciali](#sintassi-speciali)
	- [Componenti di un URI](#componenti-di-un-uri)
- [Predicati](#predicati)
	- [uri_parse/2](#uri_parse2)
	- [uri_display/2 e uri_display/1](#uri_display2-e-uri_display1)
- [DCG (Definite Clause Grammar)](#dcg-definite-clause-grammar)
  - [uridcg](#uridcg)
  - [uripath, uriquery, urifragment e urizospath (mail_host, news_host e auth_port)](#uripath-uriquery-urifragment-e-urizospath-mail_host-news_host-e-auth_port)
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
  - [id44 (e rest_id44)](#id44-e-rest_id44)
  - [id8](#id8)
  - [id_alnum](#id_alnum)
- [Testing](#testing)
  - [Struttura del file di test](#struttura-del-file-di-test)
  - [Running Tests](#running-tests)


## Grammatica

La grammatica semplificata rispettata è la seguente:

```css
URI ::= URI1 | URI2

URI1 ::= scheme ‘:’ [authorithy] [[‘/’] [path] [‘?’ query] [‘#’ fragment]]
URI2 ::= scheme ‘:’ scheme-syntax

scheme ::= <identificatore>
authorithy ::= ‘//’ [userinfo ‘@’] host [‘:’ port]
userinfo ::= <identificatore>
host ::= <identificatore-host> [‘.’ <identificatore-host>]* | indirizzo-IP
port ::= <digit>+
indirizzo-IP ::= <NNN.NNN.NNN.NNN – con N un digit e NNN < 255>
path ::= <identificatore> [‘/’ <identificatore>]* [‘/’]
query ::= <caratteri senza ‘#’>+
fragment ::= <caratteri>+
<identificatore> ::= <caratteri senza ‘/’, ‘?’, ‘#’, ‘@’, e ‘:’>+
<identificatore-host> ::= <caratteri senza ‘.’, ‘/’, ‘?’, ‘#’, ‘@’, e ‘:’>+
<digit> ::= ‘0’ |‘1’ |‘2’ |‘3’ |‘4’ |‘5’ |‘6’ |‘7’ |‘8’ |‘9’

scheme-syntax ::= <sintassi speciale>
```

### Sintassi Speciali

URI2 rappresenta la grammatica da rispettare per alcuni schemi speciali. Il parsing delle stringhe è case-insensitive per cui schemi come _"MaIlTo"_ o _"MAILTO"_ sono riconosciuti come schemi speciali _"mailto"_ e così via.

**Schemi speciali:**

_mailto_:

```css
scheme-syntax ::= [userinfo [‘@’ host]]
```

_news_:

```css
scheme-syntax ::= [host]
```

_tel_ e _fax_:

```css
scheme-syntax ::= [userinfo]
```

_zos_:

```css
scheme-syntax ::= [authorithy] [[‘/’] zospath [‘?’ query] [‘#’ fragment]]
zospath ::= <id44> [‘(’ <id8> ‘)’]
id44 ::= (<caratteri alfanumerici> | ‘.’)+
id8 ::= (<caratteri alfanumerici>)+

---

dove sia id44 che id8 devono iniziare con un carattere alfabetico e id44 non può terminare con un punto.
Inoltre la lunghezza di id44 non deve superare i 44 caratteri e quella di id8 non deve superare gli 8.
```

### Componenti di un URI

Le componenti principali di un URI che vengono restituite dal programma sono, in ordine:

`Scheme, Userinfo, Host, Port, Path, Query, Fragment`

Nella struttura restituita dal programma, i campi mancanti sono restituiti come lista vuota `[]`, invece se presenti sono restituiti come atomi, fatta eccezione per la port, che è restituita come numero intero (e come 80 di default in caso non sia presente).

Nota: port è restituito a 80 di default anche nei casi in cui authority non è presente del tutto e negli schemi speciali che non la considerano.

## Predicati

### uri_parse/2

`uri_parse` è il predicato principale con il quale è possibile effettuare il parsing di una stringa.
Esso infatti presenta 2 argomenti, `URIString` e `URI`; il primo è la stringa che si vuole parsare, mentre il secondo è la struttura risultante contenente le componenti dell'URI.
Il predicato non è invertibile ma può rispondere a query con termini parzialmente istanziati come da consegna.

Funzionamento:

1. Il predicato controlla innanzitutto che la Stringa passatagli sia effettivamente una stringa.
2. Dopodichè converte la stringa in una lista di caratteri utilizzando il predicato `string_chars/2`.
3. A questo punto utilizzando `phrase/2`, passa la lista di caratteri ad `uridcg` che si occupa del vero e proprio parsing e dunque del controllo del rispetto della grammatica.
4. Infine, se la stringa passa il controllo, viene restituita la struttura risultante, nella forma

`uri(Scheme, Userinfo, Host, Port, Path, Query, Fragment).`

### uri_display/2 e uri_display/1

Gli `uri_display` sono 2 predicati che permettono la stampa di una struttura URI su uno stream.

`uri_display/2` ha 2 argomenti, la struttura URI e lo stream su cui deve stampare, e sfrutta il predicato `format/3` per stampare sullo stream che gli viene passato le componenti dell'URI in una maniera in cui sono chiaramente distinguibili.

`uri_display/1` invece richiama semplicemente il predicato a 2 argomenti, passandogli come stream `current_output` che altro non è che il terminale di SWI-Prolog, permettendo così una più immediata stampa su terminale.

I predicati non controllano la validità delle componenti della struttura che gli viene passata, ma controllano che la struttura passata sia della forma indicata e abbia quindi i 7 elementi necessari per la stampa.

E' possibile comunque utilizzarli in combinazione con il predicato `uri_parse` in questa maniera

`uri_parse(URIString, URI), uri_display(URI).`

Passandogli un URI sottoforma di stringa. In questo modo `uri_parse` si occuperà di controllare la validità della stringa, e se così fosse, `uri_display` effettuerebbe la stampa della struttura risultante. Se la stringa non fosse valida, verrà invece restituito false.

Nota: utilizzando `uri_display_1` verrà effettuata su terminale anche la stampa effetto collaterale di `uri_parse`.

## DCG (Definite Clause Grammar)

Come detto in precedenza, il predicato principale sfrutta il predicato `phrase/2` per passare la lista di caratteri ottenuta dalla stringa a `uridcg` che è una DCG.

Una DCG, o _Definite Clause Grammar_, non è altro che "zucchero sintattico" per le normali _Definite Clauses_ in Prolog, e infatti possono volendo essere tradotte in normali predicati.

Per esempio, le regole:

```prolog
a --> a, b.
a --> [a].
b --> [b].
```
Possono essere tradotte in
```prolog
a(A, C) :- a(A, B), b(B, C).
a([a|X], X).
b([b|X], X).
```

Esse però semplificano di molto la scrittura e la leggibilità di un programma, e sono particolarmente utili per descrivere una grammatica e in generale quindi anche per effettuare parsing di stringhe.

Le regole di una DCG si compongono, come nell'esempio, di una testa (head) e di un corpo (body), separati da "-->".
Nel corpo possono essere presenti altre regole, caratteri terminali racchiusi tra parentesi quadre (`[]`), e tra parentesi graffe (`{}`) è possibile aggiungere del normale codice Prolog.

Nel programma, le DCG oltre ad occuparsi di controllare se la lista di caratteri rispetti la grammatica da loro definita, restituiscono anche ciò che la rispetta (eccetto i delimitatori), facendo in questo modo gran parte del lavoro e ricostruendo tramite backtracking gli elementi necessari.

E' presente inoltre l'utilizzo di numerosi green cut per evitare che la query cerchi di unificare con altri predicati e restituisca un solo risultato.

### uridcg
Questa regola definisce la grammatica di URI1 e URI2, ne controlla la correttezza su una lista di caratteri e ne restituisce la struttura

	uri(Scheme, Userinfo, Host, Port, Path, Query, Fragment)

Per quando riguarda URI1 sono definiti 2 predicati, uno in cui è presente il blocco `[[‘/’] [path] [‘?’ query] [‘#’ fragment]]` e uno senza.
L'opzionalità di `[authority]` è invece gestita in authority stessa.
Inoltre essa fa uso del predicato aggiuntivo `not_special/1` per controllare che lo `scheme` parsato non appartenga agli schemi speciali.

Per quanto riguarda URI2 sono invece presenti molteplici predicati per ogni schema speciale, che definiscono la loro scheme-syntax e che sfruttano il predicato `downcase_atom/2` per convertire temporaneamente lo scheme ottenuto in lowercase e controllare se è uguale o meno al corrispondente schema speciale.
L'utilizzo del predicato è necessario per implementare il case-insensitive del parsing.

### uripath, uriquery, urifragment e urizospath (mail_host, news_host e auth_port)
Sono DCG intermedie necessarie per la conversione di path, query e fragment in atomo attraverso l'utilizzo del predicato `atom_chars/2`, ma anche per il controllo della presenza di queste ultime.
I predicati _uriquery_ e _urifragment_ controllano anche la presenza rispettivamente dei caratteri '?' e '#' prima di query e fragment.
Infine se presenti richiamano le DCG di _path_, _query_ e _fragment_ per controllarne la correttezza e l'assenza di caratteri non validi.

L'opzionalità dello slash '/' nella grammatica di URI1 (e dunque anche in quella di URI2 specifica per zos) è gestita nei predicati _uripath_ e _urizospath_. 

Se invece non sono presenti, ogni predicato ha una versione che se incontra la lista vuota, restituisce la lista vuota.

Lo stesso ragionamento vale per _mail_host_ e _news_host_ per i loro rispettivi schemi speciali e per _auth_port_ per quanto riguarda authority. L'unica differenza è l'utilizzo di `number_chars/2` in _auth_port_ per restituire la porta come numero intero invece che atomo.

### scheme
Semplicemente richiama _id_ e converte il risultato di _id_ in atomo utilizzando nuovamente atom_chars.

### authority
Sono implementati 3 predicati:
- i primi 2 rappresentano la grammatica di authority, in uno è presente userinfo mentre nell'altro no (l'opzionalità di [':' port] è gestita in _auth_port_)
- l'ultimo invece unifica con il caso in cui authority non sia presente e sia quindi "vuoto".

### userinfo
Si comporta esattamente come scheme.

### host
Ha 3 predicati:
- il primo controlla se l'host per caso unifica con _ip_, in tal caso il green cut evita che unifichi con i successivi
- gli altri 2 invece definiscono ricorsivamente l'altra definizione di host basata su _id_host_, motivo per cui è necessario ricorrere a una `flatten/2` per ottenere una singola lista di caratteri, dato che host stesso restituisce una lista di caratteri.

### port
Definisce ricorsivamente port come una sequenza di _digit_.

### ip
Controlla che la lista di caratteri rispetti la grammatica di 4 triplette di _digit_ separate da punti come da definizione.
Utilizza inoltre il predicato `check_ip/1` che a sua volta si appoggia su `number_string/2` per verificare se ogni tripletta convertita in numero intero sia < = 255.

Nota: `number_string` funziona anche su liste di caratteri, come da [Documentazione ufficiale SWI-Prolog sezione 5.2.2](https://www.swi-prolog.org/pldoc/man?section=string-predicates).
In ogni caso si sarebbe potuto usare una conversione su più step utilizzando prima `string_chars` sulla lista di caratteri e poi `number_string` sulla stringa ottenuta.

### path
Definisce ricorsivamente il path e come per _host_ fa uso di `flatten/2` per evitare liste innestate.

### query
Definisce ricorsivamente query e controlla che ogni carattere sia diverso da '#' e quindi valido.

### fragment
Semplicemente scansiona e ripassa la lista di caratteri così com'è, essendo valido ogni carattere.

### id
Definisce ricorsivamente id e inoltre sfrutta `is_id/1` per controllare che i caratteri parsati siano validi e rispettino la grammatica.

### id_host
Si comporta allo stesso modo di _id_ e fa uso di `is_id_host/1` per controllarne la validità.

### digit
Controlla che il carattere passato sia una cifra da 0 a 9 attraverso il predicato `is_digit/1`.

### zospath
Ha 2 predicati, uno con la presenza dell'id8 tra parentesi tonde e l'altro con solo id44.
Inoltre sempre in zospath viene controllata la giusta lunghezza di id44 e id8, e vengono utilizzati `flatten/2` e `atom_chars/2` per ottenere una singola lista di caratteri e convertirla in atomo.

### id44 (e rest_id44)
Il predicato in sè controlla solamente che il primo carattere sia un carattere alfabetico utilizzando il predicato `char_type/2` con secondo argomento `alpha`, dopodichè se sono presenti altri caratteri richiama _rest_id44_, che controlla che il resto sia formato da caratteri alfanumerici (tramite _id_alnum_) o punti '.'.
La definizione ricorsiva di _rest_id44_ non permette che la stringa termini con un punto, inoltre utilizza `flatten/2` sempre per evitare liste innestate.

### id8
Controlla che il primo carattere sia alfabetico nuovamente utilizzando `char_type/2` con `alpha`, infine controlla che il resto se presente sia alfanumerico tramite _id_alnum_.
Utilizza `flatten/2` per evitare liste innestate.

### id_alnum
Controlla che la lista sia formata da solo caratteri alfanumerici utilizzando il predicato `char_type/2` cone secondo argomento `alnum`. Data la definizione ricorsiva utilizza `flatten/2` per ottenere una lista di soli caratteri, priva di liste innestate.

## Testing

Il testing è effettuato tramite test automatici scritti seguendo la documentazione sui [Prolog Unit Tests](https://www.swi-prolog.org/pldoc/doc_for?object=section(%27packages/plunit.html%27)).

### Struttura del file di test
Il file di test `uri-parse.plt` contiene 1665 casi test che il programma passa con esito positivo.
E' possibile personalizzare e scrivere il proprio file di test in estensione `.plt` partendo dal file già presente.

All'inizio del codice principale del progetto `uri-parse.pl` è stata aggiunta la linea di codice
```prolog
:- module(uri_parse, [uri_parse/2]).
```

Per poter avviare i test.

I test con esito positivo sono del tipo
```prolog
test(true_scheme) :- uri_parse("s:", uri('s', [], [], 80, [], [], [])).
```

E quelli con esito negativo
```prolog
test(false_scheme) :- \+ uri_parse("s", _).
```

Come è possibile vedere viene utilizzato l'operatore `\+` che restiituisce `true.` quando non è possibile unificare e risolvere un test sul predicato (e il terminale restituisce dunque `false.`).

La struttura generale è quindi
```prolog
test(id_test) :- predicato(input, risultato). | \+ predicato(input, _).
```

Dove:
- `id_test` è il nome assegnato al test, utile per capire quali test non passano
- `predicato` è il nome del predicato su cui si sta effetuando il test
- `input` è l'input che prende il predicato
- `risultato` è il risultato corretto che si ottiene con l'input passato
- `\+` è usato quando non si può ottenere un risultato con l'input passato (`_`)

### Running Tests
Per runnare i test personalizzati, assicurarsi che il file `.pl` e il file di test `.plt` siano nella stessa directory.

Dopodichè segnatevi il percorso della directory in cui avete messo il programma e i file di test, che su windows sarà del tipo
```sh
C:/Users/.../Directory
```

A questo punto aprite SWI-Prolog e lanciate il comando:
```prolog
working_directory(OldDir, 'NewDir').
```
Che vi permetterà di spostarvi nella nuova directory `NewDir`.
`NewDir` va ovviamente sostituito con il percorso della cartella dove avete messo i file e che avete salvato in precedenza.

Dopodichè lanciate i seguenti comandi:
```prolog
['uri-parse'].

load_test_files([]).

run_tests.
```

In alternativa si può anche lanciare un singolo comando unico:
```prolog
['uri-parse'], load_test_files([]), run_tests.
```

_Nota: in questo caso il comando è `['uri-parse']`, ma più in generale sarebbe `['test_file_name']` con il nome del vostro file di test `.plt` come `test_file_name`._

![Alt text](Tests.png?raw=true "Tests")