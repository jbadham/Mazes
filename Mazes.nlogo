; Cellular automata with probabilistic birth and death rules

globals
[ LR-lengths      ; list of lengths of horizontal corridors
  UD-lengths      ; list of lengths of vertical corridors
  prop-parallel   ; proportion of live patches in a parallel corridor
  prop-change     ; proportion of all patches changing state
]

patches-own
[ alive?
  LR-end-type        ; left, right or neither
  UD-end-type        ; top, bottom or neither
  through-type       ; path horizonal, vertical or both
  next-alive?
]

;----------------------------------------------------------------
; Main structure
;----------------------------------------------------------------

to setup
  clear-all
  ; randomise or use seed
  ifelse randomise?
  [ set this-seed new-seed ]
  [ random-seed this-seed ]
  ; apply rule set for updating
  apply-rules
  ; initialise reporters
  set LR-lengths []
  set UD-lengths []
  ; initialise patches
  ask patches
  [ set alive? (random-float 1 <= density)
  ]
  update-maze-type
  colour-patches
  reset-ticks
end

to go
  update-patches
  colour-patches
  update-maze-type
  calc-measures
  tick
end

;----------------------------------------------------------------
; Key procedures
;----------------------------------------------------------------

; update state based on counts of live neighbours
to update-patches
  ask patches
  [ let alive-nbrs count neighbors with [alive?]
    set next-alive? alive?   ; default to no change
    ifelse alive?
    ; check rules for survival of live cells
    [ if alive-nbrs < survive-low or alive-nbrs > survive-high
      [ set next-alive? not (random-float 1 < prob-die) ]
    ]
    ; check rules for dead cells becoming live
    [ if alive-nbrs >= born-low and alive-nbrs <= born-high
      [ set next-alive? random-float 1 < prob-born ]
    ]
  ]
  ; calculate proportion changing state
  set prop-change count patches with [ alive? != next-alive? ] / count patches
  ; change state
  ask patches [ set alive? next-alive? ]
end

; identifies the role of patches within corridors, such as end or through
to update-maze-type
  ask patches
  [ ifelse alive?
    [ ; flags for accessible directions
      let up? [alive?] of patch-at 0 1
      let down? [alive?] of patch-at 0 -1
      let right? [alive?] of patch-at 1 0
      let left? [alive?] of patch-at -1 0
      ; end point in some left/right direction
      set LR-end-type
      (ifelse-value
        left? and not right? [ "R end" ]
        right? and not left? [ "L end" ]
        [ "not LR" ]
      )
      ; end point in some up/down direction
      set UD-end-type
      (ifelse-value
        up? and not down? [ "bottom" ]
        down? and not up? [ "top" ]
        [ "not UD" ]
      )
      ; straight through
      set through-type
      (ifelse-value
        up? and down? and left? and right? [ "Both" ]
        up? and down? and not (left? and right?) [ "Vertical" ]
        not (up? and down?) and left? and right? [ "Horizontal" ]
        [ "Not through" ]
      )
      ]
    ; dead cells are not ends or paths
    [ set LR-end-type [ "not LR" ]
      set UD-end-type [ "not UD" ]
      set through-type [ "Not through" ]
    ]
  ]
end

; calls the utility functions that calculate output measures
to calc-measures
  ; start from left end and count to the right, checking for end or wrap to start
  set LR-lengths [length-R] of patches with [ LR-end-type = "L end"
    and ([through-type] of patch-at 1 0 = "Horizontal" or [through-type] of patch-at 1 0 = "Both") ]
  ; start from bottom and count up, checking for end or wrap to start
  set UD-lengths [length-D] of patches with [ UD-end-type = "bottom"
    and ([through-type] of patch-at 0 1 = "Vertical" or [through-type] of patch-at 0 1 = "Both") ]
  set prop-parallel calc-parallel
end

; applies the chosen rule set
to apply-rules
  (ifelse
    choose-rule-set = "Sliders" []
    choose-rule-set = "Conway 23/3"
    [ set survive-low 2
      set survive-high 3
      set born-low 3
      set born-high 3
    ]
    choose-rule-set = "Maze 12345/3"
    [ set survive-low 1
      set survive-high 5
      set born-low 3
      set born-high 3
    ]
    choose-rule-set = "Mazectric 1234/3"
    [ set survive-low 1
      set survive-high 4
      set born-low 3
      set born-high 3
    ]
    [ print "Unknown Rule Set"
       stop
    ]
  )
end

;----------------------------------------------------------------
; Utility procedures
;----------------------------------------------------------------

; finds parallel corridors, lines of live cells separated by a line of dead cells
to-report calc-parallel
  ; counting only the pure corridors, not ends or where a cross corridor
  let V-parallels patches with [alive? and (through-type = "Vertical")
    and [alive?] of patch-at 2 0 and [through-type] of patch-at 2 0 = "Vertical"]
  let H-parallels patches with [alive? and (through-type = "Horizontal")
    and [alive?] of patch-at 0 2 and [through-type] of patch-at 0 2 = "Horizontal"]
  ; return as proportion of live patches
  report ifelse-value any? patches with [alive?]
  [ (count V-parallels + count H-parallels) / count patches with [alive?] ]
  [ 0 ]
