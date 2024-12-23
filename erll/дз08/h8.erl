-module(h8).
 %%             c:/Users/Hio/Desktop/erll/дз08/              /mnt/c/Users/Hio/Desktop/erll/дз08
-export([start/0, create_table/0, insert_data/0, retrieve_data/0, delete_table/0, stop/1]).
%% Start the ODBC connection
start() ->
odbc:start(),
%% {ok, Ref} = odbc:connect("DSN=hio;UID=hio;PWD=1101", []),
{ok, Ref} = odbc:connect("DSN=hio;PWD=1101", []),
Ref.
%% Create a table
create_table() ->
Ref = start(),
odbc:sql_query(Ref, "CREATE TABLE students (id INT PRIMARY KEY, name VARCHAR(50))"),
io:format("Table Created"),
stop(Ref).
%% Insert data into the table
insert_data() ->
Ref = start(),
odbc:param_query(Ref, "INSERT INTO students (id, name) VALUES (?, ?)", [{sql_integer, [2,3,4]}, {{sql_varchar,20}, ["Ваня", "Аня", "Петя"]}]),
io:format("Data inserted"),
stop(Ref).
%% Retrieve data from the table
retrieve_data() ->
Ref = start(),
{selected, _, Rows} = odbc:sql_query(Ref, "SELECT * FROM students"),
io:format("Users: ~p~n", [Rows]),
stop(Ref).
%% Stop the ODBC connection
stop(Ref) ->
odbc:disconnect(Ref).
delete_table() ->
Ref = start(),
odbc:sql_query(Ref, "DROP TABLE students"),
io:format("Table Deleted"),
stop(Ref).

