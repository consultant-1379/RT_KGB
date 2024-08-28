#!/usr/bin/bash

(mkdir -p /eniq/home/dcuser/RegressionLogs;
mkdir -p /eniq/home/dcuser/ResultFiles;
source /eniq/sql_anywhere/bin64/sa_config.sh;
if [ -e data.txt ];
then
	chmod 777 RT_KGB.pl Encryption_Validation_KGB.pl TopologyLoading_Check_KGB.pl DataLoading_Check_KGB.pl CounterDataValidation_KGB.pl Aggregation_Status_KGB.pl InterfaceDirectory_Check_KGB.pl Busy_Hour_KGB.pl Universe_Check_KGB.pl RT_KGB_Summary.pl data.txt RegressionLogs ResultFiles;

	sed '/^$/d' data.txt > data.tmp
	mv data.tmp data.txt
	
	if [ -s data.txt ] 
	then
		perl -lpe 's/^\s*(.*\S)\s*$/$1/' data.txt > data.tmp && mv data.tmp data.txt;
		perl -pi -e 'chomp if eof' data.txt;
		date +%Y-%m-%d_%H_%M_%S > /eniq/home/dcuser/datetime.txt

	fileNamesArray=("RT_KGB.pl" "Encryption_Validation_KGB.pl" "TopologyLoading_Check_KGB.pl" "DataLoading_Check_KGB.pl" "CounterDataValidation_KGB.pl" "DataValidation_KGB.pl" "Aggregation_Status_KGB.pl" "InterfaceDirectory_Check_KGB.pl" "Busy_Hour_KGB.pl" "Universe_Check_KGB.pl" "RT_KGB_Summary.pl");
	
		# Iterate the loop to trigger each testcase

		for filename in ${fileNamesArray[@]};
		do
			if [ -e $filename ]; 
			then
				if [[ "$filename" == "CounterDataValidation_KGB.pl" || "$filename" == "DataValidation_KGB.pl" ]];
				then
					continue
				else 
					perl /eniq/home/dcuser/$filename 
					wait
				fi
			else 
				echo "$filename file is not exists";
			fi
		done

		#rm -rf ResultFiles
		#Aggregation_Status.txt Encryption.txt UNIVERSE_CHECK.txt InterfaceDirectory_Check.txt Busy_Hour.txt COUNTER_DATA_VALIDATION.txt TABLE_DATA_LOADING_CHECK.txt

		wait
		echo "All Test cases completed";
	else
		echo "data.txt is empty";
	fi
else
	echo "data.txt file is not exists";
fi

perl /eniq/home/dcuser/Format_KGB_Result.pl;
cp -R RegressionLogs KGB_RT_Reports/
echo "Copied html files from RegressionLogs directory and pasted it in KGB_RT_Reports directory"
echo "Creating KGB_RT_Reports.zip from KGB_RT_Reports directory";
zip -FSr KGB_RT_Reports.zip KGB_RT_Reports
echo "Created KGB_RT_Reports.zip file"
rm -rf KGB_RT_Reports/
chmod 777 KGB_RT_Reports.zip KGB.out;
exit) |& tee KGB.out
