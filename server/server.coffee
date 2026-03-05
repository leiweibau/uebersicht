parseArgs = require 'minimist'
UebersichtServer = require './src/app.coffee'
createCorsProxy = require './src/corsProxy'
path = require 'path'

handleError = (err) ->
  console.log(err.message || err)
  throw err

try
  args = parseArgs process.argv.slice(2)
  widgetPath = path.resolve(__dirname, args.d ? args.dir  ? './widgets')
  port = args.p ? args.port ? 41416
  settingsPath = path.resolve(__dirname, args.s ? args.settings ? './settings')
  publicPath = path.resolve(__dirname, './public')
  options =
    loginShell: args['login-shell']

  server = UebersichtServer(
    Number(port),
    widgetPath,
    settingsPath,
    publicPath,
    options,
    -> console.log 'server started on port', port
  )
  server.on 'close', handleError
  server.on 'error', handleError

  cors_host = '127.0.0.1'
  cors_port = port + 1
  corsServer = createCorsProxy(
    host: cors_host
    port: cors_port
    allowedOrigins: [
      "http://127.0.0.1:#{port}"
      "http://localhost:#{port}"
    ]
  )

  originalClose = server.close
  server.close = (cb) ->
    corsServer.close()
    originalClose(cb)

catch e
  handleError e
