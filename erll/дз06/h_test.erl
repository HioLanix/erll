-module(h_test).



run_test() ->
    h:gen(10),
    h:mysort_time(100),
    h:stsort_time(100),
    h:mysort_time(1000),
    h:stsort_time(1000),
    h:mysort_time(10000),
    h:stsort_time(10000),
    h:mysort_time(100000),
    h:stsort_time(100000),
    ok.