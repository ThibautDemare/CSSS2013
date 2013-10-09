extensions [gs]

globals [
  slider-check-1    ;; Temporary variables for slider values, so that if sliders
  slider-check-2    ;;   are changed on the fly, the model will notice and
  slider-check-3    ;;   change people's tendencies appropriately.
  slider-check-4
 sd;  standrad division 
]

breed [individuals individual]
individuals-own [
  infected?               ;; If true, the person is infected.  It may be known or unknown.
  coupled?                ;; If true, the person is in a sexually active couple.
  sex-appeal              ;; How likely the person is to join a couple.
  sex-appeal-sensitivity  ;;
  condom-use?             ;; The percent chance a person uses protection.
  partner                 ;; The person that is our current partner in a couple.
  abstinence-time         ;; 
  current-time            ;;
  infection-chance        ;;
  commitment              ;;
  personality             ;; 
  centrality              ;; The betweenness centrality (BC) of the individuals according to the topology of the acquainted network
  maxCentrality           ;; The maximum value of the BC between all nodes
]

;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  show "setup GS"
  ;; Initialize Graphstream communication (from Netlogo to GS)
  setup-senders
  
  setup-globals
  set-default-shape individuals "circle"
  make-network
  repeat 100 [ layout ]
  show "wait GS"
  ;; Synchronisation of Graphstream's communication
  gs:step "acquainted" ticks
  while [gs:wait-step "acquainted" < ticks][]
  get-attributes
  show "sort list"
  ;; Initialize the condom-use parameters according to eventually bias
  let list-best-ind sort-by [ [centrality] of ?1 > [centrality] of ?2] individuals
  let i 0
  let index 0
  ifelse social-positive-bias
  [
    ;; The most central individuals use condom 
    set i 0
    while [i < nb-condom-use]
    [
      ask item i list-best-ind [
        set condom-use? true
      ]
      set i (i + 1)
    ]
  ][
  ifelse social-negative-bias
  [
    ;; The less central individuals use condom use
    set i length list-best-ind - 1
    while [i > ((length list-best-ind) - nb-condom-use)]
    [
      ask item i list-best-ind [
        set condom-use? true
      ]
      set i (i - 1)
    ]
  ][
    ;; random selection for the use of condom
    ask n-of  nb-condom-use  individuals  
    [
      set condom-use? true
    ]
  ]
  ]
  
  ;; Initialize the infected parameters according to eventually bias
  ifelse infection-positive-bias
  [
    show 1
    ;; the more central individuals are infected
    set i 0
    set index 0
    while [i < nb-infected]
    [
      ask item index list-best-ind [
        if not condom-use?
        [
          set infected? true
          set i (i + 1)
        ]
        set index (index + 1)
      ]
    ]
    show 2
  ][
  ifelse infection-negative-bias
  [
    ;; The less central individuals are infected
    set i length list-best-ind
    set index  length list-best-ind - 1
    while [i > ((length list-best-ind) - nb-infected)]
    [
      ask item index list-best-ind [
        if not condom-use?
        [
          set infected? true
          set i (i - 1)
        ]
        set index (index - 1)
      ]
    ]
  ][
    ;; Random selection for the infection
    ask n-of nb-infected individuals with [not condom-use?]
    [
      set infected? true
    ]
  ]
  ]
  show 3
  ;; Set the color of each individuals
  if infectious-dissemination[
    ask individuals [if infected? [set color red]]]
  show 4
  if social-dissemination[
    ask individuals [if condom-use? [set color blue]]]
  show 5
  reset-ticks
  show 6
end

to setup-globals
  set slider-check-2 average-sex-appeal
  set slider-check-3 nb-condom-use
end

;; Receive attributes from GS and fill individuals variables with it
to get-attributes
  ;; Betweenness centrality
  ask individuals [
    let tmp gs:get-attribute "acquainted" "centrality"
    if not empty? tmp [
      set centrality last tmp
    ]
  ]
end

