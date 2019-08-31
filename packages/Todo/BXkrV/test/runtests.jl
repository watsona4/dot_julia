using Test: @testset, @test, @test_throws
using Dates: year, month, day

@eval Main TRACK_TODOS = true
using Todo


@testset "Todo" begin

@testset "TodoTask" begin
	task = TodoTask("x (A) 2019-05-09 2003-01-23 +PROJ1 this is the description +PROJ2 @context/file.jl:23 tag:a-value tag2:another-value not-tag: @ctx_2 :not-tag +PROJ3")
	@test isComplete(task) === true
	@test priority(task) == 'A'
	@test year(completed(task)) == 2019 && month(completed(task)) == 5 && day(completed(task)) == 9
	@test year(created(task)) == 2003 && month(created(task)) == 1 && day(created(task)) == 23
	@test description(task) == "+PROJ1 this is the description +PROJ2 @context/file.jl:23 tag:a-value tag2:another-value not-tag: @ctx_2 :not-tag +PROJ3"
	@test projects(task) == ["PROJ1", "PROJ2", "PROJ3"]
	@test contexts(task) == ["context/file.jl:23", "ctx_2"]
	@test tags(task) == ["tag" => "a-value", "tag2" => "another-value"]
	
	@test_throws ErrorException TodoTask("x x this is a bad description")
	@test_throws ErrorException TodoTask("(A) (B) this is another bad description")
	@test_throws ErrorException TodoTask("x 2000-01-02 2000-01-01 2000-01-01 this is also a bad description")
	@test_throws ErrorException TodoTask("2000-01-01 2000-01-01 this is not marked complete, but has a completion date")
end


@testset "load_todos/save_todos" begin
	tasks = [
		TodoTask("(A) 2003-01-23 my first task in +PROJ1 @context/file.jl:1 tag1:value1"),
		TodoTask("x (B) 2019-05-13 2003-01-23 my second task in +PROJ2 @/context/file.jl:2 tag2:value2"),
		TodoTask("(Z) my last task in +PROJ1 +PROJ2 @../another/context/file.jl:3 tag3:value3"),
	]
	
	mktempdir() do dir
		todotxt = joinpath(dir, "todo.txt")
		todomd  = joinpath(dir, "todo.md")
		
		save_todos(todotxt, tasks)
		saved = String(read(todotxt))
		@test occursin("(A) 2003-01-23 my first task in +PROJ1 @context/file.jl:1 tag1:value1", saved)
		@test occursin("x (B) 2019-05-13 2003-01-23 my second task in +PROJ2 @/context/file.jl:2 tag2:value2", saved)
		@test occursin("(Z) my last task in +PROJ1 +PROJ2 @../another/context/file.jl:3 tag3:value3", saved)
		
		loadedTasks = load_todos(todotxt)
		@test tasks == loadedTasks
		
		save_todos(todotxt, loadedTasks)
		@test String(read(todotxt)) == saved
		
		save_todos(todomd, tasks, format = :markdown)
		saved = String(read(todomd))
		@test occursin("- [ ] my first task in +PROJ1 @context/file.jl:1 tag1:value1", saved)
		@test occursin("- [x] my second task in +PROJ2 @/context/file.jl:2 tag2:value2", saved)
		@test occursin("- [ ] my last task in +PROJ1 +PROJ2 @../another/context/file.jl:3 tag3:value3", saved)
	end
end


@testset "@todo_str" begin
	before = length(todos())
	@eval Main module TodoTest
		using Todo
		
		todo"provide more module contents"
		todo"""
			provide a
			multi-line
			todo string
			"""
		
		function f()
			todo"implement this function"
			todo"""
				test
				multi-line
				in
				this function
				"""
		end
		
		macro m()
			todo"implement this macro"
			return :(todo"test macro generated code")
		end
		
		@generated function g(x)
			todo"implement this generated function with value"
			return :(todo"test generated function code")
		end
	end
	after = length(todos())
	
	expected = 0
	@testset "module" begin
		expected += 2  # 2 in module
		@test sum(values(todo_hits())) == expected
	end
	
	@testset "+ macro" begin
		@eval Main TodoTest.@m()
		expected += 1+1  # 1 in the macro, 1 in the expansion of the macro
		@test sum(values(todo_hits())) == expected
	end
	
	@testset "+ repeat macro" begin
		@eval Main TodoTest.@m()
		expected += 1+1  # another 1 in the macro and 1 in the macro expansion
		@test sum(values(todo_hits())) == expected
	end
	
	@testset "+ function" begin
		@eval Main TodoTest.f()
		expected += 2  # 2 in the function
		@test sum(values(todo_hits())) == expected
	end
	
	@testset "+ repeat function" begin
		@eval Main TodoTest.f()
		expected += 2  # 2 in the function again
		@test sum(values(todo_hits())) == expected
	end
	
	@testset "+ generated" begin
		@eval Main TodoTest.g(1)
		expected += 1+1  # 1 in generating function, 1 in generated function
		@test sum(values(todo_hits())) == expected
	end
	
	@testset "+ repeat generated" begin
		@eval Main TodoTest.g(1.0)
		expected += 1+1  # another 1 in generating function, 1 in generated function
		@test sum(values(todo_hits())) == expected
	end
	
	
	@testset "todos() + todo_hits()" begin
		@test before == 0
		@test after == 6
		@test length(todos()) == 8
		@test length(todo_hits()) == 8
		
		reset_hits()
		@test length(todos()) == 8
		@test length(todo_hits()) == 0
		@test sum(values(todo_hits())) == 0
	end
end

end
