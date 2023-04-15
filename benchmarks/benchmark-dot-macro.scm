(define max-loop 1e5)

(define-macro (make-elwise-vec-op aggregate-op per-el-op)
    `(lambda (v1 v2)
        (,aggregate-op
            (,per-el-op (car v1) (car v2))
            (,per-el-op (car (cdr v1)) (car (cdr v2)))
            (,per-el-op (car (cdr (cdr v1))) (car (cdr (cdr v2))))
        )
    )
)

(define dot-vec (make-elwise-vec-op list *))

(define (loop i)
    (and (< i max-loop) (begin
        (dot-vec (list i i i) (list (+ i 1) (+ i 2) (+ i 3)))
        (loop (+ i 1))
    ))
)

(loop 0)