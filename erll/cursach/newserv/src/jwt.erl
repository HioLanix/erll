-module(jwt).
-export([encode/3, encode/4, find_issuer_data/2, now_secs/0]).
%%      /mnt/c/Users/Hio/Desktop/jwtserv/
-include("jwt.hrl").


encode(Algorithm, Payload, Secret) ->
    encode(Algorithm, Payload, Secret, []).

encode(Algorithm, Payload, Secret, HeaderExtra) ->
    AlgorithmName = atom_to_algorithm(Algorithm),
    Header = jsx:encode([{typ, <<"JWT">>},
                         {alg, AlgorithmName} | HeaderExtra]),
    HeaderEncoded = base64url:encode(Header),
    PayloadEncoded = base64url:encode(jsx:encode(Payload)),
    DataEncoded = <<HeaderEncoded/binary, $., PayloadEncoded/binary>>,
    Signature = get_signature(Algorithm, DataEncoded, Secret),
    SignatureEncoded = base64url:encode(Signature),
    [<<DataEncoded/binary, $., SignatureEncoded/binary>>].


find_issuer_data(Data, Secret) when is_binary(Data) ->
    try
        case binary:split(Data, [<<".">>], [global]) of
            [HeaderEncoded, PayloadEncoded, SignatureEncoded] ->
   Header = jsx:decode(base64url:decode(HeaderEncoded), [{return_maps, true}]),
                       io:format("~p~n", [Header]),
                AlgorithmStr = maps:get(<<"alg">>, Header, undefined),
                %% io:format("~p~n", [AlgorithmStr]),
                Algorithm = algorithm_to_atom(AlgorithmStr),
                          io:format("~p~n", [Algorithm]),
                DataEncoded = <<HeaderEncoded/binary, $.,
                                PayloadEncoded/binary>>,
                                         %% io:format("~p~n", [DataEncoded]),
                ActualSignature = get_signature(Algorithm, DataEncoded, Secret),
                io:format("~p~n", [ActualSignature]),
                Signature = base64url:decode(SignatureEncoded),
                io:format("~p~n", [Signature]),
                Payload = jsx:decode(base64url:decode(PayloadEncoded), [{return_maps, true}]),
                    io:format("~p~n", [Payload]),
                    Expiration = maps:get(<<"exp">>, Payload, noexp),
                    io:format("~p~n", [Expiration]),
                   IssuerData=maps:get(<<"iss">>, Payload, undefined),
                    io:format("~p~n", [IssuerData]),
                if
                    Signature =:= ActualSignature ->
                        NowSecs = now_secs(),
                        if
                            Expiration == noexp orelse Expiration > NowSecs ->
                                 IssuerData;
                            true ->
                                {error, {expired, Expiration}}
                        end;
                    true ->
                        {error, {badsig}}
                end;
            _ ->
                {error, badtoken}
        end
    catch
        error:E ->
            {error, E}
                                
    end.


algorithm_to_atom(<<"HS256">>) -> hs256;
algorithm_to_atom(<<"HS384">>) -> hs384;
algorithm_to_atom(<<"HS512">>) -> hs512.

atom_to_algorithm(hs256) -> <<"HS256">>;
atom_to_algorithm(hs384) -> <<"HS384">>;
atom_to_algorithm(hs512) -> <<"HS512">>.

algorithm_to_crypto_algorithm(hs256) -> sha256;
algorithm_to_crypto_algorithm(hs384) -> sha384;
algorithm_to_crypto_algorithm(hs512) -> sha512.

get_signature(Algorithm, Data, Secret) ->
    CryptoAlg = algorithm_to_crypto_algorithm(Algorithm),
    crypto:mac(hmac, CryptoAlg, Secret, Data).

now_secs() ->
    {MegaSecs, Secs, _MicroSecs} = os:timestamp(),
    (MegaSecs * 1000000 + Secs).