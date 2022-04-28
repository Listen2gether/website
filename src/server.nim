import
  pkg/prologue,
  pkg/prologue/middlewares/staticfile

proc index*(ctx: Context) {.async.} =
  resp readFile("public/index.html")

proc mirror*(ctx: Context) {.async.} =
  resp readFile("public/index.html")

const urlPatterns* = @[
  pattern("/", index),
  pattern("/mirror", mirror),
]

var app = newApp(settings = newSettings(appName = "Listen2gether", debug = true, port = Port(8080)))

app.use(staticFileMiddleware("public"))
app.addRoute(urlPatterns, "")
app.run()
