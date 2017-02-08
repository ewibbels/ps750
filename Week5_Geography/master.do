clear
clear matrix
set more off
set matsize 800
set mem 200m
capture log close

foreach X of num 1/7 {
	do maketable`X'
}

do makefigure1
do makefigure2

