;version #32- (started to combine 16 + 28) - now the client is runinig + the plots of the host+ the client is working but the simulation is very very slow! ( no full view host+not aligned, no files)
;+added the csv logic with  html + js + github

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variable and Breed declarations ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [
    ;; variables used to assign unique color and shape to clients
    shape-names        ;; list that holds the names of the non-sick shapes a student's turtle can have
    colors             ;; list that holds the colors used for students' turtles
    color-names        ;; list that holds the names of the colors used for students' turtles
    used-shape-colors  ;; list that holds the shape-color pairs that are already being used
    max-possible-codes ;; total number of possible unique shape/color combinations
    sample-car  Slowing-Point ;;to show slowest car
    RunTime
    ServerZoom-radius
    
    ;; ===== UI widgets (from Desktop/Authoring) =====
    __hnw_teacher_radius
    __hnw_teacher_extra-lane-length
    __hnw_teacher_number-of-cars
    __hnw_teacher_number-of-trucks
    __hnw_teacher_InitialSpeed
    __hnw_teacher_acceleration
    __hnw_teacher_deceleration
    __hnw_teacher_DistanceFromCar
    __hnw_teacher_speed-parameter
    __hnw_teacher_MaxSpeed
    __hnw_teacher_allowance
    __hnw_teacher_requiredlaps
    __hnw_teacher_change-lane-x-of-100
     
    ;; switches
    __hnw_teacher_androids-change-lane?    
    __hnw_teacher_allow-accident?
    __hnw_teacher_speed-limit?
    __hnw_teacher_ShowSlowestPoint?
  
    ;; --- CSV logging (two files) ---
    csv_init            ;; one-row "world init" CSV (header + one row)
    csv_run             ;; multi-row "per-student, per-second" CSV (header + many rows)
    csv_has_init?       ;; did we write the init header+row?
    csv_has_run_header? ;; did we write the run header?
  
    DEBUG? go-started? ui_hb       ;; ui_hb = once-per-second heartbeat counter
]


turtles-own [
  speed        ;; hold the turtle speed
  speed-limit  ;; hold the turtle max speed
  speed-min    ;; hold the turtle min speed
  base-shape   ;; hold the turtle shape
  lane         ;; 1=inside, 2=outside, 3=Overtakinglane
]


;; derive from turtle
breed [ androids android ]  ;; simulate car on the road
breed [ students student ]  ;; players car's
breed [ trucks truck ]      ;; simulate track on the road

patches-own [ orig-color acc-tick-conuter ]

students-own [
  acc             ;; hold the acceleration speed parameter
  zoom-radius     ;; hold the zoom option for player
  client-perspective
  user-id         ;; unique id, input by the client when they log in, to identify each student turtle
  InitialHeading  ;; save the heading parameter of student position at start
  PrevHeading     ;; save the previous heading
  LapCounter      ;; counter the lap's that student made
  IsFirstLap      ;; flag to know if this is the student first lap
  MessageRead
  firstSetup
  ;;;;;;;; i added these three lines for the HubNet system that he can brodcast the messeges
  name-label   ;; persistent display name (kept above the status)
  msg          ;; last status text ("Free"/"Occupied")
  msg-ttl      ;; ticks left to show the status (auto-clears)
  
;;;;;;;;;;;;;;;;;;;;;;;;;;; added\changed for HubNet:
  ui-overall-time
  ui-laps
  ui-message
  ui-speed
  ui-who
  
  laps-float   ;; total laps traveled as a float (e.g., 1.3 = 1 lap + 30%)
  ; per-client history for plots
  laps-history     ;; list of this student's recent laps-float values (for client histogram)
  speed-history   ;; list of this student's recent speeds (for client histogram)

]

;;;;;;;;;;;;;;;;;;;;;;
;; Setup Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;

;; occurred when startup NetLogo
to startup
  set __hnw_teacher_radius                  26
  set __hnw_teacher_extra-lane-length       22
  set __hnw_teacher_number-of-cars          65
  set __hnw_teacher_number-of-trucks        1
  set __hnw_teacher_InitialSpeed            100
  set __hnw_teacher_acceleration            1.0
  set __hnw_teacher_deceleration            1.0
  set __hnw_teacher_DistanceFromCar         4 
  set __hnw_teacher_speed-parameter         5
  set __hnw_teacher_MaxSpeed                100
  set __hnw_teacher_allowance               1
  set __hnw_teacher_requiredlaps            1
  set __hnw_teacher_change-lane-x-of-100    99
  set __hnw_teacher_androids-change-lane?   false
  set __hnw_teacher_allow-accident?         true
  set __hnw_teacher_speed-limit?            false
  set __hnw_teacher_ShowSlowestPoint?       false
  set-up-vars
  
  ;; --- CSV defaults ---
  set csv_init ""
  set csv_run ""
  set csv_has_init? false
  set csv_has_run_header? false

end


  ;;occurred when setup butten is pressed
to setup
  
  set DEBUG? true                  ;; turn logs on (flip to false when done)
  dbg "S0 enter setup"

 
  set ServerZoom-radius 20
  Set RunTime 0
  ask androids [ die ]
  ask trucks [ die ]
  
  ;dbg "S1-before-defaults"
  
  ;; ===== Defensive defaults for all UI widgets =====
  ;; numeric sliders
  if not is-number? __hnw_teacher_radius               [ set __hnw_teacher_radius 70 ]
  if not is-number? __hnw_teacher_extra-lane-length    [ set __hnw_teacher_extra-lane-length 22 ]
  if not is-number? __hnw_teacher_number-of-cars       [ set __hnw_teacher_number-of-cars 50 ]
  if not is-number? __hnw_teacher_number-of-trucks     [ set __hnw_teacher_number-of-trucks 1 ]
  if not is-number? __hnw_teacher_InitialSpeed         [ set __hnw_teacher_InitialSpeed 100 ]
  if not is-number? __hnw_teacher_acceleration         [ set __hnw_teacher_acceleration 1 ]
  if not is-number? __hnw_teacher_deceleration         [ set __hnw_teacher_deceleration 1 ]
  if not is-number? __hnw_teacher_DistanceFromCar      [ set __hnw_teacher_DistanceFromCar 4 ]
  if not is-number? __hnw_teacher_speed-parameter      [ set __hnw_teacher_speed-parameter 5 ]
  if not is-number? __hnw_teacher_MaxSpeed             [ set __hnw_teacher_MaxSpeed 100 ]
  if not is-number? __hnw_teacher_allowance            [ set __hnw_teacher_allowance 1 ]
  if not is-number? __hnw_teacher_requiredlaps         [ set __hnw_teacher_requiredlaps 1 ]
  if not is-number? __hnw_teacher_change-lane-x-of-100 [ set __hnw_teacher_change-lane-x-of-100 99 ]

  ;; switches (booleans)
  if not is-boolean? __hnw_teacher_androids-change-lane? [ set __hnw_teacher_androids-change-lane? false ]
  if not is-boolean? __hnw_teacher_allow-accident?       [ set __hnw_teacher_allow-accident? true ]
  if not is-boolean? __hnw_teacher_speed-limit?          [ set __hnw_teacher_speed-limit? false ]
  if not is-boolean? __hnw_teacher_ShowSlowestPoint?     [ set __hnw_teacher_ShowSlowestPoint? false ]
  ;; ===== end defaults =====
  

