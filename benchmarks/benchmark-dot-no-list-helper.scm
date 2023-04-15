(define max-loop 1e5)
(define (dot-vec v1 v2)
    (+
        (* (car v1) (car v2))
        (* (car (cdr v1)) (car (cdr v2)))
        (* (car (cdr (cdr v1))) (car (cdr (cdr v2))))
    )
)

(define (loop i)
    (and (< i max-loop) (begin
        (dot-vec (list i i i) (list (+ i 1) (+ i 2) (+ i 3)))
        (loop (+ i 1))
    ))
)

(loop 0)