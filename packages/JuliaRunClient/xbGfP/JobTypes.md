## Types of Jobs

### `JuliaBatch`
A Julia Batch Job.

Runs in a single allocation/container restricted to the specified amount of
CPUs and memory. The Julia process started in the batch job is allowed to
start other worker processes or threads, all within the specified limits.
The upper bound of CPUs/memory is determined by the largest cluster node.

Scenarios:
- non-parallel
- multi-threaded parallelism
- multi-process shared memory parallelism

Required parameters:
- name: name of the job (must be unique in the system, can be random)
- start_script: a Julia script to start the master node with
- run_volume: a persistent volume to use as the master volume

Optional parameters:
- pkg_bundle: a package bundle to set at LOAD_PATH (none by default)
- additional_volumes: more persistent volumes to attach at /mnt/<volume name> (none by default)
- ports: network ports to expose as a Dict{String,Tuple{Int,Int}} of name to container port and service port map (default: nothing)
- external: whether network ports should be exposed to external network (default: false)
- image: the docker image to run (default: julia)
- cpu: CPU share to allocate (default: 0.1 of a core)
- gpu: GPUs to allocate (default: 0)
- memory: RAM to allocate (default: 512 MiB)
- shell: the script to use for startup shell (default: master.sh)

### JuliaParBatch
A Julia Master-Slave Parallel Batch Job.

A designated master process and an array of worker processes, each of which 
runs in a separate allocation/container. All worker processes have a uniform
resource allocation. The master process can have a different allocation.

The job as a whole can use all available CPU/memory in a cluster (within
practical limitations imposed networking and such). The upper bound for each
master/worker process is determined by the largest node in the cluster.

The master and worker processes are initialized for Julia parallel constructs.
The number of workers can be checked and manipulated with the `scale`/`scale!`
APIs. The number of worker processes actually running depends on the available
cluster resources and may be different from the requested scale. The job is 
deemed running when the master process starts, and JuliaRun attempts to match
number of worker processes to the requested scale continuously. The master
process may check the number of actual workers with the `nworkers` API and
wait for a minimum number of workers if needed by it.

Scenario:
- multi-process distributed memory parallelism

Required parameters:
- name: name of the job (must be unique in the system, can be random)
- start_script: a Julia script to start the master node with
- run_volume: a persistent volume to use as the master volume

Optional parameters:
- pkg_bundle: a package bundle to set at LOAD_PATH (none by default)
- additional_volumes: more persistent volumes to attach at /mnt/<volume name> (none by default)
- ports: network ports to expose from the master process as a Dict{String,Tuple{Int,Int}} of name to container port and service port map (default: nothing)
- external: whether network ports should be exposed to external network (default: false)
- image: the docker image to run (default: julia)
- cpu: CPU share to allocate to master process (default: 0.1 of a core)
- gpu: GPUs to allocate (default: 0)
- memory: RAM to allocate to master process (default: 512 MiB)
- shell: the script to use for master shell (default: master.sh)
- nworkers: number of worker processes to start (0 by default, can be scaled later)
- worker_cpu: CPU share to allocate to a worker process (default: 0.1 of a core)
- worker_gpu: GPUs to allocate to a worker process(default: 0)
- worker_memory: RAM to allocate to a worker process (default: 512 MiB)
- worker_shell: the script to use for a worker shell (default: master.sh)
- worker_start_script: a Julia script to start the worker node with (default: worker.sh)
- restart: should workers be restarted (RestartAlways by default, can also be RestartOnFailure or Never)

### JuliaParBatchWorkers
A Julia Embarrassingly Parallel Batch Job.

An array of batch jobs that can be scaled as a single unit. Each unit in the job array
can be likened to a JuliaBatch job. Since there is no interlinking between the units,
this can be scaled faster and to much higher levels.

As a whole, the job can use all available CPU/memory in the cluster, but the upper bound
for each worker process is determined by the largest node in the cluster.

Scenarios:
- work queues
- distributed memory parallelism

Required parameters:
- name: name of the job (must be unique in the system, can be random)
- start_script: a Julia script to start each node with
- run_volume: a persistent volume to use as the work volume

Optional parameters:
- pkg_bundle: a package bundle to set at LOAD_PATH (none by default)
- additional_volumes: more persistent volumes to attach at /mnt/<volume name> (none by default)
- ports: network ports to expose as a Dict{String,Tuple{Int,Int}} of name to container port and service port map (default: nothing)
- external: whether network ports should be exposed to external network (default: false)
- image: the docker image to run (default: julia)
- cpu: CPU share to allocate to each process (default: 0.1 of a core)
- gpu: GPUs to allocate to each process (default: 0)
- memory: RAM to allocate to each process (default: 512 MiB)
- shell: the script to use for process shell (default: worker.sh)
- nworkers: number of worker processes to start (0 by default, can be scaled later)
- restart: should workers be restarted (RestartAlways by default, can also be RestartOnFailure or Never)

