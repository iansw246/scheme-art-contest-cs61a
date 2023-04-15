(define max-loop 1e6)
(define (loop i)
    (and (< i max-loop) (begin
        (let (
                (a (+ 2 4))
                (b (/ 5 2))
                (c (- 4 6))
            )
            (define d (* a b c))
            (define e (= c d))
            (loop (+ i 1))
        )
    ))
)

(loop 0)