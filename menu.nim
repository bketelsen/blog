
import karax / [karax, karaxdsl, vdom, kdom, compact, jstrutils]
import jsconsole
import karaxutils


proc contentA(): VNode =
  result = buildHtml(tdiv):
    text "content A"

proc contentB(): VNode =
  result = buildHtml(tdiv):
    text "content B"

proc contentC(): VNode =
  result = buildHtml(tdiv):
    text "content C"



type
  MenuItemHandler = proc(): VNode

var content: MenuItemHandler = contentA

proc menuAction(x: MenuItemHandler): proc() =
  result = proc() = content = x

proc buildMenu*(): VNode =
  result = buildHtml(tdiv):
    nav(class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top"):
      tdiv(class="container"):
        a(class="navbar-brand",href=makeUri("/"),
        onClick=anchorCB):
          text "Start Bootstrap"
        button(class="navbar-toggler",type="button",data-toggle="collapse",data-target="#navbarResponsive",aria-controls="navbarResponsive",aria-expanded="false",aria-label="Toggle navigation"):
          span(class="navbar-toggler-icon")
        tdiv(class="collapse navbar-collapse",id="navbarResponsive"):
          ul(class="navbar-nav ml-auto"):
            li(class="nav-item active"):
              a(class="nav-link",href=makeUri("/"),
                onClick=anchorCB):
                text "Home"
                span(class="sr-only"):
                  text "(current)"
            li(class="nav-item"):
              a(class="nav-link",href=makeUri("/about"),
                onClick=anchorCB):
                text "About"
            li(class="nav-item"):
              a(class="nav-link",href=makeUri("/links"),
                onClick=anchorCB):
                text "Links"
            li(class="nav-item"):
              a(class="nav-link",href="/contact"):
                text "Contact"