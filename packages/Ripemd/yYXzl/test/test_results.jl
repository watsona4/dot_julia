using Compat

if VERSION < v"0.7"
    Base.read(x, ::Type{String}) = readstring(x)
end

function openssl_ripemd160(x::AbstractString)
    read(pipeline(`printf $x`, `openssl ripemd160`), String)[10:end - 1]
end

function openssl_ripemd160(x::Array{UInt8, 1})
    read(pipeline(`printf $(String(x))`,
                  `openssl rmd160`),
         String)[10:end - 1]
end

function openssl_ripemd160(x::NTuple{N, UInt8}) where N
    t = String([x...])
    read(pipeline(`printf $t`, `openssl rmd160`), String)[10:end - 1]
end

function vs_openssl(x)
    bytes2hex(Ripemd.ripemd160(x)) == openssl_ripemd160(x)
end

@testset "Ripemd160 vs openssl a's" begin
    for i in 1:1000
        x = [0x61 for j in 1:i]
        @test vs_openssl(x)
    end
    for i in 1:1000
        x = *(["a" for j in 1:i]...,)
        @test vs_openssl(x)
    end
    # This takes a long time, because Julia will compile a different function
    # for each length/loop iterations
    for i in 1:10
        x = ntuple(x -> 0x61, i)
        @test vs_openssl(x)
    end
end

