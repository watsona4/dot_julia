# Only works for little endian architectures (TODO: is there julia for big endian?)
function transform!(ctx::T) where T

    @inbounds begin
        buf = Ptr{UInt32}(pointer(ctx.buffer))

        # TODO: the bitcoin implementation alternates left and right lane, is
        # this faster?

        # left lane
        a, b, c, d, e = ctx.state

        @L( 1); @L( 2); @L( 3); @L( 4); @L( 5); @L( 6); @L( 7); @L( 8); @L( 9); @L(10);
        @L(11); @L(12); @L(13); @L(14); @L(15); @L(16); @L(17); @L(18); @L(19); @L(20);
        @L(21); @L(22); @L(23); @L(24); @L(25); @L(26); @L(27); @L(28); @L(29); @L(30);
        @L(31); @L(32); @L(33); @L(34); @L(35); @L(36); @L(37); @L(38); @L(39); @L(40);
        @L(41); @L(42); @L(43); @L(44); @L(45); @L(46); @L(47); @L(48); @L(49); @L(50);
        @L(51); @L(52); @L(53); @L(54); @L(55); @L(56); @L(57); @L(58); @L(59); @L(60);
        @L(61); @L(62); @L(63); @L(64); @L(65); @L(66); @L(67); @L(68); @L(69); @L(70);
        @L(71); @L(72); @L(73); @L(74); @L(75); @L(76); @L(77); @L(78); @L(79); @L(80);

        aa = a
        bb = b
        cc = c
        dd = d
        ee = e

        # right lane
        a, b, c, d, e = ctx.state

        @R( 1); @R( 2); @R( 3); @R( 4); @R( 5); @R( 6); @R( 7); @R( 8); @R( 9); @R(10);
        @R(11); @R(12); @R(13); @R(14); @R(15); @R(16); @R(17); @R(18); @R(19); @R(20);
        @R(21); @R(22); @R(23); @R(24); @R(25); @R(26); @R(27); @R(28); @R(29); @R(30);
        @R(31); @R(32); @R(33); @R(34); @R(35); @R(36); @R(37); @R(38); @R(39); @R(40);
        @R(41); @R(42); @R(43); @R(44); @R(45); @R(46); @R(47); @R(48); @R(49); @R(50);
        @R(51); @R(52); @R(53); @R(54); @R(55); @R(56); @R(57); @R(58); @R(59); @R(60);
        @R(61); @R(62); @R(63); @R(64); @R(65); @R(66); @R(67); @R(68); @R(69); @R(70);
        @R(71); @R(72); @R(73); @R(74); @R(75); @R(76); @R(77); @R(78); @R(79); @R(80);

        s1 = ctx.state[1]
        ctx.state[1] = ctx.state[2] + d + cc
        ctx.state[2] = ctx.state[3] + e + dd
        ctx.state[3] = ctx.state[4] + a + ee
        ctx.state[4] = ctx.state[5] + b + aa
        ctx.state[5] = s1           + c + bb

    end
    return nothing

end
