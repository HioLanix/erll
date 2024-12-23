-module(ui).
-export([start/0]).
-export([handle_click/2, update_gui/3]).
-include_lib("wx/include/wx.hrl").
start() ->
 wx:new(),
 Frame = wxFrame:new(wx:null(), 1, "Countdown"),
 %% build and layout the GUI components
 Counter = wxTextCtrl:new(Frame, ?wxID_ANY, [{value, "42"}, {size, {150,
50}}]),
 Font = wxFont:new(42, ?wxFONTFAMILY_DEFAULT, ?wxFONTSTYLE_NORMAL, ?
wxFONTWEIGHT_BOLD),
 wxTextCtrl:setFont(Counter, Font),
 Button = wxButton:new(Frame, ?wxID_ANY, [{label, "Start"}, {pos,{0, 64}},
{size, {150, 50}}]),

 wxButton:connect(Button, command_button_clicked, [{callback, fun
handle_click/2}, {userData, #{counter => Counter, env => wx:get_env()}}]),
 wxFrame:show(Frame).
handle_click(#wx{obj = Button, userData = #{counter := Counter, env := Env}},
 _Event) ->
 wx:set_env(Env),
 Label = wxButton:getLabel(Button),
 case list_to_integer(wxTextCtrl:getValue(Counter)) of
0 when Label =:= "Start" ->
 ok;
_ when Label =:= "Start" ->
 wxTextCtrl:setEditable(Counter, false),
 wxButton:setLabel(Button, "Stop"),
 timer:apply_after(1000, ?MODULE, update_gui, [Counter, Button, Env]);
_ when Label =:= "Stop" ->
 wxTextCtrl:setEditable(Counter, true),
 wxButton:setLabel(Button, "Start")
 end.
update_gui(Counter, Button, Env) ->
 wx:set_env(Env),
 case wxButton:getLabel(Button) of
"Stop" ->
     Value = wxTextCtrl:getValue(Counter),
 case list_to_integer(Value) of
1 ->
 wxTextCtrl:setValue(Counter, "0"),
 wxTextCtrl:setEditable(Counter, true),
 wxButton:setLabel(Button, "Start");
N ->
 wxTextCtrl:setValue(Counter, integer_to_list(N-1)),
 timer:apply_after(1000, ?MODULE, update_gui, [Counter, Button,
Env])
 end;
"Start" ->
 ok
 end.

