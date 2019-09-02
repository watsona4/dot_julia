using MemoryMutate

# runs on my machine: archlinux x86_64

filter_asm(io::IOBuffer) = filter(l -> !startswith(l,";") && !isempty(l) && !startswith(l,"\tnopw") && !startswith(l,"\t.text"), split(String(take!(io)),"\n"))
asm_stat(ss::Array{SubString{String},1}) =
  ( total = length(ss)
  , movs = length(filter(l -> occursin("mov",l),ss))
  , mov  = length(filter(l -> startswith(l,"\tmov"),ss))
  , vmov = length(filter(l -> startswith(l,"\tvmov"),ss))
  )
display_asm_stat_io(io::IOBuffer) = display(asm_stat(filter_asm(io)))
io = IOBuffer()
structinfo(T) = [(fieldoffset(T,i), fieldname(T,i), fieldtype(T,i)) for i = 1:fieldcount(T)];

#= we have
- Julep: setfield! for mutable references to immutables
  https://github.com/JuliaLang/julia/issues/17115
  - "we propose making it possible to have setfield! modify fields inside of immutable objects that are wrapped in mutable objects"
  - "To support this proposal, the setfield! function will get a multi-arg form, with the following behaviors:"
    "setfield!(x, a, b, c, value) mutates the right most mutable object to change the value of its fields to be"
    "equivalent to copying the immutable objects and updating the referenced field."
  - "tl;dr The syntax:"
    "x.a.b.c = 3"
    "would now be valid, as long as at least one of the referenced fields is mutable."
- WIP: Make mutating immutables easier
  https://github.com/JuliaLang/julia/pull/21912
  - proposes an @ operator as in `x@a = 2` for an immutable `x`
  - "The ways this works is that under the hood, it creates a new immutable object with the specified field modified and then assigns it back to the appropriate place."
    "Syntax wise, everything to the left of the @ is what's being assigned to, everything to the right of the @ is what is to be modified."
- Make immutable mutable again - or make arrays of structures stack-allocated
  https://discourse.julialang.org/t/make-immutable-mutable-again-or-make-arrays-of-structures-stack-allocated/20800
  - colleced a few related links
=#

################################################################################

        struct G1; x :: Float32;          end # struct G2 { const float x; };
        struct F1; x :: Float32; g :: G1; end # struct F2 { const float x; const G2 g; };
        struct E1; x :: Float32; f :: F1; end # struct E2 { const float x; const F2 g; };
        struct D1; x :: Float32; e :: E1; end # struct D2 { const float x; const E2 g; };
        struct C1; x :: Float32; d :: D1; end # struct C2 { const float x; const D2 g; };
        struct B1; x :: Float32; c :: C1; end # struct B2 { const float x; const C2 g; };
mutable struct A1; x :: Float32; b :: B1; end # struct A2 {       float x;       B2 g; };

g1 = G1(0.0f0)
f1 = F1(0.0f0,g1)
e1 = E1(0.0f0,f1)
d1 = D1(0.0f0,e1)
c1 = C1(0.0f0,d1)
b1 = B1(0.0f0,c1)
a1 = A1(0.0f0,b1)

test101(a::A1,v::Float32) = @mem a.b.c.d.e.f.g.x = v
test102(a::A1,v::G1)      = @mem a.b.c.d.e.f.g = v
test103(a::A1,v::Float32) = @mem a.b.c.d.e.f.x = v
test104(a::A1,v::F1)      = @mem a.b.c.d.e.f = v
test105(a::A1,v::Float32) = @mem a.b.c.d.e.x = v
test106(a::A1,v::E1)      = @mem a.b.c.d.e = v
test107(a::A1,v::Float32) = @mem a.b.c.d.x = v
test108(a::A1,v::D1)      = @mem a.b.c.d = v
test109(a::A1,v::Float32) = @mem a.b.c.x = v
test110(a::A1,v::C1)      = @mem a.b.c = v
test111(a::A1,v::Float32) = @mem a.b.x = v
test112(a::A1,v::B1)      = @mem a.b = v
test113(a::A1,v::Float32) = @mem a.x = v
test114(a::A1,v::A1)      = @mem a = v

v  = 0f0
v += 1f0; @assert a1.b.c.d.e.f.g.x != v;        test101(a1,v);        @assert a1.b.c.d.e.f.g.x == v
v += 1f0; @assert a1.b.c.d.e.f.g   != G1(v);    test102(a1,G1(v));    @assert a1.b.c.d.e.f.g   == G1(v)
v += 1f0; @assert a1.b.c.d.e.f.x   != v;        test103(a1,v);        @assert a1.b.c.d.e.f.x   == v
v += 1f0; @assert a1.b.c.d.e.f     != F1(v,g1); test104(a1,F1(v,g1)); @assert a1.b.c.d.e.f     == F1(v,g1)
v += 1f0; @assert a1.b.c.d.e.x     != v;        test105(a1,v);        @assert a1.b.c.d.e.x     == v
v += 1f0; @assert a1.b.c.d.e       != E1(v,f1); test106(a1,E1(v,f1)); @assert a1.b.c.d.e       == E1(v,f1)
v += 1f0; @assert a1.b.c.d.x       != v;        test107(a1,v);        @assert a1.b.c.d.x       == v
v += 1f0; @assert a1.b.c.d         != D1(v,e1); test108(a1,D1(v,e1)); @assert a1.b.c.d         == D1(v,e1)
v += 1f0; @assert a1.b.c.x         != v;        test109(a1,v);        @assert a1.b.c.x         == v
v += 1f0; @assert a1.b.c           != C1(v,d1); test110(a1,C1(v,d1)); @assert a1.b.c           == C1(v,d1)
v += 1f0; @assert a1.b.x           != v;        test111(a1,v);        @assert a1.b.x           == v
v += 1f0; @assert a1.b             != B1(v,c1); test112(a1,B1(v,c1)); @assert a1.b             == B1(v,c1)
v += 1f0; @assert a1.x             != v;        test113(a1,v);        @assert a1.x             == v
v += 1f0; @assert a1               != A1(v,b1); test114(a1,A1(v,b1)); # @assert a1               == A1(v,b1) # call by "sharing"

