%% -*- Mode: Prolog -*-

% uri-parse.pl

:- module(uri_parse, [uri_parse/2]).

% uri_parse/2
uri_parse(URIString, URI) :-
    string(URIString),
    string_chars(URIString, URICharsList),
    phrase(uridcg(X), URICharsList),
    URI = X.

% uri_display/1
uri_display(URI) :-
    uri_display(URI, current_output).

% uri_display/2
uri_display(URI, Stream) :-
    URI = uri(S, U, H, Port, Path, Q, F),
    format(Stream, '~n~w~n', "Display URI:"),
    format(Stream, '~t~4+~w~w~n', ["Scheme ==> ", S]),
    format(Stream, '~t~4+~w~w~n', ["Userinfo ==> ", U]),
    format(Stream, '~t~4+~w~w~n', ["Host ==> ", H]),
    format(Stream, '~t~4+~w~w~n', ["Port ==> ", Port]),
    format(Stream, '~t~4+~w~w~n', ["Path ==> ", Path]),
    format(Stream, '~t~4+~w~w~n', ["Query ==> ", Q]),
    format(Stream, '~t~4+~w~w~n~n', ["Fragment ==> ", F]).

%%% uridcg

% --- URI1

uridcg(uri(S, U, H, Port, Path, Q, F)) -->
    scheme(S),
    [:],
    authority(U, H, Port),
    uripath(Path),
    uriquery(Q),
    urifragment(F),
    { not_special(S)
    }, !.
uridcg(uri(S, U, H, P, [], [], [])) -->
    scheme(S),
    [:],
    authority(U, H, P),
    { not_special(S)
    }, !.

% --- URI2

% mailto
uridcg(uri(S, U, H, 80, [], [], [])) -->
    scheme(S),
    [:],
    userinfo(U),
    mail_host(H),
    { downcase_atom(S, Sd),
      Sd = mailto
    }, !.
uridcg(uri(S, [], [], 80, [], [], [])) -->
    scheme(S),
    [:],
    { downcase_atom(S, Sd),
      Sd = mailto
    }, !.

% news
uridcg(uri(S, [], H, 80, [], [], [])) -->
    scheme(S),
    [:],
    news_host(H),
    { downcase_atom(S, Sd),
      Sd = news
    }, !.

% tel
uridcg(uri(S, U, [], 80, [], [], [])) -->
    scheme(S),
    [:],
    userinfo(U),
    { downcase_atom(S, Sd),
      Sd = tel
    }, !.
uridcg(uri(S, [], [], 80, [], [], [])) -->
    scheme(S),
    [:],
    { downcase_atom(S, Sd),
      Sd = tel
    }, !.

% fax
uridcg(uri(S, U, [], 80, [], [], [])) -->
    scheme(S),
    [:],
    userinfo(U),
    { downcase_atom(S, Sd),
      Sd = fax
    }, !.
uridcg(uri(S, [], [], 80, [], [], [])) -->
    scheme(S),
    [:],
    { downcase_atom(S, Sd),
      Sd = fax
    }, !.

% zos
uridcg(uri(S, U, H, Port, Path, Q, F)) -->
    scheme(S),
    [:],
    authority(U, H, Port),
    urizospath(Path),
    uriquery(Q),
    urifragment(F),
    { downcase_atom(S, Sd),
      Sd = zos
    }, !.
uridcg(uri(S, U, H, P, [], [], [])) -->
    scheme(S),
    [:],
    authority(U, H, P),
    { downcase_atom(S, Sd),
      Sd = zos
    }.

% --- Additional predicates used in uridcg

% uripath
uripath(P) --> [/], path(X), {atom_chars(P, X)}.
uripath(P) --> path(X), {atom_chars(P, X)}.
uripath([]) --> [/], !.
uripath([]) -->[].

% uriquery
uriquery(Q) --> [?], query(X), {atom_chars(Q, X)}.
uriquery([]) --> [].

