;;; Scheme Recursive Art Contest Entry
;;;
;;; Please do not include your name or personal info in this file.
;;;
;;; Title: <Your title here>
;;;
;;; Description:
;;;   <It's your masterpiece.
;;;    Use these three lines to describe
;;;    its inner meaning.>

(define (draw)
	;;; Image dimension and rendering quality settings
	; Dimensions of final rendered image. Must even numbers
	(define render-width 20)
	(define render-height 20)
	(and (or (odd? render-width) (odd? render-height)) (/ "Render dimensions be even"))
	(define turtle-x-offset (- (quotient render-width 2)))
	(define turtle-y-offset (- (quotient render-height 2)))

	; virtual camera screen dimensions
	(define screen-min-x 0)
	(define screen-max-x 100)
	(define screen-min-y 0)
	(define screen-max-y 100)

	(define screen-width (- screen-max-x screen-min-x))
	(define screen-height (- screen-max-y screen-min-y))
	; Change in x/y in screen/world coordinates for every change in pixel in render space
	(define per-pixel-screen-x-step (/ screen-width render-width))
	(define per-pixel-screen-y-step (/ screen-height render-height))

	; Steps in x and y direction per pixel. Controls anti-aliasing amount
	(define x-steps-per-pixel 1)
	(define y-steps-per-pixel 1)
	(define rays-per-pixel (* x-steps-per-pixel y-steps-per-pixel))

	(define height-segments 2)
	; Range is [0, height-segments)
	(define height-segment-index 1)
	(define render-height-start (* height-segment-index (/ render-height height-segments)))
	(define render-height-end (* (+ height-segment-index 1) (/ render-height height-segments)))
	(define lines-to-render (- render-height-end render-height-start))
	(and (not (and (integer? render-height-start) (integer? render-height-end))) (print "Render segments not integers. CHange dimensions") (/ 1 0))
	
	;;; Scene object setup
	; Camera looks into positive z direction
	(define camera '(50 50 -180))
	; All colors are a list of 3 numbers for rgb from 0 to 1. Converted to color with rgb function
	; Center, radius, (ambient color, diffuse color, specular color, shiniess factor, reflective-color)
	
	; Big snowman segments
	(define big-snowman-body-material '((0.2 0.2 0.2) (0.5 0.5 0.5) (0.9 0.9 0.9) 15 (0.95 0.95 0.95)))
	(define big-snowman-glowing-eye-material '((5 0.1 0.1) (0.9 0.9 0.9) (0.9 0.9 0.9) 0.9 #f))
	(define big-top (list '(30 110 90) 30 big-snowman-body-material))
	(define big-middle (list '(30 50 90) 50 big-snowman-body-material))
	(define big-bottom (list '(30 -40 90) 75 big-snowman-body-material))
	(define big-left-eye (list '(20 110 64) 8 '((0.05 0.05 0.05) (0.15 0.15 0.15) (0.9 0.9 0.9) 25 #f)))
	(define big-left-eye-glow (list '(20 110 60) 5 big-snowman-glowing-eye-material))
	(define big-right-eye (list '(40 110 64) 8 '((0.05 0.05 0.05) (0.15 0.15 0.15) (0.9 0.9 0.9) 25 #f)))
	(define big-right-eye-glow (list '(40 110 60) 5 big-snowman-glowing-eye-material))
	; Small snowman segments
	(define small-snowman-body-material '((0.5 0.5 0.5) (0.8 0.8 0.8) (0.1 0.1 0.1) 1 #f))
	(define small-snowman-eyes-material '((0 0 0) (0.1 0.1 0.1) (0.9 0.9 0.9) 25 #f))
	(define small-top (list '(80 65 30) 10 small-snowman-body-material))
	(define small-middle (list '(80 45 30) 15 small-snowman-body-material))
	(define small-bottom (list '(80 20 30) 20 small-snowman-body-material))
	(define small-left-eye (list '(75 65 38) 2 small-snowman-eyes-material))
	(define small-right-eye (list '(71 65 33) 2 small-snowman-eyes-material))

	(define spheres (list big-top big-middle big-bottom big-left-eye big-left-eye-glow big-right-eye big-right-eye-glow small-top small-middle small-bottom small-left-eye small-right-eye))
	
	; color
	(define ambient-light '(0.35 0.35 0.35))
	
	; light position, diffuse intensity (per color), specular intensity (per color)
	(define left-light (list '(-75 55 0) '(0.3 0.3 0.3) '(0 0 0)))
	(define big-left-eye-light (list '(20 110 52) '(0.5 0.1 0.1) '(0.7 0.1 0.1)))
	(define big-right-eye-light (list '(40 110 52) '(0.5 0.1 0.1) '(0.7 0.1 0.1)))
	(define lights (list left-light big-left-eye-light big-right-eye-light))

	; Don't set to 0 because of bug in intersection code
	(define floor-y -1)

	; Default gamma value
	; (define gamma 2.2)
	; Disable gamma for a darker scene
	(define gamma 1)

	; (define (max lst)
	; 	(define (helper lst max_val)
	; 		(cond ((null? lst) max_val)
	; 			((> (car lst) max_val) (helper (cdr lst) (car lst)))
	; 			(else (helper (cdr lst) max_val))
	; 		)
	; 	)
	; 	(helper (cdr lst) (car lst))
	; )

	(define (min lst)
		(define (helper lst min_val)
			(cond ((null? lst) min_val)
				((< (car lst) min_val) (helper (cdr lst) (car lst)))
				(else (helper (cdr lst) min_val))
			)
		)
		(helper (cdr lst) (car lst))
	)
	
	; Calculate background color given pixel coordinate x, y
	; rgb(28 143 187)
	(define top-color '(0.1098 0.56078 0.73333))
	; rgb(175 228 234)
	(define bottom-color '(0.68627 0.89411 0.91764))
	(define (calc-bg-color x y)
		'(0 0 0)
		;(define proportion (/ (+ y 1) 2))
		;(add-vec (mul-vec top-color proportion) (mul-vec bottom-color (- 1 proportion)))
	)
	
	; can remove
	(define (gradient-func x y)
		(rgb
			(/ x screen-height)
			(/ y screen-height)
			0.5
		)
	)
	
	; These reduce performance. Should manually expand in most places
	(define (cddr lst) (cdr (cdr lst)))
	
	(define (cadr lst) (car (cdr lst)))
	(define (caddr lst) (car (cddr lst)))

	(define vec-x car)
	(define vec-y (lambda (lst) (car (cdr lst))))
	(define vec-z (lambda (lst) (car (cdr (cdr lst)))))

	(define-macro (make-elwise-vec-op aggregate-op per-el-op)
		`(lambda (v1 v2)
			(,aggregate-op
				(,per-el-op (car v1) (car v2))
				(,per-el-op (car (cdr v1)) (car (cdr v2)))
				(,per-el-op (car (cdr (cdr v1))) (car (cdr (cdr v2))))
			)
		)
	)
	
	(define (neg-vec v1)
		(mul-vec v1 -1)
	)
	
	; Mulitply (scale) vector v1 by scalar s
	(define (mul-vec v1 s)
		(map (lambda (el) (* el s)) v1)
	)

	(define add-vec (make-elwise-vec-op list +))
	
	; (define (add-vec v1 v2)
	; 	(list
	; 		(+ (car v1) (car v2))
	; 		(+ (cadr v1) (cadr v2))
	; 		(+ (caddr v1) (caddr v2))
	; 	)
	; )
	
	; v1 - v2 = v1 + (- v2)
	(define sub-vec (make-elwise-vec-op list -))
	
	; (define (dot-vec v1 v2)
	; 	(+
	; 		(* (car v1) (car v2))
	; 		(* (cadr v1) (cadr v2))
	; 		(* (caddr v1) (caddr v2))
	; 	)
	; )

	(define dot-vec (make-elwise-vec-op + *))

	; elementwise multiple vector
	; (define (elwise-mul-vec v1 v2)
	; 	(list
	; 		(* (car v1) (car v2))
	; 		(* (cadr v1) (cadr v2))
	; 		(* (caddr v1) (caddr v2))
	; 	)
	; )
	(define elwise-mul-vec (make-elwise-vec-op list *))

	(define (normalize-vec v1)
		(mul-vec v1 (/ 1 (sqrt (dot-vec v1 v1))))
	)
	
	; returns parameter for the closest intersection of the ray with sphere. The equation is (origin + ray * t).
	; Returns #f if no intersection
	; Does not return intersections at origin
	(define (sphere-intersect sphere origin direction)
		(define a (dot-vec direction direction))
		(define origin-sphere-diff (sub-vec origin (sphere-center sphere)))
		(define b (dot-vec origin-sphere-diff direction))
		(define c (- (dot-vec origin-sphere-diff origin-sphere-diff ) (* (sphere-radius sphere) (sphere-radius sphere))))
		
		(define descrim (- (* b b) (* a c)))
		; If descrim > 0, return parameter. Else, return false
		(and (> descrim 0)
			(begin
				; (-b + sqrt(b^2 -ac)) / 2
				(define t1 (/ (+ (- b) (sqrt descrim)) a))
				; (-b - sqrt(b^2 -ac)) / a
				(define t2 (/ (- (- b) (sqrt descrim)) a))
				(cond
					((<= t1 0) (and (> t2 0) t2))
					((<= t2 0) (and (> t1 0) t1))
					((< t1 t2) t1)
					(else t2)
				)
			)
		)
	)
	
	; Returns t and closest sphere
	; t is the parameter for the line from camera along ray
	; Spheres list must not be empty
	; If no intersection, then closest sphere is false
	(define (closest-sphere-intersect spheres origin direction)
		(define (helper spheres min-t closest-sphere)
			(if (null? spheres) (list min-t closest-sphere)
				(begin
					(define t (sphere-intersect (car spheres) origin direction))
					; Exclude t = 0 or close to zero. Also exclude negative because don't want to look behind
					(if (and t (< t min-t) (> t 0.01)) (helper (cdr spheres) t (car spheres))
						(helper (cdr spheres) min-t closest-sphere)
					)
				)
			)
		)
		; Set min to a massive number so any t will be smaller
		(helper spheres 100000000 #f)
	)

	; Returns whether the point on this-sphere is in a shadow, based on the shadow-vec (from that point to the light)
	; spheres-except-current is a list of spheres in scene except the one which is being tested if in shadow
	(define (sphere-in-shadow point light spheres-except-current)
		(define shadow-vec (sub-vec (car light) point))
		(define (helper all-spheres)
			; If all-sphere is empty, return false. Else, check if intersection
			(and (not (null? all-spheres))
				(begin
					(define possible-intersect (sphere-intersect (car all-spheres) point shadow-vec))
					(if (and possible-intersect (> possible-intersect 0) (< possible-intersect 1))
						#t
						(sphere-in-shadow point light (cdr spheres-except-current))
					)
				)
			)
		)
		(helper spheres-except-current)
	)
	
	(define (sphere-center s) (car s))
	(define (sphere-radius s) (car (cdr s)))
	(define (sphere-material s) (car (cdr (cdr s))))

	; Color functions
	(define (material-rgb-to-color rgb-list)
		(rgb
			(car rgb-list)
			(car (cdr rgb-list))
			(car (cdr (cdr rgb-list)))
		)
	)

	(define (rgb-to-color r g b)
		(list
			(/ r 255)
			(/ g 255)
			(/ b 255)
		)
	)

	(define (clamp-color color)
		(map (lambda (clr-comp) (min (list clr-comp 1))) color)
	)

	(define gamma-scale (/ gamma))

	; gamma-corrects given color by gamma global variable
	(define (gamma-correct-color color)
		(list
			(expt (car color) gamma-scale)
			(expt (car (cdr color)) gamma-scale)
			(expt (car (cdr (cdr color))) gamma-scale)
		)
	)

	; Floor functions

	(define floor-red-square-material
		(list
			(list (/ 218 1020) (/ 44 1020) (/ 56 1020)) ; Ambient color. RGB (218, 44, 56) / 4
			(list (/ 218 255) (/ 44 255) (/ 56 255)) ; diffuse color. RGB (218, 44, 56)
			'(0.8 0.8 0.8) ; specular color
			3 ; shininess factor
			#f ; reflective color
		)
	)

	; Create material outside so only done once
	(define floor-green-square-material
		(list
			(rgb-to-color (/ 106 4) (/ 153 4) (/ 78 4)) ; Ambient color. RGB (106 153 78) / 4
			(rgb-to-color 106 153 78) ; diffuse color.  RGB (106 153 78)
			'(0.8 0.8 0.8) ; specular color
			3 ; shininess factor
			#f ; reflective color
		)
	)

	(define (floor-material x z)
		(if (even? (+ (quotient (+ x 1000) 18) (quotient (+ z 1000) 18)))
			floor-red-square-material
			floor-green-square-material
		)
	)

	(define (calc-bg-ray direction)
		(define unit-direction (normalize-vec direction))
		(calc-bg-color (vec-x unit-direction) (vec-y unit-direction))
	)

	; Add diffuse and specular lighting from every light
	(define (compute-lighted-color lights current-color material intersect-point normal origin direction spheres-except-current)
		(if (null? lights) current-color (begin
			(define light (car lights))
			(define intersect-to-light (normalize-vec (sub-vec (car light) intersect-point)))

			; Check for shadow
			; Loop through all other spheres and check if intersection is between 0 < t < 1
			(if (sphere-in-shadow intersect-point light spheres-except-current)
				; In shadow. Don't add colors for this light
				(compute-lighted-color (cdr lights) current-color material intersect-point normal origin direction spheres-except-current)
				; not in shadow
				(begin
					; component of light in diffuse direction
					(define diffuse-comp (dot-vec normal intersect-to-light))
					(define diffuse-color
						(if (< diffuse-comp 0) '(0 0 0)
							; Diffuse component (Light diffuse color dot material diffuse color)
							(mul-vec (elwise-mul-vec (cadr light) (cadr material)) diffuse-comp)
						)
					)

					(define reflectance-vector (sub-vec (mul-vec normal (* 2 (dot-vec normal intersect-to-light))) intersect-to-light))
					(define view-vector (normalize-vec (sub-vec origin intersect-point)))
					(define view-dot-reflectance (dot-vec view-vector reflectance-vector))
					(define specular-color 
						(if (< view-dot-reflectance 0) '(0 0 0)
							; Light specular color elementwise multiplied by material specular color
							(mul-vec (elwise-mul-vec (car (cdr (cdr light))) (car (cdr (cdr material))))
								; raise view-dot-reflectance to power of shininess constant (4th elemnt in material list)
								(expt view-dot-reflectance (cadr (cddr material)))
							)
						)
					)
					(compute-lighted-color (cdr lights)
						(add-vec current-color (add-vec diffuse-color specular-color))
						material intersect-point normal origin direction spheres-except-current
					)
				)
			)
		))
	)

	; Returns parameter for direction for intersection with floor, or #f if no intersection
	(define (floor-intersect origin direction)
		(if (= (car (cdr direction)) 0)
			#f ; Should check if y of origin is same as y-floor, but this works as long as that is never true
			(begin
				(define t (/ (- floor-y (car (cdr origin))) (car (cdr direction))))
				(define intersect-x (+ (car origin) (* t (car direction))))
				(define intersect-z (+ (car (cdr (cdr origin))) (* t (car (cdr (cdr direction))))))
				(and (> t 0.01) (> intersect-x -100) (< intersect-x 250) (> intersect-z -100) (< intersect-z 50) t)
			)
		)
	)

	; Maximum of ray bounces allowed before stopping
	(define MAX_RAY_RECURSION_DEPTH 5)

	; Not gamma corrected color for ray
	(define (ray-color origin direction depth)
		(if (> depth MAX_RAY_RECURSION_DEPTH) (calc-bg-ray direction) (begin
			(define closest-intersect (closest-sphere-intersect spheres origin direction))
			(define t (car closest-intersect))
			(define sphere (car (cdr closest-intersect)))

			(define floor-t (floor-intersect origin direction))
			; (print closest-intersect)
			; (print floor-t)

			(cond
				; no intersection with spheres or floor
				((and (not sphere) (not floor-t)) (calc-bg-ray direction))
				; Sphere is closer
				((or (not floor-t) (< t floor-t)) (begin
					(define sphere-mat (sphere-material sphere))
					(define intersect-point (add-vec (mul-vec direction t) origin))
					(define normal (normalize-vec (sub-vec intersect-point (sphere-center sphere))))
					(define ambient-color (elwise-mul-vec (car sphere-mat) ambient-light))
					(define spheres-except-current (filter (lambda (el) (not (eq? el sphere))) spheres))

					; Color from diffuse and specular
					(define color-no-ambient (compute-lighted-color lights '(0 0 0) sphere-mat intersect-point normal origin direction spheres-except-current))

					; Color from reflection
					; Compute only if reflectivity not false
					; 5th element in list
					(define reflectivity-color (caddr (cddr sphere-mat)))
					(define reflected-color (if reflectivity-color
						(begin
							(define reflected-ray (sub-vec direction (mul-vec normal (* 2 (dot-vec direction normal)))))
							(elwise-mul-vec reflectivity-color (ray-color intersect-point reflected-ray (+ depth 1)))
						)
						'(0 0 0)
					))
					; Clamp color components to range [0, 1]
					(define final-color-unclamped (clamp-color (add-vec (add-vec color-no-ambient ambient-color) reflected-color)))
					(define final-color (map (lambda (clr-comp) (min (list clr-comp 1))) final-color-unclamped))
					final-color
				))
				; Floor is closer
				(else (begin
					(define intersect-x (+ (car origin) (* floor-t (car direction))))
					(define intersect-z (+ (car (cdr (cdr origin))) (* floor-t (car (cdr (cdr direction))))))
					(define this-floor-mat (floor-material intersect-x intersect-z))
					(clamp-color (add-vec (car this-floor-mat) ; Floor ambient color
						(compute-lighted-color
							lights
							'(0 0 0)
							this-floor-mat
							(list intersect-x floor-y intersect-z) ; intersect point
							'(0 1 0) ; normal
							origin
							direction
							spheres
						)
					))
				))
			)
		))
	)
	
	(define (y-loop render-y)
		; Loop while render-y < render-height
		(and (< render-y render-height-end)
			(begin
				(x-loop 0 render-y)
				(displayln 'Finished 'row (- render-y render-height-start -1) '/ lines-to-render "(" (* (/ (- render-y render-height-start -1) lines-to-render) 100) "% complete)")
				(y-loop (+ render-y 1))
			)
		)
	)

	; inner loop
	(define (x-loop render-x render-y)
		(and (< render-x render-width)
			(begin
				; Where to draw this point, in pixel (turtle) space
				(define turtle-x (+ render-x turtle-x-offset))
				(define turtle-y (+ render-y turtle-y-offset))

				(define screen-x (+ (/ (* render-x screen-width) render-width) screen-min-x))
				(define screen-y (+ (/ (* render-y screen-height) render-height) screen-min-y))

				; Anti-aliasing loop for multiple rays per pixel
				(define (pixel-y-loop y-step result-color)
					(if (< y-step y-steps-per-pixel)
						(pixel-y-loop (+ y-step 1) (pixel-x-loop 0 y-step result-color))
						result-color
					)
				)

				(define (pixel-x-loop x-step y-step result-color)
					(if (< x-step x-steps-per-pixel)
						(begin
							(define new-screen-x (+ screen-x (* x-step per-pixel-screen-x-step)))
							(define new-screen-y (+ screen-y (* y-step per-pixel-screen-y-step)))
							(define ray (list
								(- new-screen-x (vec-x camera))
								(- new-screen-y (vec-y camera))
								(- (vec-z camera))
							))
							(pixel-x-loop (+ x-step 1) y-step (add-vec (ray-color camera ray 1) result-color))
						)
						result-color
					)
				)

				;(pixel turtle-x turtle-y (gradient-func x y))

				(define average-color (pixel-y-loop 0 '(0 0 0)))
				(define final-color (mul-vec average-color (/ 1 rays-per-pixel)))
				; Disable gamma correction for darker scene
				; (define uncorrected-final-color (mul-vec average-color (/ 1 rays-per-pixel)))
				; (define final-color (gamma-correct-color uncorrected-final-color))

				(pixel turtle-x turtle-y (material-rgb-to-color final-color))

				;
				; (define intersect-point (list
					
				; )
				; ; Circle normal at intersection
				; (define sphere-normal
				
				(x-loop (+ render-x 1) render-y)
			)
		)
	)
	
	(ht)
	; Draw background for image
	(penup)
	(pendown)
	(begin_fill)
	(goto turtle-x-offset turtle-y-offset)
	(setheading 0)
	(forward (- render-height 1))
	(setheading 90)
	(forward (- render-width 1))
	(setheading 180)
	(forward (- render-height 1))
	(setheading 270)
	(forward (- render-width 1))
	(end_fill)
	(penup)

	; (pixelsize render-height)
	; (pixel (+ render-width turtle-x-offset) (+ render-height turtle-y-offset) "black")
	(pixelsize 1)
	(penup)
	(y-loop render-height-start)
	(displayln "Rendered lines from" render-height-start "to" render-height-end "(" lines-to-render " lines)")
  (exitonclick))  
 

; Please leave this last line alone.  You may add additional procedures above
; this line.
(draw)