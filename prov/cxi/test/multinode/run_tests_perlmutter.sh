#!/bin/bash
#SBATCH --ntasks-per-node=4 
#SBATCH -t 04:00:00
#SBATCH -A m3896
#SBATCH --constraint=gpu 
#SBATCH --gpus-per-node=4
#SBATCH --gpus-per-task=1
#SBATCH -q regular
#SBATCH --exclusive
#SBATCH -o "%j-CXI-tests.txt"
#SBATCH -J "Compression test"
#SBATCH --mail-user="michalowicz.2@osu.edu"
#SBATCH --mail-type=ALL


#source ~/.bashrc

exp(){
    export PATH=$1/bin:$PATH
    export LD_LIBRARY_PATH=$1/lib:$LD_LIBRARY_PATH
}

alias sqp="squeue -p $1"

exp2(){
    export PATH=$1/bin:$PATH
    export LD_LIBRARY_PATH=$1/lib:$LD_LIBRARY_PATH
    export CPATH=$1/include:$CPATH
}
exp-lib64() {
    exp2 $1
    export LD_LIBRARY_PATH=$1/lib64:$LD_LIBRARY_PATH
}


module unload cray-mpich libfabric/1.22.0
TESTDIR=/pscratch/sd/b/bmichalo/coll-offload/libfabric/prov/cxi/test/multinode
MPIDIR=/pscratch/sd/b/bmichalo/coll-offload/MVP-main
OFIDIR=/pscratch/sd/b/bmichalo/coll-offload/libfabric/

exp-lib64 $MPIDIR/install
exp-lib64 $OFIDIR/install

echo "Running libfabric tests on $SLURM_NNODES nodes (1 ppn)"
ppn=1
np=$(($SLURM_NNODES * $ppn))



cd $TESTDIR
numiters=1000
#echo "running barrier for all ranks and then a parallel at root 0, shifting the root of the barrier for each proc"
#exp=cxi-barrier
#mkdir $exp
#for i in `seq 0 $(($np-1))`; do
#    outfile=$exp/$SLURM_JOBID-$SLURM_NNODES-nodes-$ppn-ppn-$i-root-cxi-barrier.txt
#    rm $outfile
#    echo "Running barrier with root $i"
#    set -x
#    mpirun -np $np -ppn $ppn \
#        -genv FI_PROVIDER="cxi" \
#        -genv FI_CXI_COLL_JOB_ID=$SLURM_JOBID \
#        -genv FI_CXI_COLL_JOB_STEP_ID=1 \
#        -genv FI_CXI_HWCOLL_ADDRS_PER_JOB=$np \
#        -genv FI_CXI_HWCOLL_MIN_NODES=2 \
#        ./test_barrier -N $numiters -R $i > $outfile 2>&1
#    set +x
#done
#
#outfile=$exp/$SLURM_JOBID-$SLURM_NNODES-nodes-$ppn-ppn-0-root-parallel-cxi-barrier.txt
#rm $outfile
#set -x
#    mpirun -np $np -ppn $ppn \
#        -genv FI_PROVIDER="cxi" \
#        -genv FI_CXI_COLL_JOB_ID=$SLURM_JOBID \
#        -genv FI_CXI_COLL_JOB_STEP_ID=1 \
#        -genv FI_CXI_HWCOLL_ADDRS_PER_JOB=$np \
#        -genv FI_CXI_HWCOLL_MIN_NODES=2 \
#        ./test_barrier -N $numiters -p > $outfile 2>&1
#set +x
#

exp=cxi-coll
echo "Running test suite of collectives, $numiters counts, tests 0-9, 11-15, WITHOUT multicast model"
mkdir $exp
outfile=$exp/$SLURM_JOBID-$SLURM_NNODES-nodes-$ppn-ppn-test-cxi-coll-unicast.txt
rm $outfile
set -x
date
mpirun -np $np -ppn $ppn \
    -genv FI_PROVIDER="cxi" \
    -genv FI_CXI_COLL_JOB_ID=$SLURM_JOBID \
    -genv FI_CXI_COLL_JOB_STEP_ID=1 \
    -genv FI_CXI_HWCOLL_ADDRS_PER_JOB=$np \
    -genv FI_CXI_HWCOLL_MIN_NODES=2 \
    ./test_coll -v -V -N 1 -n $numiters -t11,12,13,14 > $outfile 2>&1
date
set +x

echo "Running test suite of collectives, 16 operation counts per reduce, tests 0-9, 11-15, WITH multicast model"
outfile=$exp/$SLURM_JOBID-$SLURM_NNODES-nodes-$ppn-ppn-test-cxi-coll-multicast.txt
rm $outfile
set -x
date
mpirun -np $np -ppn $ppn \
    -genv FI_PROVIDER="cxi" \
    -genv FI_CXI_COLL_JOB_ID=$SLURM_JOBID \
    -genv FI_CXI_COLL_JOB_STEP_ID=1 \
    -genv FI_CXI_HWCOLL_ADDRS_PER_JOB=$np \
    -genv FI_CXI_HWCOLL_MIN_NODES=2 \
    ./test_coll -v -V -N 1 -M -t11,12,13,14 > $outfile 2>&1
date
set +x

#exp=cxi-zbcoll
#echo "Running test suite of zero-based put (ZB) collectives, 40 runs, tests 0-19"
#mkdir $exp
#outfile=$exp/$SLURM_JOBID-$SLURM_NNODES-nodes-$ppn-ppn-test-cxi-zbcoll.txt
#rm $outfile
#set -x
#date
#mpirun -np $np -ppn $ppn \
#    -genv FI_PROVIDER="cxi" \
#    -genv FI_CXI_COLL_JOB_ID=$SLURM_JOBID \
#    -genv FI_CXI_COLL_JOB_STEP_ID=1 \
#    -genv FI_CXI_HWCOLL_ADDRS_PER_JOB=$np \
#    -genv FI_CXI_HWCOLL_MIN_NODES=2 \
#    ./test_zbcoll -v -V -t 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19 -N $(($numiters/2)) > $outfile 2>&1
#date
#set +x
