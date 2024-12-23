-module(i).
%% c:/Users/Hio/Desktop/erll/дз08/       cd /mnt/c/Users/Hio/Desktop/erll/дз08/
-export([start/0]).
-include_lib("wx/include/wx.hrl").
start() ->
 h8:start(),
 wx:new(),
 Frame = wxFrame:new(wx:null(), 1, "Hio's UI"),
  wxFrame:setMinSize(Frame, { 600, 400 }),
Text=wxTextCtrl:new(Frame, ?wxID_ANY, [ {value,"" },{pos,{15, 10}}, {size, {300,100}}]),
 Font = wxFont:new(8, ?wxFONTFAMILY_DEFAULT, ?wxFONTSTYLE_NORMAL, ?wxFONTWEIGHT_BOLD),
wxTextCtrl:setFont(Text, Font),
  

 Button1 = wxButton:new(Frame, ?wxID_ANY, [{label, "get data"}, {pos,{430, 0}},
{size, {70, 70}}]),

 wxButton:connect(Button1, command_button_clicked, [{callback,
    fun(A,B) ->
           A= h8:retrieve_data(),
           %%wx:new(),
           %%Frame = wxFrame:new(wx:null(), ?wxID_ANY, A),
           %%wxFrame:setMinSize(Frame, { 200, 50 }),
        
            %%M = wxMessageDialog:new(wx:null(), A),
          %% wxMessageDialog:showModal(M),

           %%wxTextCtrl:writeText(Text,A),
           %%wxTextCtrl:new(Frame, ?wxID_ANY, [ {value, A }]),
           %%wxTextCtrl:setValue(Text,A),
           %%wx:setText(Text, A),
        io:format(A,B)
            end
        }]),
        Button2 = wxButton:new(Frame, ?wxID_ANY, [{label, "insert data"}, {pos,{430, 70}},
{size, {70, 70}}]),

 wxButton:connect(Button2, command_button_clicked, [{callback,
    fun(A,B) ->
           A= h8:insert_data(),
        io:format(A,B)
            end
        }]),
        Button3 = wxButton:new(Frame, ?wxID_ANY, [{label, "create table"}, {pos,{430, 140}},
{size, {70, 70}}]),

 wxButton:connect(Button3, command_button_clicked, [{callback,
    fun(A,B) ->
           A= h8:create_table(),
        io:format(A,B)
            end
        }]),
        Button4 = wxButton:new(Frame, ?wxID_ANY, [{label, "delete table"}, {pos,{430, 210}},
{size, {70, 70}}]),

 wxButton:connect(Button4, command_button_clicked, [{callback,
    fun(A,B) ->
           A= h8:delete_table(),
        io:format(A,B)
            end
        }]),
        wxFrame:show(Frame).
       
 