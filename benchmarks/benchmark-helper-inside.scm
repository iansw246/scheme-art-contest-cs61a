(define max-loop 1e6)
(define (loop i)
    (and (< i max-loop) (begin
        (define (helper i total)
            (if (< i 1e3)
                (helper (+ 1 i) (+ total (* i i (+ 2 i))))
                total
            )
        )
        (helper 0 0)
        (loop (+ i 1))
    ))
)

(loop 0)