#!/bin/sh

while getopts ":f:d:" opt; do
case $opt in
f) device_name="$OPTARG"
;;
d) day="$OPTARG"
;;
\?) echo "Error occur!! -$OPTARG" >&2
;;
esac
done

echo "started time at $(date)" >> status.txt

#time_now=$(date +'%Y/%m/%d %H:%M:%S')
#time_yesterday=$(date --date="$day day ago" +'%Y/%m/%d %H:%M:%S')

time_now=$(date +'%Y/%m/%d 00:00:00')
time_yesterday_end=$(date --date="$day day ago" +'%Y/%m/%d 23:59:59')
time_yesterday=$(date --date="$day day ago" +'%Y/%m/%d 00:00:00')

time_now=$(date +'%Y_%m_%d')
time_yesterday=$(date --date="$day day ago" +'%Y_%m_%d')

touch device_log_file$time_yesterday.xml
touch deviceVPN_log_file$time_yesterday.xml


#panxapi.py -t $device_name --log system --text -xr --nlog 5000 --filter "(receive_time leq '$time_now') and (receive_time geq '$time_yesterday') and (subtype eq globalprotect) and ((eventid eq globalprotectgateway-auth-succ) or (eventid eq globalprotectgateway-logout-succ))" >> device_log_file$time_now.xml
panxapi.py -t $device_name --log system --text -xr --nlog 5000 --filter "(receive_time geq '$time_yesterday') and (receive_time leq '$time_yesterday_end') and (subtype eq globalprotect) and ((eventid eq globalprotectgateway-auth-succ) or (eventid eq globalprotectgateway-logout-succ))" >> device_log_file$time_yesterday.xml


line_num=$(cat device_log_file$time_yesterday.xml | wc -l)
line_start=8
line_end=$(($line_num - 12))

#awk "NR >= 8 && NR <= $line_end" device_log_file$time_now.xml | grep -v -E "^\s+<(\/)?logs" >> deviceVPN_log_file$time_now.xml
awk "NR >= 8 && NR <= $line_end" device_log_file$time_yesterday.xml | grep -v -E "^\s+<(\/)?logs" >> deviceVPN_log_file$time_yesterday.xml


#xml2csv --input "deviceVPN_log_file$time_now.xml" --output "deviceVPN_log_file$time_yesterday_to_$time_now.csv" --tag "entry"
xml2csv --input "deviceVPN_log_file$time_yesterday.xml" --output "deviceVPN_log_file$time_yesterday.csv" --tag "entry"


echo "completed at $(date)" >> status.txt

#.csv format file transfered by smbclient
smbclient //<IP_address>/Logs -U tmguser%<***password***>+ << SMBCLIENTCOMMANDS
put /root/deviceVPN_log_file$time_yesterday.csv deviceVPN_log_file$time_yesterday.csv
exit
SMBCLIENTCOMMANDS

echo 'VPN Logs send successfully' | EMAIL='Report for VPN logs <report_test@domain.com' -c abc@domain.com -s 'Success -VPN Log Transfer-'
