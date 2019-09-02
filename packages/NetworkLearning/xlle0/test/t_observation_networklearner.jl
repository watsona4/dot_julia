# Tests for observation-based learning
function t_observation_networklearner()

#############################################
# Test the observation-based NetworkLearner #
#############################################
Ntrain = 100						# Number of training observations
Ntest = 10						# Number of testing observations					
inferences = [:ic, :rl, :gs, :unknown]			# Collective inferences
rlearners = [:rn, :wrn, :bayesrn, :cdrn, :unknown]	# Relational learners
nAdj = 2						# Number of adjacencies to generate	

nlmodel=[]



#####################
# Column-major case #
#####################

# Initializations     
X = rand(1,Ntrain); 					# Training data
ft=x->vec(x)
y = vec(sin.(X)); 
Xo = zeros(1,Ntest)

# Train and test methods for local model 
fl_train = (x)->mean(x[1]); 
fl_exec=(m,x)->x.-m;

# Train and test methods for relational model
fr_train=(x)->sum(x[1], dims=2);
fr_exec=(m,x)->sum(x.-m, dims=1)
amv = sparse.(Symmetric.([sprand(Float64, Ntrain,Ntrain, 0.5) for i in 1:nAdj]));
adv = adjacency.(amv); 

for infopt in inferences
	for rlopt in rlearners  
		Test.@test try
			# Train NetworkLearner
			nlmodel=fit(NetworkLearnerObs, X, y, 
				   adv, fl_train, fl_exec,fr_train,fr_exec;
				   learner=rlopt, 
				   inference=infopt,
				   use_local_data=rand(Bool),
				   f_targets=ft,
				   normalize=false, maxiter = 5
			)

			# Test NetworkLearner
			Xtest = rand(1,Ntest)

			# Add adjacency
			amv_t = sparse.(Symmetric.([sprand(Float64, Ntest,Ntest, 0.7) for i in 1:nAdj]));
			adv_t = adjacency.(amv_t); 
			add_adjacency!(nlmodel, adv_t)
			
			#Run NetworkLearner
			predict!(Xo, nlmodel, Xtest); # in-place
			predict(nlmodel, Xtest);      # creates output matrix	
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
X = rand(Ntrain,1); 					# Training data
ft=x->vec(x)
y = vec(sin.(X)); 
Xo = zeros(Ntest,1)

# Train and test methods for local model 
fl_train = (x)->mean(x[1]); 
fl_exec=(m,x)->x.-m;

# Train and test methods for relational model
fr_train=(x)->sum(x[1], dims=1);
fr_exec=(m,x)->sum(x.-m, dims=2)
amv = sparse.(Symmetric.([sprand(Float64, Ntrain,Ntrain, 0.5) for i in 1:nAdj]));
adv = adjacency.(amv); 

for infopt in inferences
	for rlopt in rlearners  
		Test.@test try
			# Train NetworkLearner
			nlmodel=fit(NetworkLearnerObs, X, y, 
				   adv, fl_train, fl_exec,fr_train,fr_exec;
				   learner=rlopt, 
				   inference=infopt,
				   use_local_data=rand(Bool),
				   f_targets=ft,
				   normalize=false, maxiter = 5,
				   obsdim=1
			)

			# Test NetworkLearner
			Xtest = rand(Ntest,1)

			# Add adjacency
			amv_t = sparse.(Symmetric.([sprand(Float64, Ntest,Ntest, 0.7) for i in 1:nAdj]));
			adv_t = adjacency.(amv_t); 
			add_adjacency!(nlmodel, adv_t)
			
			#Run NetworkLearner
			predict!(Xo, nlmodel, Xtest); # in-place
			predict(nlmodel, Xtest);      # creates output matrix	
			true
		catch
			false
		end
	end
end




buf = IOBuffer()
Test.@test try
	show(buf,nlmodel)
	true
catch
	false
end

end