end

; calculates the length of horizontal lines
to-report length-R
  ; count to the right, checking for end or wrap to start
  let path-length 1
  while [ ([through-type] of patch-at path-length 0 = "Horizontal" or [through-type] of patch-at path-length 0 = "Both")
    and (patch-at path-length 0 != self) ]
  [ set path-length path-length + 1
  ]
  ifelse [LR-end-type] of patch-at path-length 0 = "R end"
  [ report path-length + 1 ]
  [ if patch-at path-length 0 != self [ print "Cannot calculate LR corridor length" ]
    report path-length
  ]
end

; calculates the length of vertical lines
to-report length-D
  ; count up, checking for end or wrap to start
  let path-length 1
  while [ ([through-type] of patch-at 0 path-length = "Vertical" or [through-type] of patch-at 0 path-length = "Both")
    and (patch-at 0 path-length != self) ]
  [ set path-length path-length + 1
  ]
  ifelse [UD-end-type] of patch-at 0 path-length = "top"
  [ report path-length + 1 ]
  [ if patch-at 0 path-length != self [ print "Cannot calculate UD corridor length" ]
    report path-length
  ]
end

; sets the colour of live cells
to colour-patches
  ask patches
  [ set pcolor
    (ifelse-value
      alive? and live-colour = "blue" [ sky + 4 ]
      alive? and live-colour = "pink" [ pink + 4 ]
      alive? and live-colour = "white" [ white ]
      not alive? [ black ]
    )
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
640
20
1153
534
-1
-1
5.0
1
10
1
1
1
0
1
1
1
-50
50
-50
50
1
1
1
ticks
30.0

TEXTBOX
41
41
380
91
Rules have two parts:\n> number of alive neighbours for an alive cell to survive\n> alive neighbours for a dead cell to become alive
12
0.0
1

CHOOSER
33
96
213
141
choose-rule-set
choose-rule-set
"Sliders" "Conway 23/3" "Maze 12345/3" "Mazectric 1234/3"
1

BUTTON
223
96
403
141
Apply Rule Set
apply-rules
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
33
148
213
181
survive-low
survive-low
0
8
2.0
1
1
alive
HORIZONTAL

SLIDER
33
181
213
214
survive-high
survive-high
0
8
3.0
1
1
alive
HORIZONTAL

SLIDER
33
219
213
252
prob-die
prob-die
0
1
1.0
0.05
1
NIL
HORIZONTAL

SLIDER
223
148
403
181
born-low
born-low
0
8
3.0
1
1
alive
HORIZONTAL

SLIDER
223
181
403
214
born-high
born-high
0
8
3.0
1
1
alive
HORIZONTAL

SLIDER
223
219
403
252
prob-born
prob-born
0
1
1.0
0.05
1
NIL
HORIZONTAL

SWITCH
413
157
531
190
randomise?
randomise?
0
1
-1000

INPUTBOX
413
191
531
251
this-seed
-1.490360115E9
1
0
Number

SLIDER
413
45
525
78
density
density
0
1
0.5
0.05
1
NIL
HORIZONTAL

BUTTON
413
78
525
128
populate
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
535
45
620
95
step
go
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
535
95
620
145
step 20
repeat 20 [go]
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
535
145
620
195
go
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

CHOOSER
425
486
620
531
live-colour
live-colour
"blue" "pink" "white"
1

PLOT
30
276
320
476
Horizontal (3 or more)
NIL
NIL
0.0
50.0
0.0
100.0
false
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram LR-lengths"

MONITOR
250
296
310
341
Mean
mean LR-lengths
2
1
11

MONITOR
250
341
310
386
Max
max LR-lengths
0
1
11

MONITOR
250
386
310
431
Count
length LR-lengths
0
1
11

PLOT
330
276
620
476
Vertical (3 or more)
NIL
NIL
0.0
50.0
0.0
100.0
false
false
"" ""
PENS
"default" 1.0 1 -16777216 false "" "histogram UD-lengths"

MONITOR
550
296
610
341
Mean
mean UD-lengths
2
1
11

MONITOR
550
341
610
386
Max
max UD-lengths
0
1
11

MONITOR
550
386
610
431
Count
length UD-lengths
0
1
11

PLOT
1173
20
1463
200
Average lengths
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Hor" 1.0 0 -13345367 true "" "if length LR-lengths > 0 [plot mean LR-lengths]"
"Vert" 1.0 0 -5298144 true "" "if length UD-lengths > 0 [plot mean UD-lengths]"

PLOT
1173
200
1463
380
Maximum lengths
NIL
NIL
0.0
10.0
0.0
20.0
true
true
"" ""
PENS
"Hor" 1.0 0 -13345367 true "" "if length LR-lengths > 0 [plot max LR-lengths]"
"Vert" 1.0 0 -5298144 true "" "if length UD-lengths > 0 [plot max UD-lengths]"

PLOT
1173
380
1463
534
Proportions
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Parallel" 1.0 0 -16777216 true "" "plot prop-parallel"
"Change" 1.0 0 -14835848 true "" "plot prop-change"

@#$#@#$#@
# CELLULAR AUTOMATA

The model consists of a grid of square cells that are either live (also referred to as on) or dead (off). Each cell updates its based entirely on the count of live and dead cells in its neighbourhood. Such models are a specific implementation of cellular automata.

## Classic Game of Life

The eight cells immediately surrounding a cell are together referred to as the neiighbourhood of the central cell (technically a Moore neigbourhood). Update (or translation) rules use the number of live and dead cells in the neighbourhood to define the state of each cell for the next time step. The location of the live or dead cells is irrelevant.

Two dimensional cellular automata were popularised by Conway's Game of Life, which has the following rules:

* a live cell dies if there are fewer than 2 live neighbours
* a live cell dies if there are more than 3 live neighbours
* a dead cell becomes live if there are exactly 3 live neighbours

In modern notation, that rule set would be written as 23/3. This notation refers only to the conditions under which a cell is alive in the next time step. The numbers to the left of the '/' enumerate the number of live neighbours for a live cell to survive (in this case 2 or 3), and the numbers to the right enumerate the number of live neighbours for a dead cell to be born (in this case 3).

Updates are applied synchonously. That is, all cells calculate their next state before any cell actually updates.

## Using this model

The rules are controlled by the sliders, which set the upper and lower number of live cells for a live cell to survive or a dead cell to be born (live in the next time step). Three well known sets of rules are available from the chooser, which simply set the sliders to the appropriate values. In addition to Conway's original rules, there are two popular rule sets that tend to generate maze like structures.

Classic Cellular Automata are deterministic; the current state completely determines the next state and therefore all future states. Probabilistic Cellular Automata extend the rule sets, with state changes applied according to some probability. In this model, the probabilities are set with two further sliders located with the other sliders defining the survival and birth rules.

To use the model, first choose a rule set or set the sliders to the update rules for cells to survive or be born (value bounds). Choose an initial density of live cells. Each cell is assigned a live state with the same probability set by the density slider. The populate button sets up the starting configuration. State changes are applied with the step (once) or step 20 (20 times) or go (indefinitely) buttons.

The measures presented concern the length of lines of live cells. These are intended as measures of the 'maze-ness' of the generated patterns. Measures include the longest straight lines and the distribution of lengths.

## Things to try

Start with Conway's rules and probabilities set to 1 with density of 0.5. This will generate classic patterns of small groups of live cells apparently moving. Then use initial density of 0.25 and 0.75, which generally leads to more clumps and more movement respectively. Compare that to the mazectric rules with the same probabilities and density, where a more maze like structure is generated.

Revert to Conway's rules and initial density of 0.5. Adjust the probability sliders to complementary values such as 0.5 for prob-die and prob-born, then 0.3 for prob-die and 0.7 for prob-born. These probabilistic rules also tend to generate maze like structures that are qualitatively similar to those generated by the mazectric rules with deterministic rules.

# OTHER INFORMATION

See the Life model in the NetLogo Models Library (Computer Science >> Cellular Automata section) for an implementation of the classic Game of Life that also allows the user to select specific cells as the initial live set.

See the Wiki at https://www.conwaylife.com/wiki/Main_Page for information about both the classic Game of Life and extensions such as the maze rules.

## Credits and copyright

Copyright: Jennifer Badham (2021)
Contact: research@criticalconnections.com.au

While this software is copyrighted, it is released under the terms of the following open source license, which allows it to be used and amended without charge provided appropriate attribution is observed.

	This program is free software: you can redistribute it and/or modify it under the
	terms of the GNU General Public License as published by the Free Software
	Foundation, either version 3 of the License, or (at your option) any later
	version.  This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY, without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
	details.
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Exploratory" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <exitCondition>ticks &gt; 0 and prop-change &lt; 1 / count patches</exitCondition>
    <metric>this-seed</metric>
    <metric>ifelse-value length LR-lengths &gt; 0 [mean LR-lengths][0]</metric>
    <metric>ifelse-value length LR-lengths &gt; 0 [max LR-lengths][0]</metric>
    <metric>length LR-lengths</metric>
    <metric>ifelse-value length UD-lengths &gt; 0 [mean UD-lengths][0]</metric>
    <metric>ifelse-value length UD-lengths &gt; 0 [max UD-lengths][0]</metric>
    <metric>length UD-lengths</metric>
    <metric>count patches with [alive?] / count patches</metric>
    <metric>prop-parallel</metric>
    <enumeratedValueSet variable="density">
      <value value="0.2"/>
      <value value="0.5"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="survive-low">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="survive-high">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-die">
      <value value="0"/>
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.8"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="born-low">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="born-high">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-born">
      <value value="0"/>
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.8"/>
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
