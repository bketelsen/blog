import strformat, times, options, json, tables, sugar, httpcore, uri
from dom import window, Location, document, decodeURI

include karax/prelude
import jester/[patterns]

import karaxutils, error, menu, postlist, page

type
  State = ref object
    originalTitle: cstring
    url: Location

proc copyLocation(loc: Location): Location =
  # TODO: It sucks that I had to do this. We need a nice way to deep copy in JS.
  Location(
    hash: loc.hash,
    host: loc.host,
    hostname: loc.hostname,
    href: loc.href,
    pathname: loc.pathname,
    port: loc.port,
    protocol: loc.protocol,
    search: loc.search
  )

proc newState(): State =
  State(
    originalTitle: document.title,
    url: copyLocation(window.location),
  )

var state = newState()
proc onPopState(event: dom.Event) =
  # This event is usually only called when the user moves back in their
  # history. I fire it in karaxutils.anchorCB as well to ensure the URL is
  # always updated. This should be moved into Karax in the future.
  document.title = state.originalTitle
  if state.url.href != window.location.href:
    state = newState() # Reload the state to remove stale data.
  state.url = copyLocation(window.location)

  redraw()

type Params = Table[string, string]
type
  Route = object
    n: string
    p: proc (params: Params): VNode

proc r(n: string, p: proc (params: Params): VNode): Route = Route(n: n, p: p)
proc route(routes: openarray[Route]): VNode =
  let path =
    if state.url.pathname.len == 0: "/" else: $state.url.pathname
  let prefix = if appName == "/": "" else: appName
  for route in routes:
    let pattern = (prefix & route.n).parsePattern()
    var (matched, params) = pattern.match(path)
    parseUrlQuery($state.url.search, params)
    if params.hasKey("q"):
      if "/" & params["q"] == route.n:
        matched = true
        # todo: window.history.pushstate
    if matched:
      return route.p(params)

  return renderError("Unmatched route: " & path, Http500)

proc render(data: RouterData): VNode =
  result = buildHtml(tdiv()):
    buildMenu()
    route([
      r("/blog/@id",
        (params: Params) =>
          (renderPostList(params["id"]))
      ),
      r("/about",
        (params: Params) =>
          (renderPage("about.md"))
      ),
      r("/links",
        (params: Params) =>
          (renderPage("links.md"))
      ),
      r("/404",
        (params: Params) => render404()
      ),
      r("/", (params: Params) => renderPostList("/"))
    ])

window.onPopState = onPopState
setRenderer render