;   ;; keep full ring (incl. third-lane outer bound) inside this world with a small margin - BUT NOW THE TURTLE IS MOVING ACROS THE LANES ! NOT GOOD!
;   let halfMin min (list max-pxcor (- min-pxcor) max-pycor (- min-pycor))
;   let limit2  (halfMin - 2) * (halfMin - 2)   ;; 2-patch visual margin
;   let maxR    floor sqrt (limit2 - 600)       ;; was 750 → 600 to permit larger r
;   if __hnw_teacher_radius > maxR [
;     set __hnw_teacher_radius maxR
;   ]


  ;dbg "S2-before-color"
  ask patches [ set pcolor green ]
  
  ask patches with [pxcor = 0 and pycor = 0] [ set pcolor red ]

;   show (word "DEBUG setup: teacher-radius=" __hnw_teacher_radius
;            " extra-lane-length=" __hnw_teacher_extra-lane-length)
  
  ;dbg "S3-before-setup-road"
  ask patches [ setup-road __hnw_teacher_radius ]
  
  ;dbg "S4-before-setup-extra"
  ask patches [ setup-Extra-lanes __hnw_teacher_radius ]
  ask androids [ die ]
  
  ;dbg "S5-before-setup-cars"
  setup-cars __hnw_teacher_radius
  
  ;dbg "S6-before-setup-trucks"
  setup-trucks __hnw_teacher_radius
  ask students [ set LapCounter 0 ]
  ask students [ set IsFirstLap 1 ]
  ask students [ send-lap-time ]
  ask students [ send-lap-counter ]
  ask turtles [separate-cars]
  ask patches [set orig-color pcolor]
  clear-all-plots
  
  
  ;; --- write the one-row init CSV now ---
  csv-ensure-init
  
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;---Host----;;
;   teacher-setup-speed-histogram
;   teacher-update-speed-histogram
  
;   teacher-setup-distance-histogram
;   teacher-update-distance-histogram
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;dbg "S7-before-student-vars"
  ask students [ setup-student-vars user-id ]
  
  
  ;dbg "S8-before-reset-ticks"
  reset-ticks
  
  ;show "S9-exit (print)"
  dbg "S9-exit"
end




  ;; initialize global variables
to set-up-vars
  set shape-names [  "turtle" "butterfly" "airplane" "bug" "default" "arrow" "bug" ]
  set colors      (list brown green yellow  (violet + 1) (sky + 1))
  set color-names ["brown" "green" "yellow" "purple" "blue"]
  set max-possible-codes (length colors * length shape-names)
  set used-shape-colors []
end

   ;;to seprate car's when we do setup
to separate-cars    ;; turtle procedure
  if any? other turtles in-cone 2 360
    [ moveMeFWD
      separate-cars ]
end


;; ===== create road (clamped to world) =====
to setup-road [ r ]  ;; patch procedure
  let d2 (pxcor * pxcor + pycor * pycor)
  let worldR min (list max-pxcor (- min-pxcor) max-pycor (- min-pycor))
  let limit2 (worldR - 1) * (worldR - 1)   ;; leave a 1-patch safety margin
  let rsq r * r

  ;; black band: r^2 ± {100, 400}
  let in2   max list (rsq - 100) 1 
  let out2  min list (rsq + 400) limit2
  if (d2 >= in2) and (d2 <= out2) [ set pcolor black ]

  ;; outer white band: r*(r+5) .. r*(r+5) + 20  (keep your original formula, clamped)
  let inW2  max list (r * (r + 5)) 1
  let outW2 min list (r * (r + 5) + 20) limit2
  if (d2 >= inW2) and (d2 <= outW2) [ set pcolor white ]
  
  ;if (d2 >= inW2) and (d2 <= outW2) and (abs pycor <= __hnw_teacher_extra-lane-length) [
  ;  set pcolor white
  ;]
  
  ;; one-time print from a single corner patch so we don't spam
;   if (pxcor = min-pxcor) and (pycor = min-pycor) [
;     show (word "DEBUG setup-road: worldR=" worldR
;                " limit2=" limit2 " rsq=" rsq
;                " in2=" (max list (rsq - 100) 1)
;                " out2=" (min list (rsq + 400) limit2))
;   ]
end


;; ===== create extra / third lane (clamped to world) =====
to setup-Extra-lanes [ r ]  ;; patch procedure
  let d2 (pxcor * pxcor + pycor * pycor)
  let worldR min (list max-pxcor (- min-pxcor) max-pycor (- min-pycor))
  let limit2 (worldR - 1) * (worldR - 1)
  let rsq r * r

  ;; black widening: r^2 + [400 .. 750], but only within ± extra-lane-length vertically
  let in2   max list (rsq + 400) 1
  ;let out2  min list (rsq + 750) limit2
  let out2  min list (rsq + 600) limit2 ;-TODO - TO DELETE

  if (d2 >= in2) and (d2 <= out2) and (abs pycor <= __hnw_teacher_extra-lane-length) [
    set pcolor black
  ]

  ;; white on the widened band: r^2 + [400 .. 420]
  let inW2  max list (rsq + 400) 1
  ;let outW2 min list (rsq + 420) limit2
  let outW2 min list (rsq + 410) limit2
  ;if (d2 >= inW2) and (d2 <= outW2) [ set pcolor white ]
  if (d2 >= inW2) and (d2 <= outW2) and (abs pycor <= __hnw_teacher_extra-lane-length) [
    set pcolor white
  ]

  
;   if (pxcor = min-pxcor) and (pycor = min-pycor) [
;     show (word "DEBUG extra-lanes: worldR=" worldR
;              " limit2=" limit2 " rsq=" rsq
;              " extra-lane-length=" __hnw_teacher_extra-lane-length
;              " widen-in=" (max list (rsq + 400) 1)
;              " widen-out=" (min list (rsq + 750) limit2))
;   ]
end





  ;;create androids/truck and locate them on both lane
to setup-cars [r]
  ;dbg (word "ENTER setup-cars r=" r)
  
    ; first lane
  create-androids  (__hnw_teacher_number-of-cars + 1) / 2 - (__hnw_teacher_number-of-cars + 1) * 0.05 [
    ifelse (1 = 2);(( random 100 ) > 90 ) ; 10% are trucks - eo - cancelled
    [  ; set Trucks
      set breed trucks
      set speed-limit __hnw_teacher_MaxSpeed ;- 0.4 * __hnw_teacher_MaxSpeed
      set shape "Truck"

    ]
    [ ; set androids
      set speed-limit __hnw_teacher_MaxSpeed
      set shape "car top"
    ]
    set size 2  ; easier to see
    fd r
    rt 90
    set lane 1
    set speed 1 + random __hnw_teacher_InitialSpeed
    set speed-min 0
    set color white
    ask other androids-here
  [ die ]

  ]
    ; second lane
 create-androids  (__hnw_teacher_number-of-cars + 1) / 2 + (__hnw_teacher_number-of-cars + 1) * 0.05 [
    ifelse (1 = 2);(( random 100 ) > 90 ) ; 10% are trucks
    [  ; set Trucks
      set breed trucks
      set speed-limit __hnw_teacher_MaxSpeed; - 0.3 * __hnw_teacher_MaxSpeed
      set shape "Truck"

    ]
    [   ; set androids
      set speed-limit __hnw_teacher_MaxSpeed
      set shape "car top"
    ]
    set size 2  ;; easier to see
    fd r + 5
    rt 90
    set speed 1 + random __hnw_teacher_InitialSpeed
    set lane 2
    set speed-min 0
    set color white
    ask other androids-here
  [ die ]
   ask other trucks-here
  [ die ]
  ]
  ;dbg "EXIT setup-cars"

end


