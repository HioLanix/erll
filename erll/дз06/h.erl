-module(h). 

 %%  c:/Users/Hio/Desktop/дз6/
-export([gen/1,
        rand/0,
        mysort/1,
        stsort/1,
        mysort_time/1,
        stsort_time/1]). 
-record(student, {name, age, gender, course, group}).
gen(0) -> 
   []; 
   
  gen(N) when N > 0 -> 
   [rand()|gen(N-1)].

   rand() ->
   case crypto:rand_uniform(1,16) of 
    1 ->#student{name="Biba", age=crypto:rand_uniform(1,100), gender="male", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    2 ->#student{name="Boba", age=crypto:rand_uniform(1,100), gender="male", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    3 ->#student{name="Mark", age=crypto:rand_uniform(1,100), gender="male", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    4 ->#student{name="Anya", age=crypto:rand_uniform(1,100), gender="female", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    5 ->#student{name="Danya", age=crypto:rand_uniform(1,100), gender="male", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    6 ->#student{name="Masha", age=crypto:rand_uniform(1,100), gender="female", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    7 ->#student{name="Polina", age=crypto:rand_uniform(1,100), gender="female", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    8 ->#student{name="Katya", age=crypto:rand_uniform(1,100), gender="female", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    9 ->#student{name="Nastya", age=crypto:rand_uniform(1,100), gender="female", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    10->#student{name="Mr.Anderson", age=crypto:rand_uniform(1,100), gender="male", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    11->#student{name="Alexandr", age=crypto:rand_uniform(1,100), gender="male", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    12->#student{name="Alexandra", age=crypto:rand_uniform(1,100), gender="female", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    13->#student{name="Svyatogor", age=crypto:rand_uniform(1,100), gender="male", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    14->#student{name="Alina", age=crypto:rand_uniform(1,100), gender="female", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    15->#student{name="Maxim", age=crypto:rand_uniform(1,100), gender="male", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)};
    16->#student{name="Ksenya", age=crypto:rand_uniform(1,100), gender="female", course=crypto:rand_uniform(1,5), group=crypto:rand_uniform(1,4)}
end.

mysort([]) -> [];
                   %%mysort([]) -> mysort([X || X <- T, X#student.age < 50])  ++ mysort([X || X <- T, X#student.age >= 50]).
mysort([_] = List) -> List;
mysort([H|T]) -> 
    mysort([X || X <- T, X#student.age >=H#student.age]) ++ mysort([X || X <- T, X#student.age <H#student.age] ).


    

stsort(Students) -> 
    lists:sort(Students).
   
 mysort_time(N) ->
    A=gen(N),
StartTime = erlang:monotonic_time(microsecond),
Result = mysort(A),
EndTime = erlang:monotonic_time(microsecond),
ElapsedTime = erlang:convert_time_unit(EndTime - StartTime, native, microsecond),
io:format("Mysort Execution time: ~p microseconds~n", [ElapsedTime]),
Result.

stsort_time(N) ->
    A=gen(N),
StartTime = erlang:monotonic_time(microsecond),
Result = stsort(A),
EndTime = erlang:monotonic_time(microsecond),
ElapsedTime = erlang:convert_time_unit(EndTime - StartTime, native, microsecond),
io:format("Stsort Execution time: ~p microseconds~n", [ElapsedTime]),
Result.


    

