(define max-loop 1e6)
(define (loop i)
    (if (< i max-loop)
        (begin
            (if (> (modulo i 6) 2)
                "Greater"
                "less than"
            )
            (loop (+ i 1))
        )
        #f
    )
)
(loop 0)