command: "echo ok"
refreshFrequency: 60000

styleAttr = (styles = {}) ->
  Object.keys(styles)
    .map (key) ->
      cssKey = key.replace(/[A-Z]/g, (char) -> "-#{char.toLowerCase()}")
      "#{cssKey}: #{styles[key]}"
    .join("; ")

pad = (value) ->
  String(value).padStart(2, "0")

isoWeek = (date) ->
  utcDate = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
  day = utcDate.getUTCDay() or 7
  utcDate.setUTCDate(utcDate.getUTCDate() + 4 - day)
  yearStart = new Date(Date.UTC(utcDate.getUTCFullYear(), 0, 1))
  Math.ceil((((utcDate - yearStart) / 86400000) + 1) / 7)

weekdayFormatter = new Intl.DateTimeFormat("de-DE", weekday: "long")
monthFormatter = new Intl.DateTimeFormat("de-DE", month: "long")
dayFormatter = new Intl.DateTimeFormat("de-DE", day: "2-digit")
yearFormatter = new Intl.DateTimeFormat("de-DE", year: "numeric")

getValues = ->
  now = new Date()
  week = pad(isoWeek(now))
  zeit: "#{pad(now.getHours())}:#{pad(now.getMinutes())} Uhr"
  datum: dayFormatter.format(now)
  wochentag: weekdayFormatter.format(now)
  monat: monthFormatter.format(now)
  jahr: yearFormatter.format(now)
  kalenderwoche: "Kalenderwoche: #{week}"

setText = (node, value) ->
  return unless node?
  node.textContent = value

# Hier kannst du jedes Element individuell positionieren und stylen.
layout =
  container:
    position: "fixed"
    right: "24px"
    top: "20px"
    width: "260px"
    height: "180px"
    borderRadius: "8px"
    border: "1px solid rgba(255, 255, 255, 0.14)"
    background: "linear-gradient(180deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.03))"
    boxShadow: "0 8px 20px rgba(0, 0, 0, 0.22), inset 0 1px 0 rgba(255, 255, 255, 0.14), inset 0 -1px 0 rgba(255, 255, 255, 0.05)"
    padding: "8px 10px"
    fontFamily: "\"Helvetica Neue\", \"SF Pro Text\", sans-serif"
    color: "rgba(255, 255, 255, 0.92)"
    letterSpacing: "0.01em"
    overflow: "hidden"

  zeit:
    position: "absolute"
    right: "12px"
    top: "8px"
    fontSize: "52px"
    fontWeight: "280"
    lineHeight: "1"
    color: "rgba(255, 255, 255, 0.95)"

  datum:
    position: "absolute"
    right: "180px"
    top: "70px"
    fontSize: "82px"
    fontWeight: "250"
    lineHeight: "1"
    color: "rgba(255, 255, 255, 0.90)"

  wochentag:
    position: "absolute"
    right: "14px"
    top: "68px"
    fontSize: "26px"
    fontWeight: "320"
    textTransform: "capitalize"
    color: "rgba(255, 255, 255, 0.88)"

  monat:
    position: "absolute"
    right: "14px"
    top: "100px"
    fontSize: "26px"
    fontWeight: "320"
    textTransform: "capitalize"
    color: "rgba(255, 255, 255, 0.84)"

  jahr:
    position: "absolute"
    right: "14px"
    top: "130px"
    fontSize: "24px"
    fontWeight: "320"
    color: "rgba(255, 255, 255, 0.80)"

  kalenderwoche:
    position: "absolute"
    right: "14px"
    top: "160px"
    fontSize: "22px"
    fontWeight: "320"
    color: "rgba(255, 255, 255, 0.78)"

render: ->
  values = getValues()

  """
  <div class="my-zeit-widget" style="#{styleAttr(layout.container)}">
    <div class="feld-zeit" style="#{styleAttr(layout.zeit)}">#{values.zeit}</div>
    <div class="feld-datum" style="#{styleAttr(layout.datum)}">#{values.datum}</div>
    <div class="feld-wochentag" style="#{styleAttr(layout.wochentag)}">#{values.wochentag}</div>
    <div class="feld-monat" style="#{styleAttr(layout.monat)}">#{values.monat}</div>
    <div class="feld-jahr" style="#{styleAttr(layout.jahr)}">#{values.jahr}</div>
    <div class="feld-kalenderwoche" style="#{styleAttr(layout.kalenderwoche)}">#{values.kalenderwoche}</div>
  </div>
  """

update: (output, domEl) ->
  return unless domEl?

  nodes = domEl.__timeDateNodes
  unless nodes?
    nodes =
      zeit: domEl.querySelector(".feld-zeit")
      datum: domEl.querySelector(".feld-datum")
      wochentag: domEl.querySelector(".feld-wochentag")
      monat: domEl.querySelector(".feld-monat")
      jahr: domEl.querySelector(".feld-jahr")
      kalenderwoche: domEl.querySelector(".feld-kalenderwoche")
    domEl.__timeDateNodes = nodes

  values = getValues()
  setText(nodes.zeit, values.zeit)
  setText(nodes.datum, values.datum)
  setText(nodes.wochentag, values.wochentag)
  setText(nodes.monat, values.monat)
  setText(nodes.jahr, values.jahr)
  setText(nodes.kalenderwoche, values.kalenderwoche)

style: """
  background-color: transparent

  .my-zeit-widget,
  .my-zeit-widget *
    font-family: "Helvetica Neue", "HelveticaNeue", "SF Pro Text", Helvetica, Arial, sans-serif !important

  .my-zeit-widget
    overflow: hidden !important
    border-radius: 8px

  .my-zeit-widget::before {
    content: "";
    position: absolute;
    pointer-events: none;
    top: 4px;
    left: 8px;
    width: 58%;
    height: 26%;
    transform: rotate(-8deg);
    border-radius: 100px;
    background: linear-gradient(180deg, rgba(255, 255, 255, 0.22), rgba(255, 255, 255, 0));
  }

"""
