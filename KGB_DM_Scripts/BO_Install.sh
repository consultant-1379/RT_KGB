#!/usr/bin/bash

# This Script is to Extract the BO files...
if [ ! -d "/eniq/sw/installer/boreports/" ]
then
	su - dcuser -c "mkdir /eniq/sw/installer/boreports/"
else
	echo "BOREPORTS directory is present....!!!!"
fi

BO_Check=`ls /eniq/sw/installer/BO_package/*tpi |wc -l`

if [ $BO_Check -eq 0 ]
    then
        echo "No BO TPI tech packs are available at the BO packages dir"
else
		echo " We have the BO tech packs ..and hence we have to extract these as well"

		# Below code is to rename all the BO tech packs from tpi to zip file extensions.

        cd /eniq/sw/installer/BO_package/
	chmod 777 /eniq/sw/installer/BO_package/*.tpi
	/usr/bin/chown dcuser:dc5000 /eniq/sw/installer/BO_package/*.tpi
        echo " Bo files are "
        ls -lrt /eniq/sw/installer/BO_package/*.tpi

        Files=`ls -lrt /eniq/sw/installer/BO_package/ | grep tpi | awk -F" " '{print $9}'`

        for i in ${Files[@]}
        do
            echo $i
            name=`echo $i | cut -d "." -f1`
            mv $i $name.zip
            zipfile=$name.zip
        done
	sleep 5
	su - dcuser -c "cd /eniq/sw/installer/;/usr/bin/bash /eniq/sw/installer/extract_report_packages.bsh /eniq/sw/installer/BO_package/ /eniq/sw/installer/bouniverses/"

	echo " Executing the Compare_CUID.pl script to the CUID of BO packages"
	su - dcuser -c "cd /tmp ;/usr/bin/perl /tmp/Compare_CUID.pl"
	echo "COMPARE_CUID DONE"
fi
