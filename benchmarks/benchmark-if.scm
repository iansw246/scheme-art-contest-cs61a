(define max-loop 1e6)
(define (loop i)
    (if (< i max-loop)
        (loop (+ i 1))
        #f
    )
)
(loop 0)