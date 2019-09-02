# Tests for entity-based learning
function t_entity_networklearner()

#########################################
# Test the entity-based NetworkLearner  #
#########################################
N= 100							# Number of entitites 
inferences = [:ic, :rl, :gs, :unknown]			# Collective inferences
rlearners = [:rn, :wrn, :bayesrn, :unknown]		# Relational learners
nAdj = 2						# Number of adjacencies to generate	
X = rand(1,N); 						# Training data

nlmodel=[]



#####################
# Column-major case #
#####################

# Initializations           
ft=x->vec(x)
Xo = rand(1,N)
update = trues(N)

# Train and test methods for relational model
fr_train=(x)->sum(x[1], dims=2);
fr_exec=(m,x)->sum(x.-m, dims=1)

amv = sparse.(Symmetric.([sprand(Float64, N,N, 0.5) for i in 1:nAdj]));
adv = adjacency.(amv); 

for infopt in inferences
	for rlopt in rlearners  
		Test.@test try
			# Train NetworkLearner
			nlmodel=fit(NetworkLearnerEnt, Xo, update, 
			       adv, fr_train,fr_exec;
			       learner=rlopt, 
			       inference=infopt,
			       f_targets=ft,
			       normalize=false, maxiter = 5
			)
			
			# Make modifications of adjacencies, estimates
			# ...

			# Re-run inference
			infer!(nlmodel)
			true
		catch
			false
		end
	end
end



##################
# Row-major case #
##################

# Initializations           
ft=x->vec(x)
Xo = rand(N,1)
update = trues(N)

# Train and test methods for relational model
fr_train=(x)->sum(x[1], dims=1);
fr_exec=(m,x)->sum(x.-m, dims=2)

amv = sparse.(Symmetric.([sprand(Float64, N,N, 0.5) for i in 1:nAdj]));
adv = adjacency.(amv); 

for infopt in inferences
	for rlopt in rlearners  
		Test.@test try
			# Train NetworkLearner
			nlmodel=fit(NetworkLearnerEnt, Xo, update, 
			       adv, fr_train,fr_exec;
			       learner=rlopt, 
			       inference=infopt,
			       f_targets=ft,
			       normalize=false, maxiter = 5,
			       obsdim=1
			)
			
			# Make modifications of adjacencies, estimates
			# ...

			# Re-run inference
			infer!(nlmodel)
			true
		catch
			false
		end
	end
end

# Test show methods
buf = IOBuffer()
Test.@test try
	show(buf,nlmodel)
	true
catch
	false
end

Test.@test try
	show(buf,NetworkLearning.NetworkLearnerState(rand(2,2), trues(2), ObsDim.Constant{2}()))
	true
catch
	false
end


end