to setup-trucks [r]
  ;dbg (word "ENTER setup-trucks r=" r)
  
    ; first lane
  create-androids  (__hnw_teacher_number-of-trucks + 1) / 2 - (__hnw_teacher_number-of-trucks + 1) * 0.05 [
    ifelse (1 = 1);(( random 100 ) > 90 ) ; 10% are trucks - eo - cancelled
    [  ; set Trucks
      set breed trucks
      set speed-limit __hnw_teacher_MaxSpeed ;- 0.4 * __hnw_teacher_MaxSpeed
      set shape "Truck"

    ]
    [ ; set androids
      set speed-limit __hnw_teacher_MaxSpeed
      set shape "car top"
    ]
    set size 2  ; easier to see
    fd r
    rt 90
    set lane 1
    set speed 1 + random __hnw_teacher_InitialSpeed
    set speed-min 0
    set color white
    ask other androids-here
  [ die ]

  ]
    ; second lane
 create-androids  (__hnw_teacher_number-of-trucks + 1) / 2 + (__hnw_teacher_number-of-trucks + 1) * 0.05 [
    ifelse (1 = 1);(( random 100 ) > 90 ) ; 10% are trucks
    [  ; set Trucks
      set breed trucks
      set speed-limit __hnw_teacher_MaxSpeed; - 0.3 * __hnw_teacher_MaxSpeed
      set shape "Truck"

    ]
    [   ; set androids
      set speed-limit __hnw_teacher_MaxSpeed
      set shape "car top"
    ]
    set size 2  ;; easier to see
    fd r + 5
    rt 90
    set speed 1 + random __hnw_teacher_InitialSpeed
    set lane 2
    set speed-min 0
    set color white
    ask other androids-here
  [ die ]
   ask other trucks-here
  [ die ]
  ]
  ;dbg "EXIT setup-trucks"

end


;;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;dbg "G0-enter"
  every 0.1
    [
      
      ;show "[DBG] GO: entered every-block (observer)"   ;; <— OBSERVER print
             
      ;listen-clients        ;; get commands and data from the clients
      if __hnw_teacher_androids-change-lane? [ ask androids [ zigzag ]] ;;if button is up allow change lane 
      circle __hnw_teacher_radius         ;;move the car on the road
      plot-cars             ;;display the plot on the screen
      
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; update each student's cumulative laps - helper for the distance histogram of the host plot
      ask students [
        
        ;show (word "[DBG] GO: inside ask students, who=" who)
        set laps-float calc-laps-float
        ;; keep a short rolling history so histograms show something
        let HIST_LEN 120  ;; ~12 seconds if every 0.1; tweak as you like

        ;; append current samples
        set speed-history lput speed       speed-history
        set laps-history  lput laps-float  laps-history
        
        if length speed-history > HIST_LEN [ set speed-history butfirst speed-history ]
        if length laps-history  > HIST_LEN [ set laps-history  butfirst laps-history  ]
        
      ]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      
      ;;;;;;;;;;;;;;;;;;;;;;;;;;
;       teacher-update-speed-histogram
;       teacher-update-distance-histogram
      ;;;;;;;;;;;;;;;;;;;;;;;;;;

      if __hnw_teacher_ShowSlowestPoint?
      [ Draw-Slowest ]

      ;; --- status TTL maintenance (message below name) ---
      ;; decay first, so labels that just expired can be redrawn below
      decay-msg

      ask students [
       if (not is-string? name-label) or (name-label = "") [
         set name-label (word "ID " user-id)
       ]

       ;; only draw the baseline label when there is no active message
       if msg-ttl = 0 [
         ;; baseline: show name + current speed on one line
         set label (word name-label " -> " floor speed)
         set label-color red
       ]
       ;; when msg-ttl > 0, student-msg already set:
       ;;   label = (word name-label "\n" <status>), so we leave it untouched
      ]
     ask students [ refresh-student-ui ]
     tick
   ]
     ; calculate time in sec
    every 1
    [
      Set RunTime RunTime + 1
      ask students [ refresh-student-ui ]
      
      
      ;;;;;;;;;;; CSV (per-second) ;;;;;;;;;;;
      csv-ensure-run-header
      if any? students [
        ;; gather all rows first, then append (faster)
        let rows [ csv-row-for-student ] of students
        set csv_run (word csv_run (reduce word rows))
      ]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      
      ask patches [ifelse acc-tick-conuter > 0 [set acc-tick-conuter acc-tick-conuter - 1][set pcolor orig-color] ]
    ]
end



  ;;change lane of androids
to zigzag
  if (( random 100 ) < __hnw_teacher_change-lane-x-of-100 ) and (speed < __hnw_teacher_MaxSpeed) and (count other turtles in-cone __hnw_teacher_DistanceFromCar 30 > 0)
  [
   if (lane = 1 )
   [
     execute-move 270
     stop
   ]

   if (lane = 2)
   [
     execute-move 90
     stop
   ]
    ]
end


to circle [r]
     ask turtles [ move-along-circle r ]
end

   ;;draw the slowest turtle on road in red
to Draw-Slowest
    ; set Slowing-Point one-of turtles with [speed = min [speed] of turtles]
  let min-speed min [speed] of turtles
  set min-speed min-speed + __hnw_teacher_allowance
  ask turtles [
   ifelse speed < min-speed
   [set color red  ]
   [set color blue  ]
  ]
end

   ;;move androids forwards on thier lane if they are on the same patch with other
to MoveMeFWD
   if lane = 1
  [
    fd (pi * __hnw_teacher_radius / 180) * (speed / 50)
    rt speed / 50
  ]
   if lane = 2
  [
    fd (pi * ( __hnw_teacher_radius + 5) / 180) * (speed / 50)
    rt speed / 50
  ]
     if lane = 3
  [
    fd (pi * ( __hnw_teacher_radius + 10) / 180) * (speed / 50)
    rt speed / 50
  ]
   if any? other turtles-here
   [ MoveMeFWD ]
end


 ;;the main method who move's the car forwords
to move-along-circle [r] ; turtles function
  if (breed =  students)
     [ set PrevHeading heading ]  ; For Lap Counter
  let ps patches in-cone __hnw_teacher_DistanceFromCar 60
  let ps1 patches in-cone 2 360
   ; if want to show the cone that car lock ahead take out the comment below
   ;  ask ps [ set pcolor 5]
  let car-ahead one-of other turtles-on ps
  let car-ahead1 one-of other turtles-on ps1
   ; if car is on the end of Extra lane than stop car
  if (lane = 3) and ((ycor > __hnw_teacher_extra-lane-length  ) or (ycor < 0 - __hnw_teacher_extra-lane-length ))
  [
    set speed 0
    stop
  ]


 
  if-else __hnw_teacher_allow-accident? and (breed =  students)
           ; if button allow accident is turn-on and you are student
  [ifelse car-ahead != nobody
    [
      if speed > [speed] of car-ahead
      [ accident-fireworks
        set speed [speed] of car-ahead ]
        slow-down-car

    ]
    [
       ifelse car-ahead1 != nobody
       [
         if speed > [speed] of car-ahead1
         [ set speed [speed] of car-ahead1 ]
         slow-down-car
       ]
        ; otherwise, speed up
       [ speed-up-car ]
    ]

 ]
        ; if button allow accident is turn-off
  [
    ifelse car-ahead != nobody and( [speed] of car-ahead   < speed  + 10 )
    [
      if speed > [speed] of car-ahead
      [ set speed [speed] of car-ahead ]

      slow-down-car
    ]
     ; otherwise, speed up
    [ speed-up-car ]
  ]

  set car-ahead nobody
     ; don't slow down below speed minimum or speed up beyond speed limit
  if speed < speed-min  [ set speed speed-min ]
  if speed > speed-limit and __hnw_teacher_speed-limit?  [ set speed speed-limit ]
     ; perform car move on road
  if lane = 1
  [
    fd (pi * __hnw_teacher_radius / 180) * (speed / 50)
    rt speed / 50
  ]
  if lane = 2
  [
    fd (pi * ( __hnw_teacher_radius + 5) / 180) * (speed / 50)
    rt speed / 50
  ]
  if lane = 3
  [
    fd (pi * ( __hnw_teacher_radius + 10) / 180) * (speed / 50)
    rt speed / 50
  ]
  calc_lap_counter
