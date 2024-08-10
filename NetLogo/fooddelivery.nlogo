extensions [rngs]

globals[
  ; phase counter
  all-phases
  all-phases-abbr
  current-phase
  current-phase-abbr
  phase-counter
  ; patch indices for building the city grid
  road-patch-all-index
  road-patch-right-index
  road-patch-left-index
  road-patch-up-index
  road-patch-down-index
  traffic-light-patch-index

  ; patch agentsets for building the city grids
  intersections            ; agentset containing the patches that are intersections
  roads                    ; agentset containing the patches that are roads
  streets                  ; agentset containing the patches that are roads excluding intersections

  ; patch agentsets for districts and zones of a city

  building-locations
  ; phase of the traffic:
  row-green?
  col-green?
  restaurants-with-meal
  total-delivered
  total_delivered_prev
  total_ordered
  total_discarded
  time_past_in_minutes
  time_formatted
  time_hours_of_day
  time_minutes_of_day
  lowest_number_deliverd
  delivered_past_hour
  ordered_this_tick
  delivered_this_tick
  discarded_this_tick
  chance_of_this_tick
  prev_chance_of_this_tick
  setup-complete
  weeknumber
  delivered_per_week
  average_number_deliveries_per_week

]

breed [ deliverers deliverer ]
breed [ restaurants restaurant]
breed [ customers customer ]
breed [ meals meal ]


deliverers-own[
  is-free?
  meal_nr
  time-active
  number-delivered
  number-delivered-past-week
  total-earnings
  prev-intersection
  decide_on_x?
  d-xcor
  d-ycor
  pickup-xcor
  pickup-ycor
  deliver-xcor
  deliver-ycor
  intersection-dir
  delivery-direction ; "restaurant" or "customer"

]



restaurants-own[
  meals-to-be-delivered
  meals-claimed
  meal-delivery-time ; number of ticks a meal is still deliverable
]

customers-own[
  order-outstanding?
  meal_nr
  rest-xcor
  rest-ycor
  happiness
]

meals-own [
  restaurant_nr
  customer_nr
  deliverer_nr
  freshness
  tick_ordered
  prepair_time
  status_ordered?
  status_ready?
  status_in_transit?
  status_delivered?
  status_expired?
]

patches-own[
  ; patch identity check
  is-road?
  is-intersection?
  ; controlling the direction of the traffic for each patch
  left?
  right?
  up?
  down?
  num-directions-possible
  ; traffic rules
  ; district and zone characteristics
  is-restaurant-location?
  is-client-location?
]

; The current grid size is 65x65
; To create a grid system, for any given row and column,
; there are 9 blocks with each spans for 5 patches separate by roads which spans 2 patches
; 1 tick = 1 minute
to setup
  clear-all
  setup-globals
  setup-patches
  setup-road-direction
  setup-deliverers
  setup-restaurants
  setup-customers
  reset-ticks
  set setup-complete 1
  print (word "number-of-restaurants " number-of-restaurants)
  print (word "number-of-customers " number-of-customers )
  print (word "number-of-deliverers " number-of-deliverers)
  print (word "prepair_time_mean " prepair_time_mean )
  print (word "wait_for_deliverer " wait_for_deliverer )
  print (word "order_frequency "  order_frequency)
  print (word "distribution_method " distribution_method)

end

to go
  ifelse setup-complete > 0 [



  update_time
  set ordered_this_tick 0
  set delivered_this_tick 0
  set discarded_this_tick 0
  set chance_of_this_tick (get_chance_minute time_minutes_of_day)

  if prev_chance_of_this_tick != chance_of_this_tick
  [print (word "order probability changed: " time_formatted " " (precision chance_of_this_tick 6) )]

  report-current-phase
  all-customers-behaviors
  all-restaurants-behaviors
  all-meals
  all-deliverers-behaviors

  set prev_chance_of_this_tick chance_of_this_tick
  tick
  ]
  [
    error "run setup first"
  ]

end


to export_all
  ;;export-world user-new-file
  export-output user-new-file
