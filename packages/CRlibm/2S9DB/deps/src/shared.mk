shared: *.o
	gcc -L. -shared -o libcrlibm.$(SUFFIX) *.o scs_lib/*.o