end

   ;; calculate Lap Counter for student only
to calc_lap_counter

  if (breed =  students)
   [
      if ((PrevHeading <= InitialHeading) and (heading > InitialHeading)) or ((PrevHeading < InitialHeading) and (heading >= InitialHeading))
      [
        ifelse (IsFirstLap = 0)
        [
          set LapCounter LapCounter + 1
          send-Lap-counter 
          if (__hnw_teacher_requiredlaps = LapCounter) and (__hnw_teacher_requiredlaps > 0)
          [
             send-lap-time
          ]
        ]
        [
          set LapCounter 0
          set IsFirstLap 0
          send-Lap-counter
        ]
      ]
   ]

end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;helper the procedure that will polt the distance histogram of the host
;; Report the total laps (LapCounter + fractional progress) for one student
to-report calc-laps-float  ;; turtle reporter, student context
  let diff heading - InitialHeading
  if diff < 0 [ set diff diff + 360 ]
  report LapCounter + (diff / 360)
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




to slow-down-car  ;; turtle procedure
   set speed speed - __hnw_teacher_deceleration
   ;accident-fireworks
end



to accident-fireworks
  ask patches in-radius 2
      [ set pcolor red + random-float 3
        set acc-tick-conuter 1] ;;;actually seconds not ticks:)

end


to speed-up-car  ;; turtle procedure
  ifelse breed = students
  [ set speed speed + acc
    set acc 0
  ]
  [ set speed speed + __hnw_teacher_acceleration ]
end

   ;; turtle procedure chnge car lane, get the direction to go-to
to change-lane [ side ]
  if (lane = 1 ) and (side = "left")
  [
    set lane  2
    setxy 0 0
    fd __hnw_teacher_radius + 5
    stop
  ]
  if (lane = 2) and (side = "right")
  [
    set lane  1
    setxy 0 0
    back __hnw_teacher_radius
    stop
  ]
   if (lane = 2) and (side = "left")
  [
    set lane  3
    setxy 0 0
    fd __hnw_teacher_radius + 10
    stop
  ]
   if (lane = 3) and (side = "right")
  [
    set lane  2
    setxy 0 0
    back __hnw_teacher_radius + 5
    stop
  ]
end

; this version reports just students - wich i think that just this information is relevant... TODO
 ;;display the plot on the screen
to plot-cars
  if (count turtles != 0)
  [
    set-current-plot "AverageSpeed"
    set-current-plot-pen "MinSpeed"
    plot min [speed] of turtles
    set-current-plot-pen "MaxSpeed"
    plot max [speed] of turtles
  ]
end


;TODO
; this version reports just students - wich i think that just this information is relevant... TODO
; to plot-cars  
;   if any? students [
;     set-current-plot "Average Speed"
;     set-current-plot-pen "MinSpeed"
;     plot min [speed] of students
;     set-current-plot-pen "MaxSpeed"
;     plot max [speed] of students
;   ]
; end





   ;; turtle function ,get direction to change car lane and
   ;; call change-lane function if possible , else
   ;; return to (student only) occupied
to execute-move [direction]
   ; check aveliable space in that direction
  ifelse direction = 90
  [
    ;; right
    rt direction
    let ps patches in-cone 8 60
    let car-ahead one-of other turtles-on ps
    ifelse (car-ahead = nobody) and ((lane = 2) or (lane = 3))
    [
      if (breed = students) [ student-msg "Free" ]
      change-lane "right"
    ]

    [
      if (breed = students) [ student-msg "Occupied"]
    ]
    lt direction
  ]

  ;;left
  [  rt direction
     let ps patches in-cone 8 60
     let car-ahead one-of other turtles-on ps
     ifelse (car-ahead = nobody) and ((lane = 1) or (lane = 2))
     [
      if (breed = students) [ student-msg "Free" ]
      ifelse (( lane = 2 ) and (ycor < __hnw_teacher_extra-lane-length - 3) and (ycor > 3 - __hnw_teacher_extra-lane-length)) or (lane != 2)
      [
      change-lane  "left"
      ]
      [ if (breed = students) [ student-msg "Occupied" ] ]
    ]
    [ if (breed = students) [ student-msg "Occupied" ] ]
    lt direction
  ]
end
;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;
;; HubNet Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;


;; Called automatically when a student joins (Student role)
;; OBSERVER context — must REPORT the student's turtle who number.
to-report on-connect [alias]
  let s one-of students with [ user-id = alias ]
  
  show (word "DEBUG on-connect: alias=" alias
           " existing? " (s != nobody))

  ifelse s = nobody [
    ;; first time: create a student for this alias
    let new-who create-new-student alias
    set s one-of students with [ who = new-who ]
    ;create-new-student alias ; from the old version of "to create-new-student" 
    ;set s one-of students with [ user-id = alias ]
  ] [
    ;; reconnect: optionally refresh
    ask s [ setup-student-vars alias ]
  ]

  show (word "DEBUG on-connect: alias=" alias
           " -> who=" [who] of s)

  report [who] of s
end



;; HubNet Web version: remove a student by their participant id
to remove-student [uid]
  ask students with [user-id = uid] [
    set used-shape-colors remove my-code used-shape-colors
    die
  ]
end


to-report my-code
  report (position base-shape shape-names) + (length shape-names) * (position color colors)
end



;;;; ask chatgot abiut this-
to-report create-new-student [uid]
  let new-student-who nobody
  create-students 1 [
    setup-student-vars uid
    ;student-setup-speed-histogram
    ;student-setup-distance-histogram
    set client-perspective (list "follow" self zoom-radius) 
    set new-student-who who
    send-info-to-clients
  ]
  report new-student-who
end




to setup-student-vars [uid]
  ;dbg (word "ENTER setup-student-vars uid=" uid)
  setxy 0 0
  if firstSetup < 1 [
    set user-id uid
  ]
  set firstSetup 1
  ;;;;;;;;;;;;;;;;;;;;;;;
  set name-label (word uid)  ;; use the alias the student typed
  show (word "DEBUG setup-student-vars: uid=" uid
           " who=" who
           " name-label=" name-label)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set-unique-shape-and-color
  set zoom-radius 20
  set size 2    ;; easier to see
  fd __hnw_teacher_radius
  rt 90
  set lane 1
  set speed 1 + random __hnw_teacher_InitialSpeed
  set speed-min 0
  set speed-limit __hnw_teacher_MaxSpeed
  set acc 0
  set InitialHeading heading
  
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;; added\changed for HubNet- Helpers to the HubNet version :
  set ui-speed        floor speed
  set ui-laps         LapCounter
  set ui-overall-time RunTime
  set ui-message      "Free"
  ;set msg-ttl         0          ;; optional: make explicit that no transient msg is active
  
  set speed-history []
  set laps-history  []

  ;; HubNet Web note: client view control (follow/watch) not supported
  ;; in the same way — remove hubnet-send-follow completely

  ask other androids-here [
    MoveMeFWD ;; avoid student car on android
  ]
  ;dbg "EXIT setup-student-vars"