end


to update_time
  set time_past_in_minutes ticks
  set time_minutes_of_day (time_past_in_minutes mod (24 * 60))
  let time_minutes (time_past_in_minutes mod 60)
  let time_hours ((time_past_in_minutes - time_minutes) / 60 )
  let time_days floor(time_hours / 24)
  let minute_padding ""
  if time_minutes < 10 [set minute_padding "0"]
  set time_hours_of_day (time_hours mod 24)

  if time_hours_of_day = 0 and time_minutes = 0 [
    set total_ordered 0
    set total-delivered 0
    set total_discarded 0
  ]

  set time_formatted (word time_days " " time_hours_of_day  ":" minute_padding time_minutes)

  if time_minutes = 0 [
      set delivered_past_hour  (total-delivered - total_delivered_prev)
      set total_delivered_prev total-delivered
  ]

  if ticks > 0  and (remainder ticks (60 * 24 * 7)) = 0 [
    print "week is past"
    set average_number_deliveries_per_week  (delivered_per_week / (count deliverers))
    set weeknumber (weeknumber  + 1)
    set delivered_per_week 0
  ]

end


to all-restaurants-behaviors
  ask restaurants [restaurant-behavior]
end


to all-deliverers-behaviors
  ask deliverers [deliverer-behavior]
end


to all-customers-behaviors
  ask customers [customer-behavior]
end

