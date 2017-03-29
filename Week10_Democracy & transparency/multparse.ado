program define multparse
	* First argument is variable to parse
	* Second argument is new variable stub name

	foreach curString of any A B C D E F G H I J K L M N O P Q R S T U V W X Y Z {
		
		qui g `2'_`curString' = index(`1',"`curString'")
		qui replace `2'_`curString' = 1 if `2'_`curString' > 1 & `2'_`curString' != .
		qui replace `2'_`curString' = . if `1' == ""
		
		qui summ `2'_`curString' 
		if r(mean) == 0 | r(N) == 0 {
			drop `2'_`curString'
		}
		else {
			display in green "Created variable `2'_`curString'" 
		}
	}	
end