### Notebook
A Julia Interactive Notebook.

The notebook is accessible outside the cluster and can be protected by a password (or an external portal/proxy).
The master container runs the Jupyter notebook process and the Julia kernels.

The Julia process running as the kernel is similar to a JuliaBatch.
Workers can be provisioned (optionally) as:
- slaves to a master Julia process (a Jupyter kernel), similar to JuliaParBatch
- a job array, similar to JuliaParBatchWorkers

Scenarios:
- interactive/exploratory tasks
- shell access (through Jupyter shell)
- file transfer (through Jupyter file manager)

Required parameters:
- name: name of the job (must be unique in the system, can be random)
- run_volume: a persistent volume to use as the master volume

Optional parameters:
- pkg_bundle: a package bundle to set at LOAD_PATH (none by default)
- additional_volumes: more persistent volumes to attach at /mnt/<volume name> (none by default)
- image: the docker image to run (default: julia)
- cpu: CPU share to allocate to master process (default: 0.1 of a core)
- gpu: GPUs to allocate to master process (default: 0)
- memory: RAM to allocate to master process (default: 512 MiB)
- shell: the script to use for master shell (default: notebook.sh)
- worker_cpu: CPU share to allocate to a worker process (default: 0.1 of a core)
- worker_gpu: GPUs to allocate to a worker process (default: 0)
- worker_memory: RAM to allocate to a worker process (default: 512 MiB)
- worker_shell: the script to use for a worker shell (default: master.sh)
- worker_start_script: a Julia script to start the worker node with (default: worker.sh)
- passwd: password to protect the notebook with (default: no password)
- ports: network ports to expose as a Dict{String,Tuple{Int,Int}} of name to container port and service port map (default: Dict("nb"=>(8888,8888)))
- external: whether network ports should be exposed to external network (default: false)
- restart: should workers be restarted (RestartAlways by default, can also be RestartOnFailure or Never)

### PkgBuilder
Build / update a Julia package bundle.

It mounts the volume representing the package folder of the bundle in
read-write mode, and launches a script to build them. It is similar to
a JuilaBatch job.

Package bundles are a way of making Julia packages accessible to JuliaRun jobs.
They are just folders with Julia packages, pre-compiled and along with all their
dependencies. Package bundles can be built and tested separately and attached to
multiple images, providing a way to dissociate their maintenance.

Attaching a package bundle to a JuliaRun job sets the appropriate environment
variables (`LOAD_PATH` and such) so that Julia code can start using them seamlessly.

Required parameters:
- name: name of the job (must be unique in the system, can be random)
- builder_script: a Julia script that builds packages
- run_volume: a persistent volume to use as the master volume
- pkg_bundle: the package bundle to build

Optional parameters:
- additional_volumes: more persistent volumes to attach at /mnt/<volume name> (none by default)
- image: the docker image to run (default: julia)
- cpu: CPU share to allocate (default: 2 cores)
- gpu: GPUs to allocate (default: 0)
- memory: RAM to allocate (default: 8 GiB)
- shell: the script to use for startup shell (default: master.sh)

### Webserver
Webserver that can be used to serve API/UI/files for jobs.

Scenarios:
- accept inputs (file uploads, API calls, ...)
- serve output/log files created by jobs
- simple user interfaces

Required parameters:
- name: name of the job (must be unique in the system, can be random)
- cfg_file: configuration file to start webserver with
- run_volume: a persistent volume to use as the master volume

Optional parameters:
- additional_volumes: more persistent volumes to attach at /mnt/<volume name> (none by default)
- image: the docker image to run (default: nginx)
- cpu: CPU share to allocate (default: 0.1 cores)
- memory: RAM to allocate (default: 512MiB)
- envvars: additional environment variables to set
- ports: network ports to expose as a Dict{String,Tuple{Int,Int}} of name to container port and service port map (default: Dict("http"=>(80,80), "https"=>(443,443)))
- external: whether network ports should be exposed to external network (default: false)
- nworkers: number of webserver containers to start

### MessageQ
Message Queue that can be used for communication between processes within or across jobs.
Enables complex routing/broadcast of messages.

Scenarios:
- inter process communication within / across jobs
- task queue, used by job arrays

Required parameters:
- name: name of the job (must be unique in the system, can be random)
- cfg_file: configuration file to start message queue with
- run_volume: a persistent volume to use as the master volume

Optional parameters:
- additional_volumes: more persistent volumes to attach at /mnt/<volume name> (none by default)
- image: the docker image to run (default: rabbitmq)
- cpu: CPU share to allocate (default: 1 core)
- memory: RAM to allocate (default: 4GiB)
- envvars: additional environment variables to set
- ports: network ports to expose as a Dict{String,Tuple{Int,Int}} of name to container port and service port map (default: Dict("amqptls"=>(5671,5671), "amqp"=>(5672,5672), "mgmttls"=>(15672,15671), "mgmt"=>(15672,15672)))
- external: whether network ports should be exposed to external network (default: false)

