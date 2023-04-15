(define max-loop 1e5)

(define (cddr lst) (cdr (cdr lst)))
	
(define (cadr lst) (car (cdr lst)))
(define (caddr lst) (car (cddr lst)))

(define (dot-vec v1 v2)
    (+
        (* (car v1) (car v2))
        (* (cadr v1) (cadr v2))
        (* (caddr v1) (caddr v2))
    )
)

(define (loop i)
    (and (< i max-loop) (begin
        (dot-vec (list i i i) (list (+ i 1) (+ i 2) (+ i 3)))
        (loop (+ i 1))
    ))
)

(loop 0)