using Coverage

# coverage = process_folder(ARGS[1])
coverage = process_folder()

print("Overall coverage: ")
println(get_summary(coverage))

covered_lines, total_lines = get_summary(coverage)

for c in coverage
  print(c.filename * ": ")
  println(get_summary(c))
end