;; Initialize Graphstream communication (from Netlogo to GS)
to setup-senders
  ;; The foreach is useless because we use only one graph in the GS's side
  ;; but we can add other graph in the futur
  gs:clear-senders
  (foreach (list "acquainted") (list 2001) [ ;; We give an ID to the graph and the number is the port used to transfer information on the network
      ;;The name is only used for the Netlogo's side. On the GS's side, we differentiate only with the port number.
    gs:add-sender ?1 "localhost" ?2 ;; It localhost but if you want to make a "real" server, have fun!
    gs:clear ?1
    ;; We add classical attributes in the graph.
    gs:add-attribute ?1 "ui.title" word ?1 " graph"
    gs:add-attribute ?1 "ui.antialias" true
    gs:add-attribute ?1 "ui.stylesheet" "node {size: 8px;} edge {fill-color: grey;}"
  ])
end

;; Initialize Graphstream communication (from GS to Netlogo)
;; /!\ must be executed BEFORE the start of the Java program
to setup-receivers
  gs:clear-receivers
  gs:add-receiver "acquainted" "localhost" 2002 ;; Like for the senders, we give an ID to the graph and the number is the port used to transfer information on the network
end

;; The following four procedures assign core turtle variables.  They use
;; the helper procedure RANDOM-NEAR so that the turtle variables have an
;; approximately "normal" distribution around the average values set by
;; the sliders.

to assign-sex-appeal  ;; turtle procedure
  set sex-appeal random-normal average-sex-appeal sd
end

to assign-sex-appeal-sensitivity  ;; turtle procedure
  set sex-appeal random-normal average-sex-appeal sd
end


to assign-infection-chance  ;; turtle procedure
  set infection-chance random-normal average-infection-chance sd
end


to assign-personality ;; turtle procedure
  set personality random-normal .51 sd
end

to assign-commitment  ;; turtle procedure
  set commitment random-near average-commitment
end
to-report random-near [center]  ;; turtle procedure
  let result 0
  repeat 40
    [ set result (result + random-float center) ]
  report result / 20
end


to propagate
 if infectious-dissemination [
  if infected? [ set color red]
     set current-time (current-time + 1)
     couple
     uncouple
   ]
  
if social-dissemination[
    
     change-attitude
]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Social network
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report %unsafe-neighbors
 report(  count link-neighbors with [condom-use? = false ])
  
end

to-report %safe-neighbors
 report(  count link-neighbors with [condom-use? = true ])
 
end

to-report %total-neighbors
 report (count link-neighbors)
end

to change-attitude
  if %total-neighbors != 0 [
  ifelse  %unsafe-neighbors / %total-neighbors > personality
  [set condom-use? false
   set color green ]
  [set condom-use? true  
   set color blue]
  ]
end

;;;
;;; GO PROCEDURES
;;;
to go

 if all? individuals [infected?] or %infected = 95
   [ stop ]
 
 check-sliders
 ask individuals [propagate]
 tick
end

;; Each tick, a check is made to see if sliders have been changed.
;; If one has been, the corresponding turtle variable is adjusted
to check-sliders
  if (slider-check-2 != average-sex-appeal)
    [ ask individuals [ assign-sex-appeal ]
      set slider-check-2 average-sex-appeal ]
   if (slider-check-1 != average-infection-chance)
    [ ask individuals [ assign-infection-chance ]
      set slider-check-1 average-infection-chance ]
end

;; People have a chance to couple depending on their tendency to have sex and
;; if they meet.  To better show that coupling has occurred, the patches below
;; the couple turn gray.
to couple  ;; turtle procedure -- righties only!
  if abstinence-time <=  current-time  and coupled? = false
  [ 
    let potential-partner one-of link-neighbors with 
    [not coupled? 
      and sex-appeal >= ([sex-appeal-sensitivity] of self) 
      and ([sex-appeal] of self) >= sex-appeal-sensitivity ]
    if potential-partner != nobody 
    [
      set current-time 0
      set partner potential-partner
      set coupled? true
      ask partner [ set partner myself 
                    set coupled? true ]
      infect self partner
      ask link [who] of self [who] of partner [set color blue
                                               set thickness .6 ]
    ]
  ]