code_native(io,test101,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test102,(A1,G1))     ; display_asm_stat_io(io) # (total = 4, movs = 3, mov = 2, vmov = 1)
code_native(io,test103,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test104,(A1,F1))     ; display_asm_stat_io(io) # (total = 5, movs = 4, mov = 2, vmov = 2)
code_native(io,test105,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test106,(A1,E1))     ; display_asm_stat_io(io) # (total = 11, movs = 9, mov = 9, vmov = 0)
code_native(io,test107,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test108,(A1,D1))     ; display_asm_stat_io(io) # (total = 6, movs = 5, mov = 1, vmov = 4)
code_native(io,test109,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test110,(A1,C1))     ; display_asm_stat_io(io) # (total = 10, movs = 9, mov = 5, vmov = 4)
code_native(io,test111,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test112,(A1,B1))     ; display_asm_stat_io(io) # (total = 10, movs = 9, mov = 5, vmov = 4)
code_native(io,test113,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test114,(A1,A1))     ; display_asm_stat_io(io) # (total = 3, movs = 2, mov = 2, vmov = 0)

################################################################################

a1 = A1(0.0f0,b1)

test101b(a::A1,v::Float32) = @mem getfield(a.b.c,:d).e.f.g.x = v
test102b(a::A1,v::G1)      = @mem getfield(a.b.c,:d).e.f.g = v
test103b(a::A1,v::Float32) = @mem getfield(a.b.c,:d).e.f.x = v
test104b(a::A1,v::F1)      = @mem getfield(a.b.c,:d).e.f = v
test105b(a::A1,v::Float32) = @mem getfield(a.b.c,:d).e.x = v
test106b(a::A1,v::E1)      = @mem getfield(a.b.c,:d).e = v
test107b(a::A1,v::Float32) = @mem getfield(a.b.c,:d).x = v
test108b(a::A1,v::D1)      = @mem getfield(a.b.c,:d) = v
test109b(a::A1,v::Float32) = @mem a.b.c.x = v
test110b(a::A1,v::C1)      = @mem a.b.c = v
test111b(a::A1,v::Float32) = @mem a.b.x = v
test112b(a::A1,v::B1)      = @mem a.b = v
test113b(a::A1,v::Float32) = @mem a.x = v
test114b(a::A1,v::A1)      = @mem a = v

v  = 0f0
v += 1f0; @assert a1.b.c.d.e.f.g.x != v;        test101b(a1,v);        @assert a1.b.c.d.e.f.g.x == v
v += 1f0; @assert a1.b.c.d.e.f.g   != G1(v);    test102b(a1,G1(v));    @assert a1.b.c.d.e.f.g   == G1(v)
v += 1f0; @assert a1.b.c.d.e.f.x   != v;        test103b(a1,v);        @assert a1.b.c.d.e.f.x   == v
v += 1f0; @assert a1.b.c.d.e.f     != F1(v,g1); test104b(a1,F1(v,g1)); @assert a1.b.c.d.e.f     == F1(v,g1)
v += 1f0; @assert a1.b.c.d.e.x     != v;        test105b(a1,v);        @assert a1.b.c.d.e.x     == v
v += 1f0; @assert a1.b.c.d.e       != E1(v,f1); test106b(a1,E1(v,f1)); @assert a1.b.c.d.e       == E1(v,f1)
v += 1f0; @assert a1.b.c.d.x       != v;        test107b(a1,v);        @assert a1.b.c.d.x       == v
v += 1f0; @assert a1.b.c.d         != D1(v,e1); test108b(a1,D1(v,e1)); @assert a1.b.c.d         == D1(v,e1)
v += 1f0; @assert a1.b.c.x         != v;        test109b(a1,v);        @assert a1.b.c.x         == v
v += 1f0; @assert a1.b.c           != C1(v,d1); test110b(a1,C1(v,d1)); @assert a1.b.c           == C1(v,d1)
v += 1f0; @assert a1.b.x           != v;        test111b(a1,v);        @assert a1.b.x           == v
v += 1f0; @assert a1.b             != B1(v,c1); test112b(a1,B1(v,c1)); @assert a1.b             == B1(v,c1)
v += 1f0; @assert a1.x             != v;        test113b(a1,v);        @assert a1.x             == v
v += 1f0; @assert a1               != A1(v,b1); test114b(a1,A1(v,b1)); # @assert a1               == A1(v,b1) # call by "sharing"

