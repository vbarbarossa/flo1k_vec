#!/bin/bash
#SBATCH --partition=milkun
#SBATCH --array 1-10
#SBATCH -N 1 -n 10
#SBATCH --mem=40G
#SBATCH --time=3-00:00:00
#SBATCH --output=/vol/milkunB/vbarbarossa/flo1k_vec/log/sample_flo1k_%a.out
#SBATCH --mail-type=END
#SBATCH --mail-user=vbarbarossa@science.ru.nl

module load R-3.4.2

cd /vol/milkunB/vbarbarossa/flo1k_vec

Rscript scripts/R/sample_flo1k.R
