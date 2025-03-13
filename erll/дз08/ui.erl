-module(ui).
-export([start/0]).
-export([handle_click/2, update_gui/3]).
-include_lib("wx/include/wx.hrl").
start() ->
 wx:new(),
 Frame = wxFrame:new(wx:null(), 1, "Countdown"),
 %% build and layout the GUI components
 Text = wxTextCtrl:new(Frame, ?wxID_ANY, [{value, "42"}, {size, {150,
50}}]),
 Font = wxFont:new(42, ?wxFONTFAMILY_DEFAULT, ?wxFONTSTYLE_NORMAL, ?
wxFONTWEIGHT_BOLD),
 wxTextCtrl:setFont(Text, Font),
 Button = wxButton:new(Frame, ?wxID_ANY, [{label, "Start"}, {pos,{0, 64}},
{size, {150, 50}}]),

 wxButton:connect(Button, command_button_clicked, [{callback, fun
handle_click/2}, {userData, #{Text => Text, env => wx:get_env()}}]),
 wxFrame:show(Frame).
handle_click(#wx{obj = Button, userData = #{Text := Text, env := Env}},
 _Event) ->
 wx:set_env(Env),
 Label = wxButton:getLabel(Button),
 case list_to_integer(wxTextCtrl:getValue(Text)) of
0 when Label =:= "Start" ->
 ok;
_ when Label =:= "Start" ->
 wxTextCtrl:setEditable(Text, false),
 wxButton:setLabel(Button, "Stop"),
 timer:apply_after(1000, ?MODULE, update_gui, [Text, Button, Env]);
_ when Label =:= "Stop" ->
 wxTextCtrl:setEditable(Text, true),
 wxButton:setLabel(Button, "Start")
 end.
update_gui(Text, Button, Env) ->
 wx:set_env(Env),
 case wxButton:getLabel(Button) of
"Stop" ->
     Value = wxTextCtrl:getValue(Text),
 case list_to_integer(Value) of
1 ->
 wxTextCtrl:setValue(Text, "0"),
 wxTextCtrl:setEditable(Text, true),
 wxButton:setLabel(Button, "Start");
N ->
 wxTextCtrl:setValue(Text, integer_to_list(N-1)),
 timer:apply_after(1000, ?MODULE, update_gui, [Text, Button,
Env])
 end;
"Start" ->
 ok
 end.

