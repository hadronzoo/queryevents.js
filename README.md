queryevents.js
==============

Queryevents.js is a CoffeeScript library that provides a simple way to fire
event handlers based on media queries. It includes [Paul Irish's matchMedia.js
polyfill](https://github.com/paulirish/matchMedia.js/) for browser
compatibility. Media queries are used to define devices, which then call event
handlers when those devices' media queries either match or no longer match.

## Basic Usage

```coffeescript
q = new QueryEvents

# add btn-block class to #sendButton at landscape phone resolutions
q.visibleOn 'phoneLandscape'
  show: -> $('#sendButton').addClass 'btn-block'
  hide: -> $('#sendButton').removeClass 'btn-block'

# hide column 0 at at desktop resolutions
q.hiddenOn 'desktop'
  show: -> $('#dataTable').fnSetColumnVis 0, true,  false
  hide: -> $('#dataTable').fnSetColumnVis 0, false, false

# returns true if window is at tablet resolutions
q.isVisible 'tablet'

# the above is equivalent to calling `matches` on the underlying media query
q.devices.tablet.matches
```

## Calling Matchers Only Once

If `once: true`, then the show and hide functions are only called once for each
given device.

```coffeescript
# initialize sparklines only once at desktop resolutions
q.visibleOn 'desktop'
  once: true
  show: -> $('.row').sparkline()
```

## Deleting Matchers

Matchers can also be deleted by calling `deleteMatchers` and passing in the
reference returned from the `visibleOn` and `hiddenOn` functions.

```coffeescript
# define new tablet and desktop matchers
matchers = q.visibleOn 'tablet', 'desktop'
  show: (device) -> console.log "#{device} shown"
  hide: (device) -> console.log "#{device} hidden"

q.matcherCount()        # ⇒ 2
q.matcherCount 'tablet' # ⇒ 1

# delete the previously defined matchers
q.deleteMatchers matchers
q.matcherCount()        # ⇒ 0 
```

## Devices

By default, the following device definitions are provided:

```coffeescript
[
  { device: 'phonePortrait',  maxWidth: '320px'                    }
  { device: 'phoneLandscape', maxWidth: '480px'                    }
  { device: 'tablet',         minWidth: '481px', maxWidth: '979px' }
  { device: 'desktop',        minWidth: '980px'                    }
]
```

These can be overriden by passing in a different set of definitions to the
constructor. New devices can also be defined:

```coffeescript
q.addDevice 'custom'
  minHeight: '200px'
  maxHeight: '600px'

q.visibleOn 'custom'
  show: -> console.log "custom visible"
```