to all-meals
  ask meals [
    if distribution_method = "nearest_deliverer" and status_ordered? = true and deliverer_nr = -1[
      print "nearest_deliverer"
      let this_meal self
      let free_deliverers deliverers with [is-free? = true]
      let closest_deliverer min-one-of free_deliverers [distance self]

      if closest_deliverer != nobody [
        let x-res 0
        let y-res 0
        let restaurant_of_meal 0
        let customer_of_meal 0

        set deliverer_nr closest_deliverer
        set x-res xcor
        set y-res ycor
        set restaurant_of_meal restaurant_nr
        set customer_of_meal customer_nr


        let x-cust 0
        let y-cust 0

        ask customer_of_meal [
          set x-cust xcor
          set y-cust ycor
        ]

        ask closest_deliverer [
          set meal_nr this_meal
          set pickup-xcor x-res
          set pickup-ycor y-res
          set deliver-xcor x-cust
          set deliver-ycor y-cust
          set delivery-direction "restaurant"
          set is-free?  false
          set label (word pickup-xcor "," pickup-ycor)
          set color red
          show (word " has claimed  " this_meal  " from " restaurant_of_meal " and " customer_of_meal)

        ]
      ]
    ]

    let minutes_from_order (ticks - tick_ordered)
    if minutes_from_order =  prepair_time [ ;; after 10 minutes it is ready to be picked up
      change_meal_status "ready"
      set color green
    ]
    if status_ready? and minutes_from_order = (wait_for_deliverer + prepair_time) [;; after 20 minutes and no pickup it is expired
      change_meal_status "expired"
    ]

    if status_delivered? [
       change_meal_status "delivered"
    ]
    if  status_expired? [
       set discarded_this_tick  ( discarded_this_tick + 1 )
       set total_discarded ( total_discarded + 1)
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set meal status ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to change_meal_status [#s]
  (ifelse
    #s = "ordered" [
      set status_ordered? true
      set status_ready? false
      set status_in_transit? false
      set status_delivered? false
      set status_expired? false
    ]
    #s = "ready" [
      set status_ordered? false
      set status_ready? true
      set status_in_transit? false
      set status_delivered? false
      set status_expired? false
    ]
    #s = "in_transit" [
      set status_ordered? false
      set status_ready? false
      set status_in_transit? true
      set status_delivered? false
      set status_expired? false
    ]
    #s = "delivered" [
      set status_ordered? false
      set status_ready? false
      set status_in_transit? false
      set status_delivered? true
      set status_expired? false
    ]
    #s = "expired" [
      set status_ordered? false
      set status_ready? false
      set status_in_transit? false
      set status_delivered? false
      set status_expired? true
    ]
  )

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; all deliverer behavior rules ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to deliverer-behavior
  if is-free? and distribution_method = "nearest_meal" [
    find-a-delivery  ;; distribution of meals
  ]

  if is-free? and distribution_method = "equally_distributed" [
    if lowest_number_deliverd = number-delivered [
      find-a-delivery
    ]
  ]

  if ticks > 0 and (remainder ticks (60 * 24 * 7)) = 0 [
    if number-delivered-past-week < 15 [
      die
    ]
    set number-delivered-past-week 0

  ]


  let deliverer_itself self
  if not is-free? [

    let meal_for_deliverer meal_nr ;; this uses the fact that all agents have a unique number in NetLogo

    ifelse meal_for_deliverer = nobody [ ;; the meal has expired
      set is-free? true
      show (word "meal cancelled by restaurant " meal_nr)
      set color white
      set label "x"
    ]

    [


    let picked-up? false
    let delivered? false ;; check neigbors
    let wait_at_restaurant? false



    ifelse delivery-direction = "restaurant"  [
      ask neighbors4
      [
        ask restaurants-here
        [
          let restaurant_itself self


          ask meal_for_deliverer
          [
            if restaurant_nr = restaurant_itself and status_ready? = true
            [

              ;;set status_in_transit? true
              set picked-up? true
              print (word deliverer_itself " picked-up meal nr. " meal_for_deliverer)
              change_meal_status "in_transit"
            ]

            if restaurant_nr = restaurant_itself and status_ordered? = true
            [
              print (word deliverer_itself " is waiting for meal to be ready, nr. " meal_for_deliverer)
              set wait_at_restaurant? true
            ]
          ]

        ]
      ]
    ][
      ask neighbors4
      [
        ask customers-here
        [
          let customer_itself self
          ask meal_for_deliverer
          [
            if customer_nr = customer_itself
            [
              set status_in_transit? false
              set delivered? true
              change_meal_status "delivered"

              print (word deliverer_itself " delivered meal " meal_for_deliverer)
            ]
          ]
        ]
      ]
    ]

    if picked-up? [
       set delivery-direction "customer"
       set color green
       set label (word deliver-xcor "," deliver-ycor "e:" number-delivered)
    ]

    if delivered? [
      set is-free?  true
      set color white
      set delivered_this_tick ( delivered_this_tick + 1)
      set number-delivered-past-week (number-delivered-past-week + 1)

      set delivered_per_week  (delivered_per_week + 1)
      set total-delivered total-delivered + 1
      set number-delivered number-delivered + 1
      let lowest_number_deliverd-prev lowest_number_deliverd
      set lowest_number_deliverd min [number-delivered] of deliverers
      set label (word "e:" number-delivered)
    ]

      if not wait_at_restaurant?[
        deliverers-move-to-location
      ]
  ]

   ]

end

to restaurant-behavior
   let restaurant_itself self
   set label count meals with [restaurant_nr = restaurant_itself and status_delivered? = false and status_expired? = false]
end

to-report get_chance_minute [#x] ;distribution of orders
  let _result 0
  (
    ifelse #x >= (7 * 60) and #x < (8 * 60) [
     set _result ( 2 / (24 * 60 * 1))
    ]

     #x >= (12 * 60) and #x < (13 * 60) [
     set _result ( 4 / (24 * 60 * 1))
    ]

     #x >= (18 * 60) and #x < (20 * 60) [
     set _result ( 12  / (24 * 60 * 2))
    ]
    [
      set _result ( 6 / ( 24 * 60 * 20 ))
    ]
  )
  ifelse order_frequency = "once a day"
  [report ( _result)]
  [report ( _result / 7)]
end