@testset "Ripemd160 vs openssl abc" begin
    d = Ripemd.codeunits("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
    for i in 1:1000
        x = [d[j % length(d) + 1] for j in 1:i]
        @test vs_openssl(x)
    end
    for i in 1:1000
        x = *([Char(d[j % length(d) + 1]) for j in 1:i]...,)
        @test vs_openssl(x)
    end
    # This takes a long time, because Julia will compile a different function
    # for each length/loop iterations
    for i in 1:10
        x = ntuple(j -> d[j % length(d) + 1], i)
        @test vs_openssl(x)
    end
end

@testset "Ripemd160 1M a's" begin

    d1 = [0x61 for i in 1:1_000_000];
    d2 = ntuple((i) -> 0x61, 1_000_000);
    r = "52783243c1697bdbe16d37f97f68f08325dc1528"

    @test bytes2hex(Ripemd.ripemd160(d1)) == r
    @test bytes2hex(Ripemd.ripemd160(d2)) == r
end

@testset "Ripemd160" begin
    @test bytes2hex(Ripemd.ripemd160("asdf")) ==
        "0ef2aed6346def670a8019e4ea42cf4c76018139"
    @test bytes2hex(Ripemd.ripemd160("")) ==
        "9c1185a5c5e9fc54612808977ee8f548b2258d31"
    @test bytes2hex(Ripemd.ripemd160("a")) ==
        "0bdc9d2d256b3ee9daae347be6f4dc835a467ffe"
    @test bytes2hex(Ripemd.ripemd160("abc")) ==
        "8eb208f7e05d987a9b044a8e98c6b087f15a0bfc"
    @test bytes2hex(Ripemd.ripemd160("message digest")) ==
        "5d0689ef49d2fae572b881b123a85ffa21595f36"
    @test bytes2hex(Ripemd.ripemd160("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")) ==
        "b0e20b6e3116640286ed3a87a5713079b21f5189"
    @test bytes2hex(Ripemd.ripemd160("I'd hold you up to say to your mother, 'this kid's gonna be the best kid in the world. This kid's gonna be somebody better than anybody I ever knew.' And you grew up good and wonderful. It was great just watching you, every day was like a privilege. Then the time come for you to be your own man and take on the world, and you did. But somewhere along the line, you changed. You stopped being you. You let people stick a finger in your face and tell you you're no good. And when things got hard, you started looking for something to blame, like a big shadow. Let me tell you something you already know. The world ain't all sunshine and rainbows. It's a very mean and nasty place and I don't care how tough you are it will beat you to your knees and keep you there permanently if you let it. You, me, or nobody is gonna hit as hard as life. But it ain't about how hard ya hit. It's about how hard you can get hit and keep moving forward. How much you can take and keep moving forward. That's how winning is done! Now if you know what you're worth then go out and get what you're worth. But ya gotta be willing to take the hits, and not pointing fingers saying you ain't where you wanna be because of him, or her, or anybody! Cowards do that and that ain't you! You're better than that! I'm always gonna love you no matter what. No matter what happens. You're my son and you're my blood. You're the best thing in my life. But until you start believing in yourself, ya ain't gonna have a life. Don't forget to visit your mother.")) ==
        "fff55c23c197b4fded67e09424e5aef9dafad1c6"
    @test bytes2hex(Ripemd.ripemd160(Ripemd.codeunits("asdf"))) ==
        "0ef2aed6346def670a8019e4ea42cf4c76018139"
    @test bytes2hex(Ripemd.ripemd160(Ripemd.codeunits(""))) ==
        "9c1185a5c5e9fc54612808977ee8f548b2258d31"
    @test bytes2hex(Ripemd.ripemd160(Ripemd.codeunits("a"))) ==
        "0bdc9d2d256b3ee9daae347be6f4dc835a467ffe"
    @test bytes2hex(Ripemd.ripemd160(Ripemd.codeunits("abc"))) ==
        "8eb208f7e05d987a9b044a8e98c6b087f15a0bfc"
    @test bytes2hex(Ripemd.ripemd160(Ripemd.codeunits("message digest"))) ==
        "5d0689ef49d2fae572b881b123a85ffa21595f36"
    @test bytes2hex(Ripemd.ripemd160(Ripemd.codeunits("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"))) ==
        "b0e20b6e3116640286ed3a87a5713079b21f5189"
    @test bytes2hex(Ripemd.ripemd160(Ripemd.codeunits("I'd hold you up to say to your mother, 'this kid's gonna be the best kid in the world. This kid's gonna be somebody better than anybody I ever knew.' And you grew up good and wonderful. It was great just watching you, every day was like a privilege. Then the time come for you to be your own man and take on the world, and you did. But somewhere along the line, you changed. You stopped being you. You let people stick a finger in your face and tell you you're no good. And when things got hard, you started looking for something to blame, like a big shadow. Let me tell you something you already know. The world ain't all sunshine and rainbows. It's a very mean and nasty place and I don't care how tough you are it will beat you to your knees and keep you there permanently if you let it. You, me, or nobody is gonna hit as hard as life. But it ain't about how hard ya hit. It's about how hard you can get hit and keep moving forward. How much you can take and keep moving forward. That's how winning is done! Now if you know what you're worth then go out and get what you're worth. But ya gotta be willing to take the hits, and not pointing fingers saying you ain't where you wanna be because of him, or her, or anybody! Cowards do that and that ain't you! You're better than that! I'm always gonna love you no matter what. No matter what happens. You're my son and you're my blood. You're the best thing in my life. But until you start believing in yourself, ya ain't gonna have a life. Don't forget to visit your mother."))) ==
        "fff55c23c197b4fded67e09424e5aef9dafad1c6"
    @test bytes2hex(Ripemd.ripemd160((Ripemd.codeunits("asdf")...,))) ==
        "0ef2aed6346def670a8019e4ea42cf4c76018139"
    @test bytes2hex(Ripemd.ripemd160((Ripemd.codeunits("")...,))) ==
        "9c1185a5c5e9fc54612808977ee8f548b2258d31"
    @test bytes2hex(Ripemd.ripemd160((Ripemd.codeunits("a")...,))) ==
        "0bdc9d2d256b3ee9daae347be6f4dc835a467ffe"
    @test bytes2hex(Ripemd.ripemd160((Ripemd.codeunits("abc")...,))) ==
        "8eb208f7e05d987a9b044a8e98c6b087f15a0bfc"
    @test bytes2hex(Ripemd.ripemd160((Ripemd.codeunits("message digest")...,))) ==
        "5d0689ef49d2fae572b881b123a85ffa21595f36"
    @test bytes2hex(Ripemd.ripemd160((Ripemd.codeunits("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")...,))) ==
        "b0e20b6e3116640286ed3a87a5713079b21f5189"
    @test bytes2hex(Ripemd.ripemd160((Ripemd.codeunits("I'd hold you up to say to your mother, 'this kid's gonna be the best kid in the world. This kid's gonna be somebody better than anybody I ever knew.' And you grew up good and wonderful. It was great just watching you, every day was like a privilege. Then the time come for you to be your own man and take on the world, and you did. But somewhere along the line, you changed. You stopped being you. You let people stick a finger in your face and tell you you're no good. And when things got hard, you started looking for something to blame, like a big shadow. Let me tell you something you already know. The world ain't all sunshine and rainbows. It's a very mean and nasty place and I don't care how tough you are it will beat you to your knees and keep you there permanently if you let it. You, me, or nobody is gonna hit as hard as life. But it ain't about how hard ya hit. It's about how hard you can get hit and keep moving forward. How much you can take and keep moving forward. That's how winning is done! Now if you know what you're worth then go out and get what you're worth. But ya gotta be willing to take the hits, and not pointing fingers saying you ain't where you wanna be because of him, or her, or anybody! Cowards do that and that ain't you! You're better than that! I'm always gonna love you no matter what. No matter what happens. You're my son and you're my blood. You're the best thing in my life. But until you start believing in yourself, ya ain't gonna have a life. Don't forget to visit your mother.")...,))) ==
        "fff55c23c197b4fded67e09424e5aef9dafad1c6"
end
