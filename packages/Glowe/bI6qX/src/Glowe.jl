#                                                  ....
#                                 ......''''''....;cll:;,..
#                          .';cllc:::cccc:c::::cccldxdlll:,.
#                         .ldxxxxkdlcccc:ccccccccclodoccllc.
#                       .':oddkxxlxkdollccccccc::::cl:';c:'.
#                       ,ccdxkkxd;dOxddoclllcllllc:::c,....
#                      .;llcclc:;:xxxddooxkkddddol:::::;;;'.
#                    ..,;cloollooddddddddxxkO0Odollcc:;;,'.
#                 .,;lddl:cloooddddddddxkOOOOOkxdolc:;,'..
#          .;:,. .:loxOOdlccoodxxxxxxxdddxxxxddolc;,'...
#        .l0K0ko:coodOK0xol;;,;::ccc:;;;;;;;;,''........    ..:dxl,
#       .l0XX0xolodddkOkdolc:::,'.......................  ..,:oO00Oc
#        :kOkxoloxxkkkdc;;;;;;,,''.........................':lodxkx:.
#        .odooolxxxkkkd,;clcccc;,'.......................',:loool:'
#      .;:ododxkxdkkkkx;;olllccc:;,,,,,,,,'''''''...;c:;;;:clc;.
#      ,ldxxxkkkddxkxxxoclclclcc:::::::cc:::::;,'..cxkoc:;;;.
#      'ldxxxxkdlddxkxkOkxxo::c:::::;;;;;::cl:,'.'ckOOdc;'.....
#      .lddddddxxdkkOxxO0kdxOkl,'.......,:lodooloodkkxo:;:ccllcl:;.
#      .cdoc:oxkOOkkOkxk0kxxdxkdo:.....,dkkxxxdoxxxxxdc;;lddxdddol;.
#       'ld:..:lxdxOOkxkkxxl'okxdc.....'lxkdlcdkOOxk0Ol,.:oddddxdcc.
#        ,:.  .;kOOkkOxxkkx:..,;,.......',,,'ckO0kxO0k:...',oddxocl;..  ........
#            .cxkxolc;:xkkd:................ckkkkxxxdl,....'lddolco:'...........
#            .lololc..ckkxxl'..............cxxddxdddl:'....'ldol:lo:..........
#             .,,;'. .oxxxxd:............,lxdoc;,coo:'.....'ldc;loc,........
#                     .,:::'..   ..  . .'oddol;':ooc;.....,cc:.'ll:'..    ..
#                                       .,;:;,..;c:;'. . 'cl;. .....
#                                                 .      ...
# Glowe.jl - Julia interface to GloVe
#            Written in Julia at 0x0α Research
#			 by Corneliu Cofaru, 2018
#
# Original authors: Jeffrey Pennington, Richard Socher
#					and Christopher D. Manning. 2014

module Glowe

    using LinearAlgebra
    using Statistics
    import Base: show, size

    export vocab_count, cooccur, shuffle, glove,
           WordVectors, wordvectors,
           index, size,
           get_vector,
           vocabulary, in_vocabulary,
           cosine, cosine_similar_words,
           analogy, analogy_words,
           similarity

    include("interface.jl")
    include("wordvectors.jl")

end # module