to customer-behavior
  let customer_itself self
  if (order-outstanding? = false and (random-float 1) <= chance_of_this_tick) [
    order_meal
  ]
  let ready_for_next? false
  let happiness_loc happiness
  ifelse meal_nr != nobody [
    ask customer_itself [
      set color red
    ]
    ask meal_nr [

      if status_expired? [
        show "expired"
        set happiness_loc (happiness_loc - 1)
        set ready_for_next? true
        die
      ]
      if status_delivered? [
        show "delivered"
        set happiness_loc (happiness_loc + 1)
        set ready_for_next? true
        die
      ]

    ]

  ]
  [
    set color 106
    set order-outstanding? false
  ]

  if ready_for_next? [
    set order-outstanding? false
  ]

  set happiness happiness_loc
  set label happiness

  ifelse order-outstanding? [
   set color red
  ]
  [
  if happiness >= 0 and happiness < 4 [
    set color 106 - happiness
  ]
  if happiness >= 4 [
     set color 106 - 4
  ]
  if happiness < 0 [
    set color 112 + happiness
  ]

  ]
  if happiness < -1 [
     die
  ]


end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create meal, called by a customer ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to order_meal
  let customer_itself self ;; the caller of this function
  let selected_restaurant one-of restaurants ;; a random restuarant
  let meal_nr_loc -1
  hatch-meals 1 [ ;; create a meal
    set meal_nr_loc self
    set color orange
    set restaurant_nr selected_restaurant
    set customer_nr customer_itself
    set shape "apple"
    set freshness 15
    set label ""
    set size 1
    set tick_ordered ticks
    set deliverer_nr -1
    change_meal_status "ordered"
    move-to selected_restaurant
    set prepair_time (int (random-normal prepair_time_mean prepair_time_stdev))
    if prepair_time < 0 [
       set prepair_time 0
    ]
    if prepair_time > 120 [
       set prepair_time 120
    ]
    set ordered_this_tick (ordered_this_tick + 1)
    set total_ordered (total_ordered + 1)
    show (word " is ordered at "  selected_restaurant  ", by " customer_itself ", prepair time is " prepair_time )
  ]

  set meal_nr meal_nr_loc
  set order-outstanding? true
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; find a delivery, called by a deliverer ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to find-a-delivery  ;; with  "nearest_meal" selected
  let deliverer_itself self

  let ordered_meals meals with [
    status_ordered? = true and
    deliverer_nr = -1
  ]

  let meal_without_deliverer min-one-of ordered_meals [distance deliverer_itself]

  if meal_without_deliverer != nobody
  [
    let x-res 0
    let y-res 0


    let restaurant_of_meal 0
    let customer_of_meal 0

    ask meal_without_deliverer  [
      set deliverer_nr deliverer_itself
      set x-res xcor
      set y-res ycor
      set restaurant_of_meal restaurant_nr
      set customer_of_meal customer_nr
    ]

    let x-cust 0
    let y-cust 0

    ask customer_of_meal [
      set x-cust xcor
      set y-cust ycor
    ]

    set meal_nr meal_without_deliverer
    set pickup-xcor x-res
    set pickup-ycor y-res
    set deliver-xcor x-cust
    set deliver-ycor y-cust

    set delivery-direction "restaurant"
    set is-free?  false
    set color red
    set label (word pickup-xcor "," pickup-ycor)
    show (word " has claimed  " meal_without_deliverer  " from " restaurant_of_meal " and " customer_of_meal)
  ]
end

to setup-restaurants
  create-restaurants number-of-restaurants [
    set color white
    set meals-to-be-delivered []
    set meals-claimed []
    set size 2
    set shape "house"
    set meal-delivery-time 0
   ]
  ask restaurants [ move-to one-of building-locations with [not any? restaurants-on self] ]
end

to setup-customers
  create-customers number-of-customers [
    set color 106
    set size 3
    set shape "house efficiency"
    set order-outstanding? false
    set meal_nr nobody
   ]
  ask customers [ move-to one-of building-locations with [not any? restaurants-on self and not any? customers-on self ] ]
end