code_native(io,test101b,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test102b,(A1,G1))     ; display_asm_stat_io(io) # (total = 4, movs = 3, mov = 2, vmov = 1)
code_native(io,test103b,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test104b,(A1,F1))     ; display_asm_stat_io(io) # (total = 5, movs = 4, mov = 2, vmov = 2)
code_native(io,test105b,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test106b,(A1,E1))     ; display_asm_stat_io(io) # (total = 11, movs = 9, mov = 9, vmov = 0)
code_native(io,test107b,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test108b,(A1,D1))     ; display_asm_stat_io(io) # (total = 6, movs = 5, mov = 1, vmov = 4)
code_native(io,test109b,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test110b,(A1,C1))     ; display_asm_stat_io(io) # (total = 10, movs = 9, mov = 5, vmov = 4)
code_native(io,test111b,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test112b,(A1,B1))     ; display_asm_stat_io(io) # (total = 10, movs = 9, mov = 5, vmov = 4)
code_native(io,test113b,(A1,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test114b,(A1,A1))     ; display_asm_stat_io(io) # (total = 3, movs = 2, mov = 2, vmov = 0)

################################################################################

        struct G2; x :: Float32;          end # struct G2 { const float x; };
        struct F2; x :: Float32; g :: G2; end # struct F2 { const float x; const G2  g; };
        struct E2; x :: Float32; f :: F2; end # struct E2 { const float x; const F2  g; };
mutable struct D2; x :: Float32; e :: E2; end # struct D2 {       float x;       E2  g; };
        struct C2; x :: Float32; d :: D2; end # struct C2 { const float x; const D2& g; };
        struct B2; x :: Float32; c :: C2; end # struct B2 { const float x; const C2& g; };
mutable struct A2; x :: Float32; b :: B2; end # struct A2 {       float x;       B2& g; };

g2 = G2(6.0f0)
f2 = F2(5.0f0,g2)
e2 = E2(4.0f0,f2)
d2 = D2(3.0f0,e2)
c2 = C2(2.0f0,d2)
b2 = B2(1.0f0,c2)
a2 = A2(0.0f0,b2)

test201(a::A2,v::Float32) = @mem  a.b.c.d.e.f.g.x = v
test202(a::A2,v::G2)      = @mem  a.b.c.d.e.f.g = v
test203(a::A2,v::Float32) = @mem  a.b.c.d.e.f.x = v
test204(a::A2,v::F2)      = @mem  a.b.c.d.e.f = v
test205(a::A2,v::Float32) = @mem  a.b.c.d.e.x = v
test206(a::A2,v::E2)      = @mem  a.b.c.d.e = v
test207(a::A2,v::Float32) = @mem  a.b.c.d.x = v
test208(a::A2,v::D2)      = @yolo a.b.c.d = v
test209(a::A2,v::Float32) = @yolo a.b.c.x = v
test210(a::A2,v::C2)      = @yolo a.b.c = v
test211(a::A2,v::Float32) = @yolo a.b.x = v
test212(a::A2,v::B2)      = @mem  a.b = v
test213(a::A2,v::Float32) = @mem  a.x = v
test214(a::A2,v::A2)      = @mem  a = v

            v  = 0f0
            v += 1f0; @assert a2.b.c.d.e.f.g.x != v;        test201(a2,v);        @assert a2.b.c.d.e.f.g.x == v
            v += 1f0; @assert a2.b.c.d.e.f.g   != G2(v);    test202(a2,G2(v));    @assert a2.b.c.d.e.f.g   == G2(v)
            v += 1f0; @assert a2.b.c.d.e.f.x   != v;        test203(a2,v);        @assert a2.b.c.d.e.f.x   == v
            v += 1f0; @assert a2.b.c.d.e.f     != F2(v,g2); test204(a2,F2(v,g2)); @assert a2.b.c.d.e.f     == F2(v,g2)
            v += 1f0; @assert a2.b.c.d.e.x     != v;        test205(a2,v);        @assert a2.b.c.d.e.x     == v
            v += 1f0; @assert a2.b.c.d.e       != E2(v,f2); test206(a2,E2(v,f2)); @assert a2.b.c.d.e       == E2(v,f2)
            v += 1f0; @assert a2.b.c.d.x       != v;        test207(a2,v);        @assert a2.b.c.d.x       == v
try; global v += 1f0; @assert a2.b.c.d         != D2(v,e2); test208(a2,D2(v,e2)); @assert a2.b.c.d.x       == D2(v,e2).x # mutables with equal field values are not equal
                                                                                  @assert a2.b.c.d.e       == D2(v,e2).e; catch e; print(e); end
try; global v += 1f0; @assert a2.b.c.x         != v;        test209(a2,v);        @assert a2.b.c.x         == v         ; catch e; print(e); end
try; global v += 1f0; @assert a2.b.c           != C2(v,d2); test210(a2,C2(v,d2)); @assert a2.b.c           == C2(v,d2)  ; catch e; print(e); end
try; global v += 1f0; @assert a2.b.x           != v;        test211(a2,v);        @assert a2.b.x           == v         ; catch e; print(e); end
            v += 1f0; @assert a2.b             != B2(v,c2); test212(a2,B2(v,c2)); @assert a2.b             == B2(v,c2)
            v += 1f0; @assert a2.x             != v;        test213(a2,v);        @assert a2.x             == v
            v += 1f0; @assert a2               != A2(v,b2); test214(a2,A2(v,b2)); # @assert a1               == A2(v,b2) # call by "sharing"

code_native(io,test201,(A2,Float32)); display_asm_stat_io(io) # (total = 5, movs = 4, mov = 3, vmov = 1)
code_native(io,test202,(A2,G2))     ; display_asm_stat_io(io) # (total = 7, movs = 6, mov = 5, vmov = 1)
code_native(io,test203,(A2,Float32)); display_asm_stat_io(io) # (total = 5, movs = 4, mov = 3, vmov = 1)
code_native(io,test204,(A2,F2))     ; display_asm_stat_io(io) # (total = 9, movs = 7, mov = 5, vmov = 2)
code_native(io,test205,(A2,Float32)); display_asm_stat_io(io) # (total = 5, movs = 4, mov = 3, vmov = 1)
code_native(io,test206,(A2,E2))     ; display_asm_stat_io(io) # (total = 14, movs = 12, mov = 12, vmov = 0)
code_native(io,test207,(A2,Float32)); display_asm_stat_io(io) # (total = 5, movs = 4, mov = 3, vmov = 1)
code_native(io,test208,(A2,D2))     ; display_asm_stat_io(io) # (total = 7, movs = 6, mov = 6, vmov = 0)
code_native(io,test209,(A2,Float32)); display_asm_stat_io(io) # (total = 28, movs = 18, mov = 15, vmov = 3)
code_native(io,test210,(A2,C2))     ; display_asm_stat_io(io) # (total = 18, movs = 15, mov = 14, vmov = 1)
code_native(io,test211,(A2,Float32)); display_asm_stat_io(io) # (total = 26, movs = 17, mov = 14, vmov = 3)
code_native(io,test212,(A2,B2))     ; display_asm_stat_io(io) # (total = 24, movs = 8, mov = 8, vmov = 0)
code_native(io,test213,(A2,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test214,(A2,A2))     ; display_asm_stat_io(io) # (total = 3, movs = 2, mov = 2, vmov = 0)

################################################################################

        struct G3; x :: Float32;          end # struct G3 { const float x; };
        struct F3; x :: Float32; g :: G3; end # struct F3 { const float x; const G3 g; };
        struct E3; x :: Float32; f :: F3; end # struct E3 { const float x; const F3 g; };
        struct D3; x :: Float32; e :: E3; end # struct D3 { const float x; const E3 g; };
        struct C3; x :: Float32; d :: D3; end # struct C3 { const float x; const D3 g; };
        struct B3; x :: Float32; c :: C3; end # struct B3 { const float x; const C3 g; };
        struct A3; x :: Float32; b :: B3; end # struct A3 { const float x; const B3 g; };

g3 = G3(6.0f0)
f3 = F3(5.0f0,g3)
e3 = E3(4.0f0,f3)
d3 = D3(3.0f0,e3)
c3 = C3(2.0f0,d3)
b3 = B3(1.0f0,c3)
a3 = A3(0.0f0,b3)

test301(a::Base.RefValue{A3},v::Float32) = @mem a[].b.c.d.e.f.g.x = v
test302(a::Base.RefValue{A3},v::G3)      = @mem a[].b.c.d.e.f.g = v
test303(a::Base.RefValue{A3},v::Float32) = @mem a[].b.c.d.e.f.x = v
test304(a::Base.RefValue{A3},v::F3)      = @mem a[].b.c.d.e.f = v
test305(a::Base.RefValue{A3},v::Float32) = @mem a[].b.c.d.e.x = v
test306(a::Base.RefValue{A3},v::E3)      = @mem a[].b.c.d.e = v
test307(a::Base.RefValue{A3},v::Float32) = @mem a[].b.c.d.x = v
test308(a::Base.RefValue{A3},v::D3)      = @mem a[].b.c.d = v
test309(a::Base.RefValue{A3},v::Float32) = @mem a[].b.c.x = v
test310(a::Base.RefValue{A3},v::C3)      = @mem a[].b.c = v
test311(a::Base.RefValue{A3},v::Float32) = @mem a[].b.x = v
test312(a::Base.RefValue{A3},v::B3)      = @mem a[].b = v
test313(a::Base.RefValue{A3},v::Float32) = @mem a[].x = v
test314(a::Base.RefValue{A3},v::A3)      = @mem a[] = v

a3r = Ref(a3)

v = 0f0
v += 1f0; @assert a3r[].b.c.d.e.f.g.x != v;        test301(a3r,v);        @assert a3r[].b.c.d.e.f.g.x == v
v += 1f0; @assert a3r[].b.c.d.e.f.g   != G3(v);    test302(a3r,G3(v));    @assert a3r[].b.c.d.e.f.g   == G3(v)
v += 1f0; @assert a3r[].b.c.d.e.f.x   != v;        test303(a3r,v);        @assert a3r[].b.c.d.e.f.x   == v
v += 1f0; @assert a3r[].b.c.d.e.f     != F3(v,g3); test304(a3r,F3(v,g3)); @assert a3r[].b.c.d.e.f     == F3(v,g3)
v += 1f0; @assert a3r[].b.c.d.e.x     != v;        test305(a3r,v);        @assert a3r[].b.c.d.e.x     == v
v += 1f0; @assert a3r[].b.c.d.e       != E3(v,f3); test306(a3r,E3(v,f3)); @assert a3r[].b.c.d.e       == E3(v,f3)
v += 1f0; @assert a3r[].b.c.d.x       != v;        test307(a3r,v);        @assert a3r[].b.c.d.x       == v
v += 1f0; @assert a3r[].b.c.d         != D3(v,e3); test308(a3r,D3(v,e3)); @assert a3r[].b.c.d         == D3(v,e3)
v += 1f0; @assert a3r[].b.c.x         != v;        test309(a3r,v);        @assert a3r[].b.c.x         == v
v += 1f0; @assert a3r[].b.c           != C3(v,d3); test310(a3r,C3(v,d3)); @assert a3r[].b.c           == C3(v,d3)
v += 1f0; @assert a3r[].b.x           != v;        test311(a3r,v);        @assert a3r[].b.x           == v
v += 1f0; @assert a3r[].b             != B3(v,c3); test312(a3r,B3(v,c3)); @assert a3r[].b             == B3(v,c3)
v += 1f0; @assert a3r[].x             != v;        test313(a3r,v);        @assert a3r[].x             == v
v += 1f0; @assert a3r[]               != A3(v,b3); test314(a3r,A3(v,b3)); @assert a3r[]               == A3(v,b3)

code_native(io,test301,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test302,(Base.RefValue{A3},G3))     ; display_asm_stat_io(io) # (total = 4, movs = 3, mov = 2, vmov = 1)
code_native(io,test303,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test304,(Base.RefValue{A3},F3))     ; display_asm_stat_io(io) # (total = 5, movs = 4, mov = 2, vmov = 2)
code_native(io,test305,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test306,(Base.RefValue{A3},E3))     ; display_asm_stat_io(io) # (total = 11, movs = 9, mov = 9, vmov = 0)
code_native(io,test307,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test308,(Base.RefValue{A3},D3))     ; display_asm_stat_io(io) # (total = 6, movs = 5, mov = 1, vmov = 4)
code_native(io,test309,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test310,(Base.RefValue{A3},C3))     ; display_asm_stat_io(io) # (total = 10, movs = 9, mov = 5, vmov = 4)
code_native(io,test311,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test312,(Base.RefValue{A3},B3))     ; display_asm_stat_io(io) # (total = 10, movs = 9, mov = 5, vmov = 4)
code_native(io,test313,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test314,(Base.RefValue{A3},A3))     ; display_asm_stat_io(io) # (total = 11, movs = 9, mov = 1, vmov = 8)

################################################################################

test301b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::Float32) = @mem a[][][].b.c.d.e.f.g.x = v
test302b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::G3)      = @mem a[][][].b.c.d.e.f.g = v
test303b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::Float32) = @mem a[][][].b.c.d.e.f.x = v
test304b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::F3)      = @mem a[][][].b.c.d.e.f = v
test305b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::Float32) = @mem a[][][].b.c.d.e.x = v
test306b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::E3)      = @mem a[][][].b.c.d.e = v
test307b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::Float32) = @mem a[][][].b.c.d.x = v
test308b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::D3)      = @mem a[][][].b.c.d = v
test309b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::Float32) = @mem a[][][].b.c.x = v
test310b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::C3)      = @mem a[][][].b.c = v
test311b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::Float32) = @mem a[][][].b.x = v
test312b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::B3)      = @mem a[][][].b = v
test313b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::Float32) = @mem a[][][].x = v
test314b(a::Base.RefValue{Base.RefValue{Base.RefValue{A3}}},v::A3)      = @mem a[][][] = v

