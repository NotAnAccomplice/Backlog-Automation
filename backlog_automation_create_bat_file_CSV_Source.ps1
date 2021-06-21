#Get current location:
$current_location = pwd

#Get current date
$current_date = get-date -format "MM-dd-yyyy"

#Get current time
$current_time = get-date -format "HH-mm"

#Combine date and time into one variable
$current_date_and_time = "$current_date-at-time-$current_time"

#Import the CSV holding the variables:
$csv_source = import-csv -Path "$current_location\set_versions.csv"

#Define a counter for user in the next object.
$counter = 0

#These variables will be defined later, based on the user's inputs:
$last_part_of_file_name = ''
$full_file_name = ''
$function_to_call = ''
$bat_file_value = ''

#Define a function to set the value of last_part_of_file_name depending on the user's value for $partial_sync
Function Define-variable-last_part_of_file_name {

Param(
$partial_sync
)

IF ($partial_sync -eq 'Y') {
    $script:last_part_of_file_name = ' - Quick.bat'
    }
ELSE {
    $script:last_part_of_file_name = '.bat'
    }
}

#Define a function to set the value of $function_to_call depending on the user's value for $partial_sync and $builder_is_ryan
Function Define-variable-function_to_call {

Param(
$partial_sync,
$builder_is_ryan
)

IF ($partial_sync -eq 'Y')
    {
    IF ($builder_is_ryan -eq 'Y')
        {
        #If there is a partial sync and it is a ryan builder, use this:
        $script:function_to_call = 'SyncProjects-quick'
        }
    ELSE
        {
        #If there is a partial sync and it is NOT a ryan builder, use this:
        $script:function_to_call = 'SyncProjectsNV-quick'
        }
    }
ELSE 
    {
    IF ($builder_is_ryan -eq 'Y')
        {
        #If there is NOT a partial sync and it is a ryan builder, use this:
        $script:function_to_call = 'SyncProjects'
        }
    ELSE
        {
        #If there is NOT a partial sync and it is NOT a ryan builder, use this:
        $script:function_to_call = 'SyncProjectsNV'
        }
       
    }
}

#Create an output file. If file already exists, overwrite it.
#(Overwriting a file is done using the "-Force" keyword.)
New-Item -Path . -Name "Backlog_Automation_Output_$current_date_and_time.txt" -Force

#Assign a variable to this file to easily find it again
$output_file = "$current_location\Backlog_Automation_Output_$current_date_and_time.txt"

#Get items from CSV source and put each row into its own array variable.
$csv_source | ForEach-Object {
   $counter += 1
   $var_name = "record_number_$counter"
   New-Variable -Name $var_name -Value @()
   #The code "(Get-Variable -Name $var_name).value" is getting the variable name defined above, but formatted in a way so...
   #...that powershell understands I want to assign a new value to the variable I /created/ above, rather than assign...
   #...a new value to the $var_name variable itself.
   (Get-Variable -Name $var_name).value += $_.name_set_version
   (Get-Variable -Name $var_name).value += $_.partial_sync
   (Get-Variable -Name $var_name).value += $_.builder_is_ryan

   #Now that we have an array for a given row, we will assign certain variables to match the values in the array.
   #First, we'll assign the variable $last_part_of_file_name a value based on the value of the partial_sync above.
   Define-variable-last_part_of_file_name -partial_sync (Get-Variable -Name $var_name).value[1]
   
   #Now we'll do a similar thing but defining the variable $function_to_call based on the values above for partial_sync...
   #...and builder_is_ryan
   Define-variable-function_to_call -partial_sync (Get-Variable -Name $var_name).value[1] -builder_is_ryan (Get-Variable -Name $var_name).value[2]

   $set_version = (Get-Variable -Name $var_name).value[0]

   #Here we will define the variable $full_file_name using variables from above.
   $full_file_name = "$set_version$last_part_of_file_name"

   #And here we will set the value of the .bat file
    $bat_file_value = "@echo off
    cls
    call $function_to_call `"$set_version`" "

    #Almost there - now, we create a new file. If file already exists, overwrite it.
    #(Overwriting a file is done using the "-Force" keyword.)
    New-Item -Path . -Name $full_file_name -Value $bat_file_value -Force

    #And now, we run the .bat file we just created.
    Start-Process .\$full_file_name
    
    #Last step - add the file we just created to the output file.
    Add-Content $output_file "[Name of file created]
    $full_file_name"
    Add-Content $output_file "[Content of file]
    $bat_file_value"
    Add-Content $output_file ''

    #Then we go to the start of the loop and do it all over again with the next row in the .csv file!
   }