;locations for buildings
to setup-building-locations
  let temp-list []
  foreach [-28 -21 -14 -7 0 7 14 21 28 ]
  [ x ->
    foreach [-28 -21 -14 -7 0 7 14 21 28]
    [
      y ->
      foreach [[-2 -2] [-2 -1] [-2 0] [-2 1] [-2 2] [-1 -2] [-1 2] [0 -2] [0 2] [1 2] [1 -2] [2 -2] [2 -1] [2 0] [2 1] [2 2]]  [
       nm ->
      set temp-list lput (word (x + (item 0 nm))  "." (y + (item 1 nm))) temp-list
      ]
    ]
  ]
  set building-locations patches with [
    member? (word pxcor "." pycor)  temp-list
  ]

  ask building-locations[
        set pcolor brown
        set is-restaurant-location? false
        set is-client-location? false
  ]
end


to deliverers-move-random
  ifelse num-directions-possible = 1 [
    set prev-intersection 0
    (ifelse right? [move-right]
      left? [move-left]
      up? [move-up]
      down? [move-down])
  ][
    ; turtle behavior in the intersection
    ; need to prevent taxicabs looping in the intersections
    set prev-intersection prev-intersection + 1
    ; this taxicab attribute tracks
    ; how many ticks have turtle spent on an intersection
    (ifelse
      up? and right? [
        ifelse prev-intersection = 2 [ move-right ][ifelse random 2 = 0 [ move-up ][ move-right ] ]
      ]
      up? and left? [
        ifelse prev-intersection = 2 [ move-up ][ ifelse random 2 = 0 [move-up][move-left] ]
      ]
      down? and right? [
        ifelse prev-intersection = 2 [ move-down ][ifelse random 2 = 0 [ move-down ][ move-right ] ]
      ]
      down? and left? [
        ifelse prev-intersection = 2 [ move-left ] [ ifelse random 2 = 0 [ move-down ][ move-left ] ]
      ]
    )
  ]
end

to deliverers-move-to-location
  ;print (word "van: " xcor "," ycor)
  ;print (word "naar: " pickup-xcor "," pickup-ycor)
  let go-x 0
  let go-y 0

  if delivery-direction = "customer"
  [
    set go-x (deliver-xcor - xcor)
    set go-y (deliver-ycor - ycor)
  ]

  if delivery-direction = "restaurant"
  [
    set go-x (pickup-xcor - xcor)
    set go-y (pickup-ycor - ycor)
  ]


  ifelse not is-intersection? [
    (ifelse right? [move-right]
      left? [move-left]
      up? [move-up]
      down? [move-down])
    set prev-intersection 0
  ]
  [
    ; turtle behavior in the intersection
    ; need to prevent taxicabs looping in the intersections
    set prev-intersection prev-intersection + 1
    ; this taxicab attribute tracks
    ; how many ticks have turtle spent on an intersection
    let xdir ""
    let ydir ""

    if prev-intersection = 1 [
      ifelse go-x > 0 [set xdir "r"] [set xdir "l"]
      ifelse go-y > 0 [set ydir "u"] [set ydir "d"]
      if (abs go-x) > (abs go-y)  [set intersection-dir xdir]
      if (abs go-x) < (abs go-y)  [set intersection-dir ydir]
      if (abs go-x) = (abs go-y) [
            let r (random 1)
            ifelse r = 0
            [set intersection-dir xdir][set intersection-dir ydir]
      ]
    ]

    (ifelse
      up? and right? [
        ifelse intersection-dir = "r" [move-right] [move-up]
       ]
      up? and left? [
        ifelse intersection-dir = "u" [move-up] [move-left]
      ]
      down? and right? [
        ifelse intersection-dir = "d" [move-down] [move-right]
      ]
      down? and left? [
        ifelse intersection-dir = "l" [move-left] [move-down]
      ]

      up?  [move-up]
      down? [move-down]
      left? [move-left]
      right? [move-right]
    )

  ]
end




;; create deliverers
to setup-deliverers
  create-deliverers number-of-deliverers [
    set time-active 0
    set number-delivered 0
    set size 2
    set is-free? true
    set shape "bike"
    set color white
    set decide_on_x? true
    set label "--"
   ]


  ask deliverers [ move-to one-of roads with [not any? deliverers-on self] ]
  fix-deliverers-direction
