#!/bin/bash

chkOperand(){
#Checks for missing operands
if [ $# -eq 0 ]
    then
    echo "safe_rm: missing operand"
    exit 1
fi
}

#————————————————————————————————————————————————
configDir(){

#Handles issues in number 4
read -p "Do you want to use the default directory?" an

if [[ $an = "Y" || $an = "y" ]]
    then
    deleted="$HOME/deleted/"
else
    env_R=$(printenv | grep RMCFG | cut -d"=" -f2)
   if [ ! -z $env_R ] 
	 then
   	deleted=$env_R
  elif [ -e $HOME/.rm.cfg ] 
	 then
      	rmcfg_file=$(cat ~/.rm.cfg)
       	if [ ! -z $rmcfg_file ] 
	 then
       	deleted=$rmcfg_file
       	 fi
  else			
	deleted=$HOME/deleted/
    fi
	
fi


#Creates recycle bim if its non-existent
    if ! [ -d $deleted ]
    then
        mkdir $deleted
    fi


#Creates restore.info if non existent
#restore.info stores original path and filename of file after being deleted
if [ ! -f ~/.restore.info ];
    then
    touch ~/.restore.info
fi
 chmod a+r,a+w,a+x $HOME/.restore.info

{

#————————————————————————————————————————————————————————————————————————

chkfile(){
#Checks to see if input file exists and exits script if it dont

 if [ -d $fname ] && ! $Rflag
    then
	echo "Cannot remove $fname, is a Directory."
            skip=true
             exit 1		
elif ! [ -f $fname ] && ! [ -d $fname ]
    then
	if $Rdone
	then
		exit 1
	else
	 echo cannot remove $fname : No such file or directory
        skip=true
	fi
fi
}
#——————————————————————————————————————————————————————————————————
interactive(){
if $iflag
    then
    read -p "safe_rm:remove $fname? (Y/N)" user

        if [[ $user != "Y" && $user != "y" ]]
            then
            echo "$fname not restored."
            skip=true
fi
    fi

}
#———————————————————————————————————————————————————————————

verbose(){

	if $vflag
    		then
      		echo removed $fname
	fi
}

#————————————————————————————————————————————————————————

delete(){

	#orginal directory of input file
	orginDir=$(readlink -f $fname)
	#Grab innode
	inode=$(ls -i $fname | cut -d " " -f1)
	#concatinate name underscore and innode
	finalname=$(echo $fname $inode|tr " " "_")

	  #move to deleted folder with changed name
            mv $fname $deleted/$finalname
	#creates file with data organized and appends to restore.info
	    echo $fname $finalname $orginDir | cut -d " " -f2,3 | tr " " ":" >> $HOME/.restore.info
	verbose

#————————————————————————————————————————————————————————

{

  recursivedelete(){
    for object in $(ls $fname)
    do
      route="$fname/$object"
      if [ -d $route ] ; then
	echo dir
        recur $route
      else
	if  [ -d $fname ] || [ -f $fname ]
	then
		delete
	fi
      fi
   done 
  }

#—————————————————————————————————————————————————————————

iflag=false
vflag=false
Rflag=false
Rdone=false
skip=false

while getopts :ivr opt
    do
    case $opt in
        i)iflag=true ;;
        v)vflag=true ;;
        r|R)Rflag=true ;;
        *)"safe_rm:invalid option"
                        exit ;;
    esac
done
shift $((OPTIND-1))

chkOperand
configDir

for fname in $@
do

	chkfile
	interactive

	if ! $skip
		then
		if $Rflag
	  		then
	    		recursivedelete
	    		Rdone=true
		else
	 		delete

		fi
	fi

$skip=false

done


