(define max-loop 1e6)
(define (loop i)
    (and (< i max-loop) (begin
        (/ (+ i 5) i)
        (* i i i (/ i 15))
        (and i (* i 4))
        (loop (+ i 1))
    ))
)

(loop 0)