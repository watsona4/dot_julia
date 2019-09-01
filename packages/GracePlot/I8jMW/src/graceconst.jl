#GracePlot constant literals
#-------------------------------------------------------------------------------


#==Julia Symbol => Grace constants
===============================================================================#

#A constant litteral in grace...
mutable struct GraceConstLitteral
	#Basically just a string, but will not be surrounded with quotes when sent...
	s::String
end

const graceconstmap = Dict{Symbol, GraceConstLitteral}(
	#Booleans:
	:on  => GraceConstLitteral("ON"),
	:off => GraceConstLitteral("OFF"),
	:TRUE  => GraceConstLitteral("TRUE"), #Julia does not like :true/:false
	:FALSE => GraceConstLitteral("FALSE"),

	#Axis scales:
	:lin        => GraceConstLitteral("NORMAL"),
	:log        => GraceConstLitteral("LOGARITHMIC"),
	:reciprocal => GraceConstLitteral("RECIPROCAL"),

	#Common:
	:none       => GraceConstLitteral("0"), #Linestyle, ..

	#Line styles:
	:solid       => GraceConstLitteral("1"),
	:dot         => GraceConstLitteral("2"),
	:dash        => GraceConstLitteral("3"),
	:ldash       => GraceConstLitteral("4"),
	:dotdash     => GraceConstLitteral("5"),
	:dotldash    => GraceConstLitteral("6"),
	:dotdotdash  => GraceConstLitteral("7"),
	:dotdashdash => GraceConstLitteral("8"),

	#Symobls (glyphs):
	:circle    => GraceConstLitteral("1"),
	:o         => GraceConstLitteral("1"),
	:square    => GraceConstLitteral("2"),
	:diamond   => GraceConstLitteral("3"),
	:uarrow    => GraceConstLitteral("4"),
	:larrow    => GraceConstLitteral("5"),
	:darrow    => GraceConstLitteral("6"),
	:rarrow    => GraceConstLitteral("7"),
	:cross     => GraceConstLitteral("8"),
	:+         => GraceConstLitteral("8"),
	:diagcross => GraceConstLitteral("9"),
	:x         => GraceConstLitteral("9"),
	:star      => GraceConstLitteral("10"),
	:*         => GraceConstLitteral("10"),
	:char      => GraceConstLitteral("11"),

	#Location type (relative to what coordinates):
	:world     => GraceConstLitteral("world"),
	:view      => GraceConstLitteral("view"),

	#Text justification
	:centercenter => GraceConstLitteral("14"),
)

#Last line
