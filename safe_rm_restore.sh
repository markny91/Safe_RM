#!/bin/bash

chkOperand(){
#Checks for missing operands
if [ $# -eq 0 ]
    then
    echo "safe_rm: missing operand"
    exit 1
fi
}

#—————————————————————————————————
interactive(){
if $iflag
    then
    read -p "safe_rm_restore:restore $fname? (Y/N)" user

        if [[ $user != "Y" && $user != "y" ]]
            then
            echo "$fname not restored."
            skip=true
fi
    fi

}
#————————————————————————————
verbose{
if $vflag
   then
   echo safe_rm_restore: Restored $file
fi
}

#—————————————————————————————
chkFile(){
#checks if file is in recycle bin
if ! [ -f $deleted ] && ! [ -d $deleted ]
	then
	echo "$file Does Not Exist in recycle bin"
	exit
fi

#create temporaty restore file when extracting removed file
if ! [ -f $HOME/restoretemp ]
	then
	touch $HOME/restoretemp
fi

 chmod a+r,a+w,a+x $HOME/restoretemp
 chmod a+r,a+w,a+x $HOME/.restore.info
}


#—————————————————————————
restoreFile(){
	mv $deleted $targdir
        grep -v $file $HOME/.restore.info > $HOME/restoretemp
        mv $HOME/restoretemp $HOME/.restore.info
	verbose
	}
#————————————————————————————————————————————————————————
  recursiveRestore(){
    for object in $(ls $fname)
    do
      route="$fname/$object"
      if [ -d $route ] ; then
	echo dir
        recur $route
      else
	if  [ -d $fname ] || [ -f $fname ]
	then
	restoreFile
	fi
      fi
   done 
  }
restoreHandler(){

		if [ -d $deleted ]
			then
			recursiveRestore
			Rdone=true 
		else
	        	restoreFile
				
		fi

}
#———————————————————————————————————————————————————————————
Overwrite(){

	read -p  "File Exists, Would You Like to Overwirite it: Y or N?” input
	#Moves file back to directory
	if [[ $input = 'y' || $input = 'Y' ]]
	then
		restoreHandler
		$file Overwritten

	elif  [[ $input = 'n' || $input = 'N' ]]
		then
		#Wrong input and exits code if it does
		echo File Not Overwritten
		exit
	else 
		echo Wrong input 
		Overwrite
	fi

}
#—————————————————————————
iflag=false
vflag=false
Rdone=false
skip=false

while getopts :iv opt
    do
    case $opt in
        i)iflag=true ;;
        v)vflag=true ;;
        *)"safe_rm:invalid option"
                        exit ;;
    esac
done
shift $((OPTIND-1))


file=$1
deleted=$HOME/deleted/$file

chkOperand
interactive
chkFile

targdir=$(grep $file $HOME/.restore.info | cut -d ":" -f2)


if ! $skip
	then
if [ -f $targdir ] || [ -d $targdir ]
	then
	Overwrite
else                                     
       restoreHandler
fi

fi
skip=false
