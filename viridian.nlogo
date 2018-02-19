breed [producers producer]
breed [consumers consumer]
breed [products product]
directed-link-breed [ownerships ownership]

globals [
  n-producers          ; how many producers to simulate?
  n-consumers          ; how many consumers to simulate?

  start-capital-factor ; starting capital for producers (factor to be multiplied with production cost of product)
  start-capital-con    ; starting capital for consumers

  milieus              ; list of consumer milieus
  milieu-fractions     ; what fractions of all consumers belong to the milieus?
  milieu-colors        ; each milieu has a different turtle color

  product-classes      ; different classes of products with different properties
  min-max-lifespans    ; for each product class: minimum and maximum of average lifespan range of products
  min-max-costs        ; for each product class: minimum and maximum of the production cost (if producer wants to earn her spendings, she needs the customer to pay at least this amount)
  lifespan-variances   ; for each product class: variance of average lifespan
  lifespan-vs-sust     ; for each product class: function mapping [0..10] (sustainability) onto [0..1] (0 means min-lifespan, 1 means max-lifespan)
  cost-vs-sust         ; for each product class: function mapping [0..10] (sustainability) onto [0..1] (0 means min-cost, 1 means max-cost)
  price-vs-prest        ; for each product class: function mapping [0..10] (prestige) onto [0..1] (0 means min-cost, 1 means max-cost)

  prestige-weights     ; for each product class: how are products weighted with respect to each other?

  income-distributions ; for each milieu: what is a typical income distribution?
  influentiabilities   ; for each milieu: how is the typical influentiability? (avg/std)

  consumption-needs    ; for each milieu: how are the typical consumption needs? (avg/std for each product class)
  sustainability-needs ; for each milieu: how are the typical sustainability needs? (avg/std)
  similarity-needs     ; for each milieu: how are the typical similarity needs? (avg/std)
  prestige-needs       ; for each milieu: how are the typical prestige needs? (avg/std)

  sustainability-tols  ; for each milieu: how much is sustainability of consumption allowed to deviate?
  similarity-tols      ; for each milieu: how much is similarity of consumption allowed to deviate?
  prestige-tols        ; for each milieu: how much is prestige of consumption allowed to deviate?
]

