const EMPTY = 0x0000000000000000
const FULL = 0xffffffffffffffff

const NIGHT_CLEAR_FILES = [0x3f3f3f3f3f3f3f3f, 0x7f7f7f7f7f7f7f7f,
                           0xfefefefefefefefe, 0xfcfcfcfcfcfcfcfc,
                           0xfcfcfcfcfcfcfcfc, 0xfefefefefefefefe,
                           0x7f7f7f7f7f7f7f7f, 0x3f3f3f3f3f3f3f3f]

const NIGHT_JUMPS = [-10, -17, -15, -6, 10, 17, 15, 6]

const FILE_SHIFTS = [56, 48, 40, 32, 24, 16, 8, 0]
const MASK_FILE_A = 0x8080808080808080
const MASK_FILE_B = 0x4040404040404040
const MASK_FILE_C = 0x2020202020202020
const MASK_FILE_D = 0x1010101010101010
const MASK_FILE_E = 0x0808080808080808
const MASK_FILE_F = 0x0404040404040404
const MASK_FILE_G = 0x0202020202020202
const MASK_FILE_H = 0x0101010101010101
const MASK_FILES = [0x8080808080808080,
					0x4040404040404040,
					0x2020202020202020,
					0x1010101010101010,
					0x0808080808080808,
					0x0404040404040404,
					0x0202020202020202,
					0x0101010101010101]

const RANK_SHIFTS = [0, 8, 16, 24, 32, 40, 48, 56]
const MASK_RANK_1 = 0x00000000000000ff
const MASK_RANK_2 = 0x000000000000ff00
const MASK_RANK_3 = 0x0000000000ff0000
const MASK_RANK_4 = 0x00000000ff000000
const MASK_RANK_5 = 0x000000ff00000000
const MASK_RANK_6 = 0x0000ff0000000000
const MASK_RANK_7 = 0x00ff000000000000
const MASK_RANK_8 = 0xff00000000000000
const MASK_RANKS = [0x00000000000000ff,
					0x000000000000ff00,
					0x0000000000ff0000,
					0x00000000ff000000,
					0x000000ff00000000,
					0x0000ff0000000000,
					0x00ff000000000000,
					0xff00000000000000]

const FRAME = MASK_RANK_1 | MASK_RANK_8 | MASK_FILE_A | MASK_FILE_H
const CORNERS = (0x8000000000000000 | 0x0100000000000000 | 
				 0x0000000000000080 | 0x0000000000000001)

const CLEAR_FILE_A = 0x7f7f7f7f7f7f7f7f
const CLEAR_FILE_B = 0xbfbfbfbfbfbfbfbf
const CLEAR_FILE_C = 0xdfdfdfdfdfdfdfdf
const CLEAR_FILE_D = 0xefefefefefefefef
const CLEAR_FILE_E = 0xf7f7f7f7f7f7f7f7
const CLEAR_FILE_F = 0xfbfbfbfbfbfbfbfb
const CLEAR_FILE_G = 0xfdfdfdfdfdfdfdfd
const CLEAR_FILE_H = 0xfefefefefefefefe

const CLEAR_RANK_1 = 0xffffffffffffff00
const CLEAR_RANK_2 = 0xffffffffffff00ff
const CLEAR_RANK_3 = 0xffffffffff00ffff
const CLEAR_RANK_4 = 0xffffffff00ffffff
const CLEAR_RANK_5 = 0xffffff00ffffffff
const CLEAR_RANK_6 = 0xffff00ffffffffff
const CLEAR_RANK_7 = 0xff00ffffffffffff
const CLEAR_RANK_8 = 0x00ffffffffffffff

const KING_SHIFTS = [9, 8, 7, -1, -9, -8, -7, 1]
const KING_CLEAR_FILES = [0x7f7f7f7f7f7f7f7f, 0xffffffffffffffff,
						  0xfefefefefefefefe, 0xfefefefefefefefe,
						  0xfefefefefefefefe, 0xffffffffffffffff,
						  0x7f7f7f7f7f7f7f7f, 0x7f7f7f7f7f7f7f7f]
const KING_MASK_FILES = [0x8080808080808080, 0xffffffffffffffff,
						 0x0101010101010101, 0x0101010101010101,
						 0x0101010101010101, 0xffffffffffffffff,
						 0x8080808080808080, 0x8080808080808080]

const PAWN_SQUARES = 0x00ffffffffffff00

const ANTIDIAGONALS = [0x0102040810204080,
                 	   0x0001020408102040,
                 	   0x0000010204081020,
                 	   0x0000000102040810,
                 	   0x0000000001020408,
                 	   0x0000000000010204,
                 	   0x0000000000000102,
                 	   0x0000000000000001,
                 	   0x0001020408102040<<9,
                 	   0x0000010204081020<<18,
                 	   0x0000000102040810<<27,
                 	   0x0000000001020408<<36,
                 	   0x0000000000010204<<45,
                 	   0x0000000000000102<<54,
                 	   0x0000000000000001<<63]

const DIAGONALS = [0x8040201008040201, 
             	   0x0080402010080402,
             	   0x0000804020100804,
             	   0x0000008040201008,
             	   0x0000000080402010,
             	   0x0000000000804020,
             	   0x0000000000008040,
             	   0x0000000000000080,
             	   0x0080402010080402<<7,
             	   0x0000804020100804<<14,
             	   0x0000008040201008<<21,
             	   0x0000000080402010<<28,
             	   0x0000000000804020<<35,
             	   0x0000000000008040<<42,
             	   0x0000000000000080<<49]