end

to fix-deliverers-direction
  ask roads [
    ; multi-direction patches
    if up? and not down? and not left? and right? [
      ask deliverers-here [
        ifelse random 100 > 50 [set heading 0][set heading 90]
      ]
    ]
    if up? and not down? and left? and not right? [
      ask deliverers-here [
        ifelse random 100 > 50 [set heading 0][set heading 270]
      ]
    ]
    if not up? and down? and not left? and right? [
      ask deliverers-here [
        ifelse random 100 > 50 [set heading 180][set heading 90]
      ]
    ]
    if not up? and down? and left? and not right? [
      ask deliverers-here [ifelse random 100 > 50 [set heading 180][set heading 270]
      ]
    ]
    ; single direction patches
    if up? and not down? and not left? and not right? [ask deliverers-here [set heading 0]]
    if not up? and down? and not left? and not right? [ask deliverers-here [set heading 180]]
    if not up? and not down? and left? and not right? [ask deliverers-here [set heading 270]]
    if not up? and not down? and not left? and right? [ask deliverers-here [set heading 90]]]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Setup all patches ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-patches
  build-roads
  build-intersections
  ;;build-traffic-lights
  setup-building-locations
end


; Helper that takes a list as input
; 1. turn all elements in a list negative
; 2. concatenate both negative and positive lists
to-report create-full-list [lst]
  ;; convert the input list all to negative
  let neg-lst map [i -> i * -1] lst
  ;; concatenate the negative lst with the original pos list
  let full-lst sentence neg-lst lst
  report full-lst
end

to setup-globals
  set restaurants-with-meal []


  ; define the color of the neighborhoods
  ask patches [
    set pcolor [207 207 207] ;; cherry red

    ; patch identity
    set is-road? false
    set is-intersection? false

    ; patch direction
    set left? false
    set right? false
    set up? false
    set down? false
    set num-directions-possible 0
    ;; set phase for the traffic light
    set row-green? true
    set col-green? false
  ]

  ; Identify roads with positive road index number
  let road-patch-pos [3 4 10 11 17 18 24 25 31 32]

  ; Use create-full-list procedure to get all road patch index
  set road-patch-all-index create-full-list (road-patch-pos)

  ; Identify roads that can only go right
  let road-patch-right-pos [3 10 17 24 31]
  let road-patch-right-neg map[i -> (i + 1) * -1] road-patch-right-pos
  set road-patch-right-index sentence road-patch-right-pos road-patch-right-neg

  ; Identify roads that can only go left
  let road-patch-left-pos [4 11 18 25 32]
  let road-patch-left-neg map[i -> (i - 1) * -1] road-patch-left-pos
  set road-patch-left-index sentence road-patch-left-pos road-patch-left-neg

  ; Identify roads that can only go top
  set road-patch-up-index road-patch-left-index;

  ; Identify roads that can only go bottom
  set road-patch-down-index road-patch-right-index;

  ; set up all phases
  set all-phases ["AM Peak" "Midday" "PM Peak" "Evening" "Early Morning"]
  set current-phase first all-phases
  set all-phases-abbr["AM" "MD" "PM" "EVE" "EM"]
  set current-phase-abbr first all-phases-abbr

  set phase-counter 1
  set total-delivered 0
  set delivered_past_hour 0
  set total_delivered_prev 0
end

