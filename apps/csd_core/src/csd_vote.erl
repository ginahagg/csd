-module(csd_vote).
-author('OJ Reeves <oj@buffered.io>').

%% --------------------------------------------------------------------------------------
%% API Function Exports
%% --------------------------------------------------------------------------------------

-export([
    to_vote/3,
    fetch/2,
    save/1,
    get_user_id/1,
    get_which/1,
    get_id/1,
    get_id/2,
    to_json/1,
    from_json/1,
    get_snippet_id/1,
    count_for_snippet/1,
    count_for_snippet/2,
    random_votes/2
  ]).

%% --------------------------------------------------------------------------------------
%% Internal Record Definitions
%% --------------------------------------------------------------------------------------

-record(vote, {
    user_id,
    snippet_id,
    which,
    time
  }).

-record(count, {
    left,
    right,
    which
  }).

%% --------------------------------------------------------------------------------------
%% API Function Definitions
%% --------------------------------------------------------------------------------------

to_vote(UserId, SnippetId, Which="left") when is_integer(UserId) ->
  to_vote_inner(UserId, SnippetId, Which);
to_vote(UserId, SnippetId, Which="right") when is_integer(UserId) ->
  to_vote_inner(UserId, SnippetId, Which).

count_for_snippet(SnippetId) ->
  {ok, {L, R}} = csd_db:vote_count_for_snippet(SnippetId),
  {ok, #count{
    left = L,
    right = R,
    which = <<>>
  }}.

count_for_snippet(SnippetId, UserId) ->
  {ok, {L, R, W}} = csd_db:vote_count_for_snippet(SnippetId, UserId),
  {ok, #count{
    left = L,
    right = R,
    which = W
  }}.

to_json(#vote{time=T, which=W, snippet_id=S, user_id=U}) ->
  jsx:encode({[
      {<<"time">>, T},
      {<<"user_id">>, U},
      {<<"snippet_id">>, S},
      {<<"which">>, W}
    ]});

to_json(#count{left=L, right=R, which=W}) ->
  jsx:encode({[
      {<<"left">>, L},
      {<<"right">>, R},
      {<<"which">>, W}
    ]}).

fetch(UserId, SnippetId) when is_integer(UserId) ->
  csd_db:get_vote(get_id(UserId, SnippetId)).

save(Vote=#vote{}) ->
  csd_db:save_vote(Vote).

get_user_id(#vote{user_id=U}) ->
  U.

get_which(#vote{which=W}) ->
  W.

get_snippet_id(#vote{snippet_id=S}) ->
  S.

get_id(#vote{user_id=U, snippet_id=S}) ->
  get_id(U, S).

get_id(UserId, SnippetId) when is_integer(UserId) ->
  iolist_to_binary([integer_to_list(UserId), <<"-">>, SnippetId]).

from_json(Json) ->
  {List} = jsx:decode(Json),
  #vote{
    time = proplists:get_value(<<"time">>, List),
    user_id = proplists:get_value(<<"user_id">>, List),
    snippet_id = proplists:get_value(<<"snippet_id">>, List),
    which = proplists:get_value(<<"which">>, List)
  }.

random_votes(SnippetId, NumVotes) ->
  rand:seed(os:timestamp()),
  lists:map(fun(_) ->
        Which = case rand:uniform(99999999) rem 2 of
          0 -> "left";
          _ -> "right"
        end,
        V = to_vote(rand:uniform(99999999), SnippetId, Which),
        save(V) end, lists:seq(1, NumVotes)),
  ok.

%% --------------------------------------------------------------------------------------
%% Private Function Definitions
%% --------------------------------------------------------------------------------------

to_vote_inner(UserId, SnippetId, Which) ->
  #vote{
    user_id = UserId,
    snippet_id = csd_util:to_binary(SnippetId),
    time = csd_util:utc_now(),
    which = csd_util:to_binary(Which)
  }.

