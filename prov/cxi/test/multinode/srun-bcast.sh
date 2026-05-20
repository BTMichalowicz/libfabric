#!/bin/bash
#SBATCH -t 00:95:00
#SBATCH -A csc549
#SBATCH -p batch
#SBATCH --exclusive
#SBATCH -o "%j-bcast-Frontier-CXI-tests.txt"
#SBATCH -J "CXI test"
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


module purge ; module load PrgEnv-gnu/8.6.0 ; module unload libfabric
TESTDIR=/lustre/orion/csc549/scratch/btmichalowicz/Coll-Offload/libfabric/prov/cxi/test/multinode
MPIDIR=/lustre/orion/csc549/scratch/btmichalowicz/Coll-Offload/mvapich-plus
OFIDIR=/lustre/orion/csc549/scratch/btmichalowicz/Coll-Offload/libfabric/

#exp-lib64 $MPIDIR/install
exp-lib64 $OFIDIR/install

echo "Running libfabric tests on $SLURM_NNODES nodes (1 ppn)"
ppn=$1
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
outfile=$exp/$SLURM_JOBID-Frontier-$SLURM_NNODES-nodes-$ppn-ppn-4-inflight-test-cxi-coll-unicast.txt
rm $outfile
set -x
date
max_cnt=$((32*1024))
srun -n $np --ntasks-per-node=$ppn \
    --export FI_PROVIDER="cxi",FI_CXI_COLL_JOB_ID=$SLURM_JOBID,FI_CXI_COLL_JOB_STEP_ID=1,FI_CXI_HWCOLL_ADDRS_PER_JOB=$(($np/2)),FI_CXI_HWCOLL_MIN_NODES=2,FI_CXI_BENCHMARK_MAX_CNT=$max_cnt,FI_CXI_BENCHMARK_CNT=$max_cnt,FI_CXI_BENCHMARK_MAX_ITER=$numiters,FI_CXI_BENCHMARK_MAX_INFLIGHT=$2,PMI_NUM_HSNS=4 \
    ./test_coll -v -V -N 1 -n $numiters -t13 > $outfile 2>&1
   

    #-genv FI_PROVIDER="cxi" \
    #-genv FI_CXI_COLL_JOB_ID=$SLURM_JOBID \
    #-genv FI_CXI_COLL_JOB_STEP_ID=1 \
    #-genv FI_CXI_HWCOLL_ADDRS_PER_JOB=$np \
    #-genv FI_CXI_HWCOLL_MIN_NODES=2 \
    #-genv FI_CXI_BENCHMARK_MAX_CNT=$max_cnt \
    #-genv FI_CXI_BENCHMARK_CNT=$max_cnt \
    #-genv FI_CXI_BENCHMARK_MAX_ITER=$numiters \
    #-genv FI_CXI_BENCHMARK_MAX_INFLIGHT=4 \
    #./test_coll -v -V -N 1 -n $numiters -t13 > $outfile 2>&1
date
set +x



#echo "Running test suite of collectives, $numiter operation counts per reduce, tests 0-9, 11-15, WITH multicast model"
#outfile=$exp/$SLURM_JOBID-Frontier-$SLURM_NNODES-nodes-$ppn-ppn-8-inflight-test-cxi-coll-unicast.txt
#rm $outfile
#set -x
#date
#mpirun -np $np -ppn $ppn \
#    -genv FI_PROVIDER="cxi" \
#    -genv FI_CXI_COLL_JOB_ID=$SLURM_JOBID \
#    -genv FI_CXI_COLL_JOB_STEP_ID=1 \
#    -genv FI_CXI_HWCOLL_ADDRS_PER_JOB=$np \
#    -genv FI_CXI_HWCOLL_MIN_NODES=2 \
#    -genv FI_CXI_BENCHMARK_MAX_CNT=$max_cnt \
#    -genv FI_CXI_BENCHMARK_CNT=$max_cnt \
#    -genv FI_CXI_BENCHMARK_MAX_ITER=$numiters \
#    -genv FI_CXI_BENCHMARK_MAX_INFLIGHT=8 \
#    ./test_coll -v -V -N 1 -t13 -n $numiters > $outfile 2>&1
#date
#set +x

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
#    ./test_zbcoll -v -V -t 7,8,17,18,19 -N $(($numiters/2)) > $outfile 2>&1
#date
#set +x
