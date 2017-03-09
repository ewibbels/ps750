cd "/Users/deandulay/Desktop/PE_Development"



/* use dataset with missing values*/
rename id cabb
merge 1:1 cabb period using authoritarian_collapsed_new

/* use dataset with imputed values */
rename id cabb
merge 1:1 cabb period using authoritarian_collapsed_new
