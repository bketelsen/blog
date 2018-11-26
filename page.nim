include karax/prelude
import karax / [vstyles, kajax, kdom]

import karaxutils, error
import system except Thread
import options, json, times, httpcore, strformat, sugar, math, strutils
import sequtils
from dom import window, Location, document, decodeURI
import karaxutils, error


type
  State = ref object
    page: Option[Page]
    loading: bool
    status: HttpCode
    id: cstring
    
  Page* = ref object
    id*: cstring
    contents*: cstring
    frontmatter*: Option[FrontMatter]

  FrontMatter* = ref object
    title*: string
    date*: string
    description*: string


proc newState(): State =
  State(
    page: none[Page](),
    loading: false,
    status: Http200,
    id: "",
  )
    
var
 state = newState()

proc getKey(key: kstring, source: kstring): kstring = 
 for line in splitLines($source,false):
   let kv = split(line,":",-1)
   if $kv[0] == $key:
     result = kv[1]
     return
    

proc onPage(httpStatus: int, response: kstring) =
  state.loading = false
  state.status = httpStatus.HttpCode
  if state.status != Http200: 
    return
  let parts = split(response,"---", -1)
  var fm: string = ""
  var contents: string = ""
  var fmo: FrontMatter = 
    FrontMatter(
      description: "",
      date: "",
      title: "",
    )

  if parts.len > 1:
    kout(kstring"frontmatter present")
    fm = $parts[1]
    contents = $parts[2]
    fmo.description = $getKey("description",fm)
    fmo.title= $getKey("title",fm)
  else:
    contents = $response
    fm = ""
  

  let p: Page = Page(
    id: state.id,
    contents: contents,
    frontmatter: some(fmo),
  )

  state.page = some(p)

proc toMarkdown(text: kstring): kstring {.importc.}

proc loadPage(id: cstring): VNode =
  # check to see if the requested page is different from the
  # already rendered page (if it exists)
  if state.id != id:
    state.page = none(Page)

  if state.status != Http200:
    return renderError("Couldn't retrieve page.", state.status)

  if state.page.isNone:
    if not state.loading:
      state.loading = true
      state.id = id
      let target = "/pages/" & $id
      let uri = makeUri(target, appName, false, "")
      ajaxGet(
        uri,
        @[],
        (s: int, r: kstring) => onPage(s, r)
      )
    return buildHtml(tdiv(class="loading loading-lg")):
      text "loading"
  var p = state.page.get()
  var f = p.frontmatter.get()
  dom.document.title = f.title
  result = buildHtml:
    verbatim(toMarkdown(p.contents))

proc renderPage*(id: string): VNode =
  loadPage(id)
