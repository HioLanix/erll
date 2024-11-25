-module(dz6). 
 %%  c:/Users/Hio/Desktop/erll/дз6/
-export([gen/0]). 
-record(student, {name, age, gender, course, group}).
gen()->
    #student{name="Biba", age=crypto:rand_uniform(1,100), gender="male", course=crypto:rand_uniform(1,5) , group=crypto:rand_uniform(1,4)}.
    


 

   