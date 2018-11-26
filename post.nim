import strformat, options


type
  PostInfo* = object
    creation*: int64
    content*: string

  Post* = ref object
    id*: int
    info*: PostInfo
    moreBefore*: seq[int]

  PostLink* = object ## Used by profile
    creation*: int64
    topic*: string
    postId*: int


when defined(js):
  import karaxutils

  proc renderPostUrl*(post: Post): string =
    renderPostUrl( post.id)

  proc renderPostUrl*(link: PostLink): string =
    renderPostUrl(link.postId)

