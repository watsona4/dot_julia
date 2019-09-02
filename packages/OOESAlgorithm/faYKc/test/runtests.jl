using JuMP
model = Model()
@variable(model, x[1:10], Bin)
@variable(model, 0 <=y[11:20] <= 1e10)
@objective(model, Min, sum(x[j] for j=1:10) + sum(y[k] for k=11:20))
@constraint(model, 3x[2] + 3x[6] - x[7] + 12x[10] + 17y[11] <= 80)
@constraint(model, -x[2] + 2x[7] - x[1] + 14x[3] + 15x[4] + 4x[8] + 15x[9] + 8y[12] <= 92)
@constraint(model, 6x[7] + x[10] + 6x[1] + 8x[4] - x[8] + 12x[5] + 12y[13] <= 92)
@constraint(model, 20y[14] <= 81)
@constraint(model, 19x[7] + 14x[4] - y[15] <= 99)
@constraint(model, 9x[2] + 19x[10] + 10x[9] + 15y[16] <= 93)
@constraint(model, 7x[2] + 18x[6] + 2x[7] + 12x[1] + 4x[9] + 8x[5] + 19y[17] <= 77)
@constraint(model, 3x[7] + 4x[1] + 3x[3] + 14y[18] <= 52)
@constraint(model, 17x[4] + 6y[19] <= 89)
@constraint(model, 17x[2] + 3x[7] + 6x[3] + 9x[9] + 3y[20] <= 65)
@constraint(model, x[7] + 4x[10] + 7x[1] - x[9] <= 62)
@constraint(model, 3x[2] + 7x[10] + 18x[1] + 7x[3] + 20x[5] <= 81)
@constraint(model, 9x[2] + 2x[6] + 2x[7] + 6x[1] + x[8] + 8x[9] <= 95)
@constraint(model, 2x[10] + 3x[4] + 19x[5] <= 65)
@constraint(model, 4x[6] + 10x[4] + 7x[9] <= 66)
@constraint(model, 10x[2] + 4x[10] + 7x[1] + x[5] <= 82)
@constraint(model, 6x[6] + 8x[7] + 7x[10] + 7x[1] + 4x[3] + 9x[8] + 3x[9] <= 79)
@constraint(model, 9x[2] + 11x[7] + 2x[1] + 15x[3] - x[8] <= 70)
@constraint(model, 2x[7] + 13x[1] + 9x[9] <= 84)
@constraint(model, y[11] + y[12] + y[13] + y[14] + y[15] + y[16] + y[17] + y[18] + y[19] + y[20] <= 3.333333333)
@constraint(model, 26x[2]+50x[6]-74x[7]-20x[10]+81y[11]+14x[1]-88x[3]-42x[4]+74x[8]-54x[9]-56y[12]+42x[5]+82y[13]+68y[14]-54y[15]-25y[16]-16y[17]+100y[18]-55y[19]-13y[20]==0)
@constraint(model, 5x[2]-x[6]+8x[7]+8x[10]-127y[11]+8x[1]-8x[3]-3x[4]+7x[8]+5x[9]-73y[12]-2x[5]-128y[13]+146y[14]+167y[15]+131y[16]-132y[17]-73y[18]+132y[19]-33y[20]==0)
@constraint(model, 9x[2]+7x[6]-7x[7]+9x[10]-167y[11]-8x[1]+2x[3]-5x[4]+5x[8]+8x[9]+16y[12]+5x[5]+136y[13]+98y[14]+29y[15]+48y[16]-80y[17]+60y[18]-99y[19]+141y[20]== 0)
using OOESAlgorithm, Distributed
if length(procs())-1 == 0
  try
    Solution1 = OOES(model)
    Solution2 = OOES("c20instance.lp")
    Solution3 = OOES("c20instance.mps")
    println("Solution test 1: ", Solution1.obj_vals)
    println("Solution test 2: ", Solution2.obj_vals)
    println("Solution test 3: ", Solution3.obj_vals)
    println("Test successful")
  catch
    println("Installation error")
  end
else
  try
    Solution1 = OOES(model, threads=length(procs())-1)
    Solution2 = OOES("c20instance.lp", threads=length(procs())-1)
    Solution3 = OOES("c20instance.mps", threads=length(procs())-1)
    println("Solution test 1: ", Solution1.obj_vals)
    println("Solution test 2: ", Solution2.obj_vals)
    println("Solution test 3: ", Solution3.obj_vals)
    println("Test successful")
  catch
    println("Installation error")
  end
end  
