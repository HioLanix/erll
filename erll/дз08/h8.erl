-module(h8).
 %%             c:/Users/Hio/Desktop/erll/дз08/              /mnt/c/Users/Hio/Desktop/erll/дз08
-export([start/0,
    create_table/0,
    insert_data/0,
    retrieve_data/0,
    delete_table/0,
    stop/1]).
%% Start the ODBC connection
-spec start() -> pid().
start() ->
odbc:start(),
%% {ok, Ref} = odbc:connect("DSN=hio;UID=hio;PWD=1101", []),
{ok, Ref} = odbc:connect("DSN=hio;PWD=1101", []),
Ref.

%% Create a table
-spec create_table() -> ok.
create_table() ->
Ref = start(),
odbc:sql_query(Ref, "CREATE TABLE students (id INT PRIMARY KEY, name VARCHAR(50))"),
io:format("Table Created"),
stop(Ref).
%% Insert data into the table
-spec insert_data() -> ok.
insert_data() ->
Ref = start(),
odbc:param_query(Ref, "INSERT INTO students (id, name) VALUES (?, ?)", [{sql_integer, [2,3,4]}, {{sql_varchar,20}, ["ivan", "anya", "PTRO"]}]),
io:format("Data inserted"),
stop(Ref).
%% Retrieve data from the table
-spec retrieve_data() -> ok.
retrieve_data() ->
Ref = start(),
{selected, _, Rows} = odbc:sql_query(Ref, "SELECT * FROM students"),
io:format("Users: ~p~n", [Rows]),
stop(Ref).

%% Stop the ODBC connection
-spec stop(pid) -> ok.
stop(Ref) ->
odbc:disconnect(Ref).

-spec delete_table() -> ok.
delete_table() ->
Ref = start(),
odbc:sql_query(Ref, "DROP TABLE students"),
io:format("Table Deleted~n", []),
stop(Ref).

