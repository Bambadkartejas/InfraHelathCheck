echo "triggerClassification: $1";

. /app/HealthCheck/Script/REQUIREMENT/APPLICATION.CFG

I
alertType="$alertType"
application="$ApplicationName"
MorningAndManualFolder="$MorningAndManualFolder_1"
ImmediteAlertFolder="$ImmediteAlertFolder_1"
TO="$TO_BAU_EMAIL_ID"
Alert_TO="$Alert_Mail_ID"
FROM="$FROM_EMAIL_ID"
DISK_CRITICAL_THRESHOLD="$DISK_CRITICAL_THRESHOLD"
DISK_WARNING_THRESHOLD="$DISK_WARNING_THRESHOLD"
THRESHOLD="$THRESHOLD"
MONITORED_DIR1="$MONITORED_DIR1"
MONITORED_DIR2="$MONITORED_DIR2"

##########
#####Requirement Section
##########

BASE_PATH="/app/HealthCheck/Script/REQUIREMENT"
EMAIL_CONTENT_GREEN=$(cat /app/HealthCheck/Script/REQUIREMENT/EMAIL_TRIGGER/EMAIL_BODY_GREEN)
EMAIL_CONTENT_RED=$(cat /app/HealthCheck/Script/REQUIREMENT/EMAIL_TRIGGER/EMAIL_BODY_RED)
EMAIL_CONTENT_AMBER=$(cat /app/HealthCheck/Script/REQUIREMENT/EMAIL_TRIGGER/EMAIL_BODY_AMBER)
dt1=$(date "+%Y%m%d%H%M%S")
hostName=$(hostname|tr [a-z] [A-Z])
hostname=$(hostname -i)
Current time=$(date "+%Y.%m.%d-%H.%M.%S")
dt=$(date "+%Y-%m-%d %H:%M:%S")


#################
#######TemporaryReport Name at desired path based on triggerClassi
#################

if [ "$1" == "Morning" ] || [ "$1" == "" ]; then
 {
   filename="$(MorningAndManualFolder)HealthReport-${application).html"
 }
 elif [ "$1" = "15MinFolder" ]; then
   { 
     filename="${ImmediteAlertFolder) HealthReport-${application).html"
    }
else
    echo "Invalid Argument in Health Check script"
fi

echo "<html><head><style>body{padding: 8px 8px 8px 8px; margin-right:40px; margin-left:40px;font-family: sans-serif;)h4{margin-top:15px;margin-bottom:15px;color:#00004d;font-weight:bold;text-decoration:underline;)table(width:100%;border-collapse:collapse)th{padding: 5px 0 5px 0px; text-align:center; font-size:15px; border:1px solid black;background-color:green;color:white; font-weight:bold}td{padding:5px 10px 5px 10px;text-align:left;font-size:14px;border:1px solidblack;}tr:hover(background-color:#ddd}tr:nth-child(even) (background-color:#f2f2f2;}</style>" >> $filename

echo '</head><body><div class="tab"><h3>'$alertType' INFRA Health Report of '$hostname' Server Generated at '$dt'</h3><br><h5>NOTE: Search AMBER/RED to find the issue at which section persist</h5></font></div>' >> $filename

########
#CURL COMMAND ON ALL SERVER, SERVICES #
#########

CFG_FILE="$BASE PATH/CURL/CURL_CHECK.CFG"

#check if config file exist
if [ -f "$CFG FILE"]; then
   echo "File $CFG FILE not found on the server"