end

;; If two peoples are together for longer than either person's commitment variable
;; allows, the couple breaks up.

to uncouple  ;; turtle procedure
  if coupled? 
    [ if (current-time > commitment) or
        (([current-time] of partner) > ([commitment] of partner))
        [ ask link [who] of self [who] of partner [set color green
                                                   set thickness .5]
          set coupled? false
          set current-time 0
          ask partner [ 
                        set current-time 0 
                        set partner nobody
                        set coupled? false 
                       ]
          set partner nobody 
          ] 
    ]
end

;; Infection can occur if either person is infected, but the infection is unknown.
;; This model assumes that people dont know if they are infected they  will continue to couple,
;; Note also that for condom use to occur, both people must want to use one.  If
;; either person chooses not to use a condom, infection is possible.  Changing the
;; primitive to AND in the third line will make it such that if either person
;; wants to use a condom, infection will not occur.
;; we have to change the propagation rule for the condom use
to infect  [ind-one ind-two]
  if ([infected?] of ind-one) = true or ([infected?] of ind-two) = true
  [ 
    if ([condom-use? = false ] of ind-one) and  ([condom-use? = false] of ind-two)
    [ 
      if random-float 1 < infection-chance
      [ 
        ask ind-one 
        [ 
          set infected? true
          set color red
        ]
        ask ind-two 
        [ 
          set infected? true
          set color red
        ]
      ] 
    ] 
  ]
end