end



   ;; student function
   ;;give every student unique shape and color
to set-unique-shape-and-color
  let code random max-possible-codes
  while [member? code used-shape-colors and count students < max-possible-codes]
  [
    set code random max-possible-codes
  ]
  set used-shape-colors (lput code used-shape-colors)
  set base-shape item (code mod length shape-names) shape-names
  set shape base-shape
  set color item (code / length shape-names) colors
  ;set color item (floor (code / length shape-names)) colors

end



   ;; student function
   ;; determines  what the command is and performed it
to execute-command [command]
  if command = "speed up"
  [ show (word "speed-up from uid=" user-id " who=" who)
    set acc __hnw_teacher_speed-parameter
    send-info-to-clients
    stop
  ]
  if command = "speed down"
  [ 
    show (word "speed-down from uid=" user-id " who=" who)
    set acc 0 - __hnw_teacher_speed-parameter
    send-info-to-clients
    stop
  ]
  if command = "right"
    [
      show (word "right from uid=" user-id " who=" who)
      execute-move 90 stop
    ]
  if command = "left"
    [
      show (word "left from uid=" user-id " who=" who)
      execute-move 270 stop
    ]
end



to ZoomIn
  set ServerZoom-radius max list 1 (ServerZoom-radius - 1)
  ask students [
    set zoom-radius ServerZoom-radius
    set client-perspective (list "follow" self zoom-radius)
  ]
end

to ZoomOut
  set ServerZoom-radius min list 30 (ServerZoom-radius + 1)
  ask students [
    set zoom-radius ServerZoom-radius
    set client-perspective (list "follow" self zoom-radius) 
  ]
end



   ;;send lap counter to client →  show a short per-turtle status
to send-lap-counter
  if breed = students [
    student-msg (word "Laps " LapCounter)   ;; shows under the name for ~8 cycles
  ]
end

   ;;send lap time to client →  short per-turtle status
to send-lap-time
  if breed = students [
    student-msg (word "OverallTIme " RunTime)     ;; shows under the name for ~8 cycles
  ]
end


   ;; sends the appropriate monitor information back to the client
to send-info-to-clients
  set speed floor speed
  ;refresh-student-ui    ;; optional: instant monitor refresh on any call


  if breed = students [
     if (not is-string? name-label) or (name-label = "") [
       set name-label (word "ID " user-id)
     ]
    ;; only update the baseline when no active status is being shown
    if msg-ttl = 0 [
      ;; top line: name + speed + lap
      set label (word name-label " -> " floor speed)
      ;set label (word name-label " speed " precision speed 1 "   Laps " LapCounter)

      set label-color red
    ]

  ]
end



   ;; report the string version of the turtle's color
to-report color-string [color-value]
  report item (position color-value colors) color-names
end


;;;;;;;;;;;;;;;;;;;;;;;;;;; added\changed for HubNet- Helpers to the HubNet version :

;; Show a short status under the student's name for 8 ticks
to student-msg [txt]
  if breed = students [
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     if (not is-string? name-label) or (name-label = "") [
       set name-label (word "ID " user-id)
     ]

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    set msg txt
    set ui-message txt   ;; <— add this
    ;; if i want the messege of "occupied" or "free" to last for ~8 seconds, change this 8 to 80
    set msg-ttl 8
    ;set label (word name-label "\n" txt)  ;; name on top, status on next line- TODO - TO DELETE if i dont want the “Free/Occupied” to be on‑turtle
    ;set label-color white -TODO - TO DELETE "When no temporary message is showing, your baseline label code sets the label to red (both in go and in send-info-to-clients)."
    set label-color red   ;; keep overlay but always red
  ]
end

;; Called once per tick to fade the status and restore the plain name
to decay-msg
  ask students with [msg-ttl > 0] [
    set msg-ttl msg-ttl - 1
    if msg-ttl = 0 [
      set label name-label
      ;set ui-message "Free"   ;; <— add this
    ]
  ]
end



;; === Student role: button handlers (HubNet Web) ===
to cmd-speed-up
  ;; runs in *this* student's turtle context
  execute-command "speed up"
end

to cmd-speed-down
  execute-command "speed down"
end

to cmd-left
  execute-command "left"
end

to cmd-right
  execute-command "right"
end



to refresh-student-ui  ;; turtle proc
  if breed = students [
    set ui-speed        floor speed
    set ui-laps         LapCounter
    set ui-overall-time RunTime
    ;set ui-message      (ifelse-value (msg-ttl > 0) [ msg ] [ "Free" ])
    set ui-message      msg
    set ui-who          who

  ]
end


to dbg [text]                  ;; was: to dbg [msg]
  if DEBUG? [ show (word "[DBG] " text) ]
end

to dbg-val [tag v]             ;; we already fixed this from 'label'
  if DEBUG? [ show (word "[DBG] " tag " = " v) ]
end


to noop end

to teacher-set-number-of-cars [n]        set __hnw_teacher_number-of-cars n end
to teacher-set-number-of-trucks [n]      set __hnw_teacher_number-of-trucks n end
to teacher-set-radius [n]                set __hnw_teacher_radius n end
to teacher-set-initial-speed [n]         set __hnw_teacher_InitialSpeed n end
to teacher-set-acceleration [x]          set __hnw_teacher_acceleration x end
to teacher-set-deceleration [x]          set __hnw_teacher_deceleration x end
to teacher-set-distance-from-car [n]     set __hnw_teacher_DistanceFromCar n end
to teacher-toggle-androids-change-lane [v] set __hnw_teacher_androids-change-lane? v end
to teacher-toggle-allow-accident [v]     set __hnw_teacher_allow-accident? v end
to teacher-toggle-speed-limit [v]        set __hnw_teacher_speed-limit? v end
to teacher-set-speed-parameter [n]       set __hnw_teacher_speed-parameter n end
to teacher-set-extra-lane-length [n]     set __hnw_teacher_extra-lane-length n end
to teacher-set-max-speed [n]             set __hnw_teacher_MaxSpeed n end
to teacher-set-allowance [n]             set __hnw_teacher_allowance n end
to teacher-toggle-show-slowest-point [v] set __hnw_teacher_ShowSlowestPoint? v end
to teacher-set-required-laps [n]         set __hnw_teacher_RequiredLaps n end
to teacher-set-change-lane-prob [n]      set __hnw_teacher_change-lane-x-of-100 n end




;;;;;;;;;;;;;;;;;;;;;;;;;;; added\changed for HubNet- Helpers to the HubNet version :

