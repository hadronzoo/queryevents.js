window.QueryEvents = class QueryEvents
  @MIN_INT = -9007199254740992
  @MAX_INT =  9007199254740992

  defaultDevices = [
    { device: 'phonePortrait',  maxWidth: '320px'                    }
    { device: 'phoneLandscape', maxWidth: '480px'                    }
    { device: 'tablet',         minWidth: '481px', maxWidth: '979px' }
    { device: 'desktop',        minWidth: '980px'                    }
  ]

  constructor: (devices = defaultDevices) ->
    @devices = {}
    @matchers = {}

    @addDevice = (device, query) =>
      q = ['screen']
      q.push "(max-width: #{query.maxWidth})"   if query.maxWidth?
      q.push "(max-height: #{query.maxHeight})" if query.maxHeight?
      q.push "(min-width: #{query.minWidth})"   if query.minWidth?
      q.push "(min-height: #{query.minHeight})" if query.minHeight?
      @devices[device] = window.matchMedia q.join(' and ')

      @matchers[device] = {}
      @devices[device].addListener (q) =>
        if @devices[device].matches
          matcher.match(device) for oRef, matcher of @matchers[device]
        else
          matcher.nomatch(device) for oRef, matcher of @matchers[device]

    @addDevice(deviceSpec.device, deviceSpec) for deviceSpec in devices
    @oRef = QueryEvents.MIN_INT

    @deleteMatcherORefFn = (device, oRef) =>
      =>
        delete @matchers[device][oRef]

  deleteMatchers: (matcherSpecs) =>
    for matcherSpec in matcherSpecs
      { device: device, oRef: oRef } = matcherSpec
      delete @matchers[device][oRef]

  matcherCount: (device) =>
    deviceCount = (device) =>
      i = 0
      i++ for k, v of @matchers[device]
      i
    if device?
      deviceCount(device)
    else
      i = 0
      i += deviceCount(device) for device, v of @matchers
      i

  buildShowHide = (options, finishedCallback) ->
    { show: s, hide: h, once: once } = options

    hasShown = false
    hasHidden = false

    clearIfFinished = ->
      finishedCallback() if hasShown and hasHidden

    if not s?
      hasShown = true
      s = (device) ->
    if not h?
      hasHidden = true
      h = (device) ->

    if once
      show = (device) -> 
        if not hasShown
          s(device)
          hasShown = true
          clearIfFinished()

      hide = (device) ->
        if not hasHidden
          h(device)
          hasHidden = true
          clearIfFinished()

    else
      show = s
      hide = h

    {show: show, hide: hide}

  addDevice: @addDevice

  visibleOn: (devices..., options) =>
    o = @oRef
    refs = []

    for device in devices
      { show: show, hide: hide } = buildShowHide options, @deleteMatcherORefFn(device, o)

      @matchers[device][o] = { match: show, nomatch: hide }
      if @devices[device].matches then show(device) else hide(device)

      @oRef++
      @oRef = QueryEvents.MIN_INT if @oRef == QueryEvents.MAX_INT
      refs.push { device: device, oRef: o }
    refs

  hiddenOn: (devices..., options) =>
    o = @oRef
    refs = []

    for device in devices
      { show: show, hide: hide } = buildShowHide options, @deleteMatcherORefFn(device, o)

      @matchers[device][o] = { match: hide, nomatch: show }
      if @devices[device].matches then hide(device) else show(device)
      
      @oRef++
      @oRef = QueryEvents.MIN_INT if @oRef == QueryEvents.MAX_INT
      refs.push { device: device, oRef: o }
    refs

  isVisible: (device) =>
    @devices[device].matches

  isHidden: (device) =>
    not @isVisible(device)


# Polyfill for browsers that don't support matchMedia
# From: https://github.com/paulirish/matchMedia.js/

window.matchMedia = window.matchMedia or ((doc, undefined_) ->
  bool = undefined
  docElem = doc.documentElement
  refNode = docElem.firstElementChild or docElem.firstChild
  
  # fakeBody required for <FF4 when executed in <head>
  fakeBody = doc.createElement("body")
  div = doc.createElement("div")
  div.id = "mq-test-1"
  div.style.cssText = "position:absolute;top:-100em"
  fakeBody.style.background = "none"
  fakeBody.appendChild div
  (q) ->
    div.innerHTML = "&shy;<style media=\"" + q + "\"> #mq-test-1 { width: 42px; }</style>"
    docElem.insertBefore fakeBody, refNode
    bool = div.offsetWidth is 42
    docElem.removeChild fakeBody
    matches: bool
    media: q
)(document)
(->

  # monkeypatch unsupported addListener/removeListener with polling
  unless window.matchMedia("").addListener
    oldMM = window.matchMedia
    window.matchMedia = (q) ->
      ret = oldMM(q)
      listeners = []
      last = false
      timer = undefined
      check = ->
        list = oldMM(q)
        if list.matches and not last
          i = 0
          il = listeners.length

          while i < il
            listeners[i].call ret, list
            i++
        last = list.matches

      ret.addListener = (cb) ->
        listeners.push cb
        timer = setInterval(check, 1000)  unless timer

      ret.removeListener = (cb) ->
        i = 0
        il = listeners.length

        while i < il
          listeners.splice i, 1  if listeners[i] is cb
          i++
        clearInterval timer  if not listeners.length and timer

      ret
)()