a3rrr = Ref(Ref(Ref(a3)))

# @assert false

 v = 0f0
v += 1f0; @assert a3rrr[][][].b.c.d.e.f.g.x != v;        test301b(a3rrr,v);        @assert a3rrr[][][].b.c.d.e.f.g.x == v
v += 1f0; @assert a3rrr[][][].b.c.d.e.f.g   != G3(v);    test302b(a3rrr,G3(v));    @assert a3rrr[][][].b.c.d.e.f.g   == G3(v)
v += 1f0; @assert a3rrr[][][].b.c.d.e.f.x   != v;        test303b(a3rrr,v);        @assert a3rrr[][][].b.c.d.e.f.x   == v
v += 1f0; @assert a3rrr[][][].b.c.d.e.f     != F3(v,g3); test304b(a3rrr,F3(v,g3)); @assert a3rrr[][][].b.c.d.e.f     == F3(v,g3)
v += 1f0; @assert a3rrr[][][].b.c.d.e.x     != v;        test305b(a3rrr,v);        @assert a3rrr[][][].b.c.d.e.x     == v
v += 1f0; @assert a3rrr[][][].b.c.d.e       != E3(v,f3); test306b(a3rrr,E3(v,f3)); @assert a3rrr[][][].b.c.d.e       == E3(v,f3)
v += 1f0; @assert a3rrr[][][].b.c.d.x       != v;        test307b(a3rrr,v);        @assert a3rrr[][][].b.c.d.x       == v
v += 1f0; @assert a3rrr[][][].b.c.d         != D3(v,e3); test308b(a3rrr,D3(v,e3)); @assert a3rrr[][][].b.c.d         == D3(v,e3)
v += 1f0; @assert a3rrr[][][].b.c.x         != v;        test309b(a3rrr,v);        @assert a3rrr[][][].b.c.x         == v
v += 1f0; @assert a3rrr[][][].b.c           != C3(v,d3); test310b(a3rrr,C3(v,d3)); @assert a3rrr[][][].b.c           == C3(v,d3)
v += 1f0; @assert a3rrr[][][].b.x           != v;        test311b(a3rrr,v);        @assert a3rrr[][][].b.x           == v
v += 1f0; @assert a3rrr[][][].b             != B3(v,c3); test312b(a3rrr,B3(v,c3)); @assert a3rrr[][][].b             == B3(v,c3)
v += 1f0; @assert a3rrr[][][].x             != v;        test313b(a3rrr,v);        @assert a3rrr[][][].x             == v
v += 1f0; @assert a3rrr[][][]               != A3(v,b3); test314b(a3rrr,A3(v,b3)); @assert a3rrr[][][]               == A3(v,b3)

