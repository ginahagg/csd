-module(csd_snippet).
-author('OJ Reeves <oj@buffered.io>').

-define(SNIPPET_PAGE_SIZE, 10).

%% --------------------------------------------------------------------------------------
%% API Function Exports
%% --------------------------------------------------------------------------------------

-export([
    to_snippet/4,
    to_json/1,
    from_json/1,
    list_for_user/1,
    list_for_user/2,
    fetch/1,
    save/1,
    set_user_id/2,
    get_user_id/1,
    get_key/1,
    set_key/2
  ]).

%% --------------------------------------------------------------------------------------
%% Internal Record Definitions
%% --------------------------------------------------------------------------------------

-record(snippet, {
    user_id,
    key,
    title,
    left,
    right,
    created
  }).

%% --------------------------------------------------------------------------------------
%% API Function Definitions
%% --------------------------------------------------------------------------------------

  %iolist_to_binary([Key, integer_to_list(Timestamp)]).

to_snippet(Title, Left, Right, UserId) ->
  Now = os:timestamp(),
  #snippet{
    user_id = UserId,
    key = csd_riak:new_key(),
    title = csd_util:to_binary(Title),
    left = csd_util:to_binary(Left),
    right = csd_util:to_binary(Right),
    created = csd_date:utc(Now)
  }.

list_for_user(UserId) ->
  list_for_user(UserId, 0).

list_for_user(UserId, PageNumber) ->
  FieldsToKeep = [<<"created">>, <<"title">>, <<"key">>],
  {ok, {Snippets, TotalSnippets}} = csd_db:list_snippets(UserId, FieldsToKeep,
    ?SNIPPET_PAGE_SIZE, PageNumber),

  Pages = case {TotalSnippets div ?SNIPPET_PAGE_SIZE, TotalSnippets rem ?SNIPPET_PAGE_SIZE} of
    {P, 0} -> P;
    {P, _} -> P + 1
  end,
  {ok, {Snippets, PageNumber, Pages}}.

fetch(SnippetKey) when is_list(SnippetKey) ->
  fetch(list_to_binary(SnippetKey));
fetch(SnippetKey) when is_binary(SnippetKey) ->
  csd_db:get_snippet(SnippetKey).

save(Snippet=#snippet{}) ->
  csd_db:save_snippet(Snippet).

set_user_id(Snippet=#snippet{}, UserId) ->
  Snippet#snippet{
    user_id = UserId
  }.

get_user_id(#snippet{user_id=UserId}) ->
  UserId.

get_key(#snippet{key=Key}) ->
  Key.

set_key(Snippet=#snippet{}, NewKey) ->
  Snippet#snippet{
    key = NewKey
  }.

to_json(#snippet{user_id=U, key=K, title=T, left=L, right=R, created=C}) ->
  jsx:encode({[
    {<<"user_id">>, U},
    {<<"key">>, K},
    {<<"title">>, T},
    {<<"left">>, L},
    {<<"right">>, R},
    {<<"created">>, C}
  ]}).

from_json(SnippetJson) ->
  {Data} = jsx:decode(SnippetJson),
  #snippet{
    user_id = proplists:get_value(<<"user_id">>, Data),
    key = proplists:get_value(<<"key">>, Data),
    title = proplists:get_value(<<"title">>, Data),
    left = proplists:get_value(<<"left">>, Data),
    right = proplists:get_value(<<"right">>, Data),
    created = proplists:get_value(<<"created">>, Data)
  }.

%% --------------------------------------------------------------------------------------
%% Private Function Definitions
%% --------------------------------------------------------------------------------------

