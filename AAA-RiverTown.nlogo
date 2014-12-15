globals [
  borders         ;; agentset of border patches
  drains          ;; agentset of all patches where water drains
  river           ;; aggentset of river patches
  land            ;; agentset of all non-drain patches
  total-init-soil
  dig-mound-mag   ;; controls digging or mounding by mouse action
  rise-over-run
  mound-count dig-count
]

patches-own [
  base-elevation       ;; elevation of tray above table
  soil                 ;; amount of soil on top of base-elevation
  soil-level-init      ;; initial soil level before erosion
  water                ;; amount of water on top of soil
]

to set-terrain
  ask patches [set base-elevation 100 * (world-width - pxcor - 1) * rise-over-run / (world-width - 1)]
  let d1      patches with [pxcor = max-pxcor]
  let d2      patches with [pxcor > 2 and member? pycor (list max-pycor min-pycor)] 
  set borders (patch-set d1 d2)    
  set river   patches with [member? pxcor [0 1 2]]
  set drains  patches with [pxcor = (max-pxcor - 1) and member? pycor n-values (world-height - 2) [? + 1 - max-pycor]] 
  set land    patches with [not member? self drains and not member? self borders and not member? self river]
  
  ask land [ 
    set soil 100
    if pxcor > max-pxcor - 40 [set soil 0] ; bare tray continuing slope
    set soil-level-init soil
    set water 0         ;; start land dry
  ]
  ask borders [
    set base-elevation base-elevation + 5000
    set pcolor yellow
  ]
  ask drains  [set base-elevation 0]
  ask river [
    set soil  50
    set water river-level
  ]
  
  set total-init-soil sum [soil] of land
end

to setup
  clear-all
  set rise-over-run 0.50  ;0.04
  set show-water? true
  set show-erosion? true
  set mouse-tool? false
  set river-level 45
  set mound-count 0
  set dig-count 0

  set-terrain
  recolor-land
  decorate
  reset-ticks  
end

to go
  ask land [if (pycor = 0) and (member? pxcor [6 7] ) [ set water water + water-rate ]]  ;; first add water

  ask river [set water river-level flow-water-with-soil] 
  
  ask land [ if water > 0 [flow-water-with-soil settle-soil]] 
  
  ask drains [  
    set water 0
    set soil  0]  ;; reset the drains to their initial state
  
  recolor-land  ;; update the patch colors
  
  if mouse-tool? [
    ;ifelse dig-mound-tool = "mound" [set dig-mound-mag 1] [set dig-mound-mag -1]
    if mouse-down? [
      ask patch mouse-xcor mouse-ycor [ 
        let add-soil 0
        ifelse dig-mound-tool = "dig" [
          set add-soil (max list -3 -1 * soil)
          set dig-count dig-count + 3] [
          set add-soil 3
          set mound-count mound-count + 3]   
        set soil soil + add-soil]]]
  tick
end

to flow-water-with-soil
  let soil-entrainment-factor 0.6
  let water-flow-factor 0.5
  let gamma 0.0 ;0.30
  let target min-one-of neighbors [base-elevation + soil + water]
  let flow-gradient (base-elevation + soil + water - [base-elevation + soil + water] of target)
  if flow-gradient > 0 [                            ;; flow water
    let flow-amt 0.5 * water-flow-factor * flow-gradient 
    let temp-flow-amt (min list water flow-amt)            ;; don't let flow amount exceed amount of water
    set water water - temp-flow-amt
    ask target [set water water + temp-flow-amt]
    
      if flow-amt > gamma [
        let erosion-amt soil-entrainment-factor * flow-amt
        set erosion-amt (min list soil erosion-amt)            ;;don't let erosion exceed soil
        set soil soil - erosion-amt
        ask target [set soil soil + erosion-amt]]
  ]
end

to settle-soil ;;diffusion-like transport
  let soil-settle-factor 0.3
  if water > 0.01 and pxcor > 4 [
    let target one-of neighbors
    let flow-gradient (base-elevation + soil - [base-elevation + soil] of target)
    ifelse flow-gradient > 0 [                   ;; erode land
      let erosion-amt 0.5 * soil-settle-factor * flow-gradient
      set erosion-amt (min list soil erosion-amt) ;dont' let erosion amount exceed soil amount
      set soil soil - erosion-amt
      ask target [set soil soil + erosion-amt]
      let water-delta 0.1 * water
      set water water - water-delta
      ask target [set water water + water-delta] 
    ]
    [
      let erosion-amt -0.5 * soil-settle-factor * flow-gradient
      set erosion-amt (min list [soil] of target erosion-amt) ;dont' let erosion amount exceed soil amount
      set soil soil + erosion-amt
      ask target [set soil soil - erosion-amt]
      let water-delta 0.1 * [water] of target
      set water water + water-delta
      ask target [set water water - water-delta] 
    ] 
  ]
end

to recolor-land  ;; patch procedure
  ask land [
    set pcolor scale-color white (base-elevation + soil) llimit1 ulimit1
    if show-erosion? [
      let my-erosion (soil-level-init - soil)  ;;can be negative
      if my-erosion > min-erosion-show [set pcolor scale-color green my-erosion erosion-limit-1 erosion-limit-2 ]]
    if show-water? and water > min-water-show [set pcolor scale-color blue water 20 -10 ]
    if soil > (soil-level-init + show-mounding) [set pcolor red] ;********************************************************************
  ]
  ask river [set pcolor scale-color blue water 0 110]
    