code_native(io,test301,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test302,(Base.RefValue{A3},G3))     ; display_asm_stat_io(io) # (total = 4, movs = 3, mov = 2, vmov = 1)
code_native(io,test303,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test304,(Base.RefValue{A3},F3))     ; display_asm_stat_io(io) # (total = 5, movs = 4, mov = 2, vmov = 2)
code_native(io,test305,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test306,(Base.RefValue{A3},E3))     ; display_asm_stat_io(io) # (total = 11, movs = 9, mov = 9, vmov = 0)
code_native(io,test307,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test308,(Base.RefValue{A3},D3))     ; display_asm_stat_io(io) # (total = 6, movs = 5, mov = 1, vmov = 4)
code_native(io,test309,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test310,(Base.RefValue{A3},C3))     ; display_asm_stat_io(io) # (total = 10, movs = 9, mov = 5, vmov = 4)
code_native(io,test311,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test312,(Base.RefValue{A3},B3))     ; display_asm_stat_io(io) # (total = 10, movs = 9, mov = 5, vmov = 4)
code_native(io,test313,(Base.RefValue{A3},Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test314,(Base.RefValue{A3},A3))     ; display_asm_stat_io(io) # (total = 11, movs = 9, mov = 1, vmov = 8)

################################################################################

        struct G4; x :: Float32;                         end # struct G4 { const float x; };
        struct F4; x :: Float32; g :: G4;                end # struct F4 { const float x; const G4  g; };
        struct E4; x :: Float32; f :: F4;                end # struct E4 { const float x; const F4  g; };
        struct D4; x :: Float32; e :: Base.RefValue{E4}; end # struct D4 { const float x; const E4& g; };
        struct C4; x :: Float32; d :: D4;                end # struct C4 { const float x; const D4& g; };
        struct B4; x :: Float32; c :: C4;                end # struct B4 { const float x; const C4& g; };
mutable struct A4; x :: Float32; b :: B4;                end # struct A4 {       float x;       B4& g; };

g4 = G4(0.0f0)
f4 = F4(0.0f0,g4)
e4 = E4(0.0f0,f4)
d4 = D4(0.0f0,Ref(e4))
c4 = C4(0.0f0,d4)
b4 = B4(0.0f0,c4)
a4 = A4(0.0f0,b4)

test401(a::A4,v::Float32) = @mem  a.b.c.d.e[].f.g.x = v
test402(a::A4,v::G4)      = @mem  a.b.c.d.e[].f.g = v
test403(a::A4,v::Float32) = @mem  a.b.c.d.e[].f.x = v
test404(a::A4,v::F4)      = @mem  a.b.c.d.e[].f = v
test405(a::A4,v::Float32) = @mem  a.b.c.d.e[].x = v
test406(a::A4,v::E4)      = @mem  a.b.c.d.e[] = v
test407(a::A4,v::Float32) = @yolo a.b.c.d.x = v
test408(a::A4,v::D4)      = @yolo a.b.c.d = v
test409(a::A4,v::Float32) = @yolo a.b.c.x = v
test410(a::A4,v::C4)      = @yolo a.b.c = v
test411(a::A4,v::Float32) = @yolo a.b.x = v
test412(a::A4,v::B4)      = @mem  a.b = v
test413(a::A4,v::Float32) = @mem  a.x = v
test414(a::A4,v::A4)      = @mem  a = v

            v  = 0f0
            v += 1f0; @assert a4.b.c.d.e[].f.g.x != v;             test401(a4,v);             @assert a4.b.c.d.e[].f.g.x == v
            v += 1f0; @assert a4.b.c.d.e[].f.g   != G4(v);         test402(a4,G4(v));         @assert a4.b.c.d.e[].f.g   == G4(v)
            v += 1f0; @assert a4.b.c.d.e[].f.x   != v;             test403(a4,v);             @assert a4.b.c.d.e[].f.x   == v
            v += 1f0; @assert a4.b.c.d.e[].f     != F4(v,g4);      test404(a4,F4(v,g4));      @assert a4.b.c.d.e[].f     == F4(v,g4)
            v += 1f0; @assert a4.b.c.d.e[].x     != v;             test405(a4,v);             @assert a4.b.c.d.e[].x     == v
            v += 1f0; @assert a4.b.c.d.e[]       != E4(v,f4);      test406(a4,E4(v,f4));      @assert a4.b.c.d.e[]       == E4(v,f4)
try; global v += 1f0; @assert a4.b.c.d.x         != v;             test407(a4,v);             @assert a4.b.c.d.x         == v            ; catch e; print(e); end
try; global v += 1f0; @assert a4.b.c.d           != D4(v,Ref(e4)); test408(a4,D4(v,Ref(e4))); @assert a4.b.c.d.e[]       == e4           # references to equal immutables are not equal
                                                                                              @assert a4.b.c.d.x         == v            ; catch e; print(e); end
try; global v += 1f0; @assert a4.b.c.x           != v;             test409(a4,v);             @assert a4.b.c.x           == v            ; catch e; print(e); end
try; global v += 1f0; @assert a4.b.c             != C4(v,d4);      test410(a4,C4(v,d4));      @assert a4.b.c             == C4(v,d4)     ; catch e; print(e); end
try; global v += 1f0; @assert a4.b.x             != v;             test411(a4,v);             @assert a4.b.x             == v            ; catch e; print(e); end
            v += 1f0; @assert a4.b               != B4(v,c4);      test412(a4,B4(v,c4));      @assert a4.b               == B4(v,c4)
            v += 1f0; @assert a4.x               != v;             test413(a4,v);             @assert a4.x               == v
            v += 1f0; @assert a4                 != A4(v,b4);      test414(a4,A4(v,b4));      # @assert a4               == A4(v,b4) # call by "sharing"

code_native(io,test401,(A4,Float32)); display_asm_stat_io(io) # (total = 6, movs = 5, mov = 4, vmov = 1)
code_native(io,test402,(A4,G4))     ; display_asm_stat_io(io) # (total = 8, movs = 7, mov = 6, vmov = 1)
code_native(io,test403,(A4,Float32)); display_asm_stat_io(io) # (total = 6, movs = 5, mov = 4, vmov = 1)
code_native(io,test404,(A4,F4))     ; display_asm_stat_io(io) # (total = 9, movs = 8, mov = 6, vmov = 2)
code_native(io,test405,(A4,Float32)); display_asm_stat_io(io) # (total = 6, movs = 5, mov = 4, vmov = 1)
code_native(io,test406,(A4,E4))     ; display_asm_stat_io(io) # (total = 15, movs = 13, mov = 13, vmov = 0)
code_native(io,test407,(A4,Float32)); display_asm_stat_io(io) # (total = 29, movs = 19, mov = 16, vmov = 3)
code_native(io,test408,(A4,D4))     ; display_asm_stat_io(io) # (total = 19, movs = 16, mov = 15, vmov = 1)
code_native(io,test409,(A4,Float32)); display_asm_stat_io(io) # (total = 28, movs = 18, mov = 15, vmov = 3)
code_native(io,test410,(A4,C4))     ; display_asm_stat_io(io) # (total = 18, movs = 15, mov = 14, vmov = 1)
code_native(io,test411,(A4,Float32)); display_asm_stat_io(io) # (total = 26, movs = 17, mov = 14, vmov = 3)
code_native(io,test412,(A4,B4))     ; display_asm_stat_io(io) # (total = 24, movs = 8, mov = 8, vmov = 0)
code_native(io,test413,(A4,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test414,(A4,A4))     ; display_asm_stat_io(io) # (total = 3, movs = 2, mov = 2, vmov = 0)

################################################################################

g4 = G4(0.0f0)
f4 = F4(0.0f0,g4)
e4 = E4(0.0f0,f4)
d4 = D4(0.0f0,Ref(e4))
c4 = C4(0.0f0,d4)
b4 = B4(0.0f0,c4)
a4 = A4(0.0f0,b4)

test401b(a::A4,v::Float32) = @mem  a.b.c.d.e.x.f.g.x = v
test402b(a::A4,v::G4)      = @mem  a.b.c.d.e.x.f.g = v
test403b(a::A4,v::Float32) = @mem  a.b.c.d.e.x.f.x = v
test404b(a::A4,v::F4)      = @mem  a.b.c.d.e.x.f = v
test405b(a::A4,v::Float32) = @mem  a.b.c.d.e.x.x = v
test406b(a::A4,v::E4)      = @mem  a.b.c.d.e.x = v
test407b(a::A4,v::Float32) = @yolo a.b.c.d.x = v
test408b(a::A4,v::D4)      = @yolo a.b.c.d = v
test409b(a::A4,v::Float32) = @yolo a.b.c.x = v
test410b(a::A4,v::C4)      = @yolo a.b.c = v
test411b(a::A4,v::Float32) = @yolo a.b.x = v
test412b(a::A4,v::B4)      = @mem  a.b = v
test413b(a::A4,v::Float32) = @mem  a.x = v
test414b(a::A4,v::A4)      = @mem  a = v

            v  = 0f0
            v += 1f0; @assert a4.b.c.d.e.x.f.g.x != v;             test401b(a4,v);             @assert a4.b.c.d.e.x.f.g.x == v
            v += 1f0; @assert a4.b.c.d.e.x.f.g   != G4(v);         test402b(a4,G4(v));         @assert a4.b.c.d.e.x.f.g   == G4(v)
            v += 1f0; @assert a4.b.c.d.e.x.f.x   != v;             test403b(a4,v);             @assert a4.b.c.d.e.x.f.x   == v
            v += 1f0; @assert a4.b.c.d.e.x.f     != F4(v,g4);      test404b(a4,F4(v,g4));      @assert a4.b.c.d.e.x.f     == F4(v,g4)
            v += 1f0; @assert a4.b.c.d.e.x.x     != v;             test405b(a4,v);             @assert a4.b.c.d.e.x.x     == v
            v += 1f0; @assert a4.b.c.d.e.x       != E4(v,f4);      test406b(a4,E4(v,f4));      @assert a4.b.c.d.e.x       == E4(v,f4)
try; global v += 1f0; @assert a4.b.c.d.x         != v;             test407b(a4,v);             @assert a4.b.c.d.x         == v            ;  catch e; print(e); end
try; global v += 1f0; @assert a4.b.c.d           != D4(v,Ref(e4)); test408b(a4,D4(v,Ref(e4))); @assert a4.b.c.d.e[]       == e4           # references to equal immutables are not equal
                                                                                               @assert a4.b.c.d.x         == v            ;  catch e; print(e); end
try; global v += 1f0; @assert a4.b.c.x           != v;             test409b(a4,v);             @assert a4.b.c.x           == v            ;  catch e; print(e); end
try; global v += 1f0; @assert a4.b.c             != C4(v,d4);      test410b(a4,C4(v,d4));      @assert a4.b.c             == C4(v,d4)     ;  catch e; print(e); end
try; global v += 1f0; @assert a4.b.x             != v;             test411b(a4,v);             @assert a4.b.x             == v            ;  catch e; print(e); end
            v += 1f0; @assert a4.b               != B4(v,c4);      test412b(a4,B4(v,c4));      @assert a4.b               == B4(v,c4)
            v += 1f0; @assert a4.x               != v;             test413b(a4,v);             @assert a4.x               == v
            v += 1f0; @assert a4                 != A4(v,b4);      test414b(a4,A4(v,b4));      # @assert a4               == A4(v,b4) # call by "sharing"

code_native(io,test401b,(A4,Float32)); display_asm_stat_io(io) # (total = 6, movs = 5, mov = 4, vmov = 1)
code_native(io,test402b,(A4,G4))     ; display_asm_stat_io(io) # (total = 8, movs = 7, mov = 6, vmov = 1)
code_native(io,test403b,(A4,Float32)); display_asm_stat_io(io) # (total = 6, movs = 5, mov = 4, vmov = 1)
code_native(io,test404b,(A4,F4))     ; display_asm_stat_io(io) # (total = 9, movs = 8, mov = 6, vmov = 2)
code_native(io,test405b,(A4,Float32)); display_asm_stat_io(io) # (total = 6, movs = 5, mov = 4, vmov = 1)
code_native(io,test406b,(A4,E4))     ; display_asm_stat_io(io) # (total = 15, movs = 13, mov = 13, vmov = 0)
code_native(io,test407b,(A4,Float32)); display_asm_stat_io(io) # (total = 29, movs = 19, mov = 16, vmov = 3)
code_native(io,test408b,(A4,D4))     ; display_asm_stat_io(io) # (total = 19, movs = 16, mov = 15, vmov = 1)
code_native(io,test409b,(A4,Float32)); display_asm_stat_io(io) # (total = 28, movs = 18, mov = 15, vmov = 3)
code_native(io,test410b,(A4,C4))     ; display_asm_stat_io(io) # (total = 18, movs = 15, mov = 14, vmov = 1)
code_native(io,test411b,(A4,Float32)); display_asm_stat_io(io) # (total = 26, movs = 17, mov = 14, vmov = 3)
code_native(io,test412b,(A4,B4))     ; display_asm_stat_io(io) # (total = 24, movs = 8, mov = 8, vmov = 0)
code_native(io,test413b,(A4,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test414b,(A4,A4))     ; display_asm_stat_io(io) # (total = 3, movs = 2, mov = 2, vmov = 0)

################################################################################

# template for the next try, currently the same as for case 4

#         struct G5; x :: Float32;                         end # struct G5 { const float x; };
#         struct F5; x :: Float32; g :: G5;                end # struct F5 { const float x; const G5  g; };
#         struct E5; x :: Float32; f :: F5;                end # struct E5 { const float x; const F5  g; };
# mutable struct D5; x :: Float32; e :: Base.RefValue{E5}; end # struct D5 {       float x;       E5& g; };
#         struct C5; x :: Float32; d :: D5;                end # struct C5 { const float x; const D5& g; };
#         struct B5; x :: Float32; c :: C5;                end # struct B5 { const float x; const C5& g; };
# mutable struct A5; x :: Float32; b :: B5;                end # struct A5 {       float x;       B5& g; };
#
# g5 = G5(0.0f0)
# f5 = F5(0.0f0,g5)
# e5 = E5(0.0f0,f5)
# d5 = D5(0.0f0,Ref(e5))
# c5 = C5(0.0f0,d5)
# b5 = B5(0.0f0,c5)
# a5 = A5(0.0f0,b5)
#
# test501(a::A5,v::Float32) = @mem a.b.c.d.e[].f.g.x = v
# test502(a::A5,v::G5)      = @mem a.b.c.d.e[].f.g = v
# test503(a::A5,v::Float32) = @mem a.b.c.d.e[].f.x = v
# test504(a::A5,v::F5)      = @mem a.b.c.d.e[].f = v
# test505(a::A5,v::Float32) = @mem a.b.c.d.e[].x = v
# test506(a::A5,v::E5)      = @mem a.b.c.d.e[] = v
# test507(a::A5,v::Float32) = @mem a.b.c.d.x = v
# test508(a::A5,v::D5)      = @mem a.b.c.d = v
# test509(a::A5,v::Float32) = @mem a.b.c.x = v
# test510(a::A5,v::C5)      = @mem a.b.c = v
# test511(a::A5,v::Float32) = @mem a.b.x = v
# test512(a::A5,v::B5)      = @mem a.b = v
# test513(a::A5,v::Float32) = @mem a.x = v
# test514(a::A5,v::A5)      = @mem a = v
#
#             v  = 0f0
#             v += 1f0; @assert a5.b.c.d.e[].f.g.x != v;             test501(a5,v);             @assert a5.b.c.d.e[].f.g.x == v
#             v += 1f0; @assert a5.b.c.d.e[].f.g   != G5(v);         test502(a5,G5(v));         @assert a5.b.c.d.e[].f.g   == G5(v)
#             v += 1f0; @assert a5.b.c.d.e[].f.x   != v;             test503(a5,v);             @assert a5.b.c.d.e[].f.x   == v
#             v += 1f0; @assert a5.b.c.d.e[].f     != F5(v,g5);      test504(a5,F5(v,g5));      @assert a5.b.c.d.e[].f     == F5(v,g5)
#             v += 1f0; @assert a5.b.c.d.e[].x     != v;             test505(a5,v);             @assert a5.b.c.d.e[].x     == v
#             v += 1f0; @assert a5.b.c.d.e[]       != E5(v,f5);      test506(a5,E5(v,f5));      @assert a5.b.c.d.e[]       == E5(v,f5)
#             v += 1f0; @assert a5.b.c.d.x         != v;             test507(a5,v);             @assert a5.b.c.d.x         == v
# try; global v += 1f0; @assert a5.b.c.d           != D5(v,Ref(e5)); test508(a5,D5(v,Ref(e5))); @assert a5.b.c.d           == D5(v,Ref(e5)); catch e; print(e); end
# try; global v += 1f0; @assert a5.b.c.x           != v;             test509(a5,v);             @assert a5.b.c.x           == v            ; catch e; print(e); end
# try; global v += 1f0; @assert a5.b.c             != C5(v,d5);      test510(a5,C5(v,d5));      @assert a5.b.c             == C5(v,d5)     ; catch e; print(e); end
# try; global v += 1f0; @assert a5.b.x             != v;             test511(a5,v);             @assert a5.b.x             == v            ; catch e; print(e); end
#             v += 1f0; @assert a5.b               != B5(v,c5);      test512(a5,B5(v,c5));      @assert a5.b               == B5(v,c5)
#             v += 1f0; @assert a5.x               != v;             test513(a5,v);             @assert a5.x               == v
#             v += 1f0; @assert a5                 != A5(v,b5);      test514(a5,A5(v,b5));      # @assert a5               == A5(v,b5) # call by "sharing"
#
# code_native(io,test501,(A5,Float32)); display_asm_stat_io(io) # (total = 6, movs = 5, mov = 5, vmov = 1)
# code_native(io,test502,(A5,G5))     ; display_asm_stat_io(io) # (total = 8, movs = 7, mov = 6, vmov = 1)
# code_native(io,test503,(A5,Float32)); display_asm_stat_io(io) # (total = 6, movs = 5, mov = 5, vmov = 1)
# code_native(io,test504,(A5,F5))     ; display_asm_stat_io(io) # (total = 9, movs = 8, mov = 6, vmov = 2)
# code_native(io,test505,(A5,Float32)); display_asm_stat_io(io) # (total = 6, movs = 5, mov = 5, vmov = 1)
# code_native(io,test506,(A5,E5))     ; display_asm_stat_io(io) # (total = 15, movs = 13, mov = 13, vmov = 0)
# # code_native(io,test507,(A5,Float32)); display_asm_stat_io(io)
# # code_native(io,test508,(A5,D5))     ; display_asm_stat_io(io)
# # code_native(io,test509,(A5,Float32)); display_asm_stat_io(io)
# # code_native(io,test510,(A5,C5))     ; display_asm_stat_io(io)
# code_native(io,test511,(A5,Float32)); display_asm_stat_io(io) # (total = 25, movs = 16, mov = 13, vmov = 3)
# code_native(io,test512,(A5,B5))     ; display_asm_stat_io(io) # (total = 25, movs = 8, mov = 8, vmov = 0)
# code_native(io,test513,(A5,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
# code_native(io,test514,(A5,A5))     ; display_asm_stat_io(io) # (total = 3, movs = 2, mov = 2, vmov = 0)

################################################################################

# @macroexpand @mem a.b.c.d.e.f.g.x = v
# a,v = (a1,v)
#
# @macroexpand @mem a.b.c.d = v
# a,v = (a2,D2(v,e2))
#
# @macroexpand @mem a.b.c.d.e.f.g.x = v
# a,v = (a2,v)
#
# @macroexpand @mem a[].b.c.d.e.f.g.x = v
# a,v = (a3r,v)
#
# @macroexpand @mem a[] = v
# a,v = (a3r,A3(v,b3))
#
# @macroexpand @mem a.b = v
# a,v = (a2,B2(v,c2))
#
# @macroexpand @mem a[][][].b.c.d.e.f.g.x = v
# a,v = (a3rrr,v)
#
# @macroexpand @mem a.b.c.d.e[].f.g.x = v
# a,v = (a4,v)
#
# @macroexpand @mem a.b.c.d = v
# a,v = (a2,D2(v,e2))
#
# @macroexpand @mem a.b.c.d = v
# a,v = (a4,D4(v,Ref(e4)))
#
# @macroexpand @mem a[].b.c.d.e.f.g.x = v
# a,v = (a3r,v)

using StaticArrays

m = SArray{Tuple{4,3,2},Int64,3,4*3*2}(1:4*3*2)
r = Ref(m)

@assert r[][1,1,2] == 13
@mem r[][1,1,2] = 77
@assert r[][1,1,2] == 77
@assert r[][1,1,2] == unsafe_load(@ptr r[][1,1,2])

m = Ref(SVector{8,UInt8}(reverse([0xde, 0xad, 0xbe, 0xef, 0xba, 0xad, 0xf0, 0x0d])))
unsafe_load(@ptr m[][8]) # 0xde
unsafe_load(@ptr m[][7]) # 0xad
unsafe_load(@typedptr UInt32 m[][3]) # 0xbeefbaad

@assert pointer_from_objref(r) == @voidptr r[][1,1,1]
@voidptr r[][1,1,1]
@ptr r[][1,1,2]

const B6 = SArray{Tuple{4,3,2},Float32,3,4*3*2}
const A6 = Base.RefValue{B6}
a = Ref(B6(1:4*3*2))

test601(a :: A6, v :: Float32) = @mem a[][1,1,2] = v

v = 77f0
@assert a[][1,1,2] != v; test601(a,v); @assert a[][1,1,2] == v;

code_native(io,test601,(A6,Float32)); display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)

const B6b = SArray{Tuple{4,3,2},Float32,3,4*3*2}
mutable struct A6b
   b :: B6b
end

b = B6b(1:4*3*2)
a = A6b(b)

test601b(a :: A6b, v :: Float32) = @mem a.b[1,1,2] = v
test602b(a :: A6b, x :: Int64, y :: Int64, z :: Int64,  v :: Float32) = @mem a.b[x,y,z] = v

v = 77f0
x, y, z = 2, 1, 2
@assert a.b[1,1,2] != v; test601b(a,v); @assert a.b[1,1,2] == v;
@assert a.b[x,y,z] != v; test602b(a,x,y,z,v); @assert a.b[x,y,z] == v;

code_native(io,test601b,(A6b,Float32));                   display_asm_stat_io(io) # (total = 2, movs = 1, mov = 0, vmov = 1)
code_native(io,test602b,(A6b,Int64,Int64,Int64,Float32)); display_asm_stat_io(io) # (total = 5, movs = 1, mov = 0, vmov = 1)
# leaq    (%rcx,%rcx,2), %rax
# leaq    (%rsi,%rdx,4), %rcx
# leaq    (%rcx,%rax,4), %rax
# vmovss  %xmm0, -68(%rdi,%rax,4)
