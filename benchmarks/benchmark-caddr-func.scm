(define (caddr lst) (car (cdr (cdr lst))))

(define max-loop 1e5)
	
(define (loop i)
    (and (< i max-loop) (begin
        (caddr (list i (+ i 1) (* i 2)))
        (loop (+ i 1))
    ))
)

(loop 0)