% urifragment
urifragment(F) --> [#], fragment(X), {atom_chars(F, X)}.
urifragment([]) --> [].

% urizospath
urizospath(X) --> [/], zospath(X), !.
urizospath(X) --> zospath(X).
urizospath([]) --> [/], !.
urizospath([]) -->[].


% not_special/1
not_special(S) :-
    downcase_atom(S, Sd),
    Sd \= mailto,
    Sd \= news,
    Sd \= tel,
    Sd \= fax,
    Sd \= zos.

% mail_host
mail_host(HS) --> [@], host(H), {atom_chars(HS, H)}.
mail_host([]) --> [].

% news_host
news_host(HS) --> host(H), {atom_chars(HS, H)}.
news_host([]) --> [].

% zospath
zospath(P) -->
    id44(X),
    ['('],
    id8(Y),
    [')'],
    { length(X, L44),
      L44 =< 44,
      length(Y, L8),
      L8 =< 8,
      flatten([X, '(', Y, ')'], Z),
      atom_chars(P, Z)
    }, !.
zospath(P) -->
    id44(X),
    { length(X, L44),
      L44 =< 44,
      flatten(X, Z),
      atom_chars(P, Z)
    }.

% id44
id44([X | Xs]) --> [X], rest_id44(Xs), {char_type(X, alpha)}, !.
id44([X | []]) --> [X], {char_type(X, alpha)}.

% rest_id44
rest_id44(X) -->
    id_alnum(A),
    [.],
    rest_id44(B),
    { flatten([A, '.', B], X)
    }, !.
rest_id44(X) --> [.], rest_id44(B), {flatten(['.' | B], X)}, !.
rest_id44(X) --> id_alnum(X).

% id8
id8(A) --> [X], id_alnum(Y), {char_type(X, alpha), flatten([X | Y], A)}, !.
id8([X | []]) --> [X], {char_type(X, alpha)}.

% id_ alnum
id_alnum(A) -->
    [X],
    id_alnum(Y),
    { char_type(X, alnum),
      flatten([X | Y], A)
    }, !.
id_alnum([X | []]) --> [X], {char_type(X, alnum)}.

% --- Rest of the DCG grammar rules

% scheme
scheme(S) --> id(X), {atom_chars(S, X)}.

% authority
authority(U, HS, P) -->
    [/],
    [/],
    userinfo(U),
    [@],
    host(H),
    auth_port(P),
    { atom_chars(HS, H)
    }, !.
authority([], HS, P) -->
    [/],
    [/],
    host(H),
    auth_port(P),
    { atom_chars(HS, H)
    }, !.
authority([], [], 80) --> [].

% auth_port/1
auth_port(P) --> [:], port(X), {number_chars(P, X)}.
auth_port(80) --> [].

% userinfo
userinfo(U) --> id(X), {atom_chars(U, X)}.

% host
host(X) --> ip(X), !.
host(Z) --> id_host(X), [.], host(Y), {flatten([X, '.', Y], Z)}, !.
host(X) --> id_host(X).

% port
port([X | Y]) --> digit(X), port(Y), !.
port([X | []]) --> digit(X).

% ip
ip(X) -->
    digit(A),
    digit(B),
    digit(C),
    [.],
    digit(D),
    digit(E),
    digit(F),
    [.],
    digit(G),
    digit(H),
    digit(I),
    [.],
    digit(J),
    digit(K),
    digit(L),
    { X = [A, B, C, ., D, E, F, ., G, H, I, ., J, K, L],
      check_ip([A, B, C]),
      check_ip([D, E, F]),
      check_ip([G, H, I]),
      check_ip([J, K, L])
    }.

% check_ip/1
check_ip(C) :-
    number_string(N, C),
    N =< 255.

% path
path(P) --> id(X), [/], path(Y), {flatten([X, '/', Y], P)}, !.
path(P) --> id(X), [/], {flatten([X, '/'], P)}, !.
path(X) --> id(X).

% query
query([X | Y]) --> [X], query(Y), {X \= '#'}, !.
query([X | []]) --> [X], {X \= '#'}.

% fragment
fragment([X | Y]) --> [X], fragment(Y), !.
fragment([X | []]) --> [X].

% id
id([X | Y]) --> [X], id(Y), {is_id(X)}, !.
id([X | []]) --> [X], {is_id(X)}.

% is_id/1
is_id(L) :-
    L \= '/',
    L \= '?',
    L \= '#',
    L \= '@',
    L \= ':'.

% id_host
id_host([X | Y]) --> [X], id_host(Y), {is_id_host(X)}, !.
id_host([X | []]) --> [X], {is_id_host(X)}.

% is_id_host/1
is_id_host(L) :-
    L \= '.',
    L \= '/',
    L \= '?',
    L \= '#',
    L \= '@',
    L \= ':'.

% digit
digit(X) --> [X], {is_digit(X)}.

% end of file -- uri-parse.pl
