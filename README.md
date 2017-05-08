# Introduction 
These are the PowerShell scripts I used during my NLVMUG presentation in 2017. Be aware NOT to run all scripts in your production environment - some WILL intentionally generate false or incorrect info. Please read the DESCRIPTION inside every script to learn about the code used and wetter it is safe to use in production environments.

# Getting Started
Ensure you've got the latest PowerCLI version installed. Download the .zip or use VSCODE to download and sync to this project.

# Build and Test
No need to build, just change the variables (correct vCenter server / credentials)

# Contribute
Please let me know if you have improvements to even increase speed and optimize resource utilization. Just send me a mail: [bouke@jume.nl](mailto:bouke@jume.nl)

# About all scripts
**collect**

The collect scripts shows the difference in collecting with PowerCLI Cmdlets or get-view. The 'slow' scripts are using Cmdlets, which results in slow
execution times and higher load. The 'fast' scripts are using get-view. These have fast execution times while presenting the same load.

collect-(slow/fast).1 use a limited amount of properties
collect-(slow/fast).2 and up use a larger amount of properties (to increase collection time)

collect-fast 2, 3, and 4 adds another step in increasing execution times:

2. start using get-view
3. add the property limiter
4. using hashtables

Impact difference is quite high, up to 520x faster in my environment, could be even more or less in your environment.

**grouping**

The grouping scripts shows the power in the group-by Cmdlet - it is very fast. Example 1 is without group-by (using foreach and if statements).
Example 2, 3 and 4 all use the group-object Cmdlet - also the execution time is much faster.

**types**

PowerShell and object inheritance works brilliant with devices like networkinterfaces, storage adapters, disks, etc. This example shows how
to handle different types.

**jobs**

When a Cmdlet doesn't allow asynchronous execution, and you want to run multiple tasks in parallel, use jobs. There a two options running jobs in
the background: scriptblock or calling a second script (master / slave).


