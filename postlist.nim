import system except Thread
import options, json, times, httpcore, strformat, sugar, math, strutils
import sequtils

import post
type

  PostList* = ref object
    posts*: seq[Post]

when defined(js):
  from dom import document

  include karax/prelude
  import karax / [vstyles, kajax, kdom]

  import karaxutils, error 

  type
    State = ref object
      list: Option[PostList]
      loading: bool
      status: HttpCode

  proc newState(): State =
    State(
      list: none[PostList](),
      loading: false,
      status: Http200,
    )

  var
    state = newState()
 
  proc render*(post: var Post): VNode =
        result = buildHtml():
          text "Hello World"

  proc onPostList(httpStatus: int, response: kstring, postId: Option[int]) =
    state.loading = false
    state.status = httpStatus.HttpCode
    if state.status != Http200: return

    let parsed = parseJson($response)
    let list = to(parsed, PostList)

    state.list = some(list)

    dom.document.title =  dom.document.title

    # The anchor should be jumped to once all the posts have been loaded.
    if postId.isSome():
      discard setTimeout(
        () => (
          # Would have used scrollIntoView but then the `:target` selector
          # isn't activated.
          getVNodeById($postId.get()).dom.scrollIntoView()
        ),
        100
      )

  proc onMorePosts(httpStatus: int, response: kstring, start: int) =
    state.loading = false
    state.status = httpStatus.HttpCode
    if state.status != Http200: return

    let parsed = parseJson($response)
    var list = to(parsed, seq[Post])

    var idsLoaded: seq[int] = @[]
    for i in 0..<list.len:
      state.list.get().posts.insert(list[i], i+start)
      idsLoaded.add(list[i].id)

    # Save a list of the IDs which have not yet been loaded into the top-most
    # post.
    let postIndex = start+list.len
    # The following check is necessary because we reuse this proc to load
    # a newly created post.
    if postIndex < state.list.get().posts.len:
      let post = state.list.get().posts[postIndex]
      var newPostIds: seq[int] = @[]
      for id in post.moreBefore:
        if id notin idsLoaded:
          newPostIds.add(id)
      post.moreBefore = newPostIds

  proc loadMore(start: int, ids: seq[int]) =
    if state.loading: return

    state.loading = true
    let uri = makeUri(
      "specific_posts.json",
      [("ids", $(%ids))]
    )
    ajaxGet(
      uri,
      @[],
      (s: int, r: kstring) => onMorePosts(s, r, start)
    )

  proc onLoadMore(ev: Event, n: VNode, start: int, post: Post) =
    loadMore(start, post.moreBefore) # TODO: Don't load all!

  proc renderPostList*(id: cstring): VNode =
    buildHtml():
      tdiv:
        text "some post"
