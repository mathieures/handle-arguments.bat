@echo off
SetLocal EnableDelayedExpansion EnableExtensions

set "OPTIONS=d c f o"
rem The order is relevant: actions will be executed in this order.
rem eg: create a file after a newly created directory

rem Default values we want to use:
set "dir=."
set "content="

rem Initialize options as an iterable list
set /a i=1
for %%o in (%OPTIONS%) do (
	set "options[!i!]=%%o"
	set /a i+=1
)

rem Initialize arguments as an iterable list
set /a i=1
for %%A in (%*) do (
	set "args[!i!]=%%A"
	set /a i+=1
)

rem Templates to help making the program:

rem TEMPLATE if we WANT a value after the switch:

rem :action_X
rem call :unquote variable %*
rem if "!variable!"=="" call :ERROR reason
rem echo ## do stuff with !variable! ##
rem exit /b


rem TEMPLATE if we DON'T:

rem :action_Y
rem echo ## do stuff ##
rem exit /b

rem --------------------


:before_actions
rem Insert actions without args to do before every other here
rem echo ### do stuff ###
:end_before_actions

:begin_program

set /a i=1
rem i is the options' index

:begin_loop
rem beginning of option's loop

:next_opt
call :assign current_opt options !i!
rem equivalent in C of: current_opt=options[i]

if "!current_opt!"=="" goto :end_loop

rem Loop variables' initialization
set /a j=1
rem j is the arguments' index
set "found="
rem found will tell us if we found the current option in the arguments

:begin_loop_args
rem Loop through the arguments to check if they are equal to the current option

for %%A in (%*) do (
	if not "!found!"=="true" (
		rem Are the current argument and the current option the same?
		call :is_same %%A /!current_opt!
		rem If yes:
		if not ERRORLEVEL 1	(
			rem found the option in position: !j!
			set "found=true"
		)
		rem Else, we skip to the next argument
		set /a j+=1
	)
)
:end_loop_args
rem If we didn't find the current option, we skip to the next one
if not "!found!"=="true" goto :continue

rem Else, we found it and have to execute the associated action

rem now, j is the position of the argument after the option

call :assign value args !j!
rem equivalent in C of: value=args[j]

rem We execute action_X with the !value! parameter
call :action_!current_opt! !value!
rem Then continue

:continue
set /a i+=1
goto :next_opt


:end_loop
rem End of options' loop
:after_actions
rem Insert here things you want to do by default after the actions
goto :end

rem --------------------

:functions

:assign
rem %1 = %2[%3] <=> 1st_arg = 2nd_arg[3rd_arg] 
for %%j in (%3) do set "%1=!%2[%%j]!"
exit /b

:unquote
rem Remove double quotes from string %2 and put the result in %1
set "%1=%~2"
exit /b

:is_same
rem Removing quotes from %1 and putting the result in str1; same for %2
call :unquote str1 %1
call :unquote str2 %2

rem Is str1 the same as str2? If yes, exit with code 0
if "!str1!"=="!str2!" exit /b 0
rem Else, exit with code 1
exit /b 1

rem --------------------

:actions

:action_d
rem Unquote all parameters passed to the function and put it in the 'dir' variable;
rem we have to unquote before testing, so we can test it afterwards.
call :unquote dir %*
if "!dir!"=="" call :ERROR empty directory

mkdir "!dir!"
rem Created directory named [value of dir]
exit /b

:action_f
rem We make use of !dir! and !content!, both with default values if not specified in command-line
call :unquote file %*
if "!file!"=="" call :ERROR empty file name

echo;!content!>!dir!\!file!
rem Created file '!file!' in dir '!dir!' with content '!content!'
exit /b

:action_o
echo The option o was passed.
echo Nothing seems to happen...
exit /b

:action_c
call :unquote content %*
rem if the value passed is a / plus a single character
rem -so, mainly other options-, then we set 'content' to nothing.
echo !content!| >NUL findstr /r /c:"^/[a-z]$" && set "content="
rem Note the absence of space between '%*' and the vertical line;
rem we have to do it that way or a space will be echo-ed.

rem Assigned content !content!
exit /b


rem --------------------

:ERROR
echo ----- ERROR (reason: %*) -----
goto :end

rem --------------------

:end
rem #### END ####
goto :eof