to-report average-speed
  report ifelse-value any? androids [ mean [speed] of androids ] [ 0 ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;; HOSTTTT PROCS OF THE PLOTS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ——— HOST Speed Histogram: setup and update ———

to teacher-setup-speed-histogram
  ;set-current-plot "Speed Histogram"
  clear-plot
  let xmax ifelse-value is-number? __hnw_teacher_MaxSpeed [ __hnw_teacher_MaxSpeed ] [ 100 ]
  set-plot-x-range 0 xmax
  let bars max list 10 (floor (xmax / 5))
  set-histogram-num-bars bars
end

to teacher-update-speed-histogram
  ;set-current-plot "Speed Histogram"
  ;; one dataset: all student speeds
  let speeds [ speed ] of students
  set-current-plot-pen "dist"
  histogram speeds
  ;; vertical line at mean speed (students only)
  let avg ifelse-value any? students [ mean speeds ] [ 0 ]
  set-current-plot-pen "avg-speed"
  plot-pen-reset
  plotxy avg 0
  plotxy avg (count students)
end



;; ——— HOST Distance Histogram: setup and update ———

to teacher-setup-distance-histogram
  ;set-current-plot "Distance Histogram"
  clear-plot
  ;; x-range up to max laps so far, fallback to 1 if no students yet
  let xmax ifelse-value any? students [ ceiling max [laps-float] of students ] [ 1 ]
  set-plot-x-range 0 xmax
  set-histogram-num-bars 10   ;; adjust bins if you want finer granularity
end

to teacher-update-distance-histogram
  ;set-current-plot "Distance Histogram"
  let laps [ laps-float ] of students

  set-current-plot-pen "dist"
  histogram laps

  ;; vertical line at mean laps
  let avg ifelse-value any? students [ mean laps ] [ 0 ]
  set-current-plot-pen "avg-laps"
  plot-pen-reset
  plotxy avg 0
  plotxy avg (count students)
end






;;;;;;;;;;;;;;;;;;;;;;;;;;; CLIENTTTT PROCS OF THE PLOTS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  SPEED  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; ; ======== CLIENT PLOTS (run in the student's turtle context) ========

to student-setup-my-speed-hist
  ;set-current-plot "My Speed Histogram"
  show (word "[DBG] student setup speed plot who=" who)
  clear-plot
  let xmax (ifelse-value is-number? __hnw_teacher_MaxSpeed [__hnw_teacher_MaxSpeed] [100])
  set-plot-x-range 0 xmax
  set-histogram-num-bars 15
end

to student-update-my-speed-hist
  ;set-current-plot "My Speed Histogram"
  show (word "[DBG] student update speed plot who=" who)
  ; keep X large enough for the current data
  let xmax1 (ifelse-value (length speed-history > 0) [max speed-history] [1])
  let xmax2 (ifelse-value is-number? __hnw_teacher_MaxSpeed [__hnw_teacher_MaxSpeed] [100])
  set-plot-x-range 0 max list xmax1 xmax2
  set-current-plot-pen "dist"
  histogram speed-history
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  DISTANCE   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to student-setup-my-distance-hist
  show (word "[DBG] student setup distance plot who=" who)
  ;set-current-plot "My Distance Histogram"
  clear-plot
  ; laps can exceed 1 — allow autoscale from 0 to at least 1
  set-plot-x-range 0  max list 1 (ifelse-value (length laps-history > 0) [max laps-history] [1])
  set-histogram-num-bars 15
end

to student-update-my-distance-hist
  show (word "[DBG] student update distance plot who=" who)
  ;set-current-plot "My Distance Histogram"
  let xmax (ifelse-value (length laps-history > 0) [max laps-history] [1])
  set-plot-x-range 0 max list 1 xmax
  set-current-plot-pen "dist"
  histogram laps-history
end



to-report speed-hist-count
  report length speed-history
end

to-report laps-hist-count
  report length laps-history
end






;; ========== CSV: headers & row builders ==========

to csv-write-init-header
  show (word "[DBG] ENTER TO csv-write-init-header proc")
  ;; matches "logger.csv_world_init_data.csv" header (snapshot of globals)
  set csv_init (word
    "runtime,requiredlaps,radius,number-of-trucks,number-of-cars,maxspeed,max-possible-codes,log-filename,initialspeed,extra-lane-length,distancefromcar,deceleration,colors\n")
end

to csv-write-run-header
  show (word "[DBG] ENTER TO csv-write-run-header proc")
  ;; matches "logger.csv" header (per-student, per-second)
  set csv_run (word
    "RunTime,who,user-id,color,heading,xcor,ycor,shape,speed,speed-limit,speed-min,base-shape,lane,acc,zoom-radius,initialheading,prevheading,lapcounter,isfirstlap,messageread,firstsetup\n")
end



to csv-ensure-init
  ;show (word "[DBG] ENTER TO csv-ensure-init proc")
  if csv_has_init? [ stop ]
  csv-write-init-header
  let init-row (word
    RunTime "," __hnw_teacher_requiredlaps "," __hnw_teacher_radius ","
    __hnw_teacher_number-of-trucks "," __hnw_teacher_number-of-cars ","
    __hnw_teacher_MaxSpeed "," max-possible-codes ","
    "logger" "," __hnw_teacher_InitialSpeed "," __hnw_teacher_extra-lane-length ","
    __hnw_teacher_DistanceFromCar "," __hnw_teacher_deceleration ","
    "\"" (word colors) "\"\n")
  set csv_init (word csv_init init-row)
  set csv_has_init? true
end



to csv-ensure-run-header
  if not csv_has_run_header? [
    ;show (word "[DBG] ENTER TO csv-ensure-run-header proc")
    csv-write-run-header
    set csv_has_run_header? true
  ]
end



to-report csv-row-for-student  ;; turtle reporter
  ;show (word "[DBG] ENTER TO csv-row-for-student proc")
  let runtime_val RunTime
  let who_id      who
  let uid_txt     user-id
  let col         color
  let hdg         heading

  ;; build the CSV row step by step to avoid WORD/list ambiguity
  let row ""
  set row (word row runtime_val ","
                who_id ","
                uid_txt ","
                col ","
                hdg ","
                xcor ","
                ycor ","
                shape ","
                speed ","
                speed-limit ","
                speed-min ","
                base-shape ","
                lane ","
                acc ","
                zoom-radius ","
                InitialHeading ","
                PrevHeading ","
                LapCounter ","
                IsFirstLap ","
                MessageRead ","
                firstSetup "\n")
  report row
end



;;"I dropped the aliases to keep things simple while fixing the word issue." : 

; to-report csv-row-for-student  ;; turtle reporter
;   let runtime_val RunTime
;   let row ""
;   set row (word row runtime_val ","
;                 who ","
;                 user-id ","
;                 color ","
;                 heading ","
;                 xcor ","
;                 ycor ","
;                 shape ","
;                 speed ","
;                 speed-limit ","
;                 speed-min ","
;                 base-shape ","
;                 lane ","
;                 acc ","
;                 zoom-radius ","
;                 InitialHeading ","
;                 PrevHeading ","
;                 LapCounter ","
;                 IsFirstLap ","
;                 MessageRead ","
;                 firstSetup "\n")
;   report row
; end





to-report csv-init-text
  report csv_init
end

to-report csv-run-text
  report csv_run
end

to clear-csv-run
  set csv_run ""
end



; *** NetLogo 4.1RC6 Model Copyright Notice ***
;
; This activity and associated models and materials were created as part of the projects:
; PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN
; CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT.
; The project gratefully acknowledges the support of the
; National Science Foundation (REPP & ROLE programs) --
; grant numbers REC #9814682 and REC-0126227.
;
; Copyright 1999 by Uri Wilensky & Walter Stroup.  All rights reserved.
;
; Permission to use, modify or redistribute this model is hereby granted,
; provided that both of the following requirements are followed:
; a) this copyright notice is included.
; b) this model will not be redistributed for profit without permission
;    from the copyright holders.
; Contact the copyright holders for appropriate licenses for redistribution for
; profit.
;
; If you mention this model in an academic publication, we ask that you
; include citations for the model itself and for the NetLogo software.
;
; To cite the model, please use:
; Wilensky, U. and Stroup, W. (1999).  NetLogo HubNet Disease model.
; http://ccl.northwestern.edu/netlogo/models/HubNetDisease.
; Center for Connected Learning and Computer-Based Modeling,
; Northwestern University, Evanston, IL.
;
; To cite NetLogo, please use:
; Wilensky, U. (1999). NetLogo. Center for Connected Learning and
; Computer-Based Modeling, Northwestern University, Evanston, IL.
; http://ccl.northwestern.edu/netlogo.
;
; In other publications, please use:
; Copyright 1999 Uri Wilensky and Walter Stroup.  All rights reserved.
; See http://ccl.northwestern.edu/netlogo/models/HubNetDisease
; for terms of use.
;
; *** End of NetLogo 4.1RC6 Model Copyright Notice ***
@#$#@#$#@
GRAPHICS-WINDOW
194
12
908
472
-1
-1
6.3604
1
10
1
1
1
0
0
0
1
-55
55
-35
35
1
1
1
ticks
30.0

