#!/bin/bash
#SBATCH --partition=milkun
#SBATCH -N 1 -n 4
#SBATCH --mem=40G
#SBATCH --time=1-00:00:00
#SBATCH --output=/vol/milkunB/vbarbarossa/flo1k_vec/log/collate_array.out
#SBATCH --mail-type=END
#SBATCH --mail-user=vbarbarossa@science.ru.nl

module load R-3.4.2

cd /vol/milkunB/vbarbarossa/flo1k_vec

Rscript scripts/R/collate_array.R
