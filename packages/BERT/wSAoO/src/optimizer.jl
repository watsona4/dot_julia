import Knet: update!

warmup_cosine(x, warmup=0.002) = x < warmup ? x/warmup : 0.5 * (1.0 + cos(π * x))
warmup_constant(x, warmup=0.002) = x < warmup ? x/warmup : 1.0
warmup_linear(x, warmup=0.002) = x < warmup ? x/warmup : 1.0 - x

mutable struct BertAdam
    lr::AbstractFloat
    beta1::AbstractFloat
    beta2::AbstractFloat
    eps::AbstractFloat
    t::Int
    gclip::AbstractFloat
    fstm
    scndm
    w_decay_rate::AbstractFloat
    schedule
    warmup
    t_total
end

BertAdam(; lr=0.001, gclip=1.0, beta1=0.9, beta2=0.999, eps=1e-6, w_decay_rate=0.0, schedule="warmup_linear", warmup=-1, t_total=-1)=BertAdam(lr, beta1, beta2, eps, 0, gclip, nothing, nothing, w_decay_rate, schedule, warmup, t_total)

for T in (Array{Float32},Array{Float64},KnetArray{Float32},KnetArray{Float64}); @eval begin
    function update!(w::$T, g::$T, p::BertAdam)
        Knet.gclip!(g, p.gclip)
        if p.fstm===nothing; p.fstm=zero(w); p.scndm=zero(w); end
        lmul!(p.beta1, p.fstm)
        axpy!(1-p.beta1, g, p.fstm)
        lmul!(p.beta2, p.scndm)
        axpy!(1-p.beta2, g .* g, p.scndm)
        # They don't do bias correction for some reason
        #fstm_corrected = p.fstm / (1 - p.beta1 ^ p.t)
        #scndm_corrected = p.scndm / (1 - p.beta2 ^ p.t)
        if p.t_total !== -1
            schedule_func = eval(Meta.parse(p.schedule))
            lr_scheduled = p.lr * schedule_func(p.t/p.t_total, p.warmup)
        else
            lr_scheduled = p.lr
        end

        if p.w_decay_rate > 0.0
            axpy!(-lr_scheduled, (p.fstm ./ (sqrt.(p.scndm) .+ p.eps)) .+ (p.w_decay_rate * w), w)
        else
            axpy!(-lr_scheduled, (p.fstm ./ (sqrt.(p.scndm) .+ p.eps)), w)
        end
        
        p.t += 1
    end
end;end
