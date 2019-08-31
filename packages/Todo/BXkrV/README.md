# Todo.jl

Todo task management and tracking in Julia using the [todo.txt format](https://github.com/todotxt/todo.txt).

# Usage

This package introduces a framework for placing "todo" text within Julia code.
You can do so by using the `@todo_str` string macro literally anywhere you wish.
The text content of the todo should be what is defined in the [todo.txt format](https://github.com/todotxt/todo.txt).

Defined in a file and `include(...)`-ed in the REPL:
```jl
module ExampleUsage
using Todo

todo"implement some functionality"      # a simple todo
todo"2019-05-13 add tests"              # with a creation date
todo"(A) 2019-05-13 add documentation"  # with the highest priority and a creation date
todo"(Z) notify some friends"           # with the lowest priority
todo"x (A) 2019-05-14 2019-05-13 "      # with the lowest priority
todo"include a tag:value any:where"     # with tags "tag" => "value" and "any" => "where"
todo"and projects +Project1 +Project2"  # with projects "Project1" and "Project2"
todo"and contexts @here @there"         # with contexts "here" and "there"

iscornercase(i) = (todo"add checks for corner cases" ; false)

function f()
	todo"support another use-case"
	
	for i in 1:10
		iscornercase(i) && todo"handle special corner case"
	end
end

end
```

You might be thinking, "So what? That's no different than using a comment!"
Well, this is where the additional functionality of Todo.jl comes in handy.
When running from the REPL (or when `isinteractive() == true`) Todo.jl keeps track of the number of times each todo task is hit.
This information can help you prioritize your package's todos based on how often the todo is encountered under your desired workload.

```jl
julia> using Todo

julia> ExampleUsage.f()

julia> todo_hits()
Dict{TodoTask,Int64} with 10 entries:
  TodoTask(...) => 1
  TodoTask(...) => 1
  TodoTask(...) => 10
  ...
  TodoTask(...) => 1

julia> reset_hits()

julia> ExampleUsage.f()

julia> todo_hits()
Dict{TodoTask,Int64} with 2 entries:
  TodoTask(...) => 10
  TodoTask(...) => 1
```

When not running from the REPL (`isinteractive() == false`), the package does not keep track of the hit counts for each todo task.
This behavior allows for the complete removal of any runtime impact that the todo tracking might incur.
The package can be manually forced to track or not track todos by defining `@eval Main TRACK_TODOS = true|false` before the package is first imported.

Todo.jl includes the ability to load and save a .txt file according to the todo.txt format.
It can also save a markdown file which could be used for the TODO section of your package!

```jl
julia> save_todos("todo.txt", todos())

julia> tasks = load_todos("todo.txt")
11-element Array{TodoTask,1}:
  TodoTask(...)
  TodoTask(...)
  ...
  TodoTask(...)

julia> save_todos("todo.md", tasks, format = :markdown)
```