else
    echo "<br><h4>EXECUTING CURL COMMANDS ON SERVERS</h4>" >> $filename
    echo "<table style='width:800px'><tr><th>SERVICE do NAME</th><th>SERVICES</th><th>STATUS</th><th>SCRIPT STATUS</th></tr>" >> $filename
    while IFS='' read r line || [[ -n "$line" ]]
      do
      {
      STRING="$line"
      ServicesLink=`echo $STRING | awk -F '|' '{print $1}'`
      ServicesName=`echo $STRING | awk -F '|' '{ print $2}'`
      response4=$(curl -k --head $ServicesLink | grep "HTTP/1.1 200 OK"|wc -1)
      RESPONSE_CODE=$(curl -k -o /dev/null -s -w "%(http_code)\n" $ServicesLink)
      
      if [ $response4 -gt 0]; then
      {
       echo "<tr><td>${ServicesName[$i]}</td><td>${ServicesLink[$i]}</td><td>Pass</td><td>GREEN</td></tr>" >> $filename 
      }
      else
      {
       echo "<tr style="background-color:red'><td>$(ServicesName[$i]}</td><td>${ServicesLink[$i]}</td><td>Fail</td><td>RED</td></tr>" >> $filename
       testStatus="RED" >> $filename
      }
    done < $CFG_FILE
    echo "</table>" >> $filename
fi

###########
###TELNET ON SERVERS
##########

telnet_file="$BASE_PATH/TELNET/TELNET_CHECK.CFG"

#check if config file exist
if [ -f "$telnet_file" ]; then
   echo "File Stelnet file not found on the server"
else
  echo "<h4>EXECUTING TELNET COMMANDS ON SERVERS</h4>" >> $filename
  echo "<table style='width: 700px'>" >> $filename
  echo "<tr><th>SERVERS</th><th>STATUS</th><th>SCRIPT STATUS</th></tr>" >> $filename
  
  while IFS='|' read -r line;
  do
  {
    STRING="$line"
    ip=`echo $STRING | awk -F '|' '{print $1}'`
    port=`echo $STRING | awk -F '|' '{ print $2}'`
    Name=`echo $STRING | awk -F '|' '{ print $3 }''
    
    echo quit | telnet $ ip Sport 2>/dev/null | grep i connected > /dev/null;
    if [[ $? -eq 0]]; then
       echo "<tr><td>${Name}</td><td>Successfull</td><td>GREEN</td></tr>" >> $filename
    else
       echo "<tr style='background-color: red'><td>${Name}</td><td>Un-Successfull</td><td>RED</td></tr>" >> $filename
       testStatus="RED" >> $filename
    fi
   }
   done < $telnet file
   echo "</table>" >> $filename
fi

#########
###CHECKING THE HEAP UTILIZATION ON SERVER
##########

echo "<table style='width:500px'>" >> $filename echo
echo "<h4>Checking the Heap Utilization on Server (Command: free | awk '/Mem/{printf("%.2f"), $3/$2*100}')</h4>" >> $filename
echo "<tr><th>HEAP UTILIZATION</th><th>Script Status</th></tr>" >> $filename


#THRESHOLD=80

USED_PERCENT=$(free | awk '/Mem/{printf("%.2f"), $3/$2*100}')

if (($(echo "$USED PERCENT > $THRESHOLD" |bc -1))); then
   echo "<tr style='background-color:red'>td>Heap Utilization is above $THRESHOLD & current utilization is $ USED_PERCENT%</td><td>RED</td></tr>" >> $filename
   testStatus="RED" >> $filename
else
   echo "<tr><td> Heap Utilization is below $THRESHOLD & current utilization is $USED_PERCENT%</td><td>GREEN</td></tr>" >> $filename
fi
echo "</table>" >> $filename

############
#####CHECKING THE RAM MEMORY
############

echo "<table style='width:500px'>" >> $filename
echo "<h4>CHECKING THE RAM USAGES in GB (Command: free -h)</h4>" >> $filename
echo echo "<tr><th>Utilization of RAM%</th><th>Script Status</th></tr>" >> $filename

RAM=$(free | awk 'NR=2{printf "%.0f\n", $3*100/$2}')

if [ $RAM -gt "$DISK_CRITICAL_THRESHOLD"); then
   echo "<tr style='background-color:red'><td>CRITICAL: Current utiliation is $RAM%</td><td>RED</td></tr>" >> $filename
   testStatus="RED" >> $filename
elif [[ $RAM -lt "$DISK_CRITICAL_THRESHOLD" && $RAM -ge "$DISK_WARNING_THRESHOLD")); then
   echo "<tr style='background-color: # FFBF00'><td>WARNING: Current Utiliation is $RAM%</td><td>AMBER</td></tr>" >> $filename
   testStatus="AMBER" > $filename
else
   echo "<tr><td>NORMAL: Current Utiliation is $RAM%</td><td>GREEN</td></tr>" >> $filename
fi
echo "</table>" >> $filename

###########
####CHECKING THE CPU UTILIZATION SPACE ON SERVER #
##########

echo "<table style='width:500'>" >> $filename
echo "<h4>&CPU UTILIZATION ON SERVER (Command: top) </h4>" >> $filename
echo "<tr><th>&CPU Utilization</th><th>Script Status</th></tr>" >> $filename

cpu_usage1=$(top -bn1 |grep "Cpu(s)" | sed "s/.*, *\([0-9]*\)%* id.*/\1/" | awk '{print 100 -$1}')

if (( $(echo "$cpu_usage >= 85" | bc-1) )); then
   echo "<tr style="background-color:RED'><td>CPU Utilization is High: $cpu_usage1%</td><td>RED</td></tr>" >> $filename
   testStatus="RED" >> $filename
else
  echo "<tr><td> CPU Utilization is Normal: $cpu_usage18</td><td>GREEN</td></tr>" >> $filename
fi

echo "</table>" >> $filename

##############
######Checking Disk Space On Server
##############

disk_file="$BASE_PATH/DISK_SPACE/DISK_SPACE.CFG"
default_disk file="$BASE_PATH/DISK_SPACE/READONLY_DISK_SPACE.CFG"

if [ -f "$disk_file" ] && [ ! -f "$default_disk_file" ]; then
   echo "File $disk_file and $default_disk_file not found on the server"
else
   echo "<h4>CHECKING DISK SPACE ON SERVER (Command: df -h)</h4>" >> $filename
   echo "<table style='width: 900px'>" >> $filename
   echo "<tr><th>Application</th><th>CURRENT UTILIZATIONS</th><th>STATUS</th><th>SCRIPT STATUS</th></tr>" >> $filename
   
   if [ ! -f "$disk_file" ]; then
      echo "File $disk_file not found on the server"
   else
      while IFS read -r disk_space; do
      {
      disk_usage=$(df -h "$disk_space" | awk 'NR==2 { print $5}' | cut -d'%' -f1) 
      
       if [[ disk_usage -gt "$DISK_CRITICAL_THRESHOLD" ]]; then
       {
         echo "<tr style='background-color:RED'><td>${disk_space)</td><td>${disk_usage}</td><td>CRITICAL</td><td>RED</td></tr>" >> $filename
         testStatus="RED" >> $filename
       }
       elif [[disk_usage -lt "$DISK_CRITICAL_THRESHOLD" && disk_usage -ge "$DISK_WARNING_THRESHOLD" ]]; then
       {
         echo"<tr style='background-color: #FFBF00'><td>${disk_space)</td><td>$(disk_usage}%</td><td>WARNING</td><td>AMBER</td></tr>" >> $filename
         testStatus="AMBER" >> $filename
        }
        else
        {
           echo "<tr><td>${disk_space}</td><td>${disk_usage}%</td><td>NORMAL</td><td>GREEN</td></tr>" >> $filename
        }
        fi
       }
      done "$disk file"
   fi
   
   if [ ! -f "$default_disk_file" ]; then
     echo "File $default_disk_file not found on the server"
  else
     while IFS= read -r disk_spaces; do
     {
        echo disk usagel=$(df -h "$disk_spaces" | awk 'NR==2 { print $5}' | cut -d's' -1) "<tr><td>${disk_spaces}</td><td>$disk_usage1%</td><td>NORMAL</td><td>GREEN</td></tr>" >> $filename
     }
     done < "$default_disk_file"
   fi
   echo "</table>" >> $filename
fi


##########
####SERVICES/API CHECKING ON THE SERVER
##########

businessClassification="$BASE_PATH/API/URL_BUSINESS_CLASSIFICATION/clinet1.CFG"
businessClassificationl="$BASE_PATH/API/URL_BUSINESS CLASSIFICATION/clinet2.CFG"
header="$SBASE_PATH/API/HEADER_BUSINESS_CLASSIFICATION/client1.CFG"
header1="$BASE_PATH/API/HEADER_BUSINESS_CLASSIFICATION/client2.CFG"


if [ ! -f "$businessClassification" ] || [ -f "$businessClassificationl" } || [ ! -f "$header" ] || [ ! -f "$header1" ]; then
   echo "Business classificaiton & header file not found"
else
    headers customer1=$(cat "$header")
    headers customer2=$(cat "$header1")
    echo "<h4>EXECUTING CURL ON API (SERVICES)</h4>" >> $filename echo "<table style='width: 600px'>" >> $filename
    echo "<tr><th>Client</th><th>Services</th><th>Response</th><th>SCRIPT STATUS</th></tr> " >> $filename
    
    while IFS="|" read -r client api_url api_name;
    do
      if [ -n "$api_url" && -n "$api_name"]]; then
          echo "curl doing: curl -ik X GET $headers_customer1 "$api_url" | grep HTTP/1.1"  >> $filename
          cmd="curl -ik -X GET $headers_customer1 $api_url"
          response=$(eval "$cmd | grep 'HTTP/1.1'")

          echo "<tr><td>$client</td><td>$api_name</td><td>$response</td><td>GREEN</td></tr>"  >> $filename
     else
          echo "<tr style='background-color:RED'><td>$client</td><td>$api_name</td><td>$response</td><td>RED</td></tr>"  >> $filename
     fi
    
    done < "$businessClassification"

   while IFS="|" read r client api_urll api namel;
   do
     if [ -n "$api_url1" && -n "$api_namel"]]; then
       echo "checking API: Sapi namel"
       echo "curl doing: curl -ik X GET $headers_customer2 "$api_url1" | grep HTTP/1.1"
       cmd="curl -ik X GET $headers_customer2 $api_url1"
       response=$(eval "$cmd | grep 'HTTP/1.1'")
       echo "<tr><td>$client</td><td>$api_name1</td><td>$response</td><td>GREEN</td></tr>" >> $filename
     else
       echo "<tr style='background-color:RED'><td>$client</td><td>$api_name1</td><td>$response</td><td>RED</td></tr>" >> $filename
     fi
  done < "$businessClassification1"
  echo "</table>" >> $filename
fi


###########
##CHECKING THE FOLDER MOUNTED ON SERVER OT NOT WITH CORRECT OWNER
###########

folder_file="$BASE_PATH/FOLDER_STRCTURE/FOLDER_PATH.CFG"
folder filel="$BASE_PATH/FOLDER_STRCTURE/FOLDER_INT.CFG"

if [ -f "$folder_file" ] && [ ! -f "$folder_filel" ]; then
   echo "File $folder file or $folder_filel not found on the server"
else
   echo "<h4>CHECKING FOLDER STRCTURE MOUNTED OR NOT WITH OWNER</h4>" >> $filename
   echo "<table style='width: 900px'>" >> $filename
   echo "<tr><th>Folder Path</th><th>Present/Not</th><th>Folder Onwer</th><th>Script Status</th></tr>" >> $filename

    if [ -f "$folder_file" ]; then
       echo "File $folder file not found on the server"
    else
        while IFS="|" read -r folder_path owner_name; do 
        if mount | grep "$folder_path" > /dev/null; then
    
          if [ "$(stat -c '%U' "$folder_path")" = "$owner_name" ]; then
             echo "<tr><td>$folder_path</td><td>Mounted</td><td>$owner_name is correct folder owner</td><td>GREEN</td></tr>" >> $filename
          else
             actual_owner=$(stat -c %U "$folder_path")
             echo "<tr style='background-color:red'><td>$folder_path</td><td>Mounted</td><td>$owner_name is correct folder owner but current owner is different</td><td>RED</td></tr>" >> $filename
             testStatus="RED" >> $filename
          fi
        else
           echo "<tr style='background-color: red'><td>$folder_path</td><td>Not Mounted</td><td>Folder Structure not present, so not able to check owner</td><td>RED</td></tr>" >> $filename
           testStatus="RED" >> $filename
        fi
        
        if [ -f "Sfolder file1" ]; then
          echo "File $folder_path1 not found on the server"
        else
           while IFS="|" read -r folder_pathl owner_namel; do
             if df "$folder_path1" >/dev/null 2>&1; then
                if [ "$(stat -c '%U' "$folder_path1")" = "$owner_name1" ]; then
                  echo "<tr><td>$folder_path1</td><td>Mounted</td><td>$owner_namel is correct folder owner</td><td>GREEN</td></tr>" >> $filename
                else
                  echo "<tr style='background-color: red'><td>$folder_path1</td><td>Mounted</td><td>$owner_namel is not correct folder owner</td><td>RED</td></tr>" >> $filename 
                  testStatus="RED" >> $filename
                fi
             else
               echo "<tr style='background-color:red'><td>$folder_path1</td><td>Not Mounted</td><td>Folder Structure not present, so not able to check owner</td><td>RED</td></tr>" >> $filename
               testStatus="RED" >> $filename
             fi
             done < "$folder_filel"
    fi
echo "</table>" >> $filename
fi

########
#####DIRECTORY MONITORING STATUS
########

echo "<br><h4>DIRECTORY MONITORING STATUS</h4>" >> $filename
echo "<table style='width: 800px'><tr><th>DIRECTORY</th><th>FOLDER BLANK OR NOT</th><th>STATUS</th></tr>" >> $filename

NOT_EMPTY_FLAG=0

echo "directory checking"
echo "$MONITORED_DIR1 $MONITORED_DIR2"

if [ "$(ls -A $MONITORED_DIR1)" ]; then
    NOT_EMPTY FLAG=1
fi
echo "checking flag"

if [ $NOT_EMPTY_FLAG -eq 1 ];
then
   echo "<tr style='background-color:red'><td>$MONITORED_DIR1</td><td>NOT EMPTY</td><td>RED</td></tr>" >> $filename
else
    echo "<tr><td>$MONITORED_DIR1</td><td>EMPTY</td><td>GREEN</td></tr>" >> $filename
fi

echo "checking 2nd dir"
if [ "$(ls -A SMONITORED DIR2)" ]; then NOT EMPTY FLAG=1
fi

if [ $NOT_EMPTY_FLAG -eq 1 ];
then
    echo "<tr style='background-color: red'><td>$MONITORED_DIR2 </td><td>NOT EMPTY</td><td>RED</td></tr>" >> $filename
else
    echo "<tr><td>$MONITORED_DIR2</td><td>EMPTY</td><td>GREEN</td></tr>" >> $filename
fi
echo "</table>" >> $filename


#######
###CHECKING THE ULIMIT ON SERVER
#######

echo "<table style='width:500px'>" >> $filename
echo "<h4>Ulimit Check On SERVER</h4>" >> $filename
echo "<tr><th>Open file size</th></tr>" >> $filename
Response=$(ulimit -n)
echo "<tr><td>$Response</td></tr>" >> $filename
echo "</table>" >> $filename

##Process Kill
pids=$(ps -ef | grep telnet )
  for pid in Spids;
  do
    kill -9 $pid
  done


#######
##CONDITION CHECK
#########

if [ $testStatus == "RED" ];
then
{
   echo "<style>.tab{overflow:hidden; border:1px solid #ccc;background-color:RED; width: 100%}.tab button{background-color: inherit; float: left; border:none; outline: none; cursor:pointer; padding: 14px 16px;transition:0.3s;font-size:20px;color: white; font-weight:bold;}.tab button:hover {background-color: white;color:#003366}.tab button.active{background-color: white; color: #003366}.tabcontent {display:none;padding: 6px 12px; border:1px solid #ccc;border-top:none; background-color: white}</style>""<html><head><h3 align="right">Overall Health Status: '$testStatus'</h3>" >> $filename
elif [ $testStatus = "AMBER" ]; then.
    echo "<style>.tab{overflow:hidden; border: 1px solid #ccc;background-color:#FFBF00;width:100%}.tab button{background-color: inherit; float:left; border:none; outline: none; cursor:pointer;padding: 14px 16px;transition:0.3s; font-size:20px;color: white; font-weight:bold;}.tab button:hover{background-color: white;color:#003366}.tab button.active{background-color: white; color: #003366}.tabcontent{display:none;padding: 6px 12px;border:1px solid #ccc;border-top:none; background-color:white}</style>""<html><head><h3 align="right">Overall Health Status: '$testStatus'</h3>" >> $filename
else
    echo "<style>.tab{overflow:hidden; border:1px solid #ccc;background-color:green; width:100%}.tab button{background-color: inherit; float:left; border:none; outline: none; cursor:pointer;padding: 14px 16px; transition:0.3s;font-size:20px;color: white; font-weight:bold;}.tab button:hover{background-color: white;color:#003366}.tab button.active {background-color: white; color:#003366}.tabcontent{display:none;padding: 6px 12px;border:1px solid #ccc;border-top:none; background-color: white}</style>""<html><head><h3 align="right">Overall Health Status: '$testStatus'</h3>" >> $filename
fi

echo "</body></html>" >> $filename

if [ "$1" == "15MinFolder" ]; then
{
   if ($testStatus "RED" ];
   then
   {
      echo "printing red case"
      rm -rf "${ImmediteAlertFolder}*"
      filename1="${ImmediteAlertFolder}HealthReport-${application}-$testStatus.html"
      mv $filename $filenamel
      chmod 777 $filenamel
      echo "filenamel: $filename1"
      echo "$EMAIL_CONTENT_RED" | mailx -s "$alertType-$testStatus $hostname " -r "$FROM" -a "${filename}" "$Alert_TO"
    }
    else
       rm -rf "${ImmediteAlertFolder}/*"
       filenamel="${ImmediteAlertFolde}HealthReport-${application}-$testStatus.html"
       mv $filename $filenamel
       chmod 777 $filenamel
       echo "filenamel: $filenamel"
       echo "All Green"
   fi

else
  {
   echo "pritning else for all cases"
   if [$testStatus == "RED" ];
   then
   {
     echo "printing red case"
     rm -rf "${MorningAndManualFolder}/*"
     filename1="${MorningAndManual Folder} HealthReport-${application}-$testStatus.html"
     mv $filename $filename1
     chmod 777 $filenamel
     echo "filenamel: $filename1"
     echo "$EMAIL_CONTENT_RED"
     echo "$EMAIL_CONTENT_RED" | mailx -s "$alertType-$testStatus-$hostname" -r "$FROM" -a "${filename}" "$Alert_TO"
    }
   elif ($testStatus = "AMBER" ]; then
   {
     rm -rf "$(MorningAndManualFolder}/*"
     filename1="$({MorningAndManualFolder} HealthReport-${application}-$testStatus.html"
     mv $filename $filename1
     chmod 777 $filenamel
     echo "filenamel: $filename1"
     echo "SEMAIL CONTENT AMBER" | mailx -s "$alertType-$testStatus-$hostname" -r "$FROM" -a "${filename}" "$TO"
    }
   else
     rm -rf "$(MorningAndManualFolder}/*"
     filename1="$(MorningAndManualFolder) HealthReport-${application}-$testStatus.html"
     mv $filename $filenamel
     chmod 777 $filenamel
     echo "filenamel: $filename1
     echo "$EMAIL_CONTENT_GREEN" | mailx -s "$alertType-$testStatus-$hostname" -r "$FROM" -a "${filename}" "$TO"
  fi
 }
fi
