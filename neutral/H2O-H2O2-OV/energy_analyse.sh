 #!/bin/bash

echo "What's the input file? (without extension)"
read input_file
echo "====================================="
echo "In process..."
echo "..."

output_file=$input_file.out
plot_file=${input_file}__data.ssv


starttime=$(date +%s)

#output_file=ZrO2.out         # Change the file name here
#plot_file=ZrO2__data.ssv     # Name the output file here 


if test -e $plot_file  ; then
rm -r $plot_file
fi

echo "# Starting Date: $(date)" >> $plot_file
echo "# Directory: $PWD" >> $plot_file
echo "# File: $output_file" >> $plot_file
echo -n "# CYCLE NUMBER | TOTAL ENERGY (Ha) | SCF_CYCLES | MAX_GRADIENT(0.000450) | RMS_GRADIENT(0.000300) | MAX_DISPLAC.(0.001800) | RMS_DISPLAC.(0.001200)" >> $plot_file
cycle_total=$(grep -e 'TOTAL ENERGY(DFT)(AU)'  ./$output_file | wc -l)
for((i=1;i<=$cycle_total;i++));do
    cycle_number=$(grep -m $i 'OPTIMIZATION - POINT' ./$output_file | tail -1 | awk '{print $NF}') 
    line_number1=$(grep -m $i -n 'OPTIMIZATION - POINT'  ./$output_file | tail -1 | cut  -d  ":"  -f  1)
    line_number2=$(grep -m $(expr $i + 1) -n -E 'OPTIMIZATION - POINT|OPT END - CONVERGED'  ./$output_file | tail -1 | cut  -d  ":"  -f  1)
    read total_energy SCF_CYCLES <<< $(grep -m $i 'TOTAL ENERGY(DFT)(AU)' ./$output_file | tail -1 | awk '{print $(NF-3),$(NF-4)}')
    var_type=$(echo $total_energy | tr -cd "[0-9]")
    if [ -z $var_type ] ; then
        read total_energy SCF_CYCLES <<< $(grep -m $i 'TOTAL ENERGY(DFT)(AU)' ./$output_file | tail -1 | awk '{print $(NF-4),$(NF-5)}') 
        SCF_CYCLES=$(echo $SCF_CYCLES | tr -cd "[0-9]")
    else
        SCF_CYCLES=$(echo $SCF_CYCLES | tr -cd "[0-9]")
    fi
    CYCLE_REJECTED=$(sed -n "${line_number1},${line_number2}p" ./$output_file | grep -e 'STEP REJECTED')
    if [ -n "$CYCLE_REJECTED" ] ; then
        printf "\n%s \t %d \t %15.10f \t %d" xxx $cycle_number $total_energy $SCF_CYCLES >> $plot_file
    else
        printf "\n \t %d \t %15.10f \t %d" $cycle_number $total_energy $SCF_CYCLES >> $plot_file
    fi
    #sed -n "${line_number1},${line_number2}p" ./$output_file | grep -e 'MAX GRADIENT' | awk '{print $3,$7}'| while read a b;do
    #    MAX_GRADIENT=$a MAX_GRADIENT_CONVERGED=$b
    read MAX_GRADIENT MAX_GRADIENT_CONVERGED <<< $(sed -n "${line_number1},${line_number2}p" ./$output_file | grep -e 'MAX GRADIENT' | awk '{print $3,$7}')
    read RMS_GRADIENT RMS_GRADIENT_CONVERGED <<< $(sed -n "${line_number1},${line_number2}p" ./$output_file | grep -e 'RMS GRADIENT' | awk '{print $3,$7}')
    read MAX_DISPLAC MAX_DISPLAC_CONVERGED <<< $(sed -n "${line_number1},${line_number2}p" ./$output_file | grep -e 'MAX DISPLAC' | awk '{print $3,$7}')
    read RMS_DISPLAC RMS_DISPLAC_CONVERGED <<< $(sed -n "${line_number1},${line_number2}p" ./$output_file | grep -e 'RMS DISPLAC' | awk '{print $3,$7}')
    printf "\t \t %6.6f %s" $MAX_GRADIENT  $MAX_GRADIENT_CONVERGED >> $plot_file
    printf "\t \t %5.6f %s" $RMS_GRADIENT $RMS_GRADIENT_CONVERGED >> $plot_file
    printf "\t \t %6.6f %s" $MAX_DISPLAC $MAX_DISPLAC_CONVERGED >> $plot_file
    printf "\t \t %6.6f %s" $RMS_DISPLAC $RMS_DISPLAC_CONVERGED >> $plot_file
done
endtime=$(date +%s)
dif=$(expr $endtime - $starttime)
time_used=$(date +%M:%S -d "1970-01-01 UTC $dif seconds")
sed -i "/# Starting Date:/a\# Termination Date: $(date)" $plot_file
sed -i "/# Termination Date:/a\# Time Used: $time_used" $plot_file
printf "\n# Done!" >> $plot_file
echo "Completed successfully!"
echo "====================================="
