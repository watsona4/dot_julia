using BERT

config = BertConfig(128, 30022, 256, 512, 4, 2, 8, 2, 3, Array{Float32}, 0.1, 0.1, "relu")

model = BertPreTraining(config)

x = [213 234 7789; 712 9182 8912; 7812 12 432; 12389 1823 8483] # 4x3
segment_ids = [1 1 1;1 2 1;1 2 1;1 1 1]
mlm_labels = [-1 234 -1; -1 -1 8912; -1 -1 -1; 12389 -1 -1]
nsp_labels = [1, 2, 1]

loss = model(x, segment_ids, mlm_labels, nsp_labels)
println(loss)
