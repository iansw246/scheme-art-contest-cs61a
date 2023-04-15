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
	; Dimensions of final rendered image. Must even numbers
	(define render-width 80)
	(define render-height 80)
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

	; Steps in x and y direction per pixel. Controls anti-aliasing amoutn
	(define x-steps-per-pixel 1)
	(define y-steps-per-pixel 1)
	(define rays-per-pixel (* x-steps-per-pixel y-steps-per-pixel))
	
	(define camera '(50 50 -80))
	; All colors are a list of 3 numbers for rgb from 0 to 1. Converted to color with rgb function
	; Center, radius, (ambient color, diffuse color, specular color, shiniess factor, reflective-color)
	; red sphere
	(define sphere1 (list '(20 20 30) 10 '((1 0 0) (1 0.3 0.3) (0.4 0.4 0.4) 0.9 #f)))
	; blue sphere
	(define sphere2 (list '(20 30 60) 30 '((0 0 1) (0.3 0.3 1) (0.4 0.4 0.4) 0.9 #f)))
	; Green sphere
	(define sphere3 (list '(70 70 30) 20 '((0 1 0) (0.3 1 0.3) (1 1 1) 4 #f)))
	; Metal reflective gray
	(define sphere4 (list '(90 20 160) 80 '((0.1 0.1 0.1) (0 0 0) (1 1 1) 25 (0.8 0.8 0.8))))
	(define spheres nil)
	
	; color
	(define ambient-light '(0.35 0.35 0.35))
	
	; light position, diffuse intensity (per color), specular intensity (per color)
	(define light1 (list '(50 100 300) '(0.5 0.5 0.5) '(0.8 0.8 0.8)))
	(define light2 (list '(90 90 10) '(0.5 0 0) '(0.5 0 0)))
	(define lights (list light1))

	(define floor-y -20)

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
	(define vec-y cadr)
	(define vec-z caddr)

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
	(define (sub-vec v1 v2)
		(add-vec v1 (neg-vec v2))
	)
	
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
	(define (sphere-radius s) (cadr s))
	(define (sphere-material s) (caddr s))
	(define (material-rgb-to-color rgb-list)
		(rgb
			(car rgb-list)
			(cadr rgb-list)
			(caddr rgb-list)
		)
	)

	(define (clamp-color color)
		(map (lambda (clr-comp) (min (list clr-comp 1))) color)
	)

	(define (floor-color x z)
		(if (even? (+ (quotient (+ x 1000) 14) (quotient (+ z 1000) 7)))
			'(0.5 0 0)
			'(0 0 0)
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
							(mul-vec (elwise-mul-vec (caddr light) (caddr material))
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

	(define MAX_RAY_RECURSION_DEPTH 3)

	(define (ray-color origin direction depth)
		(if (> depth MAX_RAY_RECURSION_DEPTH) (calc-bg-ray direction) (begin
			(define closest-intersect (closest-sphere-intersect spheres origin direction))
			(define t (car closest-intersect))
			(define sphere (car (cdr closest-intersect)))
			(if (and sphere t)
				(begin
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
				)
				; No intersect with sphere
				(begin
					; Calculate intersection with floor
					; t = (floorY - y(origin)) / y(direction)
					; Ignore horizontal ray
					(if (= (car (cdr direction)) 0)
						(calc-bg-ray direction)
						(begin
							(define t (/ (- floor-y (car (cdr origin))) (car (cdr direction))))
							(define intersect-x (+ (car origin) (* t (car direction))))
							(define intersect-z (+ (car (cdr (cdr origin))) (* t (car (cdr (cdr direction))))))
							(if (and (> t 0.01) (> intersect-x -50) (< intersect-x 150) (> intersect-z 50) (< intersect-z 250))
								; intersects floor
								(begin
									(define this-floor-color (floor-color intersect-x intersect-z))
									(define floor-ambient-color (mul-vec this-floor-color 0.2))
									(define floor-mat
										(list
											floor-ambient-color ; Ambient color
											this-floor-color ; diffuse color
											'(0 0 0) ; specular color
											4 ; shininess factor
											#f ; reflective color
										)
									)
									(clamp-color (add-vec floor-ambient-color
										(compute-lighted-color
											lights
											'(0 0 0)
											floor-mat
											(list intersect-x floor-y intersect-z) ; intersect point
											'(0 1 0) ; normal
											origin
											direction
											spheres
										)
									))
								)
								(calc-bg-ray direction)
							)
						)
					)
				)
			))
		)
	)
	
	(define (y-loop render-y)
		; Loop while render-y < render-height
		(and (< render-y render-height)
			(begin
				(x-loop 0 render-y)
				(print 'Finished 'y: render-y '/ render-height)
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
	; Full frame background
	; (bgcolor "gray")
	; Drawing area background
	(pixelsize render-height)
	(pixel (+ render-width turtle-x-offset) (+ render-height turtle-y-offset) "black")
	(pixelsize 1)
	(penup)
	(y-loop 0)
  (exitonclick))  
 

; Please leave this last line alone.  You may add additional procedures above
; this line.
(draw)