producers-own [
  capital              ; the current amount of money owned by the producer
  product-class        ; what class is the produced product in?
  product-class-index  ; what is the index of that product class? (useful for lookup in lists)
  sustainability       ; how sustainable is the produced product?
  lifespan             ; determined by product-class and sustainability: how many ticks until the produced product is on average broken (since it's been bought)?
  lifespan-variance    ; determined by product-class and sustainability: how much can actual lifespan deviate from average lifespan?
  prestige             ; how high is the prestige/quality (in terms of luxury, not longevity) of the product?
  cost                 ; what is the production cost per product?
  price                ; at what price does the producer decide to sell her product?
  n-products           ; how many products to produce each tick?
]

consumers-own [
  milieu
  income
  capital              ; how much money does the consumer currently have?
  influentiability     ; how easy is behaviour changed by interaction with neihgboring consumers (peers)?
  consumption-need     ; how much consumption does the individual want/need? (for each product class)
  sustainability-need  ; how sustainable shall consumption be?
  similarity-need      ; how much can consumption behaviour deviate from peers?
  prestige-need        ; how much prestige/quality (luxury) of products does the individual want? (avg/std)
  suppliers            ; list of producers (one per product class) where this consumer currently buys products
  sustainability-tol   ; how much may consumption deviate from sustainability goal?
  similarity-tol       ; how much may consumption deviate from similarity goal?
  prestige-tol         ; how much may consumption deviate from prestige goal?
]

products-own [
  product-class        ; what class does this product belong to?
;  quantity             ; how much of the product is currently stored in this product store? store individual products so this is always 1.
;  priority             ; how urgent does the consumer this product belongs to need more of it? store this not in the product, but in the consumer.
  lifespan             ; how many ticks until this product is on average broken (since it's been bought)?
  lifespan-variance    ; how much can actual lifespan deviate from average lifespan?
  age                  ; how many ticks since product was bought?
  sustainability       ; how sustainable was this product produced?
  prestige             ; how much prestige does the consumer get from owning this product? (how high is the quality?)
]



;;; GENERAL USEFUL FUNCTIONS MISSING IN NETLOGO ;;;

; report index of (first occurrence of) item in list
; create the cumulative sum of a list
to-report cumsum [lst]
  let result []
  let cs 0
  foreach lst [ x ->
    let new-val cs + x
    set result lput new-val result
    set cs new-val
  ]
  report result
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup
  clear-all
  setup-globals
  setup-consumers
  setup-producers
  reset-ticks
end

to setup-globals
  set n-producers 100
  set n-consumers 100
  set start-capital-factor 10
  set start-capital-con 2000
  set product-classes [
    "food"
    "textiles"
    "mobility-car"
    "mobility-alt"
    "IT"
    "others"
  ]
  set min-max-lifespans [
    [1 1] ; food
    [1 20] ; textiles
    [20 50] ; mobility-car
    [1 20] ; mobility-alt
    [10 30] ; IT
    [10 50] ; others
  ]
  set min-max-costs [
    [50 1000] ; food
    [100 2000] ; textiles
    [500 40000] ; mobility-car
    [50 200] ; mobility-alt
    [200 10000] ; IT
    [100 4000] ; others
  ]
  set lifespan-variances [
    0 ; food
    3 ; textiles
    10 ; mobility-car
    3 ; mobility-alt
    5 ; IT
    5 ; others
  ]
  set lifespan-vs-sust (list
    [ x -> 1 ] ; food
    [ x -> x / 10 ] ; textiles
    [ x -> x / 10 ] ; mobility-car
    [ x -> x / 10 ] ; mobility-alt
    [ x -> x / 10 ] ; IT
    [ x -> x / 10 ] ; others
  )
  set cost-vs-sust (list
    [ x -> x / 10 ] ; food
    [ x -> x / 10 ] ; textiles
    [ x -> x / 10 ] ; mobility-car
    [ x -> 1 - x / 10 ] ; mobility-alt
    [ x -> x / 10 ] ; IT
    [ x -> x / 10 ] ; others
  )
  set price-vs-prest (list
    [ x -> x / 10 ] ; food
    [ x -> x / 10 ] ; textiles
    [ x -> x / 10 ] ; mobility-car
    [ x -> x / 10 ] ; mobility-alt
    [ x -> x / 10 ] ; IT
    [ x -> x / 10 ] ; others
  )
  set prestige-weights [
    0.05 ; food
    0.15 ; textiles
    0.30 ; mobility-car
    0.05 ; mobility-alt
    0.15 ; IT
    0.30 ; others
  ]
  set milieus [
    "eco-aware"
    "conservative"
    "prestige-seeking"
    "small-income"
  ]
  set milieu-fractions [
    0.2
    0.5
    0.2
    0.1
  ]
  set milieu-colors [
    green
    gray
    pink
    blue
  ]
  set income-distributions [
    [500 500 1000 1000 1000 2000 2000 2000 2000 2000 2000 2000 3000 4000]
    [500 500 1000 1000 1000 1000 1000 1000 1000 2000 2000 2000 3000 4000]
    [500 1000 1000 1000 1000 2000 2000 2000 2000 2000 2000 3000 3000 3000 4000 4000]
    [500 500 500 500 500 500 1000 1000 1000]
  ]
  set influentiabilities [ ; mean standard-deviation
    [7.5 2.5] ; 7.5 +/- 2.5 eco
    [3 2]     ;   3 +/- 2   conservative
    [5.5 2.5] ; 5.5 +/- 2.5 prestige
    [5.5 2.5] ; 5.5 +/- 2.5 small income
  ]
  set consumption-needs [ ; average number of products bought per tick:
                          ; [mean std] if owns 0, [mean std] if owns 1, [mean std] if owns 2, [mean std] if owns 3 or more
    [ ; food
      [[1 0] [0 0] [0 0] [0 0]] ; eco
      [[1 0] [0 0] [0 0] [0 0]] ; conservative
      [[1 0] [0 0] [0 0] [0 0]] ; prestige
      [[1 0] [0 0] [0 0] [0 0]] ; small income
    ]
    [ ; textiles
      [[1 0] [0.2 0.1] [0.15 0.05] [0.01 0.01]] ; eco
      [[1 0] [0.5 0.3] [0.3 0.2] [0.05 0.05]] ; conservative
      [[1 0] [0.8 0.2] [0.5 0.2] [0.1 0.1]] ; prestige
      [[1 0] [0.1 0.1] [0.1 0.1] [0 0]] ; small income
    ]
    [ ; mobility-car
      [[0.5 0.2] [0.1 0.1] [0.01 0.01] [0 0]] ; eco
      [[1 0] [0.3 0.3] [0.01 0.01] [0 0]] ; conservative
      [[1 0] [0.5 0.2] [0.2 0.2] [0.1 0.1]] ; prestige
      [[0.7 0.2] [0.1 0.1] [0 0] [0 0]] ; small income
    ]
    [ ; mobility-alt
      [[0.8 0.2] [0.1 0.1] [0.01 0.01] [0 0]] ; eco
      [[0.3 0.2] [0.1 0.1] [0 0] [0 0]] ; conservative
      [[0.1 0.1] [0.1 0.1] [0 0] [0 0]] ; prestige
      [[0.7 0.2] [0.1 0.1] [0 0] [0 0]] ; small income
    ]
    [ ; IT
      [[0.8 0.2] [0.1 0.1] [0.01 0.01] [0 0]] ; eco
      [[1 0] [0.5 0.3] [0.01 0.01] [0 0]] ; conservative
      [[1 0] [0.7 0.3] [0.3 0.2] [0 0]] ; prestige
      [[0.7 0.2] [0.1 0.1] [0 0] [0 0]] ; small income
    ]
    [ ; other goods (luxury)
      [[0.8 0.2] [0.1 0.1] [0.01 0.01] [0 0]] ; eco
      [[1 0] [0.5 0.3] [0.01 0.01] [0 0]] ; conservative
      [[1 0] [0.7 0.3] [0.3 0.2] [0 0]] ; prestige
      [[0.7 0.2] [0.1 0.1] [0 0] [0 0]] ; small income
    ]
  ]
  set sustainability-needs [ ; mean standard-deviation
    [8 2] ;       8 +/- 2 eco
    [3 2] ;       3 +/- 2 conservative
    [1 1] ;       1 +/- 1 prestige
    [1 1] ;       1 +/- 1 small income
  ]
  set similarity-needs [ ; mean standard-deviation
    [5 3] ;       5 +/- 3 eco
    [7 3] ;       7 +/- 3 conservative
    [9 1] ;       9 +/- 1 prestige
    [5 3] ;       5 +/- 3 small income
  ]
  set prestige-needs [ ; mean standard-deviation
    [3 2] ; eco
    [7 2] ; conservative
    [9 1] ; prestige
    [5 4] ; small income
  ]
  set sustainability-tols [ ; how many points deviation is allowed?
    1 ; eco
    5 ; conservative
    10 ; prestige
    10 ; small income
  ]
  set similarity-tols [ ; how many points deviation is allowed?
    3 ; eco
    5 ; conservative
    2 ; prestige
    3 ; small income
  ]
  set prestige-tols [ ; how many points deviation is allowed?
    5 ; eco
    3 ; conservative
    1 ; prestige
    2 ; small income
  ]
end

to-report safe-random-normal [nmin nmax nmean std]
  let number random-normal nmean std
  if number < nmin [ set number nmin ]
  if number > nmax [ set number nmax ]
  report number
end

to setup-consumers
  create-consumers n-consumers [
    set shape "turtle"
    set milieu 0
  ]
  let i 0
  foreach milieus [ m ->
    let f (item i milieu-fractions)
    ask n-of int (f * n-consumers) consumers with [milieu = 0] [set milieu m]
    ask consumers with [milieu = m] [
      set income one-of item i income-distributions
      set capital start-capital-con
      set influentiability safe-random-normal 0 10 item 0 item i influentiabilities item 1 item i influentiabilities
      set consumption-need []
      foreach consumption-needs [ cn ->
        set consumption-need lput (
          map [ j -> safe-random-normal 0 1 item 0 item j item i cn item 1 item j item i cn ] [0 1 2 3]
        ) consumption-need
      ]
      set sustainability-need safe-random-normal 0 10 item 0 item i sustainability-needs item 1 item i sustainability-needs
      set similarity-need safe-random-normal 0 10 item 0 item i similarity-needs item 1 item i similarity-needs
      set prestige-need safe-random-normal 0 10 item 0 item i prestige-needs item 1 item i prestige-needs
      set sustainability-tol item i sustainability-tols
      set similarity-tol item i similarity-tols
      set prestige-tol item i prestige-tols

      setxy sustainability-need / 10 * max-pxcor prestige-need / 10 * max-pycor
      set color item i milieu-colors
    ]
    set i i + 1
  ]
end

; consumer method, returns list of consumer demands
to-report consumer-demand [pc-index]
  let pc item pc-index product-classes
  report item (
      count out-ownership-neighbors with [product-class = pc]
    ) item pc-index consumption-need
end

; what is exepctation value for next tick's consumption of a certain product class?
to-report demand [pc-index] ; index of the product class
  report sum [consumer-demand pc-index] of consumers
end

; report demands of all product classes
to-report demands
  let result []
  let pc-index 0
  while [pc-index < length product-classes] [
    set result lput (demand pc-index) result
    set pc-index pc-index + 1
  ]
  report result
end

to-report cumulative-demand [pc-index] ; index of the product class
  let pc item pc-index product-classes
  let ids sort [who] of consumers ; because order of 'of' is random, use the sorted whos for defined order
  let cs cumsum map [ x ->
    [
      item (
        count out-ownership-neighbors with [product-class = pc]
      ) item pc-index consumption-need
    ] of consumer x
  ] ids
  set cs map [ x -> x / demand pc-index ] cs
  report lput 1 but-last cs
end

; producers look at consumers' wishes, so must be created after consumers
to setup-producers
  create-producers n-producers [
    setup-producer
  ]
end

to setup-producer
  setxy random-xcor random-ycor
  hide-turtle

  ; select a random product class, with probability corresponding to demand (the product-class never changes across lifetime of producer)
  ; first calculate cumulative probabilities from the demands
  let demands-sum sum demands
  let demands-cumsum map [ x -> x / demands-sum ] cumsum demands
  ; draw a random number n between 0 and 1, the product class index is the index of the first cumsum entry larger than that number
  let n random-float 1
  set product-class-index position true map [ x -> n < x ] demands-cumsum
  set product-class item product-class-index product-classes

  orient-producer

  set capital start-capital-factor * cost
end

; the producer decides (maybe redecides) about sustainability and prestige of her product
to orient-producer
  let i product-class-index

  ; determine a randomly selected customer on which to orient the production (sustainability and prestige)
  let n random-float 1
  let target position true map [ x -> n < x ] cumulative-demand i

  set sustainability [sustainability-need] of consumer target

  let min-lifespan item 0 item i min-max-lifespans
  let max-lifespan item 1 item i min-max-lifespans
  let lifespan-f (item i lifespan-vs-sust)
  let dynamic-value (runresult lifespan-f sustainability)
  set lifespan (max-lifespan - min-lifespan) * dynamic-value + min-lifespan
;  set lifespan random-float (max-lifespan - min-lifespan) + min-lifespan
  set lifespan-variance item i lifespan-variances

  set prestige [prestige-need] of consumer target

  let min-cost item 0 item i min-max-costs
  let max-cost item 1 item i min-max-costs
  let cost-f (item i cost-vs-sust)
  let price-f (item i price-vs-prest)
  let sust-factor (runresult cost-f sustainability)
  let prest-factor (runresult price-f prestige)
  ifelse (sust-factor > prest-factor) [
    ; the product shall not have a price lower than cost, so include low prest-factor
    ; in the production cost
    set cost (max-cost - min-cost) * (mean list sust-factor prest-factor) + min-cost
    set price cost
  ]
  [
    ; the product's production cost is only determined by sust-factor (low cost),
    ; but the high prestige comes at a higher price for consumer
    set cost (max-cost - min-cost) * sust-factor + min-cost
    let min-price cost
    let max-price (max-cost - min-cost) * (mean list sust-factor prest-factor) + min-cost
    ; choose a random price between production cost and prestige boosted cost
    set price (max-price - min-price) * random-float 1 + min-price
  ]
  set n-products -1
end

to go
  ask consumers [use-products]
  ask producers [produce]
  ask consumers [consume]
  ask consumers [be-influenced]
  ask producers [re-orient]
  tick
end

; consumer method
to use-products
end

; consumer method
to-report can-buy-at? [prod]
  report (
    sustainability-need - sustainability-tol < [sustainability] of prod and
    sustainability-need + sustainability-tol > [sustainability] of prod and
    prestige-need - prestige-tol < [prestige] of prod and
    prestige-need + prestige-tol > [prestige] of prod
  )
end

; producer method
to produce
  if n-products < 0 [
    ; determine n-products anew
    let target-group consumers with [can-buy-at? myself]
    let target-demand sum [consumer-demand [product-class-index] of myself] of target-group
    let competitors producers with [
      ; can any consumer in the target group also buy at this producer? does it produce the same product class? then it's a competitor
      product-class-index = [product-class-index] of myself and
      member? true [can-buy-at? myself] of target-group
    ]
    let risk (random 3) + 1
    set n-products min list (int (target-demand / (count competitors)) * risk) 10
  ]
  ; check if you have enough money
  set capital capital - cost * n-products
  hatch-products n-products [
    set age 0
    create-ownership-from myself
  ]
end

; consumer method
to consume
end

; consumer method
to be-influenced
end

; producer method
to re-orient
end
@#$#@#$#@
GRAPHICS-WINDOW
221
17
763
560
-1
-1
31.412
1
10
1
1
1
0
1
1
1
0
16
0
16
0
0
1
ticks
30.0

BUTTON
27
52
100
85
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
109
52
190
85
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

PLOT
801
13
1149
279
Sustainability needs
Sustainability need
Number of turtles
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [sustainability-need] of consumers"

PLOT
1165
14
1509
280
Similarity needs
Similarity need
Number of turtles
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [similarity-need] of consumers"

PLOT
802
298
1149
561
Prestige needs
Prestige need
Number of turtles
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [prestige-need] of consumers"

PLOT
190
595
390
745
Sustainability of food companies
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
"default" 1.0 0 -16777216 true "" "histogram [sustainability] of producers with [product-class = \"food\"]"

PLOT
456
595
656
745
Sustainability of textile companies
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
"default" 1.0 0 -16777216 true "" "histogram [sustainability] of producers with [product-class = \"textiles\"]"

PLOT
702
595
902
745
Sustainability of mobility companies
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
"default" 1.0 0 -16777216 true "" "histogram [sustainability] of producers with [product-class = \"mobility-car\"]"

PLOT
1173
597
1373
747
Sustainability of IT companies
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
"default" 1.0 0 -16777216 true "" "histogram [sustainability] of producers with [product-class = \"IT\"]"

PLOT
1419
602
1619
752
Sustainability of other companies
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
"default" 1.0 0 -16777216 true "" "histogram [sustainability] of producers with [product-class = \"others\"]"

PLOT
1175
301
1510
567
Production costs
Cost / 100
Number of products
0.0
50.0
0.0
10.0
true
false
"; set-plot-x-range 0 max [cost / 100] of producers" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [cost / 100] of producers"

PLOT
935
595
1135
745
Sustainability of mobility-alt
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
"default" 1.0 0 -16777216 true "" "histogram [sustainability] of producers with [product-class = \"mobility-alt\"]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.0.2
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
