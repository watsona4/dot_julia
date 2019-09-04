using VisualDL

# initialize
train_logger = VisualDLLogger("tmp", 1, "train")
test_logger = as_mode(train_logger, "test")

# log scalars
for i in 1:100
    with_logger(train_logger) do
        @log_scalar s0=(i,rand()) s1=(i, rand())
    end

    with_logger(test_logger) do
        @log_scalar s0=(i,rand()) s1=(i, rand())
    end
end

# log histograms
for i in 1:100
    with_logger(train_logger) do
       @log_histogram h0=(i, randn(100))
    end
end

# log texts
for i in 1:100
    with_logger(train_logger) do
       @log_text t0=(i, "This is test " * string(i))
    end
end

# log images
for i in 1:100
    with_logger(train_logger) do
       @log_image i0=([3,3,3], rand(27) * 255)
    end
end

for i in 1:100
    with_logger(test_logger) do
        # Array{Number, 3} is also supported
        @log_image image0=rand(10, 10, 3) * 255
    end
end

save(train_logger)
save(test_logger)