# KongYiji.jl
断文识字的“孔乙己” -- 一个简单的中文分词工具
Kong Yiji, a simple fine tuned Chinese tokenizer

## Features

### Version 0.1.0
                
1. Trained on Chinese Treebank 8.0. Of version 1 now, using a extended word-level Hidden Markov Model(HMM) contrast by eariler char-level HMM. 

2. Fine tuned to deal with **new words**(未登录词, 网络新词). If the algorithm cannot find them, just add them to user dict(see **Constructor**), and twist **usr_dict_weight** if necessary.

3. Fully exported debug info. See Usage.

## Constructor
```julia
kong(; user_dict_path="", user_dict_array=[], user_dict_weight=1)
```
        
+  **user_dict_path** : a file path of user dict, eachline of which begin a **word**, optionally followed by a **part-of-speech tag(postag)**;
                               If the postag not supplied, **NR (Proper noun, 专有名词)** is automatically inserted. 
+ **user_dict_array** : a Vector{Tuple{String, String}} repr. [(postag, word)]
        
+ **user_dict_weight** : if value is **m**, frequency of (postag, word) in user dictionary will be $ m * maximum(values(h2v[postag])) $

***Note all user suppiled postags MUST conform to specifications of Chinest Treebank.***
```
                                     CTB postable
  -------------------------------------------------------------------------------------
      ﻿part.of.speech                                                            summary
  1               NR                                                           专属名词
  2               NT                                                               时间
  3               NN                                                           其他名词
  4               PN                                                               代词
  5               VA                                                       形容词动词化
  6               VC                                              be、not be 对应的中文
  7               VE                                          have、not have 对应的中文
  8               VV                                                           其他动词
  9                P                                                               介词
  10              LC                                                             方位词
  11              AD                                                               副词
  12              DT                                                       谁的，哪一个
  13              CD                                                         （数）量词
  14              OD                                                         （顺）序词
  15               M                                                         （数）量词
  16              CC                                                         连（接）词
  17              CS                                                         连（接）词
  18             DEC                                                                 的
  19             DEG                                                                 的
  20             DER                                                                 得
  21             DEV                                                                 地
  22              AS Aspect Particle 表达英语中的进行式、完成式的词，比如（着，了，过）
  23              SP                               句子结尾词（了，吧，呢，啊，呀，吗）
  24             ETC                                                           等（等）
  25             MSP                                                               其他
  26              IJ                                                         句首感叹词
  27              ON                                                             象声词
  28              LB                                                                 被
  29              SB                                                                 被
  30              BA                                                                 把
  31              JJ                                                         名词修饰词
  32              PU                                                           标点符号
  33              FW                                        POS不清楚的词（不是外语词）
```

## Usage

``` Julia

println("Simple Usage")
tk = Kong()
input = "一个脱离了低级趣味的人"
output = tk(input)
@show output
println()

println("Debug Output")
input = "一/个/脱离/了/低级/趣味/的/人"
tk(input, "/")
println()

println("Test some difficult cases, from https://www.matrix67.com/blog/archives/4212")
inputs = [
        "他/说/的/确实/在理",
        "这/事/的确/定/不/下来",
        "费孝通/向/人大/常委会/提交/书面/报告",
        "邓颖超/生前/使用/过/的/物品",
        "停电/范围/包括/沙坪坝区/的/犀牛屙屎/和/犀牛屙屎抽水",
]
println("Input :")
for input in inputs
        println(input)
end

println("Raw output :")
for input in inputs
        println(tk(filter(c -> c != '/', input)))
end

tk2 = Kong(; user_dict_array=[("VV", "定"),
                              ("VA", "在理"),
                               "邓颖超",
                               "沙坪坝区", 
                               "犀牛屙屎",
                               "犀牛屙屎抽水",
                             ]
)
println("Output with user dict supplied :")
for input in inputs
        println(tk2(filter(c -> c != '/', input)))
end
```

## Output
```
Simple Usage
output = ["一", "个", "脱离", "了", "低级", "趣味", "的", "人"]

Debug Output
Standard : 一  个  脱离  了  低级  趣味  的  人
Output   : 一  个  脱离  了  低级  趣味  的  人
          KongYiji(1) Debug Table
  -----------------------------------------
     word pos.tag source prob.h2v Prob.Add.
  1    一      CD    CTB 0.323977  0.203435
  2    个       M    CTB 0.260022  0.019667
  3  脱离      VV    CTB 0.000177    1.1e-5
  4    了      AS    CTB 0.808087  0.045661
  5  低级      JJ    CTB 0.000462  0.000352
  6  趣味      NN    CTB   4.2e-5    2.0e-6
  7    的     DEG    CTB 0.972857  0.744126
  8    人      NN    CTB  0.01615  0.004388
  =========================================
  neg.log.likelihood = 50.088239033558935

  AhoCorasickAutomaton Matched Words
  ---------------------------
      UInt8.range word source
  1        (1, 4)   一    CTB
  2        (4, 7)   个    CTB
  3       (7, 10)   脱    CTB
  4       (7, 13) 脱离    CTB
  5      (10, 13)   离    CTB
  6      (13, 16)   了    CTB
  7      (16, 19)   低    CTB
  8      (16, 22) 低级    CTB
  9      (19, 22)   级    CTB
  10     (22, 25)   趣    CTB
  11     (22, 28) 趣味    CTB
  12     (25, 28)   味    CTB
  13     (28, 31)   的    CTB
  14     (31, 34)   人    CTB


Test some difficult cases, from https://www.matrix67.com/blog/archives/4212
Input :
他/说/的/确实/在理
这/事/的确/定/不/下来
费孝通/向/人大/常委会/提交/书面/报告
邓颖超/生前/使用/过/的/物品
停电/范围/包括/沙坪坝区/的/犀牛屙屎/和/犀牛屙屎抽水
Raw output :
["他", "说", "的", "确实", "在", "理"]
["这", "事", "的", "确定", "不", "下来"]
["费孝通", "向", "人大", "常委会", "提交", "书面", "报告"]
["邓", "颖", "超生", "前", "使用", "过", "的", "物品"]
["停电", "范围", "包括", "沙", "坪", "坝", "区", "的", "犀牛", "屙", "屎", "和", "犀牛", "屙", "屎", "抽水"]
Output with user dict supplied :
["他", "说", "的", "确实", "在理"]
["这", "事", "的确", "定", "不", "下来"]
["费孝通", "向", "人大", "常委会", "提交", "书面", "报告"]
["邓颖超", "生前", "使用", "过", "的", "物品"]
["停电", "范围", "包括", "沙坪坝区", "的", "犀牛屙屎", "和", "犀牛屙屎抽水"]
```

## Todos
+ Filter low frequency words from CTB
+ Exploit summary of POS table, insert a example column, plus constract with other POS scheme(PKU etc.)
+ Explore MaxEntropy & CRF related algorithms
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTEyNDI5Nzk3MTUsLTIwMDY4ODQ4NF19
-->