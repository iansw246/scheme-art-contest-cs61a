(define max-loop 1e6)
(define (loop i)
    (and (< i max-loop) (loop (+ i 1)))
)

(loop 0)