BUTTON
10
12
93
64
Setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
97
12
181
64
Go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
7
65
179
98
number-of-cars
number-of-cars
1
200
65.0
1
1
NIL
HORIZONTAL

SLIDER
8
143
180
176
radius
radius
11
30
26.0
1
1
NIL
HORIZONTAL

SLIDER
928
15
1100
48
InitialSpeed
InitialSpeed
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
926
55
1098
88
acceleration
acceleration
0
2
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
928
94
1100
127
deceleration
deceleration
0
2
1.0
0.1
1
NIL
HORIZONTAL

PLOT
1119
11
1478
203
AverageSpeed
ticks
Speed
0.0
10.0
0.0
50.0
true
true
"" ""
PENS
"MaxSpeed" 1.0 0 -13345367 true "" ""
"MinSpeed" 1.0 0 -10899396 true "" ""

SWITCH
933
446
1095
479
ShowSlowestPoint?
ShowSlowestPoint?
1
1
-1000

SLIDER
931
361
1103
394
MaxSpeed
MaxSpeed
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
931
403
1103
436
allowance
allowance
0
20
1.0
1
1
NIL
HORIZONTAL

SLIDER
931
283
1103
316
speed-parameter
speed-parameter
0
15
5.0
1
1
NIL
HORIZONTAL

SWITCH
931
206
1071
239
allow-accident?
allow-accident?
0
1
-1000

SLIDER
931
322
1103
355
extra-lane-length
extra-lane-length
0
40
22.0
1
1
NIL
HORIZONTAL

SWITCH
930
168
1111
201
androids-change-lane?
androids-change-lane?
1
1
-1000

SLIDER
1342
385
1484
418
change-lane-x-of-100
change-lane-x-of-100
0
99
99.0
1
1
NIL
HORIZONTAL

MONITOR
1111
383
1234
428
Run Time (Seconds)
RunTime
0
1
11

SLIDER
928
130
1100
163
DistanceFromCar
DistanceFromCar
1
6
4.0
1
1
NIL
HORIZONTAL

INPUTBOX
1241
384
1341
444
RequiredLaps
1.0
1
0
Number

MONITOR
1111
431
1234
476
average speed
mean [speed] of students
0
1
11

BUTTON
13
202
86
253
ZoomIn
set ServerZoom-radius ServerZoom-radius - 1\n      if ServerZoom-radius < 1 [ set ServerZoom-radius 1 ]\n      ask students[\n       set zoom-radius ServerZoom-radius\n      ]\n
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
87
202
169
253
ZoomOut
;    if command = \"ZoomOut\"\n\n      set ServerZoom-radius ServerZoom-radius + 1\n      if ServerZoom-radius > 30 [ set ServerZoom-radius 30]\n        ask students[\n       set zoom-radius ServerZoom-radius\n      ]\n 
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
7
103
179
136
number-of-trucks
number-of-trucks
1
200
1.0
1
1
NIL
HORIZONTAL

SWITCH
931
245
1073
278
speed-limit?
speed-limit?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

A HubNet Simulation is a tool allowing teachers to run interactive online simulations in a classroom. The HubNet simulation is devided into to roles: Teacher and users. The teacher condeucts the simulation (instructions, advice, scenario etc.), and the students simulate that scenario.

This HubNet model simulates the movement of cars along a dual-lane highway. The cars are devided into 'Androids' and 'Students'. Each 'Android car' follows a simple set of rules: it slows down (decelerates) if there is a car close ahead, and speeds up (accelerates) if there isn't. All androids have the same look to it. Each 'Student car' is unique to a specific hubNet user, and follows the user's insturction regarding Acceleration and Deceleration.

The Simulation shows how individual driver's decision, although can appear to 'better' the situation, just 'worsten' it in the overall picture.
This simulation is an 'upgrade' to previous road models: extra lanes are added, and Cars are able to switch between lanes.

## HOW TO USE IT

Teacher: Follow these directions to setup the HubNet activity.
Make sure that there are enough cars selected (NUMBER-OF-CARS slider) for all the students.
Check all other sliders and switches (instructions below) according to desired scenario.

Select a name for the Server and Press START to wait for clients.
A list with all connected clients will be shown (CTRL+SHIFT+H to reopen).
Press the SETUP button.

Clients: Open up a HubNet Client on your machine and input the IP Address of Teacher's computer, type your user name in the user name box and press ENTER.

Teacher: Once everyone is logged in and has a car, the simulation is ready to begin.
Once everyone is ready, start the simulation by pressing the GO button.

Teacher: To run the activity again with the same group, stop the model by pressing the GO button, if it is on.  Change the values of the sliders and switches to the values you want for the new run.  Press the SETUP button.  Once everyone is ready, restart the simulation by pressing the GO button.

Teacher: To start the simulation over with a new group, stop the model by pressing the GO button, if it is on, press the RESET button in the Control Center and follow these instructions again from the beginning.

## TEACHER'S CONTROLS

Buttons:

SETUP - generates a new highway based on the current RADIUS and NUMBER-OF-CARS values.  This also clears all the plots.
GO - runs the simulation indefinitely

Sliders:

NUMBER-OF-CARS - sets the number of cars in the simulation (you must press the SETUP button to see the change)
RADIUS - sets the radius of the circle in which the cars go.
INITIALSPEED - sets the initial speed of the cars is defined by: random(1..initial)
ACCELERATION - sets the acceleration rate of the andorids.
DECELERATION - sets the deceleration rate of the andorids.
MAXSPEED - sets the maximum speed for the cars.
SPEED-PARAMETER - the amount the speed changes for the users on each click on  SPEED UP.
EXTRA-LANE-LENGH - sets the lenth of the extra (third) lane.
ALLOWENCE - sets the difference between a SLOW car and a FAST car (see SHOW-SLOWEST-POINT? below)
CHANGE-LANE-X-OF-100 - sets the android tendecy to change lanes (precentage) if ANDROIDS-CHANGE-LANE? switch is on

Switches:

SHOW-SLOWEST-POINT? - colors the slowest cars in same color (according to tendency)
ANDROIDS-CHANGE-LANE? - toggles android lane changes.
ALLOW-ACCIDENT? - toggles car crashing.

Plots:

AVERAGE SPEED - displays the average speed of cars over time

## CLIENT'S CONTROLS

After logging in, the client interface will appear for the students:

Buttons:

SPEED UP - Speed client's car up by SPEED-PARAMETER.
SPEED DOWN - Slow client's car down by SPEED-PARAMETER.
RIGHT / LEFT - Tries to change lane to the right or to the left. if no lane avelible on that side or another car occuping the space, the client will recieve a NO SPACE warning on the MESSEGE monitor. (there is no affect on the car).
ZOON IN / ZOOM OUT - Changes the view of the Client from close-by to full view.

Monitors

YOU ARE A:- The graphical description of clients car.
MESSEGE - Recieves messeges from the Teacher and from the simulation.
SPEED - The Current speed of the client's car.
NAME - The name of the client. will be shown above the car.