end

to decorate
  foreach [10 34 58] [
    let j -20   
    crt 1 [make-shape "plant" green 2
      repeat 10 [
        setxy ? j
        facexy max-pxcor j
        repeat 10 [hatch 1 fd 2]
        set j j - 2
      ] die
    ]
  ]
  crt 1 [make-shape "house" brown 15    
    setxy 240 40]
  let j 20
  crt 1 [make-shape "house" brown 4
    repeat 7 [
      setxy 150 j
      facexy max-pxcor j
      repeat 10 [hatch 1 fd 4]
      set j j - 4
    ]die]      
end

to make-shape [t-shape t-color t-size]
  set shape t-shape
  set color t-color
  set size t-size
end

to dam
  ask land [if member? pxcor [3 4 5] [set soil soil + 30]]
end
@#$#@#$#@
GRAPHICS-WINDOW
263
10
1473
445
-1
50
4.0
1
10
1
1
1
0
0
0
1
0
299
-50
50
1
1
1
ticks
30.0

BUTTON
25
84
126
133
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
132
85
228
134
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
24
55
224
81
Simulation controls: press Setup then Go. 
11
0.0
0

SWITCH
61
513
188
546
show-water?
show-water?
0
1
-1000

SLIDER
436
561
608
594
llimit1
llimit1
-25
10
-9
1
1
NIL
HORIZONTAL

SLIDER
436
594
608
627
ulimit1
ulimit1
0
100
62
1
1
NIL
HORIZONTAL

PLOT
968
461
1169
611
total water on land
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [water] of land"

MONITOR
780
615
920
660
NIL
sum [soil] of land
0
1
11

PLOT
720
462
920
612
total soil loss
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot total-init-soil - sum [soil] of land"

MONITOR
1045
615
1169
660
NIL
sum [water] of land
0
1
11

SWITCH
58
588
193
621
show-erosion?
show-erosion?
0
1
-1000

SLIDER
204
587
376
620
min-erosion-show
min-erosion-show
0
10
0
0.1
1
NIL
HORIZONTAL

TEXTBOX
49
480
222
520
Visualization options:
16
0.0
1

TEXTBOX
25
158
230
200
It is best to start with a low river level and gradually increase it
11
0.0
1

CHOOSER
46
338
184
383
dig-mound-tool
dig-mound-tool
"dig" "mound"
0

TEXTBOX
39
265
234
329
Select \"mound\" to add soil with mouse.\nSelect \"dig\" to remove soil.\nNote: \"go\" button must be selected
11
0.0
1

SLIDER
203
621
375
654
erosion-limit-1
erosion-limit-1
-10
10
10
1
1
NIL
HORIZONTAL

SLIDER
203
660
375
693
erosion-limit-2
erosion-limit-2
0
20
4
1
1
NIL
HORIZONTAL

SLIDER
200
515
372
548
min-water-show
min-water-show
0
10
0
0.1
1
NIL
HORIZONTAL

SWITCH
46
398
169
431
mouse-tool?
mouse-tool?
0
1
-1000

SLIDER
433
513
605
546
show-mounding
show-mounding
0
10
1.3
0.1
1
NIL
HORIZONTAL

SLIDER
29
199
201
232
river-level
river-level
0
60
45
0.001
1
NIL
HORIZONTAL

MONITOR
1239
471
1407
544
NIL
mound-count
0
1
18

MONITOR
1240
558
1406
631
NIL
dig-count
0
1
18

SLIDER
241
750
413
783
water-rate
water-rate
0
1
0
.001
1
NIL
HORIZONTAL

@#$#@#$#@
RiverTown
==========

This is an engineering water management exercise that allows the student to explore various options for water management around a community. 

## HOW IT WORKS

There is a river on the far left hand side whose level is controlled by a slider. A dig/mound tool allows the user to remove soil to (dig) create a basin, trench, ditch, or other waterway; or to (mound) create dikes or river banks. 


## HOW TO USE IT

press setup then go
slowly increase the river level using the slider and observe

press setup again
switch mouse-tool? on
select dig or mound
use the mouse to dig or mound
slowly increase the river level using the slider and observe


## THINGS TO NOTICE

headward erosion threatens the orfanage near the cliff
soil deposits are shown in red


## THINGS TO TRY

Try to prevent flooding of the town headward erosion while irrigating the crops

## EXTENDING THE MODEL

Crops could chage depending on water conditions.
Houses and orphanage could respond to flooding.

## CREDITS AND REFERENCES

RiverTown model

John Keller and David Mitchell, 

Center for Excellence in STEM Education
California Polytech, San Luis Obispo, Ca

David Mitchell, Vic Castillo, and John Keller, Saving Rivertown: Using Computer Simulations in an Earth Science Engineering Design Project for Pre-Service Teachers, 2015 ASEE Annual Conference and Exposition, Seattle, Wa.

## LICENSE

RiverTown Model. Copyright 2014 Vic Castillo

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a>

This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.

## REPOSITORY

https://github.com/VicCastillo/RiverTown
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
setup
repeat 175 [ go ]
hide-water
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