;;; MONITOR PROCEDURE
;;;
to-report %infected
  ifelse any? individuals
    [ report (count individuals with [infected?] / count individuals) * 100 ]
    [ report 0 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Make the network ;;;
;;;;;;;;;;;;;;;;;;;;;;;;
to make-network
  ; Make the preferential attachement
  clear-all
  reset-ticks
  
  ;; make the initial network of two individuals and an edge
  make-node nobody nobody       ;; first node, unattached
  make-node (individual 0)  nobody     ;; second node, attached to first node
  
  ;; Make all individuals and links according to the preferential attachement rule
  let i 0
  while [i < (initial-people - 2)]
  [
    make-node find-partner find-partner
    set i (i + 1)
  ]
  layout
  tick
end

;; used for creating a new node
to make-node [old-node-one old-node-two]
  create-individuals 1
  [
    ;; Fill parameters
    set size 2
    set coupled? false
    set partner nobody
    set infected? false
    set condom-use? false
    set abstinence-time 10
    set current-time 0
    set color green
    assign-sex-appeal
    assign-sex-appeal-sensitivity
    assign-personality
    assign-commitment
    
    ;; Send a message to GS for the the new added node
    gs:add "acquainted"
    
    if old-node-one != nobody
    [
      setxy random-xcor random-ycor
      create-link-with old-node-one [
        set color green
        gs:add "acquainted"
      ]
    ]
    
    if (random-float 1 > 0.5)[
      if old-node-two != nobody [
        setxy random-xcor random-ycor
        create-link-with old-node-two [ 
          set color green
          gs:add "acquainted"
        ]
      ]
    ]
  ]
end

;; This code is borrowed from Lottery Example (in the Code Examples
;; section of the Models Library).
;; The idea behind the code is a bit tricky to understand.
;; Basically we take the sum of the degrees (number of connections)
;; of the individuals, and that's how many "tickets" we have in our lottery.
;; Then we pick a random "ticket" (a random number).  Then we step
;; through the individuals to figure out which node holds the winning ticket.
to-report find-partner
  let total random-float sum [count link-neighbors] of individuals
  let network-partner nobody
  ask individuals
  [
    let nc count link-neighbors
    ;; if there's no winner yet...
    if network-partner = nobody
    [
      ifelse nc > total
        [ set network-partner self ]
        [ set total total - nc ]
    ]
  ]
  report network-partner
end

;;;;;;;;;;;;;;
;;; Layout ;;;
;;;;;;;;;;;;;;

;; resize-nodes, change back and forth from size based on degree to a size of 1
to resize-nodes
  ifelse all? individuals [size <= 1]
  [
    ;; a node is a circle with diameter determined by
    ;; the SIZE variable; using SQRT makes the circle's
    ;; area proportional to its degree
    ask individuals [ set size sqrt count link-neighbors ]
  ]
  [
    ask individuals [ set size 1 ]
  ]
end

to layout
  layout-spring (turtles with [any? link-neighbors]) links 0.4 6 1
end
@#$#@#$#@
GRAPHICS-WINDOW
352
10
817
496
45
45
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
-45
45
-45
45
1
1
1
weeks
30.0

BUTTON
12
81
95
114
setup
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
100
81
183
114
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

MONITOR
193
76
276
121
% infected
%infected
2
1
11

SLIDER
7
37
302
70
initial-people
initial-people
50
500
100
1
1
NIL
HORIZONTAL

SLIDER
9
138
304
171
average-sex-appeal
average-sex-appeal
0
1
0.2
0.1
1
NIL
HORIZONTAL

SLIDER
10
236
305
269
nb-condom-use
nb-condom-use
0
initial-people
15
1
1
NIL
HORIZONTAL

BUTTON
940
120
1101
153
Make the network
make-network
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
11
283
122
316
nb-infected
nb-infected
0
initial-people
9
1
1
NIL
HORIZONTAL

SLIDER
9
187
304
220
average-infection-chance
average-infection-chance
0
1
0.4
0.1
1
NIL
HORIZONTAL

SLIDER
137
283
305
316
average-commitment
average-commitment
0
100
4
1
1
NIL
HORIZONTAL

SWITCH
862
26
1098
59
infectious-dissemination
infectious-dissemination
0
1
-1000

SWITCH
862
71
1099
104
social-dissemination
social-dissemination
1
1
-1000

BUTTON
862
120
937
153
layout
layout\ndisplay
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
893
161
1077
194
Setup GS connection
setup-receivers
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
836
271
1029
304
social-positive-bias
social-positive-bias
1
1
-1000

SWITCH
834
314
1034
347
social-negative-bias
social-negative-bias
1
1
-1000

SWITCH
824
366
1037
399
infection-positive-bias
infection-positive-bias
0
1
-1000

SWITCH
826
408
1046
441
infection-negative-bias
infection-negative-bias
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This is based on :

 Wilensky, U. (1997). NetLogo AIDS model. http://ccl.northwestern.edu/netlogo/models/AIDS. Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL. 

It is the sexually transmitted disease's spread inside a social network.
It use a connection with the Graphstream Library in order to analyze the spread according to the betwenness centrality of each individuals in the network.

## HOW IT WORKS

The model uses "couples" to represent two people engaged in sexual relations.  Individuals are conected to each other by social link. If they are connected, there is a chance the two individuals will "couple" together.

The presence of the virus in the population is represented by the colors of individuals. Three colors are used: green individuals are uninfected, and red individuals are infected and their infection is known, blue links are sexual relation between the two individuals.

Some individuals use condom. According to the place they take in the network, they are more likely or not to spread the disease.

The sex-appeal of each individual give them more or less chance to be in a sexual relation.


## CREDITS AND REFERENCES

Special thanks to the staff of the Complex System Summer School 2013 of the "Université du Havre".

## COPYRIGHT AND LICENSE

Copyright 2013 Thibaut DÉMARE, Lancine DIOP, Joanne HIRTZEL, Mariem JELASSI, Dorra LOUATI and Alexandre NAUD.

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.
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

person lefty
false
0
Circle -7500403 true true 170 5 80
Polygon -7500403 true true 165 90 180 195 150 285 165 300 195 300 210 225 225 300 255 300 270 285 240 195 255 90
Rectangle -7500403 true true 187 79 232 94
Polygon -7500403 true true 255 90 300 150 285 180 225 105
Polygon -7500403 true true 165 90 120 150 135 180 195 105

person righty
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105

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
NetLogo 5.0.4
@#$#@#$#@
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
