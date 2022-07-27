# Снятие счетчиков производительности (Performance Monitor)

Снятие счетчиков производительности (Performance Monitor) осуществляется средствами скриптов [PowerShell](/PowerShell/).

Осуществляется следующие снятия счетчиков производительности, при этом показатели не должны превышать следующие значения::
- \Memory\Available MBytes                          (**> 50 MB**)
- \Memory\Pages/sec                                 (**< 1000**)
- \Network Interface(*)\Bytes Total/sec             (**< 6 MB/sec (100-Mbps NIC), 60 MB/sec (1000-Mbps NIC)**)
- \Network Interface(*)\Packets Outbound Errors     (**0**)
- \PhysicalDisk(_Total)\Avg. Disk sec/Read          (**< 20 ms (average), < 50 ms (maximum)**)
- \PhysicalDisk(_Total)\Avg. Disk sec/Write         (**< 20 ms (average), < 50 ms (maximum)**)
- \Processor(_Total)\% Processor Time               (**< 90%**)
- \System\Processor Queue Length                    (**< 2**)




