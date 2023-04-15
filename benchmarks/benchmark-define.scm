(define max-loop 1e6)
(define (loop i)
    (and (< i max-loop) (begin
        (define a (+ 2 4))
        (define b (/ 5 2))
        (define c (- 4 6))
        (define d (* a b c))
        (define e (= c d))
        (loop (+ i 1))
    ))
)

(loop 0)