## THINGS TO NOTICE

Traffic jams can start from small "seeds."  These cars start with random positions and random speeds. If some cars are clustered together, they will move slowly, causing cars behind them to slow down, and a traffic jam forms.

Even though all of the cars are moving forward, the traffic jams tend to move backwards. This behavior is common in wave phenomena: the behavior of the group is often very different from the behavior of the individuals that make up the group.

The plot shows three values as the model runs:
- the fastest speed of any car (this doesn't exceed the speed limit!)
- the slowest speed of any car
- the speed of a single car (turtle 0), painted red so it can be watched.
Notice not only the maximum and minimum, but also the variability -- the "jerkiness" of one vehicle.

Notice that the default settings have cars decelerating much faster than they accelerate. This is typical of traffic flow models.

Even though both ACCELERATION and DECELERATION are very small, the cars can achieve high speeds as these values are added or subtracted at each tick.

## THINGS TO TRY

In this model there are three variables that can affect the tendency to create traffic jams: the initial NUMBER of cars, ACCELERATION, and DECELERATION. Look for patterns in how the three settings affect the traffic flow.  Which variable has the greatest effect?  Do the patterns make sense?  Do they seem to be consistent with your driving experiences?

Set DECELERATION to zero.  What happens to the flow?  Gradually increase DECELERATION while the model runs.  At what point does the flow "break down"?

## EXTENDING THE MODEL

Try other rules for speeding up and slowing down.  Is the rule presented here realistic?   Are there other rules that are more accurate or represent better driving strategies?

In reality, different vehicles may follow different rules. Try giving different rules or ACCELERATION/DECELERATION values to some of the cars.  Can one bad driver mess things up?

The asymmetry between acceleration and deceleration is a simplified representation of different driving habits and response times. Can you explicitly encode these into the model?

What could you change to minimize the chances of traffic jams forming?

What could you change to make traffic jams move forward rather than backward?

Make a model of two-lane traffic.

## NETLOGO FEATURES

The plot shows both global values and the value for a single turtle, which helps one watch overall patterns and individual behavior at the same time.

The WATCH command is used to make it easier to focus on the red car.

## RELATED MODELS

"Traffic" (in StarLogoT) adds graphics, trucks, and a radar trap.

"Gridlock" (a HubNet model which can be run as a participatory simulation) models traffic in a grid with many intersections.

## CREDITS AND REFERENCES

This model was developed at the MIT Media Lab using CM StarLogo.  See Resnick, M. (1994) "Turtles, Termites and Traffic Jams: Explorations in Massively Parallel Microworlds."  Cambridge, MA: MIT Press.  Adapted to StarLogoT, 1997, as part of the Connected Mathematics Project.  Adapted to NetLogo, 2001, as part of the Participatory Simulations Project.

If you mention this model in an academic publication, we ask that you include citations for the model itself and for the NetLogo software.

To cite the model, please use:
Wilensky, U. (1997).  NetLogo Traffic Basic model.  http://ccl.northwestern.edu/netlogo/models/TrafficBasic.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

To cite NetLogo, please use:
Wilensky, U. (1999). NetLogo. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. http://ccl.northwestern.edu/netlogo.

In other publications, please use:
Copyright 1997 Uri Wilensky.  All rights reserved.  See http://ccl.northwestern.edu/netlogo/models/TrafficBasic for terms of use.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ambulance
false
0
Rectangle -7500403 true true 30 90 210 195
Polygon -7500403 true true 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Rectangle -2674135 true false 29 151 298 158
Line -16777216 false 210 90 210 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Line -13345367 false 45 135 75 120
Line -13345367 false 75 135 45 120
Line -13345367 false 60 112 60 142

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

bus
false
0
Polygon -7500403 true true 15 206 15 150 15 120 30 105 270 105 285 120 285 135 285 206 270 210 30 210
Rectangle -16777216 true false 36 126 231 159
Line -7500403 false 60 135 60 165
Line -7500403 false 60 120 60 165
Line -7500403 false 90 120 90 165
Line -7500403 false 120 120 120 165
Line -7500403 false 150 120 150 165
Line -7500403 false 180 120 180 165
Line -7500403 false 210 120 210 165
Line -7500403 false 240 135 240 165
Rectangle -16777216 true false 15 174 285 182
Circle -16777216 true false 48 187 42
Rectangle -16777216 true false 240 127 276 205
Circle -16777216 true false 195 187 42
Line -7500403 false 257 120 257 207

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

car side
false
0
Polygon -7500403 true true 19 147 11 125 16 105 63 105 99 79 155 79 180 105 243 111 266 129 253 149
Circle -16777216 true false 43 123 42
Circle -16777216 true false 194 124 42
Polygon -16777216 true false 101 87 73 108 171 108 151 87
Line -8630108 false 121 82 120 108
Polygon -1 true false 242 121 248 128 266 129 247 115
Rectangle -16777216 true false 12 131 28 143

car top
true
0
Polygon -7500403 true true 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 false 210 165 195 165
Line -7500403 false 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11

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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
true
0
Rectangle -6459832 true false 90 105 210 240
Rectangle -1 true false 105 45 195 90
Rectangle -1 false false 120 135 135 135
Rectangle -1 true false 120 120 135 225
Rectangle -1 true false 165 120 180 225
Rectangle -6459832 true false 60 90 240 270
Rectangle -1 false false 75 45 225 90
Rectangle -1 true false 75 45 225 90
Polygon -2064490 true false 105 45 105 15 150 0 195 15 195 45

trucktop
true
3
Polygon -7500403 true false 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 false 210 165 195 165
Line -7500403 false 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11
Rectangle -16777216 true false 105 165 195 225
Rectangle -7500403 true false 90 30 120 75
Rectangle -16777216 false false 75 15 90 30
Rectangle -16777216 true false 90 15 135 75
Rectangle -7500403 true false 75 105 210 255
Rectangle -1 true false 90 60 210 105
Rectangle -16777216 true false 90 15 225 315

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

van side
false
0
Polygon -7500403 true true 26 147 18 125 36 61 161 61 177 67 195 90 242 97 262 110 273 129 260 149
Circle -16777216 true false 43 123 42
Circle -16777216 true false 194 124 42
Polygon -16777216 true false 45 68 37 95 183 96 169 69
Line -7500403 true 62 65 62 103
Line -7500403 true 115 68 120 100
Polygon -1 true false 271 127 258 126 257 114 261 109
Rectangle -16777216 true false 19 131 27 142

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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
189
10
1193
632
0
0
0
1
1
1
1
1
0
1
1
1
-55
55
-35
35

BUTTON
25
238
88
271
left
NIL
NIL
1
T
OBSERVER
NIL
J

BUTTON
98
238
161
271
right
NIL
NIL
1
T
OBSERVER
NIL
L

MONITOR
17
131
152
180
Messege
NIL
3
1

BUTTON
61
182
126
215
speed up
NIL
NIL
1
T
OBSERVER
NIL
I

BUTTON
61
293
124
326
speed down
NIL
NIL
1
T
OBSERVER
NIL
K

MONITOR
18
358
148
407
speed
NIL
0
1

MONITOR
16
75
154
124
Laps
NIL
0
1

MONITOR
17
21
154
70
OverallTIme
NIL
1
1

BUTTON
62
524
156
557
Switch halo
NIL
NIL
1
T
OBSERVER
NIL
NIL

@#$#@#$#@
default
0.0
-0.2 1 1.0 0.0
0.0 1 1.0 0.0
0.2 1 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@















































































































































































