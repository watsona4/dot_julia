set -e
cat README.template.md.header

jl=myth.jl
echo "doc/myth.jl is an example call from single Module:<br>"
tmp=`cat $jl`
echo "\`\`\`
$tmp
\`\`\`"

echo "then run :"
run=`cat test.sh|grep "$jl"|head -1`
res=`echo $run|sh`
echo "\`\`\`
\$ $run
$res
\`\`\`"



jl=myths.jl
echo "doc/myths.jl is an example call from multiple Module:<br>"
tmp=`cat $jl`
echo "\`\`\`
$tmp
\`\`\`"

echo "then run :"
run=`cat test.sh|grep "$jl"|head -1`
res=`echo $run|sh`
echo "\`\`\`
\$ $run
$res
\`\`\`"


jl=func.jl
echo "doc/func.jl is an example call from single Function:<br>"
tmp=`cat $jl`
echo "\`\`\`
$tmp
\`\`\`"

echo "then run :"
run=`cat test.sh|grep "$jl"|head -1`
res=`echo $run|sh`
echo "\`\`\`
\$ $run
$res
\`\`\`"


jl=funcs.jl
echo "doc/funcs.jl is an example call from multiple Function:<br>"
tmp=`cat $jl`
echo "\`\`\`
$tmp
\`\`\`"

echo "then run :"
run=`cat test.sh|grep "$jl"|head -1`
res=`echo $run|sh`
echo "\`\`\`
\$ $run
$res
\`\`\`"

cat README.template.md.tail
