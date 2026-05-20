#!/bin/bash
#SBATCH -t 01:30:00
#SBATCH -p cluster
#SBATCH --exclusive
#SBATCH -o "%j-CXI-test_coll.txt"
#SBATCH -J "CXI test"
#SBATCH --mail-user="michalowicz.2@osu.edu"
#SBATCH --mail-type=ALL

source ~/.bashrc
module load PrgEnv-gnu/8.5.0
module unload libfabric cray-mpich

TESTDIR=/cosmos/nfs/home/bmichalo/HWAccel-OFI/libfabric/prov/cxi/test/multinode
OFIDIR=/cosmos/nfs/home/bmichalo/HWAccel-OFI/libfabric/
MPIDIR=/cosmos/nfs/home/bmichalo/HWAccel-OFI/mvapich-plus

exp $MPIDIR/install
exp $OFIDIR/install
ppn=1
np=$(($SLURM_NNODES * $ppn))

cd $TESTDIR
numiters=1

expdir=cxi-coll
mkdir $expdir
echo "Running test suite of collectives WITHOUT multicast model"
outfile=$expdir/$SLURM_JOBID-$SLURM_NNODES-nodes-$ppn-ppn-test-cxi-coll-unicast.txt
rm -f $outfile
set -x
date
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

echo "Running test suite of collectives WITH multicast model"

outfile=$expdir/$SLURM_JOBID-$SLURM_NNODES-nodes-$ppn-ppn-test-cxi-coll-multicast.txt
rm $outfile
set -x
date
mpirun -np $np -ppn $ppn \
    -genv FI_PROVIDER="cxi" \
    -genv FI_CXI_COLL_JOB_ID=$SLURM_JOBID \
    -genv FI_CXI_COLL_JOB_STEP_ID=1 \
    -genv FI_CXI_HWCOLL_ADDRS_PER_JOB=$np \
    -genv FI_CXI_HWCOLL_MIN_NODES=2 \
    ./test_coll -v -V -N 1 -M -t11,12,13,14 -n $numiters > $outfile 2>&1
date
set +x

