(define max-loop 1e6)

(define (func i)
    (/ (+ i 5) i)
    (* i i i (/ i 15))
    (and i (* i 4))
    (loop (+ i 1))
)
(define (loop i)
    (and (< i max-loop) (func i))
)

(loop 0)