;;;;;;;;;;;;;;;;;
;; Build roads ;;
;;;;;;;;;;;;;;;;;
to build-roads
  set roads patches with [
    member? pycor road-patch-all-index or
    member? pxcor road-patch-all-index
  ]
  ask roads [
    set is-road? true
    set pcolor black
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Build intersections ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to build-intersections
  set intersections roads with [
    member? pycor road-patch-all-index and
    member? pxcor road-patch-all-index
  ]
  ask intersections [
    set is-intersection? true
    set is-road? true
    set pcolor black
  ]
  ; build streets which separate intersection and roads
  set streets roads with [not member? self intersections]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Draw road direction ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-road-direction
  ; first set all roads with dummy direction to false
  ask roads [
    set right? false
    set left? false
    set up? false
    set down? false
  ]

  ; change roads direction dummy according to road patch index
  ask roads[
    if member? pycor road-patch-right-index[set right? true]
    if member? pycor road-patch-left-index[set left? true]
    if member? pxcor road-patch-up-index[set up? true]
    if member? pxcor road-patch-down-index[set down? true ]
  ]

  ; Adjust corner cases
  ; if a deliverer at the most top roads cannot go further top
  ask roads with [pycor = 32] [set up? false]
  ; if a deliverer at the most bottom roads cannot go further bottom
  ask roads with [pycor = -32] [set down? false]
  ; if a deliverer at the most right roads cannot go further right
  ask roads with [pxcor = 32][set right? false]
  ; if a deliverer at the most left roads cannot go left
  ask roads with [pxcor = -32][set left? false]

  ; fix some corner cases
  ; left upper corner
  ask patch -31 32 [
    set up? false
    set left? true
  ]

  ; left lower corner
  ask patch -32 -31 [
    set left? false
    set down? true
  ]
  ask patch 32 31 [
    set right? false
    set up? true
  ]

  ; right lower corner
  ask patch 31 -32 [
    set down? false
    set right? true
  ]

  ; count the number of directions possible for each road patches
  ask patches [
    if up? [set num-directions-possible num-directions-possible + 1]
    if down? [set num-directions-possible num-directions-possible + 1]
    if right? [set num-directions-possible num-directions-possible + 1]
    if left? [set num-directions-possible num-directions-possible + 1]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;
;;;; Global Clock ;;;;
;;;;;;;;;;;;;;;;;;;;;;
to report-current-phase
  ; there are a total of 5 time phases of a day
  ; so in case of the counter is exceeding 4
  ; set the counter back to 0
  if phase-counter > 4 [
      set phase-counter 0
    ]
  ; initial setting first phase is "AM Peak" and the counter is set to be 1
  ; so this will let the first phase go through the whole time period without
  ; jumping to the second phase at the very beginning
  if ticks >= 100 and ticks mod 100 = 0 [
    set current-phase item phase-counter all-phases
    set current-phase-abbr item phase-counter all-phases-abbr
    set phase-counter phase-counter + 1
  ]
end


;;;;;;;;;;;;;;;;;;;;
;;;;deliverer Movement;;;
;;;;;;;;;;;;;;;;;;;;
to move-up
  set heading 0
  stop-for-red-else-go
end

to move-down
  set heading 180
  stop-for-red-else-go
end

to move-right
  set heading 90
  stop-for-red-else-go
end

to move-left
  set heading 270
  stop-for-red-else-go
end

to stop-for-red-else-go
    ; in case there is another taxicabs waiting for red light ahead, stop behind

      fd 1


end


to move-straight
  let cur-heading [heading] of self
  (ifelse
    cur-heading = 0 [move-up]
    cur-heading = 90 [move-right]
    cur-heading = 180 [move-down]
    cur-heading = 270 [move-left]
  )
end

to make-u-turn
  ; taxicab current spatial direction and location
  let heading-up? [heading] of self = 0
  let heading-right? [heading] of self = 90
  let heading-down? [heading] of self = 180
  let heading-left? [heading] of self = 270

  if heading-up? [
    set heading 270
    fd 1
    ;update-delivery-and-income
    set heading 180
  ]
  if heading-down? [
    set heading 90
    fd 1
    ;update-delivery-and-income
    set heading 0
  ]
  if heading-right? [
    set heading 0
    fd 1
    ;update-delivery-and-income
    set heading 270
  ]
  if heading-left? [
    set heading 180
    fd 1
    ;update-delivery-and-income
    set heading 90
  ]
end


;  No two turtles can have the same who number, even if they are different breeds:
; Copyright 2019 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
215
19
873
678
-1
-1
10.0
1
10
1
1
1
0
0
0
1
-32
32
-32
32
1
1
1
ticks
30.0

BUTTON
85
12
148
45
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

BUTTON
7
11
70
44
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

SLIDER
6
97
178
130
number-of-restaurants
number-of-restaurants
1
50
10.0
1
1
NIL
HORIZONTAL

SLIDER
5
139
178
172
number-of-customers
number-of-customers
0
1000
500.0
10
1
NIL
HORIZONTAL

SLIDER
5
184
177
217
number-of-deliverers
number-of-deliverers
1
80
20.0
1
1
NIL
HORIZONTAL

PLOT
889
21
1476
178
delivered per day
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
"default" 60.0 0 -16777216 true "" "plot total-delivered"

MONITOR
892
537
1036
582
time past (days h:mm)
time_formatted
2
1
11

PLOT
890
186
1477
334
ordered per day
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
"default" 1.0 0 -16777216 true "" "plot total_ordered"

CHOOSER
5
364
143
409
order_frequency
order_frequency
"once a day" "once a week"
1

SLIDER
5
229
177
262
prepair_time_mean
prepair_time_mean
5
30
15.0
1
1
NIL
HORIZONTAL

SLIDER
5
319
177
352
wait_for_deliverer
wait_for_deliverer
10
150
90.0
1
1
NIL
HORIZONTAL

SLIDER
5
274
177
307
prepair_time_stdev
prepair_time_stdev
0
10
5.0
1
1
NIL
HORIZONTAL

PLOT
890
340
1478
513
discarded per day
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
"default" 1.0 0 -16777216 true "" "plot total_discarded"

CHOOSER
5
419
162
464
distribution_method
distribution_method
"nearest_meal" "nearest_deliverer" "equally_distributed"
0

MONITOR
897
596
1001
641
NIL
count deliverers
17
1
11

MONITOR
1010
597
1118
642
NIL
count customers
17
1
11

MONITOR
1124
596
1237
641
NIL
count restaurants
17
1
11

MONITOR
1243
595
1325
640
NIL
count meals
17
1
11

MONITOR
1044
537
1130
582
NIL
weeknumber
17
1
11

MONITOR
1222
542
1453
587
NIL
average_number_deliveries_per_week
17
1
11

PLOT
891
406
1476
556
average_number_deliveries_per_week
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
"default" 1.0 0 -16777216 true "" "plot average_number_deliveries_per_week"

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

apple
false
0
Polygon -7500403 true true 33 58 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 226 43 194 36 148 32 105 35
Line -16777216 false 106 55 151 62
Line -16777216 false 157 62 209 57
Polygon -6459832 true false 152 62 158 62 160 46 156 30 147 18 132 26 142 35 148 46
Polygon -16777216 false false 132 25 144 38 147 48 151 62 158 63 159 47 155 30 147 18

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bike
false
1
Line -7500403 false 163 183 228 184
Circle -7500403 false false 213 184 22
Circle -7500403 false false 156 187 16
Circle -1 false false 28 148 95
Circle -1 false false 24 144 102
Circle -1 false false 174 144 102
Circle -1 false false 177 148 95
Polygon -2674135 true true 75 195 90 90 98 92 97 107 192 122 207 83 215 85 202 123 211 133 225 195 165 195 164 188 214 188 202 133 94 116 82 195
Polygon -2674135 true true 208 83 164 193 171 196 217 85
Polygon -2674135 true true 165 188 91 120 90 131 164 196
Line -7500403 false 159 173 170 219
Line -7500403 false 155 172 166 172
Line -7500403 false 166 219 177 219
Polygon -1 true false 187 92 198 92 208 97 217 100 231 93 231 84 216 82 201 83 184 85
Polygon -7500403 true false 71 86 98 93 101 85 74 81
Rectangle -16777216 true false 75 75 75 90
Polygon -1 true false 70 87 70 72 78 71 78 89
Circle -7500403 false false 153 184 22
Line -7500403 false 159 206 228 205

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

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

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
NetLogo 